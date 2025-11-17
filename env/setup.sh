#!/bin/bash

#mv $HOME/.bashrc $HOME/.bashrc.orig

# Generate SSH Key
cat /dev/zero | ssh-keygen -q -N ""

# Generate GPG keyring
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

# Setup oh-my-zsh
git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
# autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Setup static files.
# Delete existing files
rm -rf $HOME/.profile\
       $HOME/.bashrc \
       $HOME/.bashrc_mark-small \
       $HOME/.bashrc_as\
       $HOME/.emacs \
       $HOME/.emacs.d \
       $HOME/.gitconfig \
       $HOME/.gitmessage \
       $HOME/.gitignore \
       $HOME/.vimrc \
       $HOME/.inputrc \
       $HOME/.zshrc \
       $HOME/.fonts \
       $HOME/.k5login \
       #$HOME/.oh-my-zsh/themes/msmall-agnoster.zsh-theme \
       $HOME/.m2 \
       $HOME/.tmux.conf \
       $HOME/.ackrc \
       $HOME/.ssh/config

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Recreate from configured.
ln -s $DIR/profile $HOME/.profile
ln -s $DIR/bashrc $HOME/.bashrc
ln -s $DIR/bashrc_mark-small $HOME/.bashrc_mark-small
ln -s $DIR/bashrc_as $HOME/.bashrc_as
ln -s $DIR/emacs $HOME/.emacs
ln -s $DIR/emacs.d $HOME/.emacs.d
ln -s $DIR/gitconfig $HOME/.gitconfig
ln -s $DIR/gitmessage $HOME/.gitmessage
ln -s $DIR/gitignore $HOME/.gitignore
ln -s $DIR/vimrc $HOME/.vimrc
ln -s $DIR/inputrc $HOME/.inputrc
ln -s $DIR/zshrc $HOME/.zshrc
ln -s $DIR/shell_aliases $HOME/.shell_aliases
ln -s $DIR/shell_secrets $HOME/.shell_secrets
ln -s $DIR/fonts $HOME/.fonts
ln -s $DIR/k5login $HOME/.k5login
#ln -s $DIR/msmall-agnoster.zsh-theme $HOME/.oh-my-zsh/themes/msmall-agnoster.zsh-theme
ln -s $DIR/m2 $HOME/.m2
ln -s $DIR/tmux.conf $HOME/.tmux.conf
ln -s $DIR/ackrc $HOME/.ackrc

mkdir -p $HOME/config/direnv
ln -s $DIR/python-env.sh $HOME/config/direnv/python-env.sh

# Install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install asdf
brew install asdf

# Setup pathogen for vim.
mkdir -p ~/.vim/autoload ~/.vim/bundle && curl -LSso ~/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim

## Add vim plugins
cd ~/.vim/bundle
git clone git://github.com/altercation/vim-colors-solarized.git
git clone git://github.com/tpope/vim-sensible.git

# Add TMUX Plugin manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

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

# update zshrc
source $HOME/.zshrc

# Install asdf tools
asdf plugin add awscli https://github.com/MetricMike/asdf-awscli.git
asdf install awscli latest
asdf plugin add azure-cli https://github.com/EcoMind/asdf-azure-cli              
asdf install azure-cli latest
asdf plugin add dotnet-core https://github.com/emersonsoares/asdf-dotnet-core.git
asdf install dotnet-core 8.0.414,9.0.304
asdf plugin add kubectl https://github.com/asdf-community/asdf-kubectl.git       
asdf install kubectl 1.22.17 
asdf plugin add kubelogin https://github.com/sechmann/asdf-kubelogin.git         
asdf install kubelogin latest,0.2.8 
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git                
asdf install nodejs latest,22.17.1
asdf plugin add poetry https://github.com/asdf-community/asdf-poetry.git         
asdf install poetry 2.1,3,2.2.0 
asdf plugin add python https://github.com/asdf-community/asdf-python.git         
asdf install python latest,3.10.11


chsh `whoami` -s /bin/zsh
