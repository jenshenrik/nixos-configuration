{ lib, inputs, ... }:

let
  topLevel = lib.evalModules {
    specialArgs = { inherit inputs; };
    modules = [ ./top-level.nix { legacy = true; } ];
  };
in

{
  # Keep the unmigrated nixhome entry point consuming ordinary NixOS modules.
  imports = [
    topLevel.config.nixos.shared
    topLevel.config.nixos.modules.legacy
  ];
}
