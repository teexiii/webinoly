# Anubis Bot Protection Feature

## Overview

This feature adds Anubis bot protection integration to Webinoly, allowing you to protect your sites from malicious bots using the Anubis service running in Docker.

## Architecture

```
Client → Nginx → Anubis (Docker) → Your Backend Application
```

- **Nginx**: Receives requests and proxies to Anubis
- **Anubis**: Analyzes requests and filters bots before forwarding to backend
- **Backend**: Your actual application (e.g., web server on port 8080)

## Usage

### Basic Syntax

```bash
sudo site domain.com -anubis=[IP:PORT]
```

Where:
- `IP:PORT` is your backend application address (e.g., `127.0.0.1:8080`)
- Anubis will automatically be configured on port `PORT + 10000`

### Example

If your backend application runs on `127.0.0.1:49023`:

```bash
sudo site example.com -anubis=[127.0.0.1:49023]
```

This will:
1. Create Anubis Docker setup in `/opt/anubis/example_com/`
2. Configure Anubis to listen on port `59023` (49023 + 10000)
3. Configure Anubis to proxy to your backend at `127.0.0.1:49023`
4. Create nginx configuration at `/etc/nginx/sites-available/example.com`
5. Configure nginx to proxy requests to Anubis

## What Gets Created

### 1. Anubis Directory: `/opt/anubis/domain_com/`

Contains:
- `docker-compose.yml` - Docker Compose configuration for Anubis
- `botPolicy.yaml` - Bot filtering policy configuration

### 2. Nginx Configuration: `/etc/nginx/sites-available/domain.com`

