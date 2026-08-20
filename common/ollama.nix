{ config, lib, pkgs, ... }:
{
  home-manager.users.pj = {
    home.packages = with pkgs; if config.networking.hostName == "commandblock" then [
      ollama
      intel-compute-runtime
      level-zero
      ocl-icd
      vulkan-loader
      vulkan-tools
      curl
      jq
    ] else
    if config.networking.hostName == "autocrafter" then [
      ollama
      rocmPackages.rocm-runtime
      rocmPackages.rocm-core
      curl
      jq
    ] else
    [
      ollama
      curl
      jq
    ];

    systemd.user.services.ollama = if config.networking.hostName == "commandblock" then {
      Unit = {
        Description = "Ollama with Intel GPU";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.ollama}/bin/ollama serve";
        Environment = [
          "OLLAMA_HOST=127.0.0.1:11434"
          "OLLAMA_NUM_GPU=1"
          "ZES_ENABLE_SYSMAN=1"
          "LD_LIBRARY_PATH=${pkgs.intel-compute-runtime}/lib:${pkgs.level-zero}/lib:${pkgs.ocl-icd}/lib"
        ];
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    } else if config.networking.hostName == "autocrafter" then {
      Unit = {
        Description = "Ollama with AMD GPU";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.ollama}/bin/ollama serve";
        Environment = [
          "OLLAMA_HOST=127.0.0.1:11434"
          "OLLAMA_NUM_GPU=1"
        ];
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    } else {
      Unit = {
        Description = "Ollama CPU only";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.ollama}/bin/ollama serve";
        Environment = [
          "OLLAMA_HOST=127.0.0.1:11434"
        ];
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

  };
}