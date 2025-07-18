ARG GO_VERSION=latest
FROM golang:${GO_VERSION}

WORKDIR /app
COPY ./api /app
RUN go mod tidy
CMD ["go", "run", "."]
