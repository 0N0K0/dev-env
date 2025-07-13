# 🔧 Modèle de création d'environnements de développement

Un **template repository** Docker Compose pour créer rapidement des environnements de développement avec différents langages et serveurs web. Parfait pour démarrer un nouveau projet ou prototyper une API.

## ✨ Fonctionnalités

-   🌐 **Serveurs web** : Apache ou Nginx
-   🚀 **Backends** : PHP (FPM), Node.js, Python ou Go
-   🗄️ **Bases de données** : PostgreSQL ou MySQL
-   📧 **SMTP local** : Mailpit
-   🔧 **Configuration flexible** : Variables d'environnement
-   🎯 **Commandes** : Makefile intégré
-   🧹 **Nettoyage automatique** : Supprime les éléments non utilisés

---

## 🚀 Utilisation du template

### 1. Créer un nouveau projet depuis le template

Sur GitHub :

1. Cliquer sur **"Use this template"**
2. Choisir un nom pour votre nouveau projet
3. Cloner votre nouveau repository

```bash
git clone <votre-nouveau-repo> mon-nouveau-projet
cd mon-nouveau-projet
```

### 2. Configurer pour votre projet

```bash
# Configuration complète en une commande (recommandé)
make switch BACKEND=php DB=mysql WEBSERVER=apache MAILPIT=true

# Avec versions spécifiques
make switch BACKEND=node BACKEND_VERSION=18 DB=pgsql DB_VERSION=15 WEBSERVER=nginx MAILPIT=false

# Configuration partielle (les autres paramètres restent inchangés)
make switch BACKEND=python DB=pgsql  # Juste backend + DB
```

### 3. Nettoyer le template (supprimer les éléments non utilisés)

```bash
make cleanup
```

### 4. Démarrer l'envrionnement

```bash
make start
```

### 5. Accéder à l'application

-   **Application** : http://localhost
-   **Mailpit** : http://localhost:8025

---

## 🎯 Exemples de configurations

### API REST PHP classique

```bash
make switch BACKEND=php BACKEND_VERSION=8.3 DB=mysql DB_VERSION=8.0
make switch-webserver WEBSERVER=apache
make cleanup
make start
```

### Application Node.js moderne

```bash
make switch BACKEND=node BACKEND_VERSION=20 DB=pgsql DB_VERSION=16
make switch-webserver WEBSERVER=nginx
make cleanup
make start
```

### Microservice Python

```bash
make switch BACKEND=python BACKEND_VERSION=3.12 DB=pgsql DB_VERSION=15
make switch-webserver WEBSERVER=apache
make cleanup
make start
```

### Service Go performant

```bash
make switch BACKEND=go BACKEND_VERSION=1.22 DB=mysql DB_VERSION=8.0
make switch-webserver WEBSERVER=nginx
make cleanup
make start
```

---

## 🧹 Que fait `make cleanup` ?

La commande `make cleanup` adapte le template à votre configuration spécifique :

