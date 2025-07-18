ARG NODE_VERSION=latest
FROM node:${NODE_VERSION}

WORKDIR /app
COPY ./api /app

CMD ["sh", "-c", "npm install && npm run dev"]
