#!/usr/bin/env python3
"""
Script de nettoyage du docker-compose.yml pour adapter le template 
à la configuration spécifique du projet.
"""

import re
import sys
import os
import shutil

def clean_project(backend, webserver, db_type, use_mailpit, use_websocket=None):
    """Nettoie complètement le projet selon la configuration"""
    
    print(f"🔧 Nettoyage pour: {backend} + {webserver} + {db_type}")
    print(f"   Services optionnels: Mailpit={use_mailpit}, WebSocket={use_websocket}")
    
    # 1. Suppression des backends non utilisés
    print("🗑️  Suppression des backends non utilisés...")
    all_backends = ['php', 'node', 'go', 'python']
    for unused_backend in all_backends:
        if unused_backend != backend:
            backend_path = unused_backend
            if os.path.exists(backend_path):
                try:
                    shutil.rmtree(backend_path)
                    print(f"   Suppression: {unused_backend}/")
                except Exception as e:
                    print(f"   ❌ Erreur suppression {unused_backend}/: {e}")
    
    # 2. Suppression des serveurs web non utilisés  
    print("🗑️  Suppression des serveurs web non utilisés...")
    all_webservers = ['apache', 'nginx']
    for unused_webserver in all_webservers:
        if unused_webserver != webserver:
            webserver_path = unused_webserver
            if os.path.exists(webserver_path):
                try:
                    shutil.rmtree(webserver_path)
                    print(f"   Suppression: {unused_webserver}/")
                except Exception as e:
                    print(f"   ❌ Erreur suppression {unused_webserver}/: {e}")
    
    # 3. Nettoyage des fichiers de configuration nginx
    if webserver == 'nginx':
        print("🗑️  Nettoyage des fichiers de configuration nginx...")
        nginx_templates = ['nginx/nginx-php.conf', 'nginx/nginx-default.conf']
        for template in nginx_templates:
            if os.path.exists(template):
                try:
                    os.remove(template)
                    print(f"   Suppression: {template} (configuration template)")
                except Exception as e:
                    print(f"   ❌ Erreur suppression {template}: {e}")
    
    # 4. Nettoyage des fichiers API non utilisés
    print("🗑️  Nettoyage des fichiers API non utilisés...")
    api_files = ['index.php', 'index.js', 'main.py', 'main.go']
    backend_file_mapping = {
        'php': 'index.php',
        'node': 'index.js', 
        'python': 'main.py',
        'go': 'main.go'
    }
    
    if backend in backend_file_mapping:
        keep_file = backend_file_mapping[backend]
        for api_file in api_files:
            if api_file != keep_file:
                file_path = os.path.join('api', api_file)
                if os.path.exists(file_path):
                    try:
                        os.remove(file_path)
                        print(f"   Suppression: api/{api_file}")
                    except Exception as e:
                        print(f"   ❌ Erreur suppression api/{api_file}: {e}")
    
    # 5. Nettoyage du docker-compose.yml
    print("📝 Mise à jour du docker-compose.yml...")
    
    # Lire le fichier docker-compose.yml
    try:
        with open('docker-compose.yml', 'r') as f:
            content = f.read()
    except FileNotFoundError:
        print("   ❌ Erreur: docker-compose.yml non trouvé")
        return
    
    # Simplifier les arguments de build - garder seulement celui du backend utilisé
    version_mappings = {
        'php': ['NODE_VERSION', 'PYTHON_VERSION', 'GO_VERSION'],
        'node': ['PHP_VERSION', 'PYTHON_VERSION', 'GO_VERSION'],
        'python': ['PHP_VERSION', 'NODE_VERSION', 'GO_VERSION'],
        'go': ['PHP_VERSION', 'NODE_VERSION', 'PYTHON_VERSION']
    }
    
    if backend in version_mappings:
        for version_to_remove in version_mappings[backend]:
            content = re.sub(rf'\s*{version_to_remove}:.*?\n', '', content)
    
    # Nettoyer les commentaires des volumes
    content = re.sub(r'\s*# pour.*?\n', '\n', content)
    
    # Gérer les volumes selon le backend
    if backend == 'php':
        # Pour PHP, garder le volume /var/www/html et supprimer /app
        content = re.sub(r'\s*- \./api:/app.*?\n', '', content)
    else:
        # Pour les autres backends, garder le volume /app et supprimer /var/www/html
        content = re.sub(r'\s*- \./api:/var/www/html.*?\n', '', content)
    
    # Gérer le port PHP-FPM (seulement pour PHP)
    if backend != 'php':
        content = re.sub(r"\s*- '9000'.*?\n", '', content)
    
    # Nettoyer les ports et variables de base de données
    if db_type == 'postgres':
        # Supprimer les éléments MySQL
        content = re.sub(r"\s*- '3306:3306'\s*\n", '', content)
        content = re.sub(r'\s*MYSQL_DATABASE:.*?\n', '', content)
        content = re.sub(r'\s*MYSQL_USER:.*?\n', '', content) 
        content = re.sub(r'\s*MYSQL_PASSWORD:.*?\n', '', content)
        content = re.sub(r'\s*MYSQL_ROOT_PASSWORD:.*?\n', '', content)
    elif db_type == 'mysql':
        # Supprimer les éléments PostgreSQL
        content = re.sub(r"\s*- '5432:5432'\s*\n", '', content)
        content = re.sub(r'\s*POSTGRES_DB:.*?\n', '', content)
        content = re.sub(r'\s*POSTGRES_USER:.*?\n', '', content)
        content = re.sub(r'\s*POSTGRES_PASSWORD:.*?\n', '', content)
    
    # Simplifier l'image de base de données (retirer les variables d'environnement)
    if db_type == 'postgres':
        content = re.sub(r'image: \$\{DB_TYPE\}:\$\{DB_VERSION\}', 'image: postgres:latest', content)
    elif db_type == 'mysql':
        content = re.sub(r'image: \$\{DB_TYPE\}:\$\{DB_VERSION\}', 'image: mysql:latest', content)
    
    # Nettoyer les espaces multiples
    content = re.sub(r'\n\n\n+', '\n\n', content)
    
    # Sauvegarder le fichier nettoyé
    try:
        with open('docker-compose.yml', 'w') as f:
            f.write(content)
        print("   ✅ docker-compose.yml nettoyé")
    except Exception as e:
        print(f"   ❌ Erreur lors de la sauvegarde: {e}")
        return
        
    # 6. Nettoyer les fichiers de dépendances non utilisés dans /api
    print("🗑️  Nettoyage des fichiers de dépendances dans /api...")
    
    # Fichiers à supprimer selon le backend
    dependency_files = {
        'php': ['go.mod', 'go.sum', 'package.json', 'package-lock.json', 'requirements.txt'],
        'node': ['go.mod', 'go.sum', 'requirements.txt', 'composer.json', 'composer.lock'],
        'python': ['go.mod', 'go.sum', 'package.json', 'package-lock.json', 'composer.json', 'composer.lock'],
        'go': ['package.json', 'package-lock.json', 'requirements.txt', 'composer.json', 'composer.lock']
    }
    
    # Dossiers à supprimer selon le backend
    dependency_dirs = {
        'php': ['node_modules', '__pycache__'],
        'node': ['__pycache__', 'vendor'],
        'python': ['node_modules', 'vendor'],
        'go': ['node_modules', '__pycache__', 'vendor']
    }
    
    if backend in dependency_files:
        for file_to_remove in dependency_files[backend]:
            file_path = os.path.join('api', file_to_remove)
            if os.path.exists(file_path):
                try:
                    os.remove(file_path)
                    print(f"   Suppression: api/{file_to_remove}")
                except Exception as e:
                    print(f"   ❌ Erreur suppression api/{file_to_remove}: {e}")
    
    if backend in dependency_dirs:
        for dir_to_remove in dependency_dirs[backend]:
            dir_path = os.path.join('api', dir_to_remove)
            if os.path.exists(dir_path):
                try:
                    # Première tentative : suppression directe avec gestion des permissions
                    def remove_readonly(func, path, exc_info):
                        """Callback pour forcer la suppression des fichiers en lecture seule"""
                        try:
                            os.chmod(path, 0o777)
                            func(path)
                        except:
                            pass
                    
                    shutil.rmtree(dir_path, onerror=remove_readonly)
                    print(f"   Suppression: api/{dir_to_remove}/")
                except Exception as e:
                    print(f"   ❌ Erreur suppression api/{dir_to_remove}/: {e}")
                    # Deuxième tentative : modification récursive des permissions puis suppression
                    try:
                        print(f"   � Modification des permissions pour api/{dir_to_remove}/...")
                        for root, dirs, files in os.walk(dir_path):
                            for d in dirs:
                                os.chmod(os.path.join(root, d), 0o777)
                            for f in files:
                                os.chmod(os.path.join(root, f), 0o777)
                        os.chmod(dir_path, 0o777)
                        shutil.rmtree(dir_path)
                        print(f"   ✅ Suppression réussie: api/{dir_to_remove}/")
                    except Exception as perm_error:
                        print(f"   ❌ Impossible de supprimer api/{dir_to_remove}/")
                        print(f"   💡 Exécutez manuellement: sudo rm -rf api/{dir_to_remove}/")
                        # Ne pas bloquer le script, continuer avec les autres suppressions
        
    # 7. Gérer les services optionnels
    
    # Mailpit
    if use_mailpit == 'false':
        if os.path.exists('docker-compose.mailpit.yml'):
            try:
                os.remove('docker-compose.mailpit.yml')
                print("🗑️  Suppression: docker-compose.mailpit.yml")
            except Exception as e:
                print(f"   ❌ Erreur suppression Mailpit: {e}")
    
    # WebSocket
    if use_websocket == 'false':
        # Supprimer le fichier docker-compose WebSocket
        if os.path.exists('docker-compose.websocket.yml'):
            try:
                os.remove('docker-compose.websocket.yml')
                print("🗑️  Suppression: docker-compose.websocket.yml")
            except Exception as e:
                print(f"   ❌ Erreur suppression docker-compose.websocket.yml: {e}")
        
        # Supprimer le dossier websocket/
        if os.path.exists('websocket/'):
            try:
                shutil.rmtree('websocket/')
                print("🗑️  Suppression: websocket/")
            except Exception as e:
                print(f"   ❌ Erreur suppression websocket/: {e}")
    
    # 8. Nettoyage final du Makefile (auto-suppression des sections de template)
    print("📝 Mise à jour du Makefile...")
    
    makefile_path = 'makefile'
    if os.path.exists(makefile_path):
        try:
            # Lire le contenu du Makefile
            with open(makefile_path, 'r') as f:
                makefile_content = f.read()
            
            # Supprimer les listes de choix (BACKENDS, WEBSERVERS, DBS)
            makefile_content = re.sub(r'^BACKENDS\s*=.*?\n', '', makefile_content, flags=re.MULTILINE)
            makefile_content = re.sub(r'^WEBSERVERS\s*=.*?\n', '', makefile_content, flags=re.MULTILINE)
            makefile_content = re.sub(r'^DBS\s*=.*?\n', '', makefile_content, flags=re.MULTILINE)
            
            # Supprimer la target switch complète (de switch: jusqu'à la prochaine target ou fin)
            makefile_content = re.sub(r'^switch:.*?(?=^\w+:|$)', '', makefile_content, flags=re.MULTILINE | re.DOTALL)
            
            # Supprimer la target clean-project complète
            makefile_content = re.sub(r'^clean-project:.*?(?=^\w+:|$)', '', makefile_content, flags=re.MULTILINE | re.DOTALL)
            
            # Supprimer switch et clean-project de la première ligne s'ils y sont
            makefile_content = re.sub(r'\bswitch\s+clean-project\s*', '', makefile_content)
            makefile_content = re.sub(r'\bswitch\s*', '', makefile_content)
            makefile_content = re.sub(r'\bclean-project\s*', '', makefile_content)
            
            # Nettoyer les lignes vides multiples
            makefile_content = re.sub(r'\n\n\n+', '\n\n', makefile_content)
            
            # Sauvegarder le Makefile simplifié
            with open(makefile_path, 'w') as f:
                f.write(makefile_content)
            
            print("   ✅ Makefile simplifié")
            
        except Exception as e:
            print(f"   ❌ Erreur lors de la simplification du Makefile: {e}")
    
    # 9. Auto-suppression du script
    print("🗑️  Auto-suppression du script de nettoyage...")
    script_path = os.path.abspath(__file__)
    try:
        os.remove(script_path)
        print("   ✅ clean_project.py supprimé")
    except Exception as e:
        print(f"   ❌ Erreur auto-suppression: {e}")
    
    print("\n✅ Nettoyage terminé !")
    print(f"\n📋 Fichiers conservés :")
    print(f"   - {backend}/ (backend)")
    print(f"   - {webserver}/ (serveur web)")
    print(f"   - api/ (code source simplifié)")
    if use_mailpit == 'true':
        print("   - docker-compose.mailpit.yml (Mailpit activé)")
    if use_websocket == 'true':
        print("   - websocket/ et docker-compose.websocket.yml (WebSocket activé)")
    print("   - .env, docker-compose.yml, makefile (simplifiés)")
    print(f"\n🚀 Votre projet est maintenant prêt avec {backend} + {webserver} + {db_type}")
    if use_mailpit == 'true' or use_websocket == 'true':
        print(" + services optionnels :", end="")
        if use_mailpit == 'true':
            print(" Mailpit", end="")
        if use_websocket == 'true':
            print(" WebSocket", end="")
        print(" !")

