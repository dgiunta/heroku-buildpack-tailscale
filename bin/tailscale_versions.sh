#!/bin/bash

curl --silent https://pkgs.tailscale.com/stable/ | \
  awk '/option/ {gsub("<[^>]+>", ""); print $1}' | \
  grep -v latest | sort
