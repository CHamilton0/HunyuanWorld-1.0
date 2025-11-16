#!/bin/bash

# HunyuanWorld Volume-Optimized Runner
# This script makes it easy to run the volume-optimized Docker setup

set -e

echo "🌍 HunyuanWorld Volume-Optimized Docker Runner"
echo "=============================================="

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if NVIDIA Docker runtime is available
if ! docker run --rm --gpus all nvidia/cuda:12.4-base nvidia-smi >/dev/null 2>&1; then
    echo "⚠️  GPU support may not be available. Continuing anyway..."
fi

# Set HuggingFace token if available
if [[ -f ".env" ]]; then
    echo "📋 Loading environment variables from .env file..."
    export $(cat .env | grep -v '^#' | xargs)
fi

# Create volume directories if they don't exist
echo "📁 Creating volume directories..."
mkdir -p docker_volumes/{venv,cache/{huggingface,transformers,torch},external_tools,outputs,models,dev_outputs,dev_models,prod_outputs}

# Function to run different profiles
run_service() {
    local profile="$1"
    local service="$2"
    
    echo "🚀 Starting HunyuanWorld ($profile profile)..."
    echo "   Service: $service"I
    echo "   Image: hunyuanworld:volume-optimized-v2 (3.27GB)"
    echo ""
    
    if [[ "$profile" == "dev" ]]; then
        docker compose -f docker-compose.volume-optimized.yml --profile dev up -d "$service"
    elif [[ "$profile" == "prod" ]]; then
        docker compose -f docker-compose.volume-optimized.yml --profile prod up -d "$service"
    else
        docker compose -f docker-compose.volume-optimized.yml up -d "$service"
    fi
    
    echo ""
    echo "✅ Container started successfully!"
    echo ""
    echo "🔧 Useful commands:"
    echo "   View logs:    docker compose -f docker-compose.volume-optimized.yml logs -f $service"
    echo "   Enter shell:  docker compose -f docker-compose.volume-optimized.yml exec $service bash"
    echo "   Stop:         docker compose -f docker-compose.volume-optimized.yml down"
    echo ""
}

# Parse command line arguments
case "${1:-main}" in
    "main"|"")
        run_service "main" "hunyuanworld-volume"
        ;;
    "dev")
        run_service "dev" "hunyuanworld-dev-volume"
        ;;
    "prod")
        run_service "prod" "hunyuanworld-prod"
        ;;
    "stop")
        echo "🛑 Stopping all HunyuanWorld containers..."
        docker compose -f docker-compose.volume-optimized.yml down
        echo "✅ All containers stopped."
        ;;
    "logs")
        service="${2:-hunyuanworld-volume}"
        echo "📜 Showing logs for $service..."
        docker compose -f docker-compose.volume-optimized.yml logs -f "$service"
        ;;
    "shell")
        service="${2:-hunyuanworld-volume}"
        echo "🐚 Opening shell in $service..."
        docker compose -f docker-compose.volume-optimized.yml exec "$service" bash
        ;;
    "status")
        echo "📊 Container status:"
        docker compose -f docker-compose.volume-optimized.yml ps
        echo ""
        echo "💾 Volume usage:"
        du -sh docker_volumes/* 2>/dev/null || echo "No volumes created yet"
        ;;
    "clean")
        echo "🧹 Cleaning up volumes and containers..."
        docker compose -f docker-compose.volume-optimized.yml down -v
        read -p "Delete volume data? This will remove all downloaded models and cache (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf docker_volumes/*
            echo "✅ Volume data deleted."
        fi
        ;;
    "help"|"-h"|"--help")
        echo ""
        echo "Usage: $0 [COMMAND] [SERVICE]"
        echo ""
        echo "Commands:"
        echo "  main     - Start main service (default)"
        echo "  dev      - Start development service with extra tools"
        echo "  prod     - Start production service (read-only)"
        echo "  stop     - Stop all services"
        echo "  logs     - Show logs for a service"
        echo "  shell    - Open shell in a service"
        echo "  status   - Show container and volume status"
        echo "  clean    - Clean up containers and optionally volumes"
        echo "  help     - Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0                    # Start main service"
        echo "  $0 dev                # Start development service"
        echo "  $0 shell              # Open shell in main service"
        echo "  $0 logs dev           # Show dev service logs"
        echo ""
        ;;
    *)
        echo "❌ Unknown command: $1"
        echo "Use '$0 help' for usage information."
        exit 1
        ;;
esac