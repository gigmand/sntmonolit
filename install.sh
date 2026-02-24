#!/bin/bash
# =============================================================================
# Скрипт установки АИС "СНТ-Управление"
# =============================================================================
# Этот скрипт выполняет полную установку системы на сервер под управлением
# Ubuntu 20.04/22.04 LTS без использования Docker
# =============================================================================

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Переменные
INSTALL_DIR="/opt/monolit"
DB_NAME="snt_monolit"
DB_USER="snt_user"
DB_PASSWORD="snt_password_$(date +%s | sha256sum | base64 | head -c 16)"
SECRET_KEY="$(openssl rand -hex 32)"
ADMIN_PASSWORD="admin123"

# Логирование
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверка прав root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Запустите скрипт от имени root (sudo ./install.sh)"
        exit 1
    fi
    log_success "Проверка прав root выполнена"
}

# Проверка ОС
check_os() {
    if [ ! -f /etc/os-release ]; then
        log_error "Не удалось определить ОС"
        exit 1
    fi

    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        log_warning "Скрипт тестировался на Ubuntu. Ваша ОС: $ID"
    fi

    log_success "ОС: $PRETTY_NAME"
}

# Обновление пакетов
update_packages() {
    log_info "Обновление списков пакетов..."
    apt update -qq
    apt upgrade -y -qq
    log_success "Пакеты обновлены"
}

# Установка системных зависимостей
install_system_deps() {
    log_info "Установка системных зависимостей..."

    apt install -y -qq \
        python3.11 python3.11-venv python3.11-dev python3-pip \
        nodejs npm \
        mariadb-server mariadb-client libmariadb-dev \
        nginx \
        libpango-1.0-0 libpangocairo-1.0-0 libgdk-pixbuf2.0-0 \
        libffi-dev shared-mime-info \
        openssl \
        curl wget git

    log_success "Системные зависимости установлены"
}

# Настройка MariaDB
setup_database() {
    log_info "Настройка базы данных..."

    # Запуск MariaDB
    systemctl start mariadb
    systemctl enable mariadb

    # Создание БД и пользователя
    mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

    log_success "База данных создана"
}

# Настройка Backend
setup_backend() {
    log_info "Настройка Backend..."

    cd ${INSTALL_DIR}/backend

    # Создание виртуального окружения
    python3.11 -m venv venv
    source venv/bin/activate

    # Установка зависимостей
    pip install --upgrade pip
    pip install -r requirements.txt

    # Создание .env файла
    cat > .env <<EOF
# Application
APP_NAME="АИС СНТ-Управление"
APP_VERSION="1.0.0"
DEBUG=False

# Database
DB_HOST=localhost
DB_PORT=3306
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}

# JWT Settings
SECRET_KEY=${SECRET_KEY}
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440

# File storage
UPLOAD_DIR=${INSTALL_DIR}/uploads
RECEIPTS_DIR=${INSTALL_DIR}/uploads/receipts

# Pagination
DEFAULT_PAGE_SIZE=20
MAX_PAGE_SIZE=100
EOF

    # Создание директорий
    mkdir -p ${INSTALL_DIR}/uploads/receipts
    chown -R www-data:www-data ${INSTALL_DIR}/uploads

    # Инициализация БД
    python init_db.py

    deactivate
    log_success "Backend настроен"
}

# Настройка Frontend
setup_frontend() {
    log_info "Настройка Frontend..."

    cd ${INSTALL_DIR}/frontend

    # Установка зависимостей
    npm install --legacy-peer-deps

    # Сборка production версии
    npm run build

    # Копирование в nginx
    cp -r dist/* /var/www/html/

    log_success "Frontend настроен"
}

# Настройка Nginx
setup_nginx() {
    log_info "Настройка Nginx..."

    # Создание конфигурации
    cat > /etc/nginx/sites-available/snt-monolit <<EOF
server {
    listen 80;
    server_name _;
    root /var/www/html;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location /api {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    location /docs {
        proxy_pass http://127.0.0.1:8000/docs;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location /openapi.json {
        proxy_pass http://127.0.0.1:8000/openapi.json;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
    }
}
EOF

    # Активация конфигурации
    ln -sf /etc/nginx/sites-available/snt-monolit /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default

    # Проверка и перезапуск
    nginx -t
    systemctl restart nginx
    systemctl enable nginx

    log_success "Nginx настроен"
}

# Настройка systemd для backend
setup_systemd() {
    log_info "Настройка systemd сервиса..."

    cat > /etc/systemd/system/snt-backend.service <<EOF
[Unit]
Description=SNT Monolit Backend
After=network.target mariadb.service

[Service]
User=www-data
Group=www-data
WorkingDirectory=${INSTALL_DIR}/backend
Environment="PATH=${INSTALL_DIR}/backend/venv/bin"
ExecStart=${INSTALL_DIR}/backend/venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000 --workers 2
Restart=always
RestartSec=5

# Security
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable snt-backend
    systemctl start snt-backend

    log_success "Systemd сервис настроен"
}

# Настройка firewall
setup_firewall() {
    log_info "Настройка firewall..."

    if command -v ufw &> /dev/null; then
        ufw allow 22/tcp
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw --force enable
        log_success "Firewall настроен"
    else
        log_warning "UFW не установлен, пропускаем настройку firewall"
    fi
}

# Вывод информации
show_info() {
    echo ""
    echo "============================================================================="
    echo -e "${GREEN}Установка завершена успешно!${NC}"
    echo "============================================================================="
    echo ""
    echo "Доступ к системе:"
    echo "  URL: http://$(hostname -I | awk '{print $1}')"
    echo ""
    echo "Учетные данные администратора:"
    echo "  Логин: admin"
    echo "  Пароль: ${ADMIN_PASSWORD}"
    echo ""
    echo "Важные файлы:"
    echo "  Backend .env: ${INSTALL_DIR}/backend/.env"
    echo "  Database: ${DB_NAME}"
    echo "  DB User: ${DB_USER}"
    echo "  DB Password: ${DB_PASSWORD}"
    echo ""
    echo "Полезные команды:"
    echo "  Статус backend:  systemctl status snt-backend"
    echo "  Статус nginx:    systemctl status nginx"
    echo "  Статус mariadb:  systemctl status mariadb"
    echo "  Логи backend:    journalctl -u snt-backend -f"
    echo "  Логи nginx:      tail -f /var/log/nginx/error.log"
    echo ""
    echo "============================================================================="
}

# Главное выполнение
main() {
    echo ""
    echo "============================================================================="
    echo "  АИС \"СНТ-Управление\" - Установка"
    echo "============================================================================="
    echo ""

    check_root
    check_os
    update_packages
    install_system_deps
    setup_database
    setup_backend
    setup_frontend
    setup_nginx
    setup_systemd
    setup_firewall
    show_info
}

# Запуск
main "$@"
