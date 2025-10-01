#!/bin/bash
# Script de nettoyage complet du template
# Usage: ./scripts/clean_project.sh

set -e

# Charger les fonctions utilitaires
if [ -f "scripts/utils.sh" ]; then
    source scripts/utils.sh
else
    echo "❌ Fichier utils.sh non trouvé"
    exit 1
fi

# Lire la configuration actuelle du .env
read_env_config() {
    if [ ! -f ".env" ]; then
        echo "❌ Fichier .env non trouvé"
        exit 1
    fi
    
    PROJECT_NAME=$(grep "^PROJECT_NAME=" .env | cut -d'=' -f2)
    TYPE=$(grep "^TYPE=" .env | cut -d'=' -f2)
    BACKEND=$(grep "^BACKEND=" .env | cut -d'=' -f2)
    WEBSERVER=$(grep "^WEBSERVER=" .env | cut -d'=' -f2)
    DB_TYPE=$(grep "^DB_TYPE=" .env | cut -d'=' -f2)
    USE_MAILPIT=$(grep "^USE_MAILPIT=" .env | cut -d'=' -f2)
    USE_WEBSOCKET=$(grep "^USE_WEBSOCKET=" .env | cut -d'=' -f2)
    WEBSOCKET_TYPE=$(grep "^WEBSOCKET_TYPE=" .env | cut -d'=' -f2)
    
    print_title "NETTOYAGE DU PROJET"
    echo -e "${CYAN}Configuration détectée :${NC}"
    echo -e "   Projet: ${GREEN}$PROJECT_NAME${NC}"
    echo -e "   Type: ${GREEN}$TYPE${NC}"
    echo -e "   Backend: ${GREEN}$BACKEND${NC}"
    echo -e "   Serveur web: ${GREEN}$WEBSERVER${NC}"
    echo -e "   Base de données: ${GREEN}$DB_TYPE${NC}"
    echo -e "   Mailpit: ${GREEN}$USE_MAILPIT${NC}"
    echo -e "   WebSocket: ${GREEN}$USE_WEBSOCKET${NC}"
    if [ "$USE_WEBSOCKET" = "true" ]; then
        echo -e "   Type WebSocket: ${GREEN}$WEBSOCKET_TYPE${NC}"
    fi
}

# Point d'entrée principal
clear
read_env_config

# Fonction de confirmation
confirm_cleanup() {
    echo -e "\n${YELLOW}⚠️  ATTENTION : Cette opération va supprimer définitivement :${NC}"
    echo -e "   ${RED}• Les services Docker non utilisés${NC}"
    echo -e "   ${RED}• Les fichiers de scripts${NC}"
    echo -e "   ${RED}• Les commandes obsolètes${NC}"
    echo ""
    confirm=$(ask_yes_no "Voulez-vous continuer le nettoyage" "false")
    
    if [ "$confirm" = "false" ]; then
        echo -e "\n${YELLOW}❌ Nettoyage annulé${NC}"
        exit 0
    fi
}

# 1. Nettoyage des services Docker non utilisés
cleanup_docker_services() {
    echo -e "\n${CYAN}🗑️  Nettoyage des services Docker...${NC}"
    
    # Backends non utilisés
    for backend_dir in php node go python; do
        if [ "$backend_dir" != "$BACKEND" ] && [ -d "docker/services/$backend_dir" ]; then
            rm -rf "docker/services/$backend_dir"
            echo -e "   ${GREEN}✅ Supprimé: docker/services/$backend_dir/${NC}"
        fi
    done
    
    # Serveurs web non utilisés
    for webserver_dir in apache nginx; do
        if [ "$webserver_dir" != "$WEBSERVER" ] && [ -d "docker/services/$webserver_dir" ]; then
            rm -rf "docker/services/$webserver_dir"
            echo -e "   ${GREEN}✅ Supprimé: docker/services/$webserver_dir/${NC}"
        fi
    done

    # WebSocket non utilisé
    if [ "$WEBSOCKET_TYPE" != "socketio" ] && [ -d "docker/services/socketio" ]; then
        rm -rf "docker/services/socketio"
        echo -e "   ${GREEN}✅ Supprimé: docker/services/socketio/${NC}"
    fi

    rm ".gitignore"
}

