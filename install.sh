#!/bin/bash

# Webinoly + Anubis Feature - Complete Installation Script
# This script installs Webinoly and adds the Anubis bot protection feature

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Track temp resources for cleanup
TEMP_DIR=""
TEMP_TAR="${HOME}/webinoly.tar"

# Cleanup function
cleanup() {
    if [[ -n "${TEMP_DIR}" && -d "${TEMP_DIR}" ]]; then
        rm -rf "${TEMP_DIR}"
    fi
    if [[ -f "${TEMP_TAR}" ]]; then
        rm -f "${TEMP_TAR}"
    fi
}

# Set trap for cleanup on exit (success or failure)
trap cleanup EXIT

# Help function
show_help() {
    echo "Webinoly + Anubis Feature Installer"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo ""
    echo "This script installs Webinoly with Anubis bot protection feature."
    echo "Supported OS: Ubuntu 22.04 (Jammy) or 24.04 (Noble)"
    echo ""
    echo "Requirements:"
    echo "  - Root privileges (run with sudo or as root)"
    echo "  - Docker (for Anubis functionality)"
    echo ""
    exit 0
}

# Parse arguments
for arg in "$@"; do
    case $arg in
        -h|--help)
            show_help
            ;;
    esac
done

echo -e "${BLUE}${BOLD}"
echo "=========================================="
echo "  Webinoly + Anubis Feature Installer"
echo "=========================================="
echo -e "${NC}"

# Check for sudo/root privileges
if [[ $(whoami) != "root" ]]; then
    echo -e "${RED}Please run this script as root or using sudo.${NC}"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check OS support
distr=$(lsb_release -i 2>/dev/null | cut -d':' -f 2 | tr -d '[:space:]')
osver=$(lsb_release -c 2>/dev/null | cut -d':' -f 2 | tr -d '[:space:]')

echo -e "${BLUE}Detected OS: ${BOLD}${distr} ${osver}${NC}"

# Supported: 22.04 Jammy and 24.04 Noble
if [[ "${distr}" != "Ubuntu" ]] || ! [[ "${osver}" =~ ^(jammy|noble)$ ]]; then
    echo -e "${RED}"
    echo "[ERROR] This OS is not supported by Webinoly."
    echo "Supported: Ubuntu 22.04 (Jammy) or 24.04 (Noble)"
    echo -e "${NC}"
    exit 1
fi

echo -e "${GREEN}✓ OS is supported${NC}"
echo ""

# Check for Docker (warning only, not required for base install)
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}⚠ Docker is not installed${NC}"
    echo -e "${DIM}  Docker is required for Anubis functionality.${NC}"
    echo -e "${DIM}  Install later with: curl -fsSL https://get.docker.com | sh${NC}"
    echo ""
fi

# Initialize variables
SKIP_WEBINOLY=""
WEBY_VERSION=""
STACK_NAME=""
ERRORS=0

# Check if Webinoly is already installed
if [[ -f /opt/webinoly/webinoly.conf ]]; then
    echo -e "${YELLOW}Webinoly is already installed!${NC}"
    read -p "Do you want to reinstall/update? (y/N): " reinstall
    reinstall="${reinstall:-n}"

    if [[ "${reinstall,,}" != "y" ]]; then
        echo -e "${BLUE}Skipping Webinoly installation, will only install Anubis feature...${NC}"
        SKIP_WEBINOLY="true"
    else
        echo -e "${YELLOW}Backing up existing installation...${NC}"
        tar -Pcf "${HOME}/.webinoly-conf-restore_dont-remove" /opt/webinoly/webinoly.conf
        echo -e "${GREEN}✓ Backup created${NC}"
    fi
fi

echo ""

# Installation type selection
if [[ -z "${SKIP_WEBINOLY:-}" ]]; then
    echo -e "${BLUE}Select installation type:${NC}"
    echo "  1 - HTML Server (Nginx only)"
    echo "  2 - PHP Server (Nginx + PHP)"
    echo "  3 - LEMP Server (Nginx + PHP + MySQL) ${DIM}[Default]${NC}"
    echo "  0 - Clean (Only Webinoly app, no stack)"
    echo ""
    read -p "Enter option (0-3): " setup
    setup="${setup:-3}"

    if ! [[ "${setup}" =~ ^[0-3]$ ]]; then
        echo -e "${RED}Invalid option, using default (3 - LEMP)${NC}"
        setup=3
    fi
    echo ""
fi

