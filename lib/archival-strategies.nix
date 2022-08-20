{
  gnutar,
  zstd,
  rsync,
  stow,
}: let
  directoryBasedProps = {
    outputHashMode = "recursive";
    fileExtension = "";
    packerFragment = ''
      mkdir -p $out
      cp -ar project/{.sbtboot,.boot,.ivy,.coursier} $out
    '';
  };
in {
  "tar" = {
    outputHashMode = "flat";
    fileExtension = ".tar";
    nativeBuildInputs = [gnutar];
    packerFragment = ''
      tar --owner=0 --group=0 --numeric-owner --format=gnu \
        --sort=name --mtime="@$SOURCE_DATE_EPOCH" \
        -C project -cf "$out" .sbtboot .boot .ivy .coursier
    '';
    extractorFragment = deps: ''
      tar -C "$target/project" -xpf ${deps}
    '';
  };
  "tar+zstd" = {
    outputHashMode = "flat";
    fileExtension = ".tar.zst";
    nativeBuildInputs = [gnutar zstd];
    packerFragment = ''
      tar --owner=0 --group=0 --numeric-owner --format=gnu \
        --sort=name --mtime="@$SOURCE_DATE_EPOCH" \
        -I 'zstd -c --fast=3 -' \
        -C project -cf "$out" .sbtboot .boot .ivy .coursier
    '';
    extractorFragment = deps: ''
      tar -I zstd -C "$target/project" -xpf ${deps}
    '';
  };
  "copy" =
    directoryBasedProps
    // {
      nativeBuildInputs = [rsync];
      extractorFragment = deps: ''
        rsync -qrlp --chmod=Dug=rwx,Fug=r ${deps}/ "$target/project/"
      '';
    };
  "link" =
    directoryBasedProps
    // {
      nativeBuildInputs = [stow];
      extractorFragment = deps: ''
        mkdir -p "$target/project"
        stow -t "$target/project" -d ${builtins.dirOf deps} --no-folding ${builtins.baseNameOf deps}
      '';
    };
}
