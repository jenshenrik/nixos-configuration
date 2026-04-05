{ pkgs, ... }:

let
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
  environment.systemPackages = [
    pkgs.prusa-slicer
    pkgs.LycheeSlicer
    lycheeDesktop
  ];
}
