{ ... }:

{
  imports = [
    ./home-assistant.nix
    ./jellyfin.nix
    ./spoolman.nix
    ./transmission.nix
    ./vpn-namespace.nix
  ];
}
