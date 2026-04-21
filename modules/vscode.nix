{ config, pkgs, lib, ... }:

let
  vscode = pkgs.vscode;

  extensions = with pkgs.vscode-extensions; [
    ms-dotnettools.csharp
    ms-dotnettools.csdevkit
    ms-dotnettools.dotnet-interactive-vscode
    ms-vscode.powershell
    ms-azuretools.vscode-docker
    editorconfig.editorconfig
    eamodio.gitlens
  ];
in
{
  options.myModules.dotnet-vscode.enable =
    lib.mkEnableOption "Enable VSCode with .NET extensions";

  config = lib.mkIf config.myModules.dotnet-vscode.enable {
    environment.systemPackages = [
      (vscode.override {
        vscodeExtensions = extensions;
      })
    ];
  };
}