{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.features.apps.usb-imaging;
in
{
  options.myModules.features.apps.usb-imaging.enable =
    lib.mkEnableOption "USB image writing tools";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      usbimager
    ];

    # usbimager needs raw block-device access; udisks2 lets it authenticate
    # via polkit instead of requiring the user to run it as root.
    services.udisks2.enable = true;
  };
}
