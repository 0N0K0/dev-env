#!/bin/bash
# Script de nettoyage complet du template dev-env
# Usage: ./clean_project.sh <backend> <webserver> <db_type> <use_mailpit> [use_websocket]

set -e  # Arrêter en cas d'erreur

# Fonction d'aide
show_usage() {
    echo "Usage: $0 <backend> <webserver> <db_type> <use_mailpit> [use_websocket]"
    echo "Exemple: $0 php nginx mysql true false"
    echo ""
    echo "Backends disponibles: php, node, python, go"
    echo "Serveurs web: apache, nginx"
    echo "Bases de données: postgres, mysql"
    echo "Options booléennes: true, false"
    exit 1
}

# Vérification des arguments
if [ $# -lt 4 ]; then
    echo "❌ Nombre d'arguments insuffisant"
    show_usage
fi

BACKEND="$1"
WEBSERVER="$2"
DB_TYPE="$3"
USE_MAILPIT="$4"
USE_WEBSOCKET="${5:-}"

# Validation des arguments
case "$BACKEND" in
    php|node|python|go) ;;
    *) echo "❌ Backend '$BACKEND' invalide. Choix: php, node, python, go"; exit 1 ;;
esac

case "$WEBSERVER" in
    apache|nginx) ;;
    *) echo "❌ Serveur web '$WEBSERVER' invalide. Choix: apache, nginx"; exit 1 ;;
esac

case "$DB_TYPE" in
    postgres|mysql) ;;
    *) echo "❌ Base de données '$DB_TYPE' invalide. Choix: postgres, mysql"; exit 1 ;;
esac

case "$USE_MAILPIT" in
    true|false) ;;
    *) echo "❌ USE_MAILPIT '$USE_MAILPIT' invalide. Choix: true, false"; exit 1 ;;
esac

if [ -n "$USE_WEBSOCKET" ]; then
    case "$USE_WEBSOCKET" in
        true|false) ;;
        *) echo "❌ USE_WEBSOCKET '$USE_WEBSOCKET' invalide. Choix: true, false"; exit 1 ;;
    esac
fi

echo "🔧 Nettoyage pour: $BACKEND + $WEBSERVER + $DB_TYPE"
echo "   Services optionnels: Mailpit=$USE_MAILPIT, WebSocket=$USE_WEBSOCKET"
echo ""

# 1. Suppression des backends non utilisés
echo "🗑️  Suppression des backends non utilisés..."
for backend_dir in php node go python; do
    if [ "$backend_dir" != "$BACKEND" ] && [ -d "docker/services/$backend_dir" ]; then
        rm -rf "docker/services/$backend_dir"
        echo "   Suppression: docker/services/$backend_dir/"
    fi
done

# 2. Suppression des serveurs web non utilisés
echo "🗑️  Suppression des serveurs web non utilisés..."
for webserver_dir in apache nginx; do
    if [ "$webserver_dir" != "$WEBSERVER" ] && [ -d "docker/services/$webserver_dir" ]; then
        rm -rf "docker/services/$webserver_dir"
        echo "   Suppression: docker/services/$webserver_dir/"
    fi
done

# 3. Nettoyage des fichiers de configuration nginx
if [ "$WEBSERVER" = "nginx" ]; then
    echo "🗑️  Nettoyage des fichiers de configuration nginx..."
    for template in nginx/nginx-php.conf nginx/nginx-default.conf; do
        if [ -f "$template" ]; then
            rm -f "$template"
            echo "   Suppression: $template (configuration template)"
        fi
    done
fi

# 4. Nettoyage des fichiers API non utilisés
echo "🗑️  Nettoyage des fichiers API non utilisés..."
declare -A backend_files
backend_files[php]="index.php"
backend_files[node]="index.js"
backend_files[python]="main.py"
backend_files[go]="main.go"

keep_file="${backend_files[$BACKEND]}"
for api_file in index.php index.js main.py main.go; do
    if [ "$api_file" != "$keep_file" ] && [ -f "api/$api_file" ]; then
        rm -f "api/$api_file"
        echo "   Suppression: api/$api_file"
    fi
done

# 5. Nettoyage du docker-compose.yml
echo "📝 Mise à jour du docker-compose.yml..."

if [ ! -f "docker-compose.yml" ]; then
    echo "   ❌ Erreur: docker-compose.yml non trouvé"
    exit 1
fi

# Créer une copie de travail
cp docker-compose.yml docker-compose.yml.tmp

# Supprimer les variables de version non utilisées selon le backend
case "$BACKEND" in
    php)
        sed -i '/NODE_VERSION:/d; /PYTHON_VERSION:/d; /GO_VERSION:/d' docker-compose.yml.tmp
        ;;
    node)
        sed -i '/PHP_VERSION:/d; /PYTHON_VERSION:/d; /GO_VERSION:/d' docker-compose.yml.tmp
        ;;
    python)
        sed -i '/PHP_VERSION:/d; /NODE_VERSION:/d; /GO_VERSION:/d' docker-compose.yml.tmp
        ;;
    go)
        sed -i '/PHP_VERSION:/d; /NODE_VERSION:/d; /PYTHON_VERSION:/d' docker-compose.yml.tmp
        ;;
