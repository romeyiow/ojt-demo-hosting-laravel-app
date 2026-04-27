# Docker & Coolify Quick Reference

## 🚀 Quick Deploy Checklist

- [ ] Push code to Git repository
- [ ] Copy `.env.example` to `.env` (locally)
- [ ] Run `php artisan key:generate` (get APP_KEY value)
- [ ] In Coolify:
  - [ ] Create Docker service
  - [ ] Connect Git repository
  - [ ] Set `APP_KEY` environment variable
  - [ ] Set `APP_ENV=production`
  - [ ] Click "Deploy"

## 📦 Dockerfile Info

**Location:** `./Dockerfile`

**Type:** Multi-stage build (3 stages)
- Stage 1: Dependencies installer
- Stage 2: Node.js frontend builder
- Stage 3: Final production image

**Base Image:** `php:8.4-fpm-alpine` (~500MB)

**Final Size:** ~150-200MB (optimized)

**Includes:**
- Nginx web server
- PHP-FPM application server
- Supervisor process manager
- Laravel queue worker
- Health checks

## 🔌 Ports

- **Internal:** 80 (HTTP)
- **Coolify:** Configure domain for HTTPS

## 📁 Persistent Volumes

Mount these to preserve data between deployments:

```yaml
volumes:
  - ./storage:/app/storage          # Logs, cache, uploads
  - ./database:/app/database        # SQLite database
```

## 🔑 Required Environment Variables

```env
APP_KEY=base64:xxxxx               # Generate: php artisan key:generate
APP_ENV=production
APP_DEBUG=false
APP_URL=https://yourdomain.com
DB_CONNECTION=sqlite               # or mysql/pgsql
```

## 🗄️ Database Options

### SQLite (Default, included)
```env
DB_CONNECTION=sqlite
```
✅ Simple, no external database
❌ Not ideal for high concurrency

### MySQL
```env
DB_CONNECTION=mysql
DB_HOST=mysql-server
DB_PORT=3306
DB_DATABASE=laravel_app
DB_USERNAME=user
DB_PASSWORD=password
```

### PostgreSQL
```env
DB_CONNECTION=pgsql
DB_HOST=postgres-server
DB_PORT=5432
DB_DATABASE=laravel_app
DB_USERNAME=user
DB_PASSWORD=password
```

## ⚙️ What Runs Automatically

1. **App Key Generation** (if missing)
2. **Database Migrations** (`php artisan migrate --force`)
3. **Cache Clearing** (config, route, view cache)
4. **Queue Worker** (via Supervisor)
5. **Health Checks** (HTTP endpoint every 30s)

## 🔄 Deployment Update Flow

1. Make code changes locally
2. Push to Git repository
3. In Coolify → Click "Redeploy"
4. Container rebuilds and restarts
5. Migrations run automatically

## 📊 Monitoring & Logs

In Coolify dashboard:
- Click service → "Logs" tab
- Filter by container logs
- Check for errors/warnings

Common log locations:
- `/app/storage/logs/` (Laravel)
- `/var/log/supervisor/` (supervisor)
- `/var/log/nginx/` (Nginx)

## 🐛 Troubleshooting

**"Application failed to start"**
- Check `APP_KEY` is set
- Verify migrations passed
- Check database connectivity

**"Permission denied on storage"**
- Ensure `/app/storage` volume exists
- Check folder permissions (writable)

**"Database locked (SQLite)"**
- Use external database (MySQL/PostgreSQL)
- Or ensure only one app instance runs

**"Build failed"**
- Check Git repo URL is correct
- Verify `.env` variables are set
- Review build logs in Coolify

## 📚 Full Documentation

See `COOLIFY_DEPLOYMENT.md` for comprehensive guide including:
- Step-by-step Coolify setup
- Custom domains & HTTPS
- Advanced configuration
- Performance optimization
- Troubleshooting guide

## 🔗 Useful Links

- [Coolify Docs](https://coolify.io/docs)
- [Laravel Docs](https://laravel.com/docs)
- [Docker Docs](https://docs.docker.com/)
- [Nginx Docs](https://nginx.org/en/docs/)
