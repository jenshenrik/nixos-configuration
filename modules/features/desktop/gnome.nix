{ config, lib, ... }:

let
  cfg = config.myModules.features.desktop.gnome;
in
{
  options.myModules.features.desktop.gnome.enable =
    lib.mkEnableOption "GNOME desktop";

  config = lib.mkIf cfg.enable {
    services.xserver.enable = true;
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;

    services.xserver.xkb = {
      layout = "dk";
      variant = "";
    };

    console.keyMap = "dk-latin1";
    services.printing.enable = true;
    programs.firefox.enable = true;
  };
}
