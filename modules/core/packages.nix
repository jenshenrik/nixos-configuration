{ config, ... }:

let
  legacy = config.legacy;
in
{
  nixos.modules.${if legacy then "legacy" else "base"} = { config, lib, pkgs, ... }:

  let
    cfg = config.myModules.core.packages;
  in
  {
    options.myModules.core.packages = lib.optionalAttrs legacy {
      enable = lib.mkEnableOption "baseline system packages";
    };

    config = lib.mkIf (!legacy || cfg.enable) {
      environment.systemPackages = with pkgs; [
        vim
        wget
        git
        killall
      ] ++ lib.optionals legacy [
        ffmpeg-full
        ungoogled-chromium
        transmission_4-gtk
        blender
        obsidian
      ];
    };
  };
}
