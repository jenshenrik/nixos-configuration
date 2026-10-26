{
  nixos.modules.base = { pkgs, ... }: {
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

        ohMyZsh = {
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
