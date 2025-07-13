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

.PHONY: start stop build clean switch switch-webserver apache nginx status logs config cleanup enable-mailpit disable-mailpit enable-websocket disable-websocket set-version help

# Commandes Docker Compose
start: prepare-compose
	docker-compose $(COMPOSE_FILES) up -d

stop: prepare-compose
	docker-compose $(COMPOSE_FILES) down

build: prepare-compose
	docker-compose $(COMPOSE_FILES) build

clean: prepare-compose
	docker-compose $(COMPOSE_FILES) down -v

# Commandes rapides pour serveurs web
apache:
	@echo "🔄 Changement vers Apache + PHP-FPM"
	@sed -i.bak 's|^WEBSERVER=.*|WEBSERVER=apache|' .env
	@rm -f .env.bak
	@echo "🔄 Redémarrage des conteneurs..."
	@docker-compose $(COMPOSE_FILES) down
	@docker-compose $(COMPOSE_FILES) up -d --build
	@echo "✅ Apache + PHP-FPM démarré ! Disponible sur http://localhost"

nginx:
	@echo "🔄 Changement vers Nginx + PHP-FPM"
	@sed -i.bak 's|^WEBSERVER=.*|WEBSERVER=nginx|' .env
	@rm -f .env.bak
	@echo "🔄 Redémarrage des conteneurs..."
	@docker-compose $(COMPOSE_FILES) down
	@docker-compose $(COMPOSE_FILES) up -d --build
	@echo "✅ Nginx + PHP-FPM démarré ! Disponible sur http://localhost"

# Commandes utilitaires
status:
	@echo "📊 État des conteneurs :"
	@docker-compose $(COMPOSE_FILES) ps

logs:
	@echo "📝 Logs des conteneurs :"
	@docker-compose $(COMPOSE_FILES) logs -f

# Afficher la configuration actuelle
config:
	@echo "⚙️  Configuration actuelle :"
	@echo "   Backend: $(shell grep "^BACKEND=" .env | cut -d'=' -f2) $(shell grep BACKEND_VERSION .env | cut -d'=' -f2)"
	@echo "   Serveur web: $(shell grep WEBSERVER .env | cut -d'=' -f2)"
	@echo "   Base de données: $(shell grep "^DB_TYPE=" .env | cut -d'=' -f2) $(shell grep DB_VERSION .env | cut -d'=' -f2)"
	@echo "   Mailpit: $(shell grep USE_MAILPIT .env | cut -d'=' -f2)"
	@echo "   WebSocket: $(shell grep USE_WEBSOCKET .env | cut -d'=' -f2) ($(shell grep WEBSOCKET_TYPE .env | cut -d'=' -f2))"
	@echo ""

# Activer/Désactiver Mailpit
enable-mailpit:
	@echo "📧 Activation de Mailpit..."
	@sed -i.bak 's|^USE_MAILPIT=.*|USE_MAILPIT=true|' .env
	@rm -f .env.bak
	@echo "🔄 Redémarrage des conteneurs..."
	@docker-compose $(COMPOSE_FILES) down
	@docker-compose $(COMPOSE_FILES) up -d
	@echo "✅ Mailpit activé ! Interface disponible sur http://localhost:8025"

disable-mailpit:
	@echo "📧 Désactivation de Mailpit..."
	@sed -i.bak 's|^USE_MAILPIT=.*|USE_MAILPIT=false|' .env
	@rm -f .env.bak
	@echo "🔄 Redémarrage des conteneurs..."
	@docker-compose $(COMPOSE_FILES) down
	@docker-compose $(COMPOSE_FILES) up -d
	@echo "✅ Mailpit désactivé !"

# Activer/Désactiver WebSocket
enable-websocket:
	@echo "🔌 Activation du serveur WebSocket..."
	@sed -i.bak 's|^USE_WEBSOCKET=.*|USE_WEBSOCKET=true|' .env
	@rm -f .env.bak
	@echo "🔄 Redémarrage des conteneurs..."
	@docker-compose $(COMPOSE_FILES) down
	@docker-compose $(COMPOSE_FILES) up -d
	@echo "✅ WebSocket activé !"
	@echo "   🌐 Serveur WebSocket: http://localhost:3001"
	@echo "   🧪 Interface de test: http://localhost:3001/test.html"

disable-websocket:
	@echo "🔌 Désactivation du serveur WebSocket..."
	@sed -i.bak 's|^USE_WEBSOCKET=.*|USE_WEBSOCKET=false|' .env
	@rm -f .env.bak
	@echo "🔄 Redémarrage des conteneurs..."
	@docker-compose $(COMPOSE_FILES) down
	@docker-compose $(COMPOSE_FILES) up -d
	@echo "✅ WebSocket désactivé !"

