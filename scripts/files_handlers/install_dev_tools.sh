#!/bin/bash
# Script d'installation des outils de développement via Homebrew
# Usage: ./install_dev_tools.sh

set -e

# Charger les fonctions utilitaires communes
if [ -f "scripts/utils.sh" ]; then
    source scripts/utils.sh
else
    echo "❌ Fichier utils.sh non trouvé"
    exit 1
fi

print_title "🍺 Installation des outils de développement via Homebrew"

# Lecture de la configuration depuis .env
ENV_FILE=".env"
if [ ! -f "$ENV_FILE" ]; then
    ENV_FILE="../.env"
    if [ ! -f "$ENV_FILE" ]; then
        echo "❌ Fichier .env introuvable. Lancez d'abord 'make init-project'"
        exit 1
    fi
fi

BACKEND=$(grep "^BACKEND=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
TYPE=$(grep "^TYPE=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
WEBSERVER=$(grep "^WEBSERVER=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
USE_WEBSOCKET=$(grep "^USE_WEBSOCKET=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
WEBSOCKET_TYPE=$(grep "^WEBSOCKET_TYPE=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')

echo "📋 Configuration détectée :"
echo "   Backend: $BACKEND"
echo "   Type: $TYPE"  
echo "   Serveur web: $WEBSERVER"
if [ "$USE_WEBSOCKET" = "true" ]; then
    echo "   WebSocket: $WEBSOCKET_TYPE"
else
    echo "   WebSocket: désactivé"
fi
echo ""

# Vérification de Homebrew
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew n'est pas installé. Installation en cours..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "✅ Homebrew déjà disponible"
fi

# Mise à jour de Homebrew
echo "🔄 Mise à jour de Homebrew..."
brew update

# Fonction d'installation avec vérification
install_if_missing() {
    local tool=$1
    local install_cmd=$2
    
    if command -v "$tool" &> /dev/null; then
        echo "✅ $tool déjà disponible"
    else
        echo "📦 Installation de $tool..."
        eval "$install_cmd"
    fi
}

# Outils génériques (toujours installés)
echo "🔧 Installation des outils génériques..."
install_if_missing "git" "brew install git"
install_if_missing "curl" "brew install curl"
install_if_missing "tree" "brew install tree"
install_if_missing "jq" "brew install jq"
install_if_missing "httpie" "brew install httpie"
install_if_missing "node" "brew install node"
install_if_missing "nvm" "brew install nvm"
install_if_missing "docker" "brew install --cask docker"

# Installation sélective selon le backend
case "$BACKEND" in
    php)
        echo "🐘 Installation des outils PHP..."
        install_if_missing "php" "brew install php"
        install_if_missing "composer" "brew install composer"
        install_if_missing "php-cs-fixer" "brew install php-cs-fixer"
                
        # Outils Composer globaux
        if command -v composer &> /dev/null; then
            echo "📦 Installation des packages Composer..."
            composer global show phpunit/phpunit &> /dev/null || composer global require phpunit/phpunit
            composer global show phpstan/phpstan &> /dev/null || composer global require phpstan/phpstan
        fi
        ;;
        
    node)
        echo "🟢 Installation des outils Node.js..."
        install_if_missing "node" "brew install node"
        install_if_missing "nvm" "brew install nvm"
        
        # Outils npm globaux
        if command -v npm &> /dev/null; then
            echo "📦 Installation des outils npm..."
            npm list -g typescript &> /dev/null || npm install -g typescript
            npm list -g eslint &> /dev/null || npm install -g eslint
            npm list -g prettier &> /dev/null || npm install -g prettier
            npm list -g nodemon &> /dev/null || npm install -g nodemon
            npm list -g @vue/cli &> /dev/null || npm install -g @vue/cli
        fi
        ;;
        
    python)
        echo "🐍 Installation des outils Python..."
        install_if_missing "python3" "brew install python"
        install_if_missing "pyenv" "brew install pyenv"
        install_if_missing "pipenv" "brew install pipenv"
        install_if_missing "poetry" "brew install poetry"
        
        # Outils pip globaux
        if command -v pip3 &> /dev/null; then
            echo "📦 Installation des outils pip..."
            pip3 show black &> /dev/null || pip3 install black
            pip3 show flake8 &> /dev/null || pip3 install flake8
            pip3 show pytest &> /dev/null || pip3 install pytest
            pip3 show fastapi &> /dev/null || pip3 install fastapi
            pip3 show uvicorn &> /dev/null || pip3 install uvicorn
        fi
        ;;
        
    go)
        echo "🔵 Installation des outils Go..."
        install_if_missing "go" "brew install go"
        
        # Outils Go
        if command -v go &> /dev/null; then
            echo "📦 Installation des outils Go additionnels..."
            if ! command -v goimports &> /dev/null; then
                go install golang.org/x/tools/cmd/goimports@latest
            fi
            if ! command -v golangci-lint &> /dev/null; then
                go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
            fi
        fi
        ;;
        
    *)
        echo "⚠️ Backend '$BACKEND' non reconnu."
        ;;