- Full nginx configuration with Anubis proxy
- Security headers (HSTS, X-Frame-Options, etc.)
- SSL support (Let's Encrypt ready)
- Security rules to block sensitive files

### 3. Nginx Upstream: `/etc/nginx/conf.d/upstream_proxy.conf`

Contains the upstream definition for Anubis:
```nginx
upstream domain_com_anubis {
    zone upstreams;
    server 127.0.0.1:59023;
    keepalive 2;
}
```

## Configuration Files

### docker-compose.yml

Located at `/opt/anubis/domain_com/docker-compose.yml`

Key environment variables:
- `BIND`: Anubis listening port (auto-calculated as target_port + 10000)
- `TARGET`: Your backend application URL
- `DIFFICULTY`: Bot challenge difficulty (default: 4)
- `METRICS_BIND`: Prometheus metrics port
- `SECRET_KEY`: Random secret for session persistence
- `FORCED_LANGUAGE`: UI language (default: "vi" for Vietnamese)

### botPolicy.yaml

Located at `/opt/anubis/domain_com/botPolicy.yaml`

Defines bot filtering rules:
- **ALLOW** SSL verification paths (`/.well-known/`)
- **ALLOW** static assets (images, CSS, JS, etc.)
- Custom rules can be added

## Step-by-Step Setup

### 1. Create the Site with Anubis

```bash
sudo site example.com -anubis=[127.0.0.1:8080]
```

You'll see output like:
```
Creating Anubis directory: /opt/anubis/example_com
Creating docker-compose.yml...
Creating botPolicy.yaml...

========================================
Anubis Bot Protection Setup Complete!
========================================

Directory: /opt/anubis/example_com
Target: 127.0.0.1:8080
Anubis Port: 18080
Upstream: example_com_anubis

Next steps:
1. Review and edit: /opt/anubis/example_com/docker-compose.yml
2. Review and edit: /opt/anubis/example_com/botPolicy.yaml
3. Start Anubis: cd /opt/anubis/example_com && docker-compose up -d
4. Check logs: docker logs -f anubis_example_com
5. Monitor metrics: http://127.0.0.1:8080/metrics
```

### 2. Review Configuration Files

```bash
# Review docker-compose.yml
sudo nano /opt/anubis/example_com/docker-compose.yml

# Review botPolicy.yaml
sudo nano /opt/anubis/example_com/botPolicy.yaml
```

### 3. Start Anubis Container

```bash
cd /opt/anubis/example_com
sudo docker-compose up -d
```

### 4. Verify Anubis is Running

```bash
# Check container status
sudo docker ps | grep anubis

# Check logs
sudo docker logs -f anubis_example_com

# Test health endpoint
curl http://127.0.0.1:18080/health
```

### 5. Test Nginx Configuration

```bash
# Test nginx config syntax
sudo nginx -t

# If OK, reload nginx (Webinoly does this automatically)
sudo systemctl reload nginx
```

### 6. Test the Complete Setup

```bash
# Test HTTP (should redirect to HTTPS if SSL is enabled)
curl -I http://example.com

# Test HTTPS (after setting up SSL)
curl -I https://example.com

# Test from browser
# Visit http://example.com or https://example.com
```

## Adding SSL Certificate

After setting up Anubis, add SSL:

```bash
sudo site example.com -ssl=on
```

This will:
1. Obtain Let's Encrypt certificate
2. Configure HTTPS in nginx
3. Anubis will automatically see HTTPS requests via X-Forwarded-Proto header

## Monitoring & Troubleshooting

### Check Anubis Logs

```bash
sudo docker logs -f anubis_example_com
```

### Check Nginx Logs

```bash
# Access log
sudo tail -f /var/log/nginx/example_com.access.log

# Error log
sudo tail -f /var/log/nginx/example_com.error.log
```

### Check Anubis Metrics (Prometheus format)

```bash
curl http://127.0.0.1:8080/metrics
```

### Restart Anubis

```bash
cd /opt/anubis/example_com
sudo docker-compose restart
```

### Stop Anubis

```bash
cd /opt/anubis/example_com
sudo docker-compose down
```

### Rebuild Anubis

```bash
cd /opt/anubis/example_com
sudo docker-compose down
sudo docker-compose up -d
```

## Customization

### Adjusting Bot Difficulty

Edit `/opt/anubis/example_com/docker-compose.yml`:

```yaml
DIFFICULTY: "5"  # Range: 1-10 (higher = harder for bots)
```

Then restart:
```bash
cd /opt/anubis/example_com
sudo docker-compose restart
```

### Adding Custom Bot Rules

Edit `/opt/anubis/example_com/botPolicy.yaml`:

```yaml
bots:
  # Block specific paths
  - name: admin-protection
    path_regex: ^/admin/.*$
    action: BLOCK

  # Allow specific user agents
  - name: allow-googlebot
    user_agent_regex: Googlebot
    action: ALLOW
```

Then restart Anubis.

### Changing Target Backend

If your backend moves to a different port:

1. Edit `/opt/anubis/example_com/docker-compose.yml`
2. Update the `TARGET` environment variable
3. Restart: `sudo docker-compose restart`

## Testing Guide

### Test 1: Basic Connectivity

```bash
# Test backend is running
curl http://127.0.0.1:8080

# Test Anubis is running
curl http://127.0.0.1:18080

# Test nginx is proxying
curl http://example.com
```

### Test 2: Bot Protection

```bash
# Normal browser request (should work)
curl -A "Mozilla/5.0" http://example.com

# Bot request (may be challenged)
curl -A "BadBot/1.0" http://example.com
```

### Test 3: Static Files Bypass

```bash
# Static files should bypass Anubis challenge
curl http://example.com/style.css
curl http://example.com/script.js
curl http://example.com/image.png
```

### Test 4: SSL Verification Bypass

```bash
# Let's Encrypt verification should work
curl http://example.com/.well-known/acme-challenge/test
```

### Test 5: Security Headers

```bash
# Check security headers are present
curl -I https://example.com | grep -E "(Strict-Transport-Security|X-Frame-Options|X-Content-Type-Options)"
```

### Test 6: Metrics

```bash
# Check Prometheus metrics
curl http://127.0.0.1:8080/metrics
```

## Port Calculation

The Anubis port is automatically calculated as:

```
Anubis Port = Backend Port + 10000
```

Examples:
- Backend: `8080` → Anubis: `18080`
- Backend: `3000` → Anubis: `13000`
- Backend: `49023` → Anubis: `59023`

Metrics port is the same as backend port.

## File Locations Summary

| File | Location |
|------|----------|
| Docker Compose | `/opt/anubis/domain_com/docker-compose.yml` |
| Bot Policy | `/opt/anubis/domain_com/botPolicy.yaml` |
| Nginx Site Config | `/etc/nginx/sites-available/domain.com` |
| Nginx Upstream | `/etc/nginx/conf.d/upstream_proxy.conf` |
| Access Logs | `/var/log/nginx/domain_com.access.log` |
| Error Logs | `/var/log/nginx/domain_com.error.log` |
| Template (nginx) | `/opt/webinoly/templates/template-site-anubis` |
| Template (compose) | `/opt/webinoly/templates/template-anubis-compose` |
| Template (policy) | `/opt/webinoly/templates/template-anubis-botpolicy` |

## Docker Commands Quick Reference

```bash
# View all Anubis containers
sudo docker ps | grep anubis

# View logs
sudo docker logs anubis_example_com

# Follow logs
sudo docker logs -f anubis_example_com

# Restart container
sudo docker restart anubis_example_com

# Stop container
sudo docker stop anubis_example_com

# Start container
sudo docker start anubis_example_com

# Remove container (will be recreated by docker-compose)
sudo docker rm -f anubis_example_com

# View container stats
sudo docker stats anubis_example_com
```

## Nginx Commands Quick Reference

```bash
# Test configuration
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx

# Restart nginx
sudo systemctl restart nginx

# View nginx status
sudo systemctl status nginx

# Edit site configuration
sudo nano /etc/nginx/sites-available/example.com

# Disable site
sudo rm /etc/nginx/sites-enabled/example.com
sudo systemctl reload nginx

# Enable site
sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/
sudo systemctl reload nginx
```

## Troubleshooting Common Issues

### Issue 1: Anubis container won't start

**Check logs:**
```bash
sudo docker logs anubis_example_com
```

**Common causes:**
- Port already in use
- Invalid TARGET format
- Missing botPolicy.yaml

**Solution:**
```bash
# Check if port is in use
sudo netstat -tlnp | grep 18080

# Verify files exist
ls -la /opt/anubis/example_com/
```

### Issue 2: 502 Bad Gateway from Nginx

**Cause:** Anubis is not running or not responding

**Check:**
```bash
# Is Anubis running?
sudo docker ps | grep anubis

# Is Anubis listening?
curl http://127.0.0.1:18080/health
```

**Solution:**
```bash
cd /opt/anubis/example_com
sudo docker-compose up -d
```

### Issue 3: Backend not receiving requests

**Check Anubis logs:**
```bash
sudo docker logs -f anubis_example_com
```

**Verify TARGET is correct:**
```bash
sudo grep TARGET /opt/anubis/example_com/docker-compose.yml
```

### Issue 4: SSL certificate errors

**Issue:** Nginx config references SSL files that don't exist

**Solution:** Either:
1. Comment out SSL server block in `/etc/nginx/sites-available/example.com`
2. Or run: `sudo site example.com -ssl=on`

### Issue 5: Metrics not accessible

**Check metrics port:**
```bash
sudo grep METRICS_BIND /opt/anubis/example_com/docker-compose.yml
```

**Test:**
```bash
curl http://127.0.0.1:8080/metrics
```

## Advanced Configuration

### Using External Database for Bot Storage

Edit `botPolicy.yaml`:

```yaml
store:
  backend: redis
  redis:
    addr: "localhost:6379"
    password: "your-password"
    db: 0
```

### Custom Logging

Edit `docker-compose.yml`:

```yaml
logging:
  sink: file
  file: /var/log/anubis/bot.log
```

### Multiple Language Support

Change `FORCED_LANGUAGE` in `docker-compose.yml`:

```yaml
FORCED_LANGUAGE: "en"  # English
FORCED_LANGUAGE: "vi"  # Vietnamese
FORCED_LANGUAGE: "fr"  # French
```

## Security Considerations

1. **Always use HTTPS** in production
2. **Review bot policies** regularly
3. **Monitor metrics** for unusual patterns
4. **Keep Anubis image updated**: `sudo docker pull digitop/anubis:v1-22-1`
5. **Protect metrics endpoint** (add nginx auth if exposed)
6. **Backup configurations** before making changes

## Performance Tuning

### Nginx Keepalive

Already configured in upstream block:
```nginx
keepalive 2;
```

Increase for high-traffic sites:
```nginx
keepalive 32;
```

### Anubis Concurrency

Add to `docker-compose.yml`:
```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 1G
```

## Integration with Webinoly Commands

The Anubis feature integrates with existing Webinoly commands:

```bash
# List sites (will show Anubis-enabled sites)
sudo site -list

# Delete site (also stops Anubis container)
sudo site example.com -delete

# Disable site
sudo site example.com -off

# Enable site
sudo site example.com -on
```

Note: Currently, deleting a site does NOT automatically remove the Anubis directory. You must manually remove it:

```bash
sudo rm -rf /opt/anubis/example_com
```

## Future Enhancements

Potential improvements for this feature:

1. Auto-cleanup Anubis directory on site deletion
2. Support for Anubis in subfolders
3. Integration with Webinoly caching
4. Auto-update Anubis Docker image
5. Web UI for managing bot policies
6. Anubis cluster support (multiple instances)
