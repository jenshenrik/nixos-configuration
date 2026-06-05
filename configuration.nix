{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules
  ];

  myModules = {
    core = {
      system.enable = true;
      users.enable = true;
      packages.enable = true;
    };

    features = {
      desktop = {
        gnome.enable = true;
        audio.enable = true;
        niri.enable = false;
      };

      apps = {
        gaming.enable = true;
        slicers.enable = true;
        editors.dotnet-vscode.enable = true;
      };

      services = {
        home-assistant.enable = true;
      };
    };
  };
}
