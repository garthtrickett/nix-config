{ config, pkgs, lib, inputs, ... }:

{
  sops = {
    defaultSopsFile = inputs.self + "/secrets.yaml";
    age.keyFile = "/home/garth/.config/sops/age/keys.txt";
  };
}
