# modules/home/garth/g-tui.nix
{ config, pkgs, lib, ... }:

{
  home.packages = [
    # Removed google-cloud-sdk as we are strictly using API Key now
    pkgs.glow
    pkgs.curl
    pkgs.jq
    pkgs.gum

    # --- GEMINI TUI (API Key Edition) ---
    (pkgs.writeShellScriptBin "g-tui" ''
      #!${pkgs.bash}/bin/bash
      
      set +e 

      # --- AUTHENTICATION LOGIC ---
      # 1. Environment Variable
      # 2. Sops Secret File
      
      KEY_FILE="$HOME/.config/gemini/api-key"
      
      if [ -z "$GEMINI_API_KEY" ]; then
        if [ -f "$KEY_FILE" ]; then
          GEMINI_API_KEY=$(cat "$KEY_FILE")
        fi
      fi

      if [ -z "$GEMINI_API_KEY" ]; then
        clear
        ${pkgs.gum}/bin/gum style --foreground 196 "Authentication Failed"
        echo "Could not find GEMINI_API_KEY."
        echo "Checked environment variable and $KEY_FILE"
        echo ""
        exit 1
      fi

      # API Key authentication passes the key as a URL query parameter
      URL_SUFFIX="?key=$GEMINI_API_KEY"

      # --- DYNAMIC MODEL FETCHING ---
      
      echo "Fetching models via API Key..."
      
      RAW_JSON=$(${pkgs.curl}/bin/curl -s --max-time 10 "https://generativelanguage.googleapis.com/v1beta/models$URL_SUFFIX")

      FETCH_SUCCESS=$?
      AVAILABLE_MODELS=""
      
      if [ $FETCH_SUCCESS -eq 0 ] && [ -n "$RAW_JSON" ]; then
        # Filter for models supporting generateContent
        AVAILABLE_MODELS=$(echo "$RAW_JSON" | ${pkgs.jq}/bin/jq -r '
          .models[] 
          | select(.supportedGenerationMethods | index("generateContent")) 
          | .name 
          | sub("models/"; "")' 2>/dev/null)
      fi

      # Define Fallback List
      FALLBACK_MODELS="gemini-exp-1121
      gemini-2.0-flash-exp
      gemini-1.5-pro-latest
      gemini-1.5-flash-latest
      gemini-1.5-flash-8b-latest"

      if [ -z "$AVAILABLE_MODELS" ]; then
         MENU_OPTIONS="$FALLBACK_MODELS
      Custom Input..."
      else
         MENU_OPTIONS="$AVAILABLE_MODELS
      Custom Input..."
      fi

      clear

      echo "Select Model:"
      CHOICE=$(echo "$MENU_OPTIONS" | ${pkgs.gum}/bin/gum choose --height 15 --cursor="> " --header "Available Models" --selected="gemini-exp-1121")

      if [ -z "$CHOICE" ]; then exit 1; fi

      if [ "$CHOICE" == "Custom Input..." ]; then
        MODEL=$(${pkgs.gum}/bin/gum input --placeholder "Enter model ID (e.g., gemini-exp-1121)")
      else
        MODEL=$(echo "$CHOICE" | awk '{print $1}')
      fi

      if [ -z "$MODEL" ]; then exit 1; fi

      # --- CHAT SESSION ---
      HISTORY_FILE="/tmp/gemini_history.md"
      
      if [ ! -f "$HISTORY_FILE" ]; then
        echo "# Gemini Chat Session" > "$HISTORY_FILE"
        echo "**Model:** \`$MODEL\` | **Auth:** API Key | **Started:** $(date)" >> "$HISTORY_FILE"
        echo "---" >> "$HISTORY_FILE"
      else
        echo -e "\n\n--- **Switched to model: \`$MODEL\`** ---\n" >> "$HISTORY_FILE"
      fi

      trap "echo 'Exiting...'; exit" SIGINT SIGTERM

      while true; do
        clear
        ${pkgs.glow}/bin/glow "$HISTORY_FILE" --width 100 --style dark
        echo ""

        PROMPT=$(${pkgs.gum}/bin/gum input --placeholder "Ask Gemini ($MODEL)... (Ctrl+C to quit)")

        if [ -z "$PROMPT" ]; then continue; fi

        if [ "$PROMPT" == "clear" ]; then
           echo "# Gemini Chat Session" > "$HISTORY_FILE"
           echo "**Model:** \`$MODEL\` | **Cleared:** $(date)" >> "$HISTORY_FILE"
           echo "---" >> "$HISTORY_FILE"
           continue
        fi

        echo -e "\n**You:** $PROMPT" >> "$HISTORY_FILE"
        
        SAFE_PROMPT=$(echo "$PROMPT" | ${pkgs.jq}/bin/jq -R .)
        JSON_DATA="{\"contents\":[{\"parts\":[{\"text\":$SAFE_PROMPT}]}]}"

        # --- EXECUTE REQUEST ---
        
        RESPONSE=$(${pkgs.gum}/bin/gum spin --spinner dot --title "Gemini ($MODEL) is thinking..." -- \
           echo "$JSON_DATA" | ${pkgs.curl}/bin/curl -s -H 'Content-Type: application/json' -d @- "https://generativelanguage.googleapis.com/v1beta/models/$MODEL:generateContent$URL_SUFFIX"
        )

        # --- PARSE RESPONSE ---
        
        TEXT=$(echo "$RESPONSE" | ${pkgs.jq}/bin/jq -r '.candidates[0].content.parts[0].text')

        if [ "$TEXT" != "null" ] && [ -n "$TEXT" ]; then
             echo -e "\n**Gemini:**\n$TEXT" >> "$HISTORY_FILE"
             echo -e "\n---" >> "$HISTORY_FILE"
        else
             ERROR_MSG=$(echo "$RESPONSE" | ${pkgs.jq}/bin/jq -r '.error.message')
             
             if [ "$ERROR_MSG" != "null" ] && [ -n "$ERROR_MSG" ]; then
                 echo -e "\n**Gemini Error:** $ERROR_MSG" >> "$HISTORY_FILE"
             else
                 echo -e "\n**Raw Error Output:**" >> "$HISTORY_FILE"
                 echo -e "\`\`\`\n$RESPONSE\n\`\`\`" >> "$HISTORY_FILE"
             fi
        fi
      done
    '')
  ];
}
