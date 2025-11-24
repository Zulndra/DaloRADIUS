#!/bin/bash
set -e

FREERADIUS_SQL_MOD_PATH="/etc/freeradius/3.0/mods-available/sql"

echo "[+] Waiting for MariaDB to be ready..."
until mariadb -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASS}" "${DB_SCHEMA}" -e "SELECT 1" >/dev/null 2>&1; do
    echo "    Waiting for database connection..."
    sleep 2
done
echo "[+] MariaDB is ready!"

echo "[+] Configuring freeRADIUS SQL module..."

# Configure SQL module
sed -Ei '/^[\t\s#]*tls\s+\{/, /[\t\s#]*\}/ s/^/#/' "${FREERADIUS_SQL_MOD_PATH}"
sed -Ei 's/^[\t\s#]*dialect\s+=\s+.*$/\tdialect = "mysql"/g' "${FREERADIUS_SQL_MOD_PATH}"
sed -Ei 's/^[\t\s#]*driver\s+=\s+"rlm_sql_null"/\tdriver = "rlm_sql_${dialect}"/g' "${FREERADIUS_SQL_MOD_PATH}"
sed -Ei "s/^[\t\s#]*server\s+=\s+\"localhost\"/\tserver = \"${DB_HOST}\"/g" "${FREERADIUS_SQL_MOD_PATH}"
sed -Ei "s/^[\t\s#]*port\s+=\s+[0-9]+/\tport = ${DB_PORT}/g" "${FREERADIUS_SQL_MOD_PATH}"
sed -Ei "s/^[\t\s#]*login\s+=\s+\"radius\"/\tlogin = \"${DB_USER}\"/g" "${FREERADIUS_SQL_MOD_PATH}"
sed -Ei "s/^[\t\s#]*password\s+=\s+\"radpass\"/\tpassword = \"${DB_PASS}\"/g" "${FREERADIUS_SQL_MOD_PATH}"
sed -Ei "s/^[\t\s#]*radius_db\s+=\s+\"radius\"/\tradius_db = \"${DB_SCHEMA}\"/g" "${FREERADIUS_SQL_MOD_PATH}"
sed -Ei 's/^[\t\s#]*read_clients\s+=\s+.*$/\tread_clients = yes/g' "${FREERADIUS_SQL_MOD_PATH}"
sed -Ei 's/^[\t\s#]*client_table\s+=\s+.*$/\tclient_table = "nas"/g' "${FREERADIUS_SQL_MOD_PATH}"

# Enable SQL module
ln -sf "${FREERADIUS_SQL_MOD_PATH}" /etc/freeradius/3.0/mods-enabled/

echo "[+] freeRADIUS configuration completed!"
echo "[+] Starting freeRADIUS..."

# Execute the command passed to the container
exec "$@"
