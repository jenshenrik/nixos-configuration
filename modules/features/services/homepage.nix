{ config, lib, ... }:

let
  cfg = config.myModules.features.services.homepage;
  svc = config.myModules.features.services;

  url = port: "http://${cfg.hostname}:${toString port}";
in
{
  options.myModules.features.services.homepage = {
    enable = lib.mkEnableOption "Homepage dashboard (gethomepage.dev)";

    port = lib.mkOption {
      type = lib.types.port;
      default = 80;
      description = "Port on which Homepage listens.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the Homepage port in the firewall.";
    };

    hostname = lib.mkOption {
      type = lib.types.str;
      default = "home.lan";
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
        "${cfg.hostname}:${toString cfg.port}"
        "${config.networking.hostName}:${toString cfg.port}"
        "localhost:${toString cfg.port}"
        "127.0.0.1:${toString cfg.port}"
      ];

      settings = {
        title = "nixhome";
        headerStyle = "clean";
        layout = {
          "Home" = { style = "row"; columns = 2; };
          "Media" = { style = "row"; columns = 2; };
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
                href = url 8123;
                description = "Home automation";
              };
            }
            ++ lib.optional svc.spoolman.enable {
              "Spoolman" = {
                icon = "spoolman.png";
                href = url svc.spoolman.port;
                description = "Filament inventory";
              };
            };
        }
        ++ lib.optional (svc.jellyfin.enable || svc.transmission.enable) {
          "Media" =
            lib.optional svc.jellyfin.enable {
              "Jellyfin" = {
                icon = "jellyfin.png";
                href = url 8096;
                description = "Media server";
              };
            }
            ++ lib.optional svc.transmission.enable {
              "Transmission" = {
                icon = "transmission.png";
                href = url svc.transmission.rpcPort;
                description = "Torrents (via VPN)";
              };
            };
        };
    };

    # Grant the homepage service permission to bind to port 80
    systemd.services.homepage-dashboard.serviceConfig = {
      AmbientCapabilities = lib.mkForce "CAP_NET_BIND_SERVICE";
      CapabilityBoundingSet = lib.mkForce "CAP_NET_BIND_SERVICE";
      PrivateUsers = lib.mkForce false;
    };
  };
}
