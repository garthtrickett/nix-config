# modules/home/waybar/mullvad-status-script.nix
{ pkgs, ... }:

pkgs.writeShellScriptBin "waybar-mullvad-status" ''
  #!${pkgs.bash}/bin/bash
  set +e

  # Explicit paths
  MULLVAD="${pkgs.mullvad-vpn}/bin/mullvad"
  JQ="${pkgs.jq}/bin/jq"
  TIMEOUT="${pkgs.coreutils}/bin/timeout"

  # 1. Get Status with a timeout
  # We capture stdout and stderr together to catch errors
  RAW_OUTPUT=$($TIMEOUT 2s $MULLVAD status 2>&1)
  EXIT_CODE=$?

  # 2. Check for failure
  if [ $EXIT_CODE -ne 0 ] || [ -z "$RAW_OUTPUT" ]; then
    $JQ -n --arg text "No Service" --arg class "disconnected" --arg tooltip "Daemon Unreachable" \
      '{text: $text, class: $class, tooltip: $tooltip}'
    exit 0
  fi

  # 3. Parse the output
  # Example Format from your logs:
  # Connected
  #     Relay:                  jp-osa-wg-003
  
  if [[ "$RAW_OUTPUT" == *"Connected"* ]]; then
    # Extract the relay name using grep and awk
    # 1. grep for "Relay:"
    # 2. awk prints the last column (the server ID)
    SERVER=$(echo "$RAW_OUTPUT" | ${pkgs.gnugrep}/bin/grep "Relay:" | ${pkgs.gawk}/bin/awk '{print $NF}')
    
    # Fallback if parsing failed but it says Connected
    if [ -z "$SERVER" ]; then
      SERVER="VPN On"
    fi

    $JQ -n --arg text " $SERVER" --arg class "connected" --arg tooltip "$RAW_OUTPUT" \
      '{text: $text, class: $class, tooltip: $tooltip}'

  elif [[ "$RAW_OUTPUT" == *"Connecting"* ]]; then
    $JQ -n --arg text " Connecting" --arg class "connecting" --arg tooltip "$RAW_OUTPUT" \
      '{text: $text, class: $class, tooltip: $tooltip}'

  else
    $JQ -n --arg text " VPN Off" --arg class "disconnected" --arg tooltip "Disconnected" \
      '{text: $text, class: $class, tooltip: $tooltip}'
  fi
''
