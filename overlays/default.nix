# /etc/nixos/overlays/default.nix
# This file now acts as an orchestrator, importing specific overlays and merging them.
final: prev:

(import ./qemu.nix final prev) //
(import ./asahi.nix final prev) //
(import ./theme.nix final prev) //
(import ./battery.nix final prev) //
(import ./tailscale.nix final prev) //
(import ./bluetooth.nix final prev) //
(import ./mesa-pin.nix final prev)
