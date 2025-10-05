# Stage 1: Build the Go binary
FROM golang:1.24.6 AS builder

# Create a directory for the application
WORKDIR /app

# Fetch dependencies
COPY go.mod go.sum ./

RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

COPY pkg ./pkg

COPY cmd/jetstream ./cmd/jetstream

COPY Makefile ./

# Build the application with cache mounts
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    make build

# Stage 2: Import SSL certificates
FROM alpine:latest AS certs

RUN apk --update add ca-certificates

# Stage 3: Build a minimal Docker image
FROM debian:stable-slim

RUN apt-get update \
  && apt-get install -y curl \
  && apt-get clean
# Import the SSL certificates from the first stage.
COPY --from=certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

# Copy the binary from the first stage.
COPY --from=builder /app/jetstream .

# Set the startup command to run the binary
CMD ["./jetstream"]
