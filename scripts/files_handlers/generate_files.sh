#!/bin/bash
# Script de génération des fichiers API/APP selon le backend et le type choisi
# Usage: ./generate_files.sh <backend> <type>

set -e  # Arrêter en cas d'erreur

# Vérification des arguments
if [ $# -ne 2 ]; then
    echo "❌ Nombre d'arguments incorrect"
    exit 1
fi

BACKEND="$1"
TYPE="$2"

# Validation des arguments
case "$BACKEND" in
    php|node|python|go) ;;
    *) echo "❌ Backend '$BACKEND' invalide. Choix: php, node, python, go"; exit 1 ;;
esac

case "$TYPE" in
    api|app) ;;
    *) echo "❌ Type '$TYPE' invalide. Choix: api, app"; exit 1 ;;
esac

echo "🔧 Génération du fichier $BACKEND en mode $TYPE..."

# Détecter le bon chemin pour le fichier .env et lire les variables de configuration
if [ -f ".env" ]; then
    ENV_FILE=".env"
    echo "   📋 Configuration lue depuis ./.env"
elif [ -f "../.env" ]; then
    ENV_FILE="../.env"
    echo "   📋 Configuration lue depuis ../.env"
else
    ENV_FILE=""
fi

if [ -n "$ENV_FILE" ]; then
    DB_TYPE=$(grep "^DB_TYPE=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
    DB_VERSION=$(grep "^DB_VERSION=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
    DB_NAME=$(grep "^DB_NAME=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
    DB_USER=$(grep "^DB_USER=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
    DB_PASSWORD=$(grep "^DB_PASSWORD=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
    BACKEND_VERSION=$(grep "^BACKEND_VERSION=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
    WEBSERVER=$(grep "^WEBSERVER=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
    USE_MAILPIT=$(grep "^USE_MAILPIT=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
    USE_WEBSOCKET=$(grep "^USE_WEBSOCKET=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
    WEBSOCKET_TYPE=$(grep "^WEBSOCKET_TYPE=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '\n\r')
else
    echo "   ⚠️  Fichier .env non trouvé, utilisation des valeurs par défaut"
    DB_TYPE="postgres"
    DB_VERSION="latest"
    DB_NAME="database"
    DB_USER="admin"
    DB_PASSWORD="root"
    BACKEND_VERSION="latest"
    WEBSERVER="nginx"
    USE_MAILPIT="false"
    USE_WEBSOCKET="false"
    WEBSOCKET_TYPE="socketio"
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

# Créer le dossier cible selon le type 
TARGET_DIR="$TYPE"
mkdir -p "$TARGET_DIR"
echo "   📁 Dossier $TARGET_DIR/ créé"

# Fonction pour générer le fichier PHP
generate_php() {
    local type="$1"
    local target_dir="$2"
    local file="$target_dir/index.php"
    
    if [ "$type" = "api" ]; then
        cat > "$file" << EOF
<?php
header('Content-Type: application/json');

// Configuration du projet
\$config = [
    'type' => '$TYPE',
    'backend' => '$BACKEND',
    'backend_version' => '$BACKEND_VERSION',
    'webserver' => '$WEBSERVER',
    'database' => [
        'type' => '$DB_TYPE',
        'version' => '$DB_VERSION',
        'name' => '$DB_NAME',
        'user' => '$DB_USER'
    ],
    'services' => [
        'mailpit' => '$USE_MAILPIT',
        'websocket' => '$USE_WEBSOCKET',
        'websocket_type' => '$WEBSOCKET_TYPE'
    ],
    'runtime' => [
        'php_version' => phpversion(),
        'server' => \$_SERVER['SERVER_SOFTWARE'] ?? 'Unknown',
        'timestamp' => date('Y-m-d H:i:s')
    ]
];

echo json_encode([
    'message' => 'Hello from PHP API!',
    'config' => \$config
], JSON_PRETTY_PRINT);
EOF
    else  # app
        cat > "$file" << EOF
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hello from PHP</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 800px;
            margin: 2rem auto;
            padding: 2rem;
            line-height: 1.6;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            color: white;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 2rem;
            box-shadow: 0 8px 32px rgba(31, 38, 135, 0.37);
            border: 1px solid rgba(255, 255, 255, 0.18);
        }
        h1 { 
            text-align: center; 
            margin-bottom: 1rem;
            font-size: 2.5rem;
        }
        .info {
            background: rgba(255, 255, 255, 0.1);
            padding: 1rem;
            border-radius: 8px;
            margin: 1rem 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐘 Hello from PHP!</h1>
        <div class="info">
            <p><strong>Type:</strong> $TYPE</p>
            <p><strong>Backend:</strong> $BACKEND $BACKEND_VERSION</p>
            <p><strong>Serveur web:</strong> $WEBSERVER</p>
            <p><strong>Base de données:</strong> $DB_TYPE $DB_VERSION</p>
            <p><strong>DB Name:</strong> $DB_NAME | <strong>User:</strong> $DB_USER</p>
            <p><strong>Mailpit:</strong> $USE_MAILPIT | <strong>WebSocket:</strong> $USE_WEBSOCKET ($WEBSOCKET_TYPE)</p>
            <hr style="margin: 1rem 0; border: 1px solid rgba(255,255,255,0.2);">
            <p><strong>PHP Version:</strong> <?= phpversion() ?></p>
            <p><strong>Server:</strong> <?= \$_SERVER['SERVER_SOFTWARE'] ?? 'Unknown' ?></p>
            <p><strong>Timestamp:</strong> <?= date('Y-m-d H:i:s') ?></p>
        </div>
        <p>Votre application PHP est prête ! 🚀</p>
        <p>Modifiez ce fichier dans <code>$target_dir/index.php</code> pour commencer votre développement.</p>
    </div>
</body>
</html>
EOF
    fi
    echo "   ✅ Fichier PHP généré: $file ($type)"
}

# Fonction pour générer le fichier Node.js
generate_node() {
    local type="$1"
    local target_dir="$2"
    local file="$target_dir/index.js"
    
    if [ "$type" = "api" ]; then
        cat > "$file" << EOF
import express from 'express';
const app = express();

// Configuration du projet
const config = {
    type: '$TYPE',
    backend: '$BACKEND',
    backend_version: '$BACKEND_VERSION',
    webserver: '$WEBSERVER',
    database: {
        type: '$DB_TYPE',
        version: '$DB_VERSION',
        name: '$DB_NAME',
        user: '$DB_USER'
    },
    services: {
        mailpit: '$USE_MAILPIT',
        websocket: '$USE_WEBSOCKET',
        websocket_type: '$WEBSOCKET_TYPE'
    },
    runtime: {
        node_version: process.version,
        platform: process.platform,
        timestamp: new Date().toISOString()
    }
};

app.get('/', (req, res) => {
	res.json({
        message: 'Hello from Node.js API!',
        config: config
    });
});

app.listen(80, () => {
    console.log('Node.js API running on port 80');
});
EOF
    else  # app
        cat > "$file" << EOF
import express from 'express';
const app = express();

app.get('/', (req, res) => {
	const html = \`
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hello from Node.js</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 800px;
            margin: 2rem auto;
            padding: 2rem;
            line-height: 1.6;
            background: linear-gradient(135deg, #4ecdc4 0%, #44a08d 100%);
            min-height: 100vh;
            color: white;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 2rem;
            box-shadow: 0 8px 32px rgba(31, 38, 135, 0.37);
            border: 1px solid rgba(255, 255, 255, 0.18);
        }
        h1 { 
            text-align: center; 
            margin-bottom: 1rem;
            font-size: 2.5rem;
        }
        .info {
            background: rgba(255, 255, 255, 0.1);
            padding: 1rem;
            border-radius: 8px;
            margin: 1rem 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🟢 Hello from Node.js!</h1>
        <div class="info">
            <p><strong>Type:</strong> $TYPE</p>
            <p><strong>Backend:</strong> $BACKEND $BACKEND_VERSION</p>
            <p><strong>Serveur web:</strong> $WEBSERVER</p>
            <p><strong>Base de données:</strong> $DB_TYPE $DB_VERSION</p>
            <p><strong>DB Name:</strong> $DB_NAME | <strong>User:</strong> $DB_USER</p>
            <p><strong>Mailpit:</strong> $USE_MAILPIT | <strong>WebSocket:</strong> $USE_WEBSOCKET ($WEBSOCKET_TYPE)</p>
            <hr style="margin: 1rem 0; border: 1px solid rgba(255,255,255,0.2);">
            <p><strong>Node Version:</strong> \${process.version}</p>
            <p><strong>Platform:</strong> \${process.platform}</p>
            <p><strong>Timestamp:</strong> \${new Date().toLocaleString('fr-FR')}</p>
        </div>
        <p>Votre application Node.js est prête ! 🚀</p>
        <p>Modifiez ce fichier dans <code>$TYPE/index.js</code> pour commencer votre développement.</p>
    </div>
</body>
</html>\`;
	
	res.send(html);
});

app.listen(80, () => {
	console.log('Node.js app running on port 80');
});
EOF
    fi
    echo "   ✅ Fichier Node.js généré: $file ($type)"
    
    # Créer le package.json pour Node.js (scripts uniquement)
    cat > "$target_dir/package.json" << 'EOF'
{
  "name": "nodejs-app",
  "version": "1.0.0",
  "type": "module",
  "main": "index.js",
  "scripts": {
    "dev": "node index.js",
    "start": "node index.js"
  }
}
EOF
    echo "   ✅ Fichier package.json créé pour Node.js"
    echo "   💡 Utilisez 'npm install express' pour ajouter les dépendances"
}

# Fonction pour générer le fichier Python
generate_python() {
    local type="$1"
    local target_dir="$2"
    local file="$target_dir/main.py"
    
    if [ "$type" = "api" ]; then
        cat > "$file" << EOF
# main.py
from fastapi import FastAPI
from fastapi.responses import JSONResponse
import platform
from datetime import datetime

app = FastAPI()

# Configuration du projet
config = {
    "type": "$TYPE",
    "backend": "$BACKEND",
    "backend_version": "$BACKEND_VERSION",
    "webserver": "$WEBSERVER",
    "database": {
        "type": "$DB_TYPE",
        "version": "$DB_VERSION",
        "name": "$DB_NAME",
        "user": "$DB_USER"
    },
    "services": {
        "mailpit": "$USE_MAILPIT",
        "websocket": "$USE_WEBSOCKET",
        "websocket_type": "$WEBSOCKET_TYPE"
    },
    "runtime": {
        "python_version": platform.python_version(),
        "platform": platform.system(),
        "timestamp": datetime.now().isoformat()
    }
}

@app.get("/")
def read_root():
    return JSONResponse(content={
        "message": "Hello from Python API!",
        "config": config
    })
EOF
    else  # app
        cat > "$file" << EOF
# main.py
from fastapi import FastAPI
from fastapi.responses import HTMLResponse
import platform
from datetime import datetime

app = FastAPI()

@app.get("/", response_class=HTMLResponse)
def read_root():
    html_content = f"""
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hello from Python</title>
    <style>
        body {{
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 800px;
            margin: 2rem auto;
            padding: 2rem;
            line-height: 1.6;
            background: linear-gradient(135deg, #ff9a9e 0%, #fecfef 50%, #fecfef 100%);
            min-height: 100vh;
            color: #333;
        }}
        .container {{
            background: rgba(255, 255, 255, 0.9);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 2rem;
            box-shadow: 0 8px 32px rgba(31, 38, 135, 0.37);
            border: 1px solid rgba(255, 255, 255, 0.18);
        }}
        h1 {{ 
            text-align: center; 
            margin-bottom: 1rem;
            font-size: 2.5rem;
            color: #d63384;
        }}
        .info {{
            background: rgba(214, 51, 132, 0.1);
            padding: 1rem;
            border-radius: 8px;
            margin: 1rem 0;
        }}
    </style>
</head>
<body>
    <div class="container">
        <h1>🐍 Hello from Python!</h1>
        <div class="info">
            <p><strong>Type:</strong> $TYPE</p>
            <p><strong>Backend:</strong> $BACKEND $BACKEND_VERSION</p>
            <p><strong>Serveur web:</strong> $WEBSERVER</p>
            <p><strong>Base de données:</strong> $DB_TYPE $DB_VERSION</p>
            <p><strong>DB Name:</strong> $DB_NAME | <strong>User:</strong> $DB_USER</p>
            <p><strong>Mailpit:</strong> $USE_MAILPIT | <strong>WebSocket:</strong> $USE_WEBSOCKET ($WEBSOCKET_TYPE)</p>
            <hr style="margin: 1rem 0; border: 1px solid rgba(214, 51, 132, 0.3);">
            <p><strong>Python Version:</strong> {platform.python_version()}</p>
            <p><strong>Platform:</strong> {platform.system()}</p>
            <p><strong>Timestamp:</strong> {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
        </div>
        <p>Votre application Python est prête ! 🚀</p>
        <p>Modifiez ce fichier dans <code>$target_dir/main.py</code> pour commencer votre développement.</p>
    </div>
</body>
</html>"""
    return HTMLResponse(content=html_content)
EOF
    fi
    echo "   ✅ Fichier Python généré: $file ($type)"
    echo "   💡 Utilisez 'pip install fastapi uvicorn' ou 'poetry add fastapi uvicorn' pour les dépendances"
}

# Fonction pour générer le fichier Go
generate_go() {
    local type="$1"
    local target_dir="$2"
    local file="$target_dir/main.go"
    
    if [ "$type" = "api" ]; then
        cat > "$file" << EOF
package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"runtime"
	"time"
)

type Config struct {
	Type           string \`json:"type"\`
	Backend        string \`json:"backend"\`
	BackendVersion string \`json:"backend_version"\`
	Webserver      string \`json:"webserver"\`
	Database       struct {
		Type    string \`json:"type"\`
		Version string \`json:"version"\`
		Name    string \`json:"name"\`
		User    string \`json:"user"\`
	} \`json:"database"\`
	Services struct {
		Mailpit       string \`json:"mailpit"\`
		Websocket     string \`json:"websocket"\`
		WebsocketType string \`json:"websocket_type"\`
	} \`json:"services"\`
	Runtime struct {
		GoVersion string \`json:"go_version"\`
		Platform  string \`json:"platform"\`
		Timestamp string \`json:"timestamp"\`
	} \`json:"runtime"\`
}

type Response struct {
	Message string \`json:"message"\`
	Config  Config \`json:"config"\`
}

func handler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	
	config := Config{
		Type:           "$TYPE",
		Backend:        "$BACKEND",
		BackendVersion: "$BACKEND_VERSION",
		Webserver:      "$WEBSERVER",
	}
	config.Database.Type = "$DB_TYPE"
	config.Database.Version = "$DB_VERSION"
	config.Database.Name = "$DB_NAME"
	config.Database.User = "$DB_USER"
	config.Services.Mailpit = "$USE_MAILPIT"
	config.Services.Websocket = "$USE_WEBSOCKET"
	config.Services.WebsocketType = "$WEBSOCKET_TYPE"
	config.Runtime.GoVersion = runtime.Version()
	config.Runtime.Platform = fmt.Sprintf("%s/%s", runtime.GOOS, runtime.GOARCH)
	config.Runtime.Timestamp = time.Now().Format(time.RFC3339)
	
	response := Response{
		Message: "Hello from Go API!",
		Config:  config,
	}
	
	json.NewEncoder(w).Encode(response)
}

func main() {
	http.HandleFunc("/", handler)
	fmt.Println("Go API server running on port 80")
	http.ListenAndServe(":80", nil)
}
EOF
    else  # app
        cat > "$file" << EOF
package main

import (
	"fmt"
	"net/http"
	"runtime"
	"time"
)

func handler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	
	html := fmt.Sprintf(\`
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hello from Go</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            max-width: 800px;
            margin: 2rem auto;
            padding: 2rem;
            line-height: 1.6;
            background: linear-gradient(135deg, #74b9ff 0%, #0984e3 100%);
            min-height: 100vh;
            color: white;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 15px;
            padding: 2rem;
            box-shadow: 0 8px 32px rgba(31, 38, 135, 0.37);
            border: 1px solid rgba(255, 255, 255, 0.18);
        }
        h1 { 
            text-align: center; 
            margin-bottom: 1rem;
            font-size: 2.5rem;
        }
        .info {
            background: rgba(255, 255, 255, 0.1);
            padding: 1rem;
            border-radius: 8px;
            margin: 1rem 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔵 Hello from Go!</h1>
        <div class="info">
            <p><strong>Type:</strong> $TYPE</p>
            <p><strong>Backend:</strong> $BACKEND $BACKEND_VERSION</p>
            <p><strong>Serveur web:</strong> $WEBSERVER</p>
            <p><strong>Base de données:</strong> $DB_TYPE $DB_VERSION</p>
            <p><strong>DB Name:</strong> $DB_NAME | <strong>User:</strong> $DB_USER</p>
            <p><strong>Mailpit:</strong> $USE_MAILPIT | <strong>WebSocket:</strong> $USE_WEBSOCKET ($WEBSOCKET_TYPE)</p>
            <hr style="margin: 1rem 0; border: 1px solid rgba(255,255,255,0.2);">
            <p><strong>Go Version:</strong> %s</p>
            <p><strong>Platform:</strong> %s/%s</p>
            <p><strong>Timestamp:</strong> %s</p>
        </div>
        <p>Votre application Go est prête ! 🚀</p>
        <p>Modifiez ce fichier dans <code>$target_dir/main.go</code> pour commencer votre développement.</p>
    </div>
</body>
</html>\`, runtime.Version(), runtime.GOOS, runtime.GOARCH, time.Now().Format("2006-01-02 15:04:05"))
	
	fmt.Fprint(w, html)
}

func main() {
	http.HandleFunc("/", handler)
	fmt.Println("Go server running on port 80")
	http.ListenAndServe(":80", nil)
}
EOF
    fi
    echo "   ✅ Fichier Go généré: $file ($type)"
    echo "   💡 Utilisez 'go mod init app && go get github.com/gin-gonic/gin' pour initialiser le module"
}

# Générer le fichier selon le backend
case "$BACKEND" in
    php)
        generate_php "$TYPE" "$TARGET_DIR"
        ;;
    node)
        generate_node "$TYPE" "$TARGET_DIR"
        ;;
    python)
        generate_python "$TYPE" "$TARGET_DIR"
        ;;
    go)
        generate_go "$TYPE" "$TARGET_DIR"
        ;;
esac

echo "✅ Génération terminée pour $BACKEND ($TYPE)"