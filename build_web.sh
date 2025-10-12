#!/bin/bash

echo "Building web version..."
flutter build web --release

echo "Web build completed. Files are in build/web/"
echo "To serve locally, run: python3 -m http.server 8080 -d build/web"