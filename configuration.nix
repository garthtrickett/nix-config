{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # -------------------------------------------------------------------
  # ⚙️ NIX & CACHE CONFIGURATION - THE CORRECT UNSTABLE SETUP
  # -------------------------------------------------------------------
  # Using the cachix cache for nixos-apple-silicon as you specified.
  # This is the key to fast builds on the unstable channel.
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
  # 🔧 NIXOS PACKAGE PATCH (OVERLAY) - A RELIABLE SAFETY NET
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

  # -------------------------------------------------------------------
  # 🍎 APPLE SILICON & CORE SERVICES
  # -------------------------------------------------------------------
  hardware.asahi.peripheralFirmwareDirectory = ./firmware;
  networking.wireless.iwd = { enable = true; settings.General.EnableNetworkingConfiguration = true; };
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "eurosign:e,caps:escape";
  services.printing.enable = true;

  # -------------------------------------------------------------------
  # 🔊 AUDIO CONFIGURATION (MANUAL METHOD + PATCH)
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
    home.stateVersion = "25.11"; # Match the unstable branch
  };

  # -------------------------------------------------------------------
  # 📦 SYSTEM PACKAGES AND SERVICES
  # -------------------------------------------------------------------
  environment.systemPackages = with pkgs; [ git vim wget ];
  programs.firefox.enable = true;
  programs.mtr.enable = true;
  programs.gnupg.agent = { enable = true; enableSSHSupport = true; };
  services.openssh.enable = true;
  system.stateVersion = "25.11"; # Match the unstable branch
}
