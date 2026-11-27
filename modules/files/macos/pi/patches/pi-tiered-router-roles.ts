import type { ThinkingLevel } from "@earendil-works/pi-agent-core";
import type { Model } from "@earendil-works/pi-ai";
import type { ModelRegistry } from "@earendil-works/pi-coding-agent";
import {
	type Complexity,
	type ResolvedRole,
	type RoleConfig,
	type RoleName,
	ROLE_NAMES,
	type RouterConfig,
} from "./types.ts";

interface SpecResolution {
	model: Model<any>;
	/** Explicit ":thinking" suffix on the spec, if any — overrides the role's configured level. */
	thinkingLevel?: ThinkingLevel;
}

/**
 * Resolve a single model spec against the registry. Two paths:
 *
 * - "provider/prefix-*" wildcards: matched by the router itself (prefer
 *   candidates with configured auth, then the lexicographically greatest id —
 *   newest point release wins for date-suffixed ids). pi's own resolver has
 *   no glob support, so this stays hand-rolled.
 * - Everything else (an exact "provider/id", a bare id, or either with a
 *   ":thinking" suffix): matched against the registry directly, in the order
 *   exact, bare id, then substring on id or name, preferring an authenticated
 *   candidate. Only real registry entries resolve, so a typo can never turn
 *   into a made-up model.
 */
function resolveSpec(registry: ModelRegistry, spec: string): SpecResolution | undefined {
	const trimmed = spec.trim();
	if (!trimmed) return undefined;

	const slash = trimmed.indexOf("/");
	const hasProviderPrefix = slash > 0 && slash < trimmed.length - 1;
	const idPart = hasProviderPrefix ? trimmed.slice(slash + 1) : trimmed;

	if (idPart.includes("*")) {
		if (!hasProviderPrefix) return undefined; // wildcards require an explicit "provider/" prefix
		const provider = trimmed.slice(0, slash);
		const prefix = idPart.replace(/\*+$/, "").replace(/[-_]$/, "");
		const candidates = registry.getAll().filter((m) => m.provider === provider && (prefix === "" || m.id.startsWith(prefix)));
		if (candidates.length === 0) return undefined;

		const authed = new Set(candidates.filter((m) => registry.hasConfiguredAuth(m)).map((m) => m.id));
		candidates.sort((a, b) => {
			const aAuth = authed.has(a.id) ? 1 : 0;
			const bAuth = authed.has(b.id) ? 1 : 0;
			if (aAuth !== bAuth) return bAuth - aAuth; // authed first
			return b.id.localeCompare(a.id); // newest id wins
		});
		return { model: candidates[0]! }; // length checked above, so index 0 is always defined
	}

	// shortcut: pi's resolveCliModel now takes a ModelRuntime, which ExtensionContext
	// does not expose, so specs resolve against registry.getAll() directly here.
	// Exact provider/id wins, then a bare id, then a substring match on id or name.
	const THINKING = ["off", "minimal", "low", "medium", "high", "xhigh", "max"] as const;
	let text = trimmed;
	let thinkingLevel: ThinkingLevel | undefined;
	const colon = text.lastIndexOf(":");
	if (colon > 0 && (THINKING as readonly string[]).includes(text.slice(colon + 1))) {
		thinkingLevel = text.slice(colon + 1) as ThinkingLevel;
		text = text.slice(0, colon);
	}
	const all = registry.getAll();
	const slash2 = text.indexOf("/");
	const wantProvider = slash2 > 0 && slash2 < text.length - 1 ? text.slice(0, slash2) : undefined;
	const wantId = (wantProvider ? text.slice(slash2 + 1) : text).toLowerCase();
	if (!wantId) return undefined;

	const exact = all.filter((m) => (!wantProvider || m.provider === wantProvider) && m.id.toLowerCase() === wantId);
	const bare = exact.length === 0 ? all.filter((m) => m.id.toLowerCase() === wantId) : [];
	const fuzzy =
		exact.length === 0 && bare.length === 0
			? all.filter(
					(m) =>
						(!wantProvider || m.provider === wantProvider) &&
						(m.id.toLowerCase().includes(wantId) || (m.name ?? "").toLowerCase().includes(wantId)),
				)
			: [];
	const matches = exact.length > 0 ? exact : bare.length > 0 ? bare : fuzzy;
	if (matches.length === 0) return undefined;

	// Prefer an authenticated candidate when a bare/fuzzy spec is ambiguous.
	const best = matches.find((m) => registry.hasConfiguredAuth(m)) ?? matches[0]!;
	return { model: best, thinkingLevel };
}

/**
 * Resolve one role using its primary spec, then its fallback chain.
 * A fallback of "skip" disables the role (skipped=true, model=undefined).
 */
