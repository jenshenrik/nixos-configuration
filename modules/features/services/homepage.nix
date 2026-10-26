{ config, ... }:

let
  localNetwork = config.localNetwork;
in
{
  nixos.modules.server-web = { config, lib, ... }:
  let
    cfg = config.myModules.features.services.homepage;
    groups = lib.groupBy (entry: entry.group) (lib.attrValues cfg.entries);
    groupOrder = [ "Home" "Media" "Printing" "Network" ];
  in
  {
    options.myModules.features.services.homepage = {
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
        description = "Hostname for direct dashboard links and the allowed-hosts check.";
      };
      entries = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            group = lib.mkOption { type = lib.types.str; };
            order = lib.mkOption { type = lib.types.int; default = 100; };
            item = lib.mkOption { type = lib.types.attrsOf lib.types.anything; };
          };
        });
        default = { };
        description = "Service-contributed dashboard entries, grouped and ordered for display.";
      };
    };

    config = {
      myModules.features.services.reverseProxy.routes = {
        home = "127.0.0.1:${toString cfg.port}";
        ${config.networking.hostName} = "127.0.0.1:${toString cfg.port}";
      };

      services.homepage-dashboard = {
        enable = true;
        listenPort = cfg.port;
        openFirewall = cfg.openFirewall;
        allowedHosts = lib.concatStringsSep "," [
          "${cfg.hostname}:${toString cfg.port}"
          "${config.networking.hostName}:${toString cfg.port}"
          "${config.networking.hostName}.local:${toString cfg.port}"
          "localhost:${toString cfg.port}"
          "127.0.0.1:${toString cfg.port}"
          "${localNetwork.serverAddress}:${toString cfg.port}"
          cfg.hostname
          config.networking.hostName
          "${config.networking.hostName}.local"
          "localhost"
          "127.0.0.1"
          localNetwork.serverAddress
          "home.${localNetwork.domain}"
          "${config.networking.hostName}.${localNetwork.domain}"
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
        services = map (group: {
          ${group} = map (entry: entry.item) (lib.sort (a: b: a.order < b.order) groups.${group});
        }) (lib.filter (group: groups ? ${group}) (groupOrder ++ lib.subtractLists groupOrder (lib.attrNames groups)));
      };
    };
  };
}
