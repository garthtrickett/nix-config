{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/battery-limiter.nix 
  ];

  # The cache settings have been moved to flake.nix for a cleaner and
  # more effective setup. No settings are needed here.

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
  services.xserver.xkb.options = "eurosign:e,caps:escape";
  services.printing.enable = true;

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
  # 👤 USER CONFIGURATION
  # -------------------------------------------------------------------
  users.users.garth = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager"];
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
  # 🔋 BATTERY LONGEVITY CONFIGURATION
  # -------------------------------------------------------------------
  # This uses the custom module we created in ./modules/battery-limiter.nix
  services.battery-limiter = {
    enable = true;
    threshold = 80; # This is optional, as 80 is the default.
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
