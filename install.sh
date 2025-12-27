#!/bin/bash

# Build and Install Script for MacCleaner

set -e

echo "🏗️  Building MacCleaner..."

# Build in release mode
swift build -c release

echo "✅ Build complete!"
echo ""

# Check if /usr/local/bin exists
if [ ! -d "/usr/local/bin" ]; then
    echo "Creating /usr/local/bin directory..."
    sudo mkdir -p /usr/local/bin
fi

# Copy binary
echo "📦 Installing to /usr/local/bin/maccleaner..."
sudo cp .build/release/maccleaner /usr/local/bin/maccleaner
sudo chmod +x /usr/local/bin/maccleaner

echo "✅ Installation complete!"
echo ""
echo "You can now run: maccleaner --help"
echo ""
echo "Example commands:"
echo "  maccleaner scan                    # Scan for large files"
echo "  maccleaner clean --all --dry-run   # Preview cache cleaning"
echo "  maccleaner status                  # Check storage status"