# Nettoyer le template pour un projet spécifique
cleanup:
	@echo "🧹 Nettoyage du template pour la configuration actuelle..."
	@$(eval BACKEND := $(shell grep BACKEND .env | cut -d'=' -f2))
	@$(eval WEBSERVER := $(shell grep WEBSERVER .env | cut -d'=' -f2))
	@$(eval DB_TYPE := $(shell grep DB_TYPE .env | cut -d'=' -f2))
	@$(eval USE_MAILPIT := $(shell grep USE_MAILPIT .env | cut -d'=' -f2))
	@$(eval USE_WEBSOCKET := $(shell grep USE_WEBSOCKET .env | cut -d'=' -f2))
	@echo "   Configuration détectée: $(BACKEND) + $(WEBSERVER) + $(DB_TYPE)"
	@if [ "$(USE_MAILPIT)" = "true" ]; then echo "   Mailpit: activé"; else echo "   Mailpit: désactivé"; fi
	@if [ "$(USE_WEBSOCKET)" = "true" ]; then echo "   WebSocket: activé"; else echo "   WebSocket: désactivé"; fi
	@echo ""
	@echo "🗑️  Suppression des backends non utilisés..."
	@for backend in php node go python; do \
		if [ "$$backend" != "$(BACKEND)" ]; then \
			echo "   Suppression: $$backend/"; \
			rm -rf $$backend/; \
		fi \
	done
	@echo "🗑️  Suppression des serveurs web non utilisés..."
	@for webserver in apache nginx; do \
		if [ "$$webserver" != "$(WEBSERVER)" ]; then \
			echo "   Suppression: $$webserver/"; \
			rm -rf $$webserver/; \
		fi \
	done
	@echo "🗑️  Nettoyage des fichiers API non utilisés..."
	@cd api && for file in index.php index.js main.py main.go; do \
		case "$(BACKEND)" in \
			php) [ "$$file" != "index.php" ] && rm -f $$file;; \
			node) [ "$$file" != "index.js" ] && rm -f $$file;; \
			python) [ "$$file" != "main.py" ] && rm -f $$file;; \
			go) [ "$$file" != "main.go" ] && rm -f $$file;; \
		esac \
	done
	@echo "📝 Mise à jour du docker-compose.yml..."
	@python3 cleanup_compose.py $(BACKEND) $(WEBSERVER) $(DB_TYPE) $(USE_MAILPIT) $(USE_WEBSOCKET)
	@echo "📝 Mise à jour du Makefile..."
	@sed -i.bak '/^BACKENDS\|^WEBSERVERS\|^DBS/d' makefile
	@sed -i.bak '/^switch:/,/^$$/d' makefile
	@sed -i.bak '/^switch-webserver:/,/^$$/d' makefile
	@sed -i.bak '/^apache:/,/^$$/d' makefile
	@sed -i.bak '/^nginx:/,/^$$/d' makefile
	@sed -i.bak '/^cleanup:/,/^$$/d' makefile
	@sed -i.bak 's/switch switch-webserver apache nginx cleanup //' makefile
	@rm -f makefile.bak
	@rm -f cleanup_compose.py
	@echo "✅ Nettoyage terminé !"
	@echo ""
	@echo "📋 Fichiers conservés :"
	@echo "   - $(BACKEND)/ (backend)"
	@echo "   - $(WEBSERVER)/ (serveur web)"
	@echo "   - api/ (code source simplifié)"
	@if [ "$(USE_MAILPIT)" = "true" ]; then echo "   - docker-compose.mailpit.yml (Mailpit activé)"; fi
	@if [ "$(USE_WEBSOCKET)" = "true" ]; then echo "   - websocket/ et docker-compose.websocket.yml (WebSocket activé)"; fi
	@echo "   - .env, docker-compose.yml, makefile (simplifiés)"
	@echo ""
	@echo "🚀 Votre projet est maintenant prêt avec $(BACKEND) + $(WEBSERVER) + $(DB_TYPE)"
	@if [ "$(USE_MAILPIT)" = "true" ] || [ "$(USE_WEBSOCKET)" = "true" ]; then echo -n " + services optionnels :"; fi
	@if [ "$(USE_MAILPIT)" = "true" ]; then echo -n " Mailpit"; fi
	@if [ "$(USE_WEBSOCKET)" = "true" ]; then echo -n " WebSocket"; fi
	@echo " !"

