#!/bin/bash

echo "========================================"
echo "  Create Missing daloRADIUS Files"
echo "========================================"
echo ""

# Create directories
mkdir -p config
mkdir -p scripts

# Create config/apache-operators.conf
if [ ! -f "config/apache-operators.conf" ]; then
    cat > config/apache-operators.conf << 'EOF'
<VirtualHost *:${DALORADIUS_OPERATORS_PORT}>
  ServerAdmin ${DALORADIUS_SERVER_ADMIN}
  DocumentRoot /var/www/daloradius/app/operators

  <Directory /var/www/daloradius/app/operators>
    Options -Indexes +FollowSymLinks
    AllowOverride All
    Require all granted
  </Directory>

  <Directory /var/www/daloradius>
    Require all denied
  </Directory>

  ErrorLog ${APACHE_LOG_DIR}/daloradius/operators/error.log
  CustomLog ${APACHE_LOG_DIR}/daloradius/operators/access.log combined
</VirtualHost>
EOF
    echo "✓ Created config/apache-operators.conf"
else
    echo "○ config/apache-operators.conf already exists"
fi

# Create config/apache-users.conf
if [ ! -f "config/apache-users.conf" ]; then
    cat > config/apache-users.conf << 'EOF'
<VirtualHost *:${DALORADIUS_USERS_PORT}>
  ServerAdmin ${DALORADIUS_SERVER_ADMIN}
  DocumentRoot /var/www/daloradius/app/users

  <Directory /var/www/daloradius/app/users>
    Options -Indexes +FollowSymLinks
    AllowOverride None
    Require all granted
  </Directory>

  <Directory /var/www/daloradius>
    Require all denied
  </Directory>

  ErrorLog ${APACHE_LOG_DIR}/daloradius/users/error.log
  CustomLog ${APACHE_LOG_DIR}/daloradius/users/access.log combined
</VirtualHost>
EOF
    echo "✓ Created config/apache-users.conf"
else
    echo "○ config/apache-users.conf already exists"
fi

# Create config/apache-ports.conf
if [ ! -f "config/apache-ports.conf" ]; then
    cat > config/apache-ports.conf << 'EOF'
# daloRADIUS Apache Ports Configuration
Listen ${DALORADIUS_USERS_PORT}
Listen ${DALORADIUS_OPERATORS_PORT}
EOF
    echo "✓ Created config/apache-ports.conf"
else
    echo "○ config/apache-ports.conf already exists"
fi

# Create scripts/configure-freeradius.sh
if [ ! -f "scripts/configure-freeradius.sh" ]; then
    cat > scripts/configure-freeradius.sh << 'EOF'
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
EOF
    chmod +x scripts/configure-freeradius.sh
    echo "✓ Created scripts/configure-freeradius.sh"
else
    echo "○ scripts/configure-freeradius.sh already exists"
fi

# Create scripts/configure-daloradius.sh
if [ ! -f "scripts/configure-daloradius.sh" ]; then
    cat > scripts/configure-daloradius.sh << 'EOF'
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
cat >> /etc/apache2/envvars << ENVEOF

# daloRADIUS Environment Variables
export DALORADIUS_USERS_PORT=${DALORADIUS_USERS_PORT}
export DALORADIUS_OPERATORS_PORT=${DALORADIUS_OPERATORS_PORT}
export DALORADIUS_SERVER_ADMIN=${DALORADIUS_SERVER_ADMIN}
ENVEOF

echo "[+] Starting Apache..."

# Execute the command passed to the container
exec "$@"
EOF
    chmod +x scripts/configure-daloradius.sh
    echo "✓ Created scripts/configure-daloradius.sh"
else
    echo "○ scripts/configure-daloradius.sh already exists"
fi

echo ""
echo "========================================"
echo "  ✓ File creation complete!"
echo "========================================"
echo ""
echo "All required config files have been created."
echo "You can now run: docker compose build"
