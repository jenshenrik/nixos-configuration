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
      (faugus-launcher.overrideAttrs (old: {
        # Avoid mismatched runtime metadata from Steam's CDN until UMU is updated.
        makeWrapperArgs = (old.makeWrapperArgs or []) ++ [
          "--set UMU_RUNTIME_UPDATE 0"
        ];
      }))
      heroic
      mangohud
      goverlay
      protonup-qt
    ];
  };
}
