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
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
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
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;

    # FIX 1: Audio Quantums & Rate
    # Forcing a specific rate prevents sample-rate switching pops.
    # Higher quantums prevent buffer underruns (crackling).
    extraConfig.pipewire."99-input-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 1024;
        "default.clock.min-quantum" = 1024;
        "default.clock.max-quantum" = 4096;
      };
    };

    # FIX 2: WirePlumber Bluetooth Configuration
    # Replaced the old pipewire module config with modern WirePlumber logic.
    wireplumber.extraConfig = {
      "10-bluez" = {
        "monitor.bluez.properties" = {
          "bluez5.enable-sbc-xq" = true;
          "bluez5.enable-msbc" = true;
          "bluez5.enable-hw-volume" = true;
          "bluez5.headroom" = 8192;
          # Switched priority: SBC-XQ is often more stable on Linux/Asahi than AAC
          "bluez5.codecs" = [ "sbc_xq" "aac" "sbc" ];
        };
      };
    };
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

  users.groups.tailscaled = { };
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
  # ⚙️ POWER MANAGEMENT
  # -------------------------------------------------------------------

  # Note: powertop auto-tune can sometimes be too aggressive with 
  # USB autosuspend on Asahi. If trackpad lags, disable this.
  powerManagement.powertop.enable = true;

  services = {
    # Disable GNOME power profiles to avoid conflicts with TLP
    power-profiles-daemon.enable = false;

    tlp = {
      enable = true;
      settings = {
        # Removed STOP_CHARGE_THRESH_BAT0 to avoid conflict with 
        # the custom services.battery-limiter module.

        # Apple Silicon (ARM) handles scaling differently than Intel.
        # 'schedutil' is often preferred for responsiveness on M-series chips.
        CPU_SCALING_GOVERNOR_ON_AC = "schedutil";
        CPU_SCALING_GOVERNOR_ON_BAT = "schedutil";

        # Keeping these as defaults, though effect varies by kernel support
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;
      };
    };
  };

  # -------------------------------------------------------------------
  # ⚙️ BLUETOOTH CONFIGURATION (Corrected)
  # -------------------------------------------------------------------
  hardware.bluetooth.enable = true;

  hardware.bluetooth.settings = {
    General = {
      Experimental = "true";
      AutoEnable = "true";
      # FastConnectable improves reconnection reliability and audio handshakes
      FastConnectable = "true";
    };
    Policy = {
      AutoEnable = "true";
      AutoConnect = "true";
    };
  };

  # Enable the Blueman applet
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
    jq
    waybar-tailscale-status
    tailscale-exit-node-selector
    envsubst
    postgresql
    brightnessctl
    firefox-nightly-bin
  ];
  programs.zsh.enable = true;
  programs.mtr.enable = true;
  programs.gnupg.agent = { enable = true; enableSSHSupport = true; };
  services.openssh.enable = true;
  system.stateVersion = "25.11";
}
