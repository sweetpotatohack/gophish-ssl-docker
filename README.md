# GoPhish SSL Docker

Complete GoPhish Docker setup with Let's Encrypt SSL support for HTTPS phishing campaigns.

## Features

- **Containerized GoPhish**: Complete Docker setup with Ubuntu 22.04 base
- **SSL/TLS Support**: Let's Encrypt certificates for HTTPS on port 443
- **Admin Panel**: Secure admin interface on port 3333 with self-signed certificates
- **Automated SSL Management**: Built-in scripts for certificate renewal and management
- **Easy Deployment**: Docker Compose orchestration for simple setup

## Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/sweetpotatohack/gophish-ssl-docker.git
   cd gophish-ssl-docker
   ```

2. **Configure your domain**: 
   - Point your domain to your server's IP address
   - Update `config.json` with your domain if needed

3. **Obtain SSL certificates**:
   ```bash
   sudo ./ssl-manager.sh obtain your-domain.com your-email@domain.com
   ```

4. **Build and start the container**:
   ```bash
   docker-compose up -d --build
   ```

5. **Access the admin panel**:
   - Navigate to `https://your-domain.com:3333`
   - Default login: `admin` / `gophish`

## SSL Certificate Management

The `ssl-manager.sh` script provides complete SSL certificate management:

### Obtain new certificates:
```bash
sudo ./ssl-manager.sh obtain your-domain.com your-email@domain.com
```

### Renew existing certificates:
```bash
sudo ./ssl-manager.sh renew
```

### Check certificate status:
```bash
sudo ./ssl-manager.sh status
```

### Restart the container:
```bash
sudo ./ssl-manager.sh restart
```

### Install certificates to running container:
```bash
sudo ./ssl-manager.sh install
```

## Container Management

### Start the service:
```bash
docker-compose up -d
```

### Stop the service:
```bash
docker-compose down
```

### View logs:
```bash
docker-compose logs -f
```

### Rebuild and restart:
```bash
docker-compose down
docker-compose up -d --build
```

## Configuration

### GoPhish Configuration (`config.json`)
- **Admin Server**: Port 3333 with TLS (self-signed certificates)
- **Phish Server**: Port 443 with Let's Encrypt certificates
- **Database**: SQLite stored in persistent volume

### Docker Configuration
- **Ports**: 443 (HTTPS phishing), 3333 (Admin panel)
- **Volumes**: 
  - `./ssl:/opt/gophish/ssl` - SSL certificates
  - `gophish_data:/opt/gophish` - Persistent data

## Directory Structure

```
gophish-ssl-docker/
├── Dockerfile              # Container definition
├── docker-compose.yml      # Orchestration configuration
├── config.json            # GoPhish configuration
├── ssl-manager.sh          # SSL certificate management script
└── README.md              # This file
```

## SSL Certificate Locations

- **Let's Encrypt certificates**: `/etc/letsencrypt/live/your-domain.com/`
- **Container SSL directory**: `./ssl/`
- **Admin panel certificates**: Auto-generated self-signed certificates

## Troubleshooting

### Certificate Issues
1. Ensure your domain points to the correct IP
2. Check firewall settings (ports 80, 443, 3333)
3. Verify certificate installation with `./ssl-manager.sh status`

### Container Issues
1. Check logs: `docker-compose logs -f`
2. Verify port availability: `netstat -tlnp | grep -E ':(80|443|3333)'`
3. Restart services: `./ssl-manager.sh restart`

### Connection Issues
1. Test HTTPS access: `curl -I https://your-domain.com`
2. Test admin panel: `curl -k -I https://your-domain.com:3333`
3. Check container status: `docker-compose ps`

## Security Notes

⚠️ **Important**: This setup is intended for authorized penetration testing and security awareness training only. Ensure you have proper authorization before conducting any phishing simulations.

- Change default admin credentials immediately
- Use strong passwords for admin access
- Regularly update SSL certificates
- Monitor access logs for unauthorized usage

## License

This project is provided as-is for educational and authorized security testing purposes.

## Support

For issues and questions, please use the GitHub issues page.
