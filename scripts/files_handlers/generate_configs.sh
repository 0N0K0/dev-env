#!/bin/bash
# Script de génération des configurations nginx/apache dynamiques
# Usage: ./generate_configs.sh

set -e

echo "⚙️  Génération des configurations serveur web..."

# Lire les variables de configuration depuis .env
if [ -f ".env" ]; then
    ENV_FILE=".env"
elif [ -f "../.env" ]; then
    ENV_FILE="../.env"
else
    echo "❌ Fichier .env non trouvé"
    exit 1
fi

# Variables de configuration
TYPE=$(grep "^TYPE=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
BACKEND=$(grep "^BACKEND=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
WEBSERVER=$(grep "^WEBSERVER=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
WORDPRESS_PROJECT=$(grep "^WORDPRESS_PROJECT=" "$ENV_FILE" | cut -d'=' -f2 2>/dev/null | tr -d '\n\r')

# Noms des services dynamiques
BACKEND_SERVICE="$TYPE-$BACKEND"

# Document root selon le type de projet
if [ "$WORDPRESS_PROJECT" = "true" ]; then
    DOCUMENT_ROOT="/var/www/html/web"  # Bedrock structure
else
    DOCUMENT_ROOT="/var/www/html"      # Standard structure
fi

echo "   📋 Configuration pour $WEBSERVER → $BACKEND_SERVICE"

if [ "$WEBSERVER" = "nginx" ]; then
    if [ "$BACKEND" = "php" ]; then
        # Configuration Nginx + PHP-FPM
        cat > "docker/services/nginx/nginx.conf" << EOF
# Configuration nginx pour backend $BACKEND_SERVICE généré automatiquement

server {
    listen 80;
    server_name localhost;
    root $DOCUMENT_ROOT;
    index index.php index.html index.htm;

    # Gérer les fichiers PHP avec PHP-FPM
    location ~ \.php\$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass $BACKEND_SERVICE:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
    }

    # Gérer les fichiers statiques
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    # Sécurité : bloquer les fichiers sensibles (base)
    location ~ /\.ht {
        deny all;
    }
    
    location ~ /\.env.* {
        deny all;
    }
EOF

        # Règles spécifiques à PHP/Composer
        if [ "$BACKEND" = "php" ]; then
            cat >> "docker/services/nginx/nginx.conf" << EOF
    
    # Sécurité PHP : fichiers de configuration
    location ~ /(composer\.json|composer\.lock) {
        deny all;
    }
EOF
        fi

        # Règles spécifiques à WordPress
        if [ "$WORDPRESS_PROJECT" = "true" ]; then
            cat >> "docker/services/nginx/nginx.conf" << EOF
    
    # Sécurité WordPress
    location ~ /(wp-config\.php|wp-config-sample\.php) {
        deny all;
    }
    
    location ~ /wp-content/uploads/.*\.php$ {
        deny all;
    }
    
    location ~ ^/wp-admin/includes/ {
        deny all;
    }
EOF
        fi

        # Optimisation des assets statiques (toujours utile)
        cat >> "docker/services/nginx/nginx.conf" << EOF
    
    # Cache des assets statiques
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|webp|avif)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Vary Accept-Encoding;
    }
EOF

        # Cache HTML seulement pour les apps web (pas APIs)
        if [ "$TYPE" = "app" ] || [ "$WORDPRESS_PROJECT" = "true" ]; then
            cat >> "docker/services/nginx/nginx.conf" << EOF
    
    # Cache pour les pages web
    location ~* \.(html|htm)$ {
        expires 1h;
        add_header Cache-Control "public";
    }
EOF
        fi

        # Cache XML/TXT seulement si pas API pure
        if [ "$TYPE" != "api" ] || [ "$WORDPRESS_PROJECT" = "true" ]; then
            cat >> "docker/services/nginx/nginx.conf" << EOF
    
    # Cache pour les métadonnées
    location ~* \.(xml|txt|json)$ {
        expires 1h;
        add_header Cache-Control "public";
    }
EOF
        fi

        # En-têtes de sécurité de base
        cat >> "docker/services/nginx/nginx.conf" << EOF

    # En-têtes de sécurité de base
    add_header X-Content-Type-Options "nosniff" always;
EOF

        # En-têtes spécifiques aux apps web/WordPress (pas APIs)
        if [ "$TYPE" = "app" ] || [ "$WORDPRESS_PROJECT" = "true" ]; then
            cat >> "docker/services/nginx/nginx.conf" << EOF
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;
EOF
        else
            # Pour les APIs, headers plus simples
            cat >> "docker/services/nginx/nginx.conf" << EOF
    add_header X-Frame-Options "DENY" always;
EOF
        fi

        cat >> "docker/services/nginx/nginx.conf" << EOF
    
    # Limite de taille des uploads (64MB)
    client_max_body_size 64M;

    # Logs
    error_log /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
}
EOF
    else
        # Configuration Nginx + Proxy vers Node.js/Python/Go
        cat > "docker/services/nginx/nginx.conf" << EOF
# Configuration nginx pour backend $BACKEND_SERVICE généré automatiquement

