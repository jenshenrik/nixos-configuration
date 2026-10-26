{
  nixos.shared = { config, lib, ... }:

  let
    cfg = config.myModules.features.services.homepage;
    svc = config.myModules.features.services;

    proxy = svc.reverseProxy;
    # Prefer the reverse-proxy name; fall back to host:port.
    link = name: port:
      if proxy.enable && proxy.hostnames ? ${name}
      then proxy.hostnames.${name}
      else "http://${cfg.hostname}:${toString port}";
  in
  {
    options.myModules.features.services.homepage = {
      enable = lib.mkEnableOption "Homepage dashboard (gethomepage.dev)";

      port = lib.mkOption {
        type = lib.types.port;
        default = 8082;
        description = "Port on which Homepage listens (port 80 belongs to Caddy).";
      };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Open the Homepage port in the firewall.";
      };

      hostname = lib.mkOption {
        type = lib.types.str;
        default = "${config.networking.hostName}.local";
        description = ''
          Hostname used for service links on the dashboard and for
          Homepage's allowed-hosts check.
        '';
      };
    };

    config = lib.mkIf cfg.enable {
      services.homepage-dashboard = {
        enable = true;
        listenPort = cfg.port;
        openFirewall = cfg.openFirewall;
        # Homepage rejects requests whose Host header isn't listed here.
        allowedHosts = lib.concatStringsSep "," [
          # With port
          "${cfg.hostname}:${toString cfg.port}"
          "${config.networking.hostName}:${toString cfg.port}"
          "${config.networking.hostName}.local:${toString cfg.port}"
          "localhost:${toString cfg.port}"
          "127.0.0.1:${toString cfg.port}"
          "192.168.86.246:${toString cfg.port}"
          # Without port (browsers often omit default port 80)
          cfg.hostname
          config.networking.hostName
          "${config.networking.hostName}.local"
          "localhost"
          "127.0.0.1"
          "192.168.86.246"
          # Via the Caddy reverse proxy
          "home.${svc.adguardhome.localDomain}"
          "${config.networking.hostName}.${svc.adguardhome.localDomain}"
        ];

        settings = {
          title = "nixhome";
          headerStyle = "clean";
          layout = {
            "Home" = { style = "row"; columns = 2; };
            "Media" = { style = "row"; columns = 2; };
            "Printing" = { style = "row"; columns = 2; };
            "Network" = { style = "row"; columns = 2; };
          };
        };

        widgets = [
          { resources = { cpu = true; memory = true; disk = [ "/" "/mnt/data" ]; }; }
          { datetime = { text_size = "md"; format = { dateStyle = "long"; timeStyle = "short"; hour12 = false; }; }; }
        ];

        services =
          lib.optional (svc.home-assistant.enable || svc.spoolman.enable) {
            "Home" =
              lib.optional svc.home-assistant.enable {
                "Home Assistant" = {
                  icon = "home-assistant.png";
                  href = link "homeassistant" 8123;
                  description = "Home automation";
                };
              }
              ++ lib.optional svc.spoolman.enable {
                "Spoolman" = {
                  icon = "spoolman.png";
                  href = link "spoolman" svc.spoolman.port;
                  description = "Filament inventory";
                };
              };
          }
          ++         lib.optional (svc.jellyfin.enable || svc.transmission.enable || svc.romm.enable) {
            "Media" =
              lib.optional svc.romm.enable {
                "RomM" = {
                  icon = "romm.png";
                  href = link "romm" svc.romm.port;
                  description = "ROM manager";
                };
              }
              ++ lib.optional svc.jellyfin.enable {
                "Jellyfin" = {
                  icon = "jellyfin.png";
                  href = link "jellyfin" 8096;
                  description = "Media server";
                };
              }
              ++ lib.optional svc.transmission.enable {
                "Transmission" = {
                  icon = "transmission.png";
                  href = link "transmission" svc.transmission.rpcPort;
                  description = "Torrents (via VPN)";
                };
              };
          }
          ++ [
            {
              "Printing" = [
                {
                  "Fluidd" = {
                    icon = "fluidd.png";
                    href = if svc.adguardhome.enable then "http://fluidd.${svc.adguardhome.localDomain}" else "http://192.168.86.120";
                    description = "Neptune 4 Plus";
                  };
                }
              ];
            }
          ]
          ++ lib.optional svc.adguardhome.enable {
            "Network" = [
              {
                "AdGuard Home" = {
                  icon = "adguard-home.png";
                  href = link "adguard" svc.adguardhome.port;
                  description = "DNS & ad blocking";
                  widget = {
                    type = "adguard";
                    url = "http://127.0.0.1:${toString svc.adguardhome.port}";
                    fields = [ "queries" "blocked" "filtered" "latency" ];
                  };
                };
              }
            ];
          };
      };
    };
  };
}
