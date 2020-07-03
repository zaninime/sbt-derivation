{ lib, stdenv, callPackage, sbt, gnused, zstd }:

{ name ? "${args'.pname}-${args'.version}", src, nativeBuildInputs ? [ ]
, passthru ? { }, patches ? [ ]

  # A function to override the dependencies derivation
, overrideDepsAttrs ? (_oldAttrs: { })

# depsSha256 is the sha256 of the dependencies
, depsSha256

# setting keepCompilerBridge to true doesn't delete the messy zip files of
# compiler bridges but tries to fix them up
, keepCompilerBridge ? true

  # whether to put the version in the dependencies' derivation too or not.
  # every time the version is changed, the dependencies will be re-downloaded
, versionInDepsName ? false

, ... }@args':

with builtins;
with lib;

let
  customSbt = callPackage ../custom-sbt { inherit sbt; };
  jarnitor = import ../jarnitor { };

  args =
    removeAttrs args' [ "overrideDepsAttrs" "depsSha256" "keepCompilerBridge" ];
  stripOutSbt = filter (x: x != sbt);

  depsDir = ".nix";

  sbtEnv = {
    SBT_BOOT_DIRECTORY = "${depsDir}/boot";
    SBT_GLOBAL_BASE = "${depsDir}/base";
    SBT_IVY_HOME = "${depsDir}/ivy";
    COURSIER_CACHE = "${depsDir}/coursier-cache";
  };

  deps = let
    depsAttrs = (sbtEnv // {
      name = "${if versionInDepsName then name else args'.pname}-deps.tar.zst";
      inherit src patches;

      nativeBuildInputs = [ customSbt gnused zstd ]
        ++ (stripOutSbt nativeBuildInputs);

      outputHash = depsSha256;
      outputHashAlgo = "sha256";
      outputHashMode = "flat";

      impureEnvVars = lib.fetchers.proxyImpureEnvVars
        ++ [ "GIT_PROXY_COMMAND" "SOCKS_SERVER" ];

      buildPhase = args.depsBuildPhase or ''
        runHook preBuild

        echo "running \"sbt compile\" to warm up the caches"
        sbt compile

        echo "stripping out comments containing dates"
        find ${depsDir} -name '*.properties' -type f -exec sed -i '/^#/d' {} \;

        echo "removing non-reproducible accessory files"
        find ${depsDir} -name '*.lock' -type f -print0 | xargs -0 rm -rfv
        find ${depsDir} -name '*.log' -type f -print0 | xargs -0 rm -rfv

        ${optionalString (!keepCompilerBridge) ''
          find ${depsDir} -name 'org.scala-sbt-compiler-bridge_*' -print0 | xargs -0 rm -rfv
        ''}
        ${optionalString keepCompilerBridge ''
          echo "fixing-up the compiler bridge"
          find ${depsDir} -name 'org.scala-sbt-compiler-bridge_*' -type f -print0 | xargs -0 ${jarnitor}/bin/jarnitor
        ''}

        runHook postBuild
      '';

      installPhase = args.depsInstallPhase or ''
        runHook preInstall

        tar --owner=0 --group=0 --numeric-owner --format=gnu \
          --sort=name --mtime="@$SOURCE_DATE_EPOCH" \
          -c ${depsDir} | zstd --fast=3 -o $out

        runHook postInstall
      '';
    });
  in stdenv.mkDerivation (depsAttrs // overrideDepsAttrs depsAttrs);
in stdenv.mkDerivation (sbtEnv // args // {
  inherit deps;
  nativeBuildInputs = [ customSbt zstd ] ++ (stripOutSbt nativeBuildInputs);

  postConfigure = (args.postConfigure or "") + ''
    echo extracting dependencies

    tar -I zstd -xf $deps
    chmod -R +rwX ${depsDir}
  '';
})
