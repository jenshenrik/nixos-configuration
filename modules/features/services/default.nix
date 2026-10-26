{ ... }:

{
  imports = [
    ./local-network.nix
    ./fluidd.nix
    ./adguardhome.nix
    ./home-assistant.nix
    ./homepage.nix
    ./jellyfin.nix
    ./reverse-proxy.nix
    ./romm.nix
    ./spoolman.nix
    ./transmission.nix
    ./vpn-namespace.nix
  ];
}
