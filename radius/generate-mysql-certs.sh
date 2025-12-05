#!/bin/bash
# generate-mysql-certs.sh

mkdir -p mysql-certs
cd mysql-certs

echo "Generating MySQL/MariaDB TLS certificates..."

# 1. Generate CA key dan certificate
openssl genrsa 2048 > ca-key.pem
openssl req -new -x509 -nodes -days 3650 -key ca-key.pem -out ca.pem \
  -subj "/C=ID/ST=Jakarta/L=Jakarta/O=MyOrg/CN=MySQL-CA"

# 2. Generate Server certificate
openssl req -newkey rsa:2048 -days 3650 -nodes -keyout server-key.pem -out server-req.pem \
  -subj "/C=ID/ST=Jakarta/L=Jakarta/O=MyOrg/CN=mariadb"

openssl rsa -in server-key.pem -out server-key.pem

openssl x509 -req -in server-req.pem -days 3650 -CA ca.pem -CAkey ca-key.pem \
  -set_serial 01 -out server-cert.pem

# 3. Generate Client certificate
openssl req -newkey rsa:2048 -days 3650 -nodes -keyout client-key.pem -out client-req.pem \
  -subj "/C=ID/ST=Jakarta/L=Jakarta/O=MyOrg/CN=freeradius"

openssl rsa -in client-key.pem -out client-key.pem

openssl x509 -req -in client-req.pem -days 3650 -CA ca.pem -CAkey ca-key.pem \
  -set_serial 02 -out client-cert.pem

# 4. Verify certificates
echo ""
echo "Verifying certificates..."
openssl verify -CAfile ca.pem server-cert.pem client-cert.pem

# 5. Set correct ownership and permissions for MariaDB
# MariaDB container runs as mysql user (UID:GID = 999:999)
echo ""
echo "Setting permissions..."
sudo chown 999:999 *.pem *.key 2>/dev/null || chown 999:999 *.pem *.key
chmod 644 ca.pem server-cert.pem client-cert.pem
chmod 600 server-key.pem client-key.pem ca-key.pem

# 6. Cleanup temporary files
rm -f server-req.pem client-req.pem

echo ""
echo "✅ MySQL TLS certificates generated successfully!"
echo ""
echo "Files created:"
ls -lh
cd ..
