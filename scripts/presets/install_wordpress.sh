#!/bin/bash
# Script d'installation de WordPress via WP-CLI
# À exécuter après le build et le start des conteneurs

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}🚀 Installation de WordPress via WP-CLI${NC}"

# Vérifier que le fichier .env existe
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ Fichier .env non trouvé${NC}"
    exit 1
fi

# Lire la configuration depuis .env
PROJECT_NAME=$(grep "^PROJECT_NAME=" .env | cut -d'=' -f2)
CREATE_CUSTOM_THEME=$(grep "^CREATE_CUSTOM_THEME=" .env | cut -d'=' -f2 2>/dev/null || echo "false")
USE_CUSTOM_BLOCKS=$(grep "^USE_CUSTOM_BLOCKS=" .env | cut -d'=' -f2 2>/dev/null || echo "false")
WP_ADMIN_USER=$(grep "^WP_ADMIN_USER=" .env | cut -d'=' -f2 2>/dev/null || echo "admin")
WP_ADMIN_PASSWORD=$(grep "^WP_ADMIN_PASSWORD=" .env | cut -d'=' -f2 2>/dev/null || echo "root")
WP_ADMIN_EMAIL=$(grep "^WP_ADMIN_EMAIL=" .env | cut -d'=' -f2 2>/dev/null || echo "admin@example.com")
WP_SITE_URL=$(grep "^WP_SITE_URL=" .env | cut -d'=' -f2 2>/dev/null || echo "http://localhost")

echo -e "\n${CYAN}📋 Configuration d'administration WordPress :${NC}"
echo -e "  ${CYAN}Titre du site :${NC} $PROJECT_NAME"
echo -e "  ${CYAN}URL du site :${NC} $WP_SITE_URL"
echo -e "  ${CYAN}Utilisateur admin :${NC} $WP_ADMIN_USER"
echo -e "  ${CYAN}Email admin :${NC} $WP_ADMIN_EMAIL"

# Lire les informations de DB pour WP-CLI local
DB_TYPE=$(grep "^DB_TYPE=" .env | cut -d'=' -f2)
TYPE=$(grep "^TYPE=" .env | cut -d'=' -f2 2>/dev/null || echo "app")
BACKEND=$(grep "^BACKEND=" .env | cut -d'=' -f2 2>/dev/null || echo "php")
WEBSERVER=$(grep "^WEBSERVER=" .env | cut -d'=' -f2 2>/dev/null || echo "apache")

# Construire les noms de services selon la convention
BACKEND_SERVICE="${TYPE}-${BACKEND}"     # app-php
DB_SERVICE="${DB_TYPE}"                  # postgres ou mysql
WEB_SERVICE="${WEBSERVER}"               # apache ou nginx

# Vérifier que les conteneurs sont démarrés
echo -e "\n${YELLOW}🔍 Vérification des conteneurs...${NC}"
if ! docker ps --format "table {{.Names}}" | grep -q "${PROJECT_NAME}-${BACKEND_SERVICE}"; then
    echo -e "${RED}❌ Les conteneurs ne semblent pas démarrés${NC}"
    echo -e "${YELLOW}💡 Lancez d'abord : make build && make start${NC}"
    echo -e "${CYAN}Conteneur attendu : ${PROJECT_NAME}-${BACKEND_SERVICE}${NC}"
    exit 1
fi
DB_NAME=$(grep "^DB_NAME=" .env | cut -d'=' -f2)
DB_USER=$(grep "^DB_USER=" .env | cut -d'=' -f2)
DB_PASSWORD=$(grep "^DB_PASSWORD=" .env | cut -d'=' -f2)
DB_PORT=$(grep "^DB_PORT=" .env | cut -d'=' -f2)

# Attendre que les services soient prêts
echo -e "\n${YELLOW}⏳ Attente que les services soient prêts...${NC}"

# Fonction pour attendre la base de données
wait_for_database() {
    local max_attempts=60
    local attempt=1
    
    echo -e "${CYAN}🔍 Vérification de la connexion à la base de données...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        # Vérifier d'abord que le port est ouvert
        if ! nc -z localhost ${DB_PORT} 2>/dev/null; then
            echo -e "${CYAN}   Tentative $attempt/$max_attempts - Port ${DB_PORT} non accessible...${NC}"
            sleep 2
            ((attempt++))
            continue
        fi
        
        # Vérifier que la base de données accepte les connexions
        local db_ready=false
        
        if [ "$DB_TYPE" = "mysql" ]; then
            # Test de connexion MySQL/MariaDB
            if docker exec "${PROJECT_NAME}-${DB_TYPE}" mysql -u"$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1; then
                db_ready=true
            fi
        elif [ "$DB_TYPE" = "postgres" ]; then
            # Test de connexion PostgreSQL
            if docker exec "${PROJECT_NAME}-${DB_TYPE}" pg_isready -h localhost -p 5432 >/dev/null 2>&1 && \
               docker exec "${PROJECT_NAME}-${DB_TYPE}" psql -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" >/dev/null 2>&1; then
                db_ready=true
            fi
        fi
        
        if [ "$db_ready" = true ]; then
            echo -e "${GREEN}✅ Base de données prête et accessible${NC}"
            return 0
        fi
        
        echo -e "${CYAN}   Tentative $attempt/$max_attempts - Base de données pas encore prête...${NC}"
        sleep 2
        ((attempt++))
    done
    
    echo -e "${RED}❌ Impossible de se connecter à la base de données après ${max_attempts} tentatives${NC}"
    echo -e "${YELLOW}💡 Vérifiez les logs: docker-compose logs ${DB_TYPE}${NC}"
    return 1
}

