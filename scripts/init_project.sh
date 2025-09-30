#!/bin/bash
# Script d'initialisation du projet
# Usage: ./init_project.sh

set -e

# Charger les fonctions utilitaires communes
if [ -f "scripts/utils.sh" ]; then
    source scripts/utils.sh
else
    echo "❌ Fichier utils.sh non trouvé"
    exit 1
fi

# Charger les presets s'ils sont disponibles
if [ -f "scripts/init_presets.sh" ]; then
    source scripts/init_presets.sh
fi

# Fonction pour appliquer la configuration
apply_configuration() {
    local project_name="$1"
    local type="$2"
    local backend="$3"
    local backend_version="$4"
    local db="$5"
    local db_version="$6"
    local webserver="$7"
    local mailpit="$8"
    local websocket="$9"
    local websocket_type="${10}"

    echo -e "${CYAN}🔍 Vérification de l'état des conteneurs...${NC}"
    
    # Arrêter les conteneurs s'ils tournent
    if [ -f ".env" ] && docker compose --env-file .env -f docker/docker-compose.yml ps -q 2>/dev/null | grep -q .; then
        echo -e "${YELLOW}⏹️  Arrêt des conteneurs en cours d'exécution...${NC}"
        cd docker && docker compose --env-file ../.env down -v
        cd ..
        echo -e "${GREEN}✅ Conteneurs arrêtés${NC}"
    else
        echo -e "${GREEN}✅ Aucun conteneur en cours d'exécution${NC}"
    fi

    echo -e "\n${CYAN}📝 Mise à jour du fichier .env...${NC}"
    
    # Mettre à jour le fichier .env
    sed -i.bak "s|^PROJECT_NAME=.*|PROJECT_NAME=$project_name|" .env
    sed -i.bak "s|^DB_NAME=.*|DB_NAME=$project_name|" .env
    sed -i.bak "s|^TYPE=.*|TYPE=$type|" .env
    sed -i.bak "s|^BACKEND=.*|BACKEND=$backend|" .env
    sed -i.bak "s|^BACKEND_VERSION=.*|BACKEND_VERSION=$backend_version|" .env
    sed -i.bak "s|^DB_TYPE=.*|DB_TYPE=$db|" .env
    sed -i.bak "s|^DB_VERSION=.*|DB_VERSION=$db_version|" .env
    sed -i.bak "s|^WEBSERVER=.*|WEBSERVER=$webserver|" .env
    sed -i.bak "s|^USE_MAILPIT=.*|USE_MAILPIT=$mailpit|" .env
    sed -i.bak "s|^USE_WEBSOCKET=.*|USE_WEBSOCKET=$websocket|" .env
    sed -i.bak "s|^WEBSOCKET_TYPE=.*|WEBSOCKET_TYPE=$websocket_type|" .env
    
    # Configurer les ports et chemins selon le type de DB
    case "$db" in
        mysql)
            sed -i.bak "s|^DB_PATH=.*|DB_PATH=/var/lib/mysql|" .env
            sed -i.bak "s|^DB_PORT=.*|DB_PORT=3306|" .env
            ;;
        postgres)
            sed -i.bak "s|^DB_PATH=.*|DB_PATH=/var/lib/postgresql/data|" .env
            sed -i.bak "s|^DB_PORT=.*|DB_PORT=5432|" .env
            ;;
    esac
    
    rm -f .env.bak
    echo -e "${GREEN}✅ Configuration mise à jour dans .env${NC}"

    echo -e "\n${CYAN}🔧 Génération du fichier d'application...${NC}"
    if [ -f "scripts/generate_files.sh" ]; then
        bash scripts/generate_files.sh "$backend" "$type"
    else
        echo -e "${YELLOW}⚠️  Script scripts/generate_files.sh non trouvé${NC}"
    fi

    echo -e "\n${CYAN}🔄 Génération des configurations dynamiques...${NC}"
    if [ -f "scripts/generate_compose.sh" ]; then
        bash scripts/generate_compose.sh
    else
        echo -e "${YELLOW}⚠️  Script scripts/generate_compose.sh non trouvé${NC}"
    fi
    
    if [ -f "scripts/generate_configs.sh" ]; then
        bash scripts/generate_configs.sh
    else
        echo -e "${YELLOW}⚠️  Script scripts/generate_configs.sh non trouvé${NC}"
    fi
    
    echo -e "${GREEN}✅ Docker Compose et configurations générés${NC}"

    echo -e "\n${CYAN}🍺 Installation des outils de développement...${NC}"
    if [ -f "scripts/install_dev_tools.sh" ]; then
        bash scripts/install_dev_tools.sh
    else
        echo -e "${YELLOW}⚠️  Script scripts/install_dev_tools.sh non trouvé${NC}"
    fi
}

