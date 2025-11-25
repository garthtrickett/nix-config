# /etc/nixos/overlays/qemu.nix
final: prev:
let
  fixQemu = pkg: pkg.overrideAttrs (old: {
    configureFlags = (old.configureFlags or [ ]) ++ [
      "--disable-nettle"
      "--disable-gcrypt"
      "--disable-gnutls"
      "--disable-crypto-afalg"
    ];
    buildInputs = builtins.filter
      (x:
        let
          name = x.pname or x.name or "";
        in
          !(prev.lib.strings.hasInfix "nettle" name ||
            prev.lib.strings.hasInfix "gcrypt" name ||
            prev.lib.strings.hasInfix "gnutls" name)
      )
      (old.buildInputs or [ ]);
  });
in
{
  qemu = fixQemu prev.qemu;
  qemu-user-static = fixQemu prev.qemu-user-static;
}
