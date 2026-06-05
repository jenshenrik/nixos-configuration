{ config, lib, ... }:

let
  cfg = config.myModules.features.services.home-assistant;
in
{
  options.myModules.features.services.home-assistant.enable =
    lib.mkEnableOption "Home Assistant service for headless home servers";

  config = lib.mkIf cfg.enable {
    services.home-assistant = {
      enable = true;
      openFirewall = true;
      config = { };
      extraComponents = [
        "default_config"
      ];
    };
  };
}
