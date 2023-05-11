FROM ubuntu:22.04 AS heroku_22
RUN apt update && apt install -yy curl
RUN curl -fsSL https://tailscale.com/install.sh | sh

FROM ubuntu:20.04 AS heroku_20
RUN apt update && apt install -yy curl
RUN curl -fsSL https://tailscale.com/install.sh | sh

FROM ubuntu:18.04 AS heroku_18
RUN apt update && apt install -yy curl
RUN curl -fsSL https://tailscale.com/install.sh | sh

FROM alpine:latest
COPY --from=heroku_22 /usr/bin/tailscale ./heroku-22/tailscale
COPY --from=heroku_22 /usr/sbin/tailscaled ./heroku-22/tailscaled
COPY --from=heroku_20 /usr/bin/tailscale ./heroku-20/tailscale
COPY --from=heroku_20 /usr/sbin/tailscaled ./heroku-20/tailscaled
COPY --from=heroku_18 /usr/bin/tailscale ./heroku-18/tailscale
COPY --from=heroku_18 /usr/sbin/tailscaled ./heroku-18/tailscaled

CMD ["sh"]
