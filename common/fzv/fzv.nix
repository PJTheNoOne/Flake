# fzv: ripgrep + fzf search that opens results in vi.
# Installed for every host via common/dev.nix.
{ writeShellApplication, ripgrep, fzf, bat, vim }:

writeShellApplication {
  name = "fzv";
  # These are put on PATH inside the script, so it works even if
  # they aren't installed system-wide.
  runtimeInputs = [ ripgrep fzf bat vim ];
  text = builtins.readFile ./fzv.sh;
}
