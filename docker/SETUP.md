# HunyuanWorld Docker Quick Setup Guide

## Option 1: One-Click Setup (Recommended)

```bash
# Clone the repository
git clone https://github.com/Tencent-Hunyuan/HunyuanWorld-1.0.git
cd HunyuanWorld-1.0

# Use the management script for easy setup
./docker/manage.sh build all
./docker/manage.sh up prod

# Run a quick demo
./docker/manage.sh demo text
```

## Option 2: Manual Docker Compose

```bash
# Build and start production environment
docker-compose build hunyuanworld
docker-compose up -d hunyuanworld

# Enter the container
docker-compose exec hunyuanworld bash

# Run your first generation
python3 demo_panogen.py --prompt "A beautiful sunset over mountains" --output_path results
python3 demo_scenegen.py --image_path results/panorama.png --classes outdoor --output_path results
```

## Option 3: Development Environment

```bash
# Build and start development environment with VS Code
docker-compose build hunyuanworld-dev
START_CODE_SERVER=true docker-compose --profile dev up -d hunyuanworld-dev

# Access VS Code at http://localhost:3000
# Access Jupyter at http://localhost:8889
```

## System Requirements

### Minimum Requirements
- **GPU**: NVIDIA GPU with 8GB+ VRAM
- **RAM**: 16GB+ system RAM
- **Storage**: 50GB+ free space
- **CUDA**: 12.4+ support

### Recommended Requirements
- **GPU**: RTX 4090 or A100 with 24GB+ VRAM
- **RAM**: 32GB+ system RAM
- **Storage**: 100GB+ SSD storage
- **CUDA**: 12.4+ support

## Pre-built Images (Future)

Once images are published to Docker Hub:

```bash
# Pull pre-built image (when available)
docker pull hunyuanworld/hunyuanworld:latest

# Run directly
docker run --gpus all -it -v $(pwd)/outputs:/workspace/outputs hunyuanworld/hunyuanworld:latest
```

## Troubleshooting Quick Fixes

### GPU Not Detected
```bash
# Check NVIDIA runtime
docker run --rm --gpus all nvidia/cuda:12.4-base nvidia-smi

# Install NVIDIA Container Toolkit if needed
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

### Out of Memory
```bash
# Use memory optimization flags
python3 demo_panogen.py --fp8_attention --fp8_gemm --cache --prompt "your prompt"
```

### Slow Model Downloads
```bash
# Set HuggingFace mirror (in container)
export HF_ENDPOINT=https://hf-mirror.com
huggingface-cli login --token YOUR_TOKEN
```

### Permission Issues
```bash
# Fix output directory permissions
sudo chown -R $USER:$USER ./outputs
chmod -R 755 ./outputs
```

## Getting Help

1. **Check logs**: `./docker/manage.sh logs hunyuanworld`
2. **Health check**: `docker-compose exec hunyuanworld /workspace/docker/healthcheck.sh`
3. **Container status**: `./docker/manage.sh status`
4. **Clean restart**: `./docker/manage.sh clean && ./docker/manage.sh build all`

## Next Steps

After successful setup:

1. **Explore examples**: Check `examples/` directory for sample inputs
2. **Customize generation**: Modify prompts and parameters in demo scripts
3. **View results**: Use `modelviewer.html` to visualize generated 3D meshes
4. **Develop**: Use development container for code modifications

For detailed documentation, see [DOCKER.md](DOCKER.md).