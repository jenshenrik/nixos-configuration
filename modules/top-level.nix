{ lib, ... }:

{
  imports = [
    ./core
    ./hardware
    ./features
  ];

  options.nixos = {
    modules = lib.mkOption {
      type = lib.types.attrsOf lib.types.deferredModule;
      default = { };
      description = "Composable NixOS profiles and independently selectable features.";
    };

    hosts = lib.mkOption {
      type = lib.types.attrsOf lib.types.deferredModule;
      default = { };
      description = "Host-specific NixOS module compositions.";
    };
  };
}
