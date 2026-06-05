{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.features.apps.slicers;
  lycheeDesktop = pkgs.makeDesktopItem {
    name = "lychee-slicer";
    desktopName = "Lychee Slicer";
    exec = "LycheeSlicer";
    icon = "printer";
    comment = "All-in-one 3D slicer for Resin and Filament";
    categories = [ "Graphics" ];
  };
in
{
  options.myModules.features.apps.slicers.enable =
    lib.mkEnableOption "3D slicer applications";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.prusa-slicer
      pkgs.LycheeSlicer
      lycheeDesktop
    ];
  };
}
