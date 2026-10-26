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
  } // lib.optionalAttrs config.legacy {
    legacy = { config, lib, pkgs, ... }: {
      users.users.jenshenrik.packages = lib.mkIf config.myModules.core.users.enable (with pkgs; [
        godot
        legcord
        opencode
      ]);
    };
  };
}
