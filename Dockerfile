FROM golang:latest AS builder

WORKDIR /app

ADD tailscale /app/tailscale

# build modified derper
RUN cd /app/tailscale/cmd/derper && \
    CGO_ENABLED=0 /usr/local/go/bin/go build -buildvcs=false -ldflags "-s -w" -o /app/derper && \
    cd /app && \
    rm -rf /app/tailscale

FROM ubuntu:20.04
WORKDIR /app

# ========= CONFIG =========
# - derper args
ENV DERP_ADDR :443
ENV DERP_CERTS=/app/certs/
ENV DERP_STUN_PORT 100
ENV DERP_VERIFY_CLIENTS false
# ==========================

# apt
RUN apt-get update && \
    apt-get install -y openssl curl

COPY build_cert.sh /app/
COPY --from=builder /app/derper /app/derper

# build self-signed certs && start derper
CMD bash /app/build_cert.sh $DERP_HOST $DERP_CERTS && \
    /app/derper --hostname=127.0.0.1 \
    --certmode=manual \
    --certdir=$DERP_CERTS \
    --stun=true  \
    --stun-port=$DERP_STUN_PORT  \
    --a=$DERP_ADDR \
    --http-port=-1 \
    --verify-clients=$DERP_VERIFY_CLIENTS
