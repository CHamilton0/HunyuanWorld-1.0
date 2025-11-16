#!/bin/bash
# HunyuanWorld Docker Management Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    printf "${1}${2}${NC}\n"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_color $RED "Error: Docker is not running. Please start Docker first."
        exit 1
    fi
}

# Function to check if NVIDIA Container Toolkit is available
check_nvidia() {
    # Check if nvidia-smi exists on host
    if ! command -v nvidia-smi >/dev/null 2>&1; then
        print_color $YELLOW "Warning: No NVIDIA GPU detected on host system."
        return
    fi
    
    # Test Docker GPU access with better error handling
    if ! docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi > /dev/null 2>&1; then
        print_color $YELLOW "Warning: NVIDIA Container Toolkit may not be properly configured."
        print_color $YELLOW "GPU acceleration may not work properly."
        print_color $YELLOW "Run './docker/manage.sh gpu' for detailed GPU setup instructions."
    fi
}

# Function to show usage
usage() {
    cat << EOF
HunyuanWorld Docker Management Script

Usage: $0 [COMMAND] [OPTIONS]

Commands:
    build [prod|dev|all]     Build Docker images
    up [prod|dev|jupyter]    Start services
    down                     Stop all services
    shell [prod|dev]         Enter container shell
    logs [service]           Show container logs
    clean                    Clean up containers and volumes
    status                   Show container status
    demo [text|image|test]   Run generation demos
    gpu                      Test GPU support and setup
    help                     Show this help message

Examples:
    $0 build prod           # Build production image
    $0 up dev               # Start development environment
    $0 shell prod           # Enter production container
    $0 demo text            # Run text-to-3D demo
    $0 logs hunyuanworld    # Show logs for main service
    $0 clean                # Clean up everything

Environment Variables:
    CUDA_VISIBLE_DEVICES    Specify GPU devices (default: 0)
    HF_TOKEN               HuggingFace access token
EOF
}

# Function to build images
build_images() {
    local target=${1:-all}
    
    print_color $BLUE "Building HunyuanWorld Docker images..."
    
    case $target in
        prod|production)
            print_color $GREEN "Building production image..."
            docker compose build hunyuanworld
            ;;
        dev|development)
            print_color $GREEN "Building development image..."
            docker compose build hunyuanworld-dev
            ;;
        all)
            print_color $GREEN "Building all images..."
            docker compose build
            ;;
        *)
            print_color $RED "Invalid build target: $target"
            print_color $YELLOW "Valid targets: prod, dev, all"
            exit 1
            ;;
    esac
    
    print_color $GREEN "Build completed successfully!"
}

# Function to start services
start_services() {
    local service=${1:-prod}
    
    case $service in
        prod|production)
            print_color $GREEN "Starting production environment..."
            docker compose up -d hunyuanworld
            print_color $GREEN "Production environment started!"
            print_color $BLUE "You can access the container with: $0 shell prod"
            ;;
        dev|development)
            print_color $GREEN "Starting development environment..."
            docker compose --profile dev up -d hunyuanworld-dev
            print_color $GREEN "Development environment started!"
            print_color $BLUE "Access VS Code Server at: http://localhost:3000"
            print_color $BLUE "Access Jupyter at: http://localhost:8889"
            ;;
        jupyter)
            print_color $GREEN "Starting Jupyter environment..."
            docker compose --profile jupyter up -d jupyter
            print_color $GREEN "Jupyter environment started!"
            print_color $BLUE "Access Jupyter at: http://localhost:8888"
            ;;
        *)
            print_color $RED "Invalid service: $service"
            print_color $YELLOW "Valid services: prod, dev, jupyter"
            exit 1
            ;;
    esac
}

# Function to stop services
stop_services() {
    print_color $YELLOW "Stopping all HunyuanWorld services..."
    docker compose --profile dev --profile jupyter down
    print_color $GREEN "All services stopped!"
}

