{
  nixos.modules.server-admin = {
    users.users.jenshenrik.extraGroups = [ "docker" ];
  };

  nixos.modules.base = {
    users.users.jenshenrik = {
      isNormalUser = true;
      description = "Jens Henrik Vogelius";
      extraGroups = [
        "networkmanager"
        "wheel"
        "dialout"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEvgOtVv78YtjYzgK/OnWMllO5uTgcC6OmkaCUdUPBCj jens.henrik.vogelius@proton.me"
      ];
    };
  };
}
