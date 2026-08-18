{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.core.packages;
in
{
  options.myModules.core.packages.enable =
    lib.mkEnableOption "baseline system packages";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      vim
      wget
      git
      killall
      ffmpeg-full
      ungoogled-chromium
      transmission_4-gtk
      blender
	obsidian
    ];
  };
}
