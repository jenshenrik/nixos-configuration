{
  nixos.modules.development = {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      silent = false;
    };
  };
}
