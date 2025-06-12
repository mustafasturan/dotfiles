#!/bin/bash
set -euo pipefail

# Colors
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
CYAN="\033[1;36m"
RESET="\033[0m"

function prompt_confirm() {
  # Usage: prompt_confirm "Message"
  while true; do
    read -rp "$(echo -e "${CYAN}💾 $1 [${GREEN}y${CYAN}/${RED}n${CYAN}]: ${RESET}")" yn
    case $yn in
      [Yy]*) return 0 ;;
      [Nn]*) return 1 ;;
      *) echo -e "${YELLOW}⚠️  Please answer y or n.${RESET}" ;;
    esac
  done
}

if command -v timeshift &>/dev/null; then
  echo -e "${GREEN}✅ Timeshift is already installed.${RESET}"
  if prompt_confirm "Do you want to take an on-demand Timeshift snapshot now?"; then
    echo -e "${CYAN}📸 Taking on-demand Timeshift snapshot...${RESET}"
    sudo timeshift --create --comments "On-demand snapshot from timeshift script"
    echo -e "${GREEN}🎉 Snapshot complete!${RESET}"
  fi
else
  echo -e "${RED}❌ Timeshift is not installed.${RESET}"
fi