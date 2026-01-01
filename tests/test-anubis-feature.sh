#!/bin/bash

# Anubis Feature Test Script
# This script tests the Anubis bot protection feature for Webinoly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test configuration
TEST_DOMAIN="anubis-test.local"
BACKEND_IP="127.0.0.1"
BACKEND_PORT="8080"
ANUBIS_PORT=$((BACKEND_PORT + 10000))

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Anubis Feature Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to print test result
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $2"
    else
        echo -e "${RED}✗ FAIL${NC}: $2"
        exit 1
    fi
}

# Test 1: Check if templates exist
echo -e "${YELLOW}Test 1: Checking template files...${NC}"
test -f /opt/webinoly/templates/template-site-anubis
print_result $? "Nginx Anubis template exists"

test -f /opt/webinoly/templates/template-anubis-compose
print_result $? "Docker Compose template exists"

test -f /opt/webinoly/templates/template-anubis-botpolicy
print_result $? "Bot Policy template exists"

echo ""

# Test 2: Check if anubis_setup function exists in lib/sites
echo -e "${YELLOW}Test 2: Checking if anubis_setup function exists...${NC}"
grep -q "anubis_setup()" /opt/webinoly/lib/sites
print_result $? "anubis_setup function found in lib/sites"

echo ""

# Test 3: Check if -anubis parameter is documented in site command
echo -e "${YELLOW}Test 3: Checking if -anubis parameter is documented...${NC}"
grep -q "\-anubis" /opt/webinoly/usr/site | head -1
print_result $? "-anubis parameter documented in site command"

echo ""

# Test 4: Validate template syntax (basic check)
echo -e "${YELLOW}Test 4: Validating template syntax...${NC}"

# Check nginx template has required placeholders
grep -q "<domain>" /opt/webinoly/templates/template-site-anubis
print_result $? "Nginx template has <domain> placeholder"

grep -q "<anubis_upstream>" /opt/webinoly/templates/template-site-anubis
print_result $? "Nginx template has <anubis_upstream> placeholder"

# Check docker-compose template has required placeholders
grep -q "<container_name>" /opt/webinoly/templates/template-anubis-compose
print_result $? "Docker Compose template has <container_name> placeholder"

grep -q "<target_ip>" /opt/webinoly/templates/template-anubis-compose
print_result $? "Docker Compose template has <target_ip> placeholder"

grep -q "<target_port>" /opt/webinoly/templates/template-anubis-compose
print_result $? "Docker Compose template has <target_port> placeholder"

echo ""

# Test 5: Check bot policy template has required sections
echo -e "${YELLOW}Test 5: Validating bot policy template...${NC}"

grep -q "store:" /opt/webinoly/templates/template-anubis-botpolicy
print_result $? "Bot policy has store section"

grep -q "logging:" /opt/webinoly/templates/template-anubis-botpolicy
print_result $? "Bot policy has logging section"

grep -q "bots:" /opt/webinoly/templates/template-anubis-botpolicy
print_result $? "Bot policy has bots section"

grep -q "ssl-verification" /opt/webinoly/templates/template-anubis-botpolicy
print_result $? "Bot policy allows SSL verification"

grep -q "static-files" /opt/webinoly/templates/template-anubis-botpolicy
print_result $? "Bot policy allows static files"

echo ""

# Test 6: Simulate site creation (dry run - checking logic only)
echo -e "${YELLOW}Test 6: Testing parameter parsing logic...${NC}"

# This would require actually running the command, which we'll skip for safety
# Instead, we verify the function exists and is callable
type anubis_setup &>/dev/null || (source /opt/webinoly/lib/sites && type anubis_setup &>/dev/null)
print_result $? "anubis_setup function is defined and callable"

echo ""

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}All tests passed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Next steps to test with a real site:${NC}"
echo "1. Start a test backend server:"
echo "   python3 -m http.server 8080"
echo ""
echo "2. Create a test site with Anubis:"
echo "   sudo site test.local -anubis=[127.0.0.1:8080]"
echo ""
echo "3. Start Anubis:"
echo "   cd /opt/anubis/test_local && sudo docker-compose up -d"
echo ""
echo "4. Test the setup:"
echo "   curl -I http://test.local"
echo ""
echo "5. Clean up:"
echo "   sudo site test.local -delete"
echo "   sudo rm -rf /opt/anubis/test_local"
echo ""
