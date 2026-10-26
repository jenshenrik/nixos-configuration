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

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
