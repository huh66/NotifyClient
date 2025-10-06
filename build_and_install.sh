#!/bin/bash

# Simple Message UDR - Build and installation script
# This script compiles and installs the UDR library

set -e  # Exit on error

echo "=========================================="
echo "Simple Message UDR - Build & Installation"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to display errors
error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

# Function to display warnings
warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

# Function to display success
success() {
    echo -e "${GREEN}$1${NC}"
}

# Check if g++ is installed
if ! command -v g++ &> /dev/null; then
    error "g++ is not installed. Please install it with: sudo apt-get install g++"
fi

# Check if Firebird headers are present
if [ ! -d "/usr/include/firebird" ]; then
    error "Firebird Development Headers not found. Please install them with: sudo apt-get install firebird3.0-dev"
fi

# Step 1: Compilation
echo "Step 1: Compiling UDR library..."
make clean
if make; then
    success "✓ Compilation successful"
else
    error "Compilation failed"
fi
echo ""

# Step 2: Installation
echo "Step 2: Installing UDR library..."
echo "Note: This step requires sudo privileges"
if sudo make install; then
    success "✓ Installation successful"
else
    error "Installation failed"
fi
echo ""

# Step 3: Restart Firebird (optional)
echo "Step 3: Restart Firebird (optional, but recommended)..."
read -p "Do you want to restart Firebird now? (y/n): " restart
if [[ $restart =~ ^[Yy]$ ]]; then
    if sudo systemctl restart firebird3.0; then
        success "✓ Firebird has been restarted"
    else
        warning "Firebird restart failed. The service name might be different."
        echo "Try manually: sudo systemctl restart firebird"
    fi
else
    warning "Firebird was not restarted. Please restart it manually."
fi
echo ""

# Step 4: SQL installation
echo "Step 4: Registering SQL procedure..."
echo ""
echo "To register the procedure in your database, execute:"
echo ""
echo "  isql -user SYSDBA -password <your-password> <database> -i install.sql"
echo ""
echo "Example:"
echo "  isql -user SYSDBA -password masterkey /var/lib/firebird/data/mydb.fdb -i install.sql"
echo ""

read -p "Do you want to execute the SQL script now? (y/n): " runsql
if [[ $runsql =~ ^[Yy]$ ]]; then
    read -p "Database path: " dbpath
    read -p "SYSDBA password: " -s password
    echo ""
    
    if isql -user SYSDBA -password "$password" "$dbpath" -i install.sql; then
        success "✓ SQL procedure has been registered"
    else
        error "SQL registration failed"
    fi
else
    warning "SQL script was not executed. Please execute it manually."
fi
echo ""

# Completion
echo "=========================================="
success "Installation completed!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Make sure a client is listening on port 1526"
echo "2. Test the procedure with:"
echo "   EXECUTE PROCEDURE NOTIFY_CLIENT('Test', 'INFO', 'Subject', 123, 'Message', '', NULL);"
echo "3. Create triggers following the examples in example_trigger.sql"
echo ""
echo "For problems please read README.md or the troubleshooting section."
echo ""