# Copy local files to temp directory for installation
TEMP_DIR=$(mktemp -d)
echo -e "${BLUE}Preparing installation files...${NC}"

# Copy all files to temp directory
cp -r "${SCRIPT_DIR}"/* "${TEMP_DIR}/"

# Create tarball from local files
cd "${TEMP_DIR}"
tar -czf "${TEMP_TAR}" \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='*.md' \
    --exclude='tests' \
    --exclude='install*.sh' \
    --exclude='weby' \
    lib/ templates/ usr/

if [[ ! -s "${TEMP_TAR}" ]]; then
    echo -e "${RED}[ERROR] Failed to create installation package!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Installation package created${NC}"
echo ""

# Install Webinoly
if [[ -z "${SKIP_WEBINOLY:-}" ]]; then
    echo -e "${YELLOW}${BOLD}Installing Webinoly...${NC}"
    echo ""

    # Create Webinoly directory
    mkdir -p /opt/webinoly

    # Extract files
    tar -xzf "${TEMP_TAR}" -C /opt/webinoly

    # Create additional required directories
    mkdir -p /opt/webinoly/templates/source

    # Set permissions
    find /opt/webinoly -type d -exec chmod 755 {} \;
    find /opt/webinoly -type f -exec chmod 644 {} \;
    chmod -f 744 /opt/webinoly/lib/ex-* 2>/dev/null || true
    chmod 755 /opt/webinoly/usr/*

    # Move commands to /usr/bin
    cp /opt/webinoly/usr/* /usr/bin/

    echo -e "${GREEN}✓ Webinoly files installed${NC}"
    echo ""

    # Source the general library
    source /opt/webinoly/lib/general

    # Write app version
    WEBY_VERSION="1.20.0-anubis"
    conf_write app-version "${WEBY_VERSION}"

    echo -e "${BLUE}Webinoly version: ${BOLD}${WEBY_VERSION}${NC}"
    echo ""
fi

# Verify Anubis templates exist
echo -e "${YELLOW}Verifying Anubis feature files...${NC}"

if [[ ! -f /opt/webinoly/templates/template-site-anubis ]]; then
    echo -e "${RED}[ERROR] Anubis templates not found!${NC}"
    echo "Make sure you're running this from the correct directory"
    exit 1
fi

if ! grep -q "anubis_setup()" /opt/webinoly/lib/sites; then
    echo -e "${RED}[ERROR] anubis_setup function not found in lib/sites!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Anubis nginx template${NC}"
echo -e "${GREEN}✓ Anubis docker-compose template${NC}"
echo -e "${GREEN}✓ Anubis bot policy template${NC}"
echo -e "${GREEN}✓ Anubis setup function${NC}"
echo ""

# Install stack based on selection
if [[ -z "${SKIP_WEBINOLY:-}" ]]; then
    source /opt/webinoly/lib/general

    echo -e "${YELLOW}${BOLD}Installing server stack...${NC}"
    echo ""

    case "${setup}" in
        1)
            echo -e "${BLUE}Installing Nginx...${NC}"
            stack -nginx
            STACK_NAME="HTML Server (Nginx)"
            ;;
        2)
            echo -e "${BLUE}Installing Nginx + PHP...${NC}"
            stack -php
            STACK_NAME="PHP Server (Nginx + PHP)"
            ;;
        3)
            echo -e "${BLUE}Installing LEMP Stack (Nginx + PHP + MySQL)...${NC}"
            stack -lemp
            STACK_NAME="LEMP Server"
            ;;
        0)
            echo -e "${BLUE}Clean installation - no stack installed${NC}"
            STACK_NAME="Clean (no stack)"
            ;;
    esac

    echo ""
fi

# Final verification
echo -e "${YELLOW}Running final verification...${NC}"

# Check Webinoly
if [[ ! -f /opt/webinoly/webinoly.conf ]]; then
    echo -e "${RED}✗ Webinoly config not found${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓ Webinoly installed${NC}"
fi

# Check commands
if ! command -v site &> /dev/null; then
    echo -e "${RED}✗ 'site' command not found${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓ 'site' command available${NC}"
fi

# Check Anubis templates
if [[ ! -f /opt/webinoly/templates/template-site-anubis ]]; then
    echo -e "${RED}✗ Anubis nginx template missing${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓ Anubis nginx template${NC}"
fi

if [[ ! -f /opt/webinoly/templates/template-anubis-compose ]]; then
    echo -e "${RED}✗ Anubis compose template missing${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓ Anubis compose template${NC}"
fi

if [[ ! -f /opt/webinoly/templates/template-anubis-botpolicy ]]; then
    echo -e "${RED}✗ Anubis policy template missing${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓ Anubis policy template${NC}"
fi

# Check anubis_setup function
if ! grep -q "anubis_setup()" /opt/webinoly/lib/sites; then
    echo -e "${RED}✗ anubis_setup function missing${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓ anubis_setup function${NC}"
fi

# Check -anubis parameter
if ! grep -q "\-anubis" /opt/webinoly/usr/site; then
    echo -e "${RED}✗ -anubis parameter not documented${NC}"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓ -anubis parameter${NC}"
fi

echo ""

if [[ "${ERRORS}" -gt 0 ]]; then
    echo -e "${RED}${BOLD}Installation completed with ${ERRORS} error(s)!${NC}"
    exit 1
fi

# Success!
echo -e "${GREEN}${BOLD}"
echo "=========================================="
echo "  Installation Successful!"
echo "=========================================="
echo -e "${NC}"
echo ""

if [[ -n "${STACK_NAME:-}" ]]; then
    echo -e "${BLUE}Stack installed: ${BOLD}${STACK_NAME}${NC}"
fi

# Display version (handle both new install and skip scenarios)
if [[ -n "${WEBY_VERSION:-}" ]]; then
    echo -e "${BLUE}Webinoly version: ${BOLD}${WEBY_VERSION}${NC}"
else
    echo -e "${BLUE}Webinoly version: ${BOLD}Existing installation${NC}"
fi
echo ""

echo -e "${GREEN}${BOLD}Webinoly Commands:${NC}"
echo -e "${BLUE}  sudo site domain.com -php${NC}          ${DIM}# Create PHP site${NC}"
echo -e "${BLUE}  sudo site domain.com -wp${NC}           ${DIM}# Create WordPress site${NC}"
echo -e "${BLUE}  sudo site domain.com -ssl=on${NC}       ${DIM}# Enable SSL${NC}"
echo -e "${BLUE}  sudo site -list${NC}                    ${DIM}# List all sites${NC}"
echo ""

echo -e "${GREEN}${BOLD}Anubis Bot Protection:${NC}"
echo -e "${BLUE}  sudo site domain.com -anubis=[IP:PORT]${NC}"
echo ""
echo -e "${DIM}Example:${NC}"
echo -e "${BLUE}  sudo site example.com -anubis=[127.0.0.1:49023]${NC}"
echo ""
echo -e "${DIM}Then start Anubis:${NC}"
echo -e "${BLUE}  cd /opt/anubis/example_com${NC}"
echo -e "${BLUE}  docker-compose up -d${NC}"
echo ""

echo -e "${YELLOW}${BOLD}Important Notes:${NC}"
echo "• Anubis requires Docker to be installed"
echo "• Default Anubis port = Backend port + 10000"
echo "• Configure firewall for ports 80, 443, and 22"
echo "• Documentation: ${SCRIPT_DIR}/ANUBIS_FEATURE.md"
echo ""

echo -e "${BLUE}${BOLD}Next Steps:${NC}"
if ! command -v docker &> /dev/null; then
    echo "1. Install Docker:"
    echo -e "${DIM}   curl -fsSL https://get.docker.com | sh${NC}"
    echo ""
    echo "2. Create a site with Anubis protection:"
else
    echo "1. Create a site with Anubis protection:"
fi
echo -e "${DIM}   sudo site yourdomain.com -anubis=[127.0.0.1:8080]${NC}"
echo ""
if ! command -v docker &> /dev/null; then
    echo "3. Start Anubis container:"
else
    echo "2. Start Anubis container:"
fi
echo -e "${DIM}   cd /opt/anubis/yourdomain_com && docker-compose up -d${NC}"
echo ""
if ! command -v docker &> /dev/null; then
    echo "4. Add SSL certificate:"
else
    echo "3. Add SSL certificate:"
fi
echo -e "${DIM}   sudo site yourdomain.com -ssl=on${NC}"
echo ""

echo -e "${GREEN}Configuration file: ${BOLD}/opt/webinoly/webinoly.conf${NC}"
echo -e "${GREEN}Documentation: ${BOLD}https://webinoly.com/documentation/${NC}"
echo ""

echo -e "${BLUE}${BOLD}"
echo "**********************************************"
echo "  Thank you for using Webinoly + Anubis!"
echo "**********************************************"
echo -e "${NC}"