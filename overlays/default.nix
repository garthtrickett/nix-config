# /etc/nixos/overlays/default.nix
final: prev:

(import ./qemu.nix final prev) //
(import ./asahi.nix final prev) //
(import ./theme.nix final prev) //
(import ./battery.nix final prev) //
(import ./bluetooth.nix final prev)
