{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.core.users;
in
{
  options.myModules.core.users.enable =
    lib.mkEnableOption "user accounts and user packages";

  config = lib.mkIf cfg.enable {
    users.users.jenshenrik = {
      isNormalUser = true;
      description = "Jens Henrik Vogeliu";
      extraGroups = [ "networkmanager" "wheel" "docker" ];
      packages = with pkgs; [
        godot
        legcord
        opencode
      ];
    };
  };
}
