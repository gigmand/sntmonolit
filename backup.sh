#!/bin/bash
# =============================================================================
# Скрипт резервного копирования АИС "СНТ-Управление"
# =============================================================================
# Автоматическое резервное копирование базы данных и файлов загрузок
# =============================================================================

set -e

# Настройки
INSTALL_DIR="/opt/monolit"
BACKUP_DIR="/opt/monolit/backups"
DB_NAME="snt_monolit"
DB_USER="snt_user"
RETENTION_DAYS=30
DATE=$(date +%Y%m%d_%H%M%S)

# Чтение пароля БД из .env файла
if [ -f "${INSTALL_DIR}/backend/.env" ]; then
    DB_PASSWORD=$(grep "^DB_PASSWORD=" ${INSTALL_DIR}/backend/.env | cut -d'=' -f2 | tr -d '"')
else
    echo "Ошибка: не найден файл .env"
    exit 1
fi

# Создание директории для бэкапов
mkdir -p ${BACKUP_DIR}

echo "=========================================="
echo "Резервное копирование АИС СНТ-Управление"
echo "Дата: $(date)"
echo "=========================================="

# Бэкап базы данных
echo "[1/3] Бэкап базы данных..."
mysqldump -u ${DB_USER} -p'${DB_PASSWORD}' ${DB_NAME} > ${BACKUP_DIR}/db_${DATE}.sql
echo "  Создан: db_${DATE}.sql"

# Бэкап загрузок
echo "[2/3] Бэкап файлов загрузок..."
tar -czf ${BACKUP_DIR}/uploads_${DATE}.tar.gz -C ${INSTALL_DIR} uploads/
echo "  Создан: uploads_${DATE}.tar.gz"

# Бэкап .env файла
echo "[3/3] Бэкап конфигурации..."
cp ${INSTALL_DIR}/backend/.env ${BACKUP_DIR}/env_${DATE}.bak

# Удаление старых бэкапов
echo "Очистка старых бэкапов (старше ${RETENTION_DAYS} дней)..."
find ${BACKUP_DIR} -name "db_*.sql" -mtime +${RETENTION_DAYS} -delete
find ${BACKUP_DIR} -name "uploads_*.tar.gz" -mtime +${RETENTION_DAYS} -delete
find ${BACKUP_DIR} -name "env_*.bak" -mtime +${RETENTION_DAYS} -delete

# Информация о размере
echo ""
echo "Размер бэкапов:"
du -sh ${BACKUP_DIR}/*_${DATE}.* 2>/dev/null || true
echo ""
echo "Общий размер:"
du -sh ${BACKUP_DIR}

echo ""
echo "=========================================="
echo "Резервное копирование завершено!"
echo "=========================================="
