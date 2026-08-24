#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
stow_packages="kitty zsh yazi rofi xfce nvim"

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
run_stow() {
    # Intentional word splitting of this fixed, reviewed package list.
    # shellcheck disable=SC2086
    stow "$@" --no-folding --dir="$repo_root" --target="$HOME" $stow_packages
}

printf '%s\n' 'Checking for conflicts with a GNU Stow dry run...'
set +e
dry_run=$(run_stow --simulate --verbose 2>&1)
dry_run_status=$?
set -e
printf '%s\n' "$dry_run"

conflicts=""
if [ "$dry_run_status" -ne 0 ]; then
    # Stow reports a conflicting file as one of:
    #   cannot stow X over existing target Y since neither a link nor ...
    #   existing target is not owned by stow: Y
    #   existing target is stowed to a different package: Y => Z
    conflicts=$(printf '%s\n' "$dry_run" | sed -n \
        -e 's/.*existing target \([^ ]*\) since .*/\1/p' \
        -e 's/.*existing target is [^:]*: \([^ ]*\).*/\1/p' | sort -u)
    if [ -z "$conflicts" ]; then
        printf '%s\n' 'Stow dry run failed for a reason other than file conflicts; see above.' >&2
        exit 1
    fi
    printf '\n%s\n' 'These existing files will be DELETED and replaced by links (no backup):'
    printf '%s\n' "$conflicts" | sed 's/^/  /'
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

if [ -n "$conflicts" ]; then
    printf '%s\n' "$conflicts" | while IFS= read -r relative_path; do
        rm -f -- "$HOME/$relative_path"
    done
fi

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

run_stow --verbose

printf '%s\n' 'Dotfiles installed.'
