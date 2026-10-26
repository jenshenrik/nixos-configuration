{ config, ... }:
let
  legacy = config.legacy;
in
{
  nixos.modules.${if legacy then "legacy" else "development"} = { config, lib, ... }:

  let
    cfg = config.myModules.features.shells.direnv;
  in
  {
    options = lib.optionalAttrs legacy {
      myModules.features.shells.direnv.enable =
        lib.mkEnableOption "direnv with nix-direnv integration";
    };

    config = lib.mkIf (!legacy || cfg.enable) {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        silent = false;
      };
    };
  };
}