def main():
    """Point d'entrée principal"""
    if len(sys.argv) < 5:
        print("Usage: clean_project.py <backend> <webserver> <db_type> <use_mailpit> [use_websocket]")
        print("Exemple: python3 clean_project.py php apache postgres true false")
        sys.exit(1)
    
    # Récupération des arguments
    backend = sys.argv[1]
    webserver = sys.argv[2]
    db_type = sys.argv[3]
    use_mailpit = sys.argv[4]
    use_websocket = sys.argv[5] if len(sys.argv) > 5 else None
    
    # Validation des arguments
    valid_backends = ['php', 'node', 'python', 'go']
    valid_webservers = ['apache', 'nginx']
    valid_db_types = ['postgres', 'mysql']
    valid_bool_values = ['true', 'false']
    
    if backend not in valid_backends:
        print(f"Erreur: backend '{backend}' invalide. Choix: {', '.join(valid_backends)}")
        sys.exit(1)
    
    if webserver not in valid_webservers:
        print(f"Erreur: webserver '{webserver}' invalide. Choix: {', '.join(valid_webservers)}")
        sys.exit(1)
    
    if db_type not in valid_db_types:
        print(f"Erreur: db_type '{db_type}' invalide. Choix: {', '.join(valid_db_types)}")
        sys.exit(1)
    
    if use_mailpit not in valid_bool_values:
        print(f"Erreur: use_mailpit '{use_mailpit}' invalide. Choix: {', '.join(valid_bool_values)}")
        sys.exit(1)
    
    if use_websocket and use_websocket not in valid_bool_values:
        print(f"Erreur: use_websocket '{use_websocket}' invalide. Choix: {', '.join(valid_bool_values)}")
        sys.exit(1)
    
    # Lancement du nettoyage
    clean_project(backend, webserver, db_type, use_mailpit, use_websocket)

if __name__ == '__main__':
    main()
