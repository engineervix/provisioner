#!/usr/bin/env bash
# Link the server dotfiles into $HOME, and install or update the plugins they use.
# cloud-init runs this on first boot, and cron runs it weekly to update everything.
# It is safe to re-run. It replaces ~/.zshrc, ~/.vimrc and ~/.config/starship.toml with symlinks.
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p ~/.config ~/.cache ~/.zsh/cache ~/.zfunc
ln -sfn "$dir/zshrc" ~/.zshrc
ln -sfn "$dir/vimrc" ~/.vimrc
ln -sfn "$dir/starship.toml" ~/.config/starship.toml

for repo in zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting; do
    name="${repo#*/}"
    if [[ -d ~/.zsh/"$name" ]]; then
        git -C ~/.zsh/"$name" pull --ff-only --quiet
    else
        git clone --depth=1 "https://github.com/$repo" ~/.zsh/"$name"
    fi
done

[[ -f ~/.vim/autoload/plug.vim ]] || curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim -E -s -u ~/.vimrc +PlugUpgrade +PlugUpdate +qall

# Run weekly from the user's crontab: pull this repo, then re-run the new install.sh.
# Output of the last run: ~/.cache/dotfiles-update.log
job="@weekly (git -C ${dir%/*} pull --ff-only --quiet && $dir/install.sh) >\$HOME/.cache/dotfiles-update.log 2>&1"
current=$(crontab -l 2>/dev/null || true)
[[ $current == *"$dir/install.sh"* ]] || printf '%s\n' ${current:+"$current"} "$job" | crontab -
