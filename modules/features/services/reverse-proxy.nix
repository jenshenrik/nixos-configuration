{
  nixos.modules.server-web = { config, lib, ... }:

  let
    cfg = config.myModules.features.services.reverseProxy;
    svc = config.myModules.features.services;
    domain = svc.adguardhome.localDomain;

    routes = cfg.routes;
  in
  {
    options.myModules.features.services.reverseProxy = {
      routes = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Service-contributed proxy names and upstream host:port addresses.";
      };

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

    config = {
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
