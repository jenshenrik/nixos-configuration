{ config, ... }:
let
  legacy = config.legacy;
in
{
  nixos.modules.${if legacy then "legacy" else "gnome"} = { config, lib, ... }:

  let
    cfg = config.myModules.features.desktop.gnome;
  in
  {
    options = lib.optionalAttrs legacy {
      myModules.features.desktop.gnome.enable =
        lib.mkEnableOption "GNOME desktop";
    };

    config = lib.mkIf (!legacy || cfg.enable) ({
      services.xserver.enable = true;
      services.displayManager.gdm.enable = true;
      services.desktopManager.gnome.enable = true;

      services.printing.enable = true;
    } // lib.optionalAttrs legacy {
      services.xserver.xkb = {
        layout = "dk";
        variant = "";
      };

      console.keyMap = "dk-latin1";
    });
  };
}
