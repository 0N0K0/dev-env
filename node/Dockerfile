ARG NODE_VERSION=20
FROM node:${NODE_VERSION}

WORKDIR /app
COPY ./api /app
RUN npm install
CMD ["npm", "run", "dev"]
