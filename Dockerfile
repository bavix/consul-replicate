FROM golang:1.26-alpine3.22 as builder

LABEL org.opencontainers.image.source=https://github.com/hashicorp/consul-replicate
LABEL org.opencontainers.image.description="Consul cross-DC KV replication daemon"
LABEL org.opencontainers.image.licenses=MPL-2.0

ARG version

RUN apk --no-cache add git &&\
    git clone https://github.com/hashicorp/consul-replicate.git /tmp/consul-replicate &&\
    cd /tmp/consul-replicate &&\
    git checkout f975972541ea72613e9b0d05f21f08d1aeb75054 &&\
    COMMIT=$(git rev-parse HEAD) &&\
    NAME=${version:-dev} &&\
    go build -v -ldflags "-s -w -X github.com/hashicorp/consul-replicate/version.Name=${NAME} -X github.com/hashicorp/consul-replicate/version.GitCommit=${COMMIT}" -o /consul-replicate &&\
    cd - &&\
    rm -rf /tmp/consul-replicate

FROM alpine:3.22
WORKDIR /
ENV USER=consul-replicate
ENV UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    "${USER}" && \
    apk add --update --no-cache tzdata curl ca-certificates

COPY --from=builder /consul-replicate .

ENTRYPOINT ["/consul-replicate"]

