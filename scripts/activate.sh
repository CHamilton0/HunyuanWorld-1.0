#!/bin/bash
# HunyuanWorld Environment Activation Script
# Source this file to ensure the conda environment is active

# Initialize conda
source /opt/conda/etc/profile.d/conda.sh

# Activate HunyuanWorld environment
conda activate HunyuanWorld 2>/dev/null || {
    echo "⚠️ HunyuanWorld conda environment not found!"
    echo "Run the startup script first: /workspace/scripts/startup.sh"
    return 1
}

# Set environment variables
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

echo "✅ HunyuanWorld environment activated"
echo "Python: $(which python)"
echo "Environment: $CONDA_DEFAULT_ENV"