server {
    listen 80;
    server_name localhost;

    # Proxy vers le backend $BACKEND_SERVICE
    location / {
        proxy_pass http://$BACKEND_SERVICE:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # En-têtes de sécurité de base
    add_header X-Content-Type-Options "nosniff" always;
EOF

        # En-têtes spécifiques selon le type de projet
        if [ "$TYPE" = "app" ] || [ "$WORDPRESS_PROJECT" = "true" ]; then
            cat >> "docker/services/nginx/nginx.conf" << EOF
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;
EOF
        else
            # Pour les APIs, headers plus simples
            cat >> "docker/services/nginx/nginx.conf" << EOF
    add_header X-Frame-Options "DENY" always;
EOF
        fi

        cat >> "docker/services/nginx/nginx.conf" << EOF

    # Logs
    error_log /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
}
EOF
    fi
    echo "   ✅ Configuration nginx générée pour $BACKEND_SERVICE"

elif [ "$WEBSERVER" = "apache" ]; then
    # Configuration Apache
    cat > "docker/services/apache/vhost.conf" << EOF
# Configuration Apache pour backend $BACKEND_SERVICE généré automatiquement

<VirtualHost *:80>
    ServerName localhost
    DocumentRoot $DOCUMENT_ROOT

    # Permissions pour le répertoire
    <Directory $DOCUMENT_ROOT>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
        DirectoryIndex index.php index.html index.htm
    </Directory>

EOF

    if [ "$BACKEND" = "php" ]; then
        cat >> "docker/services/apache/vhost.conf" << EOF
    # Configuration PHP
    <FilesMatch \.php\$>
        SetHandler "proxy:fcgi://$BACKEND_SERVICE:9000"
    </FilesMatch>
EOF
    else
        cat >> "docker/services/apache/vhost.conf" << EOF
    # Proxy vers $BACKEND_SERVICE
    ProxyPreserveHost On
    ProxyPass / http://$BACKEND_SERVICE:80/
    ProxyPassReverse / http://$BACKEND_SERVICE:80/
EOF
    fi

    cat >> "docker/services/apache/vhost.conf" << EOF

    # Sécurité : bloquer les fichiers sensibles (base)
    <Files ".ht*">
        Require all denied
    </Files>
    
    <Files ".env*">
        Require all denied
    </Files>
EOF

    # Règles spécifiques à PHP/Composer
    if [ "$BACKEND" = "php" ]; then
        cat >> "docker/services/apache/vhost.conf" << EOF
    
    # Sécurité PHP : fichiers de configuration
    <Files "composer.json">
        Require all denied
    </Files>
    
    <Files "composer.lock">
        Require all denied
    </Files>
EOF
    fi

    # Règles spécifiques à WordPress
    if [ "$WORDPRESS_PROJECT" = "true" ]; then
        cat >> "docker/services/apache/vhost.conf" << EOF
    
    # Sécurité WordPress
    <Files "wp-config.php">
        Require all denied
    </Files>
    
    <Files "wp-config-sample.php">
        Require all denied
    </Files>
    
    # Bloquer l'exécution PHP dans uploads
    <Directory "$DOCUMENT_ROOT/wp-content/uploads">
        <Files "*.php">
            Require all denied
        </Files>
    </Directory>
    
    # Bloquer l'accès aux includes wp-admin
    <DirectoryMatch "wp-admin/includes">
        Require all denied
    </DirectoryMatch>
EOF
    fi

    # Optimisation des assets statiques (toujours utile)
    cat >> "docker/services/apache/vhost.conf" << EOF
    
    # Cache des assets statiques
    <LocationMatch "\.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|webp|avif)$">
        ExpiresActive On
        ExpiresDefault "access plus 1 year"
        Header append Cache-Control "public, immutable"
    </LocationMatch>
EOF

    # Cache HTML seulement pour les apps web (pas APIs)
    if [ "$TYPE" = "app" ] || [ "$WORDPRESS_PROJECT" = "true" ]; then
        cat >> "docker/services/apache/vhost.conf" << EOF
    
    # Cache pour les pages web
    <LocationMatch "\.(html|htm)$">
        ExpiresActive On
        ExpiresDefault "access plus 1 hour"
        Header append Cache-Control "public"
    </LocationMatch>
EOF
    fi

    # Cache XML/TXT seulement si pas API pure
    if [ "$TYPE" != "api" ] || [ "$WORDPRESS_PROJECT" = "true" ]; then
        cat >> "docker/services/apache/vhost.conf" << EOF
    
    # Cache pour les métadonnées
    <LocationMatch "\.(xml|txt|json)$">
        ExpiresActive On
        ExpiresDefault "access plus 1 hour"
        Header append Cache-Control "public"
    </LocationMatch>
EOF
    fi

    cat >> "docker/services/apache/vhost.conf" << EOF

    # En-têtes de sécurité de base
    Header always set X-Content-Type-Options "nosniff"
EOF

    # En-têtes spécifiques aux apps web/WordPress (pas APIs)
    if [ "$TYPE" = "app" ] || [ "$WORDPRESS_PROJECT" = "true" ]; then
        cat >> "docker/services/apache/vhost.conf" << EOF
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    Header always set Permissions-Policy "camera=(), microphone=(), geolocation=()"
EOF
    else
        # Pour les APIs, headers plus simples
        cat >> "docker/services/apache/vhost.conf" << EOF
    Header always set X-Frame-Options "DENY"
EOF
    fi

    cat >> "docker/services/apache/vhost.conf" << EOF
    
    # Configuration pour le développement
    LogLevel info
    
    # Support des uploads de fichiers volumineux (64MB)
    LimitRequestBody 67108864

    # Logs
    ErrorLog /usr/local/apache2/logs/error.log
    CustomLog /usr/local/apache2/logs/access.log combined
</VirtualHost>
EOF
    echo "   ✅ Configuration apache générée pour $BACKEND_SERVICE"
fi

echo "🦆 Configuration serveur web générée !"