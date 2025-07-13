#!/usr/bin/env python3
"""
Script pour ajuster dynamiquement docker-compose.yml selon la configuration .env
"""
import os
import re
import sys

def read_env_file():
    """Lit le fichier .env et retourne un dictionnaire des variables"""
    env_vars = {}
    try:
        with open('.env', 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    env_vars[key] = value
    except FileNotFoundError:
        print("Erreur: fichier .env non trouvé")
        sys.exit(1)
    return env_vars

def get_db_image_name(db_type):
    """Mappe le type de DB interne vers le nom d'image Docker"""
    mapping = {
        'pgsql': 'postgres',
        'mysql': 'mysql'
    }
    return mapping.get(db_type, db_type)

def get_db_volume_path(db_type):
    """Retourne le chemin de volume selon le type de DB"""
    mapping = {
        'pgsql': '/var/lib/postgresql/data',
        'mysql': '/var/lib/mysql'
    }
    return mapping.get(db_type, '/var/lib/data')

def update_compose_file():
    """Met à jour docker-compose.yml avec la bonne configuration DB"""
    env_vars = read_env_file()
    db_type = env_vars.get('DB_TYPE', 'pgsql')
    db_version = env_vars.get('DB_VERSION', '16')
    
    # Lire le fichier docker-compose.yml
    try:
        with open('docker-compose.yml', 'r') as f:
            content = f.read()
    except FileNotFoundError:
        print("Erreur: docker-compose.yml non trouvé")
        sys.exit(1)
    
    # Déterminer l'image et le volume path
    db_image = get_db_image_name(db_type)
    volume_path = get_db_volume_path(db_type)
    
    # Remplacer l'image de base de données
    db_version_pattern = '${DB_VERSION}'
    content = re.sub(
        r'image: \w+:\$\{DB_VERSION\}',
        f'image: {db_image}:{db_version_pattern}',
        content
    )
    
    # Remplacer le volume path
    content = re.sub(
        r'- db:/var/lib/\w+(/\w+)?',
        f'- db:{volume_path}',
        content
    )
    
    # Sauvegarder le fichier
    with open('docker-compose.yml', 'w') as f:
        f.write(content)
    
    print(f"✅ docker-compose.yml mis à jour pour {db_type} ({db_image}:{db_version})")

if __name__ == "__main__":
    update_compose_file()
