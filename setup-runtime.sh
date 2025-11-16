#!/bin/bash
# Quick setup script for HunyuanWorld runtime environment

set -e

echo "🌍 HunyuanWorld Runtime Environment Setup"
echo "========================================="

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose >/dev/null 2>&1; then
    echo "❌ docker-compose is not installed. Please install it and try again."
    exit 1
fi

# Check if NVIDIA Docker runtime is available (optional)
if docker run --rm --gpus all nvidia/cuda:12.4.0-runtime-ubuntu22.04 nvidia-smi >/dev/null 2>&1; then
    echo "✅ NVIDIA Docker runtime detected"
else
    echo "⚠️ NVIDIA Docker runtime not detected. GPU acceleration may not work."
fi

# Build the minimal runtime image
echo ""
echo "🔨 Building minimal runtime image..."
docker build -f Dockerfile.minimal -t hunyuanworld:minimal .

# Create and start the container
echo ""
echo "🚀 Starting HunyuanWorld runtime container..."
docker-compose -f docker-compose.runtime.yml up -d

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Enter the container:"
echo "   docker-compose -f docker-compose.runtime.yml exec hunyuanworld-runtime bash"
echo ""
echo "2. The startup script will automatically:"
echo "   • Create the conda environment"
echo "   • Install all Python dependencies"
echo "   • Download and set up external tools"
echo "   • Apply compatibility fixes"
echo ""
echo "3. Generate your first 3D world:"
echo "   python demo_panogen.py --prompt 'forest scene' --output_path outputs/forest --fp8_attention --fp8_gemm"
echo "   python demo_scenegen.py --image_path outputs/forest/panorama.png --classes outdoor --output_path outputs/forest"
echo ""
echo "💡 Tips:"
echo "   • The first run will take longer as it downloads dependencies"
echo "   • Subsequent runs will be much faster due to persistent volumes"
echo "   • Edit scripts/startup.sh to customize the setup process"
echo "   • Use --cache flag for faster inference"