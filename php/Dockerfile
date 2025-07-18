ARG PHP_VERSION=latest
FROM php:${PHP_VERSION}-fpm

RUN apt-get update && apt-get install -y \
    git zip unzip libzip-dev \
    libpng-dev libjpeg-dev libfreetype6-dev \
    libonig-dev libxml2-dev \
    libcurl4-openssl-dev \
    libicu-dev \
    libpq-dev \
    libmcrypt-dev \
    libxslt-dev \
    libreadline-dev \
    libsqlite3-dev \
    libmagickwand-dev \
    libjpeg-dev \
    libssl-dev \
    redis-tools \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
&& docker-php-ext-install -j$(nproc) \
gd zip intl opcache pdo pdo_mysql pdo_pgsql \
bcmath curl mbstring xml xsl soap pcntl calendar \
exif iconv mysqli sockets

RUN pecl install redis imagick \
    && docker-php-ext-enable redis imagick

RUN chown -R www-data:www-data /var/www/html

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

RUN pecl install xdebug \
    && docker-php-ext-enable xdebug

# Create Xdebug configuration file
RUN echo "zend_extension=xdebug" > /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini.disabled \
    && echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini.disabled \
    && echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini.disabled \
    && echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini.disabled \
    && echo "xdebug.client_port=9003" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini.disabled \
    && echo "xdebug.log=/tmp/xdebug.log" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini.disabled

ENTRYPOINT ["/bin/sh", "-c", "if [ \"$PHP_ENABLE_XDEBUG\" = \"1\" ]; then cp /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini.disabled /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; fi && php-fpm"]

WORKDIR /var/www/html
COPY ./api /var/www/html

RUN chown -R www-data:www-data /var/www/html