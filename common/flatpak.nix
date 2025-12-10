{ confg, pkgs, inputs, nix-flatpak, ...}:

{
  services.flatpak.enable = true;
  services.flatpak.packages = [
    "app.zen_browser.zen"
    "md.obsidian.Obsidian"
#    "com.visualstudio.code"
#    "net.nokyan.Resources"
#    "org.gaphor.Gaphor"
    "com.github.tchx84.Flatseal"
    "com.discordapp.Discord"
  ];
}
