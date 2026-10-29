{
  nixos.modules.gaming = { pkgs, ... }: {
    # Steam
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };

    # Game performance tools
    programs.gamemode.enable = true;
    programs.gamescope.enable = true;

    # Useful gaming packages
    environment.systemPackages = with pkgs; [
      faugus-launcher
      heroic
      mangohud
      goverlay
      protonup-qt
    ];
  };
}
