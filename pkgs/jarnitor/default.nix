{ pkgs ? import ./nix/pkgs.nix }:
let inherit (pkgs) sbt nix-gitignore makeWrapper jdk14_headless;
in sbt.mkDerivation rec {
  pname = "jarnitor";
  version = "0.1.0";

  src = nix-gitignore.gitignoreSource [ "*.nix" "nix/" ] ./.;

  nativeBuildInputs = [ makeWrapper ];

  depsSha256 = "1ss7lkz0baxjps97lw5cvbs9w2zajxymfmgbj7kvcz5rgqxv07nm";
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
