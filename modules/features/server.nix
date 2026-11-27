{
  # Git forge and meta search for forge, the headless macbook. Both bind to
  # localhost: the Cloudflare tunnel is the only way in, so no port is opened.
  flake.nixosModules.server =
    _:
    let
      # The only value that has to be filled in by hand: create the tunnel in
      # the Cloudflare dashboard, drop its credentials JSON at
      # /var/lib/cloudflared/<ID>.json, and put the same UUID here.
      # Cloudflare routes by hostname, so there is no reverse proxy and no
      # certificate to manage. See "State outside the config" in the README.
      tunnelId = "TUNNEL-ID";
    in
    {
      services = {
        cloudflared = {
          enable = true;
          tunnels.${tunnelId} = {
            credentialsFile = "/var/lib/cloudflared/${tunnelId}.json";
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

            # Upstream defaults are still merged for server settings, but not
            # for engines: keep_only makes the list below the only inventory
            # of what this instance serves, so a searxng bump can neither add
            # nor silently drop a tab.
            use_default_settings.engines.keep_only = [
              # general
              "duckduckgo"
              "brave"
              "mojeek"
              "marginalia"
              "wikipedia"
              "wikidata"
              # images
              "duckduckgo images"
              "bing images"
              "wikicommons.images"
              # videos
              "duckduckgo videos"
              "bing videos"
              "piped"
              # news
              "duckduckgo news"
              "bing news"
              "reuters"
              # it
              "github"
              "stackoverflow"
              "arch linux wiki"
              "pypi"
              "docker hub"
              # science
              "arxiv"
              "semantic scholar"
              "pubmed"
              # map
              "openstreetmap"
              "photon"
              # music
              "bandcamp"
              "soundcloud"
              "radio browser"
              # social media
              "mastodon hashtags"
              # files
              "1337x"
              "piratebay"
              "solidtorrents"
              "kickass"
              "nyaa"
              "bt4g"
            ];

            # Only engines that differ from their upstream definition appear
            # here; everything else comes from the defaults named above.
            engines = [
              {
                name = "marginalia";
                disabled = false;
              }
              {
                name = "1337x";
                disabled = false;
              }
              {
                name = "nyaa";
                disabled = false;
              }
            ];

            # SearXNG replaces this map instead of merging it, so the default
            # tabs have to be repeated. No `onions`: that needed a Tor client,
            # which would have been the only Tor traffic on the connection.
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
            };
          };
        };
      };

      systemd.services = {
        # A missing or empty /var/lib/searx.env leaves secret_key blank, which
        # searx accepts, so fail the init unit instead of serving a broken
        # instance. Stat only, so the root-owned 0600 file is enough.
        searx-init.preStart = "test -s /var/lib/searx.env || { echo 'searx.env is missing or empty, see README' >&2; exit 1; }";
      };

      # No services.tor: the onion engines were the only consumer, and a
      # client that never runs is also the reason searx can no longer fail
      # its startup Tor check on a box nobody is sitting next to.
    };
}
