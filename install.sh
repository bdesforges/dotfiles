#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
stow_packages="kitty zsh yazi rofi xfce"

for command_name in git stow; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        printf 'Missing required command: %s\n' "$command_name" >&2
        printf '%s\n' 'Install the Debian prerequisites listed in README.md first.' >&2
        exit 1
    fi
done

printf 'Repository: %s\n' "$repo_root"
printf 'Target:     %s\n' "$HOME"
printf 'Configs:    %s\n' "$stow_packages"
printf '%s\n' 'Checking for conflicts with a GNU Stow dry run...'

# Intentional word splitting of this fixed, reviewed package list.
# shellcheck disable=SC2086
stow --simulate --verbose --no-folding \
    --dir="$repo_root" --target="$HOME" $stow_packages

printf '\nApply these configuration links? [y/N] '
read -r answer
case "$answer" in
    y|Y|yes|YES|Yes) ;;
    *)
        printf '%s\n' 'No changes applied.'
        exit 0
        ;;
esac

clone_dependency() {
    url=$1
    destination=$2

    if [ -d "$destination/.git" ]; then
        printf 'Keeping existing Git dependency: %s\n' "$destination"
        return
    fi
    if [ -e "$destination" ]; then
        printf 'Refusing to replace non-Git path: %s\n' "$destination" >&2
        exit 1
    fi

    mkdir -p "$(dirname -- "$destination")"
    git clone --depth=1 "$url" "$destination"
}

clone_dependency \
    https://github.com/ohmyzsh/ohmyzsh.git \
    "$HOME/.oh-my-zsh"
clone_dependency \
    https://github.com/romkatv/powerlevel10k.git \
    "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
clone_dependency \
    https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
clone_dependency \
    https://github.com/zsh-users/zsh-autosuggestions.git \
    "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"

# Intentional word splitting of this fixed, reviewed package list.
# shellcheck disable=SC2086
stow --verbose --no-folding \
    --dir="$repo_root" --target="$HOME" $stow_packages

printf '%s\n' 'Dotfiles installed.'
