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

# Runs the local build against a clone of the daily Nightly profile, so the FxA
# session Smart Window needs is already signed in. The source profile is looked
# up by name in profiles.ini rather than by its random directory id, and the
# clone is made on first use — delete it to resync with Nightly. mach rejects
# --setpref whenever --profile is given, so the prefs go through user.js, which
# is rewritten on every launch to stay in sync with this file.
mrai() {
  local support="$HOME/Library/Application Support/Firefox"
  local profile=${MRAI_PROFILE:-${MOZBUILD_STATE_PATH:-$HOME/.mozbuild}/dev-profiles/smartwindow}

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

  cat >"$profile/user.js" <<'EOF'
user_pref("browser.smartwindow.enabled", true);
user_pref("browser.ai.control.smartWindow", "enabled");
user_pref("browser.ml.logLevel", "All");
user_pref("browser.smartwindow.log", "All");
user_pref("devtools.chrome.enabled", true);
user_pref("devtools.console.stdout.chrome", true);
EOF

  mach run --profile "$profile" "$@"
}

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
