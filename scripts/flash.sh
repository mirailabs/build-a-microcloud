#!/bin/bash

set -e

# -- logging helpers
info () {
    echo "[*]  " "$@"
}

warn () {
    echo "[!]  " "$@"
}

err () {
    echo "[x]  " "$@"
}

prompt () {
    local msg="$1"
    local var="$2"
    read -p "[?]  ${msg}: " -r "${var?}"
}

secure_prompt () {
    local msg="$1"
    local var="$2"
    read -p "[?]  ${msg}: " -s -r "${var?}"
    echo
}

echo_flash_warning () {
    warn
    warn ' WARNING -------------------------------------------------------------- '
    warn ' Please double-check you are flashing the right device for your sdcard! '
    warn ' You can easily do this with lsblk.                                     '
    warn ' ---------------------------------------------------------------------- '
    warn
}

show_usage () {
    cat <<EOF
Usage: $(basename "$0") [img] [sdcard dev]

Example: $(basename "$0") raspbian_lite_latest.zip /dev/sdc
EOF
}

img_zip="$1" # e.g. raspbian_lite_latest.zip
sdcard="$2"  # e.g. /dev/sdc (PLEASE VERIFY WITH lsblk TO ENSURE YOU SELECT THE RIGHT DEV)

if [ ! -f "$img_zip" ] ; then
    err 'Please specify a zip containing the img to flash!'
    show_usage
    exit 1
fi

if [ ! -b "$sdcard" ] ; then
    err 'Please specify a valid sdcard device to flash!'
    show_usage
    exit 1
fi

info "You are about to flash '$img_zip' to your sdcard '$sdcard'..."
echo_flash_warning
prompt "Proceed? [y/n]" resp
if [ "$resp" != "y" ] ; then
    info 'Aborting.'
    exit 1
fi

info "Flashing..."
unzip -p "$img_zip" | sudo dd of="$sdcard" bs=4M conv=fsync status=progress

info "Enabling SSH by creating a file 'ssh' in the img boot partition..."
mkdir mnt
sudo mount "${sdcard}1" mnt
sudo touch mnt/ssh
sudo umount mnt
rm -rf mnt

prompt "Would you like to set up your Wi-Fi now? [y/n]" resp
if [ "$resp" = "y" ] ; then
    prompt "  ssid" ssid
    secure_prompt "  password" password
    info 'Setting up Wi-Fi...'
    mkdir mnt
    sudo mount "${sdcard}2" mnt
    if [ ! -e 'mnt/etc/wpa_supplicant' ] ; then
        warn "Can't find wpa_supplicant directory - aborting Wi-Fi setup..."
    else
        sudo tee -a mnt/etc/wpa_supplicant/wpa_supplicant.conf >/dev/null <<EOF

network={
    ssid="${ssid}"
    psk="${password}"
}
EOF
    fi
    sudo umount mnt
    rm -rf mnt
else
    info 'Skipping Wi-fi setup...'
fi

info 'Ejecting sdcard...'
sudo eject "$sdcard"

info 'All done! Unplug your sdcard and stick it in your Pi!'
