# Additional GitHub CLI aliases and helpers for Oh My Zsh.

# Pull requests
alias ghprs='gh pr status'
alias ghprl='gh pr list'
alias ghprv='gh pr view'
alias ghprvw='gh pr view --web'
alias ghspra='gh search prs --assignee @me --state open'
alias ghsprr='gh search prs --review-requested @me --state open'

# Open the current repository in the browser
alias ghb='gh repo view --web'

alias ghwr='gh workflow run'
alias ghba='gh browse -a'

function ghwa() {
  gh run watch \
   "$(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')" \
   --exit-status
}

# Return a repository from an organisation interactively
ghorgrepo() {
  gh repo list "$1" --limit 200 |
    fzf |
    awk '{print $1}'
}


# Search

## Search repo for a string
ghsr() {
  gh search code "$1" --repo "$2"
}

## Search org for a string
ghso() {
  gh search code "$1" --owner agrimetrics
}

## Search ors for a string and group results
ghsos() {
  gh search code "$1" --owner agrimetrics --limit 100 --json repository \
  | jq -r '.[].repository.nameWithOwner' \
  | sort | uniq -c | sort -nr | head
}

## Search org for a string and group results with details
ghsosd() {
  gh search code "$1" --owner agrimetrics --limit 100 --json repository,path \
  | jq -r '
    group_by(.repository.nameWithOwner)
    | map({
        repo: .[0].repository.nameWithOwner,
        count: length,
        files: map(.path)
      })
    | sort_by(.count)
    | reverse
    | .[]
  '
}

## Search repositories and clone one interactively
ghclone() {
  gh search repos "$1" --limit 20 |
    fzf |
    awk '{print $1}' |
    xargs -r gh repo clone
}

## Search repositories and open one in the browser interactively
ghrepo() {
  gh search repos "$1" --limit 20 |
    fzf |
    awk '{print $1}' |
    xargs -r gh repo view --web
}

