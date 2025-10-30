# Push Notifications Setup

QuikxChat uses **UnifiedPush** for privacy-focused push notifications.

## What is UnifiedPush?

UnifiedPush is an open standard for push notifications that:
- Doesn't rely on Google Play Services
- Protects your privacy
- Works with self-hosted solutions
- Is compatible with multiple distributors

Official site: https://unifiedpush.org

---

## Quick Setup

### 1. Install a UnifiedPush Distributor

Choose one of these apps:

#### ntfy (Recommended)
- **Google Play**: https://play.google.com/store/apps/details?id=io.heckel.ntfy
- **F-Droid**: https://f-droid.org/packages/io.heckel.ntfy/
- **Self-hosted**: https://ntfy.sh

#### Conversations (XMPP client with UnifiedPush)
- **Google Play**: https://play.google.com/store/apps/details?id=eu.siacs.conversations
- **F-Droid**: https://f-droid.org/packages/eu.siacs.conversations/

#### NextPush (Nextcloud integration)
- **F-Droid**: https://f-droid.org/packages/org.unifiedpush.distributor.nextpush/

---

### 2. Configure Distributor

#### For ntfy:

1. Open **ntfy** app
2. Go to **Settings**
3. Enable **UnifiedPush**
4. Choose server:
   - **ntfy.sh** (public, free)
   - **Your own server** (self-hosted)

#### For Conversations:

1. Open **Conversations**
2. Go to **Settings → Notifications**
3. Enable **UnifiedPush**

---

### 3. Enable in QuikxChat

1. Open **QuikxChat**
2. Go to **Settings → Notifications**
3. Enable **Push Notifications**
4. Select your **UnifiedPush distributor**
5. Done! You should see "Connected" status

---

## Troubleshooting

### Notifications Not Working

#### Check Distributor Status
1. Open distributor app (ntfy, etc.)
2. Verify it's running and connected
3. Check if UnifiedPush is enabled

#### Check QuikxChat Settings
1. **Settings → Notifications**
2. Verify distributor is selected
3. Try **Reconnect** button

#### Check Android Battery Optimization
1. **Android Settings → Apps → QuikxChat**
2. **Battery → Unrestricted**
3. Do the same for your distributor app

#### Check Do Not Disturb
- Disable DND or add QuikxChat to exceptions

---

### Delayed Notifications

This is normal for UnifiedPush:
- Notifications may take 1-5 seconds
- Depends on distributor and network
- Still faster than polling

---

### Multiple Devices

Each device needs:
1. Its own distributor app
2. UnifiedPush configured in QuikxChat
3. Same Matrix account

Notifications will be sent to all devices.

---

## Self-Hosting ntfy

### Docker
```bash
docker run -d \
  --name ntfy \
  -p 80:80 \
  -v /var/cache/ntfy:/var/cache/ntfy \
  binwiederhier/ntfy \
  serve
```

### Docker Compose
```yaml
version: "3.7"
services:
  ntfy:
    image: binwiederhier/ntfy
    container_name: ntfy
    command: serve
    ports:
      - "80:80"
    volumes:
      - /var/cache/ntfy:/var/cache/ntfy
    restart: unless-stopped
```

### Configuration
Create `/etc/ntfy/server.yml`:
```yaml
base-url: "https://ntfy.yourdomain.com"
listen-http: ":80"
cache-file: "/var/cache/ntfy/cache.db"
attachment-cache-dir: "/var/cache/ntfy/attachments"
```

More info: https://docs.ntfy.sh/install/

---

## Advanced Configuration

### Custom ntfy Server in QuikxChat

1. Open distributor app (ntfy)
2. **Settings → Server**
3. Enter your server URL
4. Save and reconnect

### Notification Channels

QuikxChat creates these channels:
- **Messages**: New messages
- **Invites**: Room invitations
- **Calls**: Incoming calls

Configure in **Android Settings → Apps → QuikxChat → Notifications**

---

## Privacy Considerations

### What Data is Sent?

UnifiedPush only sends:
- **Event notification** (that something happened)
- **No message content**
- **No metadata**

Your distributor receives:
- Push endpoint URL
- Encrypted notification payload

### Recommended Setup

For maximum privacy:
1. **Self-host ntfy** on your server
2. Use **end-to-end encryption** (enabled by default in QuikxChat)
3. Use **privacy-focused homeserver** (e.g., your own)

---

## Comparison with Other Solutions

| Feature | UnifiedPush | Google FCM | Apple APNs |
|---------|-------------|------------|------------|
| Privacy | ✅ High | ❌ Low | ❌ Low |
| Self-hosted | ✅ Yes | ❌ No | ❌ No |
| Open source | ✅ Yes | ❌ No | ❌ No |
| No Google dependency | ✅ Yes | ❌ No | ✅ Yes |
| Battery efficient | ✅ Yes | ✅ Yes | ✅ Yes |

---

## FAQ

**Q: Do I need Google Play Services?**  
A: No! UnifiedPush works without Google services.

**Q: Will notifications drain my battery?**  
A: No, UnifiedPush is battery-efficient like FCM.

**Q: Can I use multiple distributors?**  
A: Only one distributor per device, but you can switch anytime.

**Q: Is it free?**  
A: Yes, all UnifiedPush distributors are free and open source.

**Q: What if my distributor app crashes?**  
A: Restart it. QuikxChat will automatically reconnect.

---

## Links

- **UnifiedPush**: https://unifiedpush.org
- **ntfy**: https://ntfy.sh
- **Supported Apps**: https://unifiedpush.org/users/apps/
- **Distributors List**: https://unifiedpush.org/users/distributors/
