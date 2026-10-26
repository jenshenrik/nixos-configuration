{ lib, ... }:

{
  imports = [
    ./core
    ./hardware
    ./features
  ];

  options.legacy = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Expose the existing nixhome feature switches during its staged migration.";
  };

  options.nixos = {
    modules = lib.mkOption {
      type = lib.types.attrsOf lib.types.deferredModule;
      default = { };
      description = "Composable NixOS profiles and independently selectable features.";
    };

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
