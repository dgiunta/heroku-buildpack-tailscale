#!/bin/bash

function prefix() {
  sed -u 's/^/[tailscale] /'
}

function on_exit() {
}

if [[ -v "DISABLE_TAILSCALE" && "$DISABLE_TAILSCALE" != "false" ]]; then
  echo "DISABLE_TAILSCALE ENV var is set" | prefix
  echo "--> Disabling tailscale" | prefix
else
  PIDFILE="/app/tmp/pids/tailscaled.pid"
  TAILSCALE_PROXY_PORT=${TAILSCALE_PROXY_PORT:-1055}
  TAILSCALE_HOSTNAME=${TAILSCALE_HOSTNAME:-heroku-app}

  mkdir -p /app/tmp/pids

  if [[ -f "$PIDFILE" ]];then
    kill -9 "$(cat $PIDFILE)"
    rm "$PIDFILE"
  fi

  /app/bin/tailscaled \
    --tun=userspace-networking \
    --socks5-server=localhost:"$TAILSCALE_PROXY_PORT" \
    --outbound-http-proxy-listen=localhost:"$TAILSCALE_PROXY_PORT" \
    --verbose=0 \
  2>&1 | prefix | tee /var/log/tailscaled.log >/dev/null &

  TAILSCALE_PID=$(ps -C tailscaled --no-headers --format pid)
  echo "$TAILSCALE_PID" > $PIDFILE

  trap 'echo "Shutting down" | prefix; kill -9 $TAILSCALE_PID; rm $PIDFILE' SIGTERM

  /app/bin/tailscale up --authkey="$TAILSCALE_AUTHKEY" --hostname="$TAILSCALE_HOSTNAME" --accept-routes

  export ALL_PROXY=socks5://localhost:"$TAILSCALE_PROXY_PORT"
  export HTTP_PROXY=http://localhost:"$TAILSCALE_PROXY_PORT"
  export http_proxy=http://localhost:"$TAILSCALE_PROXY_PORT"

  echo "Tailscale tunnel started" | prefix
fi

