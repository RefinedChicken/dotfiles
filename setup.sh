#! /bin/bash

# Update system
echo "Updating the system..."
apt update
apt upgrade -y

# Install apt packages
echo "Installing apt packages..."
apt install -y curl wget git gh neovim fastfetch zoxide zsh bat tree unzip btop fzf net-tools gpg

# Install eza
mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list
chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
apt update
apt install -y eza

# Initializing zsh
chsh -s $(which zsh)

# Install Tailscale
echo "Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

# Install Oh My Posh
echo "Installing Oh My Posh..."
curl -s https://ohmyposh.dev/install.sh | bash -s

# GitHub CLI login
echo "Please follow the instructions to login to GitHub CLI tool."
gh auth login

# Git global config
echo "Configuring git credentials"
read -p "Enter your Git username: " user_input && git config --global user.name "$user_input"
read -p "Enter your Git email: " user_input && git config --global user.email "$user_input"

# Install fzf
echo "Installing fzf from GitHub..."
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# Setting up dotfile symlinks
cd $HOME
echo "Cloning dotfiles repo..."
gh repo clone RefinedChicken/dotfiles
echo "Deleting any conflicting dotfiles..."
rm -f $HOME/.zshrc
[ ! -d "$HOME/.config" ] && mkdir -p "$HOME/.config"
[ ! -d "$HOME/.config/ohmyposh" ] && mkdir -p "$HOME/.config/ohmyposh"
echo "Creating symlinks to dotfiles..."
ln -s $HOME/dotfiles/zsh/.zshrc $HOME/.zshrc
ln -s $HOME/dotfiles/ohmyposh/zen.toml $HOME/.config/ohmyposh/zen.toml

# Niceities
touch $HOME/.hushlogin

# Now Tailscale setup works maybe?
echo "Attemting to set up Tailscale automatically..."
tailscale up

# Success message
echo "Setup completed successfully. Rebooting..."
sleep 5
reboot
