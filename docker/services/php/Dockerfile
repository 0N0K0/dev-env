ARG PHP_VERSION=8.4
ARG SOURCE_DIR=api
FROM php:${PHP_VERSION}-fpm

# Install ALL system dependencies for PHP extensions
RUN apt-get update && apt-get install -y \
    # Core libraries
    libonig-dev libxml2-dev libpq-dev libsqlite3-dev \
    # Image processing
    libpng-dev libjpeg-dev libfreetype6-dev libwebp-dev libxpm-dev \
    libmagickwand-dev libavif-dev \
    # Archive and compression
    libzip-dev libbz2-dev libzstd-dev liblzf-dev \
    # Networking and protocols
    libcurl4-openssl-dev libssl-dev libssh2-1-dev \
    # Internationalization and encoding
    libicu-dev libiconv-hook-dev libonig-dev \
    # Database drivers
    libmemcached-dev libmongoc-1.0-0 libmongoc-dev \
    # System integration
    libffi-dev libkrb5-dev libldap2-dev libsasl2-dev \
    # Math and science
    libgmp-dev \
    # Additional utilities
    libtidy-dev libxslt1-dev libedit-dev \
    # Build tools (will be cleaned up)
    build-essential pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Install PECL extensions (non-bundled)
RUN pecl install \
    redis \
    imagick \
    mongodb \
    memcached \
    ssh2 \
    && docker-php-ext-enable redis imagick mongodb memcached ssh2

# Configure and install ALL stable PHP extensions  
RUN docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
        --with-webp \
        --with-xpm \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install -j$(nproc) \
        # Core extensions
        opcache \
        # Database
        pdo pdo_mysql pdo_pgsql pdo_sqlite mysqli \
        # String manipulation
        mbstring iconv \
        # Data formats
        xml xmlreader xmlwriter simplexml \
        # Web development
        curl \
        # File handling
        zip bz2 \
        # Image processing
        gd exif \
        # Internationalization
        intl gettext \
        # Math and crypto
        gmp bcmath \
        # System integration
        ldap \
        # Utilities
        tidy xsl calendar sockets \
        # IPC (Inter-Process Communication)
        sysvmsg sysvsem sysvshm

# Development tools (Composer, Xdebug, PHPUnit, etc.) managed by Homebrew
# This container focuses on runtime extensions only

# Optimize PHP for production
RUN { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=2'; \
        echo 'opcache.fast_shutdown=1'; \
        echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN chown -R www-data:www-data /var/www/html

# Simple entrypoint for production runtime
ENTRYPOINT ["php-fpm"]

WORKDIR /var/www/html
COPY ./${SOURCE_DIR} /var/www/html

RUN chown -R www-data:www-data /var/www/html