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

# Noms des services dynamiques
BACKEND_SERVICE="$TYPE-$BACKEND"           # api-php, app-nodejs, etc.

echo "   📋 Configuration pour $WEBSERVER → $BACKEND_SERVICE"

# Créer le dossier de configuration dans docker/services
mkdir -p "docker/services/$WEBSERVER"

if [ "$WEBSERVER" = "nginx" ]; then
    if [ "$BACKEND" = "php" ]; then
        # Configuration Nginx + PHP-FPM
        cat > "docker/services/nginx/nginx.conf" << EOF
# Configuration nginx pour backend $BACKEND_SERVICE - Généré automatiquement

server {
    listen 80;
    server_name localhost;
    root /var/www/html;
    index index.php index.html index.htm;

    # Handle PHP files with PHP-FPM
    location ~ \.php\$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass $BACKEND_SERVICE:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
    }

    # Handle static files
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;

    # Logs
    error_log /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
}
EOF
    else
        # Configuration Nginx + Proxy vers Node.js/Python/Go
        cat > "docker/services/nginx/nginx.conf" << EOF
# Configuration nginx pour backend $BACKEND_SERVICE - Généré automatiquement

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

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;

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
# Configuration Apache pour backend $BACKEND_SERVICE - Généré automatiquement

<VirtualHost *:80>
    ServerName localhost
    DocumentRoot /var/www/html

    # Permissions pour le répertoire
    <Directory /var/www/html>
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

    # Logs (chemins corrects pour l'image httpd officielle)
    ErrorLog /usr/local/apache2/logs/error.log
    CustomLog /usr/local/apache2/logs/access.log combined

    # Security headers
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"
</VirtualHost>
EOF
    echo "   ✅ Configuration apache générée pour $BACKEND_SERVICE"
fi

echo "🎉 Configuration serveur web générée !"