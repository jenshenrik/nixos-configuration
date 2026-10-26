{ config, ... }:

{
  nixos.hosts.nixbox = { ... }: {
    imports = [
      ./hardware-configuration.nix
      config.nixos.modules.base
      config.nixos.modules.workstation
      config.nixos.modules.development
      config.nixos.modules.gaming
      config.nixos.modules.fabrication
      config.nixos.modules.niri
      config.nixos.modules.nvidia
      config.nixos.modules.home-assistant
    ];

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    networking.hostName = "nixbox";
    networking.firewall.enable = false;

    # Enable mDNS for .local hostname resolution
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;
    };

    system.stateVersion = "26.05";

  };
}
