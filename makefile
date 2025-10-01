# Liste des types, backends, bases de données et serveurs web disponibles
TYPES = api (JSON), app (HTML)
BACKENDS = php node go python
DBS = postgres mysql
WEBSERVERS = apache nginx
WEBSOCKET = socketio mercure (native Symfony)

# Fonction pour composer les fichiers Docker Compose
DB_PROFILE = $(shell grep DB_TYPE .env | cut -d'=' -f2 | sed 's/postgres/postgres/' | sed 's/mysql/mysql/')
COMPOSE_FILES = -f docker-compose.yml
ifeq ($(shell grep USE_MAILPIT .env | cut -d'=' -f2), true)
	COMPOSE_FILES += -f docker-compose.mailpit.yml
endif
ifeq ($(shell grep USE_WEBSOCKET .env | cut -d'=' -f2), true)
	COMPOSE_FILES += -f docker-compose.websocket.yml
endif

.PHONY: start stop build clean status logs exec mysql-cli postgres-cli mysql-query postgres-query config init-project install-wordpress clean-project help

# Commandes Docker Compose
start:
	@if [ ! -f ".env" ]; then bash scripts/files_handlers/init_env.sh; fi
	@cd docker && docker compose --env-file ../.env $(COMPOSE_FILES) up -d

stop:
	@cd docker && docker compose --env-file ../.env $(COMPOSE_FILES) down

build:
	@if [ ! -f ".env" ]; then bash scripts/files_handlers/init_env.sh; fi
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
	$(error "Usage: make exec SERVICE=<service> CMD=\"<command>\". Par exemple: make exec SERVICE=mysql CMD=\"mysql -u admin -proot\"")
endif
	@echo "🔧 Exécution dans le conteneur $(SERVICE)..."
	@cd docker && docker compose --env-file ../.env $(COMPOSE_FILES) exec $(SERVICE) $(CMD)

# Accès direct aux bases de données
mysql-cli:
	@echo "🐬 Connexion à MySQL..."
	@cd docker && docker compose --env-file ../.env $(COMPOSE_FILES) exec mysql mysql -u $(shell grep "^DB_USER=" .env | cut -d'=' -f2) -p$(shell grep "^DB_PASSWORD=" .env | cut -d'=' -f2) $(shell grep "^DB_NAME=" .env | cut -d'=' -f2)

postgres-cli:
	@echo "🐘 Connexion à PostgreSQL..."
	@cd docker && docker compose --env-file ../.env $(COMPOSE_FILES) exec postgres psql -U $(shell grep "^DB_USER=" .env | cut -d'=' -f2) -d $(shell grep "^DB_NAME=" .env | cut -d'=' -f2)

# Exécuter une requête SQL directe
mysql-query:
ifndef SQL
	$(error "Usage: make mysql-query SQL=\"<requête>\". Par exemple: make mysql-query SQL=\"SHOW DATABASES;\"")
endif
	@echo "🐬 Exécution de la requête MySQL..."
	@cd docker && docker compose --env-file ../.env $(COMPOSE_FILES) exec mysql mysql -u $(shell grep "^DB_USER=" .env | cut -d'=' -f2) -p$(shell grep "^DB_PASSWORD=" .env | cut -d'=' -f2) $(shell grep "^DB_NAME=" .env | cut -d'=' -f2) -e "$(SQL)"

postgres-query:
ifndef SQL
	$(error "Usage: make postgres-query SQL=\"<requête>\". Par exemple: make postgres-query SQL=\"\\l\"")
endif
	@echo "🐘 Exécution de la requête PostgreSQL..."
	@cd docker && docker compose --env-file ../.env $(COMPOSE_FILES) exec postgres psql -U $(shell grep "^DB_USER=" .env | cut -d'=' -f2) -d $(shell grep "^DB_NAME=" .env | cut -d'=' -f2) -c "$(SQL)"

