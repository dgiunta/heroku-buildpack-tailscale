#!/bin/bash

function prefix() {
  sed -u 's/^/[tailscale] /'
}

if [[ -v "DISABLE_TAILSCALE" && "$DISABLE_TAILSCALE" != "false" ]]; then
  echo "DISABLE_TAILSCALE ENV var is set" | prefix
  echo "--> Disabling tailscale" | prefix
  exit 0
fi

TAILSCALE_PROXY_PORT=${TAILSCALE_PROXY_PORT:-1055}
TAILSCALE_HOSTNAME=${TAILSCALE_HOSTNAME:-heroku-app}

(
  /app/bin/tailscaled --tun=userspace-networking --socks5-server=localhost:"$TAILSCALE_PROXY_PORT" --outbound-http-proxy-listen=localhost:"$TAILSCALE_PROXY_PORT" 2>&1 | prefix
) &

/app/bin/tailscale up --authkey="$TAILSCALE_AUTHKEY" --hostname="$TAILSCALE_HOSTNAME" --accept-routes

export ALL_PROXY=socks5://localhost:"$TAILSCALE_PROXY_PORT"
export HTTP_PROXY=http://localhost:"$TAILSCALE_PROXY_PORT"
export http_proxy=http://localhost:"$TAILSCALE_PROXY_PORT"

echo "Tailscale tunnel started" | prefix
