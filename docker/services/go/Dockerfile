ARG GO_VERSION=latest
ARG SOURCE_DIR=api
FROM golang:${GO_VERSION}

WORKDIR /app
COPY ./${SOURCE_DIR} /app
# Dependencies managed locally with Homebrew go
# go.mod and dependencies handled outside container

EXPOSE 80

CMD ["go", "run", "."]
