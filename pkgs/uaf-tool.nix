{ stdenv }:

stdenv.mkDerivation {
  pname = "uaf-tool";
  version = "0.1.0";
  src = ./uaf-tool.m;
  dontUnpack = true;

  buildPhase = ''
    $CC -fobjc-arc -framework Foundation $src -o uaf-tool
  '';

  installPhase = ''
    install -Dm755 uaf-tool $out/bin/uaf-tool
  '';

  meta.platforms = [ "aarch64-darwin" "x86_64-darwin" ];
}
