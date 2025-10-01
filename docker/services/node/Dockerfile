ARG NODE_VERSION=latest
ARG SOURCE_DIR=api
FROM node:${NODE_VERSION}

WORKDIR /app
COPY ./${SOURCE_DIR} /app

# Dépendances gérées via Homebrew
CMD ["npm", "start"]
