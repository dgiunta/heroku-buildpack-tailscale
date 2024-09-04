#!/bin/bash

set -e

function prefix() {
  sed -u 's/^/[tailscale] /'
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

  echo "Starting tailscaled" | prefix
  /app/bin/tailscaled \
    --tun=userspace-networking \
    --socks5-server=localhost:"$TAILSCALE_PROXY_PORT" \
    --outbound-http-proxy-listen=localhost:"$TAILSCALE_PROXY_PORT" \
    --socket=/tmp/tailscaled.sock \
    --state=/tmp/tailscale \
    --verbose=0 \
  2>&1 | prefix >/dev/null &

  TAILSCALE_PID=$(ps -C tailscaled --no-headers --format pid)
  echo "$TAILSCALE_PID" > $PIDFILE

  trap 'echo "Shutting down" | prefix; kill -9 $TAILSCALE_PID; rm $PIDFILE' SIGTERM

  # Unfortunately, tailscale does not have an ENV var or global setting mechanism
  # that we can use to configure the --socket setting for the tailscale command. 
  # As a band-aid for this, the following creates a relatively simple alias that
  # adds the --socket setting by default. This means users of this buildpack won't
  # need to have to remember to mention this socket file in their invokations.
  mv /app/bin/tailscale /app/bin/tailscale-orig
  cat <<-EOF > /app/bin/tailscale
#!/bin/bash
/app/bin/tailscale-orig --socket=/tmp/tailscaled.sock "\$@"
EOF
  chmod +x /app/bin/tailscale

  bash -c "/app/bin/tailscale up --authkey=$TAILSCALE_AUTHKEY --hostname=$TAILSCALE_HOSTNAME $TAILSCALE_EXTRA_ARGS"

  export ALL_PROXY=socks5://localhost:"$TAILSCALE_PROXY_PORT"
  export HTTP_PROXY=http://localhost:"$TAILSCALE_PROXY_PORT"
  export http_proxy=http://localhost:"$TAILSCALE_PROXY_PORT"

  echo "Tailscale tunnel started" | prefix
fi

