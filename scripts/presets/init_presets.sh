#!/bin/bash
# Configuration des presets pour différents types de projets

# Charger les fonctions utilitaires communes
if [ -f "scripts/utils.sh" ]; then
    source scripts/utils.sh
else
    echo "❌ Fichier utils.sh non trouvé"
    exit 1
fi

# Fonction pour les questions communes
ask_common_questions() {
    local project_type="$1"  # "symfony" ou "wordpress"
    local default_name="$2"
    
    # Nom du projet
    PROJECT_NAME=$(ask_text "📝 Nom du projet" "$default_name" true true)
        
    # Version PHP
    PHP_VERSION=$(ask_choice "🐘 Version de PHP" 2 "8.1" "8.2" "8.3" "8.4")
    
    # Serveur web
    WEBSERVER=$(ask_choice "🌐 Serveur web" 1 "nginx" "apache")
    
    # Base de données (ordre différent selon le type)
    if [ "$project_type" = "wordpress" ]; then
        # MySQL en premier pour WordPress (recommandé)
        DB_TYPE=$(ask_choice "🗄️  Base de données" 1 "mysql" "postgres")
    else
        # Postgres en premier pour Symfony
        DB_TYPE=$(ask_choice "🗄️  Base de données" 1 "postgres" "mysql")
    fi
    
    # Mailpit
    USE_MAILPIT=$(ask_choice "📧 Mailpit (serveur email de test)" 1 "Oui" "Non")
}

# Fonction pour configurer un preset Symfony API
configure_symfony_preset() {
    print_title "Configuration de Symfony API"
    
    # Questions communes
    ask_common_questions "symfony" "symfony-api"
    
    # Questions spécifiques à Symfony
    USE_API_PLATFORM=$(ask_choice "📡 Installer API Platform" 1 "Oui" "Non")
    
    # GraphQL (seulement si API Platform)
    if [ "$USE_API_PLATFORM" = "Oui" ]; then
        USE_GRAPHQL=$(ask_choice "🕸️  Ajouter GraphQL" 1 "Oui" "Non")
    else
        USE_GRAPHQL="Non"
    fi
    
    # WebSocket
    WEBSOCKET_CHOICE=$(ask_choice "🔌 WebSocket" 3 "Mercure" "Socket.IO" "Non")
    
    # Configuration WebSocket selon le choix
    if [ "$WEBSOCKET_CHOICE" = "Non" ]; then
        USE_WEBSOCKET="Non"
        WEBSOCKET_TYPE="none"
    else
        USE_WEBSOCKET="Oui"
        if [ "$WEBSOCKET_CHOICE" = "Mercure" ]; then
            WEBSOCKET_TYPE="mercure"
        else
            WEBSOCKET_TYPE="socketio"
        fi
    fi
    
    # Appliquer la configuration
    apply_symfony_config
}

# Fonction pour configurer un preset WordPress
configure_wordpress_preset() {
    print_title "Configuration du preset WordPress avec Bedrock"
    
    # Questions communes
    ask_common_questions "wordpress" "wordpress-bedrock"
    
    # Questions spécifiques à WordPress
    CREATE_CUSTOM_THEME=$(ask_choice "🎨 Créer un thème personnalisé avec blocks" 1 "Oui" "Non")
    if [ "$CREATE_CUSTOM_THEME" = "Oui" ]; then
        USE_CUSTOM_BLOCKS=$(ask_choice "⚡ Créer des blocks personnalisés (React + Vite + TypeScript)" 1 "Oui" "Non")
    else
        USE_CUSTOM_BLOCKS="Non"
    fi
    
    # WordPress n'utilise pas de WebSocket
    USE_WEBSOCKET="Non"
    WEBSOCKET_TYPE="none"
    
    # Appliquer la configuration
    apply_wordpress_config
}

# Fonction pour appliquer la configuration Symfony
apply_symfony_config() {
    echo -e "\n${PURPLE}📋 Récapitulatif de la configuration Symfony :${NC}"
    echo -e "  ${CYAN}Projet:${NC} $PROJECT_NAME"
    echo -e "  ${CYAN}Type:${NC} API Symfony"
    echo -e "  ${CYAN}PHP:${NC} $PHP_VERSION"
    echo -e "  ${CYAN}Serveur web:${NC} $WEBSERVER"
    echo -e "  ${CYAN}Base de données:${NC} $DB_TYPE"
    echo -e "  ${CYAN}API Platform:${NC} $USE_API_PLATFORM"
    [ "$USE_API_PLATFORM" = "Oui" ] && echo -e "  ${CYAN}GraphQL:${NC} $USE_GRAPHQL"
    echo -e "  ${CYAN}Mailpit:${NC} $USE_MAILPIT"
    if [ "$USE_WEBSOCKET" = "Oui" ]; then
        echo -e "  ${CYAN}WebSocket:${NC} $WEBSOCKET_CHOICE"
    else
        echo -e "  ${CYAN}WebSocket:${NC} Non"
    fi
    
    confirm=$(ask_yes_no "Continuer avec cette configuration ?" "true")
    if [ "$confirm" != "true" ]; then
        echo -e "${YELLOW}Configuration annulée${NC}"
        exit 0
    fi
    
    # Écrire les variables dans .env
    write_symfony_env
    
    # Créer le projet Symfony
    create_symfony_project
}

