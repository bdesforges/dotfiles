#!/bin/sh
# Give the root account the same Zsh configuration as the regular user.
#
# Usage (from the regular user's clone):   sudo ./install-root.sh
#
# It links root's ~/.zshrc and ~/.p10k.zsh to this repository, gives root its
# own oh-my-zsh checkout with the theme and plugins the shared .zshrc expects,
# and makes zsh root's login shell. Like install.sh, it shows what it will do
# and asks once; existing files in the way are deleted (no backup) on 'y'.
# Safe to re-run; it only reports what is already in place.
#
# For testing, a target home directory can be passed as the first argument.
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
target_home=${1:-$(getent passwd root | cut -d: -f6)}

if [ -z "${1:-}" ] && [ "$(id -u)" -ne 0 ]; then
    printf '%s\n' 'Run this with sudo: it writes to root'\''s home directory.' >&2
    exit 1
fi
for command_name in git zsh; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        printf 'Missing required command: %s\n' "$command_name" >&2
        exit 1
    fi
done

printf 'Repository: %s\n' "$repo_root"
printf 'Target:     %s\n' "$target_home"

is_linked() {
    [ -L "$2" ] && [ "$(readlink -f -- "$2")" = "$(readlink -f -- "$1")" ]
}

# Show the plan first; collect existing files that would have to go.
conflicts=""
plan_link() {
    if is_linked "$1" "$2"; then
        printf 'Present  %s -> %s\n' "$2" "$1"
    elif [ -e "$2" ] || [ -L "$2" ]; then
        printf 'Replace  %s -> %s\n' "$2" "$1"
        conflicts="$conflicts$2
"
    else
        printf 'Link     %s -> %s\n' "$2" "$1"
    fi
}

plan_link "$repo_root/zsh/.zshrc" "$target_home/.zshrc"
plan_link "$repo_root/zsh/.p10k.zsh" "$target_home/.p10k.zsh"

if [ -n "$conflicts" ]; then
    printf '\n%s\n' 'These existing files will be DELETED and replaced by links (no backup):'
    printf '%s' "$conflicts" | sed 's/^/  /'
    printf '\nDelete them and apply the configuration links? [y/N] '
else
    printf '\nApply these configuration links? [y/N] '
fi
read -r answer
case "$answer" in
    y|Y|yes|YES|Yes) ;;
    *)
        printf '%s\n' 'No changes applied.'
        exit 0
        ;;
esac

mkdir -p -- "$target_home"

clone_if_missing() {
    if [ -d "$2/.git" ]; then
        printf 'Present  %s\n' "$2"
    else
        git clone --quiet --depth 1 -- "$1" "$2"
        printf 'Cloned   %s\n' "$2"
    fi
}

link_file() {
    if is_linked "$1" "$2"; then
        return
    fi
    if [ -e "$2" ] || [ -L "$2" ]; then
        rm -f -- "$2"
        printf 'Deleted  %s\n' "$2"
    fi
    ln -s -- "$1" "$2"
    printf 'Linked   %s -> %s\n' "$2" "$1"
}

omz="$target_home/.oh-my-zsh"
clone_if_missing https://github.com/ohmyzsh/ohmyzsh.git "$omz"
clone_if_missing https://github.com/romkatv/powerlevel10k.git "$omz/custom/themes/powerlevel10k"
clone_if_missing https://github.com/zsh-users/zsh-autosuggestions.git "$omz/custom/plugins/zsh-autosuggestions"
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting.git "$omz/custom/plugins/zsh-syntax-highlighting"

link_file "$repo_root/zsh/.zshrc" "$target_home/.zshrc"
link_file "$repo_root/zsh/.p10k.zsh" "$target_home/.p10k.zsh"

if [ -z "${1:-}" ]; then
    zsh_path=$(command -v zsh)
    if [ "$(getent passwd root | cut -d: -f7)" != "$zsh_path" ]; then
        chsh -s "$zsh_path" root
        printf 'Shell    root login shell set to %s\n' "$zsh_path"
    else
        printf 'Present  root login shell is %s\n' "$zsh_path"
    fi
fi

printf 'Checking that the configuration loads...\n'
HOME=$target_home zsh -ilc 'printf "OK       zsh %s, theme %s, plugins: %s\n" "$ZSH_VERSION" "$ZSH_THEME" "${plugins[*]}"' </dev/null
