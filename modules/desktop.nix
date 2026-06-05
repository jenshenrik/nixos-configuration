{ ... }:

{
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  services.xserver.xkb = {
    layout = "dk";
    variant = "";
  };

  console.keyMap = "dk-latin1";
  services.printing.enable = true;
  programs.firefox.enable = true;
}
