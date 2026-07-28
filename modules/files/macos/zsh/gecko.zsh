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
