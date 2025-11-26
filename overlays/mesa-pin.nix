# overlays/mesa-pin.nix
#
# This overlay pins the Mesa drivers to the version from a stable nixpkgs branch.
# This is a workaround for frequent crashes in graphics-intensive applications
# like Firefox on unstable channels for Asahi Linux.

self: super:
let
  # We check if 'nixpkgs-stable' has been passed in.
  # If it has, we use its mesa. Otherwise, we fall back to the default mesa
  # to ensure this overlay doesn't break other systems.
  mesa-stable = super.inputs.nixpkgs-stable.legacyPackages.${super.system}.mesa or super.mesa;
in
{
  mesa = mesa-stable;
}
