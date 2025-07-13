FROM golang:1.22

WORKDIR /app
COPY ./api /app
RUN go mod tidy
CMD ["go", "run", "."]
