# Tailscale Buildpack for Heroku

This Buildpack adds configuration to connect a running heroku dyno to
your tailscale network.

Tailscale's [instructions for getting it working on
Heroku](https://tailscale.com/kb/1107/heroku/) are setup to work with a
Docker-based deployment in Heroku. This repo accomplishes those
same installation instructions in buildpack form in the event that you
are running your application on heroku in a non-Docker-based setup.

You'll still want to follow [Step
1](https://tailscale.com/kb/1107/heroku/#step-1-generate-an-auth-key-to-authenticate-your-heroku-apps)
of Tailscale's instructions (ie - create an auth token and install it in
your app's ENV vars as `TAILSCALE_AUTHKEY`).

After that you'll add this repo as an additional buildpack in your
environment, and you should be all set.

If for some reason you want to temporarily disable Tailscale in your
applications, you can set the `DISABLE_TAILSCALE` ENV var to any value
other than `false`
