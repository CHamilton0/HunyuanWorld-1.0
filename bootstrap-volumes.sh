#!/bin/bash

# Bootstrap Volume Environment from Working Container
# This copies the Python environment from the working container to volumes

set -e

echo "🔄 Bootstrapping Volume Environment from Working Container"
echo "========================================================="

# Create volume directories
mkdir -p docker_volumes/{venv,cache/{huggingface,transformers,torch},external_tools,outputs,models}

echo "📦 Extracting Python environment from working container..."

# Create a temporary container to extract the conda environment
docker run --rm -v $(pwd)/docker_volumes/venv:/extract_venv hunyuanworld:latest bash -c "
echo '📋 Copying conda environment to volume...'
cp -r /opt/conda/envs/HunyuanWorld/* /extract_venv/
echo '✅ Environment copied successfully!'
"

echo "🔧 Creating activation script..."
cat > docker_volumes/venv/activate_env.sh << 'EOF'
#!/bin/bash
# Volume-optimized environment activation
export PATH="/workspace/venv/bin:$PATH"
export PYTHONPATH="/app:/workspace/venv/lib/python3.10/site-packages"
export CONDA_DEFAULT_ENV="HunyuanWorld"
export VIRTUAL_ENV="/workspace/venv"
EOF

chmod +x docker_volumes/venv/activate_env.sh

echo "✅ Volume environment bootstrapped successfully!"
echo ""
echo "🎯 Now you can use the true volume-optimized setup:"
echo "   ./run-simple.sh"
echo "   ./run-simple.sh ready"
echo "   ./run-simple.sh shell"