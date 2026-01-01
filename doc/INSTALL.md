# Installation Guide - Webinoly + Anubis

This guide shows you how to install Webinoly with the Anubis bot protection feature from scratch.

## Quick Installation

### One-Command Install

```bash
wget -O install.sh https://your-repo-url/install.sh && sudo bash install.sh
```

Or if you have the repository locally:

```bash
git clone https://github.com/yourusername/webinoly.git
cd webinoly
sudo bash install.sh
```

## Step-by-Step Installation

### 1. Download or Clone Repository

**Option A: Git Clone**
```bash
git clone https://github.com/yourusername/webinoly.git
cd webinoly
```

**Option B: Download ZIP**
```bash
wget https://github.com/yourusername/webinoly/archive/master.zip
unzip master.zip
cd webinoly-master
```

### 2. Run Installer

```bash
sudo bash install.sh
```

### 3. Select Installation Type

When prompted, choose:
- **1** - HTML Server (Nginx only)
- **2** - PHP Server (Nginx + PHP)
- **3** - LEMP Server (Nginx + PHP + MySQL) - **Recommended**
- **0** - Clean (Only Webinoly app, install stack later)

### 4. Wait for Installation

The installer will:
- ✓ Check OS compatibility
- ✓ Install Webinoly from local files
- ✓ Add Anubis feature templates
- ✓ Install selected server stack
- ✓ Configure all components
- ✓ Verify installation

## What Gets Installed

### Webinoly Components
- **/opt/webinoly/** - Main installation directory
- **/opt/webinoly/lib/** - Core libraries
- **/opt/webinoly/templates/** - Configuration templates
- **/usr/bin/site** - Site management command
- **/usr/bin/stack** - Stack management command
- **/usr/bin/webinoly** - Main command
- **/usr/bin/httpauth** - HTTP authentication
- **/usr/bin/log** - Log management

### Anubis Components
- **/opt/webinoly/templates/template-site-anubis** - Nginx config template
- **/opt/webinoly/templates/template-anubis-compose** - Docker Compose template
- **/opt/webinoly/templates/template-anubis-botpolicy** - Bot policy template
- **anubis_setup()** function in **/opt/webinoly/lib/sites**

### Server Stack (if selected)

**Option 1 - HTML Server:**
- Nginx

**Option 2 - PHP Server:**
- Nginx
- PHP-FPM (latest version)

**Option 3 - LEMP Server:**
- Nginx
- PHP-FPM
- MySQL/MariaDB
- Redis (optional)
- Memcached (optional)

## System Requirements

### Supported OS
- Ubuntu 22.04 LTS (Jammy Jellyfish)
- Ubuntu 24.04 LTS (Noble Numbat)

### Minimum Requirements
- **RAM:** 512 MB (1 GB recommended)
- **Disk:** 5 GB free space
- **CPU:** 1 core (2+ recommended)

### Required for Anubis
- **Docker:** Must be installed separately
- **Docker Compose:** Included with Docker

## Post-Installation

### 1. Install Docker (Required for Anubis)

```bash
# Install Docker
curl -fsSL https://get.docker.com | sudo sh

# Add your user to docker group (optional)
sudo usermod -aG docker $USER

# Verify installation
docker --version
docker-compose --version
```

### 2. Verify Webinoly Installation

```bash
# Check version
sudo webinoly -version

# List available commands
sudo webinoly -help

# Check server status
sudo webinoly -info
```

### 3. Test Site Creation

```bash
# Create a test PHP site
sudo site test.local -php

# List sites
sudo site -list

# Delete test site
sudo site test.local -delete
```

### 4. Test Anubis Feature

```bash
# Start a test backend (Python HTTP server)
python3 -m http.server 8080 &

# Create site with Anubis
sudo site test.local -anubis=[127.0.0.1:8080]

# Start Anubis container
cd /opt/anubis/test_local
sudo docker-compose up -d

# Check logs
sudo docker logs -f anubis_test_local

# Clean up
sudo site test.local -delete
sudo rm -rf /opt/anubis/test_local
```

## Usage Examples

### Create Regular Sites

```bash
# HTML site
sudo site example.com -html

# PHP site
sudo site example.com -php

# WordPress site
sudo site example.com -wp

# Proxy site
sudo site example.com -proxy=[http://localhost:3000]
```

### Create Site with Anubis Protection

```bash
# Your app runs on port 8080
sudo site example.com -anubis=[127.0.0.1:8080]

# Start Anubis
cd /opt/anubis/example_com
sudo docker-compose up -d

# Add SSL
sudo site example.com -ssl=on

# Check everything
sudo docker ps | grep anubis
sudo docker logs anubis_example_com
curl -I https://example.com
```

