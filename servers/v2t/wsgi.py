import sys
import os

# Path to your project (change yourusername to your username)
path = '/home/yourusername/v2t'
if path not in sys.path:
    sys.path.append(path)

# Environment variables
os.environ['V2T_SECRET_KEY'] = 'your-super-secret-key-change-this'
os.environ['GEMINI_API_KEYS'] = 'key1,key2,key3'  # Add all your keys separated by comma

from server import app as application
