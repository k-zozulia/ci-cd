#!/bin/bash

# Function to check if a command exists
is_installed() {
    command -v "$1" >/dev/null 2>&1
}

echo "Starting environment setup..."

# 1. Update system packages
echo "Updating package lists..."
sudo apt-get update -y

# 2. Install Docker
if is_installed docker; then
    echo "Docker is already installed: $(docker --version)"
else
    echo "Installing Docker..."
    sudo apt-get install -y ca-certificates curl gnupg lsb-release
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io
fi

# 3. Install Docker Compose
if is_installed docker-compose; then
    echo "Docker Compose is already installed: $(docker-compose --version)"
else
    echo "Installing Docker Compose..."
    sudo apt-get install -y docker-compose-plugin
    sudo ln -sf /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
fi

# 4. Install Python (3.9 or newer)
# Checking if python3 exists and version is >= 3.9
if is_installed python3 && python3 -c 'import sys; exit(0) if sys.version_info >= (3, 9) else exit(1)'; then
    echo "Python 3.9+ is already installed: $(python3 --version)"
else
    echo "Installing Python 3.9 and pip..."
    sudo apt-get install -y python3 python3-pip
fi

# 5. Install Django
if python3 -m django --version >/dev/null 2>&1; then
    echo "Django is already installed: $(python3 -m django --version)"
else
    echo "Installing Django via pip..."
    pip3 install --user django
fi

echo "Setup complete! Please verify the installations above."