# Placeholder. Replace this with the output of `nixos-generate-config --show-hardware-config`
# run on the actual nixhome server, then delete this comment.
{ lib, ... }:

{
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
