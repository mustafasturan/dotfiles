#!/bin/bash

set -euo pipefail

cat << EOF
  _________       __   ____ ___
 /   _____/ _____/  |_|    |   \______
 \_____  \_/ __ \   __\    |   /\____ \
 /        \  ___/|  | |    |  / |  |_> >>>>
/_______  /\___  >__| |______/  |   __/
        \/     \/               |__|

EOF

FONT_DIR="$HOME/.local/share/fonts"
DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles_backup"

echo "==> Installing Font Awesome (v5 & v6)..."

FA6_VER="6.7.2"
FA5_VER="5.15.4"
FA_DIR="$FONT_DIR/fontawesome"

if [[ ! -f "$FA_DIR/Font Awesome 6 Brands-Regular-400.otf" ]]; then
    mkdir -p "$FA_DIR"

    echo "⬇️ Downloading Font Awesome $FA6_VER..."
    wget -q "https://use.fontawesome.com/releases/v$FA6_VER/fontawesome-free-$FA6_VER-desktop.zip"

    echo "📦 Extracting..."
    unzip -q "fontawesome-free-$FA6_VER-desktop.zip"
    mv "fontawesome-free-$FA6_VER-desktop/otfs/"*.otf "$FA_DIR/"
    
    echo "🧹 Cleaning up..."
    rm -rf "fontawesome-free-$FA6_VER-desktop"*

    echo "⬇️ Downloading Font Awesome $FA5_VER..."
    wget -q "https://use.fontawesome.com/releases/v$FA5_VER/fontawesome-free-$FA5_VER-desktop.zip"
    
    echo "📦 Extracting..."
    unzip -q "fontawesome-free-$FA5_VER-desktop.zip"
    mv "fontawesome-free-$FA5_VER-desktop/otfs/"*.otf "$FA_DIR/"
    
    echo "🧹 Cleaning up..."
    rm -rf "fontawesome-free-$FA5_VER-desktop"*

    echo "🔄 Refreshing font cache..."
    fc-cache -f "$FONT_DIR" || echo "⚠️ Could not refresh font cache. Is fontconfig installed?"

    echo "✅ Font Awesome v5 and v6 installed."
else
    echo "✔️ Font Awesome already installed, skipping."
fi


JB_FONT_VERSION="3.4.0"
JB_FONT_DIR="$FONT_DIR/JetBrainsMono"

echo "==> Installing JetBrains Nerd Font..."

if [[ ! -f "$JB_FONT_DIR/JetBrainsMono-Regular.ttf" ]]; then
    mkdir -p "$JB_FONT_DIR"

    echo "⬇️ Downloading JetBrainsMono Nerd Font v$JB_FONT_VERSION..."
    wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/v$JB_FONT_VERSION/JetBrainsMono.zip"

    echo "📦 Extracting..."
    unzip -q "JetBrainsMono.zip" -d "JetBrainsMono"
    mv JetBrainsMono/*.ttf "$JB_FONT_DIR/"

    echo "🧹 Cleaning up..."
    rm -rf "JetBrainsMono" "JetBrainsMono.zip"

    echo "🔄 Refreshing font cache..."
    fc-cache -f "$FONT_DIR" || echo "⚠️ Font cache refresh failed. Is 'fontconfig' installed?"

    echo "✅ JetBrains Nerd Font installed."
else
    echo "✔️ JetBrains Nerd Font already installed, skipping."
fi

echo "🚀 Starting dotfiles installation..."

cd "$DOTFILES_DIR"

backup_needed=false

# Loop through each folder (each is a stow package)
for dir in */ ; do
  package="${dir%/}"
  echo "🔗 Stowing $package..."

  # Find conflicting files that are not symlinks
  conflicts=$(stow -nv "$package" 2>&1 | grep -oE 'existing target is not a link: (.+)' | cut -d: -f2- | xargs)

  # Backup if needed
  for file in $conflicts; do
    fullpath="$HOME/$file"
    if [ -e "$fullpath" ]; then
      if [ "$backup_needed" = false ]; then
        echo "📁 Creating backup directory: $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
        backup_needed=true
      fi
      echo "📦 Backing up $file to $BACKUP_DIR"
      mkdir -p "$BACKUP_DIR/$(dirname "$file")"
      mv "$fullpath" "$BACKUP_DIR/$file"
    fi
  done

  # Stow the package
  stow "$package"

  if [ "$package" = "bin" ]; then
    echo "⚙️ Setting executable permissions for scripts in ~/.local/bin"
    find "$HOME/.local/bin" -type f -exec chmod +x {} +
  fi
done

echo "✅ All dotfiles have been stowed!"
