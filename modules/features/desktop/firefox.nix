{ config, ... }:
let
  legacy = config.legacy;
in
{
  nixos.modules.${if legacy then "legacy" else "workstation"} = { ... }:

  {
    programs.firefox.enable = true;
  };
}
