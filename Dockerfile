FROM cgr.dev/chainguard/go:1.21@sha256:60abea54575553ffa39feafecc630fbc1c8d1a55e35d359f43d8160bbd4afb9c AS builder

WORKDIR /app

# install and cache dependencies
RUN --mount=type=cache,target=/root/go/pkg/mod \
    --mount=type=bind,source=go.sum,target=go.sum \
    --mount=type=bind,source=go.mod,target=go.mod \
    go mod download -x

# build with cache
RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/root/go/pkg/mod \
    --mount=type=bind,target=. \
    CGO_ENABLED=0 go build -o /bin/openfga ./cmd/openfga

FROM cgr.dev/chainguard/static@sha256:d1c6c919115fa5ba6563a8f641c3b7972856feb2a23a2fe9321df877cf83da18

EXPOSE 8081
EXPOSE 8080
EXPOSE 3000

COPY --from=ghcr.io/grpc-ecosystem/grpc-health-probe:v0.4.22 /ko-app/grpc-health-probe /user/local/bin/grpc_health_probe
COPY --from=builder /bin/openfga /openfga

# Healthcheck configuration for the container using grpc_health_probe
# The container will be considered healthy if the gRPC health probe returns a successful response.
HEALTHCHECK --interval=5s --timeout=30s --retries=3 CMD ["/usr/local/bin/grpc_health_probe", "-addr=:8081"]

ENTRYPOINT ["/openfga"]
