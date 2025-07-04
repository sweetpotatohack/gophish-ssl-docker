# GoPhish SSL Docker

Полноценная Docker-интеграция GoPhish с автоматическим SSL управлением через Let's Encrypt.

## 🚀 Быстрый старт

```bash
# Клонируем репозиторий
git clone https://github.com/sweetpotatohack/gophish-ssl-docker.git
cd gophish-ssl-docker

# Получаем SSL сертификат и запускаем
./ssl-manager.sh obtain your-domain.com your-email@example.com
```

## 📋 Возможности

- ✅ **Полная SSL поддержка** с Let's Encrypt сертификатами
- ✅ **Автоматическое обновление** сертификатов  
- ✅ **Docker-based архитектура** для простого развёртывания
- ✅ **Stealth модификации** GoPhish (убираем X-Gophish заголовки)
- ✅ **Готовые конфигурации** для production использования
- ✅ **Автоматическая инициализация** базы данных

## 🛠 Команды SSL Manager

```bash
./ssl-manager.sh setup                              # Установить зависимости
./ssl-manager.sh obtain domain.com user@email.com   # Получить SSL сертификат
./ssl-manager.sh renew domain.com                   # Обновить сертификат
./ssl-manager.sh deploy                             # Запустить всё
./ssl-manager.sh status                             # Проверить статус
./ssl-manager.sh logs                               # Показать логи
./ssl-manager.sh restart                            # Перезапустить
```

## 🔧 Архитектура

- **Admin Panel**: `https://localhost:3333` (самоподписанный SSL)
- **Phishing Server**: `https://localhost:443` (Let's Encrypt SSL)
- **HTTP Redirect**: `http://localhost:80` → HTTPS

## 📦 Структура проекта

```
gophish-ssl-docker/
├── ssl-manager.sh           # Основной скрипт управления
├── docker-compose.yml      # Docker Compose конфигурация
├── Dockerfile              # Кастомный образ (legacy, не используется)
├── config/                 # Конфигурационные файлы
├── ssl/                    # SSL сертификаты (не в git)
├── data/                   # База данных (не в git)
└── docker/run.sh           # Startup скрипт
```

## 🔐 Безопасность

- SSL сертификаты хранятся локально и не попадают в git
- База данных изолирована в Docker volume
- Поддержка TLS для всех соединений
- Автоматическая генерация admin сертификатов

## 🤝 Contribut

Проект создан для InfoSec сообщества. Feel free to contribute!

## ⚠️ Disclaimer

Используйте только для легальных целей и авторизованного тестирования безопасности.

---
**Created by: sweetpotatohack**  
**Version: 3.0**