# Menu principal unifié
main_menu() {
    print_title "Initialisation du Projet - Menu Principal"
    
    local project_type
    project_type=$(ask_choice "🎯 Type de projet" 1 \
        "Symfony API (API Platform + GraphQL optionnel)" \
        "WordPress Bedrock (Thème moderne optionnel)" \
        "Configuration manuelle (mode avancé)" \
        "Annuler")
    
    case "$project_type" in
        "Symfony API"*)
            echo -e "\n${GREEN}🎯 Configuration Symfony...${NC}"
            if command -v configure_symfony_preset > /dev/null 2>&1; then
                configure_symfony_preset
            else
                echo -e "${RED}❌ Preset Symfony non disponible${NC}"
                return 1
            fi
            ;;
        "WordPress Bedrock"*)
            echo -e "\n${GREEN}🎯 Configuration WordPress...${NC}"
            if command -v configure_wordpress_preset > /dev/null 2>&1; then
                configure_wordpress_preset
            else
                echo -e "${RED}❌ Preset WordPress non disponible${NC}"
                return 1
            fi
            ;;
        "Configuration manuelle"*)
            echo -e "\n${GREEN}⚙️ Configuration manuelle...${NC}"
            manual_configuration
            ;;
        "Annuler")
            echo -e "\n${YELLOW}❌ Initialisation annulée${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Option non reconnue${NC}"
            return 1
            ;;
    esac
}

# Configuration manuelle (l'ancien contenu du script)
manual_configuration() {

# Fonction pour lire la configuration actuelle
read_current_config() {
    if [ -f ".env" ]; then
        current_project_name=$(grep "^PROJECT_NAME=" .env 2>/dev/null | cut -d'=' -f2 || echo "dev-env")
        current_type=$(grep "^TYPE=" .env 2>/dev/null | cut -d'=' -f2 || echo "api")
        current_backend=$(grep "^BACKEND=" .env 2>/dev/null | cut -d'=' -f2 || echo "php")
        current_backend_version=$(grep "^BACKEND_VERSION=" .env 2>/dev/null | cut -d'=' -f2 || echo "latest")
        current_db=$(grep "^DB_TYPE=" .env 2>/dev/null | cut -d'=' -f2 || echo "postgres")
        current_db_version=$(grep "^DB_VERSION=" .env 2>/dev/null | cut -d'=' -f2 || echo "latest")
        current_webserver=$(grep "^WEBSERVER=" .env 2>/dev/null | cut -d'=' -f2 || echo "apache")
        current_mailpit=$(grep "^USE_MAILPIT=" .env 2>/dev/null | cut -d'=' -f2 || echo "true")
        current_websocket=$(grep "^USE_WEBSOCKET=" .env 2>/dev/null | cut -d'=' -f2 || echo "false")
        current_websocket_type=$(grep "^WEBSOCKET_TYPE=" .env 2>/dev/null | cut -d'=' -f2 || echo "socketio")
        
        echo -e "\n${PURPLE}📋 Configuration actuelle détectée :${NC}"
        echo -e "   Projet: ${CYAN}$current_project_name${NC}"
        echo -e "   Type: ${CYAN}$current_type${NC}"
        echo -e "   Backend: ${CYAN}$current_backend $current_backend_version${NC}"
        echo -e "   Base de données: ${CYAN}$current_db $current_db_version${NC}"
        echo -e "   Serveur web: ${CYAN}$current_webserver${NC}"
        echo -e "   Mailpit: ${CYAN}$current_mailpit${NC}"
        echo -e "   WebSocket: ${CYAN}$current_websocket${NC}"
        if [ "$current_websocket" = "true" ]; then
            echo -e "   WebSocket Type: ${CYAN}$current_websocket_type${NC}"
        fi
    else
        # Valeurs par défaut
        current_project_name="dev-env"
        current_type="api"
        current_backend="php"
        current_backend_version="8.4"
        current_db="postgres"
        current_db_version="latest"
        current_webserver="apache"
        current_mailpit="true"
        current_websocket="false"
        current_websocket_type="socketio"
        
        echo -e "\n${YELLOW}⚠️  Aucun fichier .env détecté, utilisation des valeurs par défaut${NC}"
    fi
}

# Début du script principal
clear
print_title "CONFIGURATION DE L'ENVIRONNEMENT DE DÉVELOPPEMENT"

echo -e "${GREEN}Bienvenue dans le configurateur interactif !${NC}"
echo -e "Ce script va vous guider pour configurer votre environnement de développement."


# Lire la configuration actuelle
read_current_config

echo -e "\n${CYAN}Appuyez sur Entrée pour utiliser la valeur par défaut ou saisissez votre choix.${NC}"

# 1. Nom du projet (avec validation automatique)
selected_project_name=$(ask_text "Nom du projet" "$current_project_name" true true)

# Validation supplémentaire pour les minuscules et tirets uniquement 
if [[ ! "$selected_project_name" =~ ^[a-z0-9-]+$ ]]; then
    echo -e "${RED}❌ Le nom de projet doit contenir uniquement des lettres minuscules, chiffres et tirets${NC}"
    exit 1
fi

# 2. Type d'application
type_options=("api" "app")
selected_type=$(ask_choice "Type d'application" "1" "${type_options[@]}")

# 2. Backend
backend_options=("php" "node" "python" "go")
selected_backend=$(ask_choice "Backend" "1" "${backend_options[@]}")

# 3. Version du backend
case "$selected_backend" in
    php)
        default_version="8.4"
        ;;
    node)
        default_version="latest"
        ;;
    python)
        default_version="latest"
        ;;
    go)
        default_version="latest"
        ;;
    *)
        default_version="latest"
        ;;
