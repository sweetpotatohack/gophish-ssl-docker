# GoPhish SSL Docker

Полноценная Docker-интеграция GoPhish с раздельным SSL управлением для админ панели и фиш сервера через Let's Encrypt.

## 🚀 Быстрый старт

```bash
# Клонируем репозиторий
git clone https://github.com/sweetpotatohack/gophish-ssl-docker.git
cd gophish-ssl-docker

# Устанавливаем зависимости
./ssl-manager.sh setup

# Запускаем с самоподписанными сертификатами для начала
./ssl-manager.sh deploy

# Получаем Let's Encrypt сертификат для админ панели
./ssl-manager.sh obtain-admin admin.yourdomain.com admin@yourdomain.com

# Получаем Let's Encrypt сертификат для фиш сервера  
./ssl-manager.sh obtain-phish phish.yourdomain.com admin@yourdomain.com
```

## 📋 Новая архитектура SSL

### 🔐 Admin Panel (порт 3333)
- **Домен**: `admin.yourdomain.com:3333`
- **SSL**: Let's Encrypt сертификат
- **Команда**: `./ssl-manager.sh obtain-admin admin.yourdomain.com your@email.com`

### 🎯 Phishing Server (порт 443)  
- **Домен**: `phish.yourdomain.com:443`
- **SSL**: Let's Encrypt сертификат
- **Команда**: `./ssl-manager.sh obtain-phish phish.yourdomain.com your@email.com`

### 📝 HTTP Redirect (порт 80)
- **Домен**: `phish.yourdomain.com:80` 
- **Функция**: Автоматический редирект на HTTPS

## 🛠 Команды SSL Manager v3.1

### Основные команды
```bash
./ssl-manager.sh setup                                          # Установить зависимости
./ssl-manager.sh deploy                                         # Запустить с самоподписанными сертификатами
./ssl-manager.sh status                                         # Показать статус всех сервисов
```

### SSL для админ панели
```bash
./ssl-manager.sh obtain-admin admin.example.com user@email.com  # Получить сертификат для админки
./ssl-manager.sh renew-admin admin.example.com                  # Обновить сертификат админки  
./ssl-manager.sh check-admin                                    # Проверить статус сертификата админки
```

### SSL для фиш сервера
```bash
./ssl-manager.sh obtain-phish phish.example.com user@email.com  # Получить сертификат для фишинга
./ssl-manager.sh renew-phish phish.example.com                  # Обновить сертификат фишинга
./ssl-manager.sh check-phish                                    # Проверить статус сертификата фишинга
```

### Управление
```bash
./ssl-manager.sh renew-all                                      # Обновить все сертификаты
./ssl-manager.sh restart                                        # Перезапустить контейнер
./ssl-manager.sh logs                                           # Показать логи
```

## 🔧 Примеры использования

### Сценарий 1: Локальная разработка
```bash
# Запускаем с самоподписанными сертификатами
./ssl-manager.sh deploy

# Доступ:
# Admin: https://localhost:3333 (самоподписанный SSL)
# Phish: https://localhost:443 (самоподписанный SSL)
```

### Сценарий 2: Production деплой
```bash
# 1. Настраиваем DNS записи:
# admin.example.com A 192.168.1.100
# phish.example.com A 192.168.1.100

# 2. Получаем сертификаты
./ssl-manager.sh obtain-admin admin.example.com admin@example.com
./ssl-manager.sh obtain-phish phish.example.com admin@example.com

# 3. Проверяем статус
./ssl-manager.sh status

# Доступ:
# Admin: https://admin.example.com:3333 (Let's Encrypt SSL)
# Phish: https://phish.example.com:443 (Let's Encrypt SSL)
```

### Сценарий 3: Обновление сертификатов
```bash
# Обновляем конкретный сертификат
./ssl-manager.sh renew-admin admin.example.com
./ssl-manager.sh renew-phish phish.example.com

# Или все сразу
./ssl-manager.sh renew-all
```

## 📦 Структура проекта

```
gophish-ssl-docker/
├── ssl-manager.sh           # Основной скрипт управления SSL
├── docker-compose.yml      # Docker Compose конфигурация  
├── config/
│   └── config.json         # Конфигурация GoPhish
├── ssl/                    # SSL сертификаты (не в git)
│   ├── gophish_admin.crt   # Сертификат админки
│   ├── gophish_admin.key   # Ключ админки
│   ├── letsencrypt.crt     # Сертификат фиш сервера
│   └── letsencrypt.key     # Ключ фиш сервера
├── data/                   # База данных (не в git)
└── docker/run.sh           # Startup скрипт (legacy)
```

## 🔐 Особенности SSL архитектуры

### Раздельные домены
- **Admin panel**: Отдельный поддомен для управления кампаниями
- **Phish server**: Отдельный домен для фишинговых кампаний
- **Изолированные сертификаты**: Каждый сервис имеет свой SSL сертификат

### Автоматическое обновление
- Поддержка cron для автоматического обновления сертификатов
- Graceful restart при обновлении сертификатов
- Валидация сертификатов перед применением

### Fallback механизм
- При отсутствии Let's Encrypt сертификатов автоматически создаются самоподписанные
- Возможность миграции с самоподписанных на Let's Encrypt без простоя

## 🔍 Мониторинг и отладка

```bash
# Проверка статуса всех компонентов
./ssl-manager.sh status

# Проверка сертификатов
./ssl-manager.sh check-admin
./ssl-manager.sh check-phish

# Просмотр логов
./ssl-manager.sh logs

# Отладка соединений
curl -k -I https://admin.yourdomain.com:3333
curl -k -I https://phish.yourdomain.com:443
```

## 🐛 Устранение неполадок

### Проблема: Сертификат не создаётся
```bash
# Проверьте DNS записи
nslookup admin.yourdomain.com
nslookup phish.yourdomain.com

# Проверьте доступность портов 80/443
./ssl-manager.sh status
```

### Проблема: GoPhish не запускается
```bash
# Посмотрите логи
./ssl-manager.sh logs

# Перезапустите контейнер
./ssl-manager.sh restart
```

### Проблема: Права доступа к SSL файлам
```bash
# Исправьте права
chmod 644 ssl/*.crt
chmod 600 ssl/*.key
./ssl-manager.sh restart
```

## 🔒 Безопасность

- ✅ SSL сертификаты хранятся локально и не попадают в git
- ✅ База данных изолирована в Docker volume
- ✅ Поддержка TLS для всех соединений
- ✅ Раздельные домены для админки и фишинга
- ✅ Автоматическая генерация fallback сертификатов

## 🚀 Production готовность

- ✅ Официальный образ GoPhish
- ✅ Let's Encrypt интеграция
- ✅ Автоматическое обновление сертификатов
- ✅ Health checks и мониторинг
- ✅ Graceful restarts
- ✅ Persistent data storage

## 🤝 Contribute

Проект создан для InfoSec сообщества. Feel free to contribute!

### TODO
- [ ] Добавить поддержку wildcard сертификатов
- [ ] Интеграция с CloudFlare API для DNS challenge
- [ ] Автоматические backup'ы кампаний
- [ ] Telegram бот для уведомлений

## ⚠️ Disclaimer

Используйте только для легальных целей и авторизованного тестирования безопасности.

---
**Created by: sweetpotatohack**  
**Version: 3.1**  
**Last Update: July 2025**
