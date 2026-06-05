{ pkgs, ... }:

{
  users.users.jenshenrik = {
    isNormalUser = true;
    description = "Jens Henrik Vogeliu";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    packages = with pkgs; [
      godot
      legcord
      opencode
    ];
  };
}
