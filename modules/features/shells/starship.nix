{ config, ... }:
let
  legacy = config.legacy;
in
{
  nixos.modules.${if legacy then "legacy" else "workstation"} = { config, lib, ... }:

  let
    cfg = config.myModules.features.shells.starship;
  in
  {
    options = lib.optionalAttrs legacy {
      myModules.features.shells.starship.enable =
        lib.mkEnableOption "Starship shell prompt";
    };

    config = lib.mkIf (!legacy || cfg.enable) {
      programs.starship.enable = true;
    };
  };
}
