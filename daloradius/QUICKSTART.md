# 🚀 Quick Start Guide - daloRADIUS Docker

## ⚡ Super Cepat (3 Langkah)

```bash
# 1. Generate semua file yang dibutuhkan
chmod +x create-files.sh
./create-files.sh

# 2. Jalankan auto setup
chmod +x setup.sh
./setup.sh

# 3. Tunggu 30 detik, lalu buka browser
# http://localhost:8000
```

Login: `administrator` / `radius`

---

## 📋 Langkah Detail

### 1️⃣ Pastikan Docker Terinstall

```bash
# Check Docker
docker --version

# Check Docker Compose
docker compose version
```

Jika belum ada, install dari: https://docs.docker.com/engine/install/

### 2️⃣ Download/Clone Files

Pastikan punya semua file Docker yang dibutuhkan:
- docker-compose.yml
- Dockerfile.daloradius
- Dockerfile.freeradius
- .env

### 3️⃣ Generate Config Files

```bash
# Generate config dan scripts yang hilang
chmod +x create-files.sh
./create-files.sh
```

Ini akan otomatis create:
- ✅ config/apache-*.conf
- ✅ scripts/configure-*.sh

### 4️⃣ Build & Run

**Opsi A - Otomatis (Recommended)**
```bash
chmod +x setup.sh
./setup.sh
```

**Opsi B - Manual**
```bash
# Build images
docker compose build

# Start containers
docker compose up -d

# Check logs
docker compose logs -f
```

### 5️⃣ Tunggu Initialization

First run butuh waktu 30-60 detik untuk:
- MariaDB initialization
- Database schema loading
- Apache startup

```bash
# Monitor progress
docker compose logs -f daloradius
```

Tunggu sampai muncul:
```
[+] Database schema loaded successfully!
[+] Starting Apache...
```

### 6️⃣ Login

Buka browser:

**Operators Dashboard (Admin)**
- URL: http://localhost:8000
- User: `administrator`
- Pass: `radius`

**Users Dashboard**
- URL: http://localhost:80

---

## 🔍 Troubleshooting

### Container tidak start?

```bash
# Check status
docker compose ps

# Check logs semua service
docker compose logs

# Check specific service
docker compose logs mariadb
docker compose logs freeradius
docker compose logs daloradius
```

### Database connection error?

```bash
# Restart semua
docker compose restart

# Atau restart dari awal
docker compose down
docker compose up -d
```

### Reset semua (fresh install)?

```bash
# Stop dan hapus SEMUA data
docker compose down -v

# Build ulang
docker compose build

# Start lagi
docker compose up -d
```

### File permission error?

```bash
# Fix permissions
chmod +x scripts/*.sh
chmod +x create-files.sh
chmod +x setup.sh
```

### Port sudah terpakai?

Edit `.env`:
```bash
DALORADIUS_USERS_PORT=8080
DALORADIUS_OPERATORS_PORT=9000
```

Lalu restart:
```bash
docker compose down
docker compose up -d
```

---

## 📊 Verifikasi Installation

### Check semua container running:
```bash
docker compose ps
```

Should show:
```
NAME                      STATUS
daloradius-mariadb        Up (healthy)
daloradius-freeradius     Up
daloradius-web            Up
```

### Test database:
```bash
docker compose exec mariadb mariadb -u radius -pradius radius -e "SHOW TABLES;"
```

### Test RADIUS:
```bash
# Test authentication (harus ada user dulu di daloRADIUS)
docker compose exec freeradius radtest testuser testpass localhost 0 testing123
```

---

## 🎯 Next Steps

1. **Login ke Operators Dashboard**: http://localhost:8000
2. **Buat RADIUS user** di menu "Management > Users"
3. **Tambah NAS/Client** di menu "Management > NAS"
4. **Test RADIUS auth** dengan radtest
5. **Monitor** di menu "Reports"

---

## 🛠️ Useful Commands

```bash
# Stop semua
docker compose down

# Stop dan hapus data
docker compose down -v

# Restart service tertentu
docker compose restart daloradius

# Lihat resource usage
docker stats

# Backup database
docker compose exec mariadb mysqldump -u radius -pradius radius > backup.sql

# Restore database
cat backup.sql | docker compose exec -T mariadb mariadb -u radius -pradius radius

# Masuk ke container
docker compose exec daloradius bash
docker compose exec freeradius bash
docker compose exec mariadb bash
```

---

## 📚 Documentation

- **Full README**: README.md
- **Checklist**: CHECKLIST.md
- **Original Install Script**: install.sh

---

## ❓ Need Help?

1. Check CHECKLIST.md - pastikan semua file ada
2. Check logs: `docker compose logs -f`
3. Try fresh install: `docker compose down -v && docker compose up -d`
4. Visit: https://github.com/lirantal/daloradius

---

**Happy RADIUS-ing! 🎉**
