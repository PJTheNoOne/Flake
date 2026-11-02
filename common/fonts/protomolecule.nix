{ pkgs, ... }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "protomolecule";
  version = "1.0";

  src = pkgs.fetchFromGitHub {
    owner = "ThinkDualBrain";
    repo = "Protomolecule";
    rev = "main";
    hash = "sha256-P/7n2kPP4yeKQHlon+jOVlyjJYa4Bp5ZiZozJJJJmBQ=";
  };

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/share/fonts/truetype

    find . -type f \( \
      -iname '*.ttf' -o \
      -iname '*.otf' \
    \) -exec cp {} $out/share/fonts/truetype/ \;
  '';
}
