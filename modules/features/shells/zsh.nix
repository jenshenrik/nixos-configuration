{ config, pkgs, lib, ... }:

let
  cfg = config.myModules.features.shells.zsh;
in
{
  options.myModules.features.shells.zsh.enable =
    lib.mkEnableOption "Zsh as the default user shell";

  config = lib.mkIf cfg.enable {
    programs.zsh = {
        enable = true;

        enableCompletion = true;
        #autosuggestion.enable = true;
        syntaxHighlighting.enable = true;

        # history = {
        #     size = 50000;
        #     save = 50000;
        #     extended = true;
        #     share = true;
        #     ignoreDups = true;
        #     expireDuplicatesFirst = true;
        # };

        oh-my-zsh = {
            enable = true;
            plugins = [ "git" ];
            theme = "";
        };

        shellAliases = {
            #"git pu" = "git push -u origin HEAD";
        };
    };

    users.defaultUserShell = pkgs.zsh;
    users.users.jenshenrik.shell = pkgs.zsh;
  };
}
