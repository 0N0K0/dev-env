# Liste des backends, bases de données et serveurs web disponibles
TYPES = api app
BACKENDS = php node go python
DBS = postgres mysql
WEBSERVERS = apache nginx

# Fonction pour composer les fichiers Docker Compose
DB_PROFILE = $(shell grep DB_TYPE .env | cut -d'=' -f2 | sed 's/postgres/postgres/' | sed 's/mysql/mysql/')
COMPOSE_FILES = -f docker-compose.yml
ifeq ($(shell grep USE_MAILPIT .env | cut -d'=' -f2), true)
	COMPOSE_FILES += -f docker-compose.mailpit.yml
endif
ifeq ($(shell grep USE_WEBSOCKET .env | cut -d'=' -f2), true)
	COMPOSE_FILES += -f docker-compose.websocket.yml
endif

.PHONY: start stop build clean switch configure clean-project status logs exec mysql-cli postgres-cli mysql-query postgres-query config help init-env reset-env

# Commandes Docker Compose
start:
	@if [ ! -f ".env" ]; then bash scripts/init_env.sh; fi
	@cd docker && docker compose --env-file ../.env $(COMPOSE_FILES) up -d

stop:
	@cd docker && docker compose --env-file ../.env $(COMPOSE_FILES) down

build:
	@if [ ! -f ".env" ]; then bash scripts/init_env.sh; fi
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
	@echo "   Backend: $(shell grep "^BACKEND=" .env | cut -d'=' -f2) $(shell grep BACKEND_VERSION .env | cut -d'=' -f2)"
	@echo "   Serveur web: $(shell grep WEBSERVER .env | cut -d'=' -f2)"
	@echo "   Base de données: $(shell grep "^DB_TYPE=" .env | cut -d'=' -f2) $(shell grep DB_VERSION .env | cut -d'=' -f2)"
	@echo "   Type: $(shell grep "^TYPE=" .env | cut -d'=' -f2 2>/dev/null || echo 'api')"
	@echo "   Mailpit: $(shell grep USE_MAILPIT .env | cut -d'=' -f2)"
	@echo "   WebSocket: $(shell grep USE_WEBSOCKET .env | cut -d'=' -f2) ($(shell grep WEBSOCKET_TYPE .env | cut -d'=' -f2))"
	@echo ""

# Configuration interactive (mode recommandé)
configure:
	@echo "🚀 Lancement du configurateur interactif..."
	@if [ -f "scripts/configure.sh" ]; then \
		bash scripts/configure.sh; \
	else \
		echo "❌ Script scripts/configure.sh non trouvé"; \
	fi

# Configuration complète (backend, DB, serveur web, mailpit, websocket)
switch:
ifeq ($(strip $(TYPE)$(BACKEND)$(DB)$(WEBSERVER)$(MAILPIT)$(WEBSOCKET)$(WEBSOCKET_TYPE)$(BACKEND_VERSION)$(DB_VERSION)$(PROJECT_NAME)),)
	$(error "Usage: make switch [PROJECT_NAME=<nom>] [TYPE=<api|app>] [BACKEND=<backend>] [BACKEND_VERSION=<ver>] [DB=<mysql|postgres>] [DB_VERSION=<ver>] [WEBSERVER=<webserver>] [MAILPIT=<true|false>] [WEBSOCKET=<true|false>] [WEBSOCKET_TYPE=<socketio|native>]. Au moins un paramètre doit être renseigné.")
endif
	@if [ ! -f ".env" ]; then bash scripts/init_env.sh; fi
	@echo "🔍 Vérification de l'état des conteneurs..."
	@if [ -f ".env" ]; then \
		RUNNING_CONTAINERS=$$(cd docker && docker compose --env-file ../.env $(COMPOSE_FILES) ps -q 2>/dev/null | wc -l); \
		if [ "$$RUNNING_CONTAINERS" -gt 0 ]; then \
			echo "⏹️  Arrêt des conteneurs en cours d'exécution..."; \
			cd docker && docker compose --env-file ../.env $(COMPOSE_FILES) down -v; \
			echo "✅ Conteneurs arrêtés"; \
		else \
			echo "✅ Aucun conteneur en cours d'exécution"; \
		fi; \
	fi
	@echo ""
