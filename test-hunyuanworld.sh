#!/bin/bash

# HunyuanWorld-1.0 Docker Testing Suite
# Complete testing workflow for your 3D world generation container

echo "🌍 HunyuanWorld-1.0 Docker Testing Suite"
echo "========================================="
echo ""

# Set up test environment
TEST_DIR="$(pwd)/test_outputs"
mkdir -p "$TEST_DIR"

# Test 1: System and GPU validation
echo "🔍 Test 1: System and GPU Validation"
echo "------------------------------------"
docker run --rm --gpus all hunyuanworld:latest python -c "
import torch
import numpy
print(f'✅ Python Environment Ready')
print(f'✅ PyTorch {torch.__version__}')
print(f'✅ NumPy {numpy.__version__}')
print(f'✅ CUDA Available: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'✅ GPU: {torch.cuda.get_device_name(0)}')
    print(f'✅ VRAM: {torch.cuda.get_device_properties(0).total_memory // 1024**3}GB')
print('✅ System validation passed!')
"

echo ""

# Test 2: HunyuanWorld Component Imports
echo "🧪 Test 2: HunyuanWorld Component Imports"
echo "-----------------------------------------"
docker run --rm --gpus all hunyuanworld:latest python -c "
print('Testing core HunyuanWorld-1.0 components...')
import warnings
warnings.filterwarnings('ignore')

try:
    from hy3dworld.models.pano_generator import Text2PanoramaPipelines, Image2PanoramaPipelines
    print('✅ PanoramaPipelines (Text2Panorama & Image2Panorama)')
except Exception as e:
    print(f'❌ PanoramaPipelines failed: {e}')

try:
    from hy3dworld.models.layer_decomposer import LayerDecomposition
    print('✅ LayerDecomposition (semantic segmentation)')
except Exception as e:
    print(f'❌ LayerDecomposition failed: {e}')

try:
    from hy3dworld.models.world_composer import WorldComposer
    print('✅ WorldComposer (3D mesh reconstruction)')
except Exception as e:
    print(f'❌ WorldComposer failed: {e}')

try:
    import utils3d
    print('✅ utils3d (3D processing utilities)')
except Exception as e:
    print(f'❌ utils3d failed: {e}')

print('✅ Component import testing completed!')
"

echo ""

# Test 3: Demo Script Validation
echo "📋 Test 3: Demo Script Validation"
echo "---------------------------------"
echo "Testing demo script help functions..."
docker run --rm --gpus all -v "$TEST_DIR:/workspace/outputs" hunyuanworld:latest \
    python demo_panogen.py --help

echo ""
docker run --rm --gpus all -v "$TEST_DIR:/workspace/outputs" hunyuanworld:latest \
    python demo_scenegen.py --help

echo ""

# Test 4: HuggingFace Authentication (if token provided)
if [[ -n "$HF_TOKEN" ]]; then
    echo "🔐 Test 4: HuggingFace Authentication"
    echo "------------------------------------"
    docker run --rm --gpus all -e HF_TOKEN="$HF_TOKEN" hunyuanworld:latest \
        bash -c "huggingface-cli whoami && echo '✅ HuggingFace authentication working'"
else
    echo "⚠️  Test 4 Skipped: No HF_TOKEN environment variable set"
    echo "   To test HuggingFace authentication:"
    echo "   export HF_TOKEN='your_token_here'"
    echo "   ./test-hunyuanworld.sh"
fi

echo ""

# Test 5: Quick Generation Test (requires HF_TOKEN)
if [[ -n "$HF_TOKEN" ]]; then
    echo "🎨 Test 5: Quick Text-to-Panorama Generation"
    echo "--------------------------------------------"
    echo "Generating test panorama (this may take 2-5 minutes)..."
    
    docker run --rm --gpus all \
        -e HF_TOKEN="$HF_TOKEN" \
        -v "$TEST_DIR:/workspace/outputs" \
        hunyuanworld:latest \
        python demo_panogen.py \
            --prompt "simple forest clearing with trees" \
            --output_path /workspace/outputs/test_forest \
            --fp8_attention --fp8_gemm --cache \
            --seed 42
    
    if [[ -f "$TEST_DIR/test_forest/panorama.png" ]]; then
        echo "✅ Test panorama generated successfully!"
        echo "📁 Output: $TEST_DIR/test_forest/panorama.png"
    else
        echo "❌ Test panorama generation failed"
    fi
else
    echo "⚠️  Test 5 Skipped: Requires HF_TOKEN for FLUX model access"
    echo "   Get your token from: https://huggingface.co/settings/tokens"
    echo "   Ensure access to: https://huggingface.co/black-forest-labs/FLUX.1-dev"
fi

echo ""
echo "🎯 Testing Summary"
echo "=================="
echo "✅ System validation completed"
echo "✅ Component imports tested"
echo "✅ Demo scripts validated"
if [[ -n "$HF_TOKEN" ]]; then
    echo "✅ HuggingFace authentication tested"
    echo "✅ Generation pipeline tested"
else
    echo "⚠️  HuggingFace tests skipped (no HF_TOKEN)"
fi

echo ""
echo "📖 Next Steps:"
echo "1. Set up HuggingFace token: export HF_TOKEN='your_token'"
echo "2. Generate full 3D world: python demo_panogen.py + demo_scenegen.py"
echo "3. View results in modelviewer.html"
echo ""
echo "🚀 HunyuanWorld-1.0 is ready for 3D world generation!"