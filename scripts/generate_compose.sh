#!/bin/bash
# Script de génération dynamique du docker-compose.yml
# Usage: ./generate_compose.sh

set -e

echo "🐳 Génération du docker-compose.yml dynamique..."

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
PROJECT_NAME=$(grep "^PROJECT_NAME=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
TYPE=$(grep "^TYPE=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
BACKEND=$(grep "^BACKEND=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
BACKEND_VERSION=$(grep "^BACKEND_VERSION=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
WEBSERVER=$(grep "^WEBSERVER=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
DB_TYPE=$(grep "^DB_TYPE=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
DB_VERSION=$(grep "^DB_VERSION=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
DB_NAME=$(grep "^DB_NAME=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
DB_USER=$(grep "^DB_USER=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
DB_PASSWORD=$(grep "^DB_PASSWORD=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
DB_PATH=$(grep "^DB_PATH=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
DB_PORT=$(grep "^DB_PORT=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
USE_MAILPIT=$(grep "^USE_MAILPIT=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
USE_WEBSOCKET=$(grep "^USE_WEBSOCKET=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
WEBSOCKET_TYPE=$(grep "^WEBSOCKET_TYPE=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')

# Noms des services dynamiques
WEB_SERVICE="$WEBSERVER"                    # nginx ou apache
BACKEND_SERVICE="$TYPE-$BACKEND"           # api-php, app-nodejs, etc.
DB_SERVICE="$DB_TYPE"                      # postgres ou mysql

echo "   📋 Configuration détectée :"
echo "   • Web: $WEB_SERVICE"
echo "   • Backend: $BACKEND_SERVICE"  
echo "   • Database: $DB_SERVICE"
echo "   • Network: $PROJECT_NAME"

# Créer le dossier docker s'il n'existe pas
mkdir -p docker

# Générer le docker-compose.yml principal
cat > "docker/docker-compose.yml" << EOF
# Docker Compose généré dynamiquement - NE PAS MODIFIER MANUELLEMENT
# Utilisez 'make switch' pour regénérer ce fichier

name: $PROJECT_NAME

networks:
  $PROJECT_NAME:
    driver: bridge

services:
    # Service Web ($WEBSERVER)
    $WEB_SERVICE:
        container_name: $PROJECT_NAME-$WEB_SERVICE
        build:
            context: ..
            dockerfile: ./docker/services/\${WEBSERVER}/Dockerfile
        volumes:
            - ../\${TYPE}:/var/www/html
        ports:
            - "80:80"
        depends_on:
            - $BACKEND_SERVICE
        networks:
            - $PROJECT_NAME

    # Service Backend ($TYPE-$BACKEND)
    $BACKEND_SERVICE:
        container_name: $PROJECT_NAME-$BACKEND_SERVICE
        build:
            context: ..
            dockerfile: ./docker/services/\${BACKEND}/Dockerfile
            args:
                PHP_VERSION: \${BACKEND_VERSION}
                SOURCE_DIR: \${TYPE}
        volumes:
            - ../\${TYPE}:/var/www/html
        networks:
            - $PROJECT_NAME

    # Service Database ($DB_TYPE)
    $DB_SERVICE:
        container_name: $PROJECT_NAME-$DB_SERVICE
        image: \${DB_TYPE}:\${DB_VERSION}
        environment:
EOF

# Configuration spécifique à la base de données
if [ "$DB_TYPE" = "postgres" ]; then
    cat >> "docker/docker-compose.yml" << EOF
            POSTGRES_DB: \${DB_NAME}
            POSTGRES_USER: \${DB_USER}
            POSTGRES_PASSWORD: \${DB_PASSWORD}
        volumes:
            - db-data:\${DB_PATH}
EOF
elif [ "$DB_TYPE" = "mysql" ]; then
    cat >> "docker/docker-compose.yml" << EOF
            MYSQL_DATABASE: \${DB_NAME}
            MYSQL_USER: \${DB_USER}
            MYSQL_PASSWORD: \${DB_PASSWORD}
            MYSQL_ROOT_PASSWORD: \${DB_PASSWORD}
        volumes:
            - db-data:\${DB_PATH}
EOF
fi

cat >> "docker/docker-compose.yml" << EOF
        ports:
            - "\${DB_PORT}:\${DB_PORT}"
        networks:
            - $PROJECT_NAME

volumes:
    db-data:
EOF

echo "   ✅ docker-compose.yml principal généré"

# Générer le fichier mailpit si nécessaire
if [ "$USE_MAILPIT" = "true" ]; then
    cat > "docker/docker-compose.mailpit.yml" << EOF
# Configuration Mailpit - Générée automatiquement

services:
    mailpit:
        container_name: $PROJECT_NAME-mailpit
        image: axllent/mailpit
        ports:
            - "1025:1025"  # SMTP
            - "8025:8025"  # Interface Web
        networks:
            - $PROJECT_NAME
EOF
    echo "   ✅ docker-compose.mailpit.yml généré"
fi

# Générer le fichier websocket si nécessaire  
if [ "$USE_WEBSOCKET" = "true" ]; then
    cat > "docker/docker-compose.websocket.yml" << EOF
# Configuration WebSocket ($WEBSOCKET_TYPE) - Générée automatiquement

services:
    websocket-$WEBSOCKET_TYPE:
        container_name: $PROJECT_NAME-websocket-$WEBSOCKET_TYPE
        build:
            context: ..
            dockerfile: ./docker/services/websocket/Dockerfile
        ports:
            - "3001:3001"
        volumes:
            - ./services/websocket:/app
        networks:
            - $PROJECT_NAME
        environment:
            - WEBSOCKET_TYPE=$WEBSOCKET_TYPE
EOF
    echo "   ✅ docker-compose.websocket.yml généré"
fi

echo "🎉 Génération du docker-compose.yml terminée !"
echo "   📁 Fichiers générés dans docker/"
echo "   🚀 Utilisez 'make build && make start' pour lancer les services"