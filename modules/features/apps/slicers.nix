{ config, ... }:
let
  legacy = config.legacy;
in
{
  nixos.modules.${if legacy then "legacy" else "fabrication"} = { config, lib, pkgs, ... }:

  let
    cfg = config.myModules.features.apps.slicers;
    lycheeDesktop = pkgs.makeDesktopItem {
      name = "lychee-slicer";
      desktopName = "Lychee Slicer";
      exec = "lycheeslicer";
      icon = "printer";
      comment = "All-in-one 3D slicer for Resin and Filament";
      categories = [ "Graphics" ];
    };
  in
  {
    options = lib.optionalAttrs legacy {
      myModules.features.apps.slicers.enable =
        lib.mkEnableOption "3D slicer applications";
    };

    config = lib.mkIf (!legacy || cfg.enable) {
      environment.systemPackages = [
        pkgs.prusa-slicer
        pkgs.orca-slicer
        pkgs.lycheeslicer
        lycheeDesktop
      ];
    };
  };
}