# Function to enter container shell
enter_shell() {
    local target=${1:-prod}
    
    case $target in
        prod|production)
            if ! docker compose ps hunyuanworld | grep -q "Up"; then
                print_color $YELLOW "Production container not running. Starting..."
                start_services prod
                sleep 5
            fi
            print_color $GREEN "Entering production container..."
            docker compose exec hunyuanworld bash
            ;;
        dev|development)
            if ! docker compose ps hunyuanworld-dev | grep -q "Up"; then
                print_color $YELLOW "Development container not running. Starting..."
                start_services dev
                sleep 5
            fi
            print_color $GREEN "Entering development container..."
            docker compose exec hunyuanworld-dev bash
            ;;
        *)
            print_color $RED "Invalid shell target: $target"
            print_color $YELLOW "Valid targets: prod, dev"
            exit 1
            ;;
    esac
}

# Function to show logs
show_logs() {
    local service=${1:-hunyuanworld}
    print_color $GREEN "Showing logs for service: $service"
    docker compose logs -f $service
}

# Function to clean up
cleanup() {
    print_color $YELLOW "This will remove all containers, networks, and volumes."
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_color $YELLOW "Cleaning up containers and networks..."
        docker compose --profile dev --profile jupyter down
        
        print_color $YELLOW "Removing Docker images..."
        docker images | grep hunyuanworld | awk '{print $3}' | xargs -r docker rmi
        
        print_color $YELLOW "Cleaning up volumes..."
        docker volume ls | grep hunyuanworld | awk '{print $2}' | xargs -r docker volume rm
        
        print_color $GREEN "Cleanup completed!"
    else
        print_color $BLUE "Cleanup cancelled."
    fi
}

# Function to show status
show_status() {
    print_color $GREEN "HunyuanWorld Docker Status:"
    echo
    print_color $BLUE "Running Containers:"
    docker compose ps
    echo
    print_color $BLUE "Docker Images:"
    docker images | grep -E "(hunyuanworld|REPOSITORY)"
    echo
    print_color $BLUE "Docker Volumes:"
    docker volume ls | grep -E "(hunyuanworld|DRIVER)"
}

# Function to run demo
run_demo() {
    local demo_type=${1:-text}
    
    # Ensure production container is running
    if ! docker compose ps hunyuanworld | grep -q "Up"; then
        print_color $YELLOW "Starting production container for demo..."
        start_services prod
        sleep 10
    fi
    
    case $demo_type in
        text)
            print_color $GREEN "Running text-to-3D demo..."
            docker compose exec hunyuanworld bash -c "
                source /workspace/activate.sh && \
                cd /workspace/HunyuanWorld-1.0 && \
                python demo_panogen.py \
                    --prompt 'A serene mountain landscape with a lake' \
                    --output_path /workspace/outputs/demo_text \
                    --fp8_attention --fp8_gemm && \
                python demo_scenegen.py \
                    --image_path /workspace/outputs/demo_text/panorama.png \
                    --classes outdoor \
                    --output_path /workspace/outputs/demo_text \
                    --fp8_attention --fp8_gemm
            "
            print_color $GREEN "Demo completed! Results in outputs/demo_text/"
            ;;
        image)
            print_color $GREEN "Running image-to-3D demo..."
            docker compose exec hunyuanworld bash -c "
                source /workspace/activate.sh && \
                cd /workspace/HunyuanWorld-1.0 && \
                python demo_panogen.py \
                    --image_path examples/case1/input.png \
                    --output_path /workspace/outputs/demo_image \
                    --fp8_attention --fp8_gemm && \
                python demo_scenegen.py \
                    --image_path /workspace/outputs/demo_image/panorama.png \
                    --classes outdoor \
                    --output_path /workspace/outputs/demo_image \
                    --fp8_attention --fp8_gemm
            "
            print_color $GREEN "Demo completed! Results in outputs/demo_image/"
            ;;
        test)
            print_color $GREEN "Running test suite..."
            docker compose exec hunyuanworld bash -c "
                source /workspace/activate.sh && 
                cd /workspace/HunyuanWorld-1.0 && 
                ./test_generation.sh
            "
            ;;
        *)
            print_color $RED "Invalid demo type: $demo_type"
            print_color $YELLOW "Valid types: text, image, test"
            exit 1
            ;;
    esac
}

