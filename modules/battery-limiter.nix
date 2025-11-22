# /etc/nixos/modules/battery-limiter.nix

{ config, lib, pkgs, ... }:

{
  # 1. DEFINE THE OPTIONS
  # This section creates the new options that will be available in our configuration.nix
  options.services.battery-limiter = {
    enable = lib.mkEnableOption "Set a battery charge threshold on boot";

    threshold = lib.mkOption {
      type = lib.types.int;
      default = 80;
      description = "The maximum battery charge percentage to allow.";
    };
  };

  # 2. IMPLEMENT THE FEATURE
  # This section generates the actual NixOS configuration if the feature is enabled.
  config = lib.mkIf config.services.battery-limiter.enable {
    # If 'services.battery-limiter.enable = true', then create this systemd service:
    systemd.services.set-battery-charge-threshold = {
      description = "Set the battery charge threshold to ${toString config.services.battery-limiter.threshold}%";

      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";

        # This command uses the 'threshold' option we defined above.
        # Added a check to ensure the path exists to prevent systemd failure logs on boot.
        ExecStart = "${pkgs.writeShellScriptBin "set-battery-threshold" ''
          #!/bin/sh
          BAT_PATH="/sys/class/power_supply/macsmc-battery/charge_control_end_threshold"
          if [ -f "$BAT_PATH" ]; then
            echo ${toString config.services.battery-limiter.threshold} > "$BAT_PATH"
          else
            echo "Battery threshold path not found: $BAT_PATH"
          fi
        ''}/bin/set-battery-threshold";
      };
    };
  };
}
