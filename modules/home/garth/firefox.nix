# modules/home/garth/firefox.nix
{ config, pkgs, lib, inputs, ... }:

{
  programs.firefox = {
    enable = true;
    # Use the nightly binary from your overlay
    package = pkgs.firefox-nightly-bin;

    profiles.garth = {
      id = 0;
      name = "garth";
      isDefault = true;

      settings = {
        # 0 = Dark, 1 = Light, 2 = System (Automatic), 3 = Browser
        # This forces the "Website appearance" setting to Automatic
        "layout.css.prefers-color-scheme.content-override" = 2;

        # Force Firefox to use the XDG Portal for settings (DBus)
        # This is CRITICAL for reading the theme signal
        "widget.use-xdg-desktop-portal.settings" = 1;

        # Optional: General Wayland smoothness tweaks
        "gfx.webrender.all" = true;
        
        # Allow userChrome.css to be loaded
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };
    };
  };
}
