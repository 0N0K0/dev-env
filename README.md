# 🔧 Modèle de création d'environnements de développement

Générateur d'environnements de développement Docker Compose avec **presets** et configuration automatique.

## 📑 Sommaire

-   [Fonctionnalités](#-fonctionnalités)
-   [Prérequis](#-prérequis)
-   [Utilisation du template](#-utilisation-du-template)
-   [Conseils pour le template](#-conseils-pour-le-template)
-   [Presets disponibles](#-presets-disponibles)
-   [Accès aux services](#-accès-aux-services)
-   [Commandes disponibles](#-commandes-disponibles)
-   [Configuration](#%EF%B8%8F-configuration-par-défaut)
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
-   🔌 **WebSockets** : Socket.IO ou Mercure Hub intégrés
-   🎯 **Presets** : Symfony API, WordPress Bedrock
-   🌐 **Stack complète** : Apache/Nginx + PHP/Node/Python/Go + PostgreSQL/MySQL
-   📧 **SMTP local** : Mailpit pour tester les emails
-   🔧 **Configuration contextuelle** : Optimisations selon le type de projet
-   🛠️ **Scripts d'automatisation** : Installation, configuration et nettoyage automatiques

<div align="right"><a href="#-sommaire">⬆️</a></div>

---

## 💥 Prérequis

> **Note** : Docker et Homebrew sont **installés automatiquement** pendant la configuration du projet si ils ne sont pas présents.

### 🪟 Environnement testé et recommandé

- Windows 11
- WSL2
- Ubuntu 24.04
- Oh My Zsh

- **Docker Desktop** (recommandé) : 
  - Télécharger depuis [docker.com](https://www.docker.com/products/docker-desktop)
  - **Obligatoire** : Activer l'intégration WSL2 
  - ⚡ Démarrer Docker Desktop avant d'utiliser le projet

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
make init_project
```

### 3. Nettoyer le template (supprimer les éléments non utilisés)

```bash
make clean-project
```

### 4. Construire et démarrer l'environnement

```bash
make build
```

> **Note** : La commande `make build` exécute automatiquement `docker-compose up -d --build` pour construire et démarrer tous les services en arrière-plan.

**Accès** : http://localhost

<div align="right"><a href="#-sommaire">⬆️</a></div>

---

## 💡 Conseils pour le template

-   **Commitez après clean-project** : `git add . && git commit -m "Setup project"`
-   **Modifiez le README** : Adaptez-le à votre projet spécifique après clean-project
-   **Personnalisez** : Modifiez les fichiers de configuration selon vos besoins

Synchroniser les labels, dans GitHub :

1. Cliquer sur **"Actions"**
2. Cliquer sur **"Sync Labels"**
3. Cliquer sur **"Run workflow"**

---

## 🎯 Presets disponibles

### ⚙️ Configuration manuelle
Stack sur mesure :
- Backend : PHP/Node/Python/Go
- Serveur : Apache/Nginx  
- Base : PostgreSQL/MySQL
- Services optionnels :
  - WebSocket : Socket.IO
  - Mailpit

### 🎵 Symfony API
Configuration complète avec installation automatique :
- ✅ Symfony 7
- ✅ Service optionnels :
  - Websocket : Mercure/SocketIO


### 📝 WordPress  
Stack WordPress :
- ✅ Structure Bedrock
- ✅ Services optionnels :
  - Thème de blocks
  - Blocks personnalisés avec React, Vite et Typescript

---

## 🌐 Accès aux services

| Service         | URL/Port              | Description                 |
| --------------- | --------------------- | --------------------------- |
| **Application** | http://localhost      | Votre API/APP               |
| **Mailpit**     | http://localhost:8025 | Interface email             |
| **Websocket**   | http://localhost:8001 | Interface de test Websocket |
| **SMTP**        | localhost:1025        | Serveur SMTP local          |
| **PostgreSQL**  | localhost:5432        | Base de données             |
| **MySQL**       | localhost:3306        | Base de données             |

<div align="right"><a href="#-sommaire">⬆️</a></div>

---

## 📋 Commandes disponibles

### Gestion Docker

```bash
make build              # Construire et démarrer
make start              # Démarrer
make stop               # Arrêter
make clean              # Arrêter et supprimer définitivement les conteneurs et leurs données
make status             # Voir l'état des conteneurs
make logs               # Voir les logs
make exec SERVICE=<service> CMD=<command> # Exécuter une commande dans un conteneur
```

### Configuration

```bash
make init_project       # Initialiser un projet
make clean-project      # Nettoyer les fichiers inutiles
make config             # Voir la configuration
```

### Aide

```bash
make help               # Afficher l'ensemble des commandes disponibles
```

<div align="right"><a href="#-sommaire">⬆️</a></div>

---

## ⚙️ Configuration par défaut

-   **Type** : API
-   **Backend** : PHP 8.4
-   **Serveur web** : Apache
-   **Base de données** : PostgreSQL latest
-   **Mailpit**

Le fichier `.env` est généré automatiquement par selon vos choix.

<div align="right"><a href="#-sommaire">⬆️</a></div>

---

## 📧 Gestion de Mailpit (SMTP local)

### Utilisation de Mailpit

Quand Mailpit est activé :

-   **Interface web** : http://localhost:8025
-   **Serveur SMTP** : localhost:1025

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

-   ✅ **Supprime les services** non utilisés (backends, serveurs web et websocket)
-   ✅ **Nettoie le Makefile** (supprime les commandes de template)
-   ✅ **Supprime les scripts**

### Structure après clean-project

Pour une API **PHP + Apache + MySQL**, vous aurez :

```
mon-projet/
├── 📄 Makefile
├── 📄 .env
├── 📄 README.md
├── 🗂️ docker/
    ├── docker-compose.yml
    ├── 🗂️ services/
        ├── 🗂️ php/
        ├── 🗂️ apache/
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

### Problèmes courants

**Port déjà utilisé** :
```bash
# Vérifier les ports occupés
lsof -i :80 -i :3306 -i :5432
```

**WSL2 - Permissions de fichiers** :
```bash
# Réparer les permissions dans WSL2
sudo chown -R $USER:$USER .
chmod -R 755 scripts/
```

**Docker Desktop ne démarre pas (Windows)** :
- Vérifier que WSL2 est activé
- Redémarrer Docker Desktop
- Vérifier l'intégration WSL2 dans les paramètres Docker

<div align="right"><a href="#-sommaire">⬆️</a></div>

---

## 🦆 Auteur

[@NKoelblen](https://github.com/NKoelblen) _alias_ [@0N0K0](https://github.com/0N0K0)

<div align="right"><a href="#-sommaire">⬆️</a></div>

---

## 📜 Licence

MIT License - Libre d'utilisation, modification et distribution.

<div align="right"><a href="#-sommaire">⬆️</a></div>

---
