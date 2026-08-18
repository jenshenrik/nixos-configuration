{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.myModules.features.desktop.niri;
in
{
  imports = [ inputs.noctalia.nixosModules.default ];

  options.myModules.features.desktop.niri.enable =
    lib.mkEnableOption "Niri compositor session";

  config = lib.mkIf cfg.enable {
    # Niri scrollable-tiling Wayland compositor
    programs.niri.enable = true;

    # Wayland-friendly session bits
    security.polkit.enable = true;
    services.gnome.gnome-keyring.enable = true;
    programs.dconf.enable = true;

    # XDG desktop portals for screen sharing, file pickers, etc.
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
    };

    # greetd + tuigreet as the login manager, launching niri directly
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${lib.getExe pkgs.tuigreet} --time --remember --asterisks --cmd niri-session";
          user = "greeter";
        };
      };
    };

    # tuigreet writes its state file here
    systemd.tmpfiles.rules = [
      "d /var/cache/tuigreet 0755 greeter greeter - -"
    ];

    # Give the TTY greetd runs on a clean handoff
    systemd.services.greetd.serviceConfig = {
      Type = "idle";
      StandardInput = "tty";
      StandardOutput = "tty";
      StandardError = "journal";
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
    };

    # Auto-start noctalia as part of the graphical session (niri-session
    # activates graphical-session.target on login).
    programs.noctalia = {
      enable = true;
      package = inputs.noctalia.packages.${pkgs.system}.default;
      systemd.enable = true;
      recommendedServices.enable = true;
    };

    # Keyboard/console parity with the rest of the system
    services.xserver.xkb = {
      layout = "dk";
      variant = "";
    };
    console.keyMap = "dk-latin1";

    # Baseline userland for a niri session
    environment.systemPackages = with pkgs; [
      tuigreet
      alacritty
      fuzzel
      swaylock
      swayidle
      swaybg
      mako
      wl-clipboard
      grim
      slurp
      brightnessctl
      playerctl
      pavucontrol
      networkmanagerapplet
      xwayland-satellite
      # File browser + removable media helpers
      nautilus
      udiskie
    ];

    # Removable media: udisks2 exposes drives over D-Bus, gvfs lets
    # Nautilus mount/trash/network them, and udiskie automounts on insert.
    services.udisks2.enable = true;
    services.gvfs.enable = true;

    # Autostart udiskie for every user in the graphical session so USB
    # sticks mount automatically with a desktop notification.
    systemd.user.services.udiskie = {
      description = "Automount removable media (udiskie)";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.udiskie}/bin/udiskie --no-tray --automount --notify --file-manager ${pkgs.nautilus}/bin/nautilus";
        Restart = "on-failure";
      };
    };

    # Polkit needs an authentication agent in the graphical session,
    # otherwise apps like usbimager (which authorize via udisks2/polkit)
    # get a silent EACCES with no prompt.
    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome authentication agent";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
      };
    };
  };
}