# Configuration complète (backend, DB, serveur web, mailpit, websocket)
switch:
ifndef BACKEND
	$(error "Usage: make switch BACKEND=<backend> DB=<mysql|postgres> [WEBSERVER=<webserver>] [MAILPIT=<true|false>] [WEBSOCKET=<true|false>] [WEBSOCKET_TYPE=<socketio|native>] [BACKEND_VERSION=<ver>] [DB_VERSION=<ver>]. Disponibles: $(BACKENDS)")
endif
ifndef DB
	$(error "Usage: make switch BACKEND=<backend> DB=<mysql|postgres> [WEBSERVER=<webserver>] [MAILPIT=<true|false>] [WEBSOCKET=<true|false>] [WEBSOCKET_TYPE=<socketio|native>] [BACKEND_VERSION=<ver>] [DB_VERSION=<ver>]. Disponibles: $(DBS)")
endif
	@if ! echo "$(BACKENDS)" | grep -wq $(BACKEND); then \
		echo "Erreur: backend '$(BACKEND)' invalide. Choix possibles: $(BACKENDS)"; exit 1; \
	fi
	@if ! echo "$(DBS)" | grep -wq $(DB); then \
		echo "Erreur: gestionnaire de BDD '$(DB)' invalide. Choix possibles: $(DBS)"; exit 1; \
	fi
ifdef WEBSERVER
	@if ! echo "$(WEBSERVERS)" | grep -wq $(WEBSERVER); then \
		echo "Erreur: serveur web '$(WEBSERVER)' invalide. Choix possibles: $(WEBSERVERS)"; exit 1; \
	fi
endif
	@echo "🔄 Configuration complète en cours..."
	@sed -i.bak 's|^BACKEND=.*|BACKEND=$(BACKEND)|' .env
	@sed -i.bak 's|^DB_TYPE=.*|DB_TYPE=$(DB)|' .env
	@echo "   Backend: $(BACKEND)" | tr -d '\n'
ifdef BACKEND_VERSION
	@sed -i.bak 's|^BACKEND_VERSION=.*|BACKEND_VERSION=$(BACKEND_VERSION)|' .env
	@echo " $(BACKEND_VERSION)"
else
	@case "$(BACKEND)" in \
		php) sed -i.bak 's|^BACKEND_VERSION=.*|BACKEND_VERSION=8.3|' .env; echo " 8.3 (défaut)";; \
		node) sed -i.bak 's|^BACKEND_VERSION=.*|BACKEND_VERSION=20|' .env; echo " 20 (défaut)";; \
		python) sed -i.bak 's|^BACKEND_VERSION=.*|BACKEND_VERSION=3.12|' .env; echo " 3.12 (défaut)";; \
		go) sed -i.bak 's|^BACKEND_VERSION=.*|BACKEND_VERSION=1.22|' .env; echo " 1.22 (défaut)";; \
	esac
endif
	@echo "   Base de données: $(DB)" | tr -d '\n'
ifdef DB_VERSION
	@sed -i.bak 's|^DB_VERSION=.*|DB_VERSION=$(DB_VERSION)|' .env
	@echo " $(DB_VERSION)"
else
	@case "$(DB)" in \
		postgres) sed -i.bak 's|^DB_VERSION=.*|DB_VERSION=16|' .env; echo " 16 (défaut)";; \
		mysql) sed -i.bak 's|^DB_VERSION=.*|DB_VERSION=8.0|' .env; echo " 8.0 (défaut)";; \
	esac
endif
ifdef WEBSERVER
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

# Switcher de serveur web
switch-webserver:
ifndef WEBSERVER
	$(error "Usage: make switch-webserver WEBSERVER=<webserver>. Disponibles: $(WEBSERVERS)")
endif
	@if ! echo "$(WEBSERVERS)" | grep -wq $(WEBSERVER); then \
		echo "Erreur: serveur web '$(WEBSERVER)' invalide. Choix possibles: $(WEBSERVERS)"; exit 1; \
	fi
	@echo "🔄 Changement de serveur web vers $(WEBSERVER)"
	@sed -i.bak 's|^WEBSERVER=.*|WEBSERVER=$(WEBSERVER)|' .env
	@rm -f .env.bak
	@echo "✅ Fichier .env mis à jour : WEBSERVER=$(WEBSERVER)"
	@echo "🔄 Redémarrage des conteneurs..."
	@docker-compose $(COMPOSE_FILES) down
	@docker-compose $(COMPOSE_FILES) up -d --build
	@echo "✅ Terminé ! Votre application est maintenant disponible sur http://localhost avec $(WEBSERVER)"