esac

if [ "$selected_backend" = "$current_backend" ]; then
    default_version="$current_backend_version"
fi

selected_backend_version=$(ask_text "Version du backend $selected_backend" "$default_version" false true)

# 4. Base de données
db_options=("postgres" "mysql")
selected_db=$(ask_choice "Base de données" "1" "${db_options[@]}")

# 5. Version de la base de données
selected_db_version=$(ask_text "Version de la base de données $selected_db" "$current_db_version" false true)

# 6. Serveur web
webserver_options=("apache" "nginx")
selected_webserver=$(ask_choice "Serveur web" "1" "${webserver_options[@]}")

# 7. Mailpit
selected_mailpit=$(ask_yes_no "Activer Mailpit (serveur de mail de développement)" "true")

# 8. WebSocket
websocket_choice=$(ask_choice "🔌 WebSocket" 3 "Mercure (native Symfony)" "Socket.IO" "Non")

# Configuration WebSocket selon le choix
if [ "$websocket_choice" = "Non" ]; then
    selected_websocket="false"
    selected_websocket_type="none"
else
    selected_websocket="true"
    if [ "$websocket_choice" = "Mercure (native Symfony)" ]; then
        selected_websocket_type="mercure"
    else
        selected_websocket_type="socketio"
    fi
fi

# Récapitulatif
print_title "RÉCAPITULATIF DE LA CONFIGURATION"

echo -e "${PURPLE}📋 Configuration sélectionnée :${NC}"
echo -e "   ${YELLOW}Projet:${NC} ${GREEN}$selected_project_name${NC}"
echo -e "   ${YELLOW}Type:${NC} ${GREEN}$selected_type${NC}"
echo -e "   ${YELLOW}Backend:${NC} ${GREEN}$selected_backend $selected_backend_version${NC}"
echo -e "   ${YELLOW}Base de données:${NC} ${GREEN}$selected_db $selected_db_version${NC}"
echo -e "   ${YELLOW}Serveur web:${NC} ${GREEN}$selected_webserver${NC}"
echo -e "   ${YELLOW}Mailpit:${NC} ${GREEN}$selected_mailpit${NC}"
if [ "$selected_websocket" = "true" ]; then
    echo -e "   ${YELLOW}WebSocket:${NC} ${GREEN}$websocket_choice${NC}"
else
    echo -e "   ${YELLOW}WebSocket:${NC} ${GREEN}Non${NC}"
fi

confirm=$(ask_yes_no "Voulez-vous appliquer cette configuration ?" "true")

if [ "$confirm" = "true" ]; then
    echo -e "\n${GREEN}🚀 Application de la configuration...${NC}"
    apply_configuration "$selected_project_name" "$selected_type" "$selected_backend" "$selected_backend_version" "$selected_db" "$selected_db_version" "$selected_webserver" "$selected_mailpit" "$selected_websocket" "$selected_websocket_type"
    
    echo -e "\n${GREEN}🎉 Configuration appliquée avec succès !${NC}"
    echo -e "${CYAN}💡 Utilisez 'make build && make start' pour construire et démarrer les services.${NC}"
else
    echo -e "\n${YELLOW}⏸️  Configuration annulée.${NC}"
    exit 0
fi
}

# Point d'entrée principal
main() {
    # S'assurer que le fichier .env existe
    if [ ! -f ".env" ]; then
        echo -e "${YELLOW}🔧 Initialisation du fichier .env...${NC}"
        bash scripts/init_env.sh
    fi
    
    # Lancer le menu principal
    main_menu
}

# Exécuter le script principal
main