esac

# Installation des outils WebSocket si activés
if [ "$USE_WEBSOCKET" = "true" ] && [ "$WEBSOCKET_TYPE" = "socketio" ]; then
    echo "🔌 Installation des outils de WebSocket..."
    if command -v npm &> /dev/null; then
        echo "📦 Installation de Socket.IO..."
        npm list -g socket.io &> /dev/null || npm install -g socket.io
        echo "✅ Socket.IO installé"
    else
        echo "⚠️ npm non disponible, Socket.IO ne peut pas être installé"
    fi
fi

echo ""
echo "🦆 Installation terminée pour le backend $BACKEND !"
echo "=================================================="

# Résumé des outils installés selon le backend
case "$BACKEND" in
    php)
        if command -v php &> /dev/null; then
            echo "📋 Outils PHP installés :"
            echo "   🐘 PHP: $(php --version | head -n1)"
            echo "   📦 Composer: $(composer --version | head -n1)"
            command -v php-cs-fixer &> /dev/null && echo "   🔧 PHP-CS-Fixer: $(php-cs-fixer --version | head -n1)"
        fi
        ;;
    node)
        if command -v node &> /dev/null; then
            echo "📋 Outils Node.js installés :"
            echo "   🟢 Node.js: $(node --version)"
            echo "   📦 npm: $(npm --version)"
            command -v nvm &> /dev/null && echo "   🔄 nvm: installé"
        fi
        ;;
    python)
        if command -v python3 &> /dev/null; then
            echo "📋 Outils Python installés :"
            echo "   🐍 Python: $(python3 --version)"
            echo "   📦 pip: $(pip3 --version)"
            command -v poetry &> /dev/null && echo "   📦 Poetry: $(poetry --version)"
            command -v pyenv &> /dev/null && echo "   🔄 pyenv: installé"
        fi
        ;;
    go)
        if command -v go &> /dev/null; then
            echo "📋 Outils Go installés :"
            echo "   🔵 Go: $(go version)"
            command -v goimports &> /dev/null && echo "   🔧 goimports: installé"
            command -v golangci-lint &> /dev/null && echo "   🔍 golangci-lint: installé"
        fi
        ;;
esac

# Outils génériques
echo ""
echo "📋 Outils génériques :"
echo "   Docker: $(docker --version)"
echo "   git: $(git --version)"
echo "   httpie: $(http --version)"
echo "   curl: $(curl --version | head -n1)"
echo "   tree: $(tree --version | head -n1)"
echo "   jq: $(jq --version)"
if [ "$BACKEND" != "node" ]; then
    echo "   node: $(node --version)"
    echo "   npm: $(npm --version)"
    command -v nvm &> /dev/null && echo "   nvm: installé"
fi

echo ""
echo "Outils installés pour le backend '$BACKEND' !"
echo ""
echo "💡 Exemple d'utilisation :"

case "$BACKEND" in
    php)
        echo "   composer install                  # Installer les dépendances"
        echo "   composer require monolog/monolog  # Ajouter une dépendance"
        echo "   php-cs-fixer fix                  # Formater le code"
        ;;
    node)
        echo "   npm install                       # Installer les dépendances"
        echo "   npm run dev                       # Lancer en mode développement"
        echo "   eslint src/                       # Vérifier la syntaxe"
        ;;
    python)
        echo "   pip install -r requirements.txt  # Installer les dépendances"
        echo "   poetry install                    # Avec Poetry"
        echo "   black .                           # Formater le code"
        ;;
    go)
        echo "   go mod init myapp                 # Initialiser un module"
        echo "   go get github.com/gin-gonic/gin   # Ajouter une dépendance"
        echo "   goimports -w .                    # Formater le code"
        ;;
esac

echo ""
echo "🦆 Tous les outils de développement sont installés !"