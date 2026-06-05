{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.features.apps.gaming;
in
{
  options.myModules.features.apps.gaming.enable =
    lib.mkEnableOption "gaming tools and NVIDIA configuration";

  config = lib.mkIf cfg.enable {
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

    # Graphics + 32-bit support (needed for many games)
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
    services.xserver.enable = true;
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    # Useful gaming packages
    environment.systemPackages = with pkgs; [
      heroic
      mangohud
      goverlay
      protonup-qt
    ];
  };
}
