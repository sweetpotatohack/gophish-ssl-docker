#!/bin/bash

# GoPhish SSL Certificate Manager v3.1
# Скрипт для управления SSL сертификатами Let's Encrypt с Docker

set -e

# Правильный парсинг параметров
COMMAND=${1:-"help"}
DOMAIN=${2:-"your_domain"}
EMAIL=${3:-"your_mail"}
SSL_DIR="./ssl"
DATA_DIR="./data"
CONFIG_DIR="./config"
CONTAINER_NAME="gophish-ssl"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

show_help() {
    echo "GoPhish SSL Certificate Manager v3.1"
    echo ""
    echo "Использование: $0 [COMMAND] [DOMAIN] [EMAIL]"
    echo ""
    echo "Команды:"
    echo "  setup         - Установить все зависимости (Docker, Certbot)"
    echo "  obtain-admin  - Получить SSL сертификат для админ панели (порт 3333)"
    echo "  obtain-phish  - Получить SSL сертификат для фиш сервера (порт 443)"
    echo "  renew-admin   - Обновить сертификат админ панели"
    echo "  renew-phish   - Обновить сертификат фиш сервера"
    echo "  renew-all     - Обновить все сертификаты"
    echo "  check-admin   - Проверить статус сертификата админки"
    echo "  check-phish   - Проверить статус сертификата фиш сервера"
    echo "  restart       - Перезапустить GoPhish контейнер"
    echo "  deploy        - Полный деплой (pull + up)"
    echo "  logs          - Показать логи контейнера"
    echo "  status        - Показать статус сервисов"
    echo "  help          - Показать эту справку"
    echo ""
    echo "Примеры:"
    echo "  $0 setup                                                    # Установить зависимости"
    echo "  $0 obtain-admin admin.example.com admin@example.com        # SSL для админки"
    echo "  $0 obtain-phish phish.example.com admin@example.com        # SSL для фишинга"
    echo "  $0 deploy                                                   # Запустить всё"
    echo "  $0 status                                                   # Проверить статус"
    echo ""
    echo "Архитектура:"
    echo "  🔐 Admin Panel: https://admin.example.com:3333 (Let's Encrypt SSL)"
    echo "  🎯 Phish Server: https://phish.example.com:443 (Let's Encrypt SSL)"
    echo "  📝 HTTP Redirect: http://phish.example.com:80 → HTTPS"
}

setup_dependencies() {
    log_info "Установка необходимых зависимостей..."
    
    # Обновляем пакеты
    apt update
    
    # Устанавливаем Docker
    if ! command -v docker &> /dev/null; then
        log_info "Устанавливаем Docker..."
        apt install -y docker.io
        systemctl start docker
        systemctl enable docker
        log_info "Docker установлен и запущен!"
    else
        log_info "Docker уже установлен"
    fi
    
    # Устанавливаем Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_info "Устанавливаем Docker Compose..."
        apt install -y docker-compose
        log_info "Docker Compose установлен!"
    else
        log_info "Docker Compose уже установлен"
    fi
    
    # Устанавливаем Certbot
    if ! command -v certbot &> /dev/null; then
        log_info "Устанавливаем Certbot..."
        apt install -y certbot
        log_info "Certbot установлен!"
    else
        log_info "Certbot уже установлен"
    fi
    
    # Устанавливаем дополнительные утилиты
    apt install -y curl git openssl
    
    log_info "Все зависимости установлены!"
}

check_prerequisites() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker не установлен! Запустите: $0 setup"
        exit 1
    fi

    if ! command -v certbot &> /dev/null; then
        log_error "Certbot не установлен! Запустите: $0 setup"
        exit 1
    fi
}

