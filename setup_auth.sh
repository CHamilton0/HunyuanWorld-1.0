#!/bin/bash

# HunyuanWorld Authentication Setup Script

echo "🔐 HunyuanWorld Authentication Setup"
echo "=================================="
echo

# Check if we're in the container
if [[ -f /workspace/activate.sh ]]; then
    echo "✅ Running inside Docker container"
    source /workspace/activate.sh
else
    echo "ℹ️  Running outside Docker container"
    echo "   Use: ./docker/manage.sh exec prod '/workspace/setup_auth.sh'"
    exit 1
fi

# Check for HF_TOKEN environment variable
if [[ -n "$HF_TOKEN" ]]; then
    echo "🔑 HF_TOKEN environment variable detected"
    echo "🔐 Attempting automatic authentication..."
    
    if echo "$HF_TOKEN" | huggingface-cli login --token "$HF_TOKEN" > /dev/null 2>&1; then
        echo "✅ Successfully authenticated with environment token"
    else
        echo "❌ Failed to authenticate with environment token"
        echo "   Please check that your HF_TOKEN is valid"
    fi
else
    echo "ℹ️  No HF_TOKEN environment variable found"
fi

# Check current authentication status
echo "🔍 Checking Hugging Face authentication..."
if huggingface-cli whoami > /dev/null 2>&1; then
    USER=$(huggingface-cli whoami 2>/dev/null | grep "username:" | cut -d':' -f2 | xargs)
    if [[ -n "$USER" ]]; then
        echo "✅ Already authenticated as: $USER"
    else
        echo "✅ Authenticated (username detection failed)"
    fi
    
    # Test FLUX model access
    echo "🧪 Testing FLUX model access..."
    python -c "
from huggingface_hub import model_info
try:
    info = model_info('black-forest-labs/FLUX.1-dev')
    print('✅ FLUX.1-dev access confirmed')
except Exception as e:
    print(f'❌ FLUX.1-dev access failed: {e}')
    print('📝 Please request access at: https://huggingface.co/black-forest-labs/FLUX.1-dev')
"
else
    echo "❌ Not authenticated with Hugging Face"
    echo
    echo "📋 Setup Instructions:"
    echo "1. Get a token from: https://huggingface.co/settings/tokens"
    echo "2. Request access to: https://huggingface.co/black-forest-labs/FLUX.1-dev"
    echo "3. Set environment variable: export HF_TOKEN=your_token_here"
    echo "4. Restart container: ./docker/manage.sh stop && ./docker/manage.sh start prod"
    echo
    echo "   Or manual login: huggingface-cli login --token YOUR_TOKEN"
    echo
    echo "💡 Alternative: Use FLUX.1-schnell (no auth required)"
fi

echo
echo "🚀 Ready to test generation with: ./docker/manage.sh demo text"