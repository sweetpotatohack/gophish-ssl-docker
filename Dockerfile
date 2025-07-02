FROM ubuntu:22.04

# Установка зависимостей
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Создание пользователя app
RUN useradd -m -u 1000 app

# Скачивание и установка GoPhish
WORKDIR /opt
RUN wget https://github.com/gophish/gophish/releases/download/v0.12.1/gophish-v0.12.1-linux-64bit.zip \
    && unzip gophish-v0.12.1-linux-64bit.zip \
    && mv gophish-v0.12.1-linux-64bit gophish \
    && rm gophish-v0.12.1-linux-64bit.zip \
    && chown -R app:app /opt/gophish

# Копирование конфигурации
COPY config.json /opt/gophish/config.json
RUN chown app:app /opt/gophish/config.json

# Создание директории для SSL сертификатов
RUN mkdir -p /opt/gophish/ssl && chown app:app /opt/gophish/ssl

WORKDIR /opt/gophish
USER app

EXPOSE 443 3333

CMD ["./gophish"]