validate_params() {
    if [ "$DOMAIN" = "your_domain" ] || [ "$EMAIL" = "your_mail" ]; then
        log_error "Не указан домен или email!"
        log_error "Использование: $0 $COMMAND DOMAIN EMAIL"
        log_error "Пример: $0 $COMMAND admin.example.com admin@example.com"
        exit 1
    fi
    
    # Проверяем валидность email
    if ! [[ "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        log_error "Неверный формат email: $EMAIL"
        exit 1
    fi
}

stop_container() {
    if docker ps -q -f name=${CONTAINER_NAME} | grep -q .; then
        log_info "Останавливаем контейнер GoPhish..."
        docker-compose down || true
    fi
}

start_container() {
    log_info "Запускаем контейнер GoPhish..."
    docker-compose up -d
}

obtain_admin_certificate() {
    log_info "Получение SSL сертификата для АДМИН ПАНЕЛИ"
    log_info "Домен: $DOMAIN (будет доступен на порту 3333)"
    log_info "Email для уведомлений: $EMAIL"
    
    validate_params
    
    # Останавливаем контейнер если запущен
    stop_container
    
    # Получаем сертификат
    certbot certonly --standalone \
        -d "$DOMAIN" \
        --non-interactive \
        --agree-tos \
        --email "$EMAIL" \
        --force-renewal
    
    # Устанавливаем сертификаты для админки
    install_admin_certificates
    
    # Обновляем конфигурацию
    update_config
    
    # Запускаем контейнер
    start_container
    
    log_info "SSL сертификат для админ панели успешно получен и установлен!"
    log_info "Admin Panel: https://$DOMAIN:3333"
}

obtain_phish_certificate() {
    log_info "Получение SSL сертификата для ФИШ СЕРВЕРА"
    log_info "Домен: $DOMAIN (будет доступен на порту 443)"
    log_info "Email для уведомлений: $EMAIL"
    
    validate_params
    
    # Останавливаем контейнер если запущен
    stop_container
    
    # Получаем сертификат
    certbot certonly --standalone \
        -d "$DOMAIN" \
        --non-interactive \
        --agree-tos \
        --email "$EMAIL" \
        --force-renewal
    
    # Устанавливаем сертификаты для фиш сервера
    install_phish_certificates
    
    # Обновляем конфигурацию
    update_config
    
    # Запускаем контейнер
    start_container
    
    log_info "SSL сертификат для фиш сервера успешно получен и установлен!"
    log_info "Phish Server: https://$DOMAIN:443"
}

install_admin_certificates() {
    log_info "Установка SSL сертификатов для админ панели..."
    
    mkdir -p "$SSL_DIR"
    
    if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
        cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$SSL_DIR/gophish_admin.crt"
        cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$SSL_DIR/gophish_admin.key"
        
        # Устанавливаем правильные права доступа
        chmod 644 "$SSL_DIR/gophish_admin.crt"
        chmod 600 "$SSL_DIR/gophish_admin.key"
        
        log_info "SSL сертификаты админ панели установлены в $SSL_DIR/"
    else
        log_error "SSL сертификат не найден для домена $DOMAIN"
        exit 1
    fi
}

install_phish_certificates() {
    log_info "Установка SSL сертификатов для фиш сервера..."
    
    mkdir -p "$SSL_DIR"
    
    if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
        cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$SSL_DIR/letsencrypt.crt"
        cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$SSL_DIR/letsencrypt.key"
        
        # Устанавливаем правильные права доступа
        chmod 644 "$SSL_DIR/letsencrypt.crt"
        chmod 600 "$SSL_DIR/letsencrypt.key"
        
        log_info "SSL сертификаты фиш сервера установлены в $SSL_DIR/"
    else
        log_error "SSL сертификат не найден для домена $DOMAIN"
        exit 1
    fi
}

create_self_signed_certificates() {
    log_info "Создание самоподписанных сертификатов для разработки..."
    
    mkdir -p "$SSL_DIR"
    
    # Создаем самоподписанный сертификат для админки если нет Let's Encrypt
    if [ ! -f "$SSL_DIR/gophish_admin.crt" ]; then
        log_info "Создание самоподписанного сертификата для админки..."
        openssl req -newkey rsa:2048 -nodes -keyout "$SSL_DIR/gophish_admin.key" \
            -x509 -days 365 -out "$SSL_DIR/gophish_admin.crt" \
            -subj "/C=US/ST=State/L=City/O=GoPhish/CN=gophish-admin"
        chmod 600 "$SSL_DIR/gophish_admin.key"
        chmod 644 "$SSL_DIR/gophish_admin.crt"
    fi
    
    # Создаем самоподписанный сертификат для фиш сервера если нет Let's Encrypt
    if [ ! -f "$SSL_DIR/letsencrypt.crt" ]; then
        log_info "Создание самоподписанного сертификата для фиш сервера..."
        openssl req -newkey rsa:2048 -nodes -keyout "$SSL_DIR/letsencrypt.key" \
            -x509 -days 365 -out "$SSL_DIR/letsencrypt.crt" \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
        chmod 600 "$SSL_DIR/letsencrypt.key"
        chmod 644 "$SSL_DIR/letsencrypt.crt"
    fi
}

update_config() {
    log_info "Обновление конфигурации GoPhish..."
    
    mkdir -p "$CONFIG_DIR"
    
    cat > "$CONFIG_DIR/config.json" << CONFIG_EOF
{
  "admin_server": {
    "listen_url": "0.0.0.0:3333",
    "use_tls": true,
    "cert_path": "ssl/gophish_admin.crt",
    "key_path": "ssl/gophish_admin.key"
  },
  "phish_server": {
    "listen_url": "0.0.0.0:443",
    "use_tls": true,
    "cert_path": "ssl/letsencrypt.crt",
    "key_path": "ssl/letsencrypt.key"
  },
  "db_name": "sqlite3",
  "db_path": "gophish.db",
  "migrations_prefix": "db/db_",
  "contact_address": "",
  "logging": {
    "filename": "",
    "level": ""
  }
}
CONFIG_EOF

    log_info "Конфигурация обновлена!"
}

renew_admin_certificate() {
    log_info "Обновление SSL сертификата для админ панели..."
    
    if [ "$DOMAIN" = "your_domain" ]; then
        log_error "Нужно указать домен для обновления!"
        log_error "Использование: $0 renew-admin DOMAIN"
        exit 1
    fi
    
    stop_container
    
    certbot renew --force-renewal --cert-name "$DOMAIN"
    
    install_admin_certificates
    update_config
    start_container
    
    log_info "SSL сертификат админ панели успешно обновлен!"
}

renew_phish_certificate() {
    log_info "Обновление SSL сертификата для фиш сервера..."
    
    if [ "$DOMAIN" = "your_domain" ]; then
        log_error "Нужно указать домен для обновления!"
        log_error "Использование: $0 renew-phish DOMAIN"
        exit 1
    fi
    
    stop_container
    
    certbot renew --force-renewal --cert-name "$DOMAIN"
    
    install_phish_certificates
    update_config
    start_container
    
    log_info "SSL сертификат фиш сервера успешно обновлен!"
}

renew_all_certificates() {
    log_info "Обновление всех SSL сертификатов..."
    
    stop_container
    
    certbot renew --force-renewal
    
    # Попробуем найти и установить все доступные сертификаты
    if ls /etc/letsencrypt/live/*/fullchain.pem 1> /dev/null 2>&1; then
        for cert_dir in /etc/letsencrypt/live/*/; do
            domain_name=$(basename "$cert_dir")
            if [ "$domain_name" != "*" ]; then
                log_info "Найден сертификат для домена: $domain_name"
                DOMAIN="$domain_name"
                
                # Устанавливаем как admin (можно изменить логику)
                install_admin_certificates
            fi
        done
    fi
    
    update_config
    start_container
    
    log_info "Все SSL сертификаты обновлены!"
}

check_certificate() {
    local cert_type=$1
    local cert_file=""
    
    case $cert_type in
        "admin")
            cert_file="$SSL_DIR/gophish_admin.crt"
            log_info "Проверка SSL сертификата АДМИН ПАНЕЛИ"
            ;;
        "phish")
            cert_file="$SSL_DIR/letsencrypt.crt"
            log_info "Проверка SSL сертификата ФИش СЕРВЕРА"
            ;;
        *)
            log_error "Неизвестный тип сертификата: $cert_type"
            exit 1
            ;;
    esac
    
    if [ -f "$cert_file" ]; then
        echo "=== Информация о сертификате ==="
        openssl x509 -in "$cert_file" -noout -subject -issuer -dates
        echo ""
        
        # Проверка срока действия
        expiry_date=$(openssl x509 -in "$cert_file" -noout -enddate | cut -d= -f2)
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
        log_error "Сертификат не найден: $cert_file"
        exit 1
    fi
}

