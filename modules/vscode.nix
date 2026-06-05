{ config, pkgs, lib, ... }:

{
  options.myModules.dotnet-vscode.enable =
    lib.mkEnableOption "VSCode with .NET extensions";

  config = lib.mkIf config.myModules.dotnet-vscode.enable {
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