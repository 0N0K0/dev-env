ARG PHP_VERSION=8.4
ARG SOURCE_DIR=api
ARG DB_TYPE=postgres
ARG USE_MONGODB=false
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
    libmemcached-dev \
    # Intégration système
    libffi-dev libkrb5-dev libldap2-dev libsasl2-dev \
    # Mathématiques et sciences
    libgmp-dev \
    # Utilitaires supplémentaires
    libtidy-dev libxslt1-dev libedit-dev \
    # Outils de construction
    build-essential pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Installer les dépendances MongoDB
RUN if [ "$USE_MONGODB" = "true" ]; then \
        apt-get update && apt-get install -y libmongoc-1.0-0 libmongoc-dev && \
        rm -rf /var/lib/apt/lists/*; \
    fi

# Installer les extensions PECL
RUN pecl install \
    redis \
    imagick \
    memcached \
    ssh2 \
    && docker-php-ext-enable redis imagick memcached ssh2

# Installer MongoDB
RUN if [ "$USE_MONGODB" = "true" ]; then \
        pecl install mongodb && \
        docker-php-ext-enable mongodb; \
    fi

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
        # Base de données (PDO toujours installé)
        pdo \
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

# Installer les extensions de base de données selon le type de DB
RUN if [ "$DB_TYPE" = "mysql" ]; then \
        docker-php-ext-install pdo_mysql mysqli; \
    elif [ "$DB_TYPE" = "postgres" ]; then \
        docker-php-ext-install pdo_pgsql; \
    else \
        docker-php-ext-install pdo_mysql pdo_pgsql pdo_sqlite mysqli; \
    fi

# Créer un php.ini personnalisé dans /var/www
COPY docker/services/php/php.ini /var/www/php.ini

# Lier le php.ini personnalisé
RUN ln -sf /var/www/php.ini /usr/local/etc/php/php.ini

# Point d'entrée flexible pour le développement
CMD ["php-fpm"]

WORKDIR /var/www/html
COPY ./${SOURCE_DIR} /var/www/html

# Ajuster les permissions après la copie
RUN chown -R www-data:www-data /var/www/html