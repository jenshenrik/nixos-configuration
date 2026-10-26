{ config, ... }:
let
  legacy = config.legacy;
in
{
  nixos.modules.${if legacy then "legacy" else "workstation"} = { config, lib, ... }:

  let
    cfg = config.myModules.features.desktop.audio;
  in
  {
    options = lib.optionalAttrs legacy {
      myModules.features.desktop.audio.enable =
        lib.mkEnableOption "desktop audio stack";
    };

    config = lib.mkIf (!legacy || cfg.enable) {
      services.pulseaudio.enable = false;
      security.rtkit.enable = true;

      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };
    };
  };
}
