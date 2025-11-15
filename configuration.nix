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
    experimental-features = [ "nix-command" "flakes" ];
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
  boot.kernelModules = [ "uinput" ];
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  time.timeZone = "Australia/Sydney";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  # -------------------------------------------------------------------
  # 🔧 NIXOS PACKAGE PATCH (OVERLAY)
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
  # 🎨 XDG DESKTOP PORTAL CONFIGURATION (FIX)
  # -------------------------------------------------------------------
  # This is crucial for Wayland applications (like Waybar) to function correctly.
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  # -------------------------------------------------------------------
  # 🍎 APPLE SILICON & CORE SERVICES
  # -------------------------------------------------------------------
  hardware.asahi.peripheralFirmwareDirectory = ./firmware;
  networking.wireless.iwd = { enable = true; settings.General.EnableNetworkingConfiguration = true; };
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "eurosign:e";
  services.printing.enable = true;

  # -------------------------------------------------------------------
  # ⌨️ KEY REMAPPING DAEMON (keyd)
  # -------------------------------------------------------------------
  services.keyd = {
    enable = true;
    keyboards."default" = {
      ids = [ "*" ];
      settings.main = { capslock = "overload(control, escape)"; };
    };
  };

  # -------------------------------------------------------------------
  # ⚙️ YDOTOOL SYSTEM SERVICE
  # -------------------------------------------------------------------
  systemd.services.ydotoold = {
    description = "ydotool daemon";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];
    serviceConfig = {
      Restart = "always";
      ExecStart = ''
        ${pkgs.ydotool}/bin/ydotoold \
          --socket-path=/run/ydotoold.sock \
          --socket-own=${config.users.users.garth.name}:${config.users.groups.input.name} \
          --socket-mode=0660
      '';
    };
  };

  # -------------------------------------------------------------------
  # 🔊 AUDIO CONFIGURATION, 🔋 BATTERY, 👤 USER CONFIGURATION, etc.
  # -------------------------------------------------------------------
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;
  services.libinput.enable = true;

  services.battery-limiter = {
    enable = true;
    threshold = 80;
  };

  users.groups.input = {};
  users.users.garth = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "input" ];
    shell = pkgs.bash;
    packages = with pkgs; [ tree networkmanagerapplet gnome-tweaks ];
  };
  users.users.root.home = lib.mkForce "/root";

  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660"
  '';

  home-manager = {
    backupFileExtension = "bak"; 
    users.garth = {
      imports = [ ./home-garth.nix ];
      home.stateVersion = "25.11";
    };
  };

  environment.systemPackages = with pkgs; [ git vim wget keyd ];
  programs.firefox.enable = true;
  programs.mtr.enable = true;
  programs.gnupg.agent = { enable = true; enableSSHSupport = true; };
  services.openssh.enable = true;
  system.stateVersion = "25.11";
}
