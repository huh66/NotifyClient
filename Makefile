# Makefile for NotifyClient UDR
# Firebird 3.0 UDR Library

# Compiler and flags
CXX = g++
CXXFLAGS = -Wall -fPIC -std=c++11 -O2
LDFLAGS = -shared

# Firebird include paths (adjust if necessary)
FB_INCLUDE = /usr/include/firebird
FB_LIB_DIR = /usr/lib/x86_64-linux-gnu

# UDR plugin directory (standard for Firebird 3.0 on Debian)
UDR_PLUGIN_DIR = /opt/firebird/plugins/udr

# Source files
SRC_DIR = src
SOURCES = $(SRC_DIR)/NotifyClientUDR.cpp
OBJECTS = $(SOURCES:.cpp=.o)

# Target library
TARGET = notify_client_udr.so

# Default target
all: $(TARGET)

# Create library
$(TARGET): $(OBJECTS)
	$(CXX) $(LDFLAGS) -o $@ $^
	@echo "==================================="
	@echo "Build successful!"
	@echo "Library: $(TARGET)"
	@echo "==================================="

# Compile object files
$(SRC_DIR)/%.o: $(SRC_DIR)/%.cpp $(SRC_DIR)/NotifyClientUDR.h
	$(CXX) $(CXXFLAGS) -I$(FB_INCLUDE) -c $< -o $@

# Installation (requires root privileges)
install: $(TARGET)
	@echo "Installing UDR Library..."
	sudo cp $(TARGET) $(UDR_PLUGIN_DIR)/
	sudo chown firebird:firebird $(UDR_PLUGIN_DIR)/$(TARGET)
	sudo chmod 644 $(UDR_PLUGIN_DIR)/$(TARGET)
	@echo "Creating symlink lib$(TARGET)..."
	sudo ln -sf $(UDR_PLUGIN_DIR)/$(TARGET) $(UDR_PLUGIN_DIR)/lib$(TARGET)
	@echo "==================================="
	@echo "Installation successful!"
	@echo "Library installed in: $(UDR_PLUGIN_DIR)"
	@echo "  - $(TARGET)"
	@echo "  - lib$(TARGET) -> $(TARGET)"
	@echo ""
	@echo "Next steps:"
	@echo "1. Execute SQL script: isql -user SYSDBA -password <pwd> <database> -i install.sql"
	@echo "2. Restart Firebird (optional): sudo systemctl restart firebird3.0"
	@echo "==================================="

# Cleanup
clean:
	rm -f $(OBJECTS) $(TARGET)
	@echo "Cleanup completed."

# Test installation (copies to local directory instead of system)
test-install: $(TARGET)
	mkdir -p ./test_plugins/udr
	cp $(TARGET) ./test_plugins/udr/
	@echo "Test installation to ./test_plugins/udr/ completed."

# Help
help:
	@echo "NotifyClient UDR - Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make          - Compiles the UDR Library"
	@echo "  make install  - Installs the library (requires sudo)"
	@echo "  make clean    - Removes generated files"
	@echo "  make test-install - Copies library to local test directory"
	@echo "  make help     - Shows this help"
	@echo ""
	@echo "Configuration:"
	@echo "  FB_INCLUDE     = $(FB_INCLUDE)"
	@echo "  UDR_PLUGIN_DIR = $(UDR_PLUGIN_DIR)"

.PHONY: all install clean test-install help

