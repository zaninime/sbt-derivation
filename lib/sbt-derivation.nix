{
  lib,
  stdenv,
  callPackage,
  sbt,
}: {
  pname,
  version,
  src,
  nativeBuildInputs ? [],
  passthru ? {},
  patches ? [],
  #
  # A function [final => prev => attrset] to override the dependencies derivation
  overrideDepsAttrs ? (_: _: {}),
  #
  # The sha256 of the dependencies
  depsSha256,
  #
  # Command to run to let sbt fetch all the required dependencies for the build.
  depsWarmupCommand ? "sbt compile",
  #
  # Strategy to use to package and unpackage the dependencies
  # - copy: regular directory, copy before build
  # - link: regular directory, use GNU stow to link files
  # - tar: tar archive, not compressed
  # - tar+zstd tar archive, compressed
  depsArchivalStrategy ? "tar+zstd",
  #
  # Whether to further reduce the side of the dependencies derivation by removing duplicate files
  depsOptimize ? true,
  ...
} @ args: let
  drvAttrs =
    removeAttrs args ["overrideDepsAttrs" "depsSha256" "depsWarmupCommand" "depsPackingStrategy" "depsOptimize"];

  depsDir = ".nix";

  sbtEnv = {
    SBT_OPTS = (args.SBT_OPTS or "") + " --no-share";
    COURSIER_CACHE = "project/.coursier";
  };

  dependencies = (callPackage ./dependencies.nix { inherit sbt; }) {
    inherit src patches nativeBuildInputs sbtEnv;

    namePrefix = "${pname}-sbt-dependencies";
    sha256 = depsSha256;
    warmupCommand = depsWarmupCommand;
    archivalStrategy = depsArchivalStrategy;
    optimize = depsOptimize;
    overrideAttrs = overrideDepsAttrs;
  };
in
  stdenv.mkDerivation (sbtEnv
    // drvAttrs
    // {
      nativeBuildInputs = [sbt] ++ nativeBuildInputs;

      passthru.dependencies = dependencies;

      configurePhase = ''
        runHook preConfigure

        ${dependencies.extractor} .

        runHook postConfigure
      '';
    })
