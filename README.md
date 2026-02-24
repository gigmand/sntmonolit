# АИС "СНТ-Управление" | СНТ "Монолит"

Автоматизированная информационная система для управления садоводческим некоммерческим товариществом.

## 📋 О проекте

Система предназначена для автоматизации учета членов СНТ, управления земельными участками, контроля взносов и платежей, а также формирования отчетности.

### Основные возможности

- **Управление членской базой** — учет членов СНТ, статусов, контактных данных
- **Управление участками** — реестр земельных участков, привязка к владельцам
- **История владения** — фиксация смены владельцев (продажа, наследование, дарение)
- **Учет взносов** — членские, целевые, электроэнергия
- **Платежи** — регистрация платежей, распределение по начислениям
- **Отчетность** — дашборд, отчеты по должникам, аналитика
- **Генерация квитанций** — PDF-квитанции об оплате

## 🏗️ Архитектура

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│    Frontend     │────▶│     Backend     │────▶│     MariaDB     │
│  React + AntD   │     │   FastAPI + Py  │     │     10.11+      │
│   TypeScript    │◀────│    SQLAlchemy   │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

### Технологический стек

**Backend:**
- Python 3.11+
- FastAPI
- SQLAlchemy (ORM)
- Pydantic (валидация)
- JWT (аутентификация)
- WeasyPrint (PDF)

**Frontend:**
- React 18+
- TypeScript
- Ant Design
- React Router
- Zustand (state management)
- Axios

**База данных:**
- MariaDB 10.11+

**Развертывание:**
- Docker & Docker Compose
- Nginx (reverse proxy)

## 🚀 Быстрый старт

### Требования

- Docker и Docker Compose
- Или для локальной разработки:
  - Python 3.11+
  - Node.js 18+
  - MariaDB 10.11+

### Запуск через Docker Compose

```bash
# Клонировать репозиторий
cd /opt/monolit

# Настроить переменные окружения
cp backend/.env.example backend/.env
# Отредактировать backend/.env при необходимости

# Запустить все сервисы
docker-compose up -d

# Инициализировать базу данных
docker-compose exec backend python init_db.py
```

После запуска:
- Frontend: http://localhost
- Backend API: http://localhost/api
- База данных: localhost:3306

**Учетные данные по умолчанию:**
- Логин: `admin`
- Пароль: `admin123`

### Локальная разработка

#### Backend

```bash
cd backend

# Создать виртуальное окружение
python -m venv venv
source venv/bin/activate  # Linux
# или
venv\Scripts\activate  # Windows

# Установить зависимости
pip install -r requirements.txt

# Настроить .env файл
cp .env.example .env

# Инициализировать БД
python init_db.py

# Запустить сервер разработки
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Backend доступен по адресу: http://localhost:8000
Документация API: http://localhost:8000/docs

#### Frontend

```bash
cd frontend

# Установить зависимости
npm install

# Запустить сервер разработки
npm run dev
```

Frontend доступен по адресу: http://localhost:3000

#### База данных

```bash
# Подключение к MariaDB
mysql -h localhost -P 3306 -u snt_user -p snt_monolit
```

## 📁 Структура проекта

```
/opt/monolit/
├── backend/
│   ├── app/
│   │   ├── api/          # API endpoints
│   │   ├── core/         # Конфигурация, безопасность
│   │   ├── db/           # Подключение к БД
│   │   ├── models/       # SQLAlchemy модели
│   │   ├── schemas/      # Pydantic схемы
│   │   ├── services/     # Бизнес-логика
│   │   └── main.py       # Точка входа
│   ├── tests/
│   ├── requirements.txt
│   ├── init_db.py
│   └── Dockerfile
├── frontend/
│   ├── src/
│   │   ├── components/   # React компоненты
│   │   ├── pages/        # Страницы приложения
│   │   ├── services/     # API клиенты
│   │   ├── store/        # State management
│   │   ├── types/        # TypeScript типы
│   │   └── main.tsx      # Точка входа
│   ├── public/
│   ├── package.json
│   └── Dockerfile
├── docker-compose.yml
├── docs/
└── README.md
```

## 📊 Структура базы данных

### Основные таблицы

| Таблица | Описание |
|---------|----------|
| `users` | Пользователи системы (администраторы, председатель, казначей) |
| `members` | Члены СНТ |
| `plots` | Земельные участки |
| `member_plots` | Связь членов и участков (many-to-many) |
| `ownership_history` | История владения участками |
| `fee_types` | Виды взносов (членские, целевые, электроэнергия) |
| `fee_rates` | Ставки взносов по годам |
| `fee_accruals` | Начисления взносов |
| `fee_payments` | Платежи |
| `payment_splits` | Распределение платежей по начислениям |
| `member_debts` | Текущие задолженности |
| `receipts` | Квитанции об оплате |
| `action_logs` | Журнал действий пользователей |

## 🔐 Роли и права доступа

| Роль | Описание | Права |
|------|----------|-------|
| `admin` | Администратор | Полный доступ ко всем функциям |
| `chairman` | Председатель | Просмотр всех данных, создание отчетов |
| `treasurer` | Казначей | Работа с платежами и начислениями |
| `secretary` | Секретарь | Работа с членской базой |
| `observer` | Наблюдатель | Только просмотр |

## 📡 API Endpoints

### Аутентификация
- `POST /api/auth/login` — Вход в систему
- `POST /api/auth/register` — Регистрация нового пользователя
- `GET /api/auth/me` — Информация о текущем пользователе
- `POST /api/auth/logout` — Выход из системы

### Члены СНТ
- `GET /api/members` — Список членов
- `GET /api/members/{id}` — Детальная информация
- `POST /api/members` — Создание
- `PUT /api/members/{id}` — Обновление
- `DELETE /api/members/{id}` — Удаление

### Участки
- `GET /api/plots` — Список участков
- `GET /api/plots/{id}` — Детальная информация
- `GET /api/plots/{id}/history` — История владения
- `POST /api/plots` — Создание
- `PUT /api/plots/{id}` — Обновление
- `DELETE /api/plots/{id}` — Удаление

### Взносы и платежи
- `GET /api/fees/types` — Виды взносов
- `GET /api/fees/rates` — Ставки взносов
- `GET /api/fees/accruals` — Начисления
- `POST /api/fees/accruals/bulk` — Массовое начисление
- `GET /api/fees/payments` — Платежи
- `POST /api/fees/payments` — Регистрация платежа

### Дашборд и отчеты
- `GET /api/dashboard` — Основная статистика
- `GET /api/dashboard/reports/debtors` — Отчет по должникам
- `GET /api/dashboard/reports/fees` — Отчет по взносам

Полная документация API доступна по адресу: `/docs` (Swagger UI)

## 🔧 Конфигурация

### Переменные окружения (backend/.env)

```env
# Приложение
APP_NAME="АИС СНТ-Управление"
DEBUG=True

# База данных
DB_HOST=localhost
DB_PORT=3306
DB_NAME=snt_monolit
DB_USER=snt_user
DB_PASSWORD=snt_password

# JWT
SECRET_KEY=change-this-to-a-random-secret-key
ACCESS_TOKEN_EXPIRE_MINUTES=1440
```

## 📝 Лицензия

Проект разработан для СНТ "Монолит". Все права принадлежат заказчику.

## 📞 Контакты

**СНТ "Монолит"**
- Адрес: 644043 Россия г. Омск ул. Партизанская 12
- Председатель: Пегасин Александр Александрович
- Телефон: 8 950 339 6939
- Email: snt-monolit@yandex.ru

---

Версия: 1.0.0  
Дата: 2026
