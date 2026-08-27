{ config, lib, pkgs, ... }:
{
  # Install llama.cpp with GPU support
  environment.systemPackages = with pkgs; [
    vllm
  ];
}
