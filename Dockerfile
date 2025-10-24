# Build stage
FROM golang:1.25.3-alpine AS builder

# Set working directory
WORKDIR /app

# Install build dependencies
RUN apk add --no-cache \
    git \
    ca-certificates \
    gcc \
    musl-dev

# Copy go mod files first for better caching
COPY api/go.mod api/go.sum ./

# Download dependencies
RUN go mod download && go mod verify

# Copy source code and frontend
COPY api/ .
COPY frontend/ ./frontend/

# Build arguments for versioning
ARG VERSION=dev
ARG BUILD_TIME
ARG REVISION

# Build application with SQLite compatibility and optimization
ENV CGO_CFLAGS="-D_LARGEFILE64_SOURCE"
RUN CGO_ENABLED=1 GOOS=linux \
    go build \
    -ldflags="-s -w -X main.version=${VERSION} -X main.buildTime=${BUILD_TIME} -X main.revision=${REVISION}" \
    -tags="sqlite_omit_load_extension" \
    -o main .

# Final stage - minimal Alpine
FROM alpine:3.18.4

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    wget \
    && rm -rf /var/cache/apk/*

# Create non-root user for security
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Create app directory and data directory
WORKDIR /app
RUN mkdir -p /data && \
    chown -R appuser:appgroup /app /data

# Copy binary from builder stage
COPY --from=builder /app/main .

# Change ownership of binary
RUN chown appuser:appgroup ./main

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Set environment variables
ENV PORT=8080
ENV DATABASE_PATH=/data/promptforge.db
ENV GIN_MODE=release

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["sh", "-c", "wget --no-verbose --tries=1 --spider http://localhost:8080/api/health || exit 1"]

# Run the application
CMD ["./main"]