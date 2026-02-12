#!/bin/bash
#
# Manage services easily - stop, start, restart, logs
# Usage: ./infrastructure/service-manager.sh [command] [service]
#

SERVICES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/services"

if [[ ! -d "$SERVICES_DIR" ]]; then
    echo "ERROR: Services directory not found at $SERVICES_DIR"
    exit 1
fi

usage() {
    cat << EOF
Usage: service-manager.sh [COMMAND] [SERVICE]

Commands:
  status              Show status of all services
  logs [SERVICE]      View logs (follow with: tail)
  start [SERVICE]     Start service(s)
  stop [SERVICE]      Stop service(s)
  restart [SERVICE]   Restart service(s)
  recreate [SERVICE]  Recreate containers (pull + up -d)
  cleanup             Remove dangling images/volumes
  prune               Full Docker cleanup

Examples:
  ./service-manager.sh status
  ./service-manager.sh logs outline
  ./service-manager.sh restart gitea
  ./service-manager.sh stop           # Stop all
  ./service-manager.sh start outline  # Start only outline
  ./service-manager.sh cleanup
EOF
    exit 0
}

# Parse arguments
COMMAND="${1:-status}"
SERVICE="${2:-all}"

case "$COMMAND" in
    status)
        echo "Service Status:"
        echo "==============="
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -20
        echo ""
        echo "Total: $(docker ps -q | wc -l) running"
        ;;
    
    logs)
        if [[ "$SERVICE" == "all" ]]; then
            echo "Logs from all services (last 100 lines):"
            for service_dir in "$SERVICES_DIR"/*; do
                service=$(basename "$service_dir")
                echo ""
                echo "=== $service ==="
                docker compose -f "$service_dir/docker-compose.yml" logs --tail=5 -t 2>/dev/null || true
            done
        else
            echo "Logs from $SERVICE:"
            docker compose -f "$SERVICES_DIR/$SERVICE/docker-compose.yml" logs --tail=50 -f 2>/dev/null || docker logs "$SERVICE" -f
        fi
        ;;
    
    start)
        if [[ "$SERVICE" == "all" ]]; then
            echo "Starting all services..."
            for service_dir in "$SERVICES_DIR"/*; do
                service=$(basename "$service_dir")
                echo "Starting $service..."
                cd "$service_dir"
                docker compose up -d
                cd - > /dev/null
            done
        else
            echo "Starting $SERVICE..."
            cd "$SERVICES_DIR/$SERVICE"
            docker compose up -d
        fi
        ;;
    
    stop)
        if [[ "$SERVICE" == "all" ]]; then
            echo "Stopping all services..."
            for service_dir in "$SERVICES_DIR"/*; do
                service=$(basename "$service_dir")
                echo "Stopping $service..."
                cd "$service_dir"
                docker compose down
                cd - > /dev/null
            done
        else
            echo "Stopping $SERVICE..."
            cd "$SERVICES_DIR/$SERVICE"
            docker compose down
        fi
        ;;
    
    restart)
        if [[ "$SERVICE" == "all" ]]; then
            echo "Restarting all services..."
            for service_dir in "$SERVICES_DIR"/*; do
                service=$(basename "$service_dir")
                echo "Restarting $service..."
                cd "$service_dir"
                docker compose restart
                cd - > /dev/null
            done
        else
            echo "Restarting $SERVICE..."
            cd "$SERVICES_DIR/$SERVICE"
            docker compose restart
        fi
        ;;
    
    recreate)
        if [[ "$SERVICE" == "all" ]]; then
            echo "Recreating all services..."
            for service_dir in "$SERVICES_DIR"/*; do
                service=$(basename "$service_dir")
                echo "Recreating $service..."
                cd "$service_dir"
                docker compose down
                docker compose pull
                docker compose up -d
                cd - > /dev/null
            done
        else
            echo "Recreating $SERVICE..."
            cd "$SERVICES_DIR/$SERVICE"
            docker compose down
            docker compose pull
            docker compose up -d
        fi
        ;;
    
    cleanup)
        echo "Cleaning up Docker resources..."
        docker container prune -f
        docker image prune -f
        echo "Done!"
        ;;
    
    prune)
        echo "WARNING: This will remove all unused Docker resources!"
        read -p "Continue? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker system prune -a --volumes
            echo "Done!"
        fi
        ;;
    
    *)
        echo "Unknown command: $COMMAND"
        usage
        ;;
esac
