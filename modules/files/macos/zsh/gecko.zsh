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

# Launches the local build against the profile directory in $1 with the dev
# prefs applied. mach rejects --setpref whenever --profile is given, so the prefs
# go through user.js, which is rewritten on every launch to stay in sync with
# this file. Removing a line from it does not reset the pref, since Firefox
# already copied the value into prefs.js; set it explicitly or use --fresh.
_mach_run_dev_profile() {
  local profile=$1
  shift

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

# Runs the local build against a clone of the daily Nightly profile, with its
# FxA session, history and tabs. The source profile is looked up by name in
# profiles.ini rather than by its random directory id, and the clone is made on
# first use; pass --fresh to resync it with Nightly.
mrai() {
  local support="$HOME/Library/Application Support/Firefox"
  local profile=${MRAI_PROFILE:-${MOZBUILD_STATE_PATH:-$HOME/.mozbuild}/dev-profiles/smartwindow}

  if [[ $1 == --fresh ]]; then
    shift
    rm -rf "$profile"
  fi

  if [[ ! -d $profile ]]; then
    local name=${MRAI_SOURCE_PROFILE:-default-nightly}
    local src=$(awk -F= -v name="$name" '
      /^\[/ { found = 0 }
      $1 == "Name" && $2 == name { found = 1 }
      found && $1 == "Path" { print $2; exit }
    ' "$support/profiles.ini")

    [[ $src == /* ]] || src=$support/$src

    if [[ ! -d $src ]]; then
      print -u2 "mrai: no '$name' profile found in $support/profiles.ini"
      return 1
    fi

    print "mrai: cloning $src -> $profile"
    mkdir -p "${profile:h}"
    cp -Rc "$src" "$profile" || return 1
    rm -f "$profile/lock" "$profile/.parentlock" "$profile/compatibility.ini"
  fi

  _mach_run_dev_profile "$profile" "$@"
}

# Runs the local build against an empty profile that persists between runs, so
# signing in to FxA once keeps it signed in with nothing else carried over from
# Nightly. Pass --fresh to wipe it, which also signs it out.
mrp() {
  local profile=${MRP_PROFILE:-${MOZBUILD_STATE_PATH:-$HOME/.mozbuild}/dev-profiles/plain}

  if [[ $1 == --fresh ]]; then
    shift
    rm -rf "$profile"
  fi

  mkdir -p "$profile"
  _mach_run_dev_profile "$profile" "$@"
}

# The firefox-devtools MCP server in the tree's .mcp.json launches mach with
# ${MACH_PYTHON:-python3}, so it needs the same pin as the function above.
export MACH_PYTHON=python3.12

# The Claude Code github plugin authenticates its MCP server with this variable
# and fails to connect when it is unset. gh keeps the token in the keychain.
if (( $+commands[gh] )); then
  export GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token 2>/dev/null)"
fi

alias mb="mach build"
alias mbf="mach build faster"
alias mc="mach clobber"
alias ml="mach lint -wo --fix"
alias mr="mach run"
alias mt="mach test"
alias mth="mach test --headless"

alias ph="moz-phab"
alias phs="moz-phab submit"
alias phd="moz-phab submit -d"
