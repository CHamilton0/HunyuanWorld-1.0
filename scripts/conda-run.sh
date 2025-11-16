#!/bin/bash
# Conda-aware command wrapper
# This script ensures all commands run in the HunyuanWorld conda environment

# Initialize conda
source /opt/conda/etc/profile.d/conda.sh

# Activate HunyuanWorld environment if it exists
if conda info --envs | grep -q 'HunyuanWorld'; then
    conda activate HunyuanWorld
    export CONDA_DEFAULT_ENV=HunyuanWorld
    export CONDA_PREFIX=/opt/conda/envs/HunyuanWorld
fi

# Set environment variables
export TRANSFORMERS_CACHE="/workspace/cache/transformers"
export HF_HOME="/workspace/cache/huggingface"
export TORCH_HOME="/workspace/cache/torch"
export PYTHONPATH="/workspace/HunyuanWorld-1.0"
export OMP_NUM_THREADS=4
export MKL_NUM_THREADS=4

# Change to project directory
cd /workspace/HunyuanWorld-1.0

# Execute the command
exec "$@"