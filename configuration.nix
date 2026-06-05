{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/system.nix
    ./modules/desktop.nix
    ./modules/audio.nix
    ./modules/users.nix
    ./modules/packages.nix
    ./modules/gaming.nix
    ./modules/slicers.nix
    ./modules/vscode.nix
    # ./modules/niri.nix
  ];

  myModules.dotnet-vscode.enable = true;
}
