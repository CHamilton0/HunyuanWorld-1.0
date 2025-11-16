#!/bin/bash
# Build Volume-Optimized HunyuanWorld Docker Image
# This creates a much smaller image by using volumes for large dependencies

set -e

echo "🌍 Building Volume-Optimized HunyuanWorld Docker Image..."
echo "============================================================="

# Initialize volume directories
echo "📁 Initializing volume directories..."
./manage_volumes.sh init

# Build the optimized image
echo "🔨 Building Docker image..."
docker build -f Dockerfile.volume-optimized -t hunyuanworld:volume-optimized .

# Show image sizes for comparison
echo ""
echo "📊 Image Size Comparison:"
echo "========================="
docker images | grep hunyuanworld | head -5

echo ""
echo "✅ Volume-optimized build complete!"
echo ""
echo "🚀 Quick Start:"
echo "  # Start the container:"
echo "  docker-compose -f docker-compose.volume-optimized.yml up hunyuanworld-volume"
echo ""
echo "  # Or run directly:"
echo "  docker run --rm --gpus all -v \$(pwd)/docker_volumes/venv:/workspace/venv -v \$(pwd)/docker_volumes/cache:/workspace/cache -v \$(pwd)/docker_volumes/external_tools:/workspace/external_tools -v \$(pwd)/docker_volumes/outputs:/workspace/outputs hunyuanworld:volume-optimized"
echo ""
echo "💡 Benefits of this approach:"
echo "  - Smaller image size (~1-3GB vs 15-30GB)"
echo "  - Faster builds (dependencies cached in volumes)"
echo "  - Persistent model downloads"
echo "  - Easy development workflow"