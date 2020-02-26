let
  sources = import ./sources.nix;
  sbt-derivation = import ../../../.;
in import sources.nixpkgs { overlays = [ sbt-derivation ]; }
