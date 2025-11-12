#!/usr/bin/env bash

# This script gathers all relevant NixOS configuration files into a single
# output file for easy sharing. It should be run from /etc/nixos/.

OUTPUT_FILE="a.txt"

# Clear the output file to start fresh.
> "$OUTPUT_FILE"

echo "Gathering NixOS configuration..."

# --- Add flake.nix ---
echo "############################################################" >> "$OUTPUT_FILE"
echo "##########          START flake.nix               ##########" >> "$OUTPUT_FILE"
echo "############################################################" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
cat flake.nix >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# --- Add configuration.nix ---
echo "############################################################" >> "$OUTPUT_FILE"
echo "##########       START configuration.nix          ##########" >> "$OUTPUT_FILE"
echo "############################################################" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
cat configuration.nix >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# --- Add home-garth.nix ---
echo "############################################################" >> "$OUTPUT_FILE"
echo "##########         START home-garth.nix           ##########" >> "$OUTPUT_FILE"
echo "############################################################" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
cat home-garth.nix >> "$OUTPUT_FILE"

# --- Add GEMINI.md ---
echo "############################################################" >> "$OUTPUT_FILE"
echo "##########          START gemini.md               ##########" >> "$OUTPUT_FILE"
echo "############################################################" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
cat GEMINI.md >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

echo "Done! Your configuration has been copied to $OUTPUT_FILE"
