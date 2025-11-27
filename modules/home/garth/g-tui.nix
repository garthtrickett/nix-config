# modules/home/garth/gemini.nix
{ config, pkgs, lib, ... }:

{
  home.packages = [
    # Dependencies specific to this module
    pkgs.google-cloud-sdk # Required for OAuth
    pkgs.glow # Required for Markdown rendering
    pkgs.curl
    pkgs.jq
    pkgs.gum

    # --- GEMINI TUI (GUM EDITION v8 - Scope Fix) ---
    (pkgs.writeShellScriptBin "gemini-tui" ''
      #!${pkgs.bash}/bin/bash
      
      # Disable strict error checking so network fails don't crash the script
      set +e 

      # --- AUTHENTICATION LOGIC ---
      
      AUTH_HEADER=""
      URL_SUFFIX=""
      AUTH_METHOD=""

      # FIX: Explicitly request the 'cloud-platform' scope.
      # This resolves the "insufficient authentication scopes" error.
      TOKEN=$(${pkgs.google-cloud-sdk}/bin/gcloud auth print-access-token --scopes=https://www.googleapis.com/auth/cloud-platform 2>/dev/null)
      
      if [ -n "$TOKEN" ]; then
        AUTH_METHOD="OAuth (gcloud)"
        AUTH_HEADER="Authorization: Bearer $TOKEN"
        URL_SUFFIX="" 
      elif [ -n "$GEMINI_API_KEY" ]; then
        AUTH_METHOD="API Key"
        # We use a dummy header for logic consistency if using key param
        AUTH_HEADER="X-Dummy: 0" 
        URL_SUFFIX="?key=$GEMINI_API_KEY"
      else
        ${pkgs.gum}/bin/gum style --foreground 196 "Error: No authentication method found."
        echo "Please either:"
        echo "1. Run 'gcloud auth login --update-adc' to use your Google Account (Recommended)"
        echo "2. Set the GEMINI_API_KEY environment variable."
        exit 1
      fi

      # --- DYNAMIC MODEL FETCHING ---
      
      echo "Fetching models via $AUTH_METHOD..."
      
      # Fetch logic
      if [ "$AUTH_METHOD" == "OAuth (gcloud)" ]; then
         RAW_JSON=$(${pkgs.curl}/bin/curl -s -H "$AUTH_HEADER" --max-time 10 "https://generativelanguage.googleapis.com/v1beta/models")
      else
         RAW_JSON=$(${pkgs.curl}/bin/curl -s --max-time 10 "https://generativelanguage.googleapis.com/v1beta/models$URL_SUFFIX")
      fi

      FETCH_SUCCESS=$?
      AVAILABLE_MODELS=""
      
      if [ $FETCH_SUCCESS -eq 0 ] && [ -n "$RAW_JSON" ]; then
        AVAILABLE_MODELS=$(echo "$RAW_JSON" | ${pkgs.jq}/bin/jq -r '
          .models[] 
          | select(.supportedGenerationMethods | index("generateContent")) 
          | .name 
          | sub("models/"; "")' 2>/dev/null)
      fi

      # Define Fallback List
      FALLBACK_MODELS="gemini-exp-1121 (3.0 Pro Preview)
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

      echo "Select Model ($AUTH_METHOD):"
      CHOICE=$(echo "$MENU_OPTIONS" | ${pkgs.gum}/bin/gum choose --height 15 --cursor="> " --header "Available Models" --selected="gemini-exp-1121 (3.0 Pro Preview)")

      if [ -z "$CHOICE" ]; then
        echo "No model selected."
        exit 1
      fi

      # Parse Choice
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
        echo "**Model:** \`$MODEL\` | **Auth:** $AUTH_METHOD | **Started:** $(date)" >> "$HISTORY_FILE"
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
        
        if [ "$AUTH_METHOD" == "OAuth (gcloud)" ]; then
            RESPONSE=$(${pkgs.gum}/bin/gum spin --spinner dot --title "Gemini ($MODEL) is thinking..." -- \
               echo "$JSON_DATA" | ${pkgs.curl}/bin/curl -s -H "$AUTH_HEADER" -H 'Content-Type: application/json' -d @- "https://generativelanguage.googleapis.com/v1beta/models/$MODEL:generateContent"
            )
        else
            RESPONSE=$(${pkgs.gum}/bin/gum spin --spinner dot --title "Gemini ($MODEL) is thinking..." -- \
               echo "$JSON_DATA" | ${pkgs.curl}/bin/curl -s -H 'Content-Type: application/json' -d @- "https://generativelanguage.googleapis.com/v1beta/models/$MODEL:generateContent$URL_SUFFIX"
            )
        fi

        # --- PARSE RESPONSE ---
        
        TEXT=$(echo "$RESPONSE" | ${pkgs.jq}/bin/jq -r '.candidates[0].content.parts[0].text')

        # Check if TEXT is valid (not null, not empty)
        if [ "$TEXT" != "null" ] && [ -n "$TEXT" ]; then
             echo -e "\n**Gemini:**\n$TEXT" >> "$HISTORY_FILE"
             echo -e "\n---" >> "$HISTORY_FILE"
        else
             # Parsing failed, look for error message
             ERROR_MSG=$(echo "$RESPONSE" | ${pkgs.jq}/bin/jq -r '.error.message')
             
             if [ "$ERROR_MSG" != "null" ] && [ -n "$ERROR_MSG" ]; then
                 echo -e "\n**Gemini Error:** $ERROR_MSG" >> "$HISTORY_FILE"
             else
                 # Fallback: Print raw response for debugging (e.g. HTML 404/403 or empty)
                 echo -e "\n**Raw Error Output:**" >> "$HISTORY_FILE"
                 echo -e "\`\`\`\n$RESPONSE\n\`\`\`" >> "$HISTORY_FILE"
             fi
        fi
      done
    '')
  ];
}
