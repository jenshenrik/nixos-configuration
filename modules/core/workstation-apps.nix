{ config, lib, ... }:

{
  nixos.modules = lib.optionalAttrs (!config.legacy) {
    workstation = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        ffmpeg-full
        ungoogled-chromium
        transmission_4-gtk
        blender
        obsidian
      ];
    };
  };
}
