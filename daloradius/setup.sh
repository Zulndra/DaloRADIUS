#!/bin/bash

echo "========================================"
echo "  daloRADIUS Docker Setup Script"
echo "========================================"
echo ""

# Create necessary directories
echo "[1/5] Creating directories..."
mkdir -p config
mkdir -p scripts
echo "     ✓ Directories created"

# Check if all required files exist
echo ""
echo "[2/5] Checking required files..."

REQUIRED_FILES=(
    "docker-compose.yml"
    "Dockerfile.daloradius"
    "Dockerfile.freeradius"
    ".env"
    "scripts/configure-daloradius.sh"
    "scripts/configure-freeradius.sh"
    "config/apache-operators.conf"
    "config/apache-users.conf"
    "config/apache-ports.conf"
)

MISSING_FILES=0
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "     ✗ Missing: $file"
        MISSING_FILES=$((MISSING_FILES + 1))
    else
        echo "     ✓ Found: $file"
    fi
done

if [ $MISSING_FILES -gt 0 ]; then
    echo ""
    echo "ERROR: $MISSING_FILES file(s) missing!"
    echo "Please make sure all required files are in place."
    exit 1
fi

# Set executable permissions
echo ""
echo "[3/5] Setting permissions..."
chmod +x scripts/*.sh
echo "     ✓ Permissions set"

# Check Docker and Docker Compose
echo ""
echo "[4/5] Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    echo "     ✗ Docker is not installed!"
    echo "     Please install Docker first: https://docs.docker.com/engine/install/"
    exit 1
fi
echo "     ✓ Docker found: $(docker --version)"

if ! docker compose version &> /dev/null; then
    echo "     ✗ Docker Compose is not installed!"
    echo "     Please install Docker Compose first"
    exit 1
fi
echo "     ✓ Docker Compose found: $(docker compose version)"

# Build and start
echo ""
echo "[5/5] Building and starting containers..."
echo "     This may take a few minutes..."
echo ""

docker compose build

if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: Build failed!"
    exit 1
fi

docker compose up -d

if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: Failed to start containers!"
    exit 1
fi

echo ""
echo "========================================"
echo "  ✓ Setup Complete!"
echo "========================================"
echo ""
echo "Services are starting up..."
echo "Please wait 30-60 seconds for initialization."
echo ""
echo "Access URLs:"
echo "  • Users Interface:     http://localhost:80"
echo "  • Operators Interface: http://localhost:8000"
echo ""
echo "Default Login:"
echo "  • Username: administrator"
echo "  • Password: radius"
echo ""
echo "Useful commands:"
echo "  • View logs:    docker compose logs -f"
echo "  • Stop:         docker compose down"
echo "  • Restart:      docker compose restart"
echo ""
echo "Waiting for services to be ready..."
sleep 10

# Check if containers are running
RUNNING=$(docker compose ps --services --filter "status=running" | wc -l)
TOTAL=3

if [ $RUNNING -eq $TOTAL ]; then
    echo "✓ All $TOTAL services are running!"
else
    echo "⚠ Only $RUNNING/$TOTAL services are running"
    echo "  Run 'docker compose logs' to check for errors"
fi

echo ""
