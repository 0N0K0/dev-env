# 🔧 Modèle de création d'environnements de développement

Un **template repository** Docker Compose pour créer rapidement des environnements de développement avec différents langages et serveurs web. Parfait pour démarrer un nouveau projet ou prototyper une API.

## 📑 Sommaire

-   [Fonctionnalités](#-fonctionnalités)
-   [Utilisation du template](#-utilisation-du-template)
-   [Conseils pour le template](#-conseils-pour-le-template)
-   [Architecture](#%EF%B8%8F-architecture)
-   [Structure du projet](#-structure-du-projet)
-   [Accès aux services](#-accès-aux-services)
-   [Commandes disponibles](#-commandes-disponibles)
-   [Configuration](#%EF%B8%8F-configuration)
-   [Technologies incluses](#-technologies-incluses)
-   [Gestion de Mailpit (SMTP local)](#-gestion-de-mailpit-smtp-local)
-   [Que fait `make clean-project` ?](#-que-fait-make-clean-project-)
-   [Support](#-support)
-   [Auteur](#-auteur)
-   [Licence](#-licence)

---

## ✨ Fonctionnalités

-   🌐 **Serveurs web** : Apache ou Nginx
-   🚀 **Backends** : PHP (FPM), Node.js, Python ou Go
-   🗄️ **Bases de données** : PostgreSQL ou MySQL
-   📧 **SMTP local** : Mailpit
-   🔧 **Configuration flexible** : Variables d'environnement
-   🎯 **Commandes** : Makefile intégré
-   🧹 **Nettoyage automatique** : Supprime les éléments non utilisés

<div align="right"><a href="#-sommaire">⬆️</a></div>

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
make switch [BACKEND=<php|node|go|python>] [BACKEND_VERSION=<ver>] [DB=<mysql|postgres>] [DB_VERSION=<ver>] [WEBSERVER=<apache|nginx>] [MAILPIT=<true|false>] [WEBSOCKET=<true|false>] [WEBSOCKET_TYPE=<socketio|native>]
```

### 3. Nettoyer le template (supprimer les éléments non utilisés)

```bash
make clean-project
```

### 4. Démarrer l'environnement

```bash
make build
```

### 5. Accéder à l'application

-   **Application** : http://localhost
-   **Mailpit** : http://localhost:8025

<div align="right"><a href="#-sommaire">⬆️</a></div>

---

## 💡 Conseils pour le template

-   **Commitez après clean-project** : `git add . && git commit -m "Setup project with PHP+Apache+MySQL"`
-   **Modifiez le README** : Adaptez-le à votre projet spécifique après clean-project
-   **Personnalisez** : Modifiez les fichiers de configuration selon vos besoins

<div align="right"><a href="#-sommaire">⬆️</a></div>

---

## 💡 Synchroniser les Labels

Dans GitHub :

1. Cliquer sur **"Actions"**
2. Cliquer sur **"Sync Labels"**
3. Cliquer sur **"Run workflow"**

---

## 🏗️ Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Apache    │    │             │    │             │
│     ou      │───>│   PHP-FPM   │───>│ PostgreSQL  │
│   Nginx     │    │ Node/Py/Go  │    │   MySQL     │
│  (port 80)  │    │             │    │             │
└─────────────┘    └─────────────┘    └─────────────┘
```

### Services Docker

-   **web** : Serveur frontal (Apache/Nginx)
-   **api** : Backend applicatif (PHP/NodeJS/Golang/Python)
-   **db** : Base de données (PostgreSQL/MySQL)
-   **smtp** : Serveur email local (Mailpit)
-   **websocket** : Envoi de données en temps réel

<div align="right"><a href="#-sommaire">⬆️</a></div>

---

## 📁 Structure du projet

```
dev-env/
├── 📄 Makefile                        # Commandes de gestion
├── 📄 .env                            # Variables d'environnement
├── 📄 docker-compose.yml              # Configuration Docker
├── 📄 docker-compose.mailpit.yml      # Configuration Docker pour Mailpit
├── 📄 docker-compose.websocket.yml    # Configuration Docker pour Websocket
├── 📄 README.md
│
├── 🗂️ apache/                         # Configuration Apache
│   ├── Dockerfile
│   └── vhost.conf
│
├── 🗂️ nginx/                          # Configuration Nginx
│   ├── Dockerfile
│   └── nginx-default.conf             # Configuration par défaut
│   └── nginx-php.conf                 # Configuration spécifique à PHP-FPM
│   └── nginx.conf
│
├── 🗂️ php/                            # PHP-FPM
│   └── Dockerfile
│
├── 🗂️ node/                           # Node.js
│   └── Dockerfile
│
├── 🗂️ python/                         # Python
│   └── Dockerfile
│
├── 🗂️ go/                             # Go
│   └── Dockerfile
│
├── 🗂️ websocket/                      # Websocket
│   ├── Dockerfile
│   ├── server.js                      # Configuration
│   ├── package.json                   # Dépendances
│   └── index.html                     # Interface de test
│
└── 🗂️ api/                            # Code source partagé
    ├── index.php                      # Point d'entrée PHP
    ├── index.js                       # Point d'entrée Node.js
    ├── package.json                   # Dépendances Node.js
    ├── main.py                        # Point d'entrée Python
    ├── requirements.txt               # Dépendances Python
    ├── main.go                        # Point d'entrée Go
    └── go.mod                         # Module Go
```

<div align="right"><a href="#-sommaire">⬆️</a></div>

---

## 🌐 Accès aux services

| Service         | URL/Port              | Description                 |
| --------------- | --------------------- | --------------------------- |
| **Application** | http://localhost      | Votre API                   |
| **Mailpit**     | http://localhost:8025 | Interface email             |
| **Websocket**   | http://localhost:8001 | Interface de test Websocket |
| **SMTP**        | localhost:1025        | Serveur SMTP local          |
| **PostgreSQL**  | localhost:5432        | Base de données             |
| **MySQL**       | localhost:3306        | Base de données             |

<div align="right"><a href="#-sommaire">⬆️</a></div>

---

## 📋 Commandes disponibles

### Configuration

```bash
make config           # Affiche la configuration actuelle
make switch [BACKEND=<php|node|go|python>] [BACKEND_VERSION=<ver>] [DB=<mysql|postgres>] [DB_VERSION=<ver>] [WEBSERVER=<apache|nginx>] [MAILPIT=<true|false>] [WEBSOCKET=<true|false>] [WEBSOCKET_TYPE=<socketio|native>]    # Configure le projet
make clean-project    # Nettoie le template pour un projet spécifique
```

### Gestion des conteneurs

```bash
make start     # Démarre les conteneurs
make stop      # Arrête les conteneurs
make build     # Reconstruit les images et redémarre les conteneurs
make clean     # Arrête les conteneurs et nettoie la base de données
```

### Support

```bash
make help      # Aide complète
make status    # État des conteneurs
make logs      # Logs en temps réel
```

<div align="right"><a href="#-sommaire">⬆️</a></div>

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
DB_USER=admin
DB_PASSWORD=root
```

### Configuration par défaut

-   **Backend** : PHP avec PHP-FPM
-   **Serveur web** : Apache
-   **Base de données** : PostgreSQL

### Exemples de configurations

#### API REST PHP classique

```bash
make switch BACKEND=php BACKEND_VERSION=8.4 DB=mysql DB_VERSION=8.4 WEBSERVER=apache
make clean-project
make build
```

#### Application Node.js moderne

```bash
make switch BACKEND=node BACKEND_VERSION=24 DB=pgsql DB_VERSION=17 WEBSERVER=nginx
make clean-project
make build
```

#### Microservice Python

```bash
make switch BACKEND=python BACKEND_VERSION=3.13 DB=pgsql DB_VERSION=17 WEBSERVER=apache
make clean-project
make build
```

#### Service Go performant

```bash
make switch BACKEND=go BACKEND_VERSION=1.24 DB=mysql DB_VERSION=8.4 WEBSERVER=nginx
make clean-project
make build
```

<div align="right"><a href="#-sommaire">⬆️</a></div>

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

<div align="right"><a href="#-sommaire">⬆️</a></div>

---

## 📧 Gestion de Mailpit (SMTP local)

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

<div align="right"><a href="#-sommaire">⬆️</a></div>

---

## 🧹 Que fait `make clean-project` ?

La commande `make clean-project` adapte le template à votre configuration spécifique :

-   ✅ **Supprime les dossiers** des backends non utilisés (ex: si vous utilisez PHP, supprime `node/`, `python/`, `go/`)
-   ✅ **Supprime les dossiers** des serveurs web non utilisés (ex: si vous utilisez Apache, supprime `nginx/`)
-   ✅ **Nettoie les fichiers API** non utilisés dans `api/` (garde seulement le bon point d'entrée)
-   ✅ **Simplifie le docker-compose.yml** (supprime les configs inutiles)
-   ✅ **Nettoie le Makefile** (supprime les commandes de template)
-   ✅ **Adapte les variables d'environnement** à votre configuration

### Structure après clean-project

Pour un projet **PHP + Apache + MySQL**, vous aurez :

```
mon-projet/
├── 📄 Makefile              # Simplifié
├── 📄 .env                  # Votre config
├── 📄 docker-compose.yml    # Adapté à votre stack
├── 📄 README.md
├── 🗂️ apache/
├── 🗂️ php/
└── 🗂️ api/
    └── index.php
```

<div align="right"><a href="#-sommaire">⬆️</a></div>

---

## 🆘 Support

```bash
make help    # Aide complète
make config  # Configuration actuelle
make status  # État des services docker
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

### Debug PHP

```bash
# Xdebug est automatiquement configuré
# Port: 9003, Host: host.docker.internal
```

<div align="right"><a href="#-sommaire">⬆️</a></div>

---

## 😉 Auteur

[@NKoelblen](https://github.com/NKoelblen) _alias_ [@0N0K0](https://github.com/0N0K0)

<div align="right"><a href="#-sommaire">⬆️</a></div>

---

## 📜 Licence

MIT License - Libre d'utilisation, modification et distribution.

<div align="right"><a href="#-sommaire">⬆️</a></div>

---
