{ stdenv, writeScript, runCommand, sbt, lib }:

with lib;

let
  propertiesFromEnv = [ "sbt.boot.directory" "sbt.global.base" "sbt.ivy.home" ];

  envVarNameFor = let
    normalize = replaceStrings [ "." ] [ "_" ];
    compose = f: g: x: f (g x);
  in compose toUpper normalize;

  callCheckAndSet = prop:
    "check_and_set ${escapeShellArg (envVarNameFor prop)} ${
      escapeShellArg prop
    }";

  script = writeScript "sbt-custom-script-${sbt.version}" ''
    #!${stdenv.shell}
    set -eu

    cmd=("${sbt}/bin/sbt")

    function check_and_set {
      var_name="$1"
      property_name="$2"

      if [ ! -z "''${!var_name:-}" ]; then
        cmd=(''${cmd[@]} "-D''${property_name}=''${!var_name}")
      fi
    }

    ${concatStringsSep "\n" (map callCheckAndSet propertiesFromEnv)}

    exec "''${cmd[@]}" "$@"
  '';
in runCommand "sbt-custom-${sbt.version}" { } ''
  mkdir -p $out/bin
  ln -s ${script} $out/bin/sbt
''