-   ✅ **Supprime les dossiers** des backends non utilisés (ex: si vous utilisez PHP, supprime `node/`, `python/`, `go/`)
-   ✅ **Supprime les dossiers** des serveurs web non utilisés (ex: si vous utilisez Apache, supprime `nginx/`)
-   ✅ **Nettoie les fichiers API** non utilisés dans `api/` (garde seulement le bon point d'entrée)
-   ✅ **Simplifie le docker-compose.yml** (supprime les configs inutiles)
-   ✅ **Nettoie le Makefile** (supprime les commandes de template)
-   ✅ **Adapte les variables d'environnement** à votre configuration

### Structure après cleanup

Pour un projet **PHP + Apache + MySQL**, vous aurez :

```
mon-projet/
├── 📄 Makefile              # Simplifié
├── 📄 .env                  # Votre config
├── 📄 docker-compose.yml    # Adapté à votre stack
├── 📄 README.md
├── 🗂️ apache/               # Seulement Apache
├── 🗂️ php/                  # Seulement PHP
└── 🗂️ api/
    └── index.php            # Seulement le fichier PHP
```

---

## 📋 Commandes disponibles

### Démarrage rapide

```bash
make apache    # Lance Apache + PHP-FPM
make nginx     # Lance Nginx + PHP-FPM
make config    # Affiche la configuration actuelle
make help      # Aide complète
```

### Gestion des conteneurs

```bash
make start     # Démarre les conteneurs
make stop      # Arrête les conteneurs
make build     # Reconstruit les images
make clean     # Supprime tout (⚠️ perte de données)
make status    # État des conteneurs
make logs      # Logs en temps réel
```

---

## ⚙️ Configuration

La configuration se fait via le fichier `.env` :

```env
# Backend (php, node, python, go)
BACKEND=php

# Serveur web (apache, nginx)
WEBSERVER=apache

# Base de données (postgres, mysql)
DB_TYPE=postgres

# Paramètres BDD
DB_NAME=database
DB_USER=root
DB_PASSWORD=root
```

### Configuration par défaut

-   **Backend** : PHP avec PHP-FPM
-   **Serveur web** : Apache
-   **Base de données** : PostgreSQL

### Configuration en une commande

```bash
# Configuration complète avec toutes les options
make switch BACKEND=php BACKEND_VERSION=8.3 DB=mysql DB_VERSION=8.0 WEBSERVER=nginx MAILPIT=true

# Configuration rapide (versions par défaut, autres paramètres inchangés)
make switch BACKEND=node DB=pgsql WEBSERVER=apache

# Juste backend et DB (serveur web et Mailpit inchangés)
make switch BACKEND=python DB=pgsql

# Versions par défaut utilisées si non spécifiées :
# PHP: 8.3, Node.js: 20, Python: 3.12, Go: 1.22
# PostgreSQL: 16, MySQL: 8.0
```

### Configuration séparée (alternative)

Si vous préférez configurer par étapes :

```bash
# D'abord le backend et la DB
make switch BACKEND=python DB=pgsql

# Puis les versions si besoin
make set-version BACKEND_VERSION=3.11 DB_VERSION=15

# Enfin le serveur web séparément
make switch-webserver WEBSERVER=nginx

# Ou activer/désactiver Mailpit
make enable-mailpit  # ou make disable-mailpit
```

---

## 🏗️ Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Apache    │    │             │    │             │
│     ou      │───▶│   PHP-FPM   │───▶│ PostgreSQL  │
│   Nginx     │    │ Node/Py/Go  │    │   MySQL     │
│  (port 80)  │    │             │    │             │
└─────────────┘    └─────────────┘    └─────────────┘
```

### Services Docker

-   **web** : Serveur frontal (Apache/Nginx)
-   **api** : Backend applicatif
-   **db** : Base de données
-   **smtp** : Serveur email local (Mailpit)

---

## 📁 Structure du projet

```
dev-env/
├── 📄 Makefile              # Commandes de gestion
├── 📄 .env                  # Variables d'environnement
├── 📄 docker-compose.yml    # Configuration Docker
├── 📄 README.md
│
├── 🗂️ apache/               # Configuration Apache
│   ├── Dockerfile
│   └── vhost.conf
│
├── 🗂️ nginx/                # Configuration Nginx
│   ├── Dockerfile
│   └── nginx.conf
│
├── 🗂️ php/                  # PHP-FPM
│   └── Dockerfile
│
├── 🗂️ node/                 # Node.js
│   └── Dockerfile
│
├── 🗂️ python/               # Python
│   └── Dockerfile
│
├── 🗂️ go/                   # Go
│   └── Dockerfile
│
└── 🗂️ api/                  # Code source partagé
    ├── index.php            # Point d'entrée PHP
    ├── index.js             # Point d'entrée Node.js
    ├── main.py              # Point d'entrée Python
    └── main.go              # Point d'entrée Go
```

---

## 🔧 Technologies incluses

### PHP-FPM

-   **Extensions** : gd, zip, pdo, curl, mbstring, xml, etc.
-   **PECL** : redis, imagick
-   **Debug** : Xdebug (activable avec `PHP_ENABLE_XDEBUG=1`)
-   **Composer** : Gestionnaire de dépendances

### Apache

-   **Modules** : proxy, proxy_fcgi, rewrite
-   **Configuration** : Virtual host optimisé pour PHP-FPM
-   **Support** : Fichiers statiques + proxy backend

### Nginx

-   **Configuration** : Optimisée pour PHP-FPM
-   **Features** : Gestion statique, headers sécurité
-   **Performance** : Cache et compression

### Bases de données

-   **PostgreSQL** : Port 5432
-   **MySQL** : Port 3306
-   **Persistence** : Volumes Docker

---

## 🌐 Accès aux services

| Service         | URL/Port              | Description           |
| --------------- | --------------------- | --------------------- |
| **Application** | http://localhost      | Votre API/Application |
| **Mailpit**     | http://localhost:8025 | Interface email       |
| **SMTP**        | localhost:1025        | Serveur SMTP local    |
| **PostgreSQL**  | localhost:5432        | Base de données       |
| **MySQL**       | localhost:3306        | Base de données       |

---

## 🛠️ Développement

### Debug PHP

```bash
# Xdebug est automatiquement configuré
# Port: 9003, Host: host.docker.internal
```

### Logs et monitoring

```bash
# Tous les logs
make logs

# Logs spécifiques
docker-compose logs web
docker-compose logs api
docker-compose logs db
```

### Tests email

```bash
# Configurer votre app pour utiliser :
# SMTP Host: smtp (nom du service Docker)
# SMTP Port: 1025
# Voir les emails sur : http://localhost:8025
```

---

## 📜 Licence

MIT License - Libre d'utilisation, modification et distribution.

---

## 💡 Conseils pour le template

-   **Commitez après cleanup** : `git add . && git commit -m "Setup project with PHP+Apache+MySQL"`
-   **Modifiez le README** : Adaptez-le à votre projet spécifique après cleanup
-   **Configurez Git** : Supprimez les références au template si nécessaire
-   **Personnalisez** : Modifiez les fichiers de configuration selon vos besoins

---

## 🆘 Support

```bash
make help    # Aide complète
make config  # Configuration actuelle
make status  # État des services
```

**Ports par défaut** : Apache/Nginx (80), Mailpit (8025), PostgreSQL (5432), MySQL (3306)

---

## 🔢 Gestion des versions

### Configurer les versions des langages et bases de données

```bash
# Changer la version du backend
make set-version BACKEND_VERSION=8.2

# Changer backend et base de données
make set-version BACKEND_VERSION=20 DB_VERSION=15

# Exemples de versions supportées
make set-version BACKEND_VERSION=3.11    # Python 3.11
make set-version BACKEND_VERSION=1.21    # Go 1.21
make set-version BACKEND_VERSION=18      # Node.js 18
make set-version BACKEND_VERSION=8.1     # PHP 8.1
```

### Versions disponibles par technologie

| **Backend** | **Versions supportées** |
| ----------- | ----------------------- |
| **PHP**     | 8.3, 8.2, 8.1, 8.0, 7.4 |
| **Node.js** | 20, 18, 16, 14          |
| **Python**  | 3.12, 3.11, 3.10, 3.9   |
| **Go**      | 1.22, 1.21, 1.20, 1.19  |

| **Base de données** | **Versions supportées** |
| ------------------- | ----------------------- |
| **PostgreSQL**      | 16, 15, 14, 13, 12      |
| **MySQL**           | 8.0, 5.7                |

### Configuration actuelle

```bash
make config
# ⚙️  Configuration actuelle :
#    Backend: node 18
#    Serveur web: nginx
#    Base de données: postgres 16
#    Mailpit: true
```

---

## 📧 Gestion de Mailpit (SMTP local)

### Activer/Désactiver Mailpit

```bash
# Activer Mailpit pour les tests d'emails
make enable-mailpit

# Désactiver Mailpit pour économiser les ressources
make disable-mailpit

# Vérifier l'état de Mailpit
make config
```

### Utilisation de Mailpit

Quand Mailpit est activé :

-   **Interface web** : http://localhost:8025
-   **Serveur SMTP** : localhost:1025
-   **Capture tous les emails** envoyés par votre application
-   **Interface moderne** pour consulter, tester et déboguer les emails

### Configuration SMTP dans votre application

```env
MAIL_HOST=smtp
MAIL_PORT=1025
MAIL_USERNAME=
MAIL_PASSWORD=
MAIL_ENCRYPTION=null
```
