# АИС "СНТ-Управление" — Развертывание

## Быстрый старт

### 1. Скопируйте папку `install` на целевой сервер

```bash
# Например, через scp
scp -r /opt/monolit/install root@new-server:/opt/monolit
```

### 2. Выполните установку

```bash
# Перейти в директорию
cd /opt/monolit/install

# Сделать скрипт исполняемым и запустить
chmod +x install.sh
sudo ./install.sh
```

### 3. Проверьте доступ

Откройте в браузере: `http://ip-адрес-сервера`

**Учетные данные:**
- Логин: `admin`
- Пароль: `admin123`

---

## Состав папки install

```
install/
├── backend/                    # Backend (Python/FastAPI)
│   ├── app/
│   │   ├── api/               # API endpoints
│   │   ├── core/              # Конфигурация, безопасность
│   │   ├── db/                # Подключение к БД
│   │   ├── models/            # SQLAlchemy модели
│   │   ├── schemas/           # Pydantic схемы
│   │   ├── services/          # Бизнес-логика
│   │   ├── utils/             # Утилиты (генерация PDF)
│   │   └── main.py            # Точка входа
│   ├── requirements.txt       # Python зависимости
│   ├── init_db.py            # Скрипт инициализации БД
│   └── .env.example          # Шаблон конфигурации
│
├── frontend/                   # Frontend (React/TypeScript)
│   ├── src/
│   │   ├── components/        # React компоненты
│   │   ├── pages/             # Страницы
│   │   ├── services/          # API клиенты
│   │   ├── store/             # State management
│   │   └── types/             # TypeScript типы
│   ├── package.json          # Node.js зависимости
│   ├── vite.config.ts        # Конфигурация Vite
│   └── nginx.conf            # Конфигурация nginx для frontend
│
├── docs/                       # Документация
│   ├── INSTALL_NATIVE.md     # Инструкция по установке
│   └── generate_user_manual.py
│
├── uploads/                    # Директория для загрузок
│   └── receipts/             # PDF квитанции
│
├── install.sh                  # Скрипт автоматической установки
├── backup.sh                   # Скрипт резервного копирования
├── nginx.conf                  # Конфигурация nginx (reverse proxy)
├── snt-backend.service        # Systemd сервис для backend
└── README.md                   # Основная документация
```

---

## Ручная установка (по шагам)

См. подробную инструкцию в `docs/INSTALL_NATIVE.md`

Кратко:

```bash
# 1. Установка зависимостей
sudo apt install -y python3.11 python3.11-venv nodejs npm mariadb-server nginx

# 2. Настройка БД
sudo mysql -u root -e "CREATE DATABASE snt_monolit; CREATE USER 'snt_user'@'localhost' IDENTIFIED BY 'password'; GRANT ALL ON snt_monolit.* TO 'snt_user'@'localhost';"

# 3. Backend
cd backend
python3.11 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env  # отредактируйте .env
python init_db.py

# 4. Frontend
cd ../frontend
npm install
npm run build
sudo cp -r dist/* /var/www/html/

# 5. Nginx и systemd
# Скопируйте конфиги из этой папки в /etc/nginx/ и /etc/systemd/system/
```

---

## Резервное копирование

```bash
# Ежедневный бэкап в 2:00
sudo crontab -e
# Добавьте строку:
0 2 * * * /opt/monolit/install/backup.sh
```

---

## Команды управления

```bash
# Статус сервисов
sudo systemctl status snt-backend
sudo systemctl status nginx
sudo systemctl status mariadb

# Логи
sudo journalctl -u snt-backend -f
sudo tail -f /var/log/nginx/error.log

# Перезапуск
sudo systemctl restart snt-backend nginx mariadb
```

---

## Требования

- Ubuntu 20.04/22.04 LTS
- 4 GB RAM (минимум)
- 50 GB SSD
- Доступ к портам: 80 (HTTP), 443 (HTTPS), 3306 (MariaDB, локально)

---

## Поддержка

СНТ "Монолит"
- Адрес: 644043 Россия г. Омск ул. Партизанская 12
- Председатель: Пегасин Александр Александрович
- Телефон: 8 950 339 6939
- Email: snt-monolit@yandex.ru
