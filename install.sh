#!/usr/bin/env zsh

confdir=$HOME/.my-config
source $confdir/zsh/zshrc

# Bootstrapping of basic libraries required to get all the configuration
cd $confdir/lib || exit 1
[[ -d hg-git ]] || hg clone https://bitbucket.org/durin42/hg-git
[[ -d guestrepo ]] || hg clone https://bitbucket.org/selinc/guestrepo
[[ -d dulwich ]] || git clone https://github.com/jelmer/dulwich.git

cd $HOME

ln -sf $confdir/git-config .gitconfig
ln -sf $confdir/hg/hgrc .hgrc
sudo easy_install pip
sudo pip install --upgrade $confdir/lib/dulwich

# Make sure we have all of the configuration for installation
(cd $confdir && hg grpull -u)

ln -sf $confdir/emacs.d .emacs.d
[[ -z "$EMACS" -o ! -x $EMACS ]] && EMACS=emacs
$EMACS --batch -l .emacs.d/init.el --eval '(my-recompile-init)'

ln -sf $confdir/vim .vim
ln -sf $confdir/vim/vimrc .vimrc
ln -sf .vimrc .gvimrc

ln -sf $confdir/init.lisp .sbclrc
ln -sf $confdir/init.lisp .ccl-init.lisp
cat > $HOME/.config/common-lisp/source-registry.conf.d/00-asdf3.conf << EOF
(:directory "$confdir/lib/asdf3/")
(:directory "$confdir/lib/asdf3/uiop/")
EOF
cat > $HOME/.config/common-lisp/source-registry.conf.d/42-asd-links.conf << EOF
(:directory "$HOME/.asd-links/")
EOF

$confdir/zenburn-for-xcode/install.sh

ln -sf $confdir/zsh/zshrc .zshrc
[[ -d $HOME/bin ]] || mkdir $HOME/bin
ln -sf $confdir/zsh/vcs_info.py $HOME/bin
ln -sf $confdir/zsh/vcs-info.rkt $HOME/bin

[[ -d $HOME/Library/LaunchAgents ]] || mkdir -m 0755 $HOME/Library/LaunchAgents
ln -sf $confdir/com.pitkali.env2launchctl.plist $HOME/Library/LaunchAgents
sudo cp $confdir/env2launchctl /usr/libexec

sudo zsh -c "echo /usr/local/bin | cat - /etc/paths > /etc/paths"
sudo zsh -c "echo /Applications/Racket/bin > /etc/paths.d/Racket"
