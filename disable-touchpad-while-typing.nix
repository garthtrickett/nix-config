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
    systemd.user.services.disable-touchpad-while-typing = {
      Unit = {
        Description = "Disable touchpad while typing daemon";
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = let
          script = pkgs.writeShellScript "disable-touchpad-daemon" ''
            #!${pkgs.bash}/bin/bash
            set -euo pipefail

            # Define a file to store the process ID of our timer
            PID_FILE="$XDG_RUNTIME_DIR/disable-touchpad.pid"

            echo "Starting disable-touchpad-while-typing service..."
            sleep 3

            ${pkgs.libinput}/bin/libinput debug-events | ${pkgs.gnugrep}/bin/grep --line-buffered "KEY " | while read -r; do
              # --- TIMER RESET LOGIC ---
              # If a PID file exists, it means a timer is likely running.
              if [ -f "$PID_FILE" ]; then
                # Read the PID from the file
                PID=$(cat "$PID_FILE")
                # Check if a process with that PID is actually running, then kill it.
                # The 'ps' check prevents errors if the process finished but the PID file remains.
                if ps -p "$PID" > /dev/null; then
                  echo "Key press detected. Resetting previous timer (PID: $PID)."
                  kill "$PID"
                fi
              else
                echo "Key press detected. Disabling touchpad."
              fi

              # Always disable the touchpad on a key press.
              ${toggleScript}/bin/toggle-touchpad disable

              # --- START NEW TIMER ---
              # Start a new timer in the background.
              (
                sleep 0.4
                echo "Timer finished. Enabling touchpad."
                ${toggleScript}/bin/toggle-touchpad enable
                # Clean up the PID file once the timer is done.
                rm -f "$PID_FILE"
              ) &
              
              # Immediately write the PID of the new background process ($!) to our file.
              echo $! > "$PID_FILE"
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