ifdef PROJECT_NAME
	@sed -i.bak 's|^PROJECT_NAME=.*|PROJECT_NAME=$(PROJECT_NAME)|' .env
	@sed -i.bak 's|^DB_NAME=.*|DB_NAME=$(PROJECT_NAME)|' .env
	@echo "   Nom du projet: $(PROJECT_NAME)"
else
	@echo "   Nom du projet: $(shell grep "^PROJECT_NAME=" .env | cut -d'=' -f2) (inchangé)"
endif
ifdef TYPE
	@if ! echo "api app" | grep -wq $(TYPE); then \
		echo "Erreur: type '$(TYPE)' invalide. Choix possibles: api, app"; exit 1; \
	fi
	@sed -i.bak 's|^TYPE=.*|TYPE=$(TYPE)|' .env
	@echo "   Type: $(TYPE)"
else
	@echo "   Type: $(shell grep "^TYPE=" .env | cut -d'=' -f2) (inchangé)"
endif
ifdef BACKEND
	@if ! echo "$(BACKENDS)" | grep -wq $(BACKEND); then \
		echo "Erreur: backend '$(BACKEND)' invalide. Choix possibles: $(BACKENDS)"; exit 1; \
	fi
	@sed -i.bak 's|^BACKEND=.*|BACKEND=$(BACKEND)|' .env
	@echo "   Backend: $(BACKEND)" | tr -d '\n'
ifdef BACKEND_VERSION
	@sed -i.bak 's|^BACKEND_VERSION=.*|BACKEND_VERSION=$(BACKEND_VERSION)|' .env
	@echo " $(BACKEND_VERSION)"
else
	@case "$(BACKEND)" in \
		php) sed -i.bak 's|^BACKEND_VERSION=.*|BACKEND_VERSION=8.4|' .env; echo " 8.4 (par défaut)";; \
		node|python|go) sed -i.bak 's|^BACKEND_VERSION=.*|BACKEND_VERSION=latest|' .env; echo " latest (par défaut)";; \
	esac
endif
# Configuration gérée maintenant par generate_configs.sh
else
	@echo "   Backend: $(shell grep "^BACKEND=" .env | cut -d'=' -f2) (inchangé)"
endif
ifdef DB
	@if ! echo "$(DBS)" | grep -wq $(DB); then \
		echo "Erreur: gestionnaire de BDD '$(DB)' invalide. Choix possibles: $(DBS)"; exit 1; \
	fi
	@sed -i.bak 's|^DB_TYPE=.*|DB_TYPE=$(DB)|' .env
	@echo "   Base de données: $(DB)" | tr -d '\n'
ifdef DB
	@case "$(DB)" in \
		mysql) \
			sed -i.bak 's|^DB_PATH=.*|DB_PATH=/var/lib/mysql|' .env; \
			sed -i.bak 's|^DB_PORT=.*|DB_PORT=3306|' .env; \
			echo " (DB_PATH=/var/lib/mysql, DB_PORT=3306)";; \
		postgres) \
			sed -i.bak 's|^DB_PATH=.*|DB_PATH=/var/lib/postgresql/data|' .env; \
			sed -i.bak 's|^DB_PORT=.*|DB_PORT=5432|' .env; \
			echo " (DB_PATH=/var/lib/postgresql/data, DB_PORT=5432)";; \
	esac
endif
ifdef DB_VERSION
	@sed -i.bak 's|^DB_VERSION=.*|DB_VERSION=$(DB_VERSION)|' .env
	@echo " $(DB_VERSION)"
else
	@case "$(DB)" in \
		postgres|mysql) sed -i.bak 's|^DB_VERSION=.*|DB_VERSION=latest|' .env; echo " latest (par défaut)";; \
	esac
endif
else
	@echo "   Base de données: $(shell grep "^DB_TYPE=" .env | cut -d'=' -f2) (inchangée)"
endif
ifdef WEBSERVER
	@if ! echo "$(WEBSERVERS)" | grep -wq $(WEBSERVER); then \
		echo "Erreur: serveur web '$(WEBSERVER)' invalide. Choix possibles: $(WEBSERVERS)"; exit 1; \
	fi
	@sed -i.bak 's|^WEBSERVER=.*|WEBSERVER=$(WEBSERVER)|' .env
	@echo "   Serveur web: $(WEBSERVER)"
