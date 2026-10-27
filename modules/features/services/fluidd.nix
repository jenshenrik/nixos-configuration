{ config, lib, ... }:

let
  domain = config.localNetwork.domain;
  address = config.localNetwork.printerAddress;
in
{
  options.localNetwork.printerAddress = lib.mkOption {
    type = lib.types.str;
    description = "LAN address of the printer running Fluidd.";
  };

  config.nixos.modules.printing = { config, lib, ... }: {
    config = lib.mkMerge [
      (lib.mkIf config.services.adguardhome.enable {
        myModules.features.services.adguardhome.extraRewrites."fluidd.${domain}" = address;
      })
      (lib.mkIf config.services.homepage-dashboard.enable {
        myModules.features.services.homepage.entries.fluidd = {
          group = "Printing";
          order = 10;
          item."Fluidd" = {
            icon = "fluidd.png";
            href = "http://fluidd.${domain}";
            description = "Neptune 4 Plus";
          };
        };
      })
    ];
  };
}
