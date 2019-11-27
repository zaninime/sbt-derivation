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
      name = "${name}-deps";
      inherit src patches;

      nativeBuildInputs = [ customSbt gnused ]
        ++ (stripOutSbt nativeBuildInputs);

      outputHash = depsSha256;
      outputHashAlgo = "sha256";
      outputHashMode = "recursive";

      impureEnvVars = lib.fetchers.proxyImpureEnvVars
        ++ [ "GIT_PROXY_COMMAND" "SOCKS_SERVER" ];

      buildPhase = args.depsBuildPhase or ''
        runHook preBuild

        sbt compile

        runHook postBuild
      '';

      installPhase = args.depsInstallPhase or ''
        runHook preInstall

        mkdir -p $out

        cp -ar "$SBT_IVY_HOME" $out
        cp -ar "$COURSIER_CACHE" $out
        cp -ar "$SBT_BOOT_DIRECTORY" $out

        runHook postInstall
      '';

      fixupPhase = args.depsFixupPhase or ''
        runHook preFixup

        find $out -name '*.properties' -type f -exec sed -i '/^#/d' {} \;
        find $out -name '*.lock' -delete
        find $out -name '*.log' -delete

        find $out -name 'org.scala-sbt-compiler-bridge_*' -type d -print0 | xargs -0 rm -rf

        runHook postFixup
      '';
    });
  in stdenv.mkDerivation (depsAttrs // overrideDepsAttrs depsAttrs);
in stdenv.mkDerivation (sbtEnv // args // {
  inherit deps;
  nativeBuildInputs = [ customSbt ] ++ (stripOutSbt nativeBuildInputs);

  preBuild = (args.preBuild or "") + ''
    cp -r $deps ${depsDir}
    chmod -R +rwX ${depsDir}
  '';
})
