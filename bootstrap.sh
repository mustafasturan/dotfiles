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

# Create wallpaper directory
echo "==> Creating wallpaper directory..."
if [[ ! -d "$HOME/Pictures/Wallpaper" ]]; then
    mkdir -p "$HOME/Pictures/Wallpaper"
    echo "📁 Created ~/Pictures/Wallpaper"
else
    echo "✔️ Wallpaper directory already exists, skipping."
fi

# Install yay if not already installed
if ! command -v yay &>/dev/null; then
    echo "==> Installing AUR package manager (yay)..."

    # Ensure prerequisites
    sudo pacman -S --needed --noconfirm git base-devel || {
        echo "❌ Failed to install base-devel or git"; exit 1;
    }

    # Use temporary build directory
    tmpdir=$(mktemp -d)
    echo "📁 Cloning yay into $tmpdir"
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay" || {
        echo "❌ Failed to clone yay repo"; exit 1;
    }

    pushd "$tmpdir/yay" > /dev/null
    makepkg -si --noconfirm || {
        echo "❌ yay installation failed"; exit 1;
    }
    popd > /dev/null

    rm -rf "$tmpdir"

    echo "✅ yay installed successfully."
else
    echo "✔️ yay is already installed."
fi

# Install useful packages from AUR
echo "==> Installing core packages with yay..."

PACKAGES=(
    pacseek
    zoxide
    fzf
    unzip
    zsh
    starship
    atuin
    eza
    acpi
    playerctl
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-history-substring-search
)

if yay -S --noconfirm --needed "${PACKAGES[@]}"; then
    echo "✅ Core packages installed successfully."
else
    echo "❌ Failed to install some packages. Check the yay output above." >&2
    exit 1
fi

# Install packages from official repos using pacman
echo "==> Installing system packages with pacman..."

PACMAN_PACKAGES=(
    dunst
    libnotify
    waybar
    wl-clipboard
    xdg-desktop-portal-hyprland
    xdg-desktop-portal
    brightnessctl
    pavucontrol
    tmux
    slurp
    grim
    hyprlock
    pamixer
)

if sudo pacman -S --noconfirm --needed "${PACMAN_PACKAGES[@]}"; then
    echo "✅ System packages installed successfully."
else
    echo "❌ Failed to install some system packages. Check the pacman output above." >&2
    exit 1
fi

# Set zsh as default shell if not already
if [[ "$SHELL" != "$(command -v zsh)" ]]; then
    echo "==> Changing default shell to zsh..."
    if chsh -s "$(command -v zsh)"; then
        echo "✅ Default shell changed to zsh. Please log out and log back in for it to take effect."
    else
        echo "❌ Failed to change default shell to zsh." >&2
        exit 1
    fi
else
    echo "✔️ zsh is already the default shell."
fi


echo "🚀 Starting dotfiles installation..."

cd "$DOTFILES_DIR"

backup_needed=false
processed_dirs=()

# Loop through each folder (each is a stow package)
for dir in */ ; do

  # Skip non-stow directories
  if [[ "$package" == ".git" ]]; then
    continue
  fi
  
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

  # Only chmod each top-level target once
  for topdir in "$package"/*; do
    [ -d "$topdir" ] || continue
    target="$HOME/$(basename "$topdir")"
    if [[ ! " ${processed_dirs[*]} " =~ " $target " ]] && [ -d "$target" ]; then
      find "$target" -type f -name "*.sh" -exec chmod +x {} +
      processed_dirs+=("$target")
    fi
  done
done

echo "✅ All dotfiles have been stowed!"
