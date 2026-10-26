{
  nixos.shared = { config, lib, ... }:

  let
    cfg = config.myModules.features.services.reverseProxy;
    svc = config.myModules.features.services;
    domain = svc.adguardhome.localDomain;

    # name -> upstream "host:port". Only enabled services get a route.
    routes =
      lib.optionalAttrs svc.homepage.enable {
        home = "127.0.0.1:${toString svc.homepage.port}";
        ${config.networking.hostName} = "127.0.0.1:${toString svc.homepage.port}";
      }
      // lib.optionalAttrs svc.adguardhome.enable { adguard = "127.0.0.1:${toString svc.adguardhome.port}"; }
      // lib.optionalAttrs svc.jellyfin.enable { jellyfin = "127.0.0.1:8096"; }
      // lib.optionalAttrs svc.home-assistant.enable { homeassistant = "127.0.0.1:8123"; }
      // lib.optionalAttrs svc.romm.enable { romm = "127.0.0.1:${toString svc.romm.port}"; }
      // lib.optionalAttrs svc.spoolman.enable { spoolman = "127.0.0.1:${toString svc.spoolman.port}"; }
      // lib.optionalAttrs svc.transmission.enable { transmission = "127.0.0.1:${toString svc.transmission.rpcPort}"; };
  in
  {
    options.myModules.features.services.reverseProxy = {
      enable = lib.mkEnableOption "Caddy reverse proxy serving http://<service>.${domain}";

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Open port 80 in the firewall.";
      };

      hostnames = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        readOnly = true;
        default = lib.mapAttrs (name: _: "http://${name}.${domain}") routes;
        description = "Generated URL per service name (used by Homepage links).";
      };
    };

    config = lib.mkIf cfg.enable {
      services.caddy = {
        enable = true;
        # Plain HTTP only: local names can't get public certificates, and the
        # explicit http:// prefix stops Caddy from trying.
        virtualHosts = lib.mapAttrs' (name: upstream:
          lib.nameValuePair "http://${name}.${domain}" {
            extraConfig = "reverse_proxy ${upstream}";
          }) routes;
      };

      networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ 80 ];
    };
  };
}
