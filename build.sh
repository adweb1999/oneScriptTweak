#!/bin/bash
# Mashkal Tweak - Build Script for iPhone
# Run this on your jailbroken iPhone with Theos installed

echo "⚡ Mashkal Overlay - Build Script"
echo "================================="
echo ""

# Check if Theos is installed
if [ ! -d "$THEOS" ]; then
    echo "❌ Theos not found!"
    echo "📥 Install with:"
    echo "   bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)""
    exit 1
fi

echo "✅ Theos found: $THEOS"
echo ""

# Clean previous build
echo "🧹 Cleaning previous build..."
make clean

# Build the tweak
echo "🔨 Building Mashkal Tweak..."
make

# Check if build succeeded
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo "📦 Package created in: packages/"
    ls -la packages/

    echo ""
    echo "📲 Install with:"
    echo "   make install"
    echo ""
    echo "🎉 Or install the .deb file manually"
else
    echo ""
    echo "❌ Build failed!"
    echo "🔧 Check errors above"
    exit 1
fi
