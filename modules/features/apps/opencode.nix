{
  nixos.modules.development = { pkgs, ... }: {
    users.users.jenshenrik.packages = [ pkgs.opencode ];
  };
}
