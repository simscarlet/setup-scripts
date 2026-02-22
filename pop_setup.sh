#!/bin/bash

# --- 1. Setup Environment ---
green=$(tput setaf 2)
blue=$(tput setaf 4)
reset=$(tput sgr0)

echo "${blue}==== Starting Rogue Data Engineering Setup ====${reset}"

# --- 2. System Base & Updates ---
echo "${green}Updating system packages...${reset}"
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl gpg wget git python3-pip python3-venv ca-certificates

# --- 3. Install Poetry (Official Script) ---
if ! command -v poetry &> /dev/null; then
    echo "${green}Installing Poetry...${reset}"
    curl -sSL https://install.python-poetry.org | python3 -
    export PATH="$HOME/.local/bin:$PATH"
else
    echo "${blue}Poetry is already here. Updating...${reset}"
    poetry self update
fi

# --- 4. Install VS Code (Official Repo) ---
if ! command -v code &> /dev/null; then
    echo "${green}Installing VS Code...${reset}"
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f packages.microsoft.gpg
    sudo apt update && sudo apt install -y code
fi

# --- 5. Install Docker ---
if ! command -v docker &> /dev/null; then
    echo "${green}Installing Docker...${reset}"
    sudo apt install -y docker.io
    sudo systemctl enable --now docker
    sudo usermod -aG docker $USER
fi

# --- 6. Databricks CLI ---
echo "${green}Installing/Updating Databricks CLI...${reset}"
curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sh

# --- 7. Git & SSH ---
if [ -z "$(git config --global user.name)" ]; then
    read -p "Enter Git Full Name: " git_name
    read -p "Enter Git Email: " git_email
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    git config --global init.defaultBranch main
fi

if [ ! -f ~/.ssh/id_ed25519 ]; then
    ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f ~/.ssh/id_ed25519 -N ""
    echo "${blue}New SSH Key:${reset}"
    cat ~/.ssh/id_ed25519.pub
fi

# --- 8. VS Code Extensions (Marimo & DE focus) ---
echo "${green}Installing VS Code Extensions...${reset}"
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

# --- 9. Persist Path & Aliases ---
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

# Final check for marimo (via pip since we aren't using uv)
pip install --user marimo polars

echo "${blue}==== Setup Complete. Run 'source ~/.bashrc' and restart your session. ====${reset}"