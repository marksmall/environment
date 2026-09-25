#!/bin/zsh

# zsh equivalent of bash's $(dirname "${BASH_SOURCE[0]}"): absolute dir of this script.
DIR="${0:A:h}"

#mv $HOME/.bashrc $HOME/.bashrc.orig

# Generate SSH Key, unless keys were restored from backup.
mkdir -p -m 700 $HOME/.ssh
[ -f $HOME/.ssh/id_ed25519 ] || [ -f $HOME/.ssh/id_rsa ] || ssh-keygen -q -N "" -f $HOME/.ssh/id_ed25519

# Generate GPG keyring, unless a secret key was restored from backup
# (gitconfig signs commits, so a fresh key must also be added to GitHub).
if ! gpg --list-secret-keys 2>/dev/null | grep -q '^sec'; then
  cat >foo <<EOF
     %echo Generating a basic OpenPGP key
     Key-Type: default
     Key-Length: 2048
     Subkey-Type: default
     Name-Real: Mark Small
     Name-Comment: with stupid passphrase
     Name-Email: marksmall@gmx.com
     Expire-Date: 0
     Passphrase: abc
     # Do a commit here, so that we can later print "done" :-)
     %commit
     %echo done
EOF
  gpg --batch --generate-key foo
  rm -rf foo
fi

