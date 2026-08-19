{ config, lib, pkgs, ... }:

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
        Home Assistant Connect ZBT-2 support. Grants Home Assistant access
        to the radio, pulls in the Thread/OTBR/Matter/ZHA integrations, and
        installs `universal-silabs-flasher` for reflashing the stick in
        place. Does *not* start the border router on its own; see
        `zbt2.otbr.enable`.
      '';

      otbr.enable = lib.mkEnableOption ''
        Run otbr-agent against the ZBT-2. Requires the stick to be flashed
        with OpenThread RCP firmware first — otherwise otbr-agent will spin
        in a Spinel handshake failure loop and hold the serial port open,
        blocking Home Assistant's USB discovery.
      '';

      installFlasher = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Install `universal-silabs-flasher` system-wide so the ZBT-2 can be
          reflashed in place (e.g. between EmberZNet, OpenThread RCP, and
          multi-PAN firmware).
        '';
      };

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
        config = {
          # Load the components declared in extraComponents. Without this,
          # Nix installs the Python deps but HA never loads them.
          default_config = { };
        };
        extraComponents = [
          "default_config"
          "mobile_app"
          "samsungtv"
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

      # Reflashing utility for the ZBT-2's Silicon Labs radio.
      environment.systemPackages =
        lib.optional cfg.zbt2.installFlasher
          pkgs.python3Packages.universal-silabs-flasher;

      # Matter Server: HA's Matter integration is a client that talks to
      # this over websocket on localhost:5580. Required for commissioning
      # Matter-over-Thread devices (e.g. IKEA Kajplats).
      services.matter-server = {
        enable = true;
        openFirewall = false; # localhost-only; HA connects via ws://localhost:5580/ws
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

    (lib.mkIf (cfg.enable && cfg.zbt2.enable && cfg.zbt2.otbr.enable) {
      # OpenThread Border Router talks to the ZBT-2 RCP over serial and
      # bridges the Thread mesh onto the LAN.
      services.openthread-border-router = {
        enable = true;
        openFirewall = true;
        interfaceName = cfg.zbt2.threadInterface;
        backboneInterfaces = [ cfg.zbt2.backboneInterface ];
        radio.device = cfg.zbt2.device;
        # ZBT-2 OpenThread RCP firmware uses 460800 baud with hardware flow control.
        radio.baudRate = 460800;
        radio.flowControl = true;
      };
    })
  ];
}
