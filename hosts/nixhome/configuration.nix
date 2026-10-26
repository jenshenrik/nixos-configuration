{ config, ... }:

let
  modules = config.nixos.modules;
  localNetwork = config.localNetwork;
in
{
  localNetwork = {
    serverAddress = "192.168.86.246";
    domain = "home.arpa";
  };

  nixos.hosts.nixhome = { config, pkgs, ... }: {
    imports = [
      ./hardware-configuration.nix
      modules.base
      modules.server-admin
      modules.media
      modules.printing
      modules.server-web
      modules.home-assistant
      modules.intel-gpu
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
        address = localNetwork.serverAddress;
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

    # Preserve the old baseline package selection during the structural migration.
    programs.firefox.enable = true;
    environment.systemPackages = with pkgs; [
      ffmpeg-full
      ungoogled-chromium
      transmission_4-gtk
      blender
      obsidian
    ];
    users.users.jenshenrik.packages = with pkgs; [ godot legcord opencode ];

    myModules = {
      hardware = {
        intel-gpu = {
          generation = "legacy";
        };
      };

      features = {
        services = {
          home-assistant = {
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
            autoStart = true;
            openFirewall = true;
            host = "0.0.0.0";
          };
          transmission = {
            openFirewall = true;
            openPeerPorts = false; # peer port only via VPN; nothing to open on LAN
            netnsName = config.myModules.features.services.vpnNamespace.name;
            netnsAddress = config.myModules.features.services.vpnNamespace.namespaceAddress;
            portForwarding.enable = true;
          };
          vpnNamespace = {
            name = "protonvpn";
            wireguardConfigFile = "/var/lib/proton-vpn/wg0.conf";
            lanCidr = "192.168.86.0/24";
          };
          jellyfin = {
            openFirewall = true;
          };
          romm = {
            openFirewall = true;
          };
          homepage = {
            openFirewall = true;
          };
          adguardhome = {
            openFirewall = true;
            extraRewrites = {
              "fluidd.${localNetwork.domain}" = "192.168.86.120";
            };
          };
          reverseProxy = {
            openFirewall = true;
          };
        };

      };
    };
  };
}
