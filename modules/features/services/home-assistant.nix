{ config, lib, ... }:

let
  cfg = config.myModules.features.services.home-assistant;
in
{
  options.myModules.features.services.home-assistant = {
    enable =
      lib.mkEnableOption "Home Assistant service for headless home servers";

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open the Home Assistant HTTP port (8123) in the firewall.";
    };

    zbt2 = {
      enable = lib.mkEnableOption ''
        Home Assistant Connect ZBT-2 support as an OpenThread Border Router.

        Expects the ZBT-2 to be flashed with OpenThread RCP firmware and
        exposed on the host as a serial device. Enables otbr-agent, grants
        Home Assistant access to the radio, and pulls in the Thread/OTBR
        and Matter integrations.
      '';

      device = lib.mkOption {
        type = lib.types.str;
        default =
          "/dev/serial/by-id/usb-Nabu_Casa_Home_Assistant_Connect_ZBT-2-if00";
        example =
          "/dev/serial/by-id/usb-Nabu_Casa_Home_Assistant_Connect_ZBT-2_1234ABCD-if00";
        description = ''
          Serial device path for the ZBT-2 radio. Prefer a stable
          `/dev/serial/by-id/...` path so the border router survives reboots
          and USB re-enumeration.
        '';
      };

      backboneInterface = lib.mkOption {
        type = lib.types.str;
        default = "eth0";
        example = "end0";
        description = ''
          Upstream (infrastructure) network interface otbr-agent bridges
          Thread traffic onto. Must be the LAN interface that reaches your
          Matter controllers and Thread commissioners.
        '';
      };

      threadInterface = lib.mkOption {
        type = lib.types.str;
        default = "wpan0";
        description = "Name of the Thread network interface created by otbr-agent.";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      services.home-assistant = {
        enable = true;
        openFirewall = cfg.openFirewall;
        config = { };
        extraComponents = [
          "default_config"
        ] ++ lib.optionals cfg.zbt2.enable [
          "thread"
          "otbr"
          "matter"
          "zha"
        ];
      };
    })

    (lib.mkIf (cfg.enable && cfg.zbt2.enable) {
      # Give the hass user access to the ZBT-2 serial device.
      users.users.hass.extraGroups = [ "dialout" ];

      # OpenThread Border Router talks to the ZBT-2 RCP over serial and
      # bridges the Thread mesh onto the LAN.
      services.openthread-border-router = {
        enable = true;
        openFirewall = true;
        interfaceName = cfg.zbt2.threadInterface;
        backboneInterfaces = [ cfg.zbt2.backboneInterface ];
        radio.device = cfg.zbt2.device;
      };

      # mDNS is required for Matter commissioning and for HA to discover
      # the border router over the LAN.
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
        reflector = true;
        publish = {
          enable = true;
          addresses = true;
          workstation = true;
        };
      };

    })
  ];
}
