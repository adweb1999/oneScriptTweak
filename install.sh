#!/bin/bash
# Mashkal Tweak - Quick Install for iPhone
# This script installs all dependencies and builds the tweak

echo "⚡ Mashkal Overlay - Quick Installer"
echo "===================================="
echo ""

# Colors
RED='[0;31m'
GREEN='[0;32m'
BLUE='[0;34m'
YELLOW='[1;33m'
NC='[0m' # No Color

# Check if running on iPhone
if [[ $(uname -m) != "arm64" && $(uname -m) != "arm64e" ]]; then
    echo "${RED}⚠️  This script is designed for iPhone/iPad${NC}"
    echo "📱 Detected: $(uname -m)"
    exit 1
fi

echo "${GREEN}✅ iPhone detected!${NC}"
echo ""

# Function to check command
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 1. Install Theos if not present
if [ ! -d "$THEOS" ]; then
    echo "${YELLOW}📥 Installing Theos...${NC}"
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"

    if [ $? -ne 0 ]; then
        echo "${RED}❌ Theos installation failed${NC}"
        exit 1
    fi
    echo "${GREEN}✅ Theos installed${NC}"
else
    echo "${GREEN}✅ Theos already installed${NC}"
fi

# 2. Check dependencies
echo ""
echo "${BLUE}🔍 Checking dependencies...${NC}"

DEPS_OK=true

if ! command_exists dpkg-deb; then
    echo "${YELLOW}📥 Installing dpkg...${NC}"
    apt-get update && apt-get install -y dpkg
    DEPS_OK=false
fi

if ! command_exists ldid; then
    echo "${YELLOW}📥 Installing ldid...${NC}"
    apt-get install -y ldid
    DEPS_OK=false
fi

if ! command_exists clang; then
    echo "${YELLOW}📥 Installing clang...${NC}"
    apt-get install -y clang
    DEPS_OK=false
fi

if [ "$DEPS_OK" = true ]; then
    echo "${GREEN}✅ All dependencies installed${NC}"
fi

# 3. Build the tweak
echo ""
echo "${BLUE}🔨 Building Mashkal Tweak...${NC}"
make clean
make package FINALPACKAGE=1

if [ $? -eq 0 ]; then
    echo ""
    echo "${GREEN}🎉 Build successful!${NC}"

    # Find the .deb file
    DEB_FILE=$(ls -t packages/*.deb 2>/dev/null | head -1)

    if [ -f "$DEB_FILE" ]; then
        echo "${BLUE}📦 Package: $DEB_FILE${NC}"

        # Install
        echo ""
        echo "${YELLOW}📲 Installing...${NC}"
        dpkg -i "$DEB_FILE"

        # Respring
        echo ""
        echo "${YELLOW}🔄 Respringing...${NC}"
        killall -9 SpringBoard

        echo ""
        echo "${GREEN}✅ Mashkal Overlay installed successfully!${NC}"
        echo ""
        echo "🔐 Default password: ${YELLOW}halak${NC}"
        echo "⏰ Activation: 7 days"
        echo ""
        echo "⚡ Tap the floating button to open overlay"
    else
        echo "${RED}❌ Package not found${NC}"
    fi
else
    echo "${RED}❌ Build failed!${NC}"
    echo "🔧 Check errors above"
    exit 1
fi