# Function to test GPU support
test_gpu() {
    print_color $CYAN "🖥️  Testing GPU Support"
    echo
    
    # Step 1: Check if NVIDIA GPU exists on host
    print_color $BLUE "1. Checking Host GPU..."
    if command -v nvidia-smi >/dev/null 2>&1; then
        print_color $GREEN "✅ NVIDIA GPU detected on host"
        nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader 2>/dev/null || echo "   Could not query GPU details"
    else
        print_color $RED "❌ No NVIDIA GPU or drivers detected"
        print_color $YELLOW "   Install NVIDIA drivers first: sudo apt install nvidia-driver-XXX"
        return 1
    fi
    
    # Step 2: Check Docker installation
    print_color $BLUE "2. Checking Docker..."
    if docker version >/dev/null 2>&1; then
        print_color $GREEN "✅ Docker is running"
    else
        print_color $RED "❌ Docker not running or accessible"
        return 1
    fi
    
    # Step 3: Check NVIDIA Container Toolkit
    print_color $BLUE "3. Checking NVIDIA Container Toolkit..."
    if command -v nvidia-container-runtime >/dev/null 2>&1; then
        print_color $GREEN "✅ NVIDIA Container Toolkit found"
    else
        print_color $RED "❌ NVIDIA Container Toolkit not installed"
        echo
        print_color $YELLOW "📦 Install NVIDIA Container Toolkit:"
        echo "   curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg"
        echo "   curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \\"
        echo "     sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \\"
        echo "     sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list"
        echo "   sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit"
        echo "   sudo systemctl restart docker"
        return 1
    fi
    
    # Step 4: Test Docker GPU access
    print_color $BLUE "4. Testing Docker GPU Access..."
    if docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi >/dev/null 2>&1; then
        print_color $GREEN "✅ GPU access working in Docker"
        print_color $GREEN "📊 GPU Info:"
        docker run --rm --gpus all nvidia/cuda:12.4.0-base-ubuntu22.04 nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null
    else
        print_color $RED "❌ GPU access failed in Docker"
        print_color $YELLOW "� Troubleshooting steps:"
        echo "   1. Restart Docker: sudo systemctl restart docker"
        echo "   2. Check Docker daemon config: cat /etc/docker/daemon.json"
        echo "   3. Verify NVIDIA runtime: docker info | grep -i nvidia"
        echo "   4. Test with: docker run --rm --gpus all nvidia/cuda:12.4-base-ubuntu22.04 nvidia-smi"
        return 1
    fi
    
    # Step 5: Test HunyuanWorld container GPU access
    print_color $BLUE "5. Testing HunyuanWorld Container..."
    if docker compose ps hunyuanworld | grep -q "Up"; then
        print_color $GREEN "🧪 Testing PyTorch GPU in HunyuanWorld container..."
        docker compose exec hunyuanworld bash -c "
            source /workspace/activate.sh && 
            python -c 'import torch; print(f\"CUDA Available: {torch.cuda.is_available()}\"); print(f\"GPU Count: {torch.cuda.device_count()}\"); [print(f\"GPU {i}: {torch.cuda.get_device_name(i)}\") for i in range(torch.cuda.device_count())]'
        " 2>/dev/null || print_color $YELLOW "   Could not test - container may need GPU config"
    else
        print_color $YELLOW "   Container not running. Start with: ./docker/manage.sh start"
        print_color $YELLOW "   Note: Uncomment GPU sections in docker-compose.yml first"
    fi
    
    echo
    print_color $GREEN "🎯 GPU Test Complete!"
    print_color $BLUE "💡 To enable GPU in HunyuanWorld:"
    echo "   1. Uncomment GPU sections in docker-compose.yml"
    echo "   2. Restart container: ./docker/manage.sh down && ./docker/manage.sh start"
    echo "   3. Test generation: ./docker/manage.sh demo text"
}

# Main function - process command line arguments
main() {
    check_docker
    check_nvidia
    
    local command=${1:-help}
    
    case $command in
        build)
            build_images $2
            ;;
        up|start)
            start_services $2
            ;;
        down|stop)
            stop_services
            ;;
        shell|exec)
            enter_shell $2
            ;;
        logs)
            show_logs $2
            ;;
        clean|cleanup)
            cleanup
            ;;
        status)
            show_status
            ;;
        demo)
            run_demo $2
            ;;
        gpu|test-gpu)
            test_gpu
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            print_color $RED "Unknown command: $command"
            echo
            usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"