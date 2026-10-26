{ config, ... }:
let
  legacy = config.legacy;
in
{
  nixos.modules.${if legacy then "legacy" else "gaming"} = { config, lib, pkgs, ... }:

  let
    cfg = config.myModules.features.apps.gaming;
  in
  {
    options = lib.optionalAttrs legacy {
      myModules.features.apps.gaming.enable =
        lib.mkEnableOption "gaming tools and NVIDIA configuration";
    };

    config = lib.mkIf (!legacy || cfg.enable) {
      # Steam
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
      };

      # Game performance tools
      programs.gamemode.enable = true;
      programs.gamescope.enable = true;

      # Useful gaming packages
      environment.systemPackages = with pkgs; [
        heroic
        mangohud
        goverlay
        protonup-qt
      ];
    };
  };
}
