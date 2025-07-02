#!/bin/bash

# GoPhish SSL Certificate Manager
# Скрипт для управления SSL сертификатами Let's Encrypt

set -e

DOMAIN=${1:-"your_domain"}
EMAIL=${2:-"your_mail"}
SSL_DIR="./ssl"
CONTAINER_NAME="gophish-ssl"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    echo "GoPhish SSL Certificate Manager"
    echo ""
    echo "Использование: $0 [COMMAND] [DOMAIN] [EMAIL]"
    echo ""
    echo "Команды:"
    echo "  obtain    - Получить новый SSL сертификат"
    echo "  renew     - Обновить существующий сертификат"
    echo "  install   - Установить сертификаты в GoPhish"
    echo "  check     - Проверить статус сертификата"
    echo "  restart   - Перезапустить GoPhish контейнер"
    echo "  help      - Показать эту справку"
    echo ""
    echo "Примеры:"
    echo "  $0 obtain auth.bankerlopes.com support@bankerlopes.com"
    echo "  $0 renew"
    echo "  $0 install"
    echo "  $0 check"
}

check_prerequisites() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker не установлен!"
        exit 1
    fi

    if ! command -v certbot &> /dev/null; then
        log_error "Certbot не установлен! Установите: apt install certbot"
        exit 1
    fi
}

stop_container() {
    if docker ps -q -f name=${CONTAINER_NAME} | grep -q .; then
        log_info "Останавливаем контейнер GoPhish..."
        docker stop ${CONTAINER_NAME} || true
    fi
}

start_container() {
    log_info "Запускаем контейнер GoPhish..."
    docker-compose up -d
}

obtain_certificate() {
    log_info "Получение нового SSL сертификата для домена: $DOMAIN"
    
    stop_container
    
    certbot certonly --standalone \
        -d "$DOMAIN" \
        --non-interactive \
        --agree-tos \
        --email "$EMAIL" \
        --force-renewal
    
    install_certificates
    start_container
    
    log_info "SSL сертификат успешно получен и установлен!"
}

renew_certificate() {
    log_info "Обновление SSL сертификата для домена: $DOMAIN"
    
    stop_container
    
    certbot renew --force-renewal
    
    install_certificates
    start_container
    
    log_info "SSL сертификат успешно обновлен!"
}

install_certificates() {
    log_info "Установка SSL сертификатов..."
    
    mkdir -p "$SSL_DIR"
    
    if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
        cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$SSL_DIR/letsencrypt.crt"
        cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$SSL_DIR/letsencrypt.key"
        
        # Устанавливаем правильные права доступа
        chmod 644 "$SSL_DIR/letsencrypt.crt"
        chmod 600 "$SSL_DIR/letsencrypt.key"
        
        log_info "SSL сертификаты успешно установлены в $SSL_DIR/"
    else
        log_error "SSL сертификат не найден для домена $DOMAIN"
        exit 1
    fi
    
    # Генерируем самоподписанный сертификат для админки, если его нет
    if [ ! -f "$SSL_DIR/gophish_admin.crt" ]; then
        log_info "Создание самоподписанного сертификата для админки..."
        openssl req -newkey rsa:2048 -nodes -keyout "$SSL_DIR/gophish_admin.key" \
            -x509 -days 365 -out "$SSL_DIR/gophish_admin.crt" \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=gophish-admin"
        chmod 600 "$SSL_DIR/gophish_admin.key"
        chmod 644 "$SSL_DIR/gophish_admin.crt"
    fi
}

check_certificate() {
    log_info "Проверка SSL сертификата для домена: $DOMAIN"
    
    if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
        echo "=== Информация о сертификате ==="
        openssl x509 -in "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" -noout -subject -issuer -dates
        echo ""
        
        # Проверка срока действия
        expiry_date=$(openssl x509 -in "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" -noout -enddate | cut -d= -f2)
        expiry_timestamp=$(date -d "$expiry_date" +%s)
        current_timestamp=$(date +%s)
        days_left=$(( (expiry_timestamp - current_timestamp) / 86400 ))
        
        echo "Дней до истечения: $days_left"
        
        if [ $days_left -lt 30 ]; then
            log_warn "Сертификат истекает менее чем через 30 дней! Рекомендуется обновление."
        else
            log_info "Сертификат действителен."
        fi
    else
        log_error "SSL сертификат не найден для домена $DOMAIN"
        exit 1
    fi
}

restart_container() {
    log_info "Перезапуск GoPhish контейнера..."
    docker-compose restart
    log_info "Контейнер перезапущен!"
}

# Главная логика
case "${1:-help}" in
    "obtain")
        check_prerequisites
        obtain_certificate
        ;;
    "renew")
        check_prerequisites
        renew_certificate
        ;;
    "install")
        install_certificates
        ;;
    "check")
        check_certificate
        ;;
    "restart")
        restart_container
        ;;
    "help"|*)
        show_help
        ;;
esac