restart_container() {
    log_info "Перезапуск GoPhish контейнера..."
    docker-compose restart
    log_info "Контейнер перезапущен!"
}

show_logs() {
    log_info "Показ логов GoPhish..."
    docker-compose logs -f --tail=50
}

show_status() {
    log_info "Статус сервисов GoPhish:"
    echo ""
    
    # Docker Compose статус
    docker-compose ps
    echo ""
    
    # Проверка портов
    log_info "Проверка портов:"
    if ss -tlnp | grep -q ":3333"; then
        echo "✅ Порт 3333 (Admin HTTPS) - активен"
    else
        echo "❌ Порт 3333 (Admin HTTPS) - не активен"
    fi
    
    if ss -tlnp | grep -q ":443"; then
        echo "✅ Порт 443 (Phishing HTTPS) - активен"
    else
        echo "❌ Порт 443 (Phishing HTTPS) - не активен"
    fi
    
    if ss -tlnp | grep -q ":80"; then
        echo "✅ Порт 80 (HTTP Redirect) - активен"
    else
        echo "❌ Порт 80 (HTTP Redirect) - не активен"
    fi
    
    echo ""
    log_info "SSL Certificates:"
    if [ -f "$SSL_DIR/gophish_admin.crt" ]; then
        echo "✅ Admin SSL Certificate - установлен"
    else
        echo "❌ Admin SSL Certificate - отсутствует"
    fi
    
    if [ -f "$SSL_DIR/letsencrypt.crt" ]; then
        echo "✅ Phish SSL Certificate - установлен"
    else
        echo "❌ Phish SSL Certificate - отсутствует"
    fi
    
    echo ""
    log_info "URLs:"
    echo "🔐 Admin panel: https://your-admin-domain.com:3333"
    echo "🎯 Phishing server: https://your-phish-domain.com:443"
    echo "📝 Default login: admin / gophish"
}

