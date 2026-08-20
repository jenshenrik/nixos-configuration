{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixhome";
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/aa4a0687-9ab3-4995-ad56-f490f0a92c6f";
    fsType = "ext4";
    options = [ "defaults" "nofail" ];
  };

  # Give jenshenrik write access to the shared media/download trees on /mnt/data
  # via the setgid `media` group (created by the transmission/jellyfin modules).
  users.users.jenshenrik.extraGroups = [ "media" ];

  system.stateVersion = "26.05";

  myModules = {
    core = {
      system.enable = true;
      users.enable = true;
      packages.enable = true;
    };

    hardware = {
      nvidia.enable = false;
      intel-gpu = {
        enable = true;
        generation = "legacy";
      };
    };

    features = {
      desktop = {
        gnome.enable = false;
        audio.enable = false;
        niri.enable = false;
      };

      apps = {
        gaming.enable = false;
        slicers.enable = false;
        editors.dotnet-vscode.enable = false;
        editors.neovim.enable = true;
      };

      services = {
        home-assistant = {
          enable = true;
          openFirewall = true;
          zbt2 = {
            enable = true;
            device = "/dev/serial/by-id/usb-Nabu_Casa_ZBT-2_E072A1D9F43C-if00";
            backboneInterface = "eno1";
            # Flip to true after flashing the stick with OpenThread RCP firmware.
            otbr.enable = true;
          };
        };
        spoolman = {
          enable = true;
          autoStart = true;
          openFirewall = true;
          host = "0.0.0.0";
        };
        transmission = {
          enable = true;
          openFirewall = true;
          openPeerPorts = false;   # peer port only via VPN; nothing to open on LAN
          netnsName = "protonvpn";
          portForwarding.enable = true;
        };
        vpnNamespace = {
          enable = true;
          name = "protonvpn";
          wireguardConfigFile = "/var/lib/proton-vpn/wg0.conf";
          lanCidr = "192.168.86.0/24";
        };
        jellyfin = {
          enable = true;
          openFirewall = true;
        };
      };

      shells = {
        zsh.enable = true;
      };
    };
  };
}