### Manage Sites

```bash
# List all sites
sudo site -list

# Get site info
sudo site example.com -info

# Enable site
sudo site example.com -on

# Disable site
sudo site example.com -off

# Delete site
sudo site example.com -delete
```

### Manage Stack

```bash
# Check what's installed
sudo stack -info

# Install Nginx only
sudo stack -nginx

# Install PHP
sudo stack -php

# Install full LEMP
sudo stack -lemp

# Update stack
sudo stack -update
```

## Troubleshooting

### Installation Fails

**Check OS version:**
```bash
lsb_release -a
```

**Check logs:**
```bash
tail -f /var/log/syslog
```

**Reinstall:**
```bash
sudo webinoly -uninstall
sudo bash install.sh
```

### Anubis Not Working

**Check if Docker is installed:**
```bash
docker --version
docker-compose --version
```

**Check if templates exist:**
```bash
ls -la /opt/webinoly/templates/template-*anubis*
```

**Check if function exists:**
```bash
grep -n "anubis_setup" /opt/webinoly/lib/sites
```

**Manual installation:**
```bash
sudo bash install-anubis-feature.sh
```

### Permission Errors

**Fix permissions:**
```bash
sudo find /opt/webinoly -type d -exec chmod 755 {} \;
sudo find /opt/webinoly -type f -exec chmod 644 {} \;
sudo chmod 755 /opt/webinoly/usr/*
```

## Updating

### Update Webinoly

```bash
# Standard update (official version)
sudo webinoly -update

# After official update, reinstall Anubis feature
cd /path/to/webinoly-git
sudo bash install-anubis-feature.sh
```

### Update Anubis Feature Only

```bash
cd /path/to/webinoly-git
git pull
sudo bash install-anubis-feature.sh
```

## Uninstalling

### Uninstall Everything

```bash
# Uninstall Webinoly (removes everything)
sudo webinoly -uninstall

# Remove Anubis containers
sudo docker ps -a | grep anubis | awk '{print $1}' | xargs sudo docker rm -f

# Remove Anubis directories
sudo rm -rf /opt/anubis
```

### Uninstall Anubis Only

```bash
# Stop and remove all Anubis containers
sudo docker ps -a | grep anubis | awk '{print $1}' | xargs sudo docker rm -f

# Remove Anubis directories
sudo rm -rf /opt/anubis

# Restore original Webinoly files
sudo cp /opt/webinoly/lib/sites.backup /opt/webinoly/lib/sites
sudo cp /opt/webinoly/usr/site.backup /opt/webinoly/usr/site

# Remove templates
sudo rm /opt/webinoly/templates/template-*anubis*
```

## Configuration

### Webinoly Config

Edit: `/opt/webinoly/webinoly.conf`

```bash
sudo nano /opt/webinoly/webinoly.conf
```

### Nginx Config

Site configs: `/etc/nginx/sites-available/`

```bash
sudo nano /etc/nginx/sites-available/example.com
```

### Anubis Config

Docker Compose: `/opt/anubis/domain_com/docker-compose.yml`
Bot Policy: `/opt/anubis/domain_com/botPolicy.yaml`

```bash
sudo nano /opt/anubis/example_com/docker-compose.yml
sudo nano /opt/anubis/example_com/botPolicy.yaml
```

## Support & Documentation

- **Webinoly Official Docs:** https://webinoly.com/documentation/
- **Anubis Feature Guide:** [ANUBIS_FEATURE.md](ANUBIS_FEATURE.md)
- **GitHub Issues:** https://github.com/yourusername/webinoly/issues

## Security Best Practices

1. **Always use SSL in production**
   ```bash
   sudo site example.com -ssl=on
   ```

2. **Keep system updated**
   ```bash
   sudo apt update && sudo apt upgrade
   sudo webinoly -update
   ```

3. **Configure firewall**
   ```bash
   sudo ufw allow 22/tcp
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw enable
   ```

4. **Use strong passwords for databases**

5. **Regular backups**
   ```bash
   sudo webinoly -backup
   ```

6. **Monitor Anubis logs**
   ```bash
   sudo docker logs -f anubis_example_com
   ```

## License

Same as Webinoly - GNU General Public License v3.0

## Credits

- **Webinoly:** https://github.com/QROkes/webinoly
- **Anubis Bot Protection:** https://github.com/DigitOP/anubis
