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

          # SearXNG replaces this map instead of merging it, so the default
          # tabs have to be repeated; only `onions` is new.
          categories_as_tabs = {
            general = { };
            images = { };
            videos = { };
            news = { };
            map = { };
            music = { };
            it = { };
            science = { };
            files = { };
            "social media" = { };
            onions = { };
          };

          engines = [
            {
              name = "1337x";
              disabled = false;
            }
            {
              name = "piratebay";
              disabled = false;
            }
            {
              name = "solidtorrents";
              disabled = false;
            }
            {
              name = "kickass";
              disabled = false;
            }
            {
              name = "nyaa";
              disabled = false;
            }
            {
              name = "bt4g";
              disabled = false;
            }
            # Onion engines: searx drops any `onions` engine unless it is told
            # it uses Tor, and without the socks5h proxy the request would go
            # out in the clear. Circuits are slow, hence the timeout.
            {
              name = "ahmia";
              disabled = false;
              using_tor_proxy = true;
              proxies = "socks5h://127.0.0.1:9050";
              timeout = 30.0;
            }
            {
              name = "torch";
              disabled = false;
              using_tor_proxy = true;
              proxies = "socks5h://127.0.0.1:9050";
              timeout = 30.0;
            }
          ];
        };
      };
    };

    # Tor, for the onion engines only. The module's client default already
    # listens on 127.0.0.1:9050 with IsolateDestAddr, so there is nothing else
    # to set: socks5h means the .onion name is resolved by Tor, which is the
    # only way it resolves at all.
    services.tor = {
      enable = true;
      client.enable = true;
    };

    # searx checks at startup that its Tor proxy really is Tor, by fetching
    # check.torproject.org through it, and refuses to serve if that fails.
    # Without this ordering it races tor and comes up dead.
    systemd.services.searx.after = [ "tor.service" ];
    systemd.services.searx.wants = [ "tor.service" ];
  };
}
