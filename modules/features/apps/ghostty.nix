{ config, ... }:
let
  legacy = config.legacy;
in
{
  nixos.modules.${if legacy then "legacy" else "workstation"} = { config, lib, pkgs, ... }:

  let
    cfg = config.myModules.features.apps.ghostty;
  in
  {
    options = lib.optionalAttrs legacy {
      myModules.features.apps.ghostty.enable =
        lib.mkEnableOption "Ghostty as the default terminal emulator";
    };

    config = lib.mkIf (!legacy || cfg.enable) {
      environment.systemPackages = [ pkgs.ghostty ];
      environment.sessionVariables.TERMINAL = "ghostty";
    };
  };
}
