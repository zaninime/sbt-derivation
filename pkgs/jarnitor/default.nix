{ pkgs ? import ./nix/pkgs.nix }:
let inherit (pkgs) sbt nix-gitignore makeWrapper jdk12_headless;
in sbt.mkDerivation rec {
  pname = "jarnitor";
  version = "0.1.0";

  src = nix-gitignore.gitignoreSource [ "*.nix" "nix/" ] ./.;

  nativeBuildInputs = [ makeWrapper ];

  depsSha256 = "0v4pk3l4mkwk8dgf24929dwi9jsqyvyczghg1lhh2lgnfqf08mij";
  keepCompilerBridge = false;

  buildPhase = ''
    sbt stage
  '';

  installPhase = ''
    mkdir -p $out/share/java/${pname} $out/bin
    cp target/universal/stage/lib/* $out/share/java/${pname}

    makeWrapper ${jdk12_headless}/bin/java $out/bin/${pname} \
      --add-flags "-cp \"$out/share/java/${pname}/*\" me.zanini.jarnitor.Boot"
  '';
}
