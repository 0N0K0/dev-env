# Liste des backends, bases de données et serveurs web disponibles
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

.PHONY: start stop build clean switch clean-project status logs config help

# Commandes Docker Compose
start:
	@docker compose $(COMPOSE_FILES) up -d

stop:
	@docker compose $(COMPOSE_FILES) down

build:
	@docker compose $(COMPOSE_FILES) up --build -d

clean:
	@docker compose $(COMPOSE_FILES) down -v

status:
	@echo "📊 État des conteneurs :"
	@docker compose $(COMPOSE_FILES) ps

logs:
	@echo "📝 Logs des conteneurs :"
	@docker compose $(COMPOSE_FILES) logs -f

# Afficher la configuration actuelle
config:
	@echo "⚙️  Configuration actuelle :"
	@echo "   Backend: $(shell grep "^BACKEND=" .env | cut -d'=' -f2) $(shell grep BACKEND_VERSION .env | cut -d'=' -f2)"
	@echo "   Serveur web: $(shell grep WEBSERVER .env | cut -d'=' -f2)"
	@echo "   Base de données: $(shell grep "^DB_TYPE=" .env | cut -d'=' -f2) $(shell grep DB_VERSION .env | cut -d'=' -f2)"
	@echo "   Mailpit: $(shell grep USE_MAILPIT .env | cut -d'=' -f2)"
	@echo "   WebSocket: $(shell grep USE_WEBSOCKET .env | cut -d'=' -f2) ($(shell grep WEBSOCKET_TYPE .env | cut -d'=' -f2))"
	@echo ""

# Configuration complète (backend, DB, serveur web, mailpit, websocket)
switch:
ifeq ($(strip $(BACKEND)$(DB)$(WEBSERVER)$(MAILPIT)$(WEBSOCKET)$(WEBSOCKET_TYPE)$(BACKEND_VERSION)$(DB_VERSION)),)
	$(error "Usage: make switch [BACKEND=<backend>] [BACKEND_VERSION=<ver>] [DB=<mysql|postgres>] [DB_VERSION=<ver>] [WEBSERVER=<webserver>] [MAILPIT=<true|false>] [WEBSOCKET=<true|false>] [WEBSOCKET_TYPE=<socketio|native>]. Au moins un paramètre doit être renseigné.")
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
ifeq ($(BACKEND),php)
	@echo "   Configuration nginx : section PHP décommentée (backend PHP)"
	@cp nginx/nginx-php.conf nginx/nginx.conf
	@echo "   Configuration nginx : section PHP commentée (backend $(BACKEND))"
else
	@echo "   Configuration nginx : section PHP commentée (backend $(BACKEND))"
	@cp nginx/nginx-default.conf nginx/nginx.conf
endif
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

# Nettoyer le template pour un projet spécifique
clean-project:
	@echo "🧹 Nettoyage du template pour la configuration actuelle..."
	@$(eval BACKEND := $(shell grep "^BACKEND=" .env | cut -d'=' -f2))
	@$(eval WEBSERVER := $(shell grep "^WEBSERVER=" .env | cut -d'=' -f2))
	@$(eval DB_TYPE := $(shell grep "^DB_TYPE=" .env | cut -d'=' -f2))
	@$(eval USE_MAILPIT := $(shell grep "^USE_MAILPIT=" .env | cut -d'=' -f2))
	@$(eval USE_WEBSOCKET := $(shell grep "^USE_WEBSOCKET=" .env | cut -d'=' -f2))
	@$(eval BACKEND_VERSION := $(shell grep "^BACKEND_VERSION=" .env | cut -d'=' -f2))
	@$(eval DB_VERSION := $(shell grep "^DB_VERSION=" .env | cut -d'=' -f2))
	@echo "   Configuration détectée: $(BACKEND) $(BACKEND_VERSION) + $(WEBSERVER) + $(DB_TYPE) $(DB_VERSION)"
	@if [ "$(USE_MAILPIT)" = "true" ]; then echo "   Mailpit: activé"; else echo "   Mailpit: désactivé"; fi
	@if [ "$(USE_WEBSOCKET)" = "true" ]; then echo "   WebSocket: activé"; else echo "   WebSocket: désactivé"; fi
	@echo ""
	@echo "� Délégation du nettoyage au script Python..."
	@python3 clean_project.py $(BACKEND) $(WEBSERVER) $(DB_TYPE) $(USE_MAILPIT) $(USE_WEBSOCKET)

help:
	@echo ""
	@echo "🔧 Commandes disponibles :"
	@echo "  make switch [BACKEND=<backend>] [BACKEND_VERSION=<ver>] [DB=<db>] [DB_VERSION=<ver>] [WEBSERVER=<web>] [MAILPIT=<true|false>] [WEBSOCKET=<true|false>] [WEBSOCKET_TYPE=<socketio|native>] # Configuration complète"
	@echo "  make start     # Démarrer l'environnement Docker"
	@echo "  make stop      # Arrêter les conteneurs"
	@echo "  make build     # Rebuilder les conteneurs"
	@echo "  make status    # Voir l'état des conteneurs"
	@echo "  make logs      # Voir les logs des conteneurs"
	@echo "  make config    # Afficher la configuration actuelle"
	@echo "  make clean-project # Nettoyer le template (supprimer les éléments non utilisés)"
	@echo "  make help      # Afficher cette aide"
	@echo ""
	@echo "📦 Backends disponibles : $(BACKENDS)"
	@echo "🗄️  Bases de données disponibles : $(DBS)"
	@echo "🌐 Serveurs web disponibles : $(WEBSERVERS)"
	@echo "🔌 WebSocket disponibles : socketio, native"
	@echo ""
	@echo "💡 Exemples d'utilisation :"
	@echo "   # Configuration complète :"
	@echo "   make switch BACKEND=php DB=mysql WEBSERVER=nginx MAILPIT=true WEBSOCKET=true WEBSOCKET_TYPE=socketio    # Stack complète avec WebSocket"
	@echo "   make switch BACKEND=node BACKEND_VERSION=20 DB=postgres DB_VERSION=16 WEBSERVER=apache MAILPIT=false WEBSOCKET=true    # Configuration complète avec versions"
	@echo "   # Configuration partielle (les autres paramètres restent inchangés) :"
	@echo "   make switch BACKEND=python DB=postgres WEBSOCKET=true    # Backend + DB + WebSocket"
	@echo "   make switch BACKEND=go BACKEND_VERSION=1.21 DB=mysql     # Backend avec version + DB"
