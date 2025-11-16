#!/bin/bash

# HunyuanWorld-1.0 Quick Start Script
set -e

echo "🌍 HunyuanWorld-1.0 Quick Start"
echo "================================"
echo ""

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Check if NVIDIA Docker is available
if ! docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi >/dev/null 2>&1; then
    echo "⚠️  Warning: NVIDIA Docker runtime not available. Running in CPU mode."
    echo "For GPU acceleration, install nvidia-container-toolkit"
    GPU_FLAG=""
else
    echo "✅ NVIDIA Docker runtime detected"
    GPU_FLAG="--gpus all"
fi

# Check for HuggingFace token
if [[ -z "$HF_TOKEN" ]]; then
    echo ""
    echo "⚠️  HF_TOKEN environment variable not set."
    echo "You'll need to authenticate with HuggingFace manually in the container."
    echo "Get your token from: https://huggingface.co/settings/tokens"
    echo ""
    echo "To set it permanently:"
    echo "  export HF_TOKEN='your_token_here'"
    echo "  echo 'export HF_TOKEN=\"your_token_here\"' >> ~/.bashrc"
    echo ""
fi

# Build if image doesn't exist
if ! docker image inspect hunyuanworld:latest >/dev/null 2>&1; then
    echo "📦 Building HunyuanWorld Docker image (this may take a while)..."
    docker compose build hunyuanworld
fi

# Start the container
echo "🚀 Starting HunyuanWorld container..."
docker compose up -d hunyuanworld

# Wait for container to be ready
sleep 2

echo ""
echo "✅ HunyuanWorld is ready!"
echo ""
echo "📋 Usage Examples:"
echo ""
echo "1. Text to Panorama:"
echo "   docker compose exec hunyuanworld python demo_panogen.py --prompt 'a beautiful mountain landscape' --output_path /workspace/outputs/mountain"
echo ""
echo "2. Image to Panorama:"
echo "   docker compose exec hunyuanworld python demo_panogen.py --image_path examples/case1/input.png --output_path /workspace/outputs/case1"
echo ""
echo "3. Generate 3D Scene:"
echo "   docker compose exec hunyuanworld python demo_scenegen.py --image_path /workspace/outputs/mountain/panorama.png --output_path /workspace/outputs/mountain"
echo ""
echo "4. Interactive shell:"
echo "   docker compose exec hunyuanworld bash"
echo ""
echo "🚀 Performance flags (add to any command):"
echo "   --fp8_attention --fp8_gemm --cache"
echo ""
echo "📁 Outputs are saved to: $(pwd)/outputs"
echo ""

# If HF_TOKEN is not set, offer to help set it up
if [[ -z "$HF_TOKEN" ]]; then
    read -p "Would you like to authenticate with HuggingFace now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🔐 Setting up HuggingFace authentication..."
        docker compose exec hunyuanworld bash -c "source /workspace/activate.sh && huggingface-cli login"
    fi
fi

echo ""
echo "🎉 Ready to generate 3D worlds!"