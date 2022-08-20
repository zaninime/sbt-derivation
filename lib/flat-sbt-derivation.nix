{pkgs, ...} @ args: let
  drvAttrs = pkgs.lib.removeAttrs ["pkgs"] args;
  mkSbtDerivation = pkgs.callPackage ./sbt-derivation.nix {};
in
  mkSbtDerivation drvAttrs
