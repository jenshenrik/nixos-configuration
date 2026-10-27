let
  ffmpeg = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.ffmpeg-full ];
  };
in
{
  nixos.modules.workstation = ffmpeg;
  nixos.modules.media = ffmpeg;
}
