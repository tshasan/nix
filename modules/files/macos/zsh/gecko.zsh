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
# Anything after that goes to mach run, e.g. `mr nightly --jsdebugger`.
#
# The Nightly profile is looked up by name in profiles.ini rather than by its
# random directory id. mach rejects --setpref whenever --profile is given, so the
# prefs go through user.js, which is rewritten on every launch to stay in sync
# with this file. Removing a line from it does not reset the pref, since Firefox
# already copied the value into prefs.js; set it explicitly or reset the profile.
mr() {
  local profiles=${MOZBUILD_STATE_PATH:-$HOME/.mozbuild}/dev-profiles
  local profile=$profiles/plain label="empty profile" nightly=0

  if [[ $1 == nightly ]]; then
    shift
    nightly=1
    profile=$profiles/smartwindow
    label="Nightly copy"
  fi

  if [[ $1 == reset ]]; then
    shift
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
    local src=$(awk -F= '
      /^\[/ { found = 0 }
      $1 == "Name" && $2 == "default-nightly" { found = 1 }
      found && $1 == "Path" { print $2; exit }
    ' "$support/profiles.ini")

    [[ $src == /* ]] || src=$support/$src

    if [[ ! -d $src ]]; then
      print -u2 "mr: no 'default-nightly' profile found in $support/profiles.ini"
      return 1
    fi

    print "mr: copying Nightly's profile, this only happens on first use or reset"
    mkdir -p "$profiles"
    cp -Rc "$src" "$profile" || return 1
    rm -f "$profile/lock" "$profile/.parentlock" "$profile/compatibility.ini"
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
if (( $+commands[gh] )); then
  export GITHUB_PERSONAL_ACCESS_TOKEN="$(gh auth token 2>/dev/null)"
fi

alias mb="mach build"
alias mbf="mach build faster"
alias mc="mach clobber"
alias ml="mach lint -wo --fix"
alias mt="mach test"
alias mth="mach test --headless"

alias ph="moz-phab"
alias phs="moz-phab submit"
alias phd="moz-phab submit -d"