# Configurer les versions du backend et de la base de données
set-version:
ifndef BACKEND_VERSION
	$(error "Usage: make set-version BACKEND_VERSION=<version> [DB_VERSION=<version>]")
endif
	@echo "🔢 Configuration des versions..."
	@sed -i.bak 's|^BACKEND_VERSION=.*|BACKEND_VERSION=$(BACKEND_VERSION)|' .env
ifdef DB_VERSION
	@sed -i.bak 's|^DB_VERSION=.*|DB_VERSION=$(DB_VERSION)|' .env
	@echo "   Backend: $(shell grep "^BACKEND=" .env | cut -d'=' -f2) $(BACKEND_VERSION)"
	@echo "   Base de données: $(shell grep "^DB_TYPE=" .env | cut -d'=' -f2) $(DB_VERSION)"
else
	@echo "   Backend: $(shell grep "^BACKEND=" .env | cut -d'=' -f2) $(BACKEND_VERSION)"
	@echo "   Base de données: $(shell grep "^DB_TYPE=" .env | cut -d'=' -f2) $(shell grep DB_VERSION .env | cut -d'=' -f2) (inchangée)"
endif
	@rm -f .env.bak
	@echo "✅ Versions mises à jour dans .env"

help:
	@echo ""
	@echo "🔧 Commandes disponibles :"
	@echo "  make apache                             # Démarrer avec Apache + PHP-FPM"
	@echo "  make nginx                              # Démarrer avec Nginx + PHP-FPM"
	@echo "  make switch BACKEND=<backend> DB=<db> [WEBSERVER=<web>] [MAILPIT=<true|false>] [WEBSOCKET=<true|false>] [WEBSOCKET_TYPE=<socketio|native>] [BACKEND_VERSION=<ver>] [DB_VERSION=<ver>] # Configuration complète"
	@echo "  make switch-webserver WEBSERVER=<web>  # Changer le serveur web (apache/nginx)"
	@echo "  make set-version BACKEND_VERSION=<ver> [DB_VERSION=<ver>] # Configurer les versions seulement"
	@echo "  make start                              # Démarrer l'environnement Docker"
	@echo "  make stop                               # Arrêter les conteneurs"
	@echo "  make build                              # Rebuilder les conteneurs"
	@echo "  make clean                              # Supprimer les conteneurs et les volumes"
	@echo "  make status                             # Voir l'état des conteneurs"
	@echo "  make logs                               # Voir les logs des conteneurs"
	@echo "  make config                             # Afficher la configuration actuelle"
	@echo "  make enable-mailpit                     # Activer Mailpit (SMTP local)"
	@echo "  make disable-mailpit                    # Désactiver Mailpit"
	@echo "  make enable-websocket                   # Activer le serveur WebSocket"
	@echo "  make disable-websocket                  # Désactiver le serveur WebSocket"
	@echo "  make cleanup                            # Nettoyer le template (supprimer les éléments non utilisés)"
	@echo "  make help                               # Afficher cette aide"
	@echo ""
	@echo "📦 Backends disponibles : $(BACKENDS)"
	@echo "🗄️  Bases de données disponibles : $(DBS)"
	@echo "🌐 Serveurs web disponibles : $(WEBSERVERS)"
	@echo "🔌 WebSocket disponibles : socketio, native"
	@echo ""
	@echo "🔢 Exemples de versions supportées :"
	@echo "   PHP: 8.3, 8.2, 8.1, 7.4"
	@echo "   Node.js: 20, 18, 16"
	@echo "   Python: 3.12, 3.11, 3.10"
	@echo "   Go: 1.22, 1.21, 1.20"
	@echo "   PostgreSQL: 16, 15, 14, 13"
	@echo "   MySQL: 8.0, 5.7"
	@echo ""
	@echo "💡 Exemples d'utilisation :"
	@echo "   # Configuration complète :"
	@echo "   make switch BACKEND=php DB=mysql WEBSERVER=nginx MAILPIT=true WEBSOCKET=true WEBSOCKET_TYPE=socketio    # Stack complète avec WebSocket"
	@echo "   make switch BACKEND=node BACKEND_VERSION=20 DB=postgres DB_VERSION=16 WEBSERVER=apache MAILPIT=false WEBSOCKET=true # Configuration complète avec versions"
	@echo "   # Configuration partielle (les autres paramètres restent inchangés) :"
	@echo "   make switch BACKEND=python DB=postgres WEBSOCKET=true                                                        # Backend + DB + WebSocket"
	@echo "   make switch BACKEND=go BACKEND_VERSION=1.21 DB=mysql                                                      # Backend avec version + DB"
