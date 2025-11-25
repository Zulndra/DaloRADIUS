#!/bin/bash
set -e

DALORADIUS_CONF_FILE="/var/www/daloradius/app/common/includes/daloradius.conf.php"

echo "[+] Starting daloRADIUS configuration..."
echo "[+] Environment: DB_HOST=${DB_HOST}, DB_PORT=${DB_PORT}, DB_USER=${DB_USER}, DB_SCHEMA=${DB_SCHEMA}"

# CREATE LOG DIRECTORIES FIRST - THIS IS CRITICAL!
echo "[+] Creating Apache log directories..."
mkdir -p /var/log/apache2/daloradius/operators
mkdir -p /var/log/apache2/daloradius/users
chown -R www-data:www-data /var/log/apache2/daloradius
chmod -R 755 /var/log/apache2/daloradius
echo "[+] Log directories created successfully!"

echo "[+] Waiting for MariaDB to be ready..."
RETRY_COUNT=0
MAX_RETRIES=30
until mariadb -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASS}" "${DB_SCHEMA}" -e "SELECT 1" >/dev/null 2>&1; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        echo "[!] ERROR: Failed to connect to MariaDB after ${MAX_RETRIES} attempts"
        exit 1
    fi
    echo "    Waiting for database connection... (${RETRY_COUNT}/${MAX_RETRIES})"
    sleep 2
done
echo "[+] MariaDB is ready!"

TABLE_COUNT=$(mariadb -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASS}" "${DB_SCHEMA}" -sN -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '${DB_SCHEMA}'")

if [ "$TABLE_COUNT" -eq 0 ]; then
    echo "[+] Initializing database schema..."
    
    mariadb -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASS}" "${DB_SCHEMA}" < /var/www/daloradius/contrib/db/fr3-mariadb-freeradius.sql
    mariadb -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASS}" "${DB_SCHEMA}" < /var/www/daloradius/contrib/db/mariadb-daloradius.sql
    
    echo "[+] Database schema loaded successfully!"
    
    INIT_PASSWORD="${INIT_PASSWORD:-radius}"
    mariadb -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASS}" "${DB_SCHEMA}" -e "UPDATE operators SET password='${INIT_PASSWORD}' WHERE username='administrator'"
    
    echo "[+] =========================================="
    echo "[+] Default admin credentials:"
    echo "[+]   Username: administrator"
    echo "[+]   Password: ${INIT_PASSWORD}"
    echo "[+] =========================================="
else
    echo "[+] Database already initialized, skipping schema loading"
fi

if [ ! -f "${DALORADIUS_CONF_FILE}" ]; then
    echo "[+] Configuring daloRADIUS..."
    cp "${DALORADIUS_CONF_FILE}.sample" "${DALORADIUS_CONF_FILE}"
    
    sed -Ei "s/^.*CONFIG_DB_HOST'\].*$/\$configValues['CONFIG_DB_HOST'] = '${DB_HOST}';/" "${DALORADIUS_CONF_FILE}"
    sed -Ei "s/^.*CONFIG_DB_PORT'\].*$/\$configValues['CONFIG_DB_PORT'] = '${DB_PORT}';/" "${DALORADIUS_CONF_FILE}"
    sed -Ei "s/^.*CONFIG_DB_USER'\].*$/\$configValues['CONFIG_DB_USER'] = '${DB_USER}';/" "${DALORADIUS_CONF_FILE}"
    sed -Ei "s/^.*CONFIG_DB_PASS'\].*$/\$configValues['CONFIG_DB_PASS'] = '${DB_PASS}';/" "${DALORADIUS_CONF_FILE}"
    sed -Ei "s/^.*CONFIG_DB_NAME'\].*$/\$configValues['CONFIG_DB_NAME'] = '${DB_SCHEMA}';/" "${DALORADIUS_CONF_FILE}"
    
    chown www-data:www-data "${DALORADIUS_CONF_FILE}"
    chmod 664 "${DALORADIUS_CONF_FILE}"
    
    echo "[+] daloRADIUS configuration completed!"
else
    echo "[+] daloRADIUS already configured, skipping"
fi

echo "[+] Configuring Apache environment variables..."
cat >> /etc/apache2/envvars << ENVEOF

# daloRADIUS Environment Variables
export DALORADIUS_USERS_PORT=${DALORADIUS_USERS_PORT:-80}
export DALORADIUS_OPERATORS_PORT=${DALORADIUS_OPERATORS_PORT:-8000}
export DALORADIUS_SERVER_ADMIN=${DALORADIUS_SERVER_ADMIN:-admin@daloradius.local}
ENVEOF

echo "[+] Testing Apache configuration..."
apache2ctl configtest || true

echo "[+] =========================================="
echo "[+] Starting Apache web server..."
echo "[+] =========================================="

exec "$@"
