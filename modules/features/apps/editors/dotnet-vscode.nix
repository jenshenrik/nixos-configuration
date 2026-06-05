{ config, pkgs, lib, ... }:

let
  cfg = config.myModules.features.apps.editors.dotnet-vscode;
in
{
  options.myModules.features.apps.editors.dotnet-vscode.enable =
    lib.mkEnableOption "VSCode with .NET extensions";

  config = lib.mkIf cfg.enable {
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