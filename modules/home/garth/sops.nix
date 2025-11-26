# modules/home/garth/sops.nix
{ config, pkgs, lib, inputs, ... }:

{
  sops = {
    age.keyFile = "/home/garth/.config/sops/age/keys.txt";
    defaultSopsFile = inputs.self + "/secrets.yaml";

    secrets.GEMINI_API_KEY = {
      path = "${config.home.homeDirectory}/.config/gemini/api-key";
      mode = "0400";
    };

    secrets.aws_access_key_id = { };
    secrets.aws_secret_access_key = { };

    templates."aws/credentials" = {
      path = "${config.home.homeDirectory}/.aws/credentials";
      content = ''
        [default]
        aws_access_key_id = ${config.sops.placeholder.aws_access_key_id}
        aws_secret_access_key = ${config.sops.placeholder.aws_secret_access_key}
      '';
    };

    templates."aws/config" = {
      path = "${config.home.homeDirectory}/.aws/config";
      content = ''
        [default]
        region = ap-southeast-2
        output = json
      '';
    };
  };
}
