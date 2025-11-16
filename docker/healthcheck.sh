#!/bin/bash
# Health check script for HunyuanWorld Docker containers

# Check if conda environment is activated
if [[ "$CONDA_DEFAULT_ENV" != "HunyuanWorld" ]]; then
    echo "ERROR: HunyuanWorld conda environment not activated"
    exit 1
fi

# Check if Python can import required modules
python3 -c "
import sys
try:
    import torch
    import diffusers
    import transformers
    import open3d
    import hy3dworld
    print('SUCCESS: All required modules imported successfully')
    
    # Check CUDA availability
    if torch.cuda.is_available():
        print(f'SUCCESS: CUDA available with {torch.cuda.device_count()} GPU(s)')
        print(f'CUDA Version: {torch.version.cuda}')
        print(f'PyTorch Version: {torch.__version__}')
    else:
        print('WARNING: CUDA not available, using CPU mode')
        
except ImportError as e:
    print(f'ERROR: Failed to import required module: {e}')
    sys.exit(1)
except Exception as e:
    print(f'ERROR: Health check failed: {e}')
    sys.exit(1)
"

if [ $? -eq 0 ]; then
    echo "HEALTH CHECK PASSED"
    exit 0
else
    echo "HEALTH CHECK FAILED"
    exit 1
fi