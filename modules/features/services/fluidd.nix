{ config, ... }:

let
  domain = config.localNetwork.domain;
in
{
  nixos.modules.server-web = {
    myModules.features.services.homepage.entries.fluidd = {
      group = "Printing";
      order = 10;
      item."Fluidd" = {
        icon = "fluidd.png";
        href = "http://fluidd.${domain}";
        description = "Neptune 4 Plus";
      };
    };
  };
}
