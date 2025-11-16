#!/bin/bash

# GPU Setup Script for HunyuanWorld-1.0
# This script configures Docker to work with NVIDIA GPUs

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_color() {
    printf "${1}${2}${NC}\n"
}

print_color $CYAN "🚀 HunyuanWorld GPU Setup Script"
echo "================================="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_color $RED "Don't run this script as root/sudo"
   print_color $YELLOW "Run as regular user - script will prompt for sudo when needed"
   exit 1
fi

# Step 1: Check GPU
print_color $BLUE "1. Checking NVIDIA GPU..."
if command -v nvidia-smi >/dev/null 2>&1; then
    print_color $GREEN "✅ NVIDIA GPU detected:"
    nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader
else
    print_color $RED "❌ No NVIDIA GPU detected"
    print_color $YELLOW "Install NVIDIA drivers first:"
    echo "  sudo apt update && sudo apt install nvidia-driver-535"
    exit 1
fi

# Step 2: Install NVIDIA Container Toolkit if needed
print_color $BLUE "2. Checking NVIDIA Container Toolkit..."
if command -v nvidia-container-runtime >/dev/null 2>&1; then
    print_color $GREEN "✅ NVIDIA Container Toolkit already installed"
else
    print_color $YELLOW "📦 Installing NVIDIA Container Toolkit..."
    
    # Add NVIDIA repository
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    
    # Install
    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit
    
    print_color $GREEN "✅ NVIDIA Container Toolkit installed"
fi

# Step 3: Configure Docker daemon
print_color $BLUE "3. Configuring Docker daemon..."

# Create daemon.json if it doesn't exist
if [ ! -f /etc/docker/daemon.json ]; then
    print_color $YELLOW "Creating /etc/docker/daemon.json..."
    sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
    "runtimes": {
        "nvidia": {
            "path": "nvidia-container-runtime",
            "runtimeArgs": []
        }
    }
}
EOF
else
    print_color $YELLOW "Docker daemon.json exists, checking configuration..."
    if grep -q "nvidia" /etc/docker/daemon.json; then
        print_color $GREEN "✅ NVIDIA runtime already configured"
    else
        print_color $YELLOW "Adding NVIDIA runtime to existing daemon.json..."
        # Backup existing config
        sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.backup
        
        # Add NVIDIA runtime to existing config using a simpler approach
        sudo sed -i 's/^{/{\n  "runtimes": {\n    "nvidia": {\n      "path": "nvidia-container-runtime",\n      "runtimeArgs": []\n    }\n  },/' /etc/docker/daemon.json
    fi
fi

# Step 4: Restart Docker
print_color $BLUE "4. Restarting Docker service..."
sudo systemctl restart docker

# Wait for Docker to start
sleep 5

# Step 5: Test GPU access
print_color $BLUE "5. Testing GPU access..."
if docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi >/dev/null 2>&1; then
    print_color $GREEN "✅ GPU access working!"
    print_color $GREEN "GPU Info:"
    docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
else
    print_color $RED "❌ GPU access still failing"
    print_color $YELLOW "Manual troubleshooting steps:"
    echo "1. Check Docker daemon config: sudo cat /etc/docker/daemon.json"
    echo "2. Check Docker logs: sudo journalctl -u docker.service"
    echo "3. Verify NVIDIA runtime: docker info | grep -i runtime"
    exit 1
fi

# Step 6: Enable GPU in HunyuanWorld
print_color $BLUE "6. Enabling GPU in HunyuanWorld..."

if grep -q "# GPU support (comment out for CPU-only mode)" docker-compose.yml; then
    print_color $YELLOW "Uncommenting GPU sections in docker-compose.yml..."
    
    # Backup docker-compose.yml
    cp docker-compose.yml docker-compose.yml.backup
    
    # Uncomment GPU sections
    sed -i 's/# \(deploy:\)/\1/' docker-compose.yml
    sed -i 's/# \(  resources:\)/\1/' docker-compose.yml
    sed -i 's/# \(    reservations:\)/\1/' docker-compose.yml
    sed -i 's/# \(      devices:\)/\1/' docker-compose.yml
    sed -i 's/# \(        - driver: nvidia\)/\1/' docker-compose.yml
    sed -i 's/# \(          count: 1\)/\1/' docker-compose.yml
    sed -i 's/# \(          capabilities: \[gpu\]\)/\1/' docker-compose.yml
    sed -i 's/# \(- NVIDIA_VISIBLE_DEVICES=all\)/\1/' docker-compose.yml
    sed -i 's/# \(- NVIDIA_DRIVER_CAPABILITIES=compute,utility\)/\1/' docker-compose.yml
    sed -i 's/# \(- CUDA_VISIBLE_DEVICES=0\)/\1/' docker-compose.yml
    
    print_color $GREEN "✅ GPU enabled in docker-compose.yml"
else
    print_color $GREEN "✅ GPU already enabled in docker-compose.yml"
fi

print_color $GREEN "🎉 GPU Setup Complete!"
echo
print_color $CYAN "Next Steps:"
echo "1. Test GPU: ./docker/manage.sh gpu"
echo "2. Start container: ./docker/manage.sh start"
echo "3. Run generation: ./docker/manage.sh demo text"
echo
print_color $BLUE "Your RTX 3050 (8GB) is perfect for HunyuanWorld generation!"
print_color $YELLOW "Use --fp8_attention --fp8_gemm flags for memory optimization"