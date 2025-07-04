#!/bin/bash

# GoPhish SSL Certificate Manager v3.0
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
    echo "GoPhish SSL Certificate Manager v3.0"
    echo ""
    echo "Использование: $0 [COMMAND] [DOMAIN] [EMAIL]"
    echo ""
    echo "Команды:"
    echo "  setup     - Установить все зависимости (Docker, Certbot)"
    echo "  obtain    - Получить новый SSL сертификат"
    echo "  renew     - Обновить существующий сертификат"
    echo "  install   - Установить сертификаты в GoPhish"
    echo "  check     - Проверить статус сертификата"
    echo "  restart   - Перезапустить GoPhish контейнер"
    echo "  build     - Собрать Docker образ"
    echo "  deploy    - Полный деплой (pull + up)"
    echo "  logs      - Показать логи контейнера"
    echo "  status    - Показать статус сервисов"
    echo "  help      - Показать эту справку"
    echo ""
    echo "Примеры:"
    echo "  $0 setup                                              # Установить зависимости"
    echo "  $0 obtain yura.infosec.cfd user@example.com          # Получить SSL"
    echo "  $0 deploy                                             # Запустить всё"
    echo "  $0 status                                             # Проверить статус"
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
        log_error "Использование: $0 obtain DOMAIN EMAIL"
        log_error "Пример: $0 obtain yura.infosec.cfd theskill19@yandex.ru"
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

obtain_certificate() {
    log_info "Получение нового SSL сертификата для домена: $DOMAIN"
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
    
    # Устанавливаем сертификаты
    install_certificates
    
    # Запускаем контейнер
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
            -subj "/C=US/ST=State/L=City/O=GoPhish/CN=gophish-admin"
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
    log_info "URLs:"
    echo "🔐 Admin panel: https://localhost:3333"
    echo "🎯 Phishing server: https://localhost:443"
    echo "📝 Default login: admin / gophish"
}

deploy_all() {
    log_info "Полный деплой GoPhish SSL..."
    
    # Проверяем зависимости
    check_prerequisites
    
    # Создаём директории
    mkdir -p "$SSL_DIR" "$DATA_DIR" "$CONFIG_DIR"
    
    # Запускаем
    start_container
    
    # Показываем статус
    sleep 5
    show_status
    
    log_info "Деплой завершён!"
}

# Главная логика
case "$COMMAND" in
    "setup")
        setup_dependencies
        ;;
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
