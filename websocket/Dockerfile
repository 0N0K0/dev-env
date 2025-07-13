ARG WEBSOCKET_TYPE=socketio
ARG WEBSOCKET_VERSION=latest

# Base image selon le type de WebSocket
FROM node:${WEBSOCKET_VERSION} as base

WORKDIR /app

# Installation des dépendances selon le type
COPY websocket/package*.json ./
RUN npm install

# Copier le code source
COPY websocket/ ./

# Exposer le port WebSocket
EXPOSE 3001

# Commande par défaut
CMD ["npm", "start"]
