# /etc/nixos/overlays/asahi.nix
final: prev:

{
  asahi-audio = prev.asahi-audio.override {
    triforce-lv2 = prev.triforce-lv2;
  };
}
