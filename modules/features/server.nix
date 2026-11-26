_: {
  # Git forge and meta search for forge, the headless macbook. Both bind to
  # localhost: the Cloudflare tunnel is the only way in, so no port is opened.
  flake.nixosModules.server = _: {
    services = {
      cloudflared = {
        enable = true;
        # Not declarative: create the tunnel in the Cloudflare dashboard, drop
        # its credentials JSON at /var/lib/cloudflared/<TUNNEL-ID>.json, and
        # put the same UUID here. Cloudflare routes by hostname, so there is
        # no reverse proxy and no certificate to manage.
        tunnels."TUNNEL-ID" = {
          credentialsFile = "/var/lib/cloudflared/TUNNEL-ID.json";
          default = "http_status:404";
          ingress = {
            "git.tshasan.com" = "http://127.0.0.1:3000";
            "search.tshasan.com" = "http://127.0.0.1:8888";
          };
        };
      };

      forgejo = {
        enable = true;
        settings = {
          service.DISABLE_REGISTRATION = true;
          server = {
            DOMAIN = "git.tshasan.com";
            ROOT_URL = "https://git.tshasan.com/";
            # Port 22 is not reachable through the tunnel, and reaching it
            # over the LAN would need a second URL anyway.
            DISABLE_SSH = true;
            HTTP_ADDR = "127.0.0.1";
            HTTP_PORT = 3000;
          };
        };
      };

      searx = {
        enable = true;
        # Holds SEARX_SECRET_KEY: settings.yml lands in the world-readable
        # store, so the value is substituted at startup instead.
        environmentFile = "/var/lib/searx.env";
        settings = {
          general.instance_name = "tshasan";
          server = {
            bind_address = "127.0.0.1";
            port = 8888;
            base_url = "https://search.tshasan.com/";
            secret_key = "$SEARX_SECRET_KEY";
          };
        };
      };
    };
  };
}
