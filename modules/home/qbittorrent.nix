_: {
  flake.homeModules.qbittorrent =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ qbittorrent ];
      xdg.configFile."qBittorrent/qBittorrent.conf" = {
        force = true;
        text = ''
          [LegalNotice]
          Accepted=true

          [BitTorrent]
          Session\AnonymousModeEnabled=true
          # Require encrypted peer connections (1 = forced, not just preferred).
          Session\Encryption=1
          Session\DHTEnabled=true
          Session\PeXEnabled=true
          # LSD broadcasts on the local LAN — leaks your IP to LAN peers.
          Session\LSDEnabled=false
          Session\AnnounceToAllTrackers=true
          Session\AnnounceToAllTiers=true
          Session\UseRandomPort=true
          # Drop peers binding to privileged ports — common signature of probes.
          Session\BlockPeersOnPrivilegedPorts=true
          # Reject trackers presenting an invalid TLS cert.
          Session\ValidateHTTPSTrackerCertificate=true

          [Preferences]
          # UPnP/NAT-PMP punches holes in the router from userspace — off for
          # privacy/attack-surface reasons. Tradeoff: no incoming connections
          # behind NAT, so you'll mostly leech rather than seed to NATed peers.
          Connection\UPnP=false
          # Don't gossip trackers between peers — can leak you off a private tracker.
          Advanced\LtTrackerExchange=false
          # Update check is plain HTTP from the app, bypassing the libtorrent bind.
          General\UpdateCheck=false
          # WebUI off — no remote control surface.
          WebUI\Enabled=false
          WebUI\Address=127.0.0.1
          WebUI\LocalHostAuth=false
        '';
      };
    };
}
