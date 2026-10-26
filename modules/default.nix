{ lib, inputs, ... }:

{
  # Keep the unmigrated nixhome entry point consuming ordinary NixOS modules.
  imports = [
    (lib.evalModules {
      specialArgs = { inherit inputs; };
      modules = [ ./top-level.nix ];
    }).config.nixos.shared
  ];
}
