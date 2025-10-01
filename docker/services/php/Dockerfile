ARG PHP_VERSION=8.4
ARG SOURCE_DIR=api
FROM php:${PHP_VERSION}-fpm

# Installer toutes les dépendances système pour les extensions PHP
RUN apt-get update && apt-get install -y \
    # Bibliothèques de base
    libonig-dev libxml2-dev libpq-dev libsqlite3-dev \
    # Traitement d'images
    libpng-dev libjpeg-dev libfreetype6-dev libwebp-dev libxpm-dev \
    libmagickwand-dev libavif-dev \
    # Archive et compression
    libzip-dev libbz2-dev libzstd-dev liblzf-dev \
    # Réseautage et protocoles
    libcurl4-openssl-dev libssl-dev libssh2-1-dev \
    # Internationalisation et encodage
    libicu-dev libiconv-hook-dev libonig-dev \
    # Pilotes de base de données
    libmemcached-dev libmongoc-1.0-0 libmongoc-dev \
    # Intégration système
    libffi-dev libkrb5-dev libldap2-dev libsasl2-dev \
    # Mathématiques et sciences
    libgmp-dev \
    # Utilitaires supplémentaires
    libtidy-dev libxslt1-dev libedit-dev \
    # Outils de construction
    build-essential pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Installer les extensions PECL (non incluses)
RUN pecl install \
    redis \
    imagick \
    mongodb \
    memcached \
    ssh2 \
    && docker-php-ext-enable redis imagick mongodb memcached ssh2

# Configurer et installer TOUTES les extensions PHP stables
RUN docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
        --with-webp \
        --with-xpm \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install -j$(nproc) \
        # Extensions de performance
        opcache \
        # Bases de données
        pdo pdo_mysql pdo_pgsql pdo_sqlite mysqli \
        # Manipulation de chaînes
        mbstring iconv \
        # Formats de données
        xml xmlreader xmlwriter simplexml \
        # Développement web
        curl \
        # Gestion des fichiers
        zip bz2 \
        # Traitement d'images
        gd exif \
        # Internationalisation
        intl gettext \
        # Mathématiques et crypto
        gmp bcmath \
        # Intégration système
        ldap \
        # Utilitaires supplémentaires
        tidy xsl calendar sockets \
        # IPC (Inter-Process Communication)
        sysvmsg sysvsem sysvshm

# Créer un php.ini personnalisé dans /var/www
COPY docker/services/php/php.ini /var/www/php.ini

# Lier le php.ini personnalisé
RUN ln -sf /var/www/php.ini /usr/local/etc/php/php.ini

# Point d'entrée flexible pour le développement
CMD ["php-fpm"]

WORKDIR /var/www/html
COPY ./${SOURCE_DIR} /var/www/html

# Ajuster les permissions après la copie
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html