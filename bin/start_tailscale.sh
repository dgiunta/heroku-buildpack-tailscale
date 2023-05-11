#!/bin/bash

TAILSCALE_PROXY_PORT=${TAILSCALE_PROXY_PORT:-1055}

/app/bin/tailscaled --tun=userspace-networking --socks5-server=localhost:"$TAILSCALE_PROXY_PORT" --outbound-http-proxy-listen=localhost:"$TAILSCALE_PROXY_PORT" &

/app/bin/tailscale up --authkey="$TAILSCALE_AUTHKEY" --hostname=heroku-app --accept-routes

echo Tailscale started
export ALL_PROXY=socks5://localhost:"$TAILSCALE_PROXY_PORT"
export HTTP_PROXY=http://localhost:"$TAILSCALE_PROXY_PORT"
export http_proxy=http://localhost:"$TAILSCALE_PROXY_PORT"
