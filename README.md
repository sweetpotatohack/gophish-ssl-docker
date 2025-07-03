# GoPhish SSL Docker 🎣🔒

Профессиональный Docker setup для GoPhish с автоматическим SSL сертификатом от Let's Encrypt и продвинутыми stealth модификациями.

## ⚡ Быстрый старт

```bash
# 1. Клонируем репозиторий
git clone https://github.com/sweetpotatohack/gophish-ssl-docker.git
cd gophish-ssl-docker

# 2. Устанавливаем зависимости
./ssl-manager.sh setup

# 3. Получаем SSL сертификат
./ssl-manager.sh obtain your-domain.com your-email@example.com

# 4. Запускаем полный деплой
./ssl-manager.sh deploy
```

## 🔧 Основные команды

### Управление SSL сертификатами
```bash
# Получить новый сертификат
./ssl-manager.sh obtain domain.com email@example.com

# Обновить существующий сертификат
./ssl-manager.sh renew

# Проверить статус сертификата
./ssl-manager.sh check domain.com
```

### Управление контейнером
```bash
# Собрать Docker образ
./ssl-manager.sh build

# Полный деплой (сборка + запуск)
./ssl-manager.sh deploy

# Показать статус сервисов
./ssl-manager.sh status

# Показать логи
./ssl-manager.sh logs

# Перезапустить контейнер
./ssl-manager.sh restart
```

## 🌟 Особенности

### 🔒 SSL/TLS безопасность
- ✅ Автоматические Let's Encrypt сертификаты
- ✅ HTTPS на порту 443 для фишинг-сервера
- ✅ HTTPS на порту 3333 для админ-панели
- ✅ Автоматическое обновление сертификатов

### 🥷 Stealth модификации
- ✅ Удаление заголовков `X-Gophish-*`
- ✅ Изменение User-Agent с `gophish` на `nginx`
- ✅ Замена параметра `rid` на `id`
- ✅ Кастомная 404 страница
- ✅ Robots.txt для блокировки ботов

### 🐳 Docker преимущества
- ✅ Изоляция от хост-системы
- ✅ Простое развёртывание
- ✅ Автоматический рестарт
- ✅ Health checks
- ✅ Персистентные данные

## 📂 Структура проекта

```
gophish-ssl-docker/
├── Dockerfile              # Multi-stage сборка GoPhish
├── docker-compose.yml      # Оркестрация контейнеров
├── ssl-manager.sh          # Основной скрипт управления
├── docker/
│   └── run.sh              # Скрипт запуска в контейнере
├── files/
│   ├── phish.go            # Кастомный контроллер
│   └── 404.html            # Кастомная 404 страница
├── ssl/                    # SSL сертификаты (создается автоматически)
└── data/                   # База данных и данные (создается автоматически)
```

## 🌐 Доступ к сервисам

После успешного запуска доступны:

- **Админ-панель**: https://localhost:3333
- **Фишинг-сервер**: https://localhost:443  
- **Логин**: `admin` / `gophish`

## 🔧 Требования

- Ubuntu/Debian Linux
- Root доступ
- Домен с настроенной DNS записью
- Открытые порты: 80, 443, 3333

## 📋 Детальное руководство

### 1. Подготовка сервера

```bash
# Обновление системы
apt update && apt upgrade -y

# Установка базовых утилит
apt install -y curl git wget
```

### 2. Настройка DNS

Убедитесь, что ваш домен указывает на IP сервера:
```bash
# Проверка DNS записи
dig +short your-domain.com
nslookup your-domain.com
```

### 3. Получение SSL сертификата

```bash
# Остановить веб-серверы если запущены
systemctl stop nginx apache2 2>/dev/null || true

# Получить сертификат
./ssl-manager.sh obtain your-domain.com your-email@example.com
```

### 4. Запуск GoPhish

```bash
# Полный деплой
./ssl-manager.sh deploy

# Проверка статуса
./ssl-manager.sh status
```

## 🔄 Автоматическое обновление сертификатов

Добавьте в crontab для автоматического обновления:

```bash
# Открыть crontab
crontab -e

# Добавить строку (обновление каждые 2 месяца)
0 3 1 */2 * /root/gophish-ssl-docker/ssl-manager.sh renew
```

## 🐛 Устранение неполадок

### Проверка логов
```bash
# Логи контейнера
./ssl-manager.sh logs

# Логи Docker
docker logs gophish-ssl

# Системные логи
journalctl -fu docker
```

### Проверка портов
```bash
# Проверка занятых портов
ss -tlnp | grep -E ':(80|443|3333)'

# Освобождение портов если заняты
systemctl stop nginx apache2
```

### Пересборка контейнера
```bash
# Полная пересборка
docker-compose down
docker rmi gophish-ssl-docker_gophish
./ssl-manager.sh build
./ssl-manager.sh deploy
```

## ⚠️ Безопасность

- Используйте только в легальных целях
- Не забывайте менять пароли по умолчанию
- Регулярно обновляйте систему и Docker образы
- Настройте файрвол для ограничения доступа
- Используйте VPN для доступа к админ-панели

## 📜 Лицензия

Этот проект предназначен только для образовательных целей и легального пентестинга. Автор не несёт ответственности за неправомерное использование.

## 🤝 Поддержка

Если возникли проблемы:
1. Проверьте логи: `./ssl-manager.sh logs`
2. Проверьте статус: `./ssl-manager.sh status`
3. Создайте issue в GitHub репозитории

---

**Happy Phishing! 🎣** (Но только в законных целях! 😉)
