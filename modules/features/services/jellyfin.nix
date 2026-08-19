{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.features.services.jellyfin;
in
{
  options.myModules.features.services.jellyfin = {
    enable = lib.mkEnableOption "Jellyfin media server";

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Open Jellyfin's ports in the firewall (HTTP 8096, HTTPS 8920,
        DLNA/UPnP 1900, auto-discovery 7359).
      '';
    };

    mediaDir = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/data/media";
      description = "Root directory for media libraries.";
    };

    mediaGroup = lib.mkOption {
      type = lib.types.str;
      default = "media";
      description = "Shared group used to read media/download trees.";
    };

    hardwareAcceleration = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install jellyfin-ffmpeg and add jellyfin to video/render groups
        for VA-API hardware transcoding on the Intel iGPU.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.${cfg.mediaGroup} = { };

    services.jellyfin = {
      enable = true;
      openFirewall = cfg.openFirewall;
    };

    users.users.jellyfin.extraGroups =
      [ cfg.mediaGroup ]
      ++ lib.optionals cfg.hardwareAcceleration [ "video" "render" ];

    environment.systemPackages = lib.optionals cfg.hardwareAcceleration [
      pkgs.jellyfin-ffmpeg
    ];

    systemd.tmpfiles.rules = [
      "d ${cfg.mediaDir} 2775 jellyfin ${cfg.mediaGroup} - -"
    ];
  };
}
