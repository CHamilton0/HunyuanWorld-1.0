#!/bin/bash
# Volume Management Script for HunyuanWorld
# This script helps manage Docker volumes to optimize image size

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Volume paths
VOLUME_BASE="./docker_volumes"
VOLUMES=(
    "venv"
    "cache/huggingface"
    "cache/transformers" 
    "cache/torch"
    "cache"
    "external_tools"
    "outputs"
    "models"
    "dev_outputs"
    "dev_models"
    "prod_outputs"
)

print_usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  init      - Initialize volume directories"
    echo "  clean     - Clean all volumes"
    echo "  backup    - Backup volumes to tar archives"
    echo "  restore   - Restore volumes from tar archives"
    echo "  status    - Show volume sizes and status"
    echo "  prune     - Remove unused Docker volumes"
    echo "  help      - Show this help message"
}

init_volumes() {
    echo -e "${BLUE}🔧 Initializing volume directories...${NC}"
    
    for volume in "${VOLUMES[@]}"; do
        mkdir -p "${VOLUME_BASE}/${volume}"
        echo -e "${GREEN}✅ Created: ${VOLUME_BASE}/${volume}${NC}"
    done
    
    # Set proper permissions
    chmod -R 755 "${VOLUME_BASE}"
    
    echo -e "${GREEN}✅ Volume directories initialized${NC}"
    echo -e "${YELLOW}💡 Tip: These directories will persist between container runs, reducing image size${NC}"
}

clean_volumes() {
    echo -e "${YELLOW}⚠️  This will delete all volume data. Are you sure? (y/N)${NC}"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}🧹 Cleaning volumes...${NC}"
        rm -rf "${VOLUME_BASE}"
        echo -e "${GREEN}✅ Volumes cleaned${NC}"
        init_volumes
    else
        echo -e "${YELLOW}❌ Operation cancelled${NC}"
    fi
}

backup_volumes() {
    echo -e "${BLUE}💾 Backing up volumes...${NC}"
    
    timestamp=$(date +%Y%m%d_%H%M%S)
    backup_dir="./volume_backups/${timestamp}"
    mkdir -p "${backup_dir}"
    
    for volume in "${VOLUMES[@]}"; do
        volume_path="${VOLUME_BASE}/${volume}"
        if [ -d "${volume_path}" ] && [ "$(ls -A ${volume_path})" ]; then
            echo -e "${BLUE}📦 Backing up ${volume}...${NC}"
            tar -czf "${backup_dir}/${volume//\//_}.tar.gz" -C "${VOLUME_BASE}" "${volume}"
            echo -e "${GREEN}✅ Backed up: ${volume}${NC}"
        else
            echo -e "${YELLOW}⚠️  Skipping empty volume: ${volume}${NC}"
        fi
    done
    
    echo -e "${GREEN}✅ Backup completed: ${backup_dir}${NC}"
}

restore_volumes() {
    echo -e "${BLUE}📥 Restoring volumes...${NC}"
    
    # Find latest backup
    latest_backup=$(find ./volume_backups -type d -name "20*" | sort | tail -1)
    
    if [ -z "$latest_backup" ]; then
        echo -e "${RED}❌ No backups found${NC}"
        return 1
    fi
    
    echo -e "${BLUE}📂 Using backup: ${latest_backup}${NC}"
    
    for volume in "${VOLUMES[@]}"; do
        backup_file="${latest_backup}/${volume//\//_}.tar.gz"
        if [ -f "${backup_file}" ]; then
            echo -e "${BLUE}📦 Restoring ${volume}...${NC}"
            tar -xzf "${backup_file}" -C "${VOLUME_BASE}"
            echo -e "${GREEN}✅ Restored: ${volume}${NC}"
        else
            echo -e "${YELLOW}⚠️  No backup found for: ${volume}${NC}"
        fi
    done
    
    echo -e "${GREEN}✅ Restore completed${NC}"
}

show_status() {
    echo -e "${BLUE}📊 Volume Status${NC}"
    echo "=================="
    
    total_size=0
    
    for volume in "${VOLUMES[@]}"; do
        volume_path="${VOLUME_BASE}/${volume}"
        if [ -d "${volume_path}" ]; then
            # Get size in MB
            size=$(du -sm "${volume_path}" 2>/dev/null | cut -f1)
            total_size=$((total_size + size))
            
            if [ "$size" -gt 0 ]; then
                echo -e "${GREEN}✅ ${volume}: ${size}MB${NC}"
            else
                echo -e "${YELLOW}📁 ${volume}: Empty${NC}"
            fi
        else
            echo -e "${RED}❌ ${volume}: Not found${NC}"
        fi
    done
    
    echo "=================="
    echo -e "${BLUE}📊 Total volume size: ${total_size}MB${NC}"
    
    # Show Docker volume info
    echo ""
    echo -e "${BLUE}🐳 Docker Volume Info${NC}"
    echo "======================"
    docker system df -v 2>/dev/null | grep hunyuanworld || echo "No HunyuanWorld volumes found"
}

prune_volumes() {
    echo -e "${BLUE}🧹 Pruning unused Docker volumes...${NC}"
    docker volume prune -f
    echo -e "${GREEN}✅ Docker volumes pruned${NC}"
}

# Main script logic
case "${1:-help}" in
    init)
        init_volumes
        ;;
    clean)
        clean_volumes
        ;;
    backup)
        backup_volumes
        ;;
    restore)
        restore_volumes
        ;;
    status)
        show_status
        ;;
    prune)
        prune_volumes
        ;;
    help|*)
        print_usage
        ;;
esac