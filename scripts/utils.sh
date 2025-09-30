#!/bin/bash
# Fonctions utilitaires communes pour les scripts

# Couleurs communes
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
            echo "" >&2
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

# Fonction pour demander du texte
ask_text() {
    local prompt="$1"
    local default="$2"
    local validate_project_name="${3:-false}"  # Paramètre optionnel pour valider les noms de projet
    local show_confirmation="${4:-false}"     # Paramètre optionnel pour afficher la confirmation
    local value
    
    while true; do
        if [ -n "$default" ]; then
            echo -e "\n${YELLOW}$prompt (défaut: $default): ${NC}" >&2
        else
            echo -e "\n${YELLOW}$prompt: ${NC}" >&2
        fi
        
        read -r value
        
        if [ -z "$value" ] && [ -n "$default" ]; then
            value="$default"
        fi
        
        # Validation pour le nom de projet si demandée
        if [ "$validate_project_name" = "true" ] && ! [[ "$value" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            echo -e "${RED}❌ Le nom du projet ne doit contenir que des lettres, chiffres, tirets et underscores.${NC}" >&2
            continue
        fi
        
        # Affichage de confirmation si demandé
        if [ "$show_confirmation" = "true" ]; then
            echo -e "${GREEN}✅ $(echo "$prompt" | sed 's/ (défaut: .*//'): $value${NC}" >&2
            echo "" >&2  # Ligne vide pour séparer les sections
        fi
        
        echo "$value"  # Retourner la valeur
        break
    done
}