{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.features.services.vpnNamespace;
  ns = cfg.name;
  vethHost = "vpn-h";
  vethNs = "vpn-ns";
  hostIP = "10.200.0.1";
  nsIP = "10.200.0.2";
  vethCidr = "10.200.0.0/30";
in
{
  options.myModules.features.services.vpnNamespace = {
    enable = lib.mkEnableOption "Proton VPN WireGuard network namespace";

    name = lib.mkOption {
      type = lib.types.str;
      default = "protonvpn";
      description = "Network namespace name.";
    };

    wireguardConfigFile = lib.mkOption {
      type = lib.types.str;
      example = "/var/lib/proton-vpn/wg0.conf";
      description = ''
        Absolute path to a Proton VPN WireGuard config file (kept outside the
        Nix store, mode 0600). Must contain [Interface] with PrivateKey and
        Address, and [Peer] with PublicKey, Endpoint, AllowedIPs.
      '';
    };

    dns = lib.mkOption {
      type = lib.types.str;
      default = "10.2.0.1";
      description = "DNS server used inside the namespace (Proton VPN DNS by default).";
    };

    lanCidr = lib.mkOption {
      type = lib.types.str;
      example = "192.168.86.0/24";
      description = "LAN subnet allowed to reach services proxied out of the namespace.";
    };

    hostAddress = lib.mkOption {
      type = lib.types.str;
      default = hostIP;
      description = "Host-side veth address (used by socket proxies).";
    };

    namespaceAddress = lib.mkOption {
      type = lib.types.str;
      default = nsIP;
      description = "Namespace-side veth address (targeted by socket proxies).";
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure the parent directory for the WireGuard secret exists with tight
    # perms. The .conf file itself is user-provided (kept out of the Nix store).
    systemd.tmpfiles.rules = [
      "d ${dirOf cfg.wireguardConfigFile} 0700 root root - -"
    ];

    # Ensure DNS inside the namespace.
    environment.etc."netns/${ns}/resolv.conf".text = ''
      nameserver ${cfg.dns}
    '';

    # 1. Create the network namespace and veth pair.
    systemd.services."netns-${ns}" = {
      description = "Network namespace ${ns} + veth pair";
      wantedBy = [ "multi-user.target" ];
      before = [ "wg-${ns}.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = with pkgs; [ iproute2 ];
      script = ''
        set -eu
        # (Re)create the namespace.
        ip netns del ${ns} 2>/dev/null || true
        ip netns add ${ns}
        ip -n ${ns} link set lo up

        # (Re)create veth pair. Host side lives in root ns; ns side moved in.
        ip link del ${vethHost} 2>/dev/null || true
        ip link add ${vethHost} type veth peer name ${vethNs}
        ip link set ${vethNs} netns ${ns}

        ip addr add ${cfg.hostAddress}/30 dev ${vethHost}
        ip link set ${vethHost} up

        ip -n ${ns} addr add ${cfg.namespaceAddress}/30 dev ${vethNs}
        ip -n ${ns} link set ${vethNs} up
      '';
      preStop = ''
        ${pkgs.iproute2}/bin/ip link del ${vethHost} 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip netns del ${ns} 2>/dev/null || true
      '';
    };

    # 2. Bring up WireGuard inside the namespace.
    # Trick: create wg0 in the root netns so its UDP socket uses normal
    # internet, then move the interface into ${ns}. All traffic sent *into*
    # wg0 from inside ${ns} is encrypted and egresses from the root netns.
    systemd.services."wg-${ns}" = {
      description = "WireGuard tunnel for netns ${ns}";
      wantedBy = [ "multi-user.target" ];
      after = [ "netns-${ns}.service" "network-online.target" ];
      requires = [ "netns-${ns}.service" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = with pkgs; [ iproute2 wireguard-tools gnugrep gawk coreutils ];
      script = ''
        set -eu
        CONF='${cfg.wireguardConfigFile}'
        if [ ! -r "$CONF" ]; then
          echo "WireGuard config $CONF not readable" >&2
          exit 1
        fi

        # Extract Address (may be comma-separated IPv4/IPv6) and MTU from [Interface].
        ADDR=$(awk -F' *= *' '/^\[/{s=$1} s=="[Interface]" && $1=="Address"{print $2; exit}' "$CONF")
        MTU=$(awk  -F' *= *' '/^\[/{s=$1} s=="[Interface]" && $1=="MTU"    {print $2; exit}' "$CONF")
        : "''${MTU:=1420}"

        if [ -z "$ADDR" ]; then
          echo "No Address in [Interface] of $CONF" >&2
          exit 1
        fi

        # `wg setconf` only understands wg proper keys; strip wg-quick extensions.
        FILTERED=$(mktemp)
        trap 'rm -f "$FILTERED"' EXIT
        awk '
          /^\[/                    { section=$0; print; next }
          section=="[Interface]" && /^[[:space:]]*(Address|DNS|MTU|Table|PreUp|PostUp|PreDown|PostDown|SaveConfig)[[:space:]]*=/ { next }
          { print }
        ' "$CONF" > "$FILTERED"

        # Fresh interface.
        ip link del wg0 2>/dev/null || true
        ip -n ${ns} link del wg0 2>/dev/null || true

        ip link add wg0 type wireguard
        wg setconf wg0 "$FILTERED"

        ip link set wg0 mtu "$MTU"
        ip link set wg0 netns ${ns}

        # Assign each address (comma-separated dual-stack supported).
        HAS_V6=0
        OLD_IFS=$IFS
        IFS=,
        for a in $ADDR; do
          a=$(echo "$a" | tr -d '[:space:]')
          [ -z "$a" ] && continue
          case "$a" in
            *:*) ip -n ${ns} -6 addr add "$a" dev wg0; HAS_V6=1 ;;
            *)   ip -n ${ns}    addr add "$a" dev wg0 ;;
          esac
        done
        IFS=$OLD_IFS

        ip -n ${ns} link set wg0 up

        # Default route(s) via the tunnel — kill-switch if wg0 is down.
        ip -n ${ns} route add default dev wg0
        if [ "$HAS_V6" = 1 ]; then
          ip -n ${ns} -6 route add default dev wg0
        fi
      '';
      preStop = ''
        ${pkgs.iproute2}/bin/ip -n ${ns} link del wg0 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip link del wg0 2>/dev/null || true
      '';
    };
  };
}
