{
  nixos.modules.workstation = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.ghostty ];
    environment.sessionVariables.TERMINAL = "ghostty";
  };
}
