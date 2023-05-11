#!/bin/bash

/bin/tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &
/bin/tailscale up --authkey=${TAILSCALE_AUTHKEY} --hostname=heroku-app
echo Tailscale started
export ALL_PROXY=socks5://localhost:1055
