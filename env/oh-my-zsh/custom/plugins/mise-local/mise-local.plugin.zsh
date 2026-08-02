# mise version manager — aliases and interactive helpers for Oh My Zsh.
# See ~/mise-cheatsheet.md for the full command reference and the asdf → mise mapping.

# Shorthand — all prefixed "mi", matching the gh-local convention of prefixing
# every alias with the tool name rather than reusing it as a bare command.
alias mil='mise ls'
alias milr='mise ls-remote'
alias mii='mise install'
alias mic='mise current'
alias miw='mise which'
alias mio='mise outdated'
alias miu='mise upgrade'
alias mip='mise prune'
alias mid='mise doctor'
alias micfg='mise config ls'
alias mir='mise registry'

# Print the version actually in effect for a tool, or every tool if none given
# (first-wins in a mise.toml array, so this can differ from every entry
# `mil`/`mise ls` marks "active").
# Usage: mia [tool]
mia() {
  if [[ -n "$1" ]]; then
    basename "$(mise where "$1")"
    return
  fi

  mise current | awk '{print $1}' | while IFS= read -r tool; do
    printf '%-30s %s\n' "$tool" "$(basename "$(mise where "$tool")")"
  done
}

# Interactively pick an installed version of a tool
# Usage: miv <tool>
miv() {
  local tool="${1:?Usage: miv <tool>}"
  mise ls "$tool" | fzf --header "Installed $tool versions"
}

# Interactively pick a remote version and install + use it in the current directory's mise.toml
# Usage: miuse <tool>
miuse() {
  local tool="${1:?Usage: miuse <tool>}"
  local version
  version=$(mise ls-remote "$tool" | fzf --header "Install + use $tool locally") || return
  mise use "$tool@$version"
}

# Same as miuse, but writes to the global config (~/.config/mise/config.toml) instead
# Usage: miuseg <tool>
miuseg() {
  local tool="${1:?Usage: miuseg <tool>}"
  local version
  version=$(mise ls-remote "$tool" | fzf --header "Install + use $tool globally") || return
  mise use -g "$tool@$version"
}

# Search the mise registry interactively (what mise can install, and via which backend)
# Usage: misearch [term]
misearch() {
  mise registry | fzf --header "mise registry" --query "${1:-}"
}
