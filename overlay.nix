final: prev: {
  mkSbtDerivation = prev.callPackage ./lib/sbt-derivation.nix {};

  sbt = prev.sbt.overrideAttrs (old: {
    passthru =
      (old.passthru or {})
      // {
        mkDerivation = args: prev.lib.warn "sbt.mkDerivation is deprecated. Use mkSbtDerivation instead." (final.mkSbtDerivation args);
      };
  });
}
