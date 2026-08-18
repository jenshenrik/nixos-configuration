{ config, lib, ... }:

let
  cfg = config.myModules.core.system;
in
{
  options.myModules.core.system.enable =
    lib.mkEnableOption "core system configuration";

  config = lib.mkIf cfg.enable {
    networking.networkmanager.enable = true;

    time.timeZone = "Europe/Copenhagen";

    i18n.defaultLocale = "en_DK.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "da_DK.UTF-8";
      LC_IDENTIFICATION = "da_DK.UTF-8";
      LC_MEASUREMENT = "da_DK.UTF-8";
      LC_MONETARY = "da_DK.UTF-8";
      LC_NAME = "da_DK.UTF-8";
      LC_NUMERIC = "da_DK.UTF-8";
      LC_PAPER = "da_DK.UTF-8";
      LC_TELEPHONE = "da_DK.UTF-8";
      LC_TIME = "da_DK.UTF-8";
    };

    virtualisation.docker.enable = true;
    nixpkgs.config.allowUnfree = true;
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nix.settings.trusted-users = [ "root" "jenshenrik" ];
  };
}
