# Local patches to npm-installed pi packages

`pi update --extensions` (or reinstalling) overwrites these. Restore after an update:

## pi-tiered-router (pi 1.5.2 compat)

`resolveCliModel()` in pi 1.5.2 takes a `ModelRuntime`, which `ExtensionContext`
does not expose; the package passed a `ModelRegistry`, so it crashed on load with
`Cannot read properties of undefined (reading 'getModels')`.

Fixed in `extensions/model-router/roles.ts` by resolving specs against
`registry.getAll()` directly (exact -> bare id -> substring, authed preferred).

    cp ~/.pi/agent/patches/pi-tiered-router-roles.ts \
       ~/.pi/agent/npm/node_modules/pi-tiered-router/extensions/model-router/roles.ts
