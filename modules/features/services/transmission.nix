{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.features.services.transmission;
in
{
  options.myModules.features.services.transmission = {
    enable = lib.mkEnableOption "Transmission BitTorrent daemon";

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the RPC/web UI port in the firewall.";
    };

    openPeerPorts = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the BitTorrent peer port (TCP+UDP) in the firewall.";
    };

    rpcPort = lib.mkOption {
      type = lib.types.port;
      default = 9091;
      description = "Port for the RPC / web UI.";
    };

    peerPort = lib.mkOption {
      type = lib.types.port;
      default = 51413;
      description = "BitTorrent peer port.";
    };

    downloadDir = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/data/torrents/downloads";
      description = "Directory for completed downloads.";
    };

    incompleteDir = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/data/torrents/incomplete";
      description = "Directory for in-progress downloads.";
    };

    mediaGroup = lib.mkOption {
      type = lib.types.str;
      default = "media";
      description = ''
        Shared group that owns the download/media trees so other services
        (e.g. Jellyfin) can read completed downloads.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.${cfg.mediaGroup} = { };

    services.transmission = {
      enable = true;
      package = pkgs.transmission_4;
      # flood-for-transmission served on the RPC port.
      webHome = pkgs.flood-for-transmission;
      openRPCPort = cfg.openFirewall;
      openPeerPorts = cfg.openPeerPorts;
      settings = {
        rpc-bind-address = "0.0.0.0";
        rpc-port = cfg.rpcPort;
        rpc-authentication-required = false;
        rpc-host-whitelist-enabled = false;
        rpc-whitelist-enabled = false;
        peer-port = cfg.peerPort;
        download-dir = cfg.downloadDir;
        incomplete-dir = cfg.incompleteDir;
        incomplete-dir-enabled = true;
        umask = 2;
      };
    };

    # Ensure transmission's user is in the shared media group so files it
    # writes are group-accessible to Jellyfin.
    users.users.transmission.extraGroups = [ cfg.mediaGroup ];

    systemd.tmpfiles.rules = [
      "d ${cfg.downloadDir}   2775 transmission ${cfg.mediaGroup} - -"
      "d ${cfg.incompleteDir} 2775 transmission ${cfg.mediaGroup} - -"
    ];
  };
}
