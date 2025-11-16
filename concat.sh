#!/usr/bin/env bash

# This script recursively gathers all .nix files from the current directory,
# excluding specified folders, into a single output file for easy sharing.
# It should be run from your NixOS configuration directory (e.g., /etc/nixos/).

OUTPUT_FILE="a.txt"
EXCLUDE_PATHS=("./firmware" "./apple-silicon-support")

# --- Step 1: Initialize the output file ---
> "$OUTPUT_FILE"
echo "Gathering all .nix configuration files into $OUTPUT_FILE..."
echo "Excluding paths: ${EXCLUDE_PATHS[*]}"
echo ""


# --- Step 2: Build the argument list for the 'find' command ---
# This approach is safer than building a single string, as it handles
# special characters and spaces correctly without needing 'eval'.
find_args=(".")

# Add exclusion paths if the array is not empty
if [ ${#EXCLUDE_PATHS[@]} -gt 0 ]; then
    find_args+=(\()
    for path in "${EXCLUDE_PATHS[@]}"; do
        find_args+=(-path "$path" -o)
    done
    # After the loop, remove the trailing '-o' from the last element
    unset 'find_args[${#find_args[@]}-1]'
    find_args+=(\) -prune -o)
fi

# Add the final search criteria to find all files ending in .nix
find_args+=(-name "*.nix" -type f)


# --- Step 3: Find and process each .nix file ---
# -print0 and 'read -d' handle all possible filenames safely (even with spaces).
find "${find_args[@]}" -print0 | sort -z | while IFS= read -r -d '' nix_file; do
  # Clean up the file path for the header (remove leading './')
  header_path="${nix_file#./}"

  echo "Adding: $header_path"

  # Group all 'echo' and 'cat' commands to write to the output file in one go.
  # This is more efficient as the file is opened only once per loop.
  {
    echo "############################################################"
    echo "##########          START ${header_path}          ##########"
    echo "############################################################"
    echo ""
    cat "$nix_file"
    echo ""
    echo ""
  } >> "$OUTPUT_FILE"
done


# --- Step 4: Finalization ---
echo ""
echo "Done! Your configuration has been gathered into $OUTPUT_FILE."
