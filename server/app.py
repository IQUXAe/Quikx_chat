from flask import Flask, jsonify, request

app = Flask(__name__)

# Конфигурация версий
LATEST_VERSION = "0.2.1"
MIN_SUPPORTED_VERSION = "0.1.0"
FORCE_UPDATE = False
DOWNLOAD_URL = "https://github.com/your-repo/releases/latest"

# Локализация
TRANSLATIONS = {
    'en': {
        'update_title': 'Update Available',
        'force_update_title': 'Required Update',
        'force_update_message': 'Update required to continue using the app',
        'release_notes': 'Bug fixes and improvements'
    },
    'ru': {
        'update_title': 'Доступно обновление',
        'force_update_title': 'Обязательное обновление', 
        'force_update_message': 'Требуется обновление для продолжения работы',
        'release_notes': 'Исправления ошибок и улучшения'
    }
}

def parse_version(version_str):
    """Парсит версию в формате x.y.z в кортеж чисел"""
    try:
        return tuple(map(int, version_str.split('.')))
    except (ValueError, AttributeError):
        return (0, 0, 0)

def is_version_lower(current, target):
    """Проверяет, является ли current версия меньше target"""
    current_tuple = parse_version(current)
    target_tuple = parse_version(target)
    return current_tuple < target_tuple

def get_locale():
    """Определяет локаль из заголовков запроса"""
    accept_language = request.headers.get('Accept-Language', 'en')
    # Proper Accept-Language parsing
    languages = [lang.strip().split(';')[0].lower() for lang in accept_language.split(',')]
    for lang in languages:
        if lang.startswith('ru'):
            return 'ru'
    return 'en'

@app.route('/api/updates')
def get_updates():
    # Получаем текущую версию клиента
    current_version = request.args.get('version', '0.0.0')
    locale = get_locale()
    
    # Получаем переводы для текущей локали
    texts = TRANSLATIONS.get(locale, TRANSLATIONS['en'])
    
    # Проверяем, нужно ли обновление
    needs_update = is_version_lower(current_version, LATEST_VERSION)
    needs_force_update = is_version_lower(current_version, MIN_SUPPORTED_VERSION)
    
    response = {
        "latest_version": LATEST_VERSION,
        "current_version": current_version,
        "download_url": DOWNLOAD_URL,
        "force_update": needs_force_update or FORCE_UPDATE,
        "min_supported_version": MIN_SUPPORTED_VERSION,
        "needs_update": needs_update,
        "release_notes": texts['release_notes'],
        "update_title": texts['update_title'],
        "force_update_title": texts['force_update_title'],
        "force_update_message": texts['force_update_message']
    }
    
    return jsonify(response)

@app.route('/api/version')
def get_version():
    """Простой endpoint для получения только версии"""
    return jsonify({
        "latest_version": LATEST_VERSION,
        "min_supported_version": MIN_SUPPORTED_VERSION
    })



if __name__ == '__main__':
    import os
    debug_mode = os.environ.get('FLASK_DEBUG', 'False').lower() == 'true'
    host = os.environ.get('FLASK_HOST', '127.0.0.1')
    port = int(os.environ.get('FLASK_PORT', '5000'))
    app.run(debug=debug_mode, host=host, port=port)