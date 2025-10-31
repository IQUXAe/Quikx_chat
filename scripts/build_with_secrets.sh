#!/bin/bash

# Загружаем переменные из .env файла
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Сборка с секретными ключами
flutter build apk \
  --dart-define=V2T_SECRET_KEY="$V2T_SECRET_KEY" \
  --dart-define=V2T_SERVER_URL="$V2T_SERVER_URL" \
  --release
