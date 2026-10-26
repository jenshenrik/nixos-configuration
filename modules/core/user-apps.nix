{ config, lib, ... }:

{
  nixos.modules = lib.optionalAttrs (!config.legacy) {
    workstation = { pkgs, ... }: {
      users.users.jenshenrik.packages = with pkgs; [
        godot
        legcord
      ];
    };

    development = { pkgs, ... }: {
      users.users.jenshenrik.packages = with pkgs; [ opencode ];
    };
  };
}
