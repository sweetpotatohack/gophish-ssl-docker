# Minify client side assets (JavaScript)
FROM node:latest AS build-js

RUN npm install gulp gulp-cli -g

RUN apt update && apt install git
WORKDIR /build
RUN git clone https://github.com/gophish/gophish .
RUN npm install --only=dev
RUN gulp


# Build Golang binary
FROM golang:1.19 AS build-golang

WORKDIR /go/src/github.com/gophish/gophish
COPY --from=build-js /build/ ./

# Stripping X-Gophish headers for stealth
RUN sed -i 's/X-Gophish-Contact/X-Contact/g' models/email_request_test.go
RUN sed -i 's/X-Gophish-Contact/X-Contact/g' models/maillog.go
RUN sed -i 's/X-Gophish-Contact/X-Contact/g' models/maillog_test.go
RUN sed -i 's/X-Gophish-Contact/X-Contact/g' models/email_request.go

# Stripping X-Gophish-Signature
RUN sed -i 's/X-Gophish-Signature/X-Signature/g' webhook/webhook.go

# Changing servername for stealth
RUN sed -i 's/const ServerName = "gophish"/const ServerName = "nginx"/' config/config.go

# Changing rid parameter for stealth
RUN sed -i 's/const RecipientParameter = "rid"/const RecipientParameter = "id"/g' models/campaign.go

RUN go get -v && go build -v


# Runtime container
FROM debian:stable

RUN useradd -m -d /opt/gophish -s /bin/bash app

RUN apt-get update && \
	apt-get install --no-install-recommends -y jq libcap2-bin curl ca-certificates openssl && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /opt/gophish
COPY --from=build-golang /go/src/github.com/gophish/gophish/ ./
COPY --from=build-js /build/static/js/dist/ ./static/js/dist/
COPY --from=build-js /build/static/css/dist/ ./static/css/dist/

# Copy custom files
COPY ./docker/run.sh ./docker/run.sh

# Create directories for SSL and data
RUN mkdir -p ssl data config
RUN chown -R app:app /opt/gophish

# Set capabilities to bind to port 443 without root
RUN setcap 'cap_net_bind_service=+ep' /opt/gophish/gophish

USER app

# Create simple config without SSL first
RUN echo '{ \
  "admin_server": { \
    "listen_url": "0.0.0.0:3333", \
    "use_tls": false \
  }, \
  "phish_server": { \
    "listen_url": "0.0.0.0:8080", \
    "use_tls": false \
  }, \
  "db_name": "sqlite3", \
  "db_path": "./data/gophish.db", \
  "migrations_prefix": "db/db_sqlite3/migrations/", \
  "contact_address": "", \
  "logging": { \
    "filename": "", \
    "level": "" \
  } \
}' > config.json

EXPOSE 3333 8080

CMD ["./docker/run.sh"]
