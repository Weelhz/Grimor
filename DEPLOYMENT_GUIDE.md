# BookSphere Deployment Guide

## Overview
BookSphere is a full-stack application with Node.js/TypeScript backend and Flutter cross-platform frontend, designed for deployment on Ubuntu servers with client applications for Windows, Android, and Web.

## Deployment Options

### 1. Ubuntu Server Deployment (Complete Setup)

**Prerequisites:**
- Ubuntu 18.04+ or Debian 10+
- Sudo access
- 2GB+ RAM
- 10GB+ storage

**Quick Deployment:**
```bash
chmod +x deploy_ubuntu_server.sh
./deploy_ubuntu_server.sh
```

**What this installs:**
- Node.js 18 LTS
- PostgreSQL database
- PM2 process manager
- Nginx reverse proxy
- BookSphere server on port 3000
- Firewall configuration

**Manual Configuration:**
1. Update `/opt/bookphere/.env` with your settings
2. Configure SSL certificate (recommended: Let's Encrypt)
3. Update Nginx configuration for your domain

### 2. Web Client Deployment

**Build Web Client:**
```bash
chmod +x build_web_client.sh
./build_web_client.sh
```

**Deploy to Server:**
```bash
# Local deployment
./deploy_web_to_server.sh

# Remote deployment
./deploy_web_to_server.sh SERVER_IP SSH_USER
```

**Manual Deployment:**
1. Build: `cd client && flutter build web --release`
2. Copy: `cp -r build/web/* /var/www/bookphere/`
3. Configure Nginx to serve static files

### 3. Windows Desktop Application

**Build Windows EXE:**
```batch
REM Run on Windows machine
build_windows_exe.bat
```

**Distribution Package:**
- `windows-dist/book_sphere.exe` - Main application
- `windows-dist/install.bat` - Installer script
- `windows-dist/BookSphere.bat` - Smart launcher
- `windows-dist/config.json` - Configuration file

**Installation:**
1. Run `install.bat` as Administrator
2. Configure `config.json` with server URL
3. Launch from Desktop or Start Menu

### 4. Android APK

**Build Android APK:**
```bash
chmod +x build_android_apk.sh
./build_android_apk.sh
```

**Distribution Package:**
- `android-dist/*.apk` - APK files for different architectures
- `android-dist/INSTALL_ANDROID.md` - Installation guide
- `android-dist/check_device.sh` - Compatibility checker

**Installation:**
1. Enable "Unknown Sources" on Android
2. Install appropriate APK for device architecture
3. Configure server connection in app settings

## Universal Deployment Manager

**Interactive Deployment:**
```bash
chmod +x deploy_manager.sh
./deploy_manager.sh
```

**Features:**
- Menu-driven deployment options
- Server health checking
- Build management
- Automated testing

## Configuration

### Server Configuration

**Environment Variables (server/.env):**
```env
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://bookuser:password@localhost:5432/bookphere
JWT_SECRET=your_64_character_secret
JWT_REFRESH_SECRET=your_64_character_refresh_secret
CORS_ORIGIN=https://yourdomain.com
UPLOAD_PATH=/opt/bookphere/uploads
```

**Production Security:**
- Use strong JWT secrets (64+ characters)
- Restrict CORS origins to specific domains
- Enable HTTPS with SSL certificates
- Configure firewall rules
- Regular security updates

### Client Configuration

**Web Client:**
- Automatically uses current domain
- Configure API endpoints in build
- Enable service worker for offline support

**Desktop Client:**
- Edit `config.json` for server settings
- Supports offline mode
- Auto-discovery for local servers

**Mobile Client:**
- Configure in app settings
- Supports multiple server profiles
- Offline synchronization

## Database Setup

**Automatic Setup:**
- Database created during server deployment
- Schema initialized with setup.sql
- Default mood types populated

**Manual Setup:**
```bash
sudo -u postgres psql
CREATE DATABASE bookphere;
CREATE USER bookuser WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE bookphere TO bookuser;
\q

# Initialize schema
psql -U bookuser -d bookphere -f server/database/setup.sql
```

## Monitoring and Maintenance

### Server Monitoring
```bash
# PM2 monitoring
sudo -u bookuser pm2 monit

# View logs
sudo -u bookuser pm2 logs bookphere-server

# Restart server
sudo -u bookuser pm2 restart bookphere-server
```

### Database Maintenance
```bash
# Backup database
pg_dump -U bookuser bookphere > backup.sql

# Restore database
psql -U bookuser bookphere < backup.sql
```

### Log Files
- Application logs: `/var/log/bookphere/`
- Nginx logs: `/var/log/nginx/`
- System logs: `/var/log/syslog`

## Troubleshooting

### Common Issues

**Server not starting:**
1. Check database connection
2. Verify environment variables
3. Check port availability
4. Review logs: `sudo -u bookuser pm2 logs`

**Client connection issues:**
1. Verify server URL in client config
2. Check firewall settings
3. Test with curl: `curl http://server:3000/api/health`
4. Verify CORS configuration

**Database connection failed:**
1. Check PostgreSQL service: `sudo systemctl status postgresql`
2. Verify credentials in DATABASE_URL
3. Test connection: `psql -U bookuser -d bookphere`

**File upload issues:**
1. Check upload directory permissions
2. Verify disk space
3. Check file size limits
4. Review Nginx client_max_body_size

### Performance Optimization

**Server:**
- Use PM2 cluster mode for multiple cores
- Configure Nginx compression
- Enable database connection pooling
- Add Redis for session storage

**Client:**
- Enable PWA features for web client
- Implement lazy loading
- Optimize image compression
- Use offline-first strategies

## Security Considerations

### Production Security Checklist
- [ ] Strong JWT secrets (64+ characters)
- [ ] HTTPS with valid SSL certificate
- [ ] Restricted CORS origins
- [ ] Database user with minimal privileges
- [ ] Regular security updates
- [ ] Firewall configuration
- [ ] Input validation and sanitization
- [ ] Rate limiting enabled
- [ ] Audit logging configured

### File Upload Security
- File type validation
- Size limits enforced
- Virus scanning (recommended)
- Signed URLs for access control
- Isolated upload directory

## Scaling and High Availability

### Horizontal Scaling
1. Load balancer (Nginx/HAProxy)
2. Multiple server instances
3. Shared file storage (NFS/S3)
4. Database clustering/replication

### Vertical Scaling
1. Increase server resources
2. Optimize database queries
3. Add caching layers
4. CDN for static assets

## Backup Strategy

### Automated Backups
```bash
# Daily database backup
0 2 * * * pg_dump -U bookuser bookphere | gzip > /backups/db_$(date +\%Y\%m\%d).sql.gz

# Weekly file backup
0 3 * * 0 tar -czf /backups/files_$(date +\%Y\%m\%d).tar.gz /opt/bookphere/uploads
```

### Recovery Procedures
1. Database restore from backup
2. File recovery from backup
3. Application redeployment
4. DNS/routing updates

## Support and Documentation

### Additional Resources
- `README.md` - Project overview
- `server/database/setup.sql` - Database schema
- `replit.md` - Development notes
- Individual deployment scripts for detailed implementation

### Getting Help
1. Check logs for error messages
2. Verify configuration files
3. Test individual components
4. Review deployment scripts for issues

---