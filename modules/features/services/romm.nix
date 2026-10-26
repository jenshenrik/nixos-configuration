{ config, lib, ... }:

let
  cfg = config.myModules.features.services.romm;
in
{
  options.myModules.features.services.romm = {
    enable = lib.mkEnableOption "RomM self-hosted ROM manager";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8090;
      description = ''
        Port on which the RomM web UI (nginx virtual host) listens.
        Port 80 is taken by Homepage.
      '';
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the RomM web UI port in the firewall.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/data/romm";
      description = ''
        Base path for RomM data. ROMs go in `''${dataDir}/library`
        (e.g. `library/roms/<platform>/...`).
      '';
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/var/lib/romm-secrets/romm.env";
      description = ''
        Optional environment file with metadata provider credentials
        (IGDB_CLIENT_ID, IGDB_CLIENT_SECRET, SCREENSCRAPER_USER, ...).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.romm = {
      enable = true;
      # Backend API stays on loopback; nginx fronts it.
      listenAddress = "127.0.0.1";
      port = 8085;
      dataDir = cfg.dataDir;
      environmentFile = cfg.environmentFile;
      nginx = {
        enable = true;
        virtualHost = "romm";
      };
    };

    services.nginx.virtualHosts.romm = {
      default = true;
      listen = [
        { addr = "0.0.0.0"; port = cfg.port; }
        { addr = "[::]"; port = cfg.port; }
      ];
    };

    # Upstream creates dataDir and its subdirs as 0750 romm:romm. Make them
    # group-writable with setgid so members of the romm group can manage
    # the whole tree, and new files inherit the romm group (readable by the
    # service and nginx).
    systemd.tmpfiles.settings."10-romm" = lib.genAttrs
      ([ cfg.dataDir ] ++ map (d: "${cfg.dataDir}/${d}")
        [ "assets" "cache" "config" "library" "resources" ])
      (_: { d.mode = lib.mkForce "2770"; });

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