# Fonction pour attendre PHP-FPM
wait_for_php_fpm() {
    local max_attempts=30
    local attempt=1
    
    echo -e "${CYAN}🔍 Vérification du service PHP-FPM...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        # Vérifier que le conteneur PHP répond
        if docker exec "${PROJECT_NAME}-${BACKEND_SERVICE}" php -v >/dev/null 2>&1; then
            # Vérifier que PHP peut se connecter à la base de données
            local php_test_cmd=""
            if [ "$DB_TYPE" = "mysql" ]; then
                php_test_cmd="php -r \"try { new PDO('mysql:host=${DB_TYPE};port=3306;dbname=${DB_NAME}', '${DB_USER}', '${DB_PASSWORD}'); echo 'OK'; } catch(Exception \$e) { echo 'ERROR'; }\""
            elif [ "$DB_TYPE" = "postgres" ]; then
                php_test_cmd="php -r \"try { new PDO('pgsql:host=${DB_TYPE};port=5432;dbname=${DB_NAME}', '${DB_USER}', '${DB_PASSWORD}'); echo 'OK'; } catch(Exception \$e) { echo 'ERROR'; }\""
            fi
            
            if [ -n "$php_test_cmd" ]; then
                local db_test_result=$(docker exec "${PROJECT_NAME}-${BACKEND_SERVICE}" sh -c "$php_test_cmd" 2>/dev/null)
                if [ "$db_test_result" = "OK" ]; then
                    echo -e "${GREEN}✅ PHP-FPM prêt et connecté à la base de données${NC}"
                    return 0
                else
                    echo -e "${CYAN}   Tentative $attempt/$max_attempts - PHP prêt mais base de données non accessible...${NC}"
                fi
            else
                echo -e "${GREEN}✅ PHP-FPM prêt${NC}"
                return 0
            fi
        else
            echo -e "${CYAN}   Tentative $attempt/$max_attempts - Attente de PHP-FPM...${NC}"
        fi
        
        sleep 2
        ((attempt++))
    done
    
    echo -e "${RED}❌ PHP-FPM non accessible après ${max_attempts} tentatives${NC}"
    echo -e "${YELLOW}💡 Vérifiez les logs: docker-compose logs ${BACKEND_SERVICE}${NC}"
    return 1
}

# Fonction pour attendre le serveur web
wait_for_webserver() {
    local max_attempts=20
    local attempt=1
    
    echo -e "${CYAN}🔍 Vérification du serveur web...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        # Test d'accès HTTP simple
        if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200\|404\|403"; then
            echo -e "${GREEN}✅ Serveur web accessible${NC}"
            return 0
        fi
        
        echo -e "${CYAN}   Tentative $attempt/$max_attempts - Attente du serveur web...${NC}"
        sleep 2
        ((attempt++))
    done
    
    echo -e "${RED}❌ Serveur web non accessible après ${max_attempts} tentatives${NC}"
    echo -e "${YELLOW}💡 Vérifiez les logs: docker-compose logs ${WEB_SERVICE}${NC}"
    return 1
}

# Attendre les services
echo -e "${YELLOW}🔄 Vérification séquentielle des services...${NC}"

if ! wait_for_database; then
    echo -e "${RED}❌ Échec de l'attente de la base de données${NC}"
    show_diagnostic_info
    exit 1
fi

if ! wait_for_php_fpm; then
    echo -e "${RED}❌ Échec de l'attente de PHP-FPM${NC}"
    show_diagnostic_info
    exit 1
fi

if ! wait_for_webserver; then
    echo -e "${RED}❌ Échec de l'attente du serveur web${NC}"
    show_diagnostic_info
    exit 1
fi

# Vérification finale de WP-CLI
echo -e "${CYAN}🔍 Vérification de WP-CLI...${NC}"
if ! command -v wp &> /dev/null; then
    echo -e "${RED}❌ WP-CLI non disponible${NC}"
    echo -e "${YELLOW}💡 Installez WP-CLI: brew install wp-cli${NC}"
    exit 1
fi

