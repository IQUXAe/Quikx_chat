#!/usr/bin/env python3

import sys
import os

# Добавляем путь к директории с приложением
path = '/home/iquxae/mysite'
if path not in sys.path:
    sys.path.append(path)

# Импортируем улучшенное приложение
from app import app as application

if __name__ == "__main__":
    application.run()