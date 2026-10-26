{
  nixos.shared = { config, lib, ... }:

  let
    cfg = config.myModules.features.shells.starship;
  in
  {
    options.myModules.features.shells.starship.enable =
      lib.mkEnableOption "Starship shell prompt";

    config = lib.mkIf cfg.enable {
      programs.starship.enable = true;
    };
  };
}
