{ ... }:

{
  imports = [
    ./home-assistant.nix
    ./homepage.nix
    ./jellyfin.nix
    ./romm.nix
    ./spoolman.nix
    ./transmission.nix
    ./vpn-namespace.nix
  ];
}
