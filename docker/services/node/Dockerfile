ARG NODE_VERSION=latest
ARG SOURCE_DIR=api
FROM node:${NODE_VERSION}

WORKDIR /app
COPY ./${SOURCE_DIR} /app

# Dependencies managed locally with Homebrew npm
CMD ["npm", "start"]
