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
    echo "✅ Fichier $ENV_FILE créé (ignoré par Git via .gitignore)"
else
    echo "✅ Fichier $ENV_FILE existe déjà"
fi