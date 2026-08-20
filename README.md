# Benoit's dotfiles

Shared configuration for my Debian/XFCE computers. The repository keeps the
settings I want to carry from one workstation, laptop, or VM to another:

- Kitty
- Zsh and Powerlevel10k
- Yazi
- Rofi
- selected XFCE panel launchers and Clipman actions

It deliberately does not contain passwords, shell history, browser profiles,
display layouts, or complete machine-specific XFCE sessions.

## Install on a new Debian/XFCE computer

Install the Debian-managed prerequisites:

```sh
sudo apt update
sudo apt install \
  git stow kitty fonts-jetbrains-mono zsh rofi fzf eza bat duf \
  xfce4-clipman xfce4-panel
```

Clone the repository anonymously over HTTPS:

```sh
git clone https://github.com/bdesforges/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

The installer shows a dry run and asks before creating any links. GNU Stow
will stop if an existing configuration file conflicts; it will not overwrite
that file.

Yazi is not currently supplied by the Debian repository used on these
machines. Its configuration will still be installed and will take effect once
Yazi is installed. To use the same Snap package as the current workstation:

```sh
sudo apt install snapd
sudo snap install yazi --classic
```

To make Zsh the login shell after testing it:

```sh
chsh -s "$(command -v zsh)"
```

Log out and back in after changing the login shell.

## How it works

Each top-level application directory mirrors paths under the home directory.
For example, `kitty/.config/kitty/kitty.conf` is linked to
`~/.config/kitty/kitty.conf`. The actual files stay in `~/.dotfiles`, making
changes easy to review and commit with Git.

The installer also clones Oh My Zsh, Powerlevel10k, zsh-syntax-highlighting,
and zsh-autosuggestions directly from their upstream Git repositories. It does
not run downloaded installation scripts.

The XFCE directory contains supporting panel launcher files and Clipman
actions. It does not replace the panel layout, display configuration, power
settings, or saved desktop session on a new computer.

## Update an existing computer

```sh
cd ~/.dotfiles
git pull
./install.sh
```

Changes made through an application are changes to the linked files in this
repository. Review them before committing:

```sh
cd ~/.dotfiles
git status
git diff
```
