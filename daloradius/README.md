# daloRADIUS Docker Setup

Docker Compose setup untuk daloRADIUS dengan FreeRADIUS dan MariaDB.

## Struktur Folder

```
.
├── docker-compose.yml
├── Dockerfile.daloradius
├── Dockerfile.freeradius
├── .env
├── config/
│   ├── apache-operators.conf
│   ├── apache-users.conf
│   ├── apache-ports.conf
│   └── apache-envvars
├── scripts/
│   ├── configure-daloradius.sh
│   └── configure-freeradius.sh
└── README.md
```

## Instalasi

### Cara Otomatis (Recommended)

```bash
# 1. Pastikan semua file sudah ada
# 2. Jalankan setup script
chmod +x setup.sh
./setup.sh
```

Setup script akan otomatis:
- ✅ Membuat folder yang diperlukan
- ✅ Memeriksa file yang hilang
- ✅ Set permission
- ✅ Build dan start containers

### Cara Manual

### 1. Clone atau Download Files

Pastikan semua file di atas sudah ada dalam struktur folder yang benar.

### 2. Buat Folder yang Diperlukan

```bash
mkdir -p config scripts
```

### 3. Pastikan Semua File Ada

Cek bahwa file-file berikut sudah ada:
- ✅ docker-compose.yml
- ✅ Dockerfile.daloradius
- ✅ Dockerfile.freeradius
- ✅ .env
- ✅ scripts/configure-daloradius.sh
- ✅ scripts/configure-freeradius.sh
- ✅ config/apache-operators.conf
- ✅ config/apache-users.conf
- ✅ config/apache-ports.conf

### 4. Set Permission untuk Scripts

```bash
chmod +x scripts/*.sh
```

### 5. Konfigurasi Environment Variables (Optional)

Edit file `.env` sesuai kebutuhan:

```bash
# MariaDB Configuration
MYSQL_ROOT_PASSWORD=rootpassword
DB_HOST=mariadb
DB_PORT=3306
DB_USER=radius
DB_PASS=radiuspass
DB_SCHEMA=radius

# daloRADIUS Configuration
DALORADIUS_USERS_PORT=80
DALORADIUS_OPERATORS_PORT=8000
DALORADIUS_SERVER_ADMIN=admin@daloradius.local

# Initial Admin Credentials
INIT_USERNAME=administrator
INIT_PASSWORD=radius
```

### 6. Build dan Jalankan

```bash
# Build images
docker compose build

# Jalankan containers
docker compose up -d

# Lihat logs (tunggu sampai semua service ready)
docker compose logs -f
```

**Catatan**: Tunggu 30-60 detik untuk database initialization pada first run.

## Akses

Setelah semua container berjalan:

- **Users Interface**: http://localhost:80
- **Operators Interface**: http://localhost:8000

### Login Credentials (Default)

- **Username**: administrator
- **Password**: radius (atau sesuai `INIT_PASSWORD` di `.env`)

## Management

### Stop Containers

```bash
docker-compose down
```

### Stop dan Hapus Volumes (Reset Database)

```bash
docker-compose down -v
```

### Restart Services

```bash
docker-compose restart
```

### Lihat Status

```bash
docker-compose ps
```

### Akses Container

```bash
# daloRADIUS Web
docker-compose exec daloradius bash

# FreeRADIUS
docker-compose exec freeradius bash

# MariaDB
docker-compose exec mariadb bash
```

## Troubleshooting

### Check Logs

```bash
# Semua services
docker-compose logs

# Specific service
docker-compose logs daloradius
docker-compose logs freeradius
docker-compose logs mariadb
```

### Database Connection Issues

```bash
# Test database connection
docker-compose exec daloradius mariadb -h mariadb -u radius -p radius
```

### FreeRADIUS Debug Mode

```bash
# Masuk ke container
docker-compose exec freeradius bash

# Stop service
pkill freeradius

# Run in debug mode
freeradius -X
```

### Reset Admin Password

```bash
docker-compose exec mariadb mariadb -u radius -p radius -e \
  "UPDATE operators SET password='newpassword' WHERE username='administrator'"
```

## Port Customization

Untuk mengubah port, edit file `.env`:

```bash
DALORADIUS_USERS_PORT=8080
DALORADIUS_OPERATORS_PORT=9000
```

Kemudian restart:

```bash
docker-compose down
docker-compose up -d
```

## Backup Database

```bash
# Backup
docker-compose exec mariadb mysqldump -u radius -p radius > backup.sql

# Restore
docker-compose exec -T mariadb mariadb -u radius -p radius < backup.sql
```

## Volumes

Data persisten disimpan di:

- `mariadb_data`: Database MariaDB
- `freeradius_logs`: FreeRADIUS logs
- `daloradius_logs`: Apache/daloRADIUS logs
- `daloradius_var`: daloRADIUS var directory (backups, logs)

## Security Notes

⚠️ **PENTING untuk Production:**

1. Ubah semua password default di file `.env`
2. Gunakan strong passwords
3. Pertimbangkan untuk menggunakan Docker secrets untuk credentials
4. Setup SSL/TLS untuk web interface
5. Restrict port access dengan firewall
6. Regular backup database

## Advanced Configuration

### Menggunakan External Database

Edit `docker-compose.yml` dan hapus service `mariadb`, kemudian update environment variables untuk mengarah ke database external.

### Custom FreeRADIUS Configuration

Mount custom configuration:

```yaml
freeradius:
  volumes:
    - ./freeradius-config:/etc/freeradius/3.0
```

### Enable HTTPS

Tambahkan reverse proxy seperti Nginx atau Traefik dengan SSL certificates.

## Support

Untuk issues dan dokumentasi lengkap, kunjungi:
- daloRADIUS: https://github.com/lirantal/daloradius
- FreeRADIUS: https://freeradius.org/
