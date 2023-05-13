#!/bin/bash

function prefix() {
  sed -u 's/^/[tailscale] /'
}

if [[ -v "DISABLE_TAILSCALE" && "$DISABLE_TAILSCALE" != "false" ]]; then
  echo "DISABLE_TAILSCALE ENV var is set" | prefix
  echo "--> Disabling tailscale" | prefix
  exit 0
fi

PIDFILE="/app/tmp/pids/tailscaled.pid"
TAILSCALE_PROXY_PORT=${TAILSCALE_PROXY_PORT:-1055}
TAILSCALE_HOSTNAME=${TAILSCALE_HOSTNAME:-heroku-app}

mkdir -p /app/tmp/pids

if [[ -f "$PIDFILE" ]];then
  kill -9 "$(cat $PIDFILE)"
  rm "$PIDFILE"
fi

(
  /app/bin/tailscaled --tun=userspace-networking --socks5-server=localhost:"$TAILSCALE_PROXY_PORT" --outbound-http-proxy-listen=localhost:"$TAILSCALE_PROXY_PORT" 2>&1 | prefix
) &
PID=$!
echo "$PID" > "$PIDFILE"
trap 'echo "Shutting down" | prefix; kill -9 $PID; rm $PIDFILE' SIGTERM

/app/bin/tailscale up --authkey="$TAILSCALE_AUTHKEY" --hostname="$TAILSCALE_HOSTNAME" --accept-routes

export ALL_PROXY=socks5://localhost:"$TAILSCALE_PROXY_PORT"
export HTTP_PROXY=http://localhost:"$TAILSCALE_PROXY_PORT"
export http_proxy=http://localhost:"$TAILSCALE_PROXY_PORT"

echo "Tailscale tunnel started" | prefix