export function resolveRole(
	registry: ModelRegistry,
	role: RoleName,
	roleConfig: RoleConfig,
	fallbacks: string[] = [],
): ResolvedRole {
	const base: Pick<ResolvedRole, "role" | "requested"> = {
		role,
		requested: roleConfig.model,
	};

	// A primary spec of "skip" disables the role directly — same convention as
	// "skip" in a fallback chain, just spelled at the front. Lets /router config
	// and the setup wizard offer "skip" as a role's model without the resolver
	// treating it as an unresolvable "provider/id" spec and warning at startup.
	if (roleConfig.model.trim().toLowerCase() === "skip") {
		return { ...base, model: undefined, thinking: roleConfig.thinking, viaFallback: false, skipped: true };
	}

	// Primary.
	const primary = resolveSpec(registry, roleConfig.model);
	if (primary) {
		return {
			...base,
			model: primary.model,
			resolvedId: `${primary.model.provider}/${primary.model.id}`,
			thinking: primary.thinkingLevel ?? roleConfig.thinking,
			viaFallback: false,
			skipped: false,
		};
	}

	// Fallback chain.
	for (const fb of fallbacks) {
		if (fb === "skip") {
			return { ...base, model: undefined, thinking: roleConfig.thinking, viaFallback: true, skipped: true };
		}
		const resolved = resolveSpec(registry, fb);
		if (resolved) {
			return {
				...base,
				model: resolved.model,
				resolvedId: `${resolved.model.provider}/${resolved.model.id}`,
				thinking: resolved.thinkingLevel ?? roleConfig.thinking,
				viaFallback: true,
				skipped: false,
			};
		}
	}

	// Unresolved and not explicitly skipped.
	return { ...base, model: undefined, thinking: roleConfig.thinking, viaFallback: false, skipped: false };
}

/** Resolve all four roles. */
export function resolveAllRoles(
	registry: ModelRegistry,
	config: RouterConfig,
): Record<RoleName, ResolvedRole> {
	const out = {} as Record<RoleName, ResolvedRole>;
	for (const role of ROLE_NAMES) {
		out[role] = resolveRole(registry, role, config.roles[role], config.fallbacks[role] ?? []);
	}
	return out;
}

/**
 * Apply `routing.tiers[complexity]`'s role overrides on top of already-resolved
 * base roles. Roles with no override for this tier (or when `tiers`/`complexity`
 * is absent entirely) pass through `resolved` unchanged — tiering is additive,
 * never required. An override's own spec is resolved via the same
 * resolve-then-fallback machinery as the base config (using that role's normal
 * `fallbacks` chain); if neither the override nor its fallbacks resolve, this
 * degrades to the base resolved role rather than leaving the turn with no
 * model at all — a tier override is a deliberate quality choice, not a new
 * failure mode to introduce.
 *
 * Never call this for the classifier's own role lookup: tiering depends on
 * already knowing the complexity, so classification always runs on `resolved`
 * (the base roles), not a tiered set.
 */
export function rolesForTier(
	registry: ModelRegistry,
	resolved: Record<RoleName, ResolvedRole>,
	config: RouterConfig,
	complexity: Complexity | undefined,
): Record<RoleName, ResolvedRole> {
	const tierOverrides = complexity ? config.routing.tiers?.[complexity] : undefined;
	if (!tierOverrides) return resolved;

	const out = { ...resolved };
	for (const role of ROLE_NAMES) {
		const override = tierOverrides[role];
		if (!override) continue; // no override for this role at this tier — falls through to base

		if (override === "skip") {
			out[role] = { role, model: undefined, thinking: resolved[role].thinking, requested: "skip", viaFallback: false, skipped: true };
			continue;
		}

		const tierResolved = resolveRole(registry, role, override, config.fallbacks[role] ?? []);
		out[role] = tierResolved.model || tierResolved.skipped ? tierResolved : resolved[role];
	}
	return out;
}

/** One-line human summary of a resolved role, e.g. "planner → anthropic/claude-opus-4 (high)". */
export function describeRole(r: ResolvedRole): string {
	if (r.skipped) return `${r.role} → skipped`;
	if (!r.model) return `${r.role} → UNRESOLVED (wanted ${r.requested})`;
	const via = r.viaFallback ? " [fallback]" : "";
	return `${r.role} → ${r.resolvedId} (${r.thinking})${via}`;
}

/** Short model label for status lines, e.g. "opus" from "claude-opus-4-20250101". */
export function shortModelLabel(r: ResolvedRole): string {
	if (r.skipped) return "—";
	if (!r.model) return "?";
	const id = r.model.id;
	const m = id.match(/(opus|sonnet|haiku|fable|gpt-?\d*|gemini|o\d)/i);
	if (m?.[1]) return m[1].toLowerCase();
	return id.split(/[-_]/)[0] ?? id;
}

/** "provider/id" key for a model — used to match against the current session model and the scoped-model set. */
export function modelKey(m: { provider: string; id: string }): string {
	return `${m.provider}/${m.id}`;
}

/**
 * Order a role's model options for the setup wizard: the current pi session
 * model first, then models in pi's scoped-model set (Settings.enabledModels,
 * resolved by the caller), then authed/available models, then the rest —
 * ties within a rank break alphabetically by "provider/id" for a stable,
 * predictable list. Pure and synchronous so it's testable without a registry
 * or UI context; `index.ts`'s setup wizard supplies the real registry data.
 */
export function orderModelsForRole(input: {
	all: Model<any>[];
	currentModel: Model<any> | undefined;
	scopedIds: Set<string>;
	hasAuth: (m: Model<any>) => boolean;
}): Model<any>[] {
	const { all, currentModel, scopedIds, hasAuth } = input;
	const currentKey = currentModel ? modelKey(currentModel) : undefined;

	function rank(m: Model<any>): number {
		if (currentKey && modelKey(m) === currentKey) return 0;
		if (scopedIds.has(modelKey(m))) return 1;
		if (hasAuth(m)) return 2;
		return 3;
	}

	return [...all].sort((a, b) => {
		const ra = rank(a);
		const rb = rank(b);
		if (ra !== rb) return ra - rb;
		return modelKey(a).localeCompare(modelKey(b));
	});
}
