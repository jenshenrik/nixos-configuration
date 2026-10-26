{
  nixos.modules.fabrication = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      usbimager
    ];

    # usbimager needs raw block-device access; udisks2 lets it authenticate
    # via polkit instead of requiring the user to run it as root.
    services.udisks2.enable = true;
  };
}
