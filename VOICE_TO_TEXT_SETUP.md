# Настройка Voice to Text

## Что сделано:

✅ Сервер на Python для PythonAnywhere
✅ Балансировка нагрузки между Gemini API ключами
✅ Защита от несанкционированного доступа (HMAC)
✅ Аудио НЕ сохраняется на диск
✅ Интеграция в приложение
✅ Кнопка преобразования голоса в текст

## Следующие шаги:

### 1. Настройте .env файл

```bash
cp .env.example .env
nano .env
```

Заполните:
```
V2T_SECRET_KEY=ваш-секретный-ключ
V2T_SERVER_URL=https://iquxae.pythonanywhere.com
```

Сгенерируйте секретный ключ:
```bash
python3 -c "import secrets; print(secrets.token_urlsafe(32))"
```

### 2. Разверните сервер на PythonAnywhere

Следуйте инструкции: `servers/v2t/DEPLOY.md`

### 3. Установите зависимости

```bash
flutter pub get
```

### 4. Соберите приложение

```bash
./scripts/build_with_secrets.sh
```

Или для разработки:
```bash
flutter run \
  --dart-define=V2T_SECRET_KEY="ваш-ключ" \
  --dart-define=V2T_SERVER_URL="https://iquxae.pythonanywhere.com"
```

## Как использовать:

1. Откройте чат
2. Зажмите кнопку микрофона для записи
3. Нажмите кнопку 📝 (текст) для преобразования в текст
4. Или нажмите кнопку отправки для отправки голосового сообщения

## Безопасность:

Читайте: `servers/v2t/SECURITY_FAQ.md`

**Коротко:**
- ✅ Ключи защищены
- ✅ Аудио не сохраняется
- ✅ Только авторизованные запросы
- ✅ Без секретного ключа никто не может использовать ваш сервер
