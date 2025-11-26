# modules/system/config/audio-battery-user.nix
{ config, pkgs, lib, ... }:

{
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;

    extraConfig.pipewire."99-input-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 1024;
        "default.clock.min-quantum" = 1024;
        "default.clock.max-quantum" = 4096;
      };
    };

    wireplumber.extraConfig = {
      "10-bluez" = {
        "monitor.bluez.properties" = {
          "bluez5.enable-sbc-xq" = true;
          "bluez5.enable-msbc" = true;
          "bluez5.enable-hw-volume" = true;
          "bluez5.headroom" = 8192;
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
}
