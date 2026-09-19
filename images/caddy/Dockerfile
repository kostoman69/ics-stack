# Official caddy images cannot do DNS-01.
# This image adds the Cloudflare DNS provider via xcaddy.
FROM caddy:2.11.4-builder AS builder
RUN xcaddy build --with github.com/caddy-dns/cloudflare

FROM caddy:2.11.4
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
