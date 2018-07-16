#!/usr/bin/env zsh

confdir=$HOME/.my-config
source $confdir/zsh/zshrc

[[ -d $HOME/bin ]] || mkdir $HOME/bin

# Bootstrapping of basic libraries required to get all the configuration
ln -sf $confdir/git/config $HOME/.gitconfig
cd $confdir && git submodule init && git submodule update

cd $HOME
ln -sf $confdir/hg/hgrc .hgrc
sudo easy_install pip
sudo pip install --upgrade $confdir/lib/dulwich

ln -sf $confdir/emacs.d .emacs.d
[[ -z "$EMACS" ]] && EMACS=emacs
$EMACS --batch -l .emacs.d/init.el --eval '(my-recompile-init)'

ln -sf $confdir/vim .vim
ln -sf $confdir/vim/vimrc .vimrc
ln -sf .vimrc .gvimrc

ln -sf $confdir/zsh/zshrc .zshrc
ln -sf $confdir/zsh/vcs_info.py $HOME/bin

[[ -d $HOME/Library/LaunchAgents ]] || mkdir -m 0755 $HOME/Library/LaunchAgents
ln -sf $confdir/mac/com.pitkali.env2launchctl.plist $HOME/Library/LaunchAgents
sudo cp $confdir/mac/env2launchctl /usr/libexec
sudo cp $confdir/mac/com.pitkali.launchd.* /Library/LaunchDaemons/

# sudo zsh -c "echo /usr/local/bin | cat - /etc/paths > /etc/paths"
sudo zsh -c "echo /Applications/Racket/bin > /etc/paths.d/Racket"