# Fonction pour appliquer la configuration WordPress
apply_wordpress_config() {
    echo -e "\n${PURPLE}📋 Récapitulatif de la configuration WordPress :${NC}"
    echo -e "  ${CYAN}Projet:${NC} $PROJECT_NAME"
    echo -e "  ${CYAN}Type:${NC} WordPress + Bedrock"
    echo -e "  ${CYAN}PHP:${NC} $PHP_VERSION"
    echo -e "  ${CYAN}Serveur web:${NC} $WEBSERVER"
    echo -e "  ${CYAN}Base de données:${NC} $DB_TYPE"
    echo -e "  ${CYAN}Thème personnalisé:${NC} $CREATE_CUSTOM_THEME"
    [ "$CREATE_CUSTOM_THEME" = "Oui" ] && echo -e "  ${CYAN}Build moderne:${NC} $USE_CUSTOM_BLOCKS"
    echo -e "  ${CYAN}Mailpit:${NC} $USE_MAILPIT"
    
    confirm=$(ask_yes_no "Continuer avec cette configuration ?" "true")
    if [ "$confirm" != "true" ]; then
        echo -e "${YELLOW}Configuration annulée${NC}"
        exit 0
    fi
    
    # Écrire les variables dans .env
    write_wordpress_env
    
    # Créer le projet WordPress
    create_wordpress_project
}

# Fonction commune pour écrire la configuration de base dans .env
write_common_env_config() {
    local project_type="$1"  # "api" ou "app"
    
    # Réinitialiser .env depuis le template pour avoir une base propre
    if [ -f "scripts/files_handlers/init_env.sh" ]; then
        rm -f .env
        bash scripts/files_handlers/init_env.sh
    else
        echo -e "${RED}❌ Impossible d'initialiser .env${NC}"
        exit 1
    fi
    
    # Configuration de base commune
    sed -i.bak "s|^PROJECT_NAME=.*|PROJECT_NAME=$PROJECT_NAME|" .env
    sed -i.bak "s|^TYPE=.*|TYPE=$project_type|" .env
    sed -i.bak "s|^BACKEND=.*|BACKEND=php|" .env
    sed -i.bak "s|^BACKEND_VERSION=.*|BACKEND_VERSION=$PHP_VERSION|" .env
    sed -i.bak "s|^WEBSERVER=.*|WEBSERVER=$WEBSERVER|" .env
    sed -i.bak "s|^DB_TYPE=.*|DB_TYPE=$DB_TYPE|" .env
    sed -i.bak "s|^DB_NAME=.*|DB_NAME=$PROJECT_NAME|" .env
    
    # Configuration spécifique à la base de données choisie
    if [ "$DB_TYPE" = "postgres" ]; then
        sed -i.bak "s|^DB_PATH=.*|DB_PATH=/var/lib/postgresql/data|" .env
        sed -i.bak "s|^DB_PORT=.*|DB_PORT=5432|" .env
    elif [ "$DB_TYPE" = "mysql" ]; then
        sed -i.bak "s|^DB_PATH=.*|DB_PATH=/var/lib/mysql|" .env
        sed -i.bak "s|^DB_PORT=.*|DB_PORT=3306|" .env
    fi
    
    # Mailpit
    if [ "$USE_MAILPIT" = "Oui" ]; then
        sed -i.bak "s|^USE_MAILPIT=.*|USE_MAILPIT=true|" .env
    else
        sed -i.bak "s|^USE_MAILPIT=.*|USE_MAILPIT=false|" .env
    fi
    
    # WebSocket
    if [ "$USE_WEBSOCKET" = "Oui" ]; then
        sed -i.bak "s|^USE_WEBSOCKET=.*|USE_WEBSOCKET=true|" .env
        # Configurer le type de WebSocket si défini
        if [ -n "$WEBSOCKET_TYPE" ]; then
            sed -i.bak "s|^WEBSOCKET_TYPE=.*|WEBSOCKET_TYPE=$WEBSOCKET_TYPE|" .env
        fi
    else
        sed -i.bak "s|^USE_WEBSOCKET=.*|USE_WEBSOCKET=false|" .env
    fi
    
    # Nettoyer les fichiers de sauvegarde
    rm -f .env.bak
}

