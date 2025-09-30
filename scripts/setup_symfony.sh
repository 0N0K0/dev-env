#!/bin/bash
# Script d'automatisation complète pour Symfony API
# Ce script installe Symfony avec Composer global et configure l'environnement

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Lire la configuration depuis .env
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ Fichier .env non trouvé${NC}"
    exit 1
fi

PROJECT_NAME=$(grep "^PROJECT_NAME=" .env | cut -d'=' -f2)
USE_API_PLATFORM=$(grep "^USE_API_PLATFORM=" .env | cut -d'=' -f2 2>/dev/null || echo "false")
USE_GRAPHQL=$(grep "^USE_GRAPHQL=" .env | cut -d'=' -f2 2>/dev/null || echo "false")

echo -e "${BLUE}🚀 Installation automatique Symfony: $PROJECT_NAME${NC}"

# Installer Symfony CLI uniquement si nécessaire
echo -e "\n${YELLOW}🔧 Vérification de Symfony CLI...${NC}"
if ! command -v symfony &> /dev/null; then
    echo -e "${CYAN}Installation de Symfony CLI...${NC}"
    brew install symfony-cli/tap/symfony-cli
    echo -e "${GREEN}✅ Symfony CLI installé${NC}"
else
    echo -e "${GREEN}✅ Symfony CLI déjà disponible${NC}"
fi

# Nettoyer les anciens dossiers api/ et app/
if [ -d "api" ]; then
    sudo rm -rf "api" 2>/dev/null || rm -rf "api" 2>/dev/null || true
    echo "   🗑️  Dossier api/ supprimé"
fi

if [ -d "app" ]; then
    sudo rm -rf "app" 2>/dev/null || rm -rf "app" 2>/dev/null || true
    echo "   🗑️  Dossier app/ supprimé"
fi

# Créer le projet Symfony avec Composer global
echo -e "\n${YELLOW}🎼 Installation de Symfony avec Composer...${NC}"
composer create-project symfony/skeleton ./api --no-interaction
echo -e "${GREEN}✅ Projet Symfony créé${NC}"

# Installer les dépendances de base
echo -e "\n${YELLOW}📚 Installation des dépendances Symfony...${NC}"

# API de base
echo -e "${CYAN}- Installation du pack API...${NC}"
composer require api --no-interaction

# Doctrine ORM
echo -e "${CYAN}- Installation de Doctrine ORM...${NC}"
composer require doctrine --no-interaction

# API Platform si demandé
if [ "$USE_API_PLATFORM" = "true" ]; then
    echo -e "${CYAN}- Installation d'API Platform...${NC}"
    composer require api-platform/api-pack --no-interaction
fi

# GraphQL si demandé
if [ "$USE_GRAPHQL" = "true" ]; then
    echo -e "${CYAN}- Installation de GraphQL...${NC}"
    composer require webonyx/graphql-php-bundle --no-interaction
fi

# Outils de développement
echo -e "\n${YELLOW}🔧 Installation des outils de développement...${NC}"
composer require --dev symfony/maker-bundle --no-interaction
composer require --dev doctrine/doctrine-fixtures-bundle --no-interaction
composer require --dev symfony/profiler-pack --no-interaction

# Configuration de l'environnement
echo -e "\n${YELLOW}⚙️  Configuration de l'environnement...${NC}"

# Créer le fichier .env.local
DB_TYPE=$(grep "^DB_TYPE=" .env | cut -d'=' -f2)
DB_PORT=$(grep "^DB_PORT=" ../.env | cut -d'=' -f2)
DB_USER=$(grep "^DB_USER=" ../.env | cut -d'=' -f2)
DB_PASSWORD=$(grep "^DB_PASSWORD=" ../.env | cut -d'=' -f2)
DB_NAME=$(grep "^DB_NAME=" ../.env | cut -d'=' -f2)
DB_VERSION=$(grep "^DB_VERSION=" ../.env | cut -d'=' -f2)

cat > .env.local << EOF
# Configuration automatique pour Docker
DATABASE_URL="${DB_TYPE}://${DB_USER}:${DB_PASSWORD}@${DB_TYPE}:${DB_PORT}/${DB_NAME}?serverVersion=${DB_VERSION}&charset=utf8"
EOF

echo -e "${GREEN}✅ Fichier .env.local créé${NC}"

# Revenir au dossier racine
cd ..

# Informations finales
echo -e "\n${GREEN}🎉 Installation Symfony terminée avec succès !${NC}"
echo -e "\n${PURPLE}📋 Informations du projet :${NC}"
echo -e "  ${CYAN}Nom:${NC} $PROJECT_NAME"
echo -e "  ${CYAN}Type:${NC} API Symfony"
echo -e "  ${CYAN}API Platform:${NC} $USE_API_PLATFORM"
echo -e "  ${CYAN}GraphQL:${NC} $USE_GRAPHQL"
echo -e "\n${PURPLE}🗄️  Base de données :${NC}"
echo -e "  ${CYAN}Type:${NC} $DB_TYPE"
echo -e "  ${CYAN}Version:${NC} $DB_VERSION"
echo -e "  ${CYAN}Hôte:${NC} localhost"
echo -e "  ${CYAN}Port:${NC} $DB_PORT"
echo -e "  ${CYAN}Utilisateur:${NC} $DB_USER"
echo -e "  ${CYAN}Nom de la base:${NC} $DB_NAME"

echo -e "\n${YELLOW}🚀 Votre API Symfony est prête ! Commencez à développer :${NC}"
echo -e "1. ${CYAN}Créer vos entités :${NC} make exec SERVICE=api-php CMD=\"php bin/console make:entity\""
echo -e "2. ${CYAN}Générer des migrations :${NC} make exec SERVICE=api-php CMD=\"php bin/console make:migration\""
echo -e "3. ${CYAN}Appliquer les migrations :${NC} make exec SERVICE=api-php CMD=\"php bin/console doctrine:migrations:migrate\""
echo -e "4. ${CYAN}Accéder à votre API :${NC} http://localhost"
echo -e "5. ${CYAN}Shell interactif :${NC} make exec SERVICE=api-php CMD=\"bash\""

if [ "$USE_API_PLATFORM" = "true" ]; then
    echo -e "6. ${CYAN}Interface API Platform :${NC} http://localhost/api"
fi

echo -e "\n${GREEN}✨ Votre environnement Symfony est prêt !${NC}"