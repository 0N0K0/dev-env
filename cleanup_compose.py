#!/usr/bin/env python3
"""
Script de nettoyage du docker-compose.yml pour adapter le template 
à la configuration spécifique du projet.
"""

import re
import sys
import os
import shutil

def cleanup_docker_compose(backend, webserver, db_type, use_mailpit, use_websocket=None):
    """Nettoie le docker-compose.yml selon la configuration"""
    
    print(f"🔧 Nettoyage pour: {backend} + {webserver} + {db_type}")
    print(f"   Services optionnels: Mailpit={use_mailpit}, WebSocket={use_websocket}")
    
    # Lire le fichier docker-compose.yml
    try:
        with open('docker-compose.yml', 'r') as f:
            content = f.read()
    except FileNotFoundError:
        print("Erreur: docker-compose.yml non trouvé")
        return
    
    # 1. Simplifier les arguments de build - garder seulement celui du backend utilisé
    version_mappings = {
        'php': ['NODE_VERSION', 'PYTHON_VERSION', 'GO_VERSION'],
        'node': ['PHP_VERSION', 'PYTHON_VERSION', 'GO_VERSION'],
        'python': ['PHP_VERSION', 'NODE_VERSION', 'GO_VERSION'],
        'go': ['PHP_VERSION', 'NODE_VERSION', 'PYTHON_VERSION']
    }
    
    if backend in version_mappings:
        for version_to_remove in version_mappings[backend]:
            content = re.sub(rf'\s*{version_to_remove}:.*?\n', '', content)
    
    # 2. Nettoyer les commentaires des volumes
    content = re.sub(r'\s*# pour.*?\n', '\n', content)
    
    # 3. Gérer les volumes selon le backend
    if backend == 'php':
        # Pour PHP, garder le volume /var/www/html et supprimer /app
        content = re.sub(r'\s*- \./api:/app.*?\n', '', content)
    else:
        # Pour les autres backends, garder le volume /app et supprimer /var/www/html
        content = re.sub(r'\s*- \./api:/var/www/html.*?\n', '', content)
    
    # 4. Gérer le port PHP-FPM (seulement pour PHP)
    if backend != 'php':
        content = re.sub(r"\s*- '9000'.*?\n", '', content)
    
    # 5. Nettoyer les ports et variables de base de données
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
    
    # 6. Simplifier l'image de base de données (retirer les variables d'environnement)
    if db_type == 'postgres':
        content = re.sub(r'image: \$\{DB_TYPE\}:\$\{DB_VERSION\}', 'image: postgres:latest', content)
    elif db_type == 'mysql':
        content = re.sub(r'image: \$\{DB_TYPE\}:\$\{DB_VERSION\}', 'image: mysql:latest', content)
    
    # 7. Nettoyer les espaces multiples
    content = re.sub(r'\n\n\n+', '\n\n', content)
    
    # Sauvegarder le fichier nettoyé
    try:
        with open('docker-compose.yml', 'w') as f:
            f.write(content)
        print("   ✅ docker-compose.yml nettoyé")
    except Exception as e:
        print(f"   ❌ Erreur lors de la sauvegarde: {e}")
        return
    
    # 8. Gérer les services optionnels
    
    # Mailpit
    if use_mailpit == 'false':
        if os.path.exists('docker-compose.mailpit.yml'):
            try:
                os.remove('docker-compose.mailpit.yml')
                print("   🗑️  Suppression: docker-compose.mailpit.yml")
            except Exception as e:
                print(f"   ❌ Erreur suppression Mailpit: {e}")
    
    # WebSocket
    if use_websocket == 'false':
        # Supprimer le fichier docker-compose WebSocket
        if os.path.exists('docker-compose.websocket.yml'):
            try:
                os.remove('docker-compose.websocket.yml')
                print("   🗑️  Suppression: docker-compose.websocket.yml")
            except Exception as e:
                print(f"   ❌ Erreur suppression docker-compose.websocket.yml: {e}")
        
        # Supprimer le dossier websocket/
        if os.path.exists('websocket/'):
            try:
                shutil.rmtree('websocket/')
                print("   🗑️  Suppression: websocket/")
            except Exception as e:
                print(f"   ❌ Erreur suppression websocket/: {e}")

def main():
    """Point d'entrée principal"""
    if len(sys.argv) < 5:
        print("Usage: cleanup_compose.py <backend> <webserver> <db_type> <use_mailpit> [use_websocket]")
        print("Exemple: python3 cleanup_compose.py php apache postgres true false")
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
    cleanup_docker_compose(backend, webserver, db_type, use_mailpit, use_websocket)

if __name__ == '__main__':
    main()
