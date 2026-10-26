{
  nixos.modules = {
    workstation = { pkgs, ... }: {
      users.users.jenshenrik.packages = with pkgs; [
        godot
        legcord
      ];
    };

    development = { pkgs, ... }: {
      users.users.jenshenrik.packages = with pkgs; [ opencode ];
    };
  };
}
