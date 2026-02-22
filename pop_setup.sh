#!/bin/bash

# --- 1. Style & Initialization ---
green=$(tput setaf 2)
blue=$(tput setaf 4)
reset=$(tput sgr0)

echo "${blue}==== Starting Pop!_OS DE Setup (Chrome + Poetry + Marimo) ====${reset}"

# --- 2. System Refresh ---
echo "${green}Updating system packages...${reset}"
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl gpg wget git ca-certificates

# --- 3. Install Google Chrome ---
if ! command -v google-chrome &> /dev/null; then
    echo "${green}Installing Google Chrome...${reset}"
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt install -y ./google-chrome-stable_current_amd64.deb
    rm google-chrome-stable_current_amd64.deb
else
    echo "${blue}Google Chrome is already installed.${reset}"
fi

# --- 4. Install Poetry (Official Script) ---
if ! command -v poetry &> /dev/null; then
    echo "${green}Installing Poetry...${reset}"
    curl -sSL https://install.python-poetry.org | python3 -
    export PATH="$HOME/.local/bin:$PATH"
else
    echo "${blue}Poetry is already here. Updating...${reset}"
    poetry self update
fi

# --- 5. VS Code (Official Microsoft Repo) ---
if ! command -v code &> /dev/null; then
    echo "${green}Installing VS Code...${reset}"
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f packages.microsoft.gpg
    sudo apt update && sudo apt install -y code
fi

# --- 6. Docker CLI & Engine ---
if ! command -v docker &> /dev/null; then
    echo "${green}Installing Docker...${reset}"
    sudo apt install -y docker.io
    sudo systemctl enable --now docker
    sudo usermod -aG docker $USER
fi

# --- 7. Databricks CLI ---
echo "${green}Installing/Updating Databricks CLI...${reset}"
curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sh

# --- 8. Git & SSH ---
if [ -z "$(git config --global user.name)" ]; then
    read -p "Enter Git Full Name: " git_name
    read -p "Enter Git Email: " git_email
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    git config --global init.defaultBranch main
fi

if [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f ~/.ssh/id_ed25519 -N ""
    echo "${blue}Copy this to GitHub:${reset}"
    cat ~/.ssh/id_ed25519.pub
fi

# --- 9. VS Code Extensions ---
echo "${green}Syncing VS Code Extensions...${reset}"
EXTENSIONS=(
    "ms-python.python"
    "ms-python.vscode-pylance"
    "marimo-team.vscode-marimo"
    "ms-azuretools.vscode-docker"
    "redhat.vscode-yaml"
    "ckotzbauer.databricks"
    "tamasfe.even-better-toml"
)

for ext in "${EXTENSIONS[@]}"; do
    code --install-extension "$ext" --force > /dev/null 2>&1
done

# --- 10. Bashrc Shell Customization ---
if ! grep -q "alias mo=" ~/.bashrc; then
    {
        echo ""
        echo "# Rogue DE Environment"
        echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo "alias mo='marimo edit'"
        echo "alias mor='marimo run'"
        echo "alias p='poetry'"
    } >> ~/.bashrc
fi

# Install Marimo for the user
pip install --user marimo polars

echo "${blue}==== Setup Complete! ====${reset}"
echo "1. Run: source ~/.bashrc"
echo "2. Open Chrome and sign in to sync your data."