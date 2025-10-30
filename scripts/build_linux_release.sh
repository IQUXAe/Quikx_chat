#!/bin/bash

set -e

echo "🚀 Building Linux release..."

# Get version from pubspec.yaml
VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | sed 's/+.*//')

# Build Linux
flutter build linux --release

# Create tar.gz
cd build/linux/x64/release/bundle
echo "📦 Creating tar.gz archive..."
tar -czf QuikxChat-${VERSION}-linux-x64.tar.gz *

# Move to root
mv QuikxChat-${VERSION}-linux-x64.tar.gz ../../../../../

cd ../../../../../

echo ""
echo "✅ Build complete!"
ls -lh QuikxChat-${VERSION}-linux-x64.tar.gz
