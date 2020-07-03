{ pkgs ? import ./nix/pkgs.nix }:
let inherit (pkgs) sbt nix-gitignore makeWrapper jdk14_headless;
in sbt.mkDerivation rec {
  pname = "jarnitor";
  version = "0.1.0";

  src = nix-gitignore.gitignoreSource [ "*.nix" "nix/" ] ./.;

  nativeBuildInputs = [ makeWrapper ];

  depsSha256 = "1b8xmr2waq715v63p7ja66pji2hpkfm3yni6ki6bhydiy4yk7vkq";
  keepCompilerBridge = false;

  buildPhase = ''
    sbt stage
  '';

  installPhase = ''
    mkdir -p $out/share/java/${pname} $out/bin
    cp target/universal/stage/lib/* $out/share/java/${pname}

    makeWrapper ${jdk14_headless}/bin/java $out/bin/${pname} \
      --add-flags "-cp \"$out/share/java/${pname}/*\" me.zanini.jarnitor.Boot"
  '';
}
