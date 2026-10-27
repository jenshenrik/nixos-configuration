{
  nixos.modules = {
    workstation = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        ungoogled-chromium
        blender
        obsidian
      ];
    };
  };
}
