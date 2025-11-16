#!/bin/bash
# HunyuanWorld Remote Deployment Script
# Usage: ./deploy_remote.sh your-dockerhub-username

set -e

DOCKER_USER=${1:-"your-username"}
IMAGE_NAME="hunyuan-world"

echo "🚀 HunyuanWorld Remote Machine Setup"
echo "===================================="
echo "Docker Hub User: $DOCKER_USER"
echo

# Check for HF_TOKEN
if [[ -z "$HF_TOKEN" ]]; then
    echo "❌ Please set your HuggingFace token first:"
    echo "   export HF_TOKEN='hf_your_token_here'"
    echo "   ./deploy_remote.sh $DOCKER_USER"
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Docker if needed
if ! command_exists docker; then
    echo "📦 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "⚠️  Please log out and log back in, then run this script again"
    exit 0
fi

# Check if user is in docker group
if ! groups $USER | grep -q docker; then
    echo "⚠️  Adding user to docker group..."
    sudo usermod -aG docker $USER
    echo "⚠️  Please log out and log back in, then run this script again"
    exit 0
fi

# Install NVIDIA Container Toolkit
if ! dpkg -l 2>/dev/null | grep -q nvidia-container-toolkit; then
    echo "🎮 Installing NVIDIA Container Toolkit..."
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -fsSL https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
    curl -fsSL https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
    sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
    sudo systemctl restart docker
    sleep 5
fi

# Test GPU access
echo "🔍 Testing GPU access..."
if ! nvidia-smi >/dev/null 2>&1; then
    echo "⚠️  NVIDIA drivers not found. GPU features will not work."
    echo "   Install NVIDIA drivers and try again for GPU support."
else
    echo "✅ GPU detected: $(nvidia-smi --query-gpu=name --format=csv,noheader,nounits | head -n1)"
fi

# Clone or update repository
if [[ ! -d "HunyuanWorld-1.0" ]]; then
    echo "📁 Cloning HunyuanWorld repository..."
    git clone https://github.com/Tencent-Hunyuan/HunyuanWorld-1.0.git
else
    echo "📁 Updating HunyuanWorld repository..."
    cd HunyuanWorld-1.0
    git pull
    cd ..
fi

cd HunyuanWorld-1.0

# Pull Docker image
echo "⬇️  Pulling HunyuanWorld Docker image..."
echo "   This may take 10-30 minutes depending on your internet speed"
docker pull $DOCKER_USER/$IMAGE_NAME:latest

# Tag for local use
docker tag $DOCKER_USER/$IMAGE_NAME:latest $IMAGE_NAME:latest

# Create environment file
echo "🔧 Setting up environment..."
cat > .env << EOF
# HunyuanWorld Environment Configuration
HF_TOKEN=$HF_TOKEN
CUDA_VISIBLE_DEVICES=0
EOF

echo "✅ Environment file created"

# Stop any running containers
echo "🛑 Stopping any existing containers..."
./docker/manage.sh stop 2>/dev/null || true

# Start the container
echo "🚀 Starting HunyuanWorld container..."
./docker/manage.sh start prod

# Wait for container to be ready
echo "⏳ Waiting for container to initialize..."
sleep 10

# Test the setup
echo "🧪 Testing HunyuanWorld setup..."

# Check container is running
if ! docker ps | grep -q hunyuanworld-main; then
    echo "❌ Container failed to start"
    docker logs hunyuanworld-main 2>/dev/null || echo "No logs available"
    exit 1
fi

# Test GPU in container
echo "🔍 Testing GPU access in container..."
if ./docker/manage.sh exec prod "nvidia-smi" >/dev/null 2>&1; then
    GPU_NAME=$(./docker/manage.sh exec prod "nvidia-smi --query-gpu=name --format=csv,noheader,nounits" | head -n1)
    echo "✅ GPU accessible in container: $GPU_NAME"
else
    echo "⚠️  GPU not accessible in container (CPU-only mode)"
fi

# Test authentication
echo "🔐 Testing HuggingFace authentication..."
./docker/manage.sh exec prod '/workspace/setup_auth.sh' || echo "Authentication check completed"

echo
echo "🎉 HunyuanWorld deployment complete!"
echo
echo "📋 Quick Start Commands:"
echo "   Text-to-3D generation:  ./docker/manage.sh demo text"
echo "   Image-to-3D generation: ./docker/manage.sh demo image examples/case2/input.png"
echo "   Container shell:        ./docker/manage.sh shell prod"
echo "   View logs:              ./docker/manage.sh logs"
echo "   Stop container:         ./docker/manage.sh stop"
echo
echo "📚 Documentation:"
echo "   Setup guide:            cat DOCKER_HUB_DEPLOYMENT.md"
echo "   Authentication help:    cat AUTHENTICATION.md"
echo "   Quick setup:            cat QUICK_SETUP.md"
echo