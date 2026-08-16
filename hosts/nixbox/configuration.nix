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
      nvidia.enable = true;
    };

    features = {
      desktop = {
        gnome.enable = false;
        audio.enable = true;
        niri.enable = true;
      };

      apps = {
        gaming.enable = true;
        slicers.enable = true;
        editors.dotnet-vscode.enable = true;
        editors.neovim.enable = true;
      };

      services = {
        home-assistant.enable = true;
      };

      shells = {
        zsh.enable = true;
      };
    };
  };
}
