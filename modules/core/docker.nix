let
  docker = {
    virtualisation.docker.enable = true;
  };
in
{
  nixos.modules.development = docker;
  nixos.modules.server-admin = docker;
}
