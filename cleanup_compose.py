#!/usr/bin/env python3
"""
Script de nettoyage du docker-compose.yml pour adapter le template 
à la configuration spécifique du projet.
"""

import re
import sys
import os

def cleanup_docker_compose(backend, webserver, db_type, use_mailpit, use_websocket=None):
    """Nettoie le docker-compose.yml selon la configuration"""
    
    with open('docker-compose.yml', 'r') as f:
        content = f.read()
    
    # Simplifier les arguments de build - garder seulement celui du backend utilisé
    if backend == 'php':
        # Garder seulement PHP_VERSION
        content = re.sub(r'\s*NODE_VERSION:.*?\n', '', content)
        content = re.sub(r'\s*PYTHON_VERSION:.*?\n', '', content)
        content = re.sub(r'\s*GO_VERSION:.*?\n', '', content)
    elif backend == 'node':
        # Garder seulement NODE_VERSION
        content = re.sub(r'\s*PHP_VERSION:.*?\n', '', content)
        content = re.sub(r'\s*PYTHON_VERSION:.*?\n', '', content)
        content = re.sub(r'\s*GO_VERSION:.*?\n', '', content)
    elif backend == 'python':
        # Garder seulement PYTHON_VERSION
        content = re.sub(r'\s*PHP_VERSION:.*?\n', '', content)
        content = re.sub(r'\s*NODE_VERSION:.*?\n', '', content)
        content = re.sub(r'\s*GO_VERSION:.*?\n', '', content)
    elif backend == 'go':
        # Garder seulement GO_VERSION
        content = re.sub(r'\s*PHP_VERSION:.*?\n', '', content)
        content = re.sub(r'\s*NODE_VERSION:.*?\n', '', content)
        content = re.sub(r'\s*PYTHON_VERSION:.*?\n', '', content)
    
    # Nettoyer les commentaires des volumes
    content = re.sub(r'\s*# pour.*?\n', '\n', content)
    
    # Gérer les volumes selon le backend
    if backend == 'php':
        # Garder seulement le volume PHP
        content = re.sub(r'\s*- \./api:/app.*?\n', '', content)
    else:
        # Garder seulement le volume non-PHP
        content = re.sub(r'\s*- \./api:/var/www/html.*?\n', '', content)
    
    # Gérer le port PHP-FPM
    if backend != 'php':
        content = re.sub(r"\s*- '9000'.*?\n", '', content)
    
    # Nettoyer les ports de base de données
    if db_type == 'postgres':
        content = re.sub(r"\s*- '3306:3306'\s*\n", '', content)
        # Supprimer les variables MySQL
        content = re.sub(r'\s*MYSQL_DATABASE:.*?\n', '', content)
        content = re.sub(r'\s*MYSQL_USER:.*?\n', '', content) 
        content = re.sub(r'\s*MYSQL_PASSWORD:.*?\n', '', content)
        content = re.sub(r'\s*MYSQL_ROOT_PASSWORD:.*?\n', '', content)
    else:  # mysql
        content = re.sub(r"\s*- '5432:5432'\s*\n", '', content)
        # Supprimer les variables PostgreSQL
        content = re.sub(r'\s*POSTGRES_DB:.*?\n', '', content)
        content = re.sub(r'\s*POSTGRES_USER:.*?\n', '', content)
        content = re.sub(r'\s*POSTGRES_PASSWORD:.*?\n', '', content)
    
    # Simplifier l'image de base de données
    content = re.sub(r'image: \$\{DB_TYPE\}:\$\{DB_VERSION\}', f'image: {db_type}:latest', content)
    
    # Nettoyer les espaces multiples
    content = re.sub(r'\n\n\n+', '\n\n', content)
    
    with open('docker-compose.yml', 'w') as f:
        f.write(content)
    
    # Gérer le fichier Mailpit
    if use_mailpit == 'false':
        if os.path.exists('docker-compose.mailpit.yml'):
            os.remove('docker-compose.mailpit.yml')
            print("   Suppression: docker-compose.mailpit.yml")
    
    # Gérer le fichier WebSocket
    if use_websocket == 'false':
        if os.path.exists('docker-compose.websocket.yml'):
            os.remove('docker-compose.websocket.yml')
            print("   Suppression: docker-compose.websocket.yml")
        if os.path.exists('websocket/'):
            import shutil
            shutil.rmtree('websocket/')
            print("   Suppression: websocket/")

if __name__ == '__main__':
    if len(sys.argv) < 5:
        print("Usage: cleanup_compose.py <backend> <webserver> <db_type> <use_mailpit> [use_websocket]")
        sys.exit(1)
    
    backend, webserver, db_type, use_mailpit = sys.argv[1:5]
    use_websocket = sys.argv[5] if len(sys.argv) > 5 else None
    cleanup_docker_compose(backend, webserver, db_type, use_mailpit, use_websocket)