else
	@echo "   Serveur web: $(shell grep "^WEBSERVER=" .env | cut -d'=' -f2) (inchangé)"
endif
ifdef MAILPIT
	@sed -i.bak 's|^USE_MAILPIT=.*|USE_MAILPIT=$(MAILPIT)|' .env
	@if [ "$(MAILPIT)" = "true" ]; then \
		echo "   Mailpit: activé"; \
	else \
		echo "   Mailpit: désactivé"; \
	fi
else
	@echo "   Mailpit: $(shell grep "^USE_MAILPIT=" .env | cut -d'=' -f2) (inchangé)"
endif
ifdef WEBSOCKET
	@sed -i.bak 's|^USE_WEBSOCKET=.*|USE_WEBSOCKET=$(WEBSOCKET)|' .env
	@if [ "$(WEBSOCKET)" = "true" ]; then \
		echo "   WebSocket: activé"; \
	else \
		echo "   WebSocket: désactivé"; \
	fi
else
	@echo "   WebSocket: $(shell grep "^USE_WEBSOCKET=" .env | cut -d'=' -f2) (inchangé)"
endif
ifdef WEBSOCKET_TYPE
	@sed -i.bak 's|^WEBSOCKET_TYPE=.*|WEBSOCKET_TYPE=$(WEBSOCKET_TYPE)|' .env
	@echo "   WebSocket type: $(WEBSOCKET_TYPE)"
else
	@echo "   WebSocket type: $(shell grep "^WEBSOCKET_TYPE=" .env | cut -d'=' -f2) (inchangé)"
endif
	@rm -f .env.bak
	@echo "✅ Configuration mise à jour dans .env"
	@echo ""
	@echo "🔧 Génération du fichier d'application..."
	@if [ -f "scripts/generate_files.sh" ]; then \
		CURRENT_BACKEND=$$(grep "^BACKEND=" .env | cut -d'=' -f2); \
		CURRENT_TYPE=$$(grep "^TYPE=" .env | cut -d'=' -f2 2>/dev/null || echo 'api'); \
		bash scripts/generate_files.sh "$$CURRENT_BACKEND" "$$CURRENT_TYPE"; \
	else \
		echo "   ❌ Script scripts/generate_files.sh non trouvé"; \
	fi
	@echo ""
	@echo "🔄 Génération des configurations dynamiques..."
	@if [ -f "scripts/generate_compose.sh" ]; then \
		bash scripts/generate_compose.sh; \
	else \
		echo "   ❌ Script scripts/generate_compose.sh non trouvé"; \
	fi
	@if [ -f "scripts/generate_configs.sh" ]; then \
		bash scripts/generate_configs.sh; \
	else \
		echo "   ❌ Script scripts/generate_configs.sh non trouvé"; \
	fi
	@echo "✅ Docker Compose et configurations générés avec noms sémantiques"
	@echo ""
	@echo "🍺 Installation des outils de développement..."
	@if [ -f "scripts/install_dev_tools.sh" ]; then \
		bash scripts/install_dev_tools.sh; \
	else \
		echo "   ❌ Script scripts/install_dev_tools.sh non trouvé"; \
	fi
	@echo ""
	@echo "💡 N'oubliez pas de reconstruire les conteneurs avec 'make build' pour appliquer les changements !"

# Nettoyer le template pour un projet spécifique
clean-project:
	@echo "🧹 Nettoyage du template pour la configuration actuelle..."
	@$(eval BACKEND := $(shell grep "^BACKEND=" .env | cut -d'=' -f2))
	@$(eval WEBSERVER := $(shell grep "^WEBSERVER=" .env | cut -d'=' -f2))
	@$(eval DB_TYPE := $(shell grep "^DB_TYPE=" .env | cut -d'=' -f2))
	@$(eval TYPE := $(shell grep "^TYPE=" .env | cut -d'=' -f2 2>/dev/null || echo 'api'))
	@$(eval USE_MAILPIT := $(shell grep "^USE_MAILPIT=" .env | cut -d'=' -f2))
	@$(eval USE_WEBSOCKET := $(shell grep "^USE_WEBSOCKET=" .env | cut -d'=' -f2))
	@$(eval BACKEND_VERSION := $(shell grep "^BACKEND_VERSION=" .env | cut -d'=' -f2))
	@$(eval DB_VERSION := $(shell grep "^DB_VERSION=" .env | cut -d'=' -f2))
	@echo "   Configuration détectée: $(BACKEND) $(BACKEND_VERSION) + $(WEBSERVER) + $(DB_TYPE) $(DB_VERSION) ($(TYPE))"
	@if [ "$(USE_MAILPIT)" = "true" ]; then echo "   Mailpit: activé"; else echo "   Mailpit: désactivé"; fi
	@if [ "$(USE_WEBSOCKET)" = "true" ]; then echo "   WebSocket: activé"; else echo "   WebSocket: désactivé"; fi
	@echo ""
	@echo "🔧 Délégation du nettoyage au script shell..."
	@bash clean_project.sh $(BACKEND) $(WEBSERVER) $(DB_TYPE) $(USE_MAILPIT) $(USE_WEBSOCKET) $(TYPE)

