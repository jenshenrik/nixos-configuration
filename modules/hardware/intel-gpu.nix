{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.hardware.intel-gpu;
in
{
  options.myModules.hardware.intel-gpu = {
    enable = lib.mkEnableOption "Intel integrated GPU with VA-API hardware video acceleration";

    generation = lib.mkOption {
      type = lib.types.enum [ "legacy" "modern" ];
      default = "modern";
      description = ''
        Which Intel VA-API driver stack to install.
        - "modern": intel-media-driver (Broadwell / gen8 and newer).
        - "legacy": intel-vaapi-driver (i965), required for Ivy Bridge / Haswell
          (gen7 / gen7.5, e.g. HD Graphics 2500/4000, 4200/4400/4600).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.graphics = {
      enable = true;
      extraPackages = if cfg.generation == "legacy"
        then [ pkgs.intel-vaapi-driver ]
        else [ pkgs.intel-media-driver ];
    };

    # The legacy i965 driver is only picked up when LIBVA_DRIVER_NAME=i965 is
    # set; the modern driver is auto-detected.
    environment.sessionVariables = lib.mkIf (cfg.generation == "legacy") {
      LIBVA_DRIVER_NAME = "i965";
    };
  };
}
