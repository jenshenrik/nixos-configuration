{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.features.services.spoolman;
in
{
  options.myModules.features.services.spoolman = {
    enable = lib.mkEnableOption "Spoolman filament spool manager";

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to start the Spoolman service automatically at boot.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 7912;
      description = "Port on which Spoolman listens.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      example = "0.0.0.0";
      description = "Address on which Spoolman listens.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the Spoolman port in the firewall.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Upstream nixpkgs 26.05 pairs spoolman 0.23.1 with starlette 1.1.0, which
    # dropped FileResponse's `method` kwarg — every static asset 500s and the
    # UI is blank. Apply the upstream commit that removes the kwarg.
    nixpkgs.overlays = [
      (final: prev: {
        spoolman = prev.spoolman.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            ./spoolman-patch-fileresponse-method.patch
          ];
          # The nixpkgs derivation installs a second copy of the source tree
          # under $out/runpath, which is what the launcher cd's into and which
          # Python then imports from (CWD is on sys.path). Patches only touch
          # the site-packages copy, so replace runpath's client.py with the
          # patched one after install.
          postInstall = (old.postInstall or "") + ''
            chmod +w $out/runpath/spoolman
            install -m 0444 \
              $out/lib/python*/site-packages/spoolman/client.py \
              $out/runpath/spoolman/client.py
          '';
        });
      })
    ];

    services.spoolman = {
      enable = true;
      port = cfg.port;
      listen = cfg.host;
    };

    systemd.services.spoolman.wantedBy =
      lib.mkForce (lib.optional cfg.autoStart "multi-user.target");

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];

    # Spoolman's SPA server uses Python's mimetypes, which reads /etc/mime.types.
    # Without it, .js assets are served as text/plain and browsers block them.
    environment.etc."mime.types".source = "${pkgs.mailcap}/etc/mime.types";
  };
}
