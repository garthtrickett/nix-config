# /etc/nixos/configuration.nix
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/battery-limiter.nix
  ];

  # -------------------------------------------------------------------
  # ⚙️ NIX & CACHE CONFIGURATION
  # -------------------------------------------------------------------
  nix.settings = {
    extra-substituters = [
      "https://nixos-apple-silicon.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
    ];
  };

  # -------------------------------------------------------------------
  # ⚙️ GENERAL SYSTEM SETTINGS
  # -------------------------------------------------------------------
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  time.timeZone = "Australia/Sydney";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  # -------------------------------------------------------------------
  # 🔧 NIXOS PACKAGE PATCH (OVERLAY) - Audio Fix
  # -------------------------------------------------------------------
  nixpkgs.overlays = [
    (final: prev: {
      asahi-audio = prev.asahi-audio.override {
        triforce-lv2 = prev.triforce-lv2;
      };
    })
  ];

  # -------------------------------------------------------------------
  # 🖥️ GRAPHICAL ENVIRONMENT (HYPRLAND & GNOME)
  # -------------------------------------------------------------------
  services.xserver.enable = true;
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
  services.displayManager.sessionPackages = [ pkgs.hyprland ];
  programs.hyprland.enable = true;

  # -------------------------------------------------------------------
  # 🍎 APPLE SILICON & CORE SERVICES
  # -------------------------------------------------------------------
  hardware.asahi.peripheralFirmwareDirectory = ./firmware;
  networking.wireless.iwd = { enable = true; settings.General.EnableNetworkingConfiguration = true; };
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "eurosign:e";
  services.printing.enable = true;

  # -------------------------------------------------------------------
  # ⌨️ ADVANCED KEY REMAPPING (CAPS to ESC/CTRL)
  # -------------------------------------------------------------------
  # --- THIS IS THE FINAL, CORRECT FIX ---
  # The 'extraConfig' option should ONLY contain the key definitions,
  # not the '[main]' header, which is handled by the NixOS module.
  services.keyd = {
    enable = true;
    keyboards."default" = {
      ids = [ "*" ];
      extraConfig = "capslock = overload(esc, control)";
    };
  };

  # -------------------------------------------------------------------
  # 🔊 AUDIO CONFIGURATION
  # -------------------------------------------------------------------
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;
  services.libinput.enable = true;

  # -------------------------------------------------------------------
  # 🔋 BATTERY LONGEVITY CONFIGURATION
  # -------------------------------------------------------------------
  services.battery-limiter = {
    enable = true;
    threshold = 80;
  };

  # -------------------------------------------------------------------
  # 👤 USER CONFIGURATION
  # -------------------------------------------------------------------
  users.users.garth = {
    isNormalUser = true;
    # User added to "keyd" group to resolve permissions.
    extraGroups = [ "wheel" "networkmanager" "keyd" ];
    shell = pkgs.bash;
    packages = with pkgs; [ tree networkmanagerapplet gnome-tweaks ];
  };
  users.users.root.home = lib.mkForce "/root";

  # -------------------------------------------------------------------
  # 🏡 HOME MANAGER CONFIGURATION for 'garth'
  # -------------------------------------------------------------------
  home-manager.users.garth = {
    imports = [ ./home-garth.nix ];
    home.stateVersion = "25.11";
  };

  # -------------------------------------------------------------------
  # 📦 SYSTEM PACKAGES AND SERVICES
  # -------------------------------------------------------------------
  environment.systemPackages = with pkgs; [ git vim wget ];
  programs.firefox.enable = true;
  programs.mtr.enable = true;
  programs.gnupg.agent = { enable = true; enableSSHSupport = true; };
  services.openssh.enable = true;
  system.stateVersion = "25.11";
}