# Initialiser le fichier .env depuis le template
init-env:
	@bash scripts/init_env.sh

# Réinitialiser complètement le fichier .env
reset-env:
	@echo "🔄 Réinitialisation du fichier .env..."
	@if [ -f ".env" ]; then \
		echo "🗑️  Suppression de l'ancien fichier .env"; \
		rm .env; \
	fi
	@bash scripts/init_env.sh
	@echo "✅ Fichier .env réinitialisé depuis le template"

help:
	@echo ""
	@echo "🔧 Commandes disponibles :"
	@echo "  make configure # 🌟 Configuration interactive (RECOMMANDÉ)"
	@echo "  make switch [PROJECT_NAME=<nom>] [TYPE=<api|app>] [BACKEND=<backend>] [BACKEND_VERSION=<ver>] [DB=<db>] [DB_VERSION=<ver>] [WEBSERVER=<web>] [MAILPIT=<true|false>] [WEBSOCKET=<true|false>] [WEBSOCKET_TYPE=<socketio|native>] # Configuration par paramètres"
	@echo "  make start     # Démarrer l'environnement Docker"
	@echo "  make stop      # Arrêter les conteneurs"
	@echo "  make build     # Rebuilder les conteneurs"
	@echo "  make status    # Voir l'état des conteneurs"
	@echo "  make logs      # Voir les logs des conteneurs"
	@echo "  make exec SERVICE=<service> CMD=\"<command>\" # Exécuter une commande dans un conteneur"
	@echo "  make mysql-cli # Connexion directe à MySQL"
	@echo "  make postgres-cli # Connexion directe à PostgreSQL"
	@echo "  make mysql-query SQL=\"<requête>\" # Exécuter une requête MySQL"
	@echo "  make postgres-query SQL=\"<requête>\" # Exécuter une requête PostgreSQL"
	@echo "  make config    # Afficher la configuration actuelle"
	@echo "  make init-env  # Initialiser le fichier .env depuis le template"
	@echo "  make reset-env # Réinitialiser complètement le fichier .env"
	@echo "  make clean-project # Nettoyer le template (supprimer les éléments non utilisés)"
	@echo "  make help      # Afficher cette aide"
	@echo ""
	@echo "📦 Backends disponibles : $(BACKENDS)"
	@echo "🗄️  Bases de données disponibles : $(DBS)"
	@echo "🌐 Serveurs web disponibles : $(WEBSERVERS)"
	@echo "🎯 Types d'application : api (JSON), app (HTML)"
	@echo "🔌 WebSocket disponibles : socketio, native"
	@echo ""
	@echo "💡 Exemples d'utilisation :"
	@echo "   # Configuration complète :"
	@echo "   make switch PROJECT_NAME=myapi BACKEND=php TYPE=api DB=mysql WEBSERVER=nginx MAILPIT=true WEBSOCKET=true WEBSOCKET_TYPE=socketio    # API complète avec WebSocket"
	@echo "   make switch PROJECT_NAME=myapp BACKEND=node TYPE=app BACKEND_VERSION=20 DB=postgres DB_VERSION=16 WEBSERVER=apache MAILPIT=false    # App Node.js avec HTML"
	@echo "   # Configuration partielle (les autres paramètres restent inchangés) :"
	@echo "   make switch TYPE=app BACKEND=python DB=postgres WEBSOCKET=true    # App + Backend + DB + WebSocket"
	@echo "   make switch BACKEND=go BACKEND_VERSION=1.21 DB=mysql     # Backend avec version + DB"