# Setup oh-my-zsh
[ -d $HOME/.oh-my-zsh ] || git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
# autosuggestions
[ -d $ZSH_CUSTOM/plugins/zsh-autosuggestions ] || git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
# highlighting
[ -d $ZSH_CUSTOM/plugins/zsh-syntax-highlighting ] || git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
# Own plugins (*-local, pnpm, mark) and theme, as listed in zshrc.
for plugin in $DIR/oh-my-zsh/custom/plugins/*(/) $DIR/.oh-my-zsh/custom/plugins/mark; do
  [ -e $ZSH_CUSTOM/plugins/${plugin:t} ] || ln -s $plugin $ZSH_CUSTOM/plugins/${plugin:t}
done
[ -e $ZSH_CUSTOM/themes/msmall-agnoster.zsh-theme ] || ln -s $DIR/msmall-agnoster.zsh-theme $ZSH_CUSTOM/themes/msmall-agnoster.zsh-theme

# Setup static files.
# Delete existing files
rm -rf $HOME/.profile \
       $HOME/.emacs \
       $HOME/.emacs.d \
       $HOME/.gitconfig \
       $HOME/.gitmessage \
       $HOME/.gitignore \
       $HOME/.vimrc \
       $HOME/.inputrc \
       $HOME/.zshrc \
       $HOME/.fonts \
       $HOME/.m2 \
       $HOME/.tmux.conf \
       $HOME/.ssh/config
       #$HOME/.bashrc
       #$HOME/.bashrc_mark-small
       #$HOME/.bashrc_as
       #$HOME/.k5login
       #$HOME/.ackrc

# Recreate from configured.
[ -L $HOME/.profile ] || ln -s $DIR/profile $HOME/.profile
#ln -s $DIR/bashrc $HOME/.bashrc
#ln -s $DIR/bashrc_mark-small $HOME/.bashrc_mark-small
#ln -s $DIR/bashrc_as $HOME/.bashrc_as
[ -L $HOME/.emacs ] || ln -s $DIR/emacs $HOME/.emacs
[ -L $HOME/.emacs.d ] || ln -s $DIR/emacs.d $HOME/.emacs.d
[ -L $HOME/.gitconfig ] || ln -s $DIR/gitconfig $HOME/.gitconfig
[ -L $HOME/.gitmessage ] || ln -s $DIR/gitmessage $HOME/.gitmessage
[ -L $HOME/.gitignore ] || ln -s $DIR/gitignore $HOME/.gitignore
[ -L $HOME/.vimrc ] || ln -s $DIR/vimrc $HOME/.vimrc
[ -L $HOME/.inputrc ] || ln -s $DIR/inputrc $HOME/.inputrc
[ -L $HOME/.zshrc ] || ln -s $DIR/zshrc $HOME/.zshrc
[ -L $HOME/.zshenv ] || ln -s $DIR/zshenv $HOME/.zshenv
[ -L $HOME/.mise.toml ] || ln -s $DIR/mise.toml $HOME/.mise.toml
[ -L $HOME/.shell_aliases ] || ln -s $DIR/shell_aliases $HOME/.shell_aliases
[ -L $HOME/.shell_secrets ] || ln -s $DIR/shell_secrets $HOME/.shell_secrets
[ -L $HOME/.fonts ] || ln -s $DIR/fonts $HOME/.fonts
#ln -s $DIR/k5login $HOME/.k5login
[ -L $HOME/.m2 ] || ln -s $DIR/m2 $HOME/.m2
[ -L $HOME/.tmux.conf ] || ln -s $DIR/tmux.conf $HOME/.tmux.conf
#ln -s $DIR/ackrc $HOME/.ackrc
# Includes the gitignored env/config.private for work hosts.
[ -L $HOME/.ssh/config ] || ln -s $DIR/config $HOME/.ssh/config

# direnv python auto-venv; project .envrc files do `source ~/.config/direnv/python-autoenv.sh`.
mkdir -p "$HOME/.config/direnv"
cp -f "$DIR/python-autoenv.sh" "$HOME/.config/direnv/python-autoenv.sh"

# Install homebrew
[ -x /home/linuxbrew/.linuxbrew/bin/brew ] || NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Install brew formulae, taps, VS Code extensions and npm globals (includes mise).
brew bundle --file=$DIR/Brewfile

# Setup pathogen for vim.
mkdir -p ~/.vim/autoload ~/.vim/bundle && curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim

## Add vim plugins
[ -d $HOME/.vim/bundle/vim-colors-solarized ] || git clone https://github.com/altercation/vim-colors-solarized.git $HOME/.vim/bundle/vim-colors-solarized
[ -d $HOME/.vim/bundle/vim-sensible ] || git clone https://github.com/tpope/vim-sensible.git $HOME/.vim/bundle/vim-sensible

# Add TMUX Plugin manager
[ -d $HOME/.tmux/plugins/tpm ] || git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Add Node Version manager
#git clone https://github.com/nodenv/nodenv.git ~/.nodenv

# Add node-build plugin for ndenv
#mkdir -p ~/.nodenv/plugins
#git clone https://github.com/nodenv/node-build.git ~/.nodenv/plugins/node-build

# Add pyenv
# git clone https://github.com/pyenv/pyenv.git ~/.pyenv
# cd ~/.pyenv && src/configure && make -C src && cd -

# echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
# echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
# echo 'eval "$(pyenv init -)"' >> ~/.zshrc

# cd ~/.pyenv/plugins/python-build/../.. && git pull && cd -

# Install every runtime/CLI version pinned in mise.toml (symlinked to ~/.mise.toml above).
# Needs the apt build dependencies from install.sh for python etc.
export MISE_GLOBAL_CONFIG_FILE="$HOME/.mise.toml"
mise install
# Put the tools just installed on PATH for the rest of this script.
export PATH="$HOME/.local/share/mise/shims:$PATH"

# k8s_secrets (used by the `secrets` function in shell_aliases) comes from agri_cli,
# an editable install from the agrimetrics-cli repo, once that has been cloned.
AGRI_CLI=$HOME/dev/projects/github/telespazio/dsp3/agm/agrimetrics-cli
[ -d $AGRI_CLI ] && mise exec python@3.10.11 -- pip install -e $AGRI_CLI

# Work Azure/AKS login and kube contexts (gitignored, see env/setup.private.sh).
[ -f $DIR/setup.private.sh ] && source $DIR/setup.private.sh

#chsh `whoami` -s /bin/zsh
