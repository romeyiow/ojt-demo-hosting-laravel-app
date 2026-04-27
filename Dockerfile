# Multi-stage build for Laravel 13 application
# Stage 1: Dependencies and build
FROM php:8.4-fpm-alpine AS dependencies

RUN apk add --no-cache \
    curl \
    git \
    zip \
    unzip \
    libpq-dev \
    sqlite-dev \
    oniguruma-dev \
    libxml2-dev \
    linux-headers

RUN docker-php-ext-install \
    pdo \
    pdo_sqlite \
    pdo_mysql \
    mbstring \
    xml \
    bcmath

# Install Node.js for frontend build
FROM node:22-alpine AS node_builder

WORKDIR /app
COPY package*.json ./
RUN npm ci --prefer-offline --no-audit

COPY . .
RUN npm run build

# Stage 2: Composer dependencies
FROM php:8.4-fpm-alpine AS composer_builder

RUN apk add --no-cache \
    curl \
    git \
    zip \
    unzip \
    libpq-dev \
    sqlite-dev \
    oniguruma-dev \
    libxml2-dev

RUN docker-php-ext-install \
    pdo \
    pdo_sqlite \
    pdo_mysql \
    mbstring \
    xml \
    bcmath

WORKDIR /app

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY composer.json composer.lock ./
RUN composer install \
    --no-dev \
    --no-interaction \
    --no-plugins \
    --no-scripts \
    --prefer-dist

# Stage 3: Final production image
FROM php:8.4-fpm-alpine

# Install runtime dependencies only
RUN apk add --no-cache \
    libpq \
    sqlite \
    oniguruma \
    libxml2 \
    curl \
    nginx \
    supervisor \
    bash

# Install PHP extensions
RUN docker-php-ext-install \
    pdo \
    pdo_sqlite \
    pdo_mysql \
    mbstring \
    xml \
    bcmath

# Set working directory
WORKDIR /app

# Copy PHP configuration
RUN mkdir -p /etc/php/8.4 && \
    echo "memory_limit=512M" > /usr/local/etc/php/conf.d/app.ini && \
    echo "upload_max_filesize=100M" >> /usr/local/etc/php/conf.d/app.ini && \
    echo "post_max_size=100M" >> /usr/local/etc/php/conf.d/app.ini

# Copy application files
COPY --chown=www-data:www-data . .

# Copy built assets from Node stage
COPY --from=node_builder --chown=www-data:www-data /app/public/build ./public/build

# Copy composer dependencies from Composer stage
COPY --from=composer_builder --chown=www-data:www-data /app/vendor ./vendor

# Create necessary directories
RUN mkdir -p storage/logs storage/framework/sessions storage/framework/views storage/framework/cache && \
    chmod -R 775 storage bootstrap/cache

# Create nginx configuration
RUN mkdir -p /etc/nginx/conf.d

COPY <<'EOF' /etc/nginx/conf.d/default.conf
server {
    listen 80;
    server_name _;
    root /app/public;

    index index.php index.html;

    client_max_body_size 100M;

    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_param SCRIPT_NAME $fastcgi_script_name;
    }

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~* ^/(?:css|js|images|fonts)/(.*)$ {
        expires 7d;
        add_header Cache-Control "public, immutable";
    }

    gzip on;
    gzip_types text/css text/javascript application/javascript application/json;
}
EOF

# Create supervisor configuration
COPY <<'EOF' /etc/supervisor/conf.d/laravel.conf
[supervisord]
nodaemon=true
logfile=/var/log/supervisor/supervisord.log

[program:php-fpm]
command=/usr/local/sbin/php-fpm
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/php-fpm.err.log
stdout_logfile=/var/log/supervisor/php-fpm.out.log

[program:nginx]
command=/usr/sbin/nginx -g "daemon off;"
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/nginx.err.log
stdout_logfile=/var/log/supervisor/nginx.out.log

[program:laravel-queue]
process_name=%(program_name)s_%(process_num)02d
command=php /app/artisan queue:work --sleep=3 --tries=3
autostart=true
autorestart=true
numprocs=1
redirect_stderr=true
stdout_logfile=/var/log/supervisor/laravel-queue.log
EOF

# Create application startup script
COPY <<'EOF' /app/docker-entrypoint.sh
#!/bin/bash
set -e

echo "Running Laravel application setup..."

# Generate app key if not set
if [ -z "$APP_KEY" ]; then
    echo "Generating APP_KEY..."
    php artisan key:generate --force
fi

# Run migrations
echo "Running migrations..."
php artisan migrate --force

# Clear caches
echo "Clearing caches..."
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear

echo "Starting supervisor..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/laravel.conf
EOF

RUN chmod +x /app/docker-entrypoint.sh

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Run entrypoint
ENTRYPOINT ["/app/docker-entrypoint.sh"]
