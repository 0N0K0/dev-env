# Liste des backends, bases de données et serveurs web disponibles
BACKENDS = php node go python
DBS = pgsql mysql
WEBSERVERS = apache nginx

.PHONY: start stop build clean switch switch-webserver apache nginx status logs config cleanup help

# Commandes Docker Compose
start:
	docker-compose up -d

stop:
	docker-compose down

build:
	docker-compose build

clean:
	docker-compose down -v

# Commandes rapides pour serveurs web
apache:
	@echo "🔄 Changement vers Apache + PHP-FPM"
	@sed -i.bak 's|^WEBSERVER=.*|WEBSERVER=apache|' .env
	@rm -f .env.bak
	@echo "🔄 Redémarrage des conteneurs..."
	@docker-compose down
	@docker-compose up -d --build
	@echo "✅ Apache + PHP-FPM démarré ! Disponible sur http://localhost"

nginx:
	@echo "🔄 Changement vers Nginx + PHP-FPM"
	@sed -i.bak 's|^WEBSERVER=.*|WEBSERVER=nginx|' .env
	@rm -f .env.bak
	@echo "🔄 Redémarrage des conteneurs..."
	@docker-compose down
	@docker-compose up -d --build
	@echo "✅ Nginx + PHP-FPM démarré ! Disponible sur http://localhost"

# Commandes utilitaires
status:
	@echo "📊 État des conteneurs :"
	@docker-compose ps

logs:
	@echo "📝 Logs des conteneurs :"
	@docker-compose logs -f

# Afficher la configuration actuelle
config:
	@echo "⚙️  Configuration actuelle :"
	@echo "   Backend: $(shell grep BACKEND .env | cut -d'=' -f2)"
	@echo "   Serveur web: $(shell grep WEBSERVER .env | cut -d'=' -f2)"
	@echo "   Base de données: $(shell grep DB_TYPE .env | cut -d'=' -f2)"
	@echo ""

# Nettoyer le template pour un projet spécifique
cleanup:
	@echo "🧹 Nettoyage du template pour la configuration actuelle..."
	@$(eval BACKEND := $(shell grep BACKEND .env | cut -d'=' -f2))
	@$(eval WEBSERVER := $(shell grep WEBSERVER .env | cut -d'=' -f2))
	@$(eval DB_TYPE := $(shell grep DB_TYPE .env | cut -d'=' -f2))
	@echo "   Configuration détectée: $(BACKEND) + $(WEBSERVER) + $(DB_TYPE)"
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
	@python3 cleanup_compose.py $(BACKEND) $(WEBSERVER) $(DB_TYPE)
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
	@echo "   - .env, docker-compose.yml, makefile (simplifiés)"
	@echo ""
	@echo "🚀 Votre projet est maintenant prêt avec $(BACKEND) + $(WEBSERVER) + $(DB_TYPE) !"

# Switcher de backend et base de données
switch:
ifndef BACKEND
	$(error "Usage: make switch BACKEND=<backend> DB=<mysql|pgsql>. Disponibles: $(BACKENDS)")
endif
ifndef DB
	$(error "Usage: make switch BACKEND=<backend> DB=<mysql|pgsql>. Disponibles: $(DBS)")
endif
	@if ! echo "$(BACKENDS)" | grep -wq $(BACKEND); then \
		echo "Erreur: backend '$(BACKEND)' invalide. Choix possibles: $(BACKENDS)"; exit 1; \
	fi
	@if ! echo "$(DBS)" | grep -wq $(DB); then \
		echo "Erreur: gestionnaire de BDD '$(DB)' invalide. Choix possibles: $(DBS)"; exit 1; \
	fi
	@echo "🔄 Changement de langage backend vers $(BACKEND)"
	@sed -i.bak 's|^BACKEND=.*|BACKEND=$(BACKEND)|' .env
	@echo "🔄 Changement de Gestionnaire de BDD vers $(DB)"
	@sed -i.bak 's|^DB_TYPE=.*|DB_TYPE=$(DB)|' .env
	@rm -f .env.bak
	@echo "✅ Fichier .env mis à jour : BACKEND=$(BACKEND), DB_TYPE=$(DB)"

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
	@docker-compose down
	@docker-compose up -d --build
	@echo "✅ Terminé ! Votre application est maintenant disponible sur http://localhost avec $(WEBSERVER)"

help:
	@echo ""
	@echo "🔧 Commandes disponibles :"
	@echo "  make apache                             # Démarrer avec Apache + PHP-FPM"
	@echo "  make nginx                              # Démarrer avec Nginx + PHP-FPM"
	@echo "  make switch BACKEND=<backend> DB=<db>   # Modifier le backend et le gestionnaire de BDD"
	@echo "  make switch-webserver WEBSERVER=<web>  # Changer le serveur web (apache/nginx)"
	@echo "  make start                              # Démarrer l'environnement Docker"
	@echo "  make stop                               # Arrêter les conteneurs"
	@echo "  make build                              # Rebuilder les conteneurs"
	@echo "  make clean                              # Supprimer les conteneurs et les volumes"
	@echo "  make status                             # Voir l'état des conteneurs"
	@echo "  make logs                               # Voir les logs des conteneurs"
	@echo "  make config                             # Afficher la configuration actuelle"
	@echo "  make cleanup                            # Nettoyer le template (supprimer les éléments non utilisés)"
	@echo "  make help                               # Afficher cette aide"
	@echo ""
	@echo "📦 Backends disponibles : $(BACKENDS)"
	@echo "🗄️  Bases de données disponibles : $(DBS)"
	@echo "🌐 Serveurs web disponibles : $(WEBSERVERS)"
