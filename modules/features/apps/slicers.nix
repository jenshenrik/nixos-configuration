{
  nixos.modules.fabrication = { pkgs, ... }:

  let
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
    environment.systemPackages = [
      pkgs.prusa-slicer
      pkgs.orca-slicer
      pkgs.lycheeslicer
      lycheeDesktop
    ];
  };
}
