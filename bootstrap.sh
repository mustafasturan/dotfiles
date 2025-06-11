#!/bin/bash

set -e  # Exit on error

DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles_backup"

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
done

echo "✅ All dotfiles have been stowed!"
