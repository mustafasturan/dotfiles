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
    fc-cache -f -v || echo "⚠️ Could not refresh font cache. Is fontconfig installed?"

    echo "✅ Font Awesome v5 and v6 installed."
else
    echo "✔️ Font Awesome already installed, skipping."
fi


JB_FONT_VERSION="3.4.0"
JB_FONT_DIR="$FONT_DIR/JetBrainsMono"

echo "==> Installing JetBrains Nerd Font..."

if [[ ! -f "$JB_FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf" ]]; then
    mkdir -p "$JB_FONT_DIR"

    echo "⬇️ Downloading JetBrainsMono Nerd Font v$JB_FONT_VERSION..."
    wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/v$JB_FONT_VERSION/JetBrainsMono.zip"

    echo "📦 Extracting..."
    unzip -q "JetBrainsMono.zip" -d "JetBrainsMono"
    mv JetBrainsMono/*.ttf "$JB_FONT_DIR/"

    echo "🧹 Cleaning up..."
    rm -rf "JetBrainsMono" "JetBrainsMono.zip"

    echo "🔄 Refreshing font cache..."
    fc-cache -f -v || echo "⚠️ Font cache refresh failed. Is 'fontconfig' installed?"

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
    bat
    acpi
    playerctl
    zsh-autosuggestions
    zsh-syntax-highlighting
    zsh-history-substring-search
    bibata-cursor-theme
    catppuccin-gtk-theme-mocha
    kvantum-theme-catppuccin-git
    catppuccin-sddm-theme
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
    stow
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
    hyprland
    hyprlock
    hypridle
    hyprpaper
    hyprpicker
    kitty
    qt5-wayland
    qt6-wayland
    pamixer
    rofi
    sddm
    gtk3
    gtk4
    kvantum
    qt5ct
    qt6ct
    adwaita-icon-theme
    papirus-icon-theme
)

if sudo pacman -S --noconfirm --needed "${PACMAN_PACKAGES[@]}"; then
    echo "✅ System packages installed successfully."
else
    echo "❌ Failed to install some system packages. Check the pacman output above." >&2
    exit 1
fi

# Check and enable multilib repository if needed
echo "==> Checking multilib repository..."
if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    echo "Enabling multilib repository..."
    sudo sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
    sudo pacman -Sy
    echo "✅ Multilib repository enabled."
else
    echo "✔️ Multilib repository is already enabled."
fi

# Install NVIDIA Open Kernel Driver
echo "==> Checking NVIDIA driver status ..."

# Function to check if a package is installed
is_package_installed() {
    pacman -Q "$1" &>/dev/null
}

# Check if drivers are already installed
if is_package_installed "nvidia-open-dkms" && lsmod | grep -q "nvidia"; then
    echo "✔️ NVIDIA open kernel driver is already installed and loaded."
else
    echo "⬇️ Installing NVIDIA Open Kernel Driver (DKMS)..."
    
    NVIDIA_PACKAGES=(
        nvidia-open-dkms     # Open kernel driver with DKMS support
        nvidia-utils         # NVIDIA driver utilities
        nvidia-settings      # NVIDIA settings GUI tool
        lib32-nvidia-utils   # 32-bit support for NVIDIA drivers
        egl-wayland          # EGL support for Wayland
        libva-nvidia-driver  # VA-API support for NVIDIA
    )

    if sudo pacman -S --noconfirm --needed "${NVIDIA_PACKAGES[@]}"; then
        echo "✅ NVIDIA drivers installed successfully."
    else
        echo "❌ Failed to install NVIDIA drivers. Check the pacman output above." >&2
        exit 1
    fi
fi

# Configure NVIDIA settings (even if drivers were already installed)
echo "==> Configuring NVIDIA for Hyprland with Wayland..."

# Create or update NVIDIA configuration for Hyprland
NVIDIA_CONF="/etc/modprobe.d/nvidia.conf"
if [[ ! -f "$NVIDIA_CONF" ]]; then
    echo "Creating NVIDIA module configuration..."
    echo "options nvidia-drm modeset=1" | sudo tee "$NVIDIA_CONF"
    echo "options nvidia NVreg_PreserveVideoMemoryAllocations=1" | sudo tee -a "$NVIDIA_CONF"
else
    echo "✔️ NVIDIA kernel configuration already exists."
fi

# Add environment variables to profile.d for proper NVIDIA Wayland support
NVIDIA_ENV="/etc/profile.d/nvidia-wayland.sh"
if [[ ! -f "$NVIDIA_ENV" ]]; then
    echo "Creating NVIDIA Wayland environment settings..."
    cat << EOF | sudo tee "$NVIDIA_ENV"
# NVIDIA Wayland environment variables
export LIBVA_DRIVER_NAME=nvidia
export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export WLR_NO_HARDWARE_CURSORS=1
export CUDA_CACHE_DISABLE=0
export __GL_THREADED_OPTIMIZATIONS=1
EOF
    sudo chmod +x "$NVIDIA_ENV"
else
    echo "✔️ NVIDIA Wayland environment settings already exist."
fi

# Update initramfs only if we installed new drivers
if ! is_package_installed "nvidia-open-dkms" || ! lsmod | grep -q "nvidia"; then
    echo "Updating initramfs with NVIDIA modules..."
    sudo mkinitcpio -P
    echo "⚠️ A system reboot is recommended to activate the new NVIDIA drivers."
fi

# Set zsh as default shell if not already
if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$(command -v zsh)" ]]; then
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

# Enable SDDM if not already enabled
if ! systemctl is-enabled sddm &>/dev/null; then
    echo "==> Enabling SDDM display manager..."
    sudo systemctl enable sddm
    echo "✅ SDDM enabled."
else
    echo "✔️ SDDM is already enabled."
fi

echo "🚀 Starting dotfiles installation..."

cd "$DOTFILES_DIR"

backup_needed=false
processed_dirs=()

# Loop through each folder (each is a stow package)
for dir in */ ; do
  package="${dir%/}"
  
  # Skip non-stow directories
  if [[ "$package" == ".git" || "$package" == "sddm" ]]; then
    continue
  fi
  
  echo "🔗 Stowing $package..."

  # Debug output
  echo "Debug: Running stow dry run for $package"
  stow -nv "$package" 2>&1 | tee /tmp/stow-debug-$package.log
  echo "Debug: Dry run complete"

  # Find conflicting files that are not symlinks
  conflicts=$(stow -nv "$package" 2>&1 | grep -oE 'existing target is not a link: (.+)' | cut -d: -f2- | xargs) || true

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
  echo "Debug: About to stow $package"
  stow "$package" || { echo "❌ Stow failed for $package"; exit 1; }
  echo "Debug: Successfully stowed $package"

  # Recursively chmod +x all *.sh files in installed target dirs, including hidden folders like .config
  for topdir in "$package"/* "$package"/.*; do
    # Skip non-directories and special entries
    [[ ! -d "$topdir" ]] && continue
    [[ "$(basename "$topdir")" == "." || "$(basename "$topdir")" == ".." ]] && continue

    # Corresponding target in $HOME
    target="$HOME/$(basename "$topdir")"

    if [[ ! " ${processed_dirs[*]} " =~ " $target " ]] && [ -d "$target" ]; then
      echo "🔧 Setting executable permissions on scripts in $target"
      find "$target" -type f -name "*.sh" -exec chmod +x {} +
      processed_dirs+=("$target")
    fi
  done

done

echo "✅ All dotfiles have been stowed!"

echo "==> Configuring SDDM ..."
if [ -d "$DOTFILES_DIR/sddm" ]; then
    # SDDM requires system-level configuration
    for conf_file in "$DOTFILES_DIR"/sddm/etc/sddm.conf.d/*.conf; do
        if [ -f "$conf_file" ]; then
            filename=$(basename "$conf_file")
            sudo mkdir -p /etc/sddm.conf.d
            echo "📄 Installing SDDM config: $filename"
            sudo cp "$conf_file" "/etc/sddm.conf.d/$filename"
        fi
    done
    echo "✅ SDDM configuration installed."
else
    echo "⚠️ SDDM configuration not found in dotfiles."
fi