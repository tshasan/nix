# Sourced by the ~/.config/zsh/local/*.zsh loop in common.zsh.

# Homebrew's unversioned python3 is 3.14 and has to stay there, since llvm,
# mercurial, meson and watchman all depend on python@3.14. The Firefox build
# system is only validated up to 3.12, and on 3.14 it floods artifact builds
# with 'JarFileReader has no attribute flush' finalization errors, so pin the
# interpreter here instead of relinking python3 machine-wide.
#
# Walks up to the enclosing checkout, so this works from any subdirectory,
# unlike ./mach which only works from the tree root. caffeinate -i holds off
# idle sleep for the duration of the command so long builds and test runs
# don't stall halfway through.
mach() {
  local dir=$PWD root=""

  while [[ -n $dir && $dir != / ]]; do
    if [[ -x $dir/mach ]]; then
      root=$dir
      break
    fi
    dir=${dir:h}
  done

  if [[ -z $root ]]; then
    print -u2 "mach: no mach found in $PWD or any parent directory"
    return 1
  fi

  if (( $+commands[python3.12] )); then
    caffeinate -i python3.12 "$root/mach" "$@"
  else
    print -u2 "mach: python3.12 not found, falling back to the default interpreter"
    caffeinate -i "$root/mach" "$@"
  fi
}

# One command for running the local build:
#
#   mr                  empty profile, sign in to FxA once and it stays signed in
#   mr nightly          copy of the daily Nightly profile, with its FxA, history and tabs
#   mr reset            wipe the empty profile first
#   mr nightly reset    re-copy from Nightly first
#
# nightly and reset can come in either order. Anything after them goes to
# mach run, e.g. `mr nightly --jsdebugger`.
#
# The Nightly profile is looked up by name in profiles.ini rather than by its
# random directory id. mach rejects --setpref whenever --profile is given, so the
# prefs go through user.js, which is rewritten on every launch to stay in sync
# with this file. Removing a line from it does not reset the pref, since Firefox
# already copied the value into prefs.js; set it explicitly or reset the profile.
mr() {
  local profiles=${MOZBUILD_STATE_PATH:-$HOME/.mozbuild}/dev-profiles
  local profile=$profiles/plain label="empty profile" nightly=0 reset=0

  while [[ $1 == (nightly|reset) ]]; do
    [[ $1 == nightly ]] && nightly=1 || reset=1
    shift
  done

  if (( nightly )); then
    profile=$profiles/smartwindow
    label="Nightly copy"
  fi

  if (( reset )); then
    if [[ -d $profile ]]; then
      read -q "?mr: wipe the $label at $profile? Your real Nightly profile is not touched. [y/N] " || {
        print
        return 1
      }
      print
      rm -rf "$profile"
    fi
  fi

  if (( nightly )) && [[ ! -d $profile ]]; then
    local support="$HOME/Library/Application Support/Firefox"
    local staging
    mkdir -p "$profiles" || return 1
    staging=$(mktemp -d "$profiles/.nightly-copy.XXXXXXXX") || return 1

    print "mr: copying Nightly's profile, this only happens on first use or reset"
    if ! python3.12 - "$support" "$staging/profile" <<'PYTHON'
import configparser
import fcntl
import pathlib
import subprocess
import sys

support = pathlib.Path(sys.argv[1])
try:
    ini = configparser.RawConfigParser()
    with (support / "profiles.ini").open() as stream:
        ini.read_file(stream)
    matches = [section for section in ini.sections()
               if section.startswith("Profile")
               and ini.get(section, "Name", fallback="") == "default-nightly"]
    if len(matches) != 1:
        raise ValueError("expected exactly one 'default-nightly' profile")
    section = ini[matches[0]]
    value = section.get("Path", "").strip()
    if not value:
        raise ValueError("Nightly profile has no Path")
    source = pathlib.Path(value)
    if section.getboolean("IsRelative", fallback=True):
        if source.is_absolute():
            raise ValueError("Nightly profile has an invalid relative Path")
        source = support / source
    elif not source.is_absolute():
        raise ValueError("Nightly profile has an invalid absolute Path")
    source = source.resolve(strict=True)
    if pathlib.Path(sys.argv[2]).resolve().is_relative_to(source):
        raise ValueError("Nightly profile cannot contain the development profiles")
    if source == support.resolve() or not (source / "prefs.js").is_file():
        raise ValueError("Nightly Path is not an initialized profile")
    # Firefox uses an fcntl lock; the lock file can also remain after exit.
    with (source / ".parentlock").open("a+b") as lock:
        try:
            fcntl.lockf(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise ValueError("quit Nightly before copying its profile") from None
        subprocess.run(["cp", "-Rc", str(source), sys.argv[2]], check=True)
except (OSError, ValueError, configparser.Error, subprocess.CalledProcessError) as error:
    print(f"mr: {error}", file=sys.stderr)
    sys.exit(1)
PYTHON
    then
      rm -rf "$staging"
      return 1
    fi

    # A shared store ID makes Firefox repoint default-nightly in profiles.ini
    # at this copy, which orphans the real Nightly profile.
    if ! rm -f "$staging/profile/lock" "$staging/profile/.parentlock" "$staging/profile/compatibility.ini" ||
      ! sed -i '' '/toolkit\.profiles\.storeID/d' "$staging/profile/prefs.js" ||
      ! python3.12 -c 'import os, sys; os.rename(sys.argv[1], sys.argv[2])' "$staging/profile" "$profile"; then
      rm -rf "$staging"
      return 1
    fi
    rmdir "$staging"
  fi

  mkdir -p "$profile"
  print "mr: $label    (options: mr, mr nightly, add 'reset' to start over)"

  cat >"$profile/user.js" <<'EOF'
user_pref("browser.aboutConfig.showWarning", false);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.smartwindow.enabled", true);
user_pref("browser.ai.control.smartWindow", "enabled");
user_pref("browser.ml.logLevel", "All");
user_pref("browser.smartwindow.log", "All");
user_pref("devtools.chrome.enabled", true);
user_pref("devtools.console.stdout.chrome", true);

// default-nightly pins this to 0, which disables speculative connections.
user_pref("network.http.speculative-parallel-limit", 6);
EOF

  # A profile outside profiles.ini keeps its startup cache in the profile dir,
  # where it can outlive .sys.mjs edits and keep running stale bytecode.
  rm -rf "$profile/startupCache"

  # Builds from different worktrees share these profiles, so an older one would
  # otherwise trip the profile downgrade prompt.
  mach run --profile "$profile" -allow-downgrade "$@"
}

alias mrai="mr nightly"

# The firefox-devtools MCP server in the tree's .mcp.json launches mach with
# ${MACH_PYTHON:-python3}, so it needs the same pin as the function above.
export MACH_PYTHON=python3.12

# The Claude Code github plugin authenticates its MCP server with this variable
# and fails to connect when it is unset. gh keeps the token in the keychain.
# Reading it costs a keychain round trip, so only pay that when claude starts,
# and keep the token out of every other process's environment.
claude() {
  GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token 2>/dev/null)" command claude "$@"
}

alias mb="mach build"
alias mbf="mach build faster"
alias mc="mach clobber"
alias ml="mach lint -wo --fix"
alias mt="mach test"
alias mth="mach test --headless"

alias ph="moz-phab"
alias phs="moz-phab submit"
alias phd="moz-phab submit -d"
