#!/bin/bash

# Script pour initialiser le fichier .env depuis .env.template
# Ce script est appelé automatiquement par le Makefile si .env n'existe pas

set -e

ENV_FILE=".env"
TEMPLATE_FILE=".env.template"

# Vérifier si le template existe
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "❌ Fichier $TEMPLATE_FILE non trouvé"
    exit 1
fi

# Copier le template vers .env s'il n'existe pas
if [ ! -f "$ENV_FILE" ]; then
    echo "📋 Initialisation du fichier $ENV_FILE depuis $TEMPLATE_FILE..."
    cp "$TEMPLATE_FILE" "$ENV_FILE"
    echo "✅ Fichier $ENV_FILE créé"
    
    # Marquer le fichier pour être ignoré par Git
    if git rev-parse --git-dir > /dev/null 2>&1; then
        git update-index --skip-worktree "$ENV_FILE" 2>/dev/null || true
        echo "🔧 Fichier $ENV_FILE marqué pour ignorer les modifications locales"
    fi
else
    echo "✅ Fichier $ENV_FILE existe déjà"
fi