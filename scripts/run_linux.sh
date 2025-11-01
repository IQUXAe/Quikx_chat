#!/bin/bash

# Load environment variables from .env
set -a
source .env
set +a

# Run Flutter with dart-define
flutter run -d linux \
  --dart-define=V2T_SECRET_KEY="$V2T_SECRET_KEY" \
  --dart-define=V2T_SERVER_URL="$V2T_SERVER_URL"
