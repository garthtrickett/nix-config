# /etc/nixos/configuration.nix
{ config, lib, pkgs, ... }:

let
  # The Waybar status script provides visual feedback.
  waybar-battery-status = pkgs.writeShellScriptBin "waybar-battery-status" ''
    #!${pkgs.stdenv.shell}
    
    find_threshold_path() {
      if [ -f "/sys/class/power_supply/macsmc-battery/charge_control_end_threshold" ]; then
        echo "/sys/class/power_supply/macsmc-battery/charge_control_end_threshold"
      elif [ -f "/sys/class/power_supply/battery/charge_control_end_threshold" ]; then
        echo "/sys/class/power_supply/battery/charge_control_end_threshold"
      else
        exit 1
      fi
    }
    THRESHOLD_PATH=$(find_threshold_path)
    
    if [ ! -f "$THRESHOLD_PATH" ]; then
      exit 0
    fi

    CONFIGURED_LIMIT=${toString config.services.battery-limiter.threshold}
    CURRENT_LIMIT=$(cat "$THRESHOLD_PATH")

    if [ "$CURRENT_LIMIT" -eq "$CONFIGURED_LIMIT" ]; then
      printf '{"text": "󰌾", "tooltip": "Battery charge limit is ON (%s%%)"}' "$CONFIGURED_LIMIT"
    else
      printf '{"text": "", "tooltip": "Battery charge limit is OFF"}'
    fi
  '';
in
{
  imports = [
    ./hardware-configuration.nix
    ./modules/battery-limiter.nix
    ./modules/system/ydotool.nix # <-- NEW
    ./modules/system/keyd.nix    # <-- NEW
    ./modules/system/sudo.nix    # <-- NEW
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
  # 🖥️ GRAPHICAL ENVIRONMENT (HYPRLAND & GNOME)
  # -------------------------------------------------------------------
  services.xserver.enable = true;
  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;
  services.displayManager.sessionPackages = [ pkgs.hyprland ];

  # -------------------------------------------------------------------
  # 🎨 XDG DESKTOP PORTAL CONFIGURATION
  # -------------------------------------------------------------------
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
  # 🔊 AUDIO, 🔋 BATTERY, 👤 USER
  # -------------------------------------------------------------------
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  services.libinput = {
    enable = true;
    touchpad = {
      disableWhileTyping = false;
      tapping = true;
      naturalScrolling = false;
    };
  };

  services.battery-limiter = {
    enable = true;
    threshold = 80;
  };

  users.users.garth = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "input" ];
    shell = pkgs.zsh;
    packages = with pkgs; [ tree networkmanagerapplet gnome-tweaks waybar-battery-status ];
  };
  users.users.root.home = lib.mkForce "/root";

  # -------------------------------------------------------------------
  # 🛠️ SYSTEM-WIDE PACKAGES & SETTINGS
  # -------------------------------------------------------------------
  # The toggle script is installed here so you can call it from the command line.
  environment.systemPackages = with pkgs; [ git vim wget keyd toggle-battery-limit ];
  programs.zsh.enable = true;
  programs.firefox.enable = true;
  programs.mtr.enable = true;
  programs.gnupg.agent = { enable = true; enableSSHSupport = true; };
  services.openssh.enable = true;
  system.stateVersion = "25.11";
}
