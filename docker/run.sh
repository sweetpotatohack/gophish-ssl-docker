#!/bin/bash

# SSL Certificate Check and Setup
check_ssl_certs() {
    echo "[INFO] Checking SSL certificates..."
    
    # Check if Let's Encrypt certificates exist
    if [[ -f "./ssl/letsencrypt.crt" && -f "./ssl/letsencrypt.key" ]]; then
        echo "[INFO] Let's Encrypt certificates found - using them for phishing server"
        return 0
    fi
    
    # If no Let's Encrypt certs, create self-signed for testing
    echo "[WARN] No Let's Encrypt certificates found, creating self-signed for phishing server"
    openssl req -newkey rsa:2048 -nodes -keyout "./ssl/letsencrypt.key" \
        -x509 -days 365 -out "./ssl/letsencrypt.crt" \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
    
    chmod 600 "./ssl/letsencrypt.key"
    chmod 644 "./ssl/letsencrypt.crt"
}

# Admin SSL Check
check_admin_ssl() {
    if [[ ! -f "./ssl/gophish_admin.crt" || ! -f "./ssl/gophish_admin.key" ]]; then
        echo "[INFO] Creating admin SSL certificates..."
        openssl req -newkey rsa:2048 -nodes -keyout "./ssl/gophish_admin.key" \
            -x509 -days 365 -out "./ssl/gophish_admin.crt" \
            -subj "/C=US/ST=State/L=City/O=GoPhish/CN=gophish-admin"
        
        chmod 600 "./ssl/gophish_admin.key"
        chmod 644 "./ssl/gophish_admin.crt"
    fi
}

# Main startup sequence
main() {
    echo "==================================="
    echo "    GoPhish SSL Docker Startup"
    echo "==================================="
    
    # Ensure directories exist
    mkdir -p ./ssl ./data ./static ./templates
    
    # Check and setup SSL certificates
    check_admin_ssl
    check_ssl_certs
    
    # Start GoPhish
    echo "[INFO] Starting GoPhish with SSL support..."
    echo "[INFO] Admin panel: https://0.0.0.0:3333"
    echo "[INFO] Phishing server: https://0.0.0.0:443"
    echo "[INFO] Default credentials: admin / gophish"
    echo "==================================="
    
    # Execute GoPhish
    exec ./gophish
}

# Run main function
main "$@"