# 2. Génération du README personnalisé
generate_project_readme() {
    echo -e "\n${CYAN}📝 Génération du README personnalisé...${NC}"
    
    # Créer une sauvegarde de l'ancien README
    if [ -f "README.md" ]; then
        cp README.md README.md.backup
        echo -e "   ${BLUE}ℹ️  Sauvegarde créée: README.md.backup${NC}"
    fi
    
    # Générer le nouveau README
    cat > README.md << EOF
# 🚀 $PROJECT_NAME

Environnement de développement Docker Compose configuré avec **$BACKEND** et **$WEBSERVER**.

## 📋 Configuration du projet

- **Type**: $TYPE
- **Backend**: $BACKEND
- **Serveur web**: $WEBSERVER
- **Base de données**: $DB_TYPE
EOF

    # Ajouter les services optionnels
    if [ "$USE_MAILPIT" = "true" ]; then
        echo "- **SMTP local**: Mailpit activé" >> README.md
    fi
    
    if [ "$USE_WEBSOCKET" = "true" ]; then
        echo "- **WebSocket**: $WEBSOCKET_TYPE activé" >> README.md
    fi
    
    cat >> README.md << 'EOF'

## 🚀 Démarrage rapide

### Prérequis

- Docker Desktop
- Homebrew

### Installation

1. Cloner le projet :
\`\`\`bash
git clone <votre-repo>
cd $PROJECT_NAME
\`\`\`

2. Construire et démarrer l'environnement :
\`\`\`bash
make build
\`\`\`

3. Accéder à l'application :
   - **Application principale** : http://localhost
EOF

    # Ajouter les accès aux services selon la configuration
    if [ "$USE_MAILPIT" = "true" ]; then
        echo "   - **Interface Mailpit** : http://localhost:8025" >> README.md
    fi
    
    if [ "$USE_WEBSOCKET" = "true" ]; then
        echo "   - **Interface WebSocket** : http://localhost:8001" >> README.md
    fi
    
    # Ajouter les ports de base de données
    if [ "$DB_TYPE" = "mysql" ]; then
        echo "   - **MySQL** : localhost:3306" >> README.md
    elif [ "$DB_TYPE" = "postgres" ]; then
        echo "   - **PostgreSQL** : localhost:5432" >> README.md
    fi
    
    cat >> README.md << 'EOF'

## 📋 Commandes disponibles

### Gestion Docker
```bash
make start       # Démarrer les services
make stop        # Arrêter les services
make build       # Construire et démarrer
make clean       # Arrêter et supprimer les données
make status      # État des conteneurs
make logs        # Voir les logs
```

### Commandes utiles
```bash
make help        # Afficher l'aide complète

make exec SERVICE=<service> CMD=<commande> # Exécuter une commande dans un conteneur

EOF

    # Ajouter les commandes DB spécifiques
    if [ "$DB_TYPE" = "mysql" ]; then
        cat >> README.md << 'EOF'
make mysql-cli # Accès direct à MySQL
make mysql-query SQL="SHOW DATABASES;" # Exécuter une requête MySQL
```
EOF
    elif [ "$DB_TYPE" = "postgres" ]; then
        cat >> README.md << 'EOF'
make postgres-cli # Accès direct à PostgreSQL
make postgres-query SQL="\l" # Exécuter une requête PostgreSQL
```
EOF
    fi
    
    cat >> README.md << EOF

## 📁 Structure du projet

\`\`\`
$PROJECT_NAME/
├── 📄 Makefile                    # Commandes de gestion
├── 📄 .env                        # Configuration
├── 🗂️ docker/
│   ├── 🗂️ services/
│   │   ├── 🗂️ $BACKEND/           # Configuration $BACKEND
│   │   └── 🗂️ $WEBSERVER/         # Configuration $WEBSERVER
│   ├── 📄 docker-compose.yml      # Services Docker
└── 🗂️ $TYPE/                      # Code source
\`\`\`

EOF

    # Ajouter la section de configuration SMTP si Mailpit est activé
    if [ "$USE_MAILPIT" = "true" ]; then
        cat >> README.md << 'EOF'
## 📧 Configuration SMTP (Mailpit)

Pour tester les emails localement, configurez votre application avec :

```env
MAIL_HOST=smtp
MAIL_PORT=1025
MAIL_USERNAME=
MAIL_PASSWORD=
MAIL_ENCRYPTION=null
```

Interface web disponible sur : http://localhost:8025

EOF
    fi

    # Ajouter la section WebSocket si activé
    if [ "$USE_WEBSOCKET" = "true" ]; then
        cat >> README.md << EOF
## 🔌 WebSocket ($WEBSOCKET_TYPE)

Le service WebSocket $WEBSOCKET_TYPE est configuré et disponible.

- **Interface de test** : http://localhost:8001
- **Endpoint WebSocket** : ws://localhost:8001

EOF
    fi

    cat >> README.md << 'EOF'
## 🛠️ Développement

### Variables d'environnement

Les variables principales sont définies dans le fichier `.env`.

### Logs et debugging

```bash
# Voir tous les logs
make logs

# Logs d'un service spécifique
docker compose logs backend
docker compose logs webserver
docker compose logs database
```

*Généré automatiquement par le script de nettoyage - $(date)*
EOF

    echo -e "   ${GREEN}✅ README personnalisé généré${NC}"
}

# 3. Nettoyage du Makefile
cleanup_makefile() {
    echo -e "\n${CYAN}🗑️  Nettoyage du Makefile...${NC}"
    
    if [ ! -f "makefile" ]; then
        echo -e "   ${YELLOW}⚠️  Makefile non trouvé${NC}"
        return
    fi
    
    # Créer une copie de sauvegarde
    cp makefile makefile.backup
    
    # Créer un nouveau makefile simplifié
    cat > makefile << 'EOF'
# Makefile pour environnement de développement configuré

# Composition des fichiers Docker Compose selon la configuration
COMPOSE_FILES = -f docker-compose.yml
ifeq ($(shell grep USE_MAILPIT .env | cut -d'=' -f2), true)
	COMPOSE_FILES += -f docker-compose.mailpit.yml
endif
ifeq ($(shell grep USE_WEBSOCKET .env | cut -d'=' -f2), true)
	COMPOSE_FILES += -f docker-compose.websocket.yml
endif

.PHONY: start stop build clean status logs exec help

# Commandes Docker Compose principales
start:
	@if [ ! -f ".env" ]; then echo "❌ Fichier .env manquant"; exit 1; fi
	@cd docker && docker compose --env-file ../.env $(COMPOSE_FILES) up -d

stop:
	@cd docker && docker compose --env-file ../.env $(COMPOSE_FILES) down

build:
	@if [ ! -f ".env" ]; then echo "❌ Fichier .env manquant"; exit 1; fi
	@cd docker && docker compose --env-file ../.env $(COMPOSE_FILES) up --build -d

clean:
	@cd docker && docker compose --env-file ../.env $(COMPOSE_FILES) down -v

status:
	@echo "📊 État des conteneurs :"
	@cd docker && docker compose --env-file ../.env $(COMPOSE_FILES) ps

logs:
	@echo "📝 Logs des conteneurs :"
	@cd docker && docker compose --env-file ../.env $(COMPOSE_FILES) logs -f

# Exécuter une commande dans un conteneur
exec:
ifndef SERVICE
	$(error "Usage: make exec SERVICE=<service> CMD=\"<command>\". Par exemple: make exec SERVICE=backend CMD=\"ls -la\"")
endif
	@echo "🔧 Exécution dans le conteneur $(SERVICE)..."
	@cd docker && docker compose --env-file ../.env $(COMPOSE_FILES) exec $(SERVICE) $(CMD)

EOF
    
    # Ajouter les commandes DB spécifiques selon le type de base de données
    if [ "$DB_TYPE" = "mysql" ]; then
        cat >> makefile << 'EOF'
# Commandes MySQL
mysql-cli:
	@echo "🐬 Connexion à MySQL..."
	@cd docker && docker compose --env-file ../.env $(COMPOSE_FILES) exec mysql mysql -u $(shell grep "^DB_USER=" .env | cut -d'=' -f2) -p$(shell grep "^DB_PASSWORD=" .env | cut -d'=' -f2) $(shell grep "^DB_NAME=" .env | cut -d'=' -f2)

mysql-query:
ifndef SQL
	$(error "Usage: make mysql-query SQL=\"<requête>\". Par exemple: make mysql-query SQL=\"SHOW DATABASES;\"")
endif
	@echo "🐬 Exécution de la requête MySQL..."
	@cd docker && docker compose --env-file ../.env $(COMPOSE_FILES) exec mysql mysql -u $(shell grep "^DB_USER=" .env | cut -d'=' -f2) -p$(shell grep "^DB_PASSWORD=" .env | cut -d'=' -f2) $(shell grep "^DB_NAME=" .env | cut -d'=' -f2) -e "$(SQL)"

EOF
        # Mettre à jour .PHONY
        sed -i 's/.PHONY: start stop build clean status logs exec help/.PHONY: start stop build clean status logs exec mysql-cli mysql-query help/' makefile
    elif [ "$DB_TYPE" = "postgres" ]; then
        cat >> makefile << 'EOF'
# Commandes PostgreSQL
postgres-cli:
	@echo "🐘 Connexion à PostgreSQL..."
	@cd docker && docker compose --env-file ../.env $(COMPOSE_FILES) exec postgres psql -U $(shell grep "^DB_USER=" .env | cut -d'=' -f2) -d $(shell grep "^DB_NAME=" .env | cut -d'=' -f2)

postgres-query:
ifndef SQL
	$(error "Usage: make postgres-query SQL=\"<requête>\". Par exemple: make postgres-query SQL=\"\\l\"")
endif
	@echo "🐘 Exécution de la requête PostgreSQL..."
	@cd docker && docker compose --env-file ../.env $(COMPOSE_FILES) exec postgres psql -U $(shell grep "^DB_USER=" .env | cut -d'=' -f2) -d $(shell grep "^DB_NAME=" .env | cut -d'=' -f2) -c "$(SQL)"

EOF
        # Mettre à jour .PHONY
        sed -i 's/.PHONY: start stop build clean status logs exec help/.PHONY: start stop build clean status logs exec postgres-cli postgres-query help/' makefile
    fi
    
    # Ajouter la section help simplifiée
    cat >> makefile << 'EOF'
help:
	@echo ""
	@echo "🔧 Commandes disponibles :"
	@echo "  make start     # Démarrer l'environnement Docker"
	@echo "  make stop      # Arrêter les conteneurs"
	@echo "  make build     # Rebuilder les conteneurs"
	@echo "  make status    # Voir l'état des conteneurs"
	@echo "  make logs      # Voir les logs des conteneurs"
	@echo "  make exec SERVICE=<service> CMD=\"<command>\" # Exécuter une commande dans un conteneur"
EOF
    
    # Ajouter les commandes DB spécifiques dans l'aide
    if [ "$DB_TYPE" = "mysql" ]; then
        cat >> makefile << 'EOF'
	@echo "  make mysql-cli # Connexion directe à MySQL"
	@echo "  make mysql-query SQL=\"<requête>\" # Exécuter une requête MySQL"
EOF
    elif [ "$DB_TYPE" = "postgres" ]; then
        cat >> makefile << 'EOF'
	@echo "  make postgres-cli # Connexion directe à PostgreSQL"
	@echo "  make postgres-query SQL=\"<requête>\" # Exécuter une requête PostgreSQL"
EOF
    fi
    
    cat >> makefile << 'EOF'
	@echo "  make help      # Afficher cette aide"
	@echo ""
EOF
    
    echo -e "   ${GREEN}✅ Makefile nettoyé et simplifié${NC}"
    echo -e "   ${BLUE}ℹ️  Sauvegarde créée: makefile.backup${NC}"
}

# Fonction de résumé final
show_final_summary() {
    echo -e "\n${GREEN}🦆 NETTOYAGE TERMINÉ !${NC}"
    print_title "RÉSUMÉ"
    
    echo -e "${CYAN}Fichiers générés :${NC}"
    echo -e "   ${GREEN}✅ README.md personnalisé${NC}"
    echo -e "   ${GREEN}✅ Makefile simplifié${NC}"
    
    echo -e "\n${CYAN}📋 Configuration finale :${NC}"
    echo -e "   ${YELLOW}Projet:${NC} ${GREEN}$PROJECT_NAME${NC}"
    echo -e "   ${YELLOW}Backend:${NC} ${GREEN}$BACKEND${NC} (docker/services/$BACKEND/)"
    echo -e "   ${YELLOW}Serveur web:${NC} ${GREEN}$WEBSERVER${NC} (docker/services/$WEBSERVER/)"
    echo -e "   ${YELLOW}Base de données:${NC} ${GREEN}$DB_TYPE${NC}"
    echo -e "   ${YELLOW}Code source:${NC} ${GREEN}$TYPE/${NC}"
    
    echo -e "\n${CYAN}🚀 Services actifs :${NC}"
    if [ "$USE_MAILPIT" = "true" ]; then
        echo -e "   ${GREEN}✅ Mailpit (docker/docker-compose.mailpit.yml)${NC}"
    else
        echo -e "   ${RED}❌ Mailpit (désactivé)${NC}"
    fi
    
    if [ "$USE_WEBSOCKET" = "true" ]; then
        echo -e "   ${GREEN}✅ WebSocket - $WEBSOCKET_TYPE (docker/docker-compose.websocket.yml)${NC}"
    else
        echo -e "   ${RED}❌ WebSocket (désactivé)${NC}"
    fi
        
    echo -e "\n${PURPLE}💡 Prochaines étapes :${NC}"
    echo -e "   ${CYAN}1.${NC} Utilisez ${GREEN}make build${NC} pour construire les services"
    echo -e "   ${CYAN}2.${NC} Utilisez ${GREEN}make start${NC} pour démarrer l'environnement"
    echo -e "   ${CYAN}3.${NC} Développez dans le dossier ${GREEN}$TYPE/${NC}"
    
    echo -e "\n${YELLOW}⚠️  Note:${NC} Le dossier scripts/ complet sera supprimé après validation."
}

# Auto-suppression complète du dossier scripts avec confirmation
cleanup_self() {    
    echo -e "\n${CYAN}🗑️  Scripts de développement dans scripts/:${NC}"
    if [ -d "scripts/" ]; then
        for script in scripts/*; do
            if [ -f "$script" ]; then
                script_name=$(basename "$script")
                echo -e "   ${BLUE}   • $script_name${NC}"
            fi
        done
        echo -e "   ${YELLOW}⚠️  Ces scripts seront supprimés si vous confirmez${NC}"
    fi

    self_cleanup=$(ask_yes_no "Supprimer complètement le dossier scripts/" "true")
    
    if [ "$self_cleanup" = "true" ]; then
        # Créer un script temporaire pour la suppression après la fin de ce script
        cat > /tmp/cleanup_scripts.sh << 'EOL'
#!/bin/bash
sleep 1  # Attendre que le script parent se termine
cd "$1"  # Aller dans le répertoire du projet

# Supprimer le dossier scripts/
if [ -d "scripts/" ]; then
    rm -rf "scripts/"
    if [ $? -eq 0 ]; then
        echo "✅ Dossier scripts/ complètement supprimé"
    else
        echo "⚠️  Erreur lors de la suppression. Supprimez manuellement: rm -rf scripts/"
    fi
else
    echo "ℹ️  Dossier scripts/ déjà supprimé"
fi

# Nettoyer tous les fichiers temporaires créés pendant le processus
echo "🧹 Nettoyage des fichiers temporaires..."

# Supprimer les sauvegardes créées pendant le nettoyage
if [ -f "README.md.backup" ]; then
    rm -f "README.md.backup"
    echo "   ✅ README.md.backup supprimé"
fi

if [ -f "makefile.backup" ]; then
    rm -f "makefile.backup"
    echo "   ✅ makefile.backup supprimé"
fi

# Supprimer d'autres fichiers temporaires potentiels
if [ -f ".env.local" ]; then
    rm -f ".env.local"
    echo "   ✅ .env.local supprimé"
fi

if [ -f "app/.env.local" ]; then
    rm -f "app/.env.local"
    echo "   ✅ app/.env.local supprimé"
fi

# Nettoyer les fichiers de logs temporaires
if [ -f "docker-compose.override.yml" ]; then
    rm -f "docker-compose.override.yml"
    echo "   ✅ docker-compose.override.yml supprimé"
fi

echo "✅ Nettoyage complet terminé !"

# Auto-suppression du script temporaire
rm -f /tmp/cleanup_scripts.sh
EOL
        
        chmod +x /tmp/cleanup_scripts.sh
        
        # Lancer la suppression en arrière-plan après la fin de ce script
        /tmp/cleanup_scripts.sh "$(pwd)" &
        
        echo -e "   ${GREEN}✅ Suppression programmée du dossier scripts/${NC}"
        echo -e "   ${BLUE}ℹ️  La suppression se fera après la fin de ce script${NC}"
    else
        echo -e "   ${BLUE}ℹ️  Dossier scripts/ conservé${NC}"
    fi
}

# Exécution du processus de nettoyage
main_cleanup_process() {
    confirm_cleanup
    
    echo -e "\n${GREEN}🚀 Début du nettoyage...${NC}"
    
    cleanup_docker_services
    generate_project_readme
    cleanup_makefile
    
    show_final_summary
    cleanup_self
}

# Point d'entrée principal - exécuter le nettoyage
main_cleanup_process
