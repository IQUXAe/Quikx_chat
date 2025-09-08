#!/bin/bash
set -e

echo "🔨 Building AppImage for Simple Messenger..."

# Build Linux version
flutter build linux --release

# Clean and prepare AppDir
rm -rf SimpleMessenger.AppDir/usr/bin/*
mkdir -p SimpleMessenger.AppDir/usr/bin

# Copy built application
cp -r build/linux/x64/release/bundle/* SimpleMessenger.AppDir/usr/bin/

# Rename executable file
mv SimpleMessenger.AppDir/usr/bin/simple_messenger SimpleMessenger.AppDir/usr/bin/simplemessenger

# Build AppImage
if [ -f "./appimagetool" ]; then
    ./appimagetool SimpleMessenger.AppDir Simple_Messenger-x86_64.AppImage
    echo "✅ AppImage built: Simple_Messenger-x86_64.AppImage"
elif command -v appimagetool &> /dev/null; then
    appimagetool SimpleMessenger.AppDir Simple_Messenger-x86_64.AppImage
    echo "✅ AppImage built: Simple_Messenger-x86_64.AppImage"
else
    echo "❌ appimagetool not found. Install AppImageKit"
    exit 1
fi