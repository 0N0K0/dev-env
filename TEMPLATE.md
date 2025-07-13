# 📋 Instructions Template Repository

Ce repository est configuré comme un **template** pour créer rapidement des environnements de développement.

## 🎯 Comment utiliser ce template

### 1. Créer un nouveau repository depuis ce template

Sur GitHub :

1. Cliquer sur **"Use this template"**
2. Choisir un nom pour votre nouveau project
3. Cloner votre nouveau repository

### 2. Configuration rapide

```bash
cd votre-nouveau-projet

# Configurer selon vos besoins (exemples) :

# Pour une API PHP classique
make switch BACKEND=php DB=mysql
make switch-webserver WEBSERVER=apache

# Pour une app Node.js moderne
make switch BACKEND=node DB=postgres
make switch-webserver WEBSERVER=nginx

# Pour un microservice Python
make switch BACKEND=python DB=postgres

# Pour un service Go
make switch BACKEND=go DB=mysql
```

### 3. Nettoyer le template

```bash
# Supprime tous les fichiers/config non utilisés
make cleanup
```

### 4. Démarrer le développement

```bash
make start
```

## 🧹 Que fait `make cleanup` ?

-   ✅ **Supprime les dossiers** des backends non utilisés (ex: si vous utilisez PHP, supprime `node/`, `python/`, `go/`)
-   ✅ **Supprime les dossiers** des serveurs web non utilisés (ex: si vous utilisez Apache, supprime `nginx/`)
-   ✅ **Nettoie les fichiers API** non utilisés dans `api/` (garde seulement le bon point d'entrée)
-   ✅ **Simplifie le docker-compose.yml** (supprime les configs inutiles)
-   ✅ **Nettoie le Makefile** (supprime les commandes de template)
-   ✅ **Adapte les variables d'environnement** à votre configuration

## 📁 Structure après cleanup

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

## 💡 Conseils

-   **Commitez après cleanup** : `git add . && git commit -m "Setup project with PHP+Apache+MySQL"`
-   **Modifiez le README** : Adaptez-le à votre projet spécifique
-   **Configurez Git** : Supprimez ce fichier `TEMPLATE.md` si vous voulez

## 🆘 Support

Si vous avez des problèmes :

1. Vérifiez que Docker et Docker Compose sont installés
2. Lancez `make help` pour voir toutes les commandes
3. Lancez `make config` pour voir votre configuration actuelle
