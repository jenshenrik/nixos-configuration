{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.features.apps.ghostty;
in
{
  options.myModules.features.apps.ghostty.enable =
    lib.mkEnableOption "Ghostty as the default terminal emulator";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.ghostty ];
    environment.sessionVariables.TERMINAL = "ghostty";
  };
}
