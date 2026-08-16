{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];

  myModules = {
    core = {
      system.enable = true;
      users.enable = true;
      packages.enable = true;
    };

    hardware = {
      nvidia.enable = false;
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
      };

      shells = {
        zsh.enable = true;
      };
    };
  };
}
