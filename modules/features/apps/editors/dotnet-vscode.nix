{
  nixos.modules.development = { pkgs, ... }: {
    programs.vscode = {
      enable = true;

      extensions = with pkgs.vscode-extensions; [
        ms-dotnettools.csharp
        ms-dotnettools.csdevkit
        #ms-dotnettools.dotnet-interactive-vscode
        ms-vscode.powershell
        ms-azuretools.vscode-docker
        editorconfig.editorconfig
        eamodio.gitlens
      ];
    };
  };
}
