#!/bin/bash
# Script de configuration interactif pour l'environnement de développement
# Usage: ./configure.sh

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Fonction pour afficher un titre
print_title() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🚀 $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Fonction pour afficher les options
print_options() {
    local title="$1"
    shift
    echo -e "\n${YELLOW}$title :${NC}"
    local i=1
    for option in "$@"; do
        echo -e "  ${CYAN}$i)${NC} $option"
        ((i++))
    done
}

# Fonction pour demander un choix
ask_choice() {
    local prompt="$1"
    local default_index="$2"  # Index par défaut (1-based)
    shift 2
    local options=("$@")
    
    # Si pas de défaut fourni, utiliser 1
    if [ -z "$default_index" ]; then
        default_index=1
    fi
    
    while true; do
        print_options "$prompt" "${options[@]}" >&2
        echo -e "\n${GREEN}Choix [1-${#options[@]}] (défaut: $default_index - ${options[$((default_index-1))]}): ${NC}" >&2
        read -r choice
        
        # Utiliser la valeur par défaut si aucune saisie
        if [ -z "$choice" ]; then
            choice="$default_index"
        fi
        
        # Vérifier que le choix est valide
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
            local selected="${options[$((choice-1))]}"
            echo -e "${GREEN}✅ Sélectionné: $selected${NC}" >&2
            echo "" >&2  # Ligne vide pour séparer les sections
            echo "$selected"  # Retourner la valeur sélectionnée
            return 0
        else
            echo -e "${RED}❌ Choix invalide. Veuillez entrer un nombre entre 1 et ${#options[@]}.${NC}" >&2
        fi
    done
}

# Fonction pour demander oui/non
ask_yes_no() {
    local prompt="$1"
    local default="$2"
    
    while true; do
        if [ "$default" = "true" ]; then
            echo -e "\n${YELLOW}$prompt [o/n] (défaut: oui): ${NC}" >&2
        elif [ "$default" = "false" ]; then
            echo -e "\n${YELLOW}$prompt [o/n] (défaut: non): ${NC}" >&2
        else
            echo -e "\n${YELLOW}$prompt [o/n]: ${NC}" >&2
        fi
        
        read -r response
        
        # Utiliser la valeur par défaut si aucune saisie
        if [ -z "$response" ] && [ -n "$default" ]; then
            if [ "$default" = "true" ]; then
                echo -e "${GREEN}✅ Sélectionné: oui${NC}" >&2
                echo "" >&2
                echo "true"
                return
            else
                echo -e "${GREEN}✅ Sélectionné: non${NC}" >&2
                echo "" >&2
                echo "false"
                return
            fi
        fi
        
        case "$response" in
            [oO]|[oO][uU][iI]|true|TRUE|yes|YES|y|Y)
                echo -e "${GREEN}✅ Sélectionné: oui${NC}" >&2
                echo "" >&2
                echo "true"
                return
                ;;
            [nN]|[nN][oO][nN]|false|FALSE|no|NO|n|N)
                echo -e "${GREEN}✅ Sélectionné: non${NC}" >&2
                echo "" >&2
                echo "false"
                return
                ;;
            *)
                echo -e "${RED}❌ Veuillez répondre par 'o' (oui) ou 'n' (non).${NC}" >&2
                ;;
        esac
    done
}

# Fonction pour demander une version ou un nom
ask_version() {
    local prompt="$1"
    local default="$2"
    
    while true; do
        echo -e "\n${YELLOW}$prompt (défaut: $default): ${NC}" >&2
        read -r version
        
        if [ -z "$version" ]; then
            version="$default"
        fi
        
        # Validation pour le nom de projet (pas d'espaces, caractères spéciaux limités)
        if [[ "$prompt" =~ "projet" ]] && ! [[ "$version" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            echo -e "${RED}❌ Le nom du projet ne doit contenir que des lettres, chiffres, tirets et underscores.${NC}" >&2
            continue
        fi
        
        echo -e "${GREEN}✅ $(echo "$prompt" | sed 's/ (défaut: .*//'): $version${NC}" >&2
        echo "" >&2  # Ligne vide pour séparer les sections
        echo "$version"  # Retourner la valeur
        break
    done
}

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

# 1. Nom du projet
selected_project_name=$(ask_version "Nom du projet" "$current_project_name")

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

selected_backend_version=$(ask_version "Version du backend $selected_backend" "$default_version")

# 4. Base de données
db_options=("postgres" "mysql")
selected_db=$(ask_choice "Base de données" "1" "${db_options[@]}")

# 5. Version de la base de données
selected_db_version=$(ask_version "Version de la base de données $selected_db" "$current_db_version")

# 6. Serveur web
webserver_options=("apache" "nginx")
selected_webserver=$(ask_choice "Serveur web" "1" "${webserver_options[@]}")

# 7. Mailpit
selected_mailpit=$(ask_yes_no "Activer Mailpit (serveur de mail de développement)" "true")

# 8. WebSocket
selected_websocket=$(ask_yes_no "Activer WebSocket" "false")

# 9. Type de WebSocket (si activé)
if [ "$selected_websocket" = "true" ]; then
    websocket_type_options=("socketio" "native")
    selected_websocket_type=$(ask_choice "Type de WebSocket" "1" "${websocket_type_options[@]}")
else
    selected_websocket_type="$current_websocket_type"
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
echo -e "   ${YELLOW}WebSocket:${NC} ${GREEN}$selected_websocket${NC}"
if [ "$selected_websocket" = "true" ]; then
    echo -e "   ${YELLOW}WebSocket Type:${NC} ${GREEN}$selected_websocket_type${NC}"
fi

echo -e "\n${YELLOW}Voulez-vous appliquer cette configuration ? [o/N]: ${NC}"
read -r confirm

if [[ "$confirm" =~ ^[oO]|[oO][uU][iI]|yes|YES|y|Y$ ]]; then
    echo -e "\n${GREEN}🚀 Application de la configuration...${NC}"
    
    # Appeler make switch avec les paramètres sélectionnés
    make switch \
        PROJECT_NAME="$selected_project_name" \
        TYPE="$selected_type" \
        BACKEND="$selected_backend" \
        BACKEND_VERSION="$selected_backend_version" \
        DB="$selected_db" \
        DB_VERSION="$selected_db_version" \
        WEBSERVER="$selected_webserver" \
        MAILPIT="$selected_mailpit" \
        WEBSOCKET="$selected_websocket" \
        WEBSOCKET_TYPE="$selected_websocket_type"
    
    echo -e "\n${GREEN}🎉 Configuration appliquée avec succès !${NC}"
    echo -e "${CYAN}💡 Utilisez 'make build && make start' pour construire et démarrer les services.${NC}"
else
    echo -e "\n${YELLOW}⏸️  Configuration annulée.${NC}"
    exit 0
fi