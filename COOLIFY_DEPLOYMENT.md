# Coolify Deployment Guide

This guide explains how to deploy your Laravel 13 application to Coolify.

## Prerequisites

- Coolify instance running
- Docker and Docker Compose installed on your server
- Your app pushed to a Git repository (GitHub, GitLab, Gitea, etc.)
- Environment variables ready

## Deployment Methods

### Method 1: Using Dockerfile (Recommended)

This uses the multi-stage `Dockerfile` provided in the repository root.

**Steps:**

1. **In Coolify Dashboard:**
   - Create a new service → Select "Docker" service
   - Set the **Git Repository** to your repo URL
   - Set **Dockerfile Path** to `Dockerfile` (default)
   - Set **Build Pack** to "Docker"

2. **Environment Variables:**
   Add the following in Coolify's environment section:
   ```
   APP_NAME=Laravel
   APP_ENV=production
   APP_DEBUG=false
   APP_URL=https://your-domain.com
   APP_KEY=base64:xxxxxxxxxxxx
   
   DB_CONNECTION=sqlite
   
   SESSION_DRIVER=database
   QUEUE_CONNECTION=database
   CACHE_STORE=database
   
   MAIL_MAILER=log
   LOG_CHANNEL=stack
   LOG_LEVEL=info
   ```

3. **Configure Port:**
   - Exposed Port: `80`
   - Public Port: `443` (if using HTTPS/domain)

4. **Storage & Persistence:**
   - Mount `/app/storage` as a volume for persistent logs and files
   - Mount `/app/database` if using SQLite

5. **Deploy:**
   - Click "Deploy" and monitor the build logs

### Method 2: Docker Compose (Alternative)

Create a `docker-compose.prod.yaml` for production:

```yaml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: laravel_app
    restart: always
    ports:
      - "80:80"
    environment:
      APP_NAME: Laravel
      APP_ENV: production
      APP_DEBUG: false
      APP_URL: https://your-domain.com
      APP_KEY: ${APP_KEY}
      DB_CONNECTION: sqlite
    volumes:
      - ./storage:/app/storage
      - ./database:/app/database
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 40s
```

Then in Coolify, select "Docker Compose" and reference this file.

## Environment Variables

Essential variables for production:

```env
# App Configuration
APP_NAME=Your App Name
APP_ENV=production
APP_DEBUG=false
APP_KEY=base64:generated_key_here
APP_URL=https://yourdomain.com

# Database
DB_CONNECTION=sqlite
# Or for MySQL/PostgreSQL:
# DB_CONNECTION=mysql
# DB_HOST=your-db-host
# DB_PORT=3306
# DB_DATABASE=laravel_db
# DB_USERNAME=user
# DB_PASSWORD=password

# Session & Cache
SESSION_DRIVER=database
CACHE_STORE=database
QUEUE_CONNECTION=database

# Mail
MAIL_MAILER=log
# Or configure SMTP:
# MAIL_MAILER=smtp
# MAIL_HOST=smtp.mailtrap.io
# MAIL_PORT=2525
# MAIL_USERNAME=username
# MAIL_PASSWORD=password

# Logging
LOG_CHANNEL=stack
LOG_LEVEL=info

# Optional: External Database
# Configure if not using SQLite
```

## File Structure in Container

```
/app/
├── app/
├── bootstrap/
├── config/
├── database/
│   └── database.sqlite    (persistent volume)
├── public/
│   └── build/             (compiled assets)
├── resources/
├── routes/
├── storage/               (persistent volume)
│   ├── logs/
│   ├── framework/
│   └── app/
├── vendor/
├── .env                   (injected at runtime)
└── artisan
```

## Advanced Configuration

### Custom Domain with HTTPS

In Coolify:
1. Add your domain in the "Domain" settings
2. Enable "Auto SSL" (uses Let's Encrypt)
3. Configure DNS to point to your Coolify server

### Using External Database

Instead of SQLite, use a managed database:

```env
DB_CONNECTION=mysql
DB_HOST=managed-db.provider.com
DB_PORT=3306
DB_DATABASE=laravel_prod
DB_USERNAME=user
DB_PASSWORD=secure_password
```

Update `DB_CONNECTION=sqlite` to your database of choice.

### Queue Workers

The Dockerfile includes a queue worker via Supervisor. To enable:

```env
QUEUE_CONNECTION=database  # or redis
```

The container automatically runs:
- PHP-FPM (app server)
- Nginx (web server)
- Laravel Queue Worker (background jobs)

### Caching

For better performance, configure a cache driver:

```env
CACHE_STORE=redis
REDIS_HOST=redis-host
REDIS_PORT=6379
```

## Logs & Monitoring

### View Logs in Coolify

1. In the service dashboard, click "Logs"
2. Filter by container name: `laravel_app`

### Access Application Logs

Logs are in `/app/storage/logs/`. Mount this as a volume to persist them.

## Database Migrations

Migrations run automatically on container startup. To manually run:

```bash
docker exec laravel_app php artisan migrate --force
```

## Troubleshooting

### Build Fails

Check the build logs in Coolify. Common issues:
- Missing environment variables (ensure `APP_KEY` is set)
- Composer/npm dependency issues (check `.dockerignore`)
- Base image unavailable

### Container Crashes

1. Check logs: `docker logs <container_id>`
2. Verify `APP_KEY` is set
3. Check storage directory permissions
4. Ensure migrations are passing

### Database Connection Issues

For SQLite:
- Ensure `/app/database` volume is writable
- Verify `database/` folder exists

For MySQL/PostgreSQL:
- Verify connection credentials
- Check database host is reachable
- Ensure user has necessary permissions

## Performance Tips

1. **Use a CDN** for static assets (JS, CSS, images)
2. **Enable Redis** for caching and sessions
3. **Use a managed database** instead of SQLite for production
4. **Configure autostart** in Coolify for automatic restarts
5. **Set up monitoring** and alerts

## Updating the Application

1. Push changes to your Git repository
2. In Coolify, click "Redeploy"
3. Container rebuilds and restarts automatically

## Support

For Coolify-specific help:
- [Coolify Documentation](https://coolify.io/docs)
- [Coolify Discord Community](https://cool.sh/discord)

For Laravel help:
- [Laravel Documentation](https://laravel.com/docs)
- [Laravel Cloud](https://cloud.laravel.com/)
