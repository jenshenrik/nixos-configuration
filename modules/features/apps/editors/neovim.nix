{ config, pkgs, lib, ... }:

let
  cfg = config.myModules.features.apps.editors.neovim;
in
{
  options.myModules.features.apps.editors.neovim.enable =
    lib.mkEnableOption "Neovim configured to load an external LazyVim config with Mason support";

  config = lib.mkIf cfg.enable {
    # Install Neovim itself. Using the unwrapped package keeps Nix from
    # managing an init.lua so LazyVim (installed by the user into
    # ~/.config/nvim) is free to take over.
    environment.systemPackages = with pkgs; [
      neovim

      # Tooling LazyVim and its default extras expect on PATH.
      git
      gcc
      gnumake
      unzip
      wget
      curl
      ripgrep
      fd
      tree-sitter

      # Language runtimes Mason relies on to fetch/build LSPs, DAPs,
      # linters and formatters. Mason downloads prebuilt binaries which
      # normally do not run on NixOS; nix-ld (enabled below) lets them
      # find a dynamic linker and common libraries.
      nodejs
      python3
      python3Packages.pip
      cargo
      rustc
      go
      lua5_1
      luarocks

      # Clipboard providers (LazyVim autodetects these).
      wl-clipboard
      xclip
    ];

    # Make prebuilt binaries fetched by Mason executable on NixOS.
    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc
        zlib
        openssl
        curl
        icu
        libxml2
        libgcc
      ];
    };

    # Make nvim the default editor system-wide.
    environment.variables.EDITOR = "nvim";

    # Nerd Font so file-tree/statusline icons render correctly.
    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
    ];
  };
}
