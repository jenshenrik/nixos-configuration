{ config, lib, ... }:

let
  cfg = config.myModules.features.services.home-assistant;
in
{
  options.myModules.features.services.home-assistant.enable =
    lib.mkEnableOption "Home Assistant service for headless home servers";
  options.myModules.features.services.home-assistant.otbrRadioDevice = lib.mkOption {
    type = lib.types.str;
    default = "/dev/ttyUSB0";
    description = "Serial device path for the Home Assistant Connect ZBT-2 OpenThread radio.";
    example = "/dev/serial/by-id/usb-Nabu_Casa_Home_Assistant_Connect_ZBT-2_<serial>-if00-port0";
  };
  options.myModules.features.services.home-assistant.otbrRadioBaudRate = lib.mkOption {
    type = lib.types.ints.positive;
    default = 460800;
    description = "Baud rate for the OpenThread radio serial connection (ZBT-2 default: 460800).";
  };

  config = lib.mkIf cfg.enable {
    services.home-assistant = {
      enable = true;
      openFirewall = true;
      config = { };
      extraComponents = [
        "default_config"
        "otbr"
        "thread"
      ];
    };

    services.openthread-border-router = {
      enable = true;
      radio = {
        device = cfg.otbrRadioDevice;
        baudRate = cfg.otbrRadioBaudRate;
        flowControl = true;
      };
    };
  };
}
