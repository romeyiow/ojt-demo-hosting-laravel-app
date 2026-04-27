# Use an official PHP production image
FROM php:8.3-fpm-alpine

# Install system dependencies and PHP extensions
RUN apk add --no-cache \
    nginx \
    supervisor \
    libpng-dev \
    libzip-dev \
    zip \
    unzip

RUN docker-php-ext-install pdo_mysql gd zip

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . .

# Install Composer dependencies
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-dev --optimize-autoloader

# Set permissions
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Copy Nginx configuration (you'll need to add a basic nginx.conf to your repo)
COPY ./docker/nginx.conf /etc/nginx/http.d/default.conf

# Expose port 80
EXPOSE 80

# Start via a script or Supervisor
CMD ["sh", "-c", "php-fpm -D && nginx -g 'daemon off;'"]
