{ config, lib, ... }:

let
  cfg = config.myModules.features.shells.direnv;
in
{
  options.myModules.features.shells.direnv.enable =
    lib.mkEnableOption "direnv with nix-direnv integration";

  config = lib.mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      silent = false;
    };
  };
}
