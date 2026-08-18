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
        home-assistant.enable = false;
        spoolman = {
          enable = true;
          autoStart = true;
          openFirewall = true;
          host = "0.0.0.0";
        };
      };

      shells = {
        zsh.enable = true;
      };
    };
  };
}
