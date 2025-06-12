# Dotfiles

My Arch Linux dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Usage

```bash
git clone https://github.com/mustafasturan/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
chmod +x ~/.dotfiles/timeshift.sh
chmod +x ~/.dotfiles/bootstrap.sh
./timeshift.sh
./bootstrap.sh
```

# First, modify the filter file for a one-time restore
sudo nano /etc/timeshift/timeshift.json

# Find the "exclude" section and remove or comment out home directory exclusions
# Then save and exit

# Perform the restore with the --clone flag which forces complete restoration
sudo timeshift --restore --snapshot '2023-06-13_12-00-01' --target / --clone

# Or use the --yes flag to skip confirmations
sudo timeshift --restore --snapshot '2023-06-13_12-00-01' --target / --clone --yes

https://github.com/korvahannu/arch-nvidia-drivers-installation-guide

 NVIDIA_PACKAGES=(
        nvidia-open          # Open kernel driver with DKMS support
        nvidia-utils         # NVIDIA driver utilities
        nvidia-settings      # NVIDIA settings GUI tool
        lib32-nvidia-utils   # 32-bit support for NVIDIA drivers
        egl-wayland          # EGL support for Wayland
        libva-nvidia-driver  # VA-API support for NVIDIA
    )