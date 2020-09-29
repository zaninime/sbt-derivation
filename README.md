# sbt-derivation

`sbt-derivation` is an experimental method for building `sbt` projects with
Nix. Its main goal is to be compatible with the sandbox, therefore disabling
network access (and more) at build time.

## How?

The "trick" used is equivalent to the one used in the Go modules
infrastructure in Nix. Internally, `sbt-derivation` creates two derivations:
one for the dependencies and one for the actual build.

The dependencies derivation is a *fixed-output* derivation, which means it has a hash that needs to be changed each time the dependencies are updated or changed in any way. It's also far from trivial to calculate this hash programmatically, strictly from the project files. The proposed solution is *trust on first use* (aka let a build fail the first time and use the hash that Nix prints).

The actual build derivation copies the dependencies in the workspace before running the build step. The provided `sbt` is already configured to point to those.

## Getting started

This repo exports one overlay, which means it needs to be fed to `nixpkgs` itself.

If you keep your overlays in separate files, you could create a `sbt-derivation.nix`:

```nix
let
  repo = builtins.fetchTarball {
    url =
      "https://github.com/zaninime/sbt-derivation/archive/1ef212261cf7ad878c253192a1c8171de4d75b6d.tar.gz";
    sha256 = "1mz2s4hajc9cnrfs26d99ap4gswcidxcq441hg3aplnrmzrxbqbp";
  };
in import repo
```

If you want to try out something quickly, you can use this one-file example:

```nix
let
  sbt-derivation = import (builtins.fetchTarball {
    url =
      "https://github.com/zaninime/sbt-derivation/archive/1ef212261cf7ad878c253192a1c8171de4d75b6d.tar.gz";
    sha256 = "1mz2s4hajc9cnrfs26d99ap4gswcidxcq441hg3aplnrmzrxbqbp";
  });
in { pkgs ? import <nixpkgs> { overlays = [ sbt-derivation ]; } }:
pkgs.sbt.mkDerivation {
  pname = "my-package";
  version = "1.0.0";

  depsSha256 = "0000000000000000000000000000000000000000000000000000";

  src = ./.;

  buildPhase = ''
    sbt assembly
  '';

  installPhase = ''
    cp target/scala-*/*-assembly-*.jar $out
  '';
}
```

To use this as a flake input you can use something along the lines of

```nix
{
  description = "My Package";

  inputs.sbt-derivation = {
    type = "github";
    owner = "zaninime";
    repo = "sbt-derivation";
  };

  outputs = { self, nixpkgs, sbt-derivation }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [ sbt-derivation.overlay ];
      };
    in
    {
      defaultPackage.x86_64-linux = self.packages.x86_64-linux.my-package;
      packages.x86_64-linux.my-package = pkgs.sbt.mkDerivation {
        pname = "my-package";
        version = "1.0.0";

        depsSha256 = "0000000000000000000000000000000000000000000000000000";

        src = ./.;

        buildPhase = ''
          sbt assembly
        '';

        installPhase = ''
          cp target/scala-*/*-assembly-*.jar $out
        '';
      };
    };
}
```

⚠️ **Remember to update to the latest revision available!** The examples are not always kept up to date with the most recent development.

## Common problems

* Your build will be failing if you forget to remove or ignore the `target` folders in the root and the `project` directories. Remove those and try the build again.

## Gotchas

At the moment, when building the dependencies, a full `sbt compile` is being
run. From the tests I ran, neither `sbt update` nor `sbt updateFull` actually
populate the depedencies derivation completely.