esac

# Nettoyer les commentaires des volumes
sed -i '/# pour/d' docker-compose.yml.tmp

# Gérer les volumes selon le backend
if [ "$BACKEND" = "php" ]; then
    # Pour PHP, garder /var/www/html et supprimer /app
    sed -i '/- \.\/api:\/app/d' docker-compose.yml.tmp
else
    # Pour les autres, garder /app et supprimer /var/www/html
    sed -i '/- \.\/api:\/var\/www\/html/d' docker-compose.yml.tmp
fi

# Gérer le port PHP-FPM (seulement pour PHP)
if [ "$BACKEND" != "php" ]; then
    sed -i "/- '9000'/d" docker-compose.yml.tmp
fi

# Nettoyer les ports et variables de base de données
if [ "$DB_TYPE" = "postgres" ]; then
    # Supprimer les éléments MySQL
    sed -i "/- '3306:3306'/d; /MYSQL_DATABASE:/d; /MYSQL_USER:/d; /MYSQL_PASSWORD:/d; /MYSQL_ROOT_PASSWORD:/d" docker-compose.yml.tmp
elif [ "$DB_TYPE" = "mysql" ]; then
    # Supprimer les éléments PostgreSQL
    sed -i "/- '5432:5432'/d; /POSTGRES_DB:/d; /POSTGRES_USER:/d; /POSTGRES_PASSWORD:/d" docker-compose.yml.tmp
fi

# Simplifier l'image de base de données
if [ "$DB_TYPE" = "postgres" ]; then
    sed -i 's/image: \${DB_TYPE}:\${DB_VERSION}/image: postgres:latest/' docker-compose.yml.tmp
elif [ "$DB_TYPE" = "mysql" ]; then
    sed -i 's/image: \${DB_TYPE}:\${DB_VERSION}/image: mysql:latest/' docker-compose.yml.tmp
fi

# Nettoyer les lignes vides multiples
sed -i '/^$/N;/^\n$/d' docker-compose.yml.tmp

# Remplacer le fichier original
mv docker-compose.yml.tmp docker-compose.yml
echo "   ✅ docker-compose.yml nettoyé"

# 6. Nettoyer les fichiers de dépendances non utilisés dans /api
echo "🗑️  Nettoyage des fichiers de dépendances dans /api..."

# Fonction pour supprimer un fichier de dépendance
remove_dependency_file() {
    local file="$1"
    if [ -f "api/$file" ]; then
        rm -f "api/$file"
        echo "   Suppression: api/$file"
    fi
}

# Fonction pour supprimer un dossier de dépendance avec gestion sudo
remove_dependency_dir() {
    local dir="$1"
    if [ -d "api/$dir" ]; then
        if rm -rf "api/$dir" 2>/dev/null; then
            echo "   ✅ Suppression: api/$dir/"
        else
            echo "   💡 Le dossier api/$dir/ nécessite des permissions administrateur"
            echo "   🔐 Suppression avec sudo..."
            if sudo rm -rf "api/$dir"; then
                echo "   ✅ Suppression réussie avec sudo: api/$dir/"
            else
                echo "   ❌ Échec suppression: api/$dir/"
                echo "   ⚠️  Vous devrez supprimer manuellement: api/$dir"
            fi
        fi
    else
        echo "   ℹ️  Dossier api/$dir/ n'existe pas"
    fi
}

echo "   Backend actuel: $BACKEND"

# Supprimer les fichiers selon le backend
case "$BACKEND" in
    php)
        echo "   Fichiers à supprimer: go.mod, go.sum, package.json, package-lock.json, requirements.txt"
        remove_dependency_file "go.mod"
        remove_dependency_file "go.sum"
        remove_dependency_file "package.json"
        remove_dependency_file "package-lock.json"
        remove_dependency_file "requirements.txt"
        echo "   Dossiers à supprimer: node_modules, __pycache__"
        remove_dependency_dir "node_modules"
        remove_dependency_dir "__pycache__"
        ;;
    node)
        echo "   Fichiers à supprimer: go.mod, go.sum, requirements.txt, composer.json, composer.lock"
        remove_dependency_file "go.mod"
        remove_dependency_file "go.sum"
        remove_dependency_file "requirements.txt"
        remove_dependency_file "composer.json"
        remove_dependency_file "composer.lock"
        echo "   Dossiers à supprimer: __pycache__, vendor"
        remove_dependency_dir "__pycache__"
        remove_dependency_dir "vendor"
        ;;
    python)
        echo "   Fichiers à supprimer: go.mod, go.sum, package.json, package-lock.json, composer.json, composer.lock"
        remove_dependency_file "go.mod"
        remove_dependency_file "go.sum"
        remove_dependency_file "package.json"
        remove_dependency_file "package-lock.json"
        remove_dependency_file "composer.json"
        remove_dependency_file "composer.lock"
        echo "   Dossiers à supprimer: node_modules, vendor"
        remove_dependency_dir "node_modules"
        remove_dependency_dir "vendor"
        ;;
    go)
        echo "   Fichiers à supprimer: package.json, package-lock.json, requirements.txt, composer.json, composer.lock"
        remove_dependency_file "package.json"
        remove_dependency_file "package-lock.json"
        remove_dependency_file "requirements.txt"
        remove_dependency_file "composer.json"
        remove_dependency_file "composer.lock"
        echo "   Dossiers à supprimer: node_modules, __pycache__, vendor"
        remove_dependency_dir "node_modules"
        remove_dependency_dir "__pycache__"
        remove_dependency_dir "vendor"
        ;;
