{ config, ... }:

let
  localNetwork = config.localNetwork;
in
{
  nixos.modules.server-web = { config, lib, ... }:

  let
    cfg = config.myModules.features.services.adguardhome;
  in
  {
    options.myModules.features.services.adguardhome = {
      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Open DNS (53/tcp+udp) in the firewall.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 3000;
        description = "Port for the web UI (bound to localhost; reach it via the reverse proxy).";
      };

      extraRewrites = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        example = { "fluidd.home.arpa" = "192.168.86.120"; };
        description = "Extra DNS names pointing at other LAN devices.";
      };
    };

    config = {
      myModules.features.services = lib.mkIf config.services.adguardhome.enable {
        reverseProxy.routes.adguard = "127.0.0.1:${toString cfg.port}";
        homepage.entries.adguard = {
          group = "Network";
          order = 10;
          item = {
            "AdGuard Home" = {
              icon = "adguard-home.png";
              href = config.myModules.features.services.reverseProxy.hostnames.adguard;
              description = "DNS & ad blocking";
              widget = {
                type = "adguard";
                url = "http://127.0.0.1:${toString cfg.port}";
                fields = [ "queries" "blocked" "filtered" "latency" ];
              };
            };
          };
        };
      };

      services.adguardhome = {
        enable = true;
        host = "127.0.0.1";
        port = cfg.port;
        # Nix provides the baseline; changes made in the web UI are kept
        # until the next config change in Nix merges over them.
        mutableSettings = true;

        settings = {
          dns = {
            bind_hosts = [ "0.0.0.0" ];
            port = 53;
            # Encrypted upstreams: Quad9 (malware filtering) + Cloudflare,
            # queried in parallel; the fastest answer wins.
            upstream_dns = [
              "https://dns.quad9.net/dns-query"
              "https://cloudflare-dns.com/dns-query"
            ];
            upstream_mode = "parallel";
            # Plain-IP resolvers used only to look up the DoH hostnames above.
            bootstrap_dns = [ "9.9.9.9" "1.1.1.1" ];
            cache_size = 4194304;
          };

          filtering = {
            protection_enabled = true;
            filtering_enabled = true;
            # Exact names (extraRewrites) take precedence over the wildcard.
            rewrites =
              [
                { domain = "*.${localNetwork.domain}"; answer = localNetwork.serverAddress; enabled = true; }
                { domain = "${config.networking.hostName}.${localNetwork.domain}"; answer = localNetwork.serverAddress; enabled = true; }
              ]
              ++ lib.mapAttrsToList
                (domain: answer: { inherit domain answer; enabled = true; })
                cfg.extraRewrites;
          };

          filters = [
            { enabled = true; id = 1; name = "AdGuard DNS filter"; url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt"; }
            { enabled = true; id = 2; name = "OISD Big"; url = "https://big.oisd.nl"; }
          ];

          querylog = { enabled = true; interval = "168h"; };
          statistics = { enabled = true; interval = "168h"; };
        };
      };

      networking.firewall = lib.mkIf cfg.openFirewall {
        allowedTCPPorts = [ 53 ];
        allowedUDPPorts = [ 53 ];
      };
    };
  };
}