# Afficher la configuration actuelle
config:
	@echo "⚙️  Configuration actuelle :"
	@echo "   Projet: $(shell grep "^PROJECT_NAME=" .env | cut -d'=' -f2)"
	@echo "   Type: $(shell grep "^TYPE=" .env | cut -d'=' -f2 2>/dev/null || echo 'api')"
	@echo "   Backend: $(shell grep "^BACKEND=" .env | cut -d'=' -f2) $(shell grep BACKEND_VERSION .env | cut -d'=' -f2)"
	@echo "   Serveur web: $(shell grep WEBSERVER .env | cut -d'=' -f2)"
	@echo "   Base de données: $(shell grep "^DB_TYPE=" .env | cut -d'=' -f2) $(shell grep DB_VERSION .env | cut -d'=' -f2)"
	@echo "   Mailpit: $(shell grep USE_MAILPIT .env | cut -d'=' -f2)"
	@echo "   WebSocket: $(shell grep USE_WEBSOCKET .env | cut -d'=' -f2) ($(shell grep WEBSOCKET_TYPE .env | cut -d'=' -f2))"

# Initialisation du projet
init-project:
	@echo "🚀 Initialisation du projet..."
	@if [ -f "scripts/init_project.sh" ]; then \
		bash scripts/init_project.sh; \
	else \
		echo "❌ Script scripts/init_project.sh non trouvé"; \
	fi

# Nettoyer le template
clean-project:
	@echo "🧹 Nettoyage du template pour la configuration actuelle..."
	@bash scripts/clean_project.sh $(BACKEND) $(WEBSERVER) $(DB_TYPE) $(USE_MAILPIT) $(USE_WEBSOCKET) $(TYPE)


# Installation de WordPress via WP-CLI (après build/start)
install-wordpress: build
	@echo "📚 Installation de WordPress via WP-CLI..."
	@if [ -f "scripts/presets/install_wordpress.sh" ]; then \
		bash scripts/presets/install_wordpress.sh; \
	else \
		echo "❌ Script scripts/presets/install_wordpress.sh non trouvé"; \
	fi

help:
	@echo ""
	@echo "🔧 Commandes disponibles :"
	@echo "  make config                                   # Afficher la configuration actuelle"
	@echo "  make init-project                             # Initialisation du projet"
	@echo "  make install-wordpress                        # Installation WordPress via WP-CLI (après build/start)"
	@echo "  make clean-project                            # Nettoyer le template (supprimer les éléments non utilisés par le projet)"
	@echo "  make start                                    # Démarrer l'environnement Docker"
	@echo "  make stop                                     # Arrêter les conteneurs"
	@echo "  make build                                    # Rebuilder les conteneurs"
	@echo "  make status                                   # Voir l'état des conteneurs"
	@echo "  make logs                                     # Voir les logs des conteneurs"
	@echo "  make exec SERVICE=<service> CMD=\"<command>\" # Exécuter une commande dans un conteneur"
	@echo "  make mysql-cli                                # Connexion directe à MySQL"
	@echo "  make postgres-cli                             # Connexion directe à PostgreSQL"
	@echo "  make mysql-query SQL=\"<requête>\"            # Exécuter une requête MySQL"
	@echo "  make postgres-query SQL=\"<requête>\"         # Exécuter une requête PostgreSQL"
	@echo "  make help                                     # Afficher cette aide"
	@echo ""
	@echo "🎯 Types d'application : $(TYPES)"
	@echo "📦 Backends disponibles : $(BACKENDS)"
	@echo "🗄️ Bases de données disponibles : $(DBS)"
	@echo "🌐 Serveurs web disponibles : $(WEBSERVERS)"
	@echo "🔌 WebSocket disponibles : $(WEBSOCKET)"
	@echo ""
	@echo "🎯 Options d'installation disponibles :"
	@echo "   • ⚙️ Configuration Manuelle : Configuration détaillée étape par étape"
	@echo "   • 🎯 Presets Rapides : Symfony API ou WordPress Bedrock optimisés"
