ARG WEBSOCKET_TYPE=socketio
ARG WEBSOCKET_VERSION=latest

# Base image selon le type de WebSocket
FROM node:${WEBSOCKET_VERSION} as base

WORKDIR /app

# Installation des dépendances selon le type
COPY ./docker/services/websocket/package*.json ./

# Copier le code source
COPY ./docker/services/websocket/ ./

# Exposer le port WebSocket
EXPOSE 3001

# Commande par défaut
CMD ["sh", "-c", "npm install && npm run dev"]
