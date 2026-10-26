{ lib, ... }:

{
  imports = [
    ./core
    ./hardware
    ./features
  ];

  options.nixos = {
    shared = lib.mkOption {
      type = lib.types.deferredModule;
      description = "Shared NixOS feature definitions, selected by the existing myModules options.";
    };

    hosts = lib.mkOption {
      type = lib.types.attrsOf lib.types.deferredModule;
      default = { };
      description = "Host-specific NixOS module compositions.";
    };
  };
}
