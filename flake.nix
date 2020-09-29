{
  description = "sbt-derivation";

  outputs = { self }: {
    overlay = import ./default.nix;
  };
}
