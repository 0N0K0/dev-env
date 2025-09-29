#!/bin/bash
# Script d'installation des outils de développement via Homebrew
# Installation sélective selon le backend configuré dans .env

set -e

echo "🍺 Installation des outils de développement via Homebrew"
echo "=================================================="

# Lecture de la configuration depuis .env
if [ ! -f "../.env" ]; then
    echo "❌ Fichier .env introuvable. Lancez d'abord 'make switch BACKEND=<backend>'"
    exit 1
fi

BACKEND=$(grep "^BACKEND=" ../.env | cut -d'=' -f2 | tr -d '\n\r')
TYPE=$(grep "^TYPE=" ../.env | cut -d'=' -f2 | tr -d '\n\r')
WEBSERVER=$(grep "^WEBSERVER=" ../.env | cut -d'=' -f2 | tr -d '\n\r')
USE_WEBSOCKET=$(grep "^USE_WEBSOCKET=" ../.env | cut -d'=' -f2 | tr -d '\n\r')

echo "📋 Configuration détectée :"
echo "   Backend: $BACKEND"
echo "   Type: $TYPE"  
echo "   Serveur web: $WEBSERVER"
echo "   WebSocket: $USE_WEBSOCKET"
echo "

# Vérification de Homebrew
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew n'est pas installé. Installation en cours..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "✅ Homebrew déjà installé"
fi

# Mise à jour de Homebrew
echo "🔄 Mise à jour de Homebrew..."
brew update

# Fonction d'installation avec vérification
install_if_missing() {
    local tool=$1
    local install_cmd=$2
    
    if command -v "$tool" &> /dev/null; then
        echo "✅ $tool déjà installé"
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

# Installation sélective selon le backend
case "$BACKEND" in
    php)
        echo "🐘 Installation des outils PHP complets (dev + debug)..."
        install_if_missing "php" "brew install php"
        install_if_missing "composer" "brew install composer"
        
        echo "📦 Installation des outils PHP de développement..."
        install_if_missing "php-cs-fixer" "brew install php-cs-fixer"
        
        # Extensions PHP pour développement (gérées localement)
        if command -v php &> /dev/null; then
            echo "🔧 Configuration des extensions PHP locales..."
            # Vérifier si Xdebug est disponible
            php -m | grep -q xdebug || echo "   💡 Pour Xdebug: pecl install xdebug (si nécessaire)"
            echo "   💡 Extensions disponibles localement: zip, curl, gd, redis, imagick, xdebug"
        fi
        
        # Outils Composer globaux
        if command -v composer &> /dev/null; then
            echo "📦 Installation des packages Composer globaux..."
            composer global show phpunit/phpunit &> /dev/null || composer global require phpunit/phpunit
            composer global show phpstan/phpstan &> /dev/null || composer global require phpstan/phpstan
        fi
        ;;
        
    node)
        echo "🟢 Installation des outils Node.js..."
        install_if_missing "node" "brew install node"
        install_if_missing "nvm" "brew install nvm"
        install_if_missing "yarn" "brew install yarn"
        
        # Outils npm globaux
        if command -v npm &> /dev/null; then
            echo "📦 Installation des outils npm globaux..."
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
            echo "📦 Installation des outils pip globaux..."
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
        echo "⚠️ Backend '$BACKEND' non reconnu. Installation des outils de base uniquement."
        ;;
esac

# Installation des outils WebSocket si activés
if [ "$USE_WEBSOCKET" = "true" ]; then
    echo "🔌 WebSocket activé - installation des outils associés..."
    if [ "$BACKEND" = "node" ]; then
        if command -v npm &> /dev/null; then
            npm list -g socket.io &> /dev/null || npm install -g socket.io
        fi
    fi
fi

# Docker (si nécessaire)
echo "🐳 Vérification de Docker..."
if command -v docker &> /dev/null; then
    echo "✅ Docker déjà installé"
else
    echo "📦 Installation de Docker Desktop..."
    brew install --cask docker
fi

echo ""
echo "🎉 Installation terminée pour le backend $BACKEND !"
echo "=================================================="

# Résumé des outils installés selon le backend
case "$BACKEND" in
    php)
        if command -v php &> /dev/null; then
            echo "� Outils PHP installés :"
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
            command -v yarn &> /dev/null && echo "   📦 Yarn: $(yarn --version)"
            command -v nvm &> /dev/null && echo "   🔄 nvm: installé"
        fi
        ;;
    python)
        if command -v python3 &> /dev/null; then
            echo "� Outils Python installés :"
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
echo "   � Docker: $(docker --version)"
echo "   � git: $(git --version)"
echo "   � httpie: $(http --version)"

echo ""
echo "� Outils installés pour le backend '$BACKEND' !"
echo "💡 Les conteneurs Docker continuent de fonctionner pour l'exécution."
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