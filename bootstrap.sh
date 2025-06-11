#!/bin/bash

set -e  # Exit on error

DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles_backup"

echo "🚀 Starting dotfiles installation..."

# Create backup directory
mkdir -p "$BACKUP_DIR"

cd "$DOTFILES_DIR"

# Loop through each folder (each is a stow package)
for dir in */ ; do
  package="${dir%/}"

  echo "🔗 Stowing $package..."

  # Dry run to find conflicting files
  conflicts=$(stow -nv "$package" 2>&1 | grep -oE 'existing target is not a link: (.+)' | cut -d: -f2- | xargs)

  # Backup conflicting files
  for file in $conflicts; do
    if [ -e "$HOME/$file" ]; then
      echo "📦 Backing up $file to $BACKUP_DIR"
      mkdir -p "$BACKUP_DIR/$(dirname "$file")"
      mv "$HOME/$file" "$BACKUP_DIR/$file"
    fi
  done

  # Actually stow the package
  stow "$package"
done

echo "✅ All dotfiles have been stowed!"
