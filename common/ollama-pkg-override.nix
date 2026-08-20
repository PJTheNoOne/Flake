{ pkgs }:
pkgs.ollama.overrideAttrs (old: {
  buildInputs = old.buildInputs ++ [ pkgs.libclc pkgs.clang ];
  preBuild = (old.preBuild or "") + ''
    export OLLAMA_SYCL_BUILD=1
  '';
})