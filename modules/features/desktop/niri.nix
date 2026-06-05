{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.features.desktop.niri;
in
{
  options.myModules.features.desktop.niri.enable =
    lib.mkEnableOption "Niri compositor session";

  config = lib.mkIf cfg.enable {
    programs.niri.enable = true;

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri";
          user = "greeter";
        };
      };
    };

    xdg.portal.enable = true;
  };
}
