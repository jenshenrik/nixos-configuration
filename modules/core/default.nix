{ ... }:

{
  imports = [
    ./system.nix
    ./users.nix
    ./packages.nix
    ./docker.nix
    ./user-apps.nix
    ./workstation-apps.nix
  ];
}
