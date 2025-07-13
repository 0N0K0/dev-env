# 🔧 Multi-Backend Development Environment Template

Un **template repository** Docker Compose pour créer rapidement des environnements de développement avec différents langages et serveurs web. Parfait pour démarrer un nouveau projet ou prototyper une API.

## ✨ Fonctionnalités

-   🌐 **Serveurs web** : Apache ou Nginx (commutation facile)
-   🚀 **Backends** : PHP (FPM), Node.js, Python, Go
-   🗄️ **Bases de données** : PostgreSQL ou MySQL
-   📧 **SMTP local** : Mailpit pour les tests d'emails
-   🔧 **Configuration flexible** : Variables d'environnement
-   🎯 **Commandes simples** : Makefile intégré
-   🧹 **Nettoyage automatique** : Supprime les éléments non utilisés

---

## 🚀 Utilisation du template

### 1. Créer un nouveau projet depuis le template

```bash
# Utiliser GitHub "Use this template" ou :
git clone <template-repo> mon-nouveau-projet
cd mon-nouveau-projet
```

### 2. Configurer pour votre projet

```bash
# Exemple : PHP + Apache + MySQL
make switch BACKEND=php DB=mysql
make switch-webserver WEBSERVER=apache

# Ou Node.js + Nginx + PostgreSQL
make switch BACKEND=node DB=postgres
make switch-webserver WEBSERVER=nginx
```

### 3. Nettoyer le template (supprimer les éléments non utilisés)

```bash
make cleanup
```

### 4. Démarrer le développement

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
make switch BACKEND=php DB=mysql
make switch-webserver WEBSERVER=apache
make cleanup
make start
```

### Application Node.js moderne

```bash
make switch BACKEND=node DB=postgres
make switch-webserver WEBSERVER=nginx
make cleanup
make start
```

### Microservice Python

```bash
make switch BACKEND=python DB=postgres
make switch-webserver WEBSERVER=apache
make cleanup
make start
```

### Service Go performant

```bash
make switch BACKEND=go DB=mysql
make switch-webserver WEBSERVER=nginx
make cleanup
make start
```

---

### 3. Ou avec Nginx

```bash
make nginx
```

### 4. Accéder à l'application

-   **Application** : http://localhost
-   **Mailpit** : http://localhost:8025

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

### Exemples de changement de configuration

```bash
# Setup Node.js + MySQL + Nginx
make switch BACKEND=node DB=mysql
make nginx

# Setup Python + PostgreSQL + Apache
make switch BACKEND=python DB=postgres
make apache

# Voir la config actuelle
make config
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

## 🎯 Cas d'usage

### API REST en PHP

```bash
make apache
# Développer dans api/index.php
```

### Application Node.js

```bash
make switch BACKEND=node DB=mysql
make nginx
# Développer dans api/index.js
```

### Microservice Python

```bash
make switch BACKEND=python DB=postgres
make apache
# Développer dans api/main.py
```

### Service Go

```bash
make switch BACKEND=go DB=mysql
make nginx
# Développer dans api/main.go
```

---

## 📜 Licence

MIT License - Libre d'utilisation, modification et distribution.

---

## 🆘 Support

```bash
make help    # Aide complète
make config  # Configuration actuelle
make status  # État des services
```

**Ports par défaut** : Apache/Nginx (80), Mailpit (8025), PostgreSQL (5432), MySQL (3306)
