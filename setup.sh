#!/usr/bin/env bash
#
# setup.sh — personal environment bootstrap (Linux + macOS)
# Run as your normal user (with sudo privileges) — NOT as root.

set -euo pipefail

OS="$(uname -s)"
if [[ "$OS" != "Linux" && "$OS" != "Darwin" ]]; then
    echo "Unsupported OS: $OS" >&2
    exit 1
fi

# ---------- helpers ----------

log() {
    printf '\n\033[1;36m==> %s\033[0m\n' "$1"
}

require_non_root() {
    if [[ "$EUID" -eq 0 ]]; then
        echo "Please run this script as your normal user (with sudo privileges), not as root." >&2
        echo "Running as root would install dotfiles/configs into /root instead of your home directory." >&2
        exit 1
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ---------- steps ----------

update_system() {
    case "$OS" in
        Linux)
            log "Updating the system"
            sudo apt update
            sudo apt upgrade -y
            ;;
        Darwin)
            if ! command_exists brew; then
                log "Installing Homebrew"
                NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            if [[ -x /opt/homebrew/bin/brew ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [[ -x /usr/local/bin/brew ]]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
            log "Updating Homebrew"
            brew update
            brew upgrade
            ;;
    esac
}

install_packages() {
    case "$OS" in
        Linux)
            log "Installing apt packages"
            local packages=(
                curl wget git neovim fastfetch zoxide zsh
                bat tree unzip btop fzf net-tools gpg
            )
            sudo apt install -y "${packages[@]}"
            ;;
        Darwin)
            log "Installing Homebrew packages"
            local packages=(git neovim fastfetch zoxide tree btop fzf yazi)
            brew install "${packages[@]}"
            ;;
    esac
}

install_eza() {
    if command_exists eza; then
        log "eza already installed, skipping"
        return
    fi
    log "Installing eza"
    case "$OS" in
        Linux)
            sudo mkdir -p /etc/apt/keyrings
            wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
                | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
            echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
                | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
            sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
            sudo apt update
            sudo apt install -y eza
            ;;
        Darwin)
            brew install eza
            ;;
    esac
}

install_ghostty() {
    [[ "$OS" != "Darwin" ]] && return
    if command_exists ghostty; then
        log "Ghostty already installed, skipping"
        return
    fi
    log "Installing Ghostty"
    brew install --cask ghostty
}

setup_shell() {
    local zsh_path current_shell
    zsh_path="$(command -v zsh)"

    case "$OS" in
        Linux)
            current_shell="$(getent passwd "$USER" | cut -d: -f7)"
            ;;
        Darwin)
            current_shell="$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')"
            ;;
    esac

    if [[ "$current_shell" == "$zsh_path" ]]; then
        log "Default shell already zsh, skipping"
        return
    fi
    log "Setting default shell to zsh"
    chsh -s "$zsh_path"
}

install_tailscale() {
    if command_exists tailscale; then
        log "Tailscale already installed, skipping"
        return
    fi
    log "Installing Tailscale"
    case "$OS" in
        Linux)
            curl -fsSL https://tailscale.com/install.sh | sh
            ;;
        Darwin)
            brew install tailscale
            sudo brew services start tailscale
            ;;
    esac
}

install_ohmyposh() {
    if command_exists oh-my-posh; then
        log "Oh My Posh already installed, skipping"
        return
    fi
    log "Installing Oh My Posh"
    case "$OS" in
        Linux)
            curl -s https://ohmyposh.dev/install.sh | bash -s
            ;;
        Darwin)
            brew install oh-my-posh
            ;;
    esac
}

setup_github_ssh() {
    log "Setting up SSH access to GitHub"
    local ssh_key="$HOME/.ssh/id_ed25519"

    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    # Pre-trust GitHub's host key so clones don't hang on a host-authenticity prompt
    if ! ssh-keygen -F github.com -f "$HOME/.ssh/known_hosts" >/dev/null 2>&1; then
        ssh-keyscan -t ed25519 github.com >>"$HOME/.ssh/known_hosts" 2>/dev/null
    fi

    if [[ ! -f "$ssh_key" ]]; then
        echo
        echo "No SSH key found at $ssh_key."
        echo "Paste your private key below, then press Ctrl+D when done:"
        echo
        cat >"$ssh_key"
        chmod 600 "$ssh_key"

        if ! ssh-keygen -y -f "$ssh_key" >"${ssh_key}.pub" 2>/dev/null; then
            echo "Warning: couldn't derive a public key from that paste — check it was complete and correct." >&2
        fi
        chmod 644 "${ssh_key}.pub" 2>/dev/null || true
    fi

    eval "$(ssh-agent -s)" >/dev/null
    ssh-add "$ssh_key" >/dev/null 2>&1

    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        log "GitHub SSH authentication confirmed"
    else
        echo "Warning: could not confirm SSH authentication with GitHub." >&2
        echo "Double check the key is registered at https://github.com/settings/keys" >&2
    fi
}

configure_git() {
    log "Configuring git identity"
    git config --global user.name "RefinedChicken"
    git config --global user.email "imall4him06@gmail.com"
}

setup_dotfiles() {
    log "Setting up dotfiles"
    cd "$HOME"

    if [[ -d "$HOME/dotfiles" ]]; then
        echo "dotfiles repo already present, pulling latest"
        git -C "$HOME/dotfiles" pull
    else
        git clone git@github.com:RefinedChicken/dotfiles.git "$HOME/dotfiles"
    fi

    if [[ -e "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
        echo "Backing up existing .zshrc to .zshrc.bak"
        mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
    elif [[ -L "$HOME/.zshrc" ]]; then
        rm -f "$HOME/.zshrc"
    fi

    mkdir -p "$HOME/.config/ohmyposh"

    case "$OS" in
        Linux)
            ln -sf "$HOME/dotfiles/zsh/.zshrc" "$HOME/.zshrc"
            ln -sf "$HOME/dotfiles/ohmyposh/zen.toml" "$HOME/.config/ohmyposh/zen.toml"
            ;;
        Darwin)
            mkdir -p "$HOME/.config/ghostty"
            ln -sf "$HOME/dotfiles/macos/zsh/.zshrc" "$HOME/.zshrc"
            ln -sf "$HOME/dotfiles/macos/ohmyposh/joray.omp.json" "$HOME/.config/ohmyposh/joray.omp.json"
            ln -sf "$HOME/dotfiles/macos/ghostty/config.ghostty" "$HOME/.config/ghostty/config.ghostty"
            ;;
    esac
}

finalize() {
    log "Final touches"
    touch "$HOME/.hushlogin"

    log "Setting up Tailscale"
    sudo tailscale up

    log "Setup complete"
    read -rp "Reboot now? [y/N] " reboot_confirm
    if [[ "$reboot_confirm" =~ ^[Yy]$ ]]; then
        sudo reboot
    else
        echo "Skipping reboot. Run 'exec zsh' or re-login to pick up your new shell."
    fi
}

main() {
    require_non_root
    update_system
    install_packages
    install_eza
    install_ghostty
    setup_shell
    install_tailscale
    install_ohmyposh
    setup_github_ssh
    configure_git
    setup_dotfiles
    finalize
}

main "$@"
