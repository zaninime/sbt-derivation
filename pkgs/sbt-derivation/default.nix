{ lib, stdenv, callPackage, sbt, gnused, zstd, strip-nondeterminism, file, findutils }:

{ name ? "${args'.pname}-${args'.version}", src, nativeBuildInputs ? [ ]
, passthru ? { }, patches ? [ ]

  # A function to override the dependencies derivation
, overrideDepsAttrs ? (_oldAttrs: { })

# depsSha256 is the sha256 of the dependencies
, depsSha256

# whether to put the version in the dependencies' derivation too or not.
# every time the version is changed, the dependencies will be re-downloaded
, versionInDepsName ? false

  # command to run to let sbt fetch all the required dependencies for the build.
, depsWarmupCommand ? "sbt compile"

, ... }@args':

with builtins;
with lib;

let
  customSbt = callPackage ../custom-sbt { inherit sbt; };

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

      nativeBuildInputs = [ customSbt gnused zstd strip-nondeterminism file findutils ]
        ++ (stripOutSbt nativeBuildInputs);

      outputHash = depsSha256;
      outputHashAlgo = "sha256";
      outputHashMode = "flat";

      impureEnvVars = lib.fetchers.proxyImpureEnvVars
        ++ [ "GIT_PROXY_COMMAND" "SOCKS_SERVER" ];

      buildPhase = args.depsBuildPhase or ''
        runHook preBuild

        echo running \"${
          escapeShellArg depsWarmupCommand
        }\" to warm up the caches
        ${depsWarmupCommand}

        echo "stripping out comments containing dates"
        find ${depsDir} -name '*.properties' -type f -exec sed -i '/^#/d' {} \;

        echo "removing non-reproducible accessory files"
        find ${depsDir} -name '*.lock' -type f -print0 | xargs -r0 rm -rfv
        find ${depsDir} -name '*.log' -type f -print0 | xargs -r0 rm -rfv

        echo "fixing-up the compiler bridge"
        find ${depsDir} -name 'org.scala-sbt-compiler-bridge_*' -type f -print0 | xargs -r0 strip-nondeterminism

        echo "removing runtime jar"
        find ${depsDir} -name rt.jar -delete

        echo "removing empty directories"
        find ${depsDir} -type d -empty -delete

        runHook postBuild
      '';

      installPhase = args.depsInstallPhase or ''
        runHook preInstall

        tar --owner=0 --group=0 --numeric-owner --format=gnu \
          --sort=name --mtime="@$SOURCE_DATE_EPOCH" \
          -I 'zstd -c --fast=3 -' -c ${depsDir} -f $out

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
