#!/bin/bash

# HunyuanWorld-1.0 Docker Build Script with Compatibility Fixes
set -e

echo "🌍 Building HunyuanWorld-1.0 Docker Environment"
echo "================================================"
echo ""
echo "🔧 Key Improvements Applied:"
echo "   ✅ NumPy 1.26.4 locked for PyTorch 2.1.2 compatibility"
echo "   ✅ FluxIPAdapterMixin → IPAdapterMixin compatibility fix"
echo "   ✅ Real-ESRGAN integration for image super-resolution"
echo "   ✅ ZIM integration for zero-shot image matting"
echo "   ✅ Draco 3D mesh compression support"
echo "   ✅ FP8 quantization optimization support"
echo "   ✅ Runtime NumPy validation and auto-repair"
echo "   ✅ HuggingFace FLUX model authentication"
echo ""

# Check system requirements
echo "🔍 Checking system requirements..."

# Check Docker
if ! command -v docker >/dev/null 2>&1; then
    echo "❌ Docker not found. Please install Docker first."
    exit 1
fi

# Check NVIDIA Docker (optional but recommended)
if command -v nvidia-smi >/dev/null 2>&1; then
    echo "✅ NVIDIA GPU detected"
    if docker run --rm --gpus all nvidia/cuda:12.4-base-ubuntu22.04 nvidia-smi >/dev/null 2>&1; then
        echo "✅ NVIDIA Docker runtime working"
    else
        echo "⚠️  NVIDIA Docker runtime may need configuration"
        echo "   Run: sudo apt-get install nvidia-container-toolkit"
    fi
else
    echo "⚠️  No NVIDIA GPU detected - CPU-only mode will be very slow"
fi

# Check available disk space
AVAILABLE_SPACE=$(df /var/lib/docker --output=avail | tail -n1)
if [ "$AVAILABLE_SPACE" -lt 20000000 ]; then
    echo "⚠️  Less than 20GB available in /var/lib/docker"
    echo "   HunyuanWorld-1.0 Docker image will be ~10-15GB"
fi

echo ""
echo "🚀 Starting build process (estimated time: 15-30 minutes)..."
echo "   This will download and install:"
echo "   - CUDA 12.4 development environment (~2GB)"
echo "   - Miniconda with PyTorch 2.1.2 ecosystem (~3GB)"
echo "   - HunyuanWorld-1.0 dependencies (~2GB)"
echo "   - Real-ESRGAN, ZIM, and 3D processing tools (~1GB)"
echo ""

# Build the Docker image with progress
echo "📦 Building hunyuanworld:latest..."
docker build \
    --progress=plain \
    --tag hunyuanworld:latest \
    --file Dockerfile \
    .

BUILD_STATUS=$?

if [ $BUILD_STATUS -eq 0 ]; then
    echo ""
    echo "🎉 HunyuanWorld-1.0 Docker build completed successfully!"
    echo ""
    
    # Get image size
    IMAGE_SIZE=$(docker images hunyuanworld:latest --format "table {{.Size}}" | tail -n +2)
    echo "📊 Image size: $IMAGE_SIZE"
    echo ""
    
    echo "🧪 Testing the built image..."
    echo ""
    
    # Test basic functionality
    echo "   Testing Python environment..."
    docker run --rm hunyuanworld:latest python -c "
import sys
print(f'✅ Python {sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}')
"
    
    echo "   Testing NumPy compatibility..."
    docker run --rm hunyuanworld:latest python -c "
import numpy
print(f'✅ NumPy {numpy.__version__}')
"
    
    echo "   Testing PyTorch..."
    docker run --rm hunyuanworld:latest python -c "
import torch
print(f'✅ PyTorch {torch.__version__}')
print(f'✅ CUDA available: {torch.cuda.is_available()}')
"
    
    echo "   Testing HunyuanWorld imports..."
    docker run --rm hunyuanworld:latest python -c "
try:
    from hy3dworld.models.pano_generator import Text2PanoramaPipelines
    print('✅ HunyuanWorld panorama generation ready')
except Exception as e:
    print(f'⚠️  Import issue: {e}')

try:
    from hy3dworld.models.layer_decomposer import LayerDecomposition
    print('✅ HunyuanWorld layer decomposition ready')
except Exception as e:
    print(f'⚠️  Import issue: {e}')

try:
    from hy3dworld.models.world_composer import WorldComposer
    print('✅ HunyuanWorld 3D composition ready')
except Exception as e:
    print(f'⚠️  Import issue: {e}')
" || echo "⚠️  Some components may need HuggingFace authentication"

    echo ""
    echo "🎯 Quick Start Commands:"
    echo ""
    echo "📋 Interactive shell:"
    echo "   docker run --rm -it --gpus all \\"
    echo "     -v \$(pwd)/outputs:/workspace/outputs \\"
    echo "     hunyuanworld:latest bash"
    echo ""
    echo "🌋 Text-to-3D world generation:"
    echo "   export HF_TOKEN=\"your_huggingface_token\""
    echo "   docker run --rm --gpus all \\"
    echo "     -e HF_TOKEN=\$HF_TOKEN \\"
    echo "     -v \$(pwd)/outputs:/workspace/outputs \\"
    echo "     hunyuanworld:latest \\"
    echo "     python demo_panogen.py --prompt \"volcanic landscape\" \\"
    echo "       --output_path /workspace/outputs/volcano \\"
    echo "       --fp8_attention --fp8_gemm --cache"
    echo ""
    echo "🏔️  Complete pipeline (panorama + 3D scene):"
    echo "   docker run --rm --gpus all \\"
    echo "     -e HF_TOKEN=\$HF_TOKEN \\"
    echo "     -v \$(pwd)/outputs:/workspace/outputs \\"
    echo "     hunyuanworld:latest bash -c \""
    echo "     python demo_panogen.py --prompt 'mountain vista' --output_path /workspace/outputs/mountain --fp8_attention --fp8_gemm && \\"
    echo "     python demo_scenegen.py --image_path /workspace/outputs/mountain/panorama.png --classes outdoor --output_path /workspace/outputs/mountain\""
    echo ""
    echo "💡 Pro Tips:"
    echo "   - Get HF token: https://huggingface.co/settings/tokens"
    echo "   - Request FLUX access: https://huggingface.co/black-forest-labs/FLUX.1-dev"
    echo "   - Use --fp8_attention --fp8_gemm for RTX 4090/consumer GPUs"
    echo "   - View results in modelviewer.html for 3D exploration"
    echo ""

else
    echo ""
    echo "❌ Build failed with exit code $BUILD_STATUS"
    echo ""
    echo "🔧 Common solutions:"
    echo "   1. Check available disk space (need 20GB+)"
    echo "   2. Check internet connection for package downloads"
    echo "   3. Try: docker system prune -f && ./build-fixed.sh"
    echo "   4. Check Docker daemon is running: sudo systemctl status docker"
    echo ""
    exit $BUILD_STATUS
fi