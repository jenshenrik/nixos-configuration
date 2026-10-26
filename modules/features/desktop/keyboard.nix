{ ... }:
{
  nixos.modules.workstation = {
    services.xserver.xkb = {
      layout = "dk";
      variant = "";
    };
    console.keyMap = "dk-latin1";
  };
}
