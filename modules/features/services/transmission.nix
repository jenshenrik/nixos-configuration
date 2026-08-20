{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.features.services.transmission;
in
{
  options.myModules.features.services.transmission = {
    enable = lib.mkEnableOption "Transmission BitTorrent daemon";

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the RPC/web UI port in the firewall.";
    };

    openPeerPorts = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the BitTorrent peer port (TCP+UDP) in the firewall.";
    };

    rpcPort = lib.mkOption {
      type = lib.types.port;
      default = 9091;
      description = "Port for the RPC / web UI.";
    };

    peerPort = lib.mkOption {
      type = lib.types.port;
      default = 51413;
      description = "BitTorrent peer port.";
    };

    downloadDir = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/data/torrents/downloads";
      description = "Directory for completed downloads.";
    };

    incompleteDir = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/data/torrents/incomplete";
      description = "Directory for in-progress downloads.";
    };

    mediaGroup = lib.mkOption {
      type = lib.types.str;
      default = "media";
      description = ''
        Shared group that owns the download/media trees so other services
        (e.g. Jellyfin) can read completed downloads.
      '';
    };

    netnsName = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "protonvpn";
      description = ''
        If set, run transmission inside this network namespace (see
        `myModules.features.services.vpnNamespace`) and expose the web UI on
        the host via a systemd socket proxy to the namespace-side veth address.
      '';
    };

    netnsAddress = lib.mkOption {
      type = lib.types.str;
      default = "10.200.0.2";
      description = "Namespace-side veth address that the socket proxy targets.";
    };

    portForwarding = {
      enable = lib.mkEnableOption ''
        Proton VPN NAT-PMP port forwarding. Requires a Proton WireGuard
        config generated with "NAT-PMP (Port Forwarding)" enabled and a P2P
        server that supports it. Only meaningful when `netnsName` is set.
      '';

      gateway = lib.mkOption {
        type = lib.types.str;
        default = "10.2.0.1";
        description = "NAT-PMP gateway inside the VPN (Proton's tunnel gateway).";
      };

      interval = lib.mkOption {
        type = lib.types.int;
        default = 45;
        description = "Seconds between mapping renewals (Proton leases expire at 60s).";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.${cfg.mediaGroup} = { };

    services.transmission = {
      enable = true;
      package = pkgs.transmission_4;
      # flood-for-transmission served on the RPC port.
      webHome = pkgs.flood-for-transmission;
      openRPCPort = cfg.openFirewall;
      openPeerPorts = cfg.openPeerPorts;
      settings = {
        rpc-bind-address = "0.0.0.0";
        rpc-port = cfg.rpcPort;
        rpc-authentication-required = false;
        rpc-host-whitelist-enabled = false;
        rpc-whitelist-enabled = false;
        peer-port = cfg.peerPort;
        download-dir = cfg.downloadDir;
        incomplete-dir = cfg.incompleteDir;
        incomplete-dir-enabled = true;
        umask = 2;
      };
    };

    # Ensure transmission's user is in the shared media group so files it
    # writes are group-accessible to Jellyfin.
    users.users.transmission.extraGroups = [ cfg.mediaGroup ];

    systemd.tmpfiles.rules = [
      "d ${cfg.downloadDir}   2775 transmission ${cfg.mediaGroup} - -"
      "d ${cfg.incompleteDir} 2775 transmission ${cfg.mediaGroup} - -"
    ];

    # When running inside a network namespace, bind transmission to that
    # namespace and proxy the web UI back to the host on the same port.
    systemd.sockets = lib.mkIf (cfg.netnsName != null) {
      "transmission-rpc-proxy" = {
        description = "Socket proxy: host :${toString cfg.rpcPort} -> ${cfg.netnsAddress}:${toString cfg.rpcPort}";
        wantedBy = [ "sockets.target" ];
        listenStreams = [ (toString cfg.rpcPort) ];
      };
    };

    systemd.services = lib.mkIf (cfg.netnsName != null) {
      transmission = {
        bindsTo = [ "netns-${cfg.netnsName}.service" "wg-${cfg.netnsName}.service" ];
        after   = [ "netns-${cfg.netnsName}.service" "wg-${cfg.netnsName}.service" ];
        serviceConfig = {
          NetworkNamespacePath = "/run/netns/${cfg.netnsName}";
          BindReadOnlyPaths = [
            "/etc/netns/${cfg.netnsName}/resolv.conf:/etc/resolv.conf"
          ];
        };
      };

      "transmission-rpc-proxy" = {
        description = "Forward host RPC port into netns ${cfg.netnsName}";
        after = [ "wg-${cfg.netnsName}.service" "transmission.service" ];
        requires = [ "transmission-rpc-proxy.socket" ];
        serviceConfig = {
          ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd ${cfg.netnsAddress}:${toString cfg.rpcPort}";
          DynamicUser = true;
        };
      };

      # NAT-PMP port forwarding loop (Proton VPN). Runs inside the netns,
      # renews the mapping periodically, and updates transmission's peer-port
      # via its RPC whenever the mapped port changes.
      "transmission-port-forward" = lib.mkIf cfg.portForwarding.enable {
        description = "Proton VPN NAT-PMP port forwarding for transmission";
        wantedBy = [ "multi-user.target" ];
        after = [ "wg-${cfg.netnsName}.service" "transmission.service" ];
        bindsTo = [ "wg-${cfg.netnsName}.service" "transmission.service" ];
        path = with pkgs; [ libnatpmp transmission_4 gnugrep coreutils ];
        serviceConfig = {
          NetworkNamespacePath = "/run/netns/${cfg.netnsName}";
          BindReadOnlyPaths = [
            "/etc/netns/${cfg.netnsName}/resolv.conf:/etc/resolv.conf"
          ];
          Restart = "on-failure";
          RestartSec = 10;
        };
        script = ''
          set -u
          LAST_PORT=""
          while true; do
            UDP_OUT=$(natpmpc -a 1 0 udp 60 -g ${cfg.portForwarding.gateway} 2>&1 || true)
            TCP_OUT=$(natpmpc -a 1 0 tcp 60 -g ${cfg.portForwarding.gateway} 2>&1 || true)
            PORT=$(printf '%s\n' "$TCP_OUT" | grep -oE 'Mapped public port [0-9]+' | grep -oE '[0-9]+' | head -1)
            if [ -n "$PORT" ]; then
              if [ "$PORT" != "$LAST_PORT" ]; then
                echo "Proton PF: mapped port $PORT (was: ''${LAST_PORT:-none})"
                transmission-remote 127.0.0.1:${toString cfg.rpcPort} -p "$PORT" || \
                  echo "Failed to update transmission peer-port" >&2
                LAST_PORT="$PORT"
              fi
            else
              echo "Proton PF: NAT-PMP request failed" >&2
              echo "$TCP_OUT" >&2
            fi
            sleep ${toString cfg.portForwarding.interval}
          done
        '';
      };
    };
  };
}
