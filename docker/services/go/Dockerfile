ARG GO_VERSION=latest
ARG SOURCE_DIR=api
FROM golang:${GO_VERSION}

WORKDIR /app
COPY ./${SOURCE_DIR} /app

EXPOSE 80

# Dépendances gérées via Homebrew
CMD ["go", "run", "."]
