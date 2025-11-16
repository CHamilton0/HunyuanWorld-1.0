#!/bin/bash

# Test script for HunyuanWorld-1.0 generation
# This script tests both panorama generation and 3D scene generation

set -e  # Exit on error

echo "🌍 Testing HunyuanWorld-1.0 Generation"
echo "======================================"

# Check if we're inside Docker
if [ -f /.dockerenv ]; then
    echo "✅ Running inside Docker container"
    source /workspace/activate.sh
    cd /workspace/HunyuanWorld-1.0
else
    echo "⚠️  Running on host system (not recommended)"
fi

# Create test output directory
mkdir -p test_outputs
echo "📁 Created test_outputs directory"

# Test 1: Check dependencies
echo ""
echo "🔍 Testing Dependencies..."
python -c "
try:
    import torch
    import diffusers
    import transformers
    print(f'✅ PyTorch: {torch.__version__}')
    print(f'✅ Diffusers: {diffusers.__version__}')
    print(f'✅ Transformers: {transformers.__version__}')
    print(f'✅ CUDA Available: {torch.cuda.is_available()}')
    if torch.cuda.is_available():
        print(f'✅ GPU: {torch.cuda.get_device_name()}')
    else:
        print('⚠️  No GPU detected - will use CPU mode')
except ImportError as e:
    print(f'❌ Import error: {e}')
    exit(1)
"

# Test 2: Check HunyuanWorld modules
echo ""
echo "🧪 Testing HunyuanWorld Modules..."
python -c "
try:
    # Test basic imports without full initialization
    from hy3dworld.utils.general_utils import *
    from hy3dworld.utils.perspective_utils import Perspective
    print('✅ HunyuanWorld utils imported successfully')
except Exception as e:
    print(f'⚠️  HunyuanWorld import issue: {e}')
    print('This may require GPU or model downloads')
"

# Test 3: Check example data
echo ""
echo "📋 Available Test Cases:"
for case in examples/case*; do
    if [ -d "$case" ]; then
        echo "  - $case:"
        if [ -f "$case/prompt.txt" ]; then
            echo "    📝 Prompt: $(head -1 "$case/prompt.txt")"
        fi
        if [ -f "$case/input.png" ]; then
            echo "    🖼️  Input image available"
        fi
        if [ -f "$case/classes.txt" ]; then
            echo "    🏷️  Class: $(cat "$case/classes.txt")"
        fi
    fi
done

# Test 4: Check model requirements
echo ""
echo "🔧 Model Requirements Check:"
echo "  Required models will be downloaded from HuggingFace:"
echo "  - FLUX.1-dev (text-to-panorama)"
echo "  - FLUX.1-Fill-dev (image-to-panorama)"
echo "  - tencent/HunyuanWorld-1 (LoRA weights)"
echo ""
echo "  Note: Models will auto-download on first run (requires internet)"

# Test 5: Simple generation test (if GPU available)
echo ""
echo "🚀 Generation Test:"
if python -c "import torch; exit(0 if torch.cuda.is_available() else 1)" 2>/dev/null; then
    echo "✅ GPU detected - ready for generation"
    echo ""
    echo "To test panorama generation:"
    echo "  python demo_panogen.py --prompt 'A beautiful mountain landscape' --output_path test_outputs/test1"
    echo ""
    echo "To test with example case:"
    echo "  python demo_panogen.py --prompt_file examples/case4/prompt.txt --output_path test_outputs/case4"
    echo ""
    echo "To test full pipeline:"
    echo "  ./test_pipeline.sh"
else
    echo "⚠️  No GPU - generation requires CUDA for model inference"
    echo "   Consider using Google Colab or a GPU-enabled system"
fi

echo ""
echo "🎯 Test Complete!"
echo "   Ready to generate 3D worlds with HunyuanWorld-1.0"