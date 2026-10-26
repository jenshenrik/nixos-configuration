{
  nixos.modules.server-web = { config, ... }: {
    myModules.features.services.homepage.entries.fluidd = {
      group = "Printing";
      order = 10;
      item."Fluidd" = {
        icon = "fluidd.png";
        href = "http://fluidd.${config.myModules.features.services.adguardhome.localDomain}";
        description = "Neptune 4 Plus";
      };
    };
  };
}
