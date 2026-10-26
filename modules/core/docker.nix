{ config, ... }:

let
  legacy = config.legacy;
in
{
  nixos.modules.${if legacy then "legacy" else "development"} = { config, lib, ... }: {
    config = lib.mkIf (!legacy || config.myModules.core.system.enable) {
      virtualisation.docker.enable = true;
    };
  };
}
