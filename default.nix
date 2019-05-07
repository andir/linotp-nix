{ pkgs, ...}:
let
  srcPkgs = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs-channels/archive/1233c8d9e9bc463899ed6a8cf0232e6bf36475ee.tar.gz";
    sha256 = "0gs8vqw7kc2f35l8wdg7ass06s1lynf7qdx1a10lrll8vv3gl5am";
  }) {};
  python27 = srcPkgs.python27.override {
    packageOverrides = srcPkgs.callPackage ./deps.nix {};
  };
in
rec {
  linotp = srcPkgs.callPackage ./pkg.nix { python27Packages = python27.pkgs; };
  inherit python27; # required for the module
}
