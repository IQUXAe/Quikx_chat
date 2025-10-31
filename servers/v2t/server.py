from flask import Flask, request, jsonify
from flask_cors import CORS
import google.generativeai as genai
import hashlib
import hmac
import time
import os
import uuid
from threading import Lock, Semaphore
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor

app = Flask(__name__)
CORS(app)

# Thread pool for parallel processing
executor = ThreadPoolExecutor(max_workers=10)

# Max audio size (25 MB)
MAX_AUDIO_SIZE = 25 * 1024 * 1024

# Secret key for request authentication
SECRET_KEY = os.environ.get('V2T_SECRET_KEY', 'change-this-secret-key')

# List of Gemini API keys
API_KEYS = [key.strip() for key in os.environ.get('GEMINI_API_KEYS', '').split(',') if key.strip()]

# API key usage statistics
api_stats = defaultdict(lambda: {'count': 0, 'last_used': 0, 'semaphore': Semaphore(5)})
stats_lock = Lock()

# Cache for rate limiting
request_cache = {}
cache_lock = Lock()

def verify_signature(data, signature):
    """Verify HMAC signature of request"""
    expected = hmac.new(SECRET_KEY.encode(), data.encode(), hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, signature)

def select_api_key():
    """Select least loaded API key
    
    Logic:
    1. Reset counters older than 60 seconds
    2. Select key with minimum request count
    3. Semaphore limits 5 parallel requests per key
    """
    with stats_lock:
        current_time = time.time()
        for key in api_stats:
            if current_time - api_stats[key]['last_used'] > 60:
                api_stats[key]['count'] = 0
        
        selected = min(API_KEYS, key=lambda k: api_stats[k]['count'])
        api_stats[selected]['count'] += 1
        api_stats[selected]['last_used'] = current_time
        return selected, api_stats[selected]['semaphore']

@app.route('/v2t', methods=['POST'])
def voice_to_text():
    """Convert voice to text via Gemini API"""
    
    # Verify signature
    signature = request.headers.get('X-Signature')
    if not signature:
        return jsonify({'error': 'Missing signature'}), 401
    
    # Get timestamp for replay attack protection
    timestamp = request.headers.get('X-Timestamp')
    if not timestamp:
        return jsonify({'error': 'Missing timestamp'}), 401
    
    # Check request validity (not older than 5 minutes)
    try:
        if abs(time.time() - float(timestamp)) > 300:
            return jsonify({'error': 'Request expired'}), 401
    except ValueError:
        return jsonify({'error': 'Invalid timestamp'}), 401
    
    # Verify signature
    signature_data = f"{timestamp}"
    if not verify_signature(signature_data, signature):
        return jsonify({'error': 'Invalid signature'}), 403
    
    # Get audio file
    if 'audio' not in request.files:
        return jsonify({'error': 'No audio file'}), 400
    
    audio_file = request.files['audio']
    request_id = str(uuid.uuid4())
    filename = audio_file.filename or 'unknown'
    
    audio_data = None
    try:
        # Read audio to memory (not saved to disk)
        audio_data = audio_file.read()
        
        # DoS protection: check file size
        if len(audio_data) > MAX_AUDIO_SIZE:
            print(f"[{request_id}] Audio too large: {len(audio_data)} bytes")
            return jsonify({'error': 'Audio too large'}), 413
        
        print(f"[{request_id}] Processing {filename} ({len(audio_data)} bytes)")
        
        # Determine MIME type by file extension
        if filename.endswith('.ogg'):
            mime_type = 'audio/ogg'
        elif filename.endswith('.m4a'):
            mime_type = 'audio/mp4'
        elif filename.endswith('.wav'):
            mime_type = 'audio/wav'
        elif filename.endswith('.mp3'):
            mime_type = 'audio/mpeg'
        else:
            mime_type = audio_file.content_type or 'audio/ogg'
        
        # Try all API keys in sequence
        for attempt in range(len(API_KEYS)):
            try:
                api_key, semaphore = select_api_key()
                
                with semaphore:
                    genai.configure(api_key=api_key)
                    model = genai.GenerativeModel('gemini-2.5-flash-lite')
                    
                    response = model.generate_content([
                        "Transcribe this audio to text. Return only the transcribed text without any additional comments.",
                        {"mime_type": mime_type, "data": audio_data}
                    ])
                
                print(f"[{request_id}] Success")
                return jsonify({'text': response.text}), 200
                
            except Exception as e:
                print(f"[{request_id}] Attempt {attempt + 1} failed: {str(e)}")
                if attempt == len(API_KEYS) - 1:
                    return jsonify({'error': 'Service temporarily unavailable'}), 503
                continue
        
    except Exception as e:
        print(f"[{request_id}] Error: {str(e)}")
        return jsonify({'error': 'Processing failed'}), 500
    finally:
        if audio_data is not None:
            del audio_data

@app.route('/health', methods=['GET'])
def health():
    """Check server health"""
    return jsonify({'status': 'ok', 'api_keys_count': len(API_KEYS)}), 200

if __name__ == '__main__':
    if not API_KEYS:
        print("WARNING: No API keys configured. Set GEMINI_API_KEYS environment variable.")
    app.run(host='0.0.0.0', port=5000)
