
{ pkgs, ... }:

{
  home-manager.users.pj = {
    home.packages = [
      # Main theme-switching script
      (pkgs.writeShellApplication {
        name = "theme-switch";

        runtimeInputs = with pkgs; [
          coreutils
          gnugrep
          jq
          procps
          glib
        ];

        text = builtins.readFile ./theme-switcher/switch.sh;
      })

      # Interactive Fuzzel theme selector
      (pkgs.writeShellApplication {
        name = "theme-switch-menu";

        runtimeInputs = with pkgs; [
          fuzzel
          jq
          coreutils
        ];

        # Inherit the Home Manager PATH so this script can find
        # the separately installed theme-switch command.
        inheritPath = true;

        text = ''
          palette_file="''${XDG_CONFIG_HOME:-"$HOME/.config"}/theme-switcher/palettes.json"

          if ! [[ -f "$palette_file" ]]; then
            echo "Palette file not found: $palette_file" >&2
            exit 1
          fi

          if selected_theme="$(
            jq -r '.themes | to_entries[] | .value.name' "$palette_file" |
              fuzzel --dmenu --prompt="Select theme: "
          )"; then

            if [[ -z "$selected_theme" ]]; then
              exit 0
            fi

            theme="$(
              jq -er --arg name "$selected_theme" \
                '.themes | to_entries[] | select(.value.name == $name) | .key' \
                "$palette_file"
            )"

            theme-switch "$theme"
          fi
        '';
      })
    ];

    xdg.configFile."theme-switcher/palettes.json".source =
      ./theme-switcher/palettes.json;

    # Fuzzel imports the runtime-generated color configuration.
    programs.fuzzel.settings.main.include =
      "/home/pj/.config/fuzzel/theme-switcher.ini";

    qt = {
      enable = true;

      platformTheme.name = "qtct";
      style.name = "Fusion";

      qt5ctSettings = {
        Appearance = {
          style = "Fusion";
          custom_palette = true;
          color_scheme_path =
            "/home/pj/.config/theme-switcher/qt-colors.conf";
        };
      };

      qt6ctSettings = {
        Appearance = {
          style = "Fusion";
          custom_palette = true;
          color_scheme_path =
            "/home/pj/.config/theme-switcher/qt-colors.conf";
        };
      };
    };
  };
}

