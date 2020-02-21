{ lib, stdenv, callPackage, sbt, gnused }:

{ name ? "${args'.pname}-${args'.version}", src, nativeBuildInputs ? [ ]
, passthru ? { }, patches ? [ ]

  # A function to override the dependencies derivation
, overrideDepsAttrs ? (_oldAttrs: { })

# depsSha256 is the sha256 of the dependencies
, depsSha256

, ... }@args':

with builtins;
with lib;

let
  customSbt = callPackage ../custom-sbt { inherit sbt; };
  args = removeAttrs args' [ "overrideDepsAttrs" "depsSha256" ];
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
      name = "${name}-deps.tar.gz";
      inherit src patches;

      nativeBuildInputs = [ customSbt gnused ]
        ++ (stripOutSbt nativeBuildInputs);

      outputHash = depsSha256;
      outputHashAlgo = "sha256";
      outputHashMode = "flat";

      impureEnvVars = lib.fetchers.proxyImpureEnvVars
        ++ [ "GIT_PROXY_COMMAND" "SOCKS_SERVER" ];

      buildPhase = args.depsBuildPhase or ''
        runHook preBuild

        sbt compile

        find ${depsDir} -name '*.properties' -type f -exec sed -i '/^#/d' {} \;
        find ${depsDir} -name '*.lock' -delete
        find ${depsDir} -name '*.log' -delete
        find ${depsDir} -name 'org.scala-sbt-compiler-bridge_*' -type f -print0 | xargs -0 rm -rf

        runHook postBuild
      '';

      installPhase = args.depsInstallPhase or ''
        runHook preInstall

        tar --owner=0 --group=0 --numeric-owner --format=gnu \
          --sort=name --mtime="@$SOURCE_DATE_EPOCH" \
          -czf $out ${depsDir}

        runHook postInstall
      '';
    });
  in stdenv.mkDerivation (depsAttrs // overrideDepsAttrs depsAttrs);
in stdenv.mkDerivation (sbtEnv // args // {
  inherit deps;
  nativeBuildInputs = [ customSbt ] ++ (stripOutSbt nativeBuildInputs);

  postConfigure = (args.postConfigure or "") + ''
    echo extracting dependencies

    tar xf $deps
    chmod -R +rwX ${depsDir}
  '';
})
