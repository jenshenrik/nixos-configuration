{ config, ... }:
let
  legacy = config.legacy;
in
{
  nixos.modules.${if legacy then "legacy" else "fabrication"} = { config, lib, pkgs, ... }:

  let
    cfg = config.myModules.features.apps.usb-imaging;
  in
  {
    options = lib.optionalAttrs legacy {
      myModules.features.apps.usb-imaging.enable =
        lib.mkEnableOption "USB image writing tools";
    };

    config = lib.mkIf (!legacy || cfg.enable) {
      environment.systemPackages = with pkgs; [
        usbimager
      ];

      # usbimager needs raw block-device access; udisks2 lets it authenticate
      # via polkit instead of requiring the user to run it as root.
      services.udisks2.enable = true;
    };
  };
}
