# Personal git aliases, predating any awareness of the built-in `git` plugin's
# own alias set. A few names below still collide with it, but only where this
# version does the same thing as the builtin with extra/different flags (e.g.
# `gm` here is `git merge --ff-only`, not the builtin's plain `git merge`;
# `gsu` adds `--init --recursive`, which the builtin's version lacks). Loads
# after the built-in plugin, so these win. Aliases whose meaning here had
# nothing to do with the builtin's (gss, gg, gr, gbs, gcf) were removed —
# gsts/glg/grb are the community equivalents for the first three; gbs pointed
# at a nonexistent `git branch-status` command; gcf was unused (gclean covers
# it).

alias gt='git tag -n'
alias gm='git merge --ff-only'
alias gd='git diff -w --'
alias gdc='git diff -w --cached --'
alias gs='git stash'
alias gsl='git stash list'
alias gsp='git stash pop'
alias gsc='git stash clear'
alias gfd='git fetch && git diff $(current_branch) origin/$(current_branch)'
alias gcl='git clone'
alias gl='git pull --ff-only --rebase'
alias grp='git remote prune origin'
alias gpo='git push -u origin'
alias gfa='git fetch --all'
alias gfl='git fetch && git log $(current_branch) origin/$(current_branch)'
alias gbl='git blame'
alias gsk='git stash --keep-index'
alias gsu='git submodule update --init --recursive'
alias gpa='for f in `ls`; do echo $f; cd $f; git pull; cd ..; done'
alias gpn='git push --no-verify'
alias gbsc='git branch --sort=-committerdate'
alias gup='for f in `ls`; do cd $f; git pull; cd ..; done'
