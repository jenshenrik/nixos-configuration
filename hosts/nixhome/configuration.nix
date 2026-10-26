{ lib, inputs, ... }:

let
  # Preserve feature selection until nixhome's lower-level modules are migrated.
  legacyConfig =
    (lib.evalModules {
      specialArgs = { inherit inputs; };
      modules = [
        ../../modules/top-level.nix
        { legacy = true; }
      ];
    }).config;
in

{
  nixos.hosts.nixhome = { ... }: {
    imports = [
      ./hardware-configuration.nix
      legacyConfig.nixos.shared
      legacyConfig.nixos.modules.legacy
    ];

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    networking.hostName = "nixhome";

    # Static IP on the wired LAN interface. nixhome serves DNS for the LAN,
    # so its address must never change. NetworkManager is told to leave eno1
    # alone; the NixOS scripted networking configures it instead.
    networking.networkmanager.unmanaged = [ "eno1" ];
    networking.useDHCP = false;
    networking.interfaces.eno1.ipv4.addresses = [
      {
        address = "192.168.86.246";
        prefixLength = 24;
      }
    ];
    networking.defaultGateway = {
      address = "192.168.86.1";
      interface = "eno1";
    };
    # Use the local AdGuard Home first; fall back to Quad9 if it's down.
    networking.nameservers = [
      "127.0.0.1"
      "9.9.9.9"
    ];
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
      options = [
        "defaults"
        "nofail"
      ];
    };

    # Give jenshenrik write access to the shared media/download trees on /mnt/data
    # via the setgid `media` group (created by the transmission/jellyfin modules).
    # Also `romm` for write access to /mnt/data/romm.
    users.users.jenshenrik.extraGroups = [
      "media"
      "romm"
    ];

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
            openPeerPorts = false; # peer port only via VPN; nothing to open on LAN
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
          romm = {
            enable = true;
            openFirewall = true;
          };
          homepage = {
            enable = true;
            openFirewall = true;
          };
          adguardhome = {
            enable = true;
            openFirewall = true;
            extraRewrites = {
              "fluidd.home.arpa" = "192.168.86.120";
            };
          };
          reverseProxy = {
            enable = true;
            openFirewall = true;
          };
        };

        shells = {
          zsh.enable = true;
        };
      };
    };
  };
}
