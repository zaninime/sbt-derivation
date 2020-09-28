{
  description = "sbt-derivation";

  outputs = { self, nixpkgs }: {

    packages.x86_64-linux.custom-sbt =
      nixpkgs.legacyPackages.x86_64-linux.callPackage ./pkgs/custom-sbt { };

    defaultPackage.x86_64-linux =
      self.packages.x86_64-linux.custom-sbt;

    overlay = import ./default.nix;
  };
}
