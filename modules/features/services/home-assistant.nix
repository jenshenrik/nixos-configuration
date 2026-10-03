{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.features.services.home-assistant;

  # Fixed UID/GID for the matter.js server container so state files on
  # the host aren't owned by whichever local user happens to sit on UID
  # 1000 (the container's default). Value is arbitrary; keep stable.
  matterJsUid = 987;
  matterJsGid = 987;

  matterJsStateDir = "/var/lib/matter-js-server";
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
        # Allow HA to write to its config dir (needed for the UI to save
        # automations.yaml, scenes.yaml, scripts.yaml). Without this the
        # NixOS module makes configuration.yaml a read-only store symlink
        # and the UI's "create automation" flow times out on save.
        configWritable = true;
        config = {
          # Load the components declared in extraComponents. Without this,
          # Nix installs the Python deps but HA never loads them.
          default_config = { };
          # UI-managed automations/scripts/scenes live in these files.
          # The nixpkgs HA module post-processes the emitted YAML to turn
          # `"!include foo"` strings into real YAML `!include foo` tags
          # (see nixos/modules/services/home-automation/home-assistant.nix).
          automation = "!include automations.yaml";
          script = "!include scripts.yaml";
          scene = "!include scenes.yaml";
        };
        extraComponents = [
          "default_config"
          "mobile_app"
          "samsungtv"
          "cast"
          "google_translate"
          "xbox"
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

      # Matter Server: Home Assistant's Matter integration is a client that
      # talks to a Matter controller server over ws://localhost:5580/ws.
      #
      # We do NOT use `services.matter-server` from nixpkgs: it wires up
      # `python-matter-server`, which is archived upstream and has a broken
      # OTA path ("Target node did not process the update file" for every
      # IKEA device — see HA community topic 976445). The community fix is
      # to switch to `matter-js/matterjs-server`, which is not yet in
      # nixpkgs. We run the upstream OCI image instead, keeping the
      # WebSocket API compatible so HA needs no reconfiguration.
      #
      # First-time migration: existing python-matter-server state lives at
      # /var/lib/private/matter-server (DynamicUser). Before starting the
      # container for the first time, on nixhome:
      #   sudo systemctl stop matter-server 2>/dev/null || true
      #   sudo mkdir -p ${matterJsStateDir}
      #   sudo cp -a /var/lib/private/matter-server/. ${matterJsStateDir}/
      #   sudo chown -R ${toString matterJsUid}:${toString matterJsGid} ${matterJsStateDir}
      # matterjs-server auto-migrates the storage format on first launch.
      users.users.matter-js-server = {
        isSystemUser = true;
        uid = matterJsUid;
        group = "matter-js-server";
        description = "matter.js server (OCI container)";
      };
      users.groups.matter-js-server.gid = matterJsGid;

      systemd.tmpfiles.settings."10-matter-js-server"."${matterJsStateDir}".d = {
        user = "matter-js-server";
        group = "matter-js-server";
        mode = "0750";
      };

      virtualisation.podman = {
        enable = true;
        # Not enabling dockerCompat/dockerSocket — nothing else needs it.
      };
      virtualisation.oci-containers = {
        backend = "podman";
        containers.matter-js-server = {
          image = "ghcr.io/matter-js/matterjs-server:stable";
          autoStart = true;
          # --network=host is required: matter.js needs raw access to mDNS
          # and to the LAN interface for Matter/Thread commissioning and
          # OTA. --user pins the in-container UID to our fixed system UID
          # so files land with predictable ownership on the host.
          extraOptions = [
            "--network=host"
            "--user=${toString matterJsUid}:${toString matterJsGid}"
          ];
          volumes = [ "${matterJsStateDir}:/data" ];
          environment = {
            STORAGE_PATH = "/data";
            # WebSocket API. HA connects via ws://localhost:5580/ws.
            LISTEN_ADDRESS = "127.0.0.1";
            PORT = "5580";
            PRIMARY_INTERFACE = cfg.zbt2.backboneInterface;
            # Match the vendor ID that python-matter-server used (Nabu Casa,
            # 0x134b = 4939). matter.js defaults to the test vendor 0xfff1;
            # leaving the default makes the legacy-data migrator skip the
            # existing fabric ("No fabric found matching vendorId=0xfff1
            # ... Available fabrics: [vendorId=0x134b]") and start fresh,
            # which makes all commissioned devices appear as "unavailable"
            # in Home Assistant.
            VENDOR_ID = "4939";
            # Bumped to debug while chasing OTA / Bilresa issues. Revert
            # to "info" once things are stable.
            LOG_LEVEL = "debug";
            # Allow OTA lookups from the CSA test-net DCL alongside main-net.
            # Consider removing once all devices are on main-net-served firmware.
            ENABLE_TEST_NET_DCL = "true";
          };
        };
      };

      # Workaround for matterjs-server #940 ("Events stop flowing from
      # sleepy devices (ICDs) after subscription re-establishment").
      # After the ~15m ICD subscription liveness timeout, matter.js logs
      # `Subscription successful` on the resubscribe but no reports flow
      # from the device; events queue on-device until a fresh session is
      # forced (battery pull). Poking the node over the WebSocket API on
      # a short interval forces controller <-> device traffic and keeps
      # the session real. Hardcoded to node 2 (IKEA Bilresa) — the only
      # sleepy device on this fabric today. If more show up, extend the
      # for-loop below.
      #
      # Upstream refs: matter-js/matterjs-server#940, #843, #985.
      # Remove once a matter.js release fixes the underlying bug.
      systemd.services.matter-js-ping-node2 = {
        description = "Poke matter.js sleepy ICDs to keep their subscriptions alive";
        after = [ "podman-matter-js-server.service" ];
        requires = [ "podman-matter-js-server.service" ];
        serviceConfig = {
          Type = "oneshot";
          # Discard the response; we only care that the command reaches
          # the server. `timeout` kills the WS connection after 10s so
          # the unit doesn't hang.
          # `ping_node` is a session-level ping the sleepy device never
          # answers ("Node @1:2 is connected but no pings succeeded"), so
          # it doesn't dislodge the stuck subscription. `interview_node`
          # tears down the peer and forces a fresh CASE handshake plus
          # full node re-read, which is heavy but is our last lever from
          # outside matter.js. Bump the timeout well above 10s — an
          # interview can take a while on Thread.
          ExecStart = pkgs.writeShellScript "matter-js-ping-node2" ''
            for node in 2; do
              ${pkgs.coreutils}/bin/printf '%s\n' \
                "{\"message_id\":\"interview-$node\",\"command\":\"interview_node\",\"args\":{\"node_id\":$node}}" \
              | ${pkgs.coreutils}/bin/timeout 60 \
                  ${pkgs.websocat}/bin/websocat -n ws://127.0.0.1:5580/ws \
                  >/dev/null 2>&1 || true
            done
          '';
        };
      };
      systemd.timers.matter-js-ping-node2 = {
        description = "Timer: poke matter.js sleepy ICDs every 10 minutes";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5min";
          OnUnitActiveSec = "10min";
          AccuracySec = "30s";
          Persistent = false;
        };
      };

      # mDNS is required for Matter commissioning and for HA to discover
      # the border router over the LAN. Reflector is intentionally OFF:
      # on a single-LAN host it does nothing useful, and if any other
      # interface (e.g. wlp2s0) is up on the same subnet it duplicates
      # mDNS traffic, which is known to disturb Matter subscription
      # heartbeats.
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
        reflector = false;
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
