{ config, lib, pkgs, ... }:

let
  cfg = config.myModules.hardware.nvidia;
in
{
  options.myModules.hardware.nvidia.enable =
    lib.mkEnableOption "NVIDIA proprietary driver";

  config = lib.mkIf cfg.enable {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      modesetting.enable = true;
      # Save/restore VRAM across suspend so the GPU actually resumes.
      powerManagement.enable = true;
      powerManagement.finegrained = false;
      # Use the open kernel modules. Required to avoid the proprietary
      # nvidia_drm plane-fence semaphore failure on resume seen with the
      # 595.x driver on Ampere (Xid 13 after S3, kills the compositor).
      open = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    # Enable nvidia_drm fbdev so the DRM subsystem owns the framebuffer,
    # which improves modeset/resume behavior on Wayland.
    boot.kernelParams = [ "nvidia_drm.fbdev=1" ];
  };
}
