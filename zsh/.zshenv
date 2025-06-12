# Set ZDOTDIR to use XDG config directory
export ZDOTDIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

# Source the main zshenv if it exists
if [ -f "$ZDOTDIR/.zshenv" ]; then
  source "$ZDOTDIR/.zshenv"
fi