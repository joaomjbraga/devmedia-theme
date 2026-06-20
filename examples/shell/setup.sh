#!/usr/bin/env bash
# Shell example - DevMedia project setup script
set -euo pipefail
IFS=$'\n\t'

# ---------- Configuration ----------

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_NAME="devmedia-app"
readonly PYTHON_VERSION="3.12"
readonly NODE_VERSION="20"
readonly DOCKER_COMPOSE_VERSION="3.8"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# ---------- Utility Functions ----------

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

command_exists() {
    command -v "$1" &>/dev/null
}

check_dependencies() {
    local deps=("$@")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command_exists "$dep"; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing[*]}"
        log_info "Please install them and try again."
        exit 1
    fi
}

# ---------- Setup Functions ----------

setup_python() {
    log_info "Setting up Python virtual environment..."

    if command_exists python3; then
        python3 -m venv "${SCRIPT_DIR}/.venv"
        source "${SCRIPT_DIR}/.venv/bin/activate"
        pip install --upgrade pip --quiet
        if [[ -f "${SCRIPT_DIR}/requirements.txt" ]]; then
            pip install -r requirements.txt --quiet
        fi
        log_success "Python environment ready"
    else
        log_warn "Python 3 not found. Skipping..."
    fi
}

setup_node() {
    log_info "Setting up Node.js environment..."

    if command_exists node && command_exists npm; then
        if [[ -f "${SCRIPT_DIR}/package.json" ]]; then
            npm install --silent
            log_success "Node.js dependencies installed"
        fi
    else
        log_warn "Node.js not found. Skipping..."
    fi
}

setup_docker() {
    log_info "Checking Docker..."

    if command_exists docker && command_exists docker-compose; then
        log_success "Docker is available"

        # Check if containers are running
        if docker ps --format '{{.Names}}' | grep -q "devmedia"; then
            log_info "DevMedia containers already running"
        else
            log_info "Starting Docker Compose..."
            docker-compose up -d --build || true
        fi
    else
        log_warn "Docker not found. Skipping container setup..."
    fi
}

create_env_file() {
    local env_file="${SCRIPT_DIR}/.env"

    if [[ ! -f "$env_file" ]]; then
        log_info "Creating .env file..."

        cat > "$env_file" <<- EOF
# DevMedia Environment Configuration
APP_ENV=development
APP_DEBUG=true
APP_PORT=8000

# Database
DATABASE_URL=postgresql://devmedia:secret@localhost:5432/devmedia
DB_HOST=localhost
DB_PORT=5432
DB_NAME=devmedia
DB_USER=devmedia
DB_PASSWORD=secret

# Redis
REDIS_URL=redis://localhost:6379/0

# JWT
JWT_SECRET=change-me-in-production
JWT_ALGORITHM=HS256
JWT_EXPIRY_HOURS=24

# External APIs
SENDGRID_API_KEY=
STRIPE_API_KEY=
EOF

        log_success ".env file created"
        log_warn "Please update the .env file with your actual configuration"
    else
        log_info ".env file already exists"
    fi
}

create_directories() {
    log_info "Creating project directories..."

    local dirs=(
        "${SCRIPT_DIR}/logs"
        "${SCRIPT_DIR}/data"
        "${SCRIPT_DIR}/uploads"
        "${SCRIPT_DIR}/static"
        "${SCRIPT_DIR}/backups"
    )

    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_success "Created: $dir"
        fi
    done
}

cleanup() {
    log_info "Cleaning up temporary files..."

    # Remove __pycache__
    find "${SCRIPT_DIR}" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

    # Remove .pyc files
    find "${SCRIPT_DIR}" -name "*.pyc" -delete 2>/dev/null || true

    # Remove node_modules/.cache
    rm -rf "${SCRIPT_DIR}/node_modules/.cache" 2>/dev/null || true

    log_success "Cleanup complete"
}

run_checks() {
    log_info "Running environment checks..."

    echo ""
    echo "========== Environment Info =========="
    echo "OS: $(uname -a)"
    echo "Shell: $SHELL"
    echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    # Check versions
    for cmd in python3 node npm docker docker-compose git; do
        if command_exists "$cmd"; then
            echo "$(printf '%-16s' "$cmd"): $($cmd --version 2>&1 | head -n1)"
        else
            echo "$(printf '%-16s' "$cmd"): ${RED}not found${NC}"
        fi
    done
    echo "======================================"
    echo ""
}

# ---------- Main Script ----------

main() {
    echo ""
    echo "========================================"
    echo "  DevMedia Project Setup"
    echo "========================================"
    echo ""

    # Parse arguments
    local skip_checks=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --skip-checks) skip_checks=true ;;
            --help)
                echo "Usage: $0 [--skip-checks]"
                echo ""
                echo "Options:"
                echo "  --skip-checks    Skip dependency checks"
                echo "  --help           Show this help"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
        shift
    done

    # Check dependencies
    if [[ "$skip_checks" == false ]]; then
        check_dependencies python3 node npm git
    fi

    # Run setup steps
    create_env_file
    create_directories
    setup_python
    setup_node
    setup_docker
    run_checks

    # Optional cleanup
    if [[ "${DEVMEDIA_CLEANUP:-false}" == "true" ]]; then
        cleanup
    fi

    echo ""
    log_success "Setup complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Edit .env with your configuration"
    echo "  2. Start the development server:"
    echo "     $ source .venv/bin/activate  # Python"
    echo "     $ npm run dev                # Node.js"
    echo "  3. Visit http://localhost:8000"
    echo ""
}

# Run main
main "$@"
