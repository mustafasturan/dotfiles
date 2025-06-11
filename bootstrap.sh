#!/bin/bash

set -e

DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles_backup"

echo "🚀 Starting dotfiles installation..."

mkdir -p "$BACKUP_DIR"
cd "$DOTFILES_DIR"

for dir in */ ; do
  package="${dir%/}"

  echo "🔗 Stowing $package..."

  conflicts=$(stow -nv "$package" 2>&1 | grep -oE 'existing target is not a link: (.+)' | cut -d: -f2- | xargs)

  for file in $conflicts; do
    if [ -e "$HOME/$file" ]; then
      echo "📦 Backing up $file to $BACKUP_DIR"
      mkdir -p "$BACKUP_DIR/$(dirname "$file")"
      mv "$HOME/$file" "$BACKUP_DIR/$file"
    fi
  done

  stow "$package"
done

echo "✅ All dotfiles have been stowed!"
