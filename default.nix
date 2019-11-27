self: super: {
  sbt = super.sbt.overrideAttrs (old: {
    passthru = (old.passthru or { }) // {
      mkDerivation = super.callPackage ./pkgs/sbt-derivation { };
    };
  });
}
