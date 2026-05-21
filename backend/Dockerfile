FROM php:8.2-fpm-alpine

RUN apk add --no-cache \
    nginx supervisor curl git unzip libzip-dev oniguruma-dev \
    && docker-php-ext-install pdo_mysql mbstring zip bcmath

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-interaction || true

COPY . .
RUN composer install --no-dev --optimize-autoloader --no-interaction 2>/dev/null || composer install --optimize-autoloader --no-interaction

RUN chown -R www-data:www-data storage bootstrap/cache

EXPOSE 8000

CMD php artisan serve --host=0.0.0.0 --port=8000
