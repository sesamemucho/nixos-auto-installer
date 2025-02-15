{ config, pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];
  nixpkgs.config.allowUnfree = true;
  hardware.enableAllFirmware = true;

  systemd.services.install = {
    description = "Bootstrap a NixOS installation";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "polkit.service" ];
    path = [ "/run/current-system/sw/" ];
    script = with pkgs; ''
      # this is just for debugging purposes, can be removed when it all works
      echo 'journalctl -fb -n100 -uinstall' >>~nixos/.bash_history

      set -euxo pipefail

      wait-for() {
        for _ in seq 10; do
          if $@; then
            break
          fi
          sleep 1
        done
      }

      dev=/dev/sda
      [ -b /dev/nvme0n1 ] && dev=/dev/nvme0n1
      [ -b /dev/vda ] && dev=/dev/vda

      # the cryptic type stands for "EFI system partition"
      ${utillinux}/bin/sfdisk --wipe=always "$dev" <<-END
        label: gpt

        name=BOOT, size=512MiB, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
        name=SWAP, size=8GiB, type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F
        name=LTEST, size=20GiB
        name=NIXOS
      END

      sync

      wait-for [ -b /dev/disk/by-partlabel/BOOT ]
      wait-for mkfs.fat -F 32 -n boot /dev/disk/by-partlabel/BOOT

      wait-for [ -b /dev/disk/by-partlabel/SWAP ]
      wait-for mkswap -L swap /dev/disk/by-partlabel/SWAP

      wait-for [ -b /dev/disk/by-partlabel/NIXOS ]
      # format the disk with the luks structure
      echo -n p | cryptsetup luksFormat --type luks2 --key-file - /dev/disk/by-partlabel/NIXOS
      # open the encrypted partition and map it to /dev/mapper/cryptroot
      echo -n p | cryptsetup open --type luks2 --key-file - /dev/disk/by-partlabel/NIXOS cryptroot
      # format
      mkfs.btrfs -f -L nixos /dev/mapper/cryptroot
      wait-for [ -b /dev/disk/by-label/nixos ]
      mount -t btrfs /dev/mapper/cryptroot /mnt
      #mount /dev/disk/by-label/nixos /mnt

      # We first create the subvolumes outlined above:
      btrfs subvolume create /mnt/root
      btrfs subvolume create /mnt/home
      btrfs subvolume create /mnt/nix
      btrfs subvolume create /mnt/persist
      btrfs subvolume create /mnt/log

      # We then take an empty *readonly* snapshot of the root subvolume,
      # which we'll eventually rollback to on every boot.
      btrfs subvolume snapshot -r /mnt/root /mnt/root-blank

      umount /mnt

      sync
      wait-for [ -b /dev/disk/by-label/swap ]
      swapon /dev/disk/by-label/swap

      mount -o subvol=root,compress=zstd,noatime /dev/mapper/cryptroot /mnt

      # Once we’ve created the subvolumes, we mount them with the options that we want. Here, we’re using Zstandard compression along with the noatime option.

      mkdir /mnt/home
      mount -o subvol=home,compress=zstd,noatime /dev/mapper/cryptroot /mnt/home

      mkdir /mnt/nix
      mount -o subvol=nix,compress=zstd,noatime /dev/mapper/cryptroot /mnt/nix

      mkdir /mnt/persist
      mount -o subvol=persist,compress=zstd,noatime /dev/mapper/cryptroot /mnt/persist

      mkdir -p /mnt/var/log
      mount -o subvol=log,compress=zstd,noatime /dev/mapper/cryptroot /mnt/var/log

      mkdir /mnt/boot
      wait-for mount /dev/disk/by-label/boot /mnt/boot

      install -D ${./configuration.nix} /mnt/etc/nixos/configuration.nix
      install -D ${./hardware-configuration.nix} /mnt/etc/nixos/hardware-configuration.nix

      #sed -i -E 's/(\w*)#installer-only /\1/' /mnt/etc/nixos/*

      # add parameters so that nix does not try to contact a cache as we expect
      # to be offline anyway
      ${config.system.build.nixos-install}/bin/nixos-install \
        --system ${(pkgs.nixos [
          ./configuration.nix
          ./hardware-configuration.nix
        ]).config.system.build.toplevel} \
        --no-root-passwd \
        --cores 0

      echo 'Shutting off in 1min'
      ${systemd}/bin/shutdown +1
    '';
    environment = config.nix.envVars // {
      inherit (config.environment.sessionVariables) NIX_PATH;
      HOME = "/root";
    };
    serviceConfig = {
      Type = "oneshot";
    };
  };
}
