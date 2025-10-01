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

# Vérifier que les conteneurs sont démarrés
echo -e "\n${YELLOW}🔍 Vérification des conteneurs...${NC}"
if ! docker ps --format "table {{.Names}}" | grep -q "app-php"; then
    echo -e "${RED}❌ Les conteneurs ne semblent pas démarrés${NC}"
    echo -e "${YELLOW}💡 Lancez d'abord : make build && make start${NC}"
    exit 1
fi

# Lire les informations de DB pour WP-CLI local
DB_TYPE=$(grep "^DB_TYPE=" .env | cut -d'=' -f2)
DB_NAME=$(grep "^DB_NAME=" .env | cut -d'=' -f2)
DB_USER=$(grep "^DB_USER=" .env | cut -d'=' -f2)
DB_PASSWORD=$(grep "^DB_PASSWORD=" .env | cut -d'=' -f2)
DB_PORT=$(grep "^DB_PORT=" .env | cut -d'=' -f2)

# Configuration temporaire pour WP-CLI local
echo -e "\n${YELLOW}🔧 Configuration temporaire pour WP-CLI local...${NC}"

# Vérifier si WordPress est déjà installé  
echo -e "\n${YELLOW}🔍 Vérification de l'installation WordPress...${NC}"
if wp core is-installed --path=./app/web/wp > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  WordPress semble déjà installé${NC}"
    read -p "Voulez-vous réinstaller WordPress ? (y/N) " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}💡 Installation annulée${NC}"
        # Nettoyer le fichier temporaire
        rm -f app/wp-config-cli.php
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