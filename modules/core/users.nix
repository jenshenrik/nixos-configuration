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
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEvgOtVv78YtjYzgK/OnWMllO5uTgcC6OmkaCUdUPBCj jens.henrik.vogelius@proton.me"
      ];
      packages = with pkgs; [
        godot
        legcord
        opencode
      ];
    };
  };
}