# Test de WP-CLI dans le conteneur
if ! docker exec "${PROJECT_NAME}-${BACKEND_SERVICE}" php -r "echo 'PHP OK';" >/dev/null 2>&1; then
    echo -e "${RED}❌ PHP non accessible dans le conteneur${NC}"
    exit 1
fi

echo -e "${GREEN}🎉 Tous les services sont prêts !${NC}"

# Fonction de diagnostic en cas d'échec
show_diagnostic_info() {
    echo -e "\n${YELLOW}🔍 Informations de diagnostic :${NC}"
    echo -e "${CYAN}État des conteneurs :${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo -e "\n${CYAN}Logs récents de la base de données :${NC}"
    docker-compose logs --tail=10 ${DB_TYPE} 2>/dev/null || echo "Aucun log de DB disponible"
    
    echo -e "\n${CYAN}Logs récents de PHP :${NC}"
    docker-compose logs --tail=10 ${BACKEND_SERVICE} 2>/dev/null || echo "Aucun log PHP disponible"
    
    echo -e "\n${CYAN}Logs récents du serveur web :${NC}"
    docker-compose logs --tail=10 ${WEB_SERVICE} 2>/dev/null || echo "Aucun log web disponible"
    
    echo -e "\n${YELLOW}💡 Solutions possibles :${NC}"
    echo -e "1. Attendre quelques minutes et relancer"
    echo -e "2. Vérifier les logs complets: docker-compose logs"
    echo -e "3. Redémarrer les services: make stop && make start"
    echo -e "4. Reconstruire si nécessaire: make clean && make build"
}

# Configuration temporaire pour WP-CLI local
echo -e "\n${YELLOW}🔧 Configuration temporaire pour WP-CLI local...${NC}"
cat > app/.env.local << EOF
# Configuration temporaire pour WP-CLI local
DB_HOST=127.0.0.1:${DB_PORT}
EOF

# Vérifier si WordPress est déjà installé  
echo -e "\n${YELLOW}🔍 Vérification de l'installation WordPress...${NC}"
if wp core is-installed --path=./app/web/wp > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  WordPress semble déjà installé${NC}"
    read -p "Voulez-vous réinstaller WordPress ? (y/N) " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}💡 Installation annulée${NC}"
        # Nettoyer le fichier temporaire
        rm -f app/.env.local
        exit 0
    fi
fi

# Installer WordPress avec la configuration temporaire
echo -e "\n${YELLOW}📚 Installation de WordPress...${NC}"
wp core install \
    --path=./app/web/wp \
    --url="$WP_SITE_URL" \
    --title="$PROJECT_NAME" \
    --admin_user="$WP_ADMIN_USER" \
    --admin_password="$WP_ADMIN_PASSWORD" \
    --admin_email="$WP_ADMIN_EMAIL"

# Activer le thème personnalisé si il existe
THEME_NAME="${PROJECT_NAME}-theme"
if wp theme list --format=csv --path=./app/web/wp | grep -q "$THEME_NAME"; then
    echo -e "\n${YELLOW}🎨 Activation du thème personnalisé...${NC}"
    wp theme activate "$THEME_NAME" --path=./app/web/wp
    echo -e "${GREEN}✅ Thème '$THEME_NAME' activé${NC}"
fi

# Informations finales
echo -e "\n${GREEN}🦆 Installation WordPress terminée avec succès !${NC}"
echo -e "\n${PURPLE}🔑 Informations de connexion :${NC}"
echo -e "  ${CYAN}URL du site :${NC} $WP_SITE_URL"
echo -e "  ${CYAN}URL Admin :${NC} $WP_SITE_URL/wp/wp-admin"
echo -e "  ${CYAN}Utilisateur :${NC} $WP_ADMIN_USER"
echo -e "  ${CYAN}Mot de passe :${NC} $WP_ADMIN_PASSWORD"
echo -e "  ${CYAN}Email :${NC} $WP_ADMIN_EMAIL"

echo -e "\n${YELLOW}🚀 Prochaines étapes :${NC}"
echo -e "1. ${CYAN}Accéder au site :${NC} http://localhost"
echo -e "2. ${CYAN}Accéder à l'admin :${NC} http://localhost/wp/wp-admin"
if [ "$CREATE_CUSTOM_THEME" = "true" ]; then
    echo -e "3. ${CYAN}Personnaliser le thème :${NC} app/web/app/themes/${PROJECT_NAME}-theme/"
fi
if [ "$USE_CUSTOM_BLOCKS" = "true" ]; then
    echo -e "4. ${CYAN}Développer avec Vite :${NC} cd app/web/app/themes/${PROJECT_NAME}-theme && npm run dev"
fi

# Nettoyer le fichier de configuration temporaire
echo -e "\n${CYAN}🧹 Nettoyage des fichiers temporaires...${NC}"
rm -f app/.env.local
echo -e "${GREEN}✅ Configuration temporaire supprimée${NC}"