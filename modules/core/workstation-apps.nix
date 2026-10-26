{
  nixos.modules = {
    workstation = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        ffmpeg-full
        ungoogled-chromium
        blender
        obsidian
      ];
    };
  };
}
