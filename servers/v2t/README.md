# Voice to Text Server

AI-powered voice transcription server using Gemini API with load balancing.

## Features

- ✅ Load balancing across multiple Gemini API keys
- ✅ HMAC authentication
- ✅ Replay attack protection
- ✅ DoS protection (file size limit)
- ✅ Automatic failover between API keys
- ✅ No data logging or storage

## Deploy

### Render.com (Recommended)

1. Push to GitHub
2. Connect to Render.com
3. Set environment variables:
   - `V2T_SECRET_KEY` - your secret key
   - `GEMINI_API_KEYS` - comma-separated API keys
4. Deploy automatically

### PythonAnywhere

1. Upload files to `/home/yourusername/v2t/`
2. Install: `pip install -r requirements.txt --user`
3. Configure `wsgi.py` with your keys
4. Reload web app

## Environment Variables

- `V2T_SECRET_KEY` - Secret key for HMAC authentication
- `GEMINI_API_KEYS` - Comma-separated Gemini API keys (e.g., `key1,key2,key3`)

## API

### POST /v2t

Convert voice to text.

**Headers:**
- `X-Signature` - HMAC-SHA256 signature
- `X-Timestamp` - Unix timestamp

**Body:**
- `audio` - Audio file (max 10 MB)

**Response:**
```json
{"text": "transcribed text"}
```

### GET /health

Check server status.

**Response:**
```json
{"status": "ok", "api_keys_count": 3}
```

## Limits

- Max audio size: 10 MB
- Request timeout: 5 minutes
- Parallel requests per API key: 3
- Total workers: 5

## Security

- HMAC-SHA256 authentication
- Timestamp-based replay protection
- No audio storage (memory only)
- No logging of user data
- CORS enabled
