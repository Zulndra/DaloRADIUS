#!/bin/bash
set -e

DALORADIUS_CONF_FILE="/var/www/daloradius/app/common/includes/daloradius.conf.php"

echo "[+] Waiting for MariaDB to be ready..."
until mariadb -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASS}" "${DB_SCHEMA}" -e "SELECT 1" >/dev/null 2>&1; do
    echo "    Waiting for database connection..."
    sleep 2
done
echo "[+] MariaDB is ready!"

# Check if database is already initialized
TABLE_COUNT=$(mariadb -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASS}" "${DB_SCHEMA}" -sN -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '${DB_SCHEMA}'")

if [ "$TABLE_COUNT" -eq 0 ]; then
    echo "[+] Initializing database schema..."
    
    # Load freeRADIUS schema
    mariadb -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASS}" "${DB_SCHEMA}" < /var/www/daloradius/contrib/db/fr3-mariadb-freeradius.sql
    
    # Load daloRADIUS schema
    mariadb -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASS}" "${DB_SCHEMA}" < /var/www/daloradius/contrib/db/mariadb-daloradius.sql
    
    echo "[+] Database schema loaded successfully!"
    
    # Update default admin password
    INIT_PASSWORD="${INIT_PASSWORD:-radius}"
    mariadb -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASS}" "${DB_SCHEMA}" -e "UPDATE operators SET password='${INIT_PASSWORD}' WHERE username='administrator'"
    
    echo "[+] Default admin credentials:"
    echo "    Username: administrator"
    echo "    Password: ${INIT_PASSWORD}"
else
    echo "[+] Database already initialized, skipping schema loading"
fi

# Configure daloRADIUS
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

# Append environment variables to Apache envvars
cat >> /etc/apache2/envvars << EOF

# daloRADIUS Environment Variables
export DALORADIUS_USERS_PORT=${DALORADIUS_USERS_PORT}
export DALORADIUS_OPERATORS_PORT=${DALORADIUS_OPERATORS_PORT}
export DALORADIUS_SERVER_ADMIN=${DALORADIUS_SERVER_ADMIN}
EOF

echo "[+] Starting Apache..."

# Execute the command passed to the container
exec "$@"
