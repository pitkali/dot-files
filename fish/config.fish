/home/linuxbrew/.linuxbrew/bin/brew shellenv | source

fish_add_path $HOME/bin $HOME/.cargo/bin

set -gx VISUAL "nvim -f"
set -gx EDITOR $VISUAL
set -gx LESS RSFX
set -gx PAGER less
set -gx HOMEBREW_NO_ENV_HINTS 1
set -gx GTK_IM_MODULE ibus

umask 022

if status is-interactive
  abbr -a -- lg lazygit
end