# Fonction pour écrire la configuration Symfony dans .env
write_symfony_env() {
    # Configuration commune
    write_common_env_config "api"
    
    # Variables spécifiques à Symfony
    echo "" >> .env
    echo "# Configuration Symfony" >> .env
    echo "SYMFONY_PROJECT=true" >> .env
    echo "USE_API_PLATFORM=$([ "$USE_API_PLATFORM" = "Oui" ] && echo "true" || echo "false")" >> .env
    echo "USE_GRAPHQL=$([ "$USE_GRAPHQL" = "Oui" ] && echo "true" || echo "false")" >> .env
        
    echo -e "${GREEN}✅ Configuration sauvegardée dans .env${NC}"
}

# Fonction pour écrire la configuration WordPress dans .env
write_wordpress_env() {
    # Configuration commune
    write_common_env_config "app"
    
    # Variables spécifiques à WordPress
    echo "" >> .env
    echo "# Configuration WordPress" >> .env
    echo "WORDPRESS_PROJECT=true" >> .env
    echo "USE_BEDROCK=true" >> .env
    echo "CREATE_CUSTOM_THEME=$([ "$CREATE_CUSTOM_THEME" = "Oui" ] && echo "true" || echo "false")" >> .env
    echo "USE_CUSTOM_BLOCKS=$([ "$USE_CUSTOM_BLOCKS" = "Oui" ] && echo "true" || echo "false")" >> .env

    echo "" >> .env
    echo "# Configuration d'administration WordPress" >> .env
    echo " WP_ADMIN_USER=admin" >> .env
    echo "WP_ADMIN_PASSWORD=root" >> .env
    echo "WP_ADMIN_EMAIL=admin@example.com" >> .env
    echo "WP_SITE_URL=http://localhost" >> .env
    
    echo -e "${GREEN}✅ Configuration sauvegardée dans .env${NC}"
}

create_common_project() {
    echo -e "\n${BLUE}🔧 Génération des configurations...${NC}"
    
    # Générer les configurations Docker
    if [ -f "scripts/files_handlers/generate_compose.sh" ]; then
        bash scripts/files_handlers/generate_compose.sh
    fi
    
    if [ -f "scripts/files_handlers/generate_configs.sh" ]; then
        bash scripts/files_handlers/generate_configs.sh
    fi

    if [ -f "scripts/files_handlers/install_dev_tools.sh" ]; then
        bash scripts/files_handlers/install_dev_tools.sh
    else
        echo -e "${YELLOW}⚠️  Script scripts/files_handlers/install_dev_tools.sh non trouvé${NC}"
    fi

    echo -e "\n${GREEN}Lancement de l'installation automatique complète...${NC}"
    echo -e "${CYAN}Cette installation va :${NC}"
    }

# Fonction pour créer le projet Symfony
create_symfony_project() {
    create_common_project
    
    echo -e "  • Installer Symfony CLI"
    echo -e "  • Installer Symfony avec toutes les dépendances"
    echo -e "  • Configurer la base de données"
    [ "$USE_API_PLATFORM" = "Oui" ] && echo -e "  • Installer API Platform"
    [ "$USE_GRAPHQL" = "Oui" ] && echo -e "  • Installer GraphQL"
    
    echo -e "\n${YELLOW}⏳ Cela peut prendre quelques minutes...${NC}"
    
    # Lancer le script d'automatisation
    if [ -f "scripts/presets/setup_symfony.sh" ]; then
        bash scripts/presets/setup_symfony.sh
    else
        echo -e "${RED}❌ Script scripts/presets/setup_symfony.sh non trouvé${NC}"
        exit 1
    fi
}

# Fonction pour créer le projet WordPress
create_wordpress_project() {
    create_common_project

    echo -e "  • Installer WP-CLI"
    echo -e "  • Installer WordPress Bedrock"
    echo -e "  • Configurer la base de données"
    [ "$CREATE_CUSTOM_THEME" = "Oui" ] && echo -e "  • Créer un thème personnalisé"
    [ "$USE_CUSTOM_BLOCKS" = "Oui" ] && echo -e "  • Configurer React + Vite + TypeScript"
    
    echo -e "\n${YELLOW}⏳ Cela peut prendre quelques minutes...${NC}"
    
    # Lancer le script d'automatisation
    if [ -f "scripts/presets/setup_wordpress.sh" ]; then
        bash scripts/presets/setup_wordpress.sh
    else
        echo -e "${RED}❌ Script scripts/presets/setup_wordpress.sh non trouvé${NC}"
        exit 1
    fi
}

# Export des fonctions pour utilisation dans d'autres scripts
export -f configure_symfony_preset configure_wordpress_preset