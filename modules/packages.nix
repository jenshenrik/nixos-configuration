{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    neofetch
    killall
    ffmpeg-full
    ungoogled-chromium
  ];
}
