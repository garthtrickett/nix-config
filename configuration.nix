# /etc/nixos/configuration.nix
{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/battery-limiter.nix
    ./modules/system/ydotool.nix
    ./modules/system/keyd.nix
    ./modules/system/waybar-scripts.nix
    ./modules/system/keyboard-backlight-toggle.nix
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
  
  # not needed anymore replaced by systemd-resolved
  # networking.resolvconf.enable = true;

  networking.extraHosts = ''
    127.0.0.1 garth.localhost.com.au
  '';
  time.timeZone = "Australia/Sydney";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  # -------------------------------------------------------------------
  # 🖥️ GRAPHICAL ENVIRONMENT (HYPRLAND)
  # -------------------------------------------------------------------
  services.xserver.enable = true;
  services.desktopManager.gnome.enable = false;
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
    config.common = {
      default = [ "hyprland" "gtk" ];
    };
  };

  # -------------------------------------------------------------------
  # 🍎 APPLE SILICON & CORE SERVICES
  # -------------------------------------------------------------------
  hardware.asahi.peripheralFirmwareDirectory = ./firmware;
  networking.wireless.iwd = { enable = true; settings.General.EnableNetworkingConfiguration = true; };
  services.resolved.enable = true;
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "eurosign:e";
  services.printing.enable = true;

  # -------------------------------------------------------------------
  # 🐳 VIRTUALISATION (DOCKER)
  # -------------------------------------------------------------------
  virtualisation.docker.enable = true;
  
  # -------------------------------------------------------------------
  # 🛡️ SUDO RULES
  # -------------------------------------------------------------------
  security.sudo.extraRules = [
    {
      users = [ "garth" ];
      commands = [
        {
          command = "${pkgs.toggle-battery-limit}/bin/toggle-battery-limit";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.tailscale}/bin/tailscale set --exit-node *";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

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

  users.groups.tailscaled = {};
  users.users.tailscaled = {
    group = "tailscaled";
    isSystemUser = true;
  };

  users.users.garth = {
    isNormalUser = true;
    extraGroups = [ "wheel" "input" "docker" ];
    shell = pkgs.zsh;
  };
  users.users.root.home = lib.mkForce "/root";

  # -------------------------------------------------------------------
  # 🔑 SECRETS MANAGEMENT (SYSTEM-WIDE)
  # -------------------------------------------------------------------
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/home/garth/.config/sops/age/keys.txt";
  };

  sops.secrets.tailscale_auth_key = {
    owner = "tailscaled";
    group = "tailscaled";
  };

  # -------------------------------------------------------------------
  # ⚙️ BLUETOOTH CONFIGURATION (Corrected)
  # -------------------------------------------------------------------
  # Enable the core Bluetooth daemon (under the 'hardware' attribute)
  hardware.bluetooth.enable = true;
  

  # Enable the Blueman applet, which provides a graphical interface
  # for managing Bluetooth devices from your system tray.
  services.blueman.enable = true;

  # -------------------------------------------------------------------
  #  VPN (TAILSCALE)
  # -------------------------------------------------------------------
  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets.tailscale_auth_key.path;
    extraUpFlags = [ "--accept-dns=true" ]; 
    useRoutingFeatures = "client"; 
  };

  # -------------------------------------------------------------------
  # 🛠️ SYSTEM-WIDE PACKAGES & SETTINGS
  # -------------------------------------------------------------------
  environment.systemPackages = with pkgs; [ 
    git 
    vim 
    wget 
    keyd 
    toggle-battery-limit 
    tailscale
    jq # Needed for the new robust scripts
    waybar-tailscale-status
    tailscale-exit-node-selector
    envsubst
    postgresql
    brightnessctl 
  ];
  programs.zsh.enable = true;
  programs.firefox.enable = true;
  programs.mtr.enable = true;
  programs.gnupg.agent = { enable = true; enableSSHSupport = true; };
  services.openssh.enable = true;
  system.stateVersion = "25.11";
}
