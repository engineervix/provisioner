#!/usr/bin/env bash
# Link the server dotfiles into $HOME and fetch the plugins they use.
# cloud-init runs this on first boot. It is safe to re-run.
# It replaces ~/.zshrc, ~/.vimrc and ~/.config/starship.toml with symlinks.
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p ~/.config ~/.zsh/cache ~/.zfunc
ln -sfn "$dir/zshrc" ~/.zshrc
ln -sfn "$dir/vimrc" ~/.vimrc
ln -sfn "$dir/starship.toml" ~/.config/starship.toml

for repo in zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting; do
    name="${repo#*/}"
    [[ -d ~/.zsh/"$name" ]] || git clone --depth=1 "https://github.com/$repo" ~/.zsh/"$name"
done

[[ -f ~/.vim/autoload/plug.vim ]] || curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim -E -s -u ~/.vimrc +PlugInstall +qall
