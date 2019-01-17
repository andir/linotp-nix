{ pkgs ? import <nixpkgs> {}}:
let
  python27 = pkgs.python27.override {
    packageOverrides = pkgs.callPackage ./deps.nix {};
  };
in
{
  linotp = pkgs.callPackage ./pkg.nix { python27Packages = python27.pkgs; };
}
