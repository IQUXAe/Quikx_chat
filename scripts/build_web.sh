#!/bin/bash

echo "Building web version..."

# Load .env variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
    echo "✅ Loaded environment variables from .env"
fi

flutter build web --release 

echo "Web build completed. Files are in build/web/"
echo "To serve locally, run: python3 -m http.server 8080 -d build/web"