# /etc/nixos/disable-touchpad-while-typing.nix
{ config, pkgs, lib, ... }:

let
  cfg = config.services.disable-touchpad-while-typing;
  toggleScript = import ./toggle-touchpad.nix { inherit pkgs; };
in
{
  options.services.disable-touchpad-while-typing = {
    enable = lib.mkEnableOption "Disable touchpad while typing service";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.keyd pkgs.gawk ];

    systemd.user.services.disable-touchpad-while-typing = {
      Unit = {
        Description = "Intelligently disable touchpad while typing daemon";
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = let
          script = pkgs.writeShellScript "disable-touchpad-daemon" ''
            #!${pkgs.bash}/bin/bash
            set -euo pipefail

            PID_FILE="$XDG_RUNTIME_DIR/disable-touchpad.pid"

            echo "Starting intelligent touchpad daemon using 'keyd monitor'..."
            sleep 3

            # Pipe 'keyd monitor' through 'grep' to listen ONLY to the virtual keyboard.
            # This filters out the noisy raw hardware events, preventing multiple triggers.
            ${pkgs.keyd}/bin/keyd monitor | ${pkgs.gnugrep}/bin/grep --line-buffered "keyd virtual keyboard" | while read -r line; do
              
              if echo "$line" | ${pkgs.gnugrep}/bin/grep -q "down"; then
                
                KEY=$(${pkgs.gawk}/bin/awk '{print $(NF-1)}' <<< "$line")
                
                case $KEY in
                  leftshift|rightshift|leftcontrol|rightcontrol|leftalt|rightalt|leftmeta|rightmeta|capslock)
                    continue
                    ;;
                  *)
                    # This is a regular key, proceed.
                    ;;
                esac

                # --- TIMER LOGIC ---
                if [ -f "$PID_FILE" ]; then
                  PID=$(cat "$PID_FILE")
                  if ps -p "$PID" > /dev/null; then
                    kill "$PID"
                  fi
                fi

                ${toggleScript}/bin/toggle-touchpad disable

                (
                  sleep 0.3
                  ${toggleScript}/bin/toggle-touchpad enable
                  rm -f "$PID_FILE"
                ) &
                
                echo $! > "$PID_FILE"
              fi
            done
          '';
        in "${script}";
        Restart = "always";
        RestartSec = 3;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