esac

# 7. Gérer les services optionnels
echo "🗑️  Gestion des services optionnels..."

# Mailpit
if [ "$USE_MAILPIT" = "false" ] && [ -f "docker-compose.mailpit.yml" ]; then
    rm -f "docker-compose.mailpit.yml"
    echo "   Suppression: docker-compose.mailpit.yml"
fi

# WebSocket
if [ "$USE_WEBSOCKET" = "false" ]; then
    if [ -f "docker-compose.websocket.yml" ]; then
        rm -f "docker-compose.websocket.yml"
        echo "   Suppression: docker-compose.websocket.yml"
    fi
    if [ -d "websocket/" ]; then
        rm -rf "websocket/"
        echo "   Suppression: websocket/"
    fi
fi

# 8. Nettoyage final du Makefile
echo "📝 Mise à jour du Makefile..."

if [ -f "makefile" ]; then
    # Créer une copie de travail
    cp makefile makefile.tmp
    
    # Supprimer les listes de choix
    sed -i '/^BACKENDS\s*=/d; /^WEBSERVERS\s*=/d; /^DBS\s*=/d' makefile.tmp
    
    # Supprimer la target switch (plus complexe en sed, on utilise awk)
    awk '
        /^switch:/ { skip=1; next }
        /^[a-zA-Z][a-zA-Z0-9_-]*:/ && skip { skip=0 }
        !skip { print }
    ' makefile.tmp > makefile.tmp2
    
    # Supprimer la target clean-project
    awk '
        /^clean-project:/ { skip=1; next }
        /^[a-zA-Z][a-zA-Z0-9_-]*:/ && skip { skip=0 }
        !skip { print }
    ' makefile.tmp2 > makefile.tmp3
    
    # Supprimer switch et clean-project de la ligne .PHONY ou autres références
    sed -i 's/switch clean-project //g; s/switch //g; s/clean-project //g' makefile.tmp3
    
    # Nettoyer les lignes vides multiples
    sed -i '/^$/N;/^\n$/d' makefile.tmp3
    
    # Remplacer le fichier original
    mv makefile.tmp3 makefile
    rm -f makefile.tmp makefile.tmp2
    
    echo "   ✅ Makefile simplifié"
fi

# 9. Auto-suppression du script
echo "🗑️  Auto-suppression du script de nettoyage..."
script_path="$(realpath "$0")"
if rm -f "$script_path" 2>/dev/null; then
    echo "   ✅ clean_project.sh supprimé"
else
    echo "   ❌ Impossible de supprimer le script (permissions)"
fi

# Supprimer aussi le script Python s'il existe
if [ -f "clean_project.py" ]; then
    rm -f "clean_project.py"
    echo "   ✅ clean_project.py supprimé"
fi

# Supprimer le script bash auxiliaire s'il existe
if [ -f "clean_protected_dirs.sh" ]; then
    rm -f "clean_protected_dirs.sh"
    echo "   ✅ clean_protected_dirs.sh supprimé"
fi

echo ""
echo "✅ Nettoyage terminé !"
echo ""
echo "📋 Fichiers conservés :"
echo "   - $BACKEND/ (backend)"
echo "   - $WEBSERVER/ (serveur web)"
echo "   - api/ (code source simplifié)"

if [ "$USE_MAILPIT" = "true" ]; then
    echo "   - docker-compose.mailpit.yml (Mailpit activé)"
fi

if [ "$USE_WEBSOCKET" = "true" ]; then
    echo "   - websocket/ et docker-compose.websocket.yml (WebSocket activé)"
fi

echo "   - .env, docker-compose.yml, makefile (simplifiés)"
echo ""
echo "🚀 Votre projet est maintenant prêt avec $BACKEND + $WEBSERVER + $DB_TYPE"

if [ "$USE_MAILPIT" = "true" ] || [ "$USE_WEBSOCKET" = "true" ]; then
    echo -n " + services optionnels :"
    [ "$USE_MAILPIT" = "true" ] && echo -n " Mailpit"
    [ "$USE_WEBSOCKET" = "true" ] && echo -n " WebSocket"
    echo " !"
fi
