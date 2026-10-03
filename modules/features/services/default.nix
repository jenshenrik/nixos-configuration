{ ... }:

{
  imports = [
    ./home-assistant.nix
    ./homepage.nix
    ./jellyfin.nix
    ./spoolman.nix
    ./transmission.nix
    ./vpn-namespace.nix
  ];
}
