{ config, ... }:

let
  legacy = config.legacy;
in
{
  nixos.modules.${if legacy then "legacy" else "base"} = { config, lib, pkgs, ... }:

  let
    cfg = config.myModules.core.users;
  in
  {
    options.myModules.core.users = lib.optionalAttrs legacy {
      enable = lib.mkEnableOption "user accounts and user packages";
    };

    config = lib.mkIf (!legacy || cfg.enable) {
      users.users.jenshenrik = {
        isNormalUser = true;
        description = "Jens Henrik Vogeliu";
        extraGroups = [ "networkmanager" "wheel" "docker" "dialout" ];
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEvgOtVv78YtjYzgK/OnWMllO5uTgcC6OmkaCUdUPBCj jens.henrik.vogelius@proton.me"
        ];
        packages = with pkgs; lib.optionals legacy [
          godot
          legcord
          opencode
        ];
      };
    };
  };
}
