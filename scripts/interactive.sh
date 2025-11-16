#!/bin/bash
# HunyuanWorld Interactive Setup Script
# This script provides a comprehensive setup for interactive use

echo "🌍 HunyuanWorld Interactive Setup"
echo "================================="

# Initialize conda properly
source /opt/conda/etc/profile.d/conda.sh

# Check if HunyuanWorld environment exists
if ! conda info --envs | grep -q 'HunyuanWorld'; then
    echo "❌ HunyuanWorld environment not found!"
    echo "Run the setup first: /workspace/scripts/startup.sh"
    exit 1
fi

# Activate the environment
conda activate HunyuanWorld

# Export environment variables
export CONDA_DEFAULT_ENV=HunyuanWorld
export CONDA_PREFIX=/opt/conda/envs/HunyuanWorld
export TRANSFORMERS_CACHE="/workspace/cache/transformers"
export HF_HOME="/workspace/cache/huggingface"
export TORCH_HOME="/workspace/cache/torch"
export PYTHONPATH="/workspace/HunyuanWorld-1.0"
export OMP_NUM_THREADS=4
export MKL_NUM_THREADS=4

# Change to project directory
cd /workspace/HunyuanWorld-1.0

# Test the environment
echo ""
echo "🧪 Testing environment..."
echo "Python: $(which python)"
echo "Conda env: $CONDA_DEFAULT_ENV"

# Test PyTorch import
if python -c "import torch; print(f'✅ PyTorch {torch.__version__} available')" 2>/dev/null; then
    echo "✅ Environment ready!"
else
    echo "❌ Environment setup incomplete. Run /workspace/scripts/startup.sh first"
    exit 1
fi

echo ""
echo "🚀 Ready to use HunyuanWorld!"
echo ""
echo "Usage examples:"
echo "  python demo_panogen.py --prompt 'forest scene' --output_path outputs/forest --fp8_attention --fp8_gemm"
echo "  python demo_scenegen.py --image_path outputs/forest/panorama.png --classes outdoor --output_path outputs/forest"
echo ""

# Start an interactive shell with the environment active
exec bash --rcfile <(echo "
# Custom bash profile for HunyuanWorld
source /opt/conda/etc/profile.d/conda.sh
conda activate HunyuanWorld 2>/dev/null || true
export TRANSFORMERS_CACHE='/workspace/cache/transformers'
export HF_HOME='/workspace/cache/huggingface'
export TORCH_HOME='/workspace/cache/torch'
export PYTHONPATH='/workspace/HunyuanWorld-1.0'
export OMP_NUM_THREADS=4
export MKL_NUM_THREADS=4
cd /workspace/HunyuanWorld-1.0
echo '🌍 HunyuanWorld environment active - Python: \$(which python)'
")