deploy_all() {
    log_info "Полный деплой GoPhish SSL..."
    
    # Проверяем зависимости
    check_prerequisites
    
    # Создаём директории
    mkdir -p "$SSL_DIR" "$DATA_DIR" "$CONFIG_DIR"
    
    # Создаем самоподписанные сертификаты для начала
    create_self_signed_certificates
    
    # Обновляем конфигурацию
    update_config
    
    # Запускаем
    start_container
    
    # Показываем статус
    sleep 5
    show_status
    
    log_info "Деплой завершён!"
    log_warn "Для получения Let's Encrypt сертификатов используйте:"
    log_warn "  $0 obtain-admin your-admin-domain.com your-email@example.com"
    log_warn "  $0 obtain-phish your-phish-domain.com your-email@example.com"
}

# Главная логика
case "$COMMAND" in
    "setup")
        setup_dependencies
        ;;
    "obtain-admin")
        check_prerequisites
        obtain_admin_certificate
        ;;
    "obtain-phish")
        check_prerequisites
        obtain_phish_certificate
        ;;
    "renew-admin")
        check_prerequisites
        renew_admin_certificate
        ;;
    "renew-phish")
        check_prerequisites
        renew_phish_certificate
        ;;
    "renew-all")
        check_prerequisites
        renew_all_certificates
        ;;
    "check-admin")
        check_certificate "admin"
        ;;
    "check-phish")
        check_certificate "phish"
        ;;
    "restart")
        restart_container
        ;;
    "deploy")
        deploy_all
        ;;
    "logs")
        show_logs
        ;;
    "status")
        show_status
        ;;
    "help"|*)
        show_help
        ;;
esac
