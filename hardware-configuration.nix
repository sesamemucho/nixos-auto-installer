{ config, modulesPath, lib, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];
  hardware.enableAllFirmware = true;

  boot.loader.systemd-boot.enable = true;

  boot.initrd.kernelModules = [
    "kvm-intel"
    "virtio_balloon"
    "virtio_console"
    "virtio_rng"
  ];

  boot.extraModulePackages = [
    config.boot.kernelPackages.broadcom_sta
  ];

  boot.initrd.availableKernelModules = [
    "9p"
    "9pnet_virtio"
    "ata_piix"
    "nvme"
    "sr_mod"
    "uhci_hcd"
    "virtio_blk"
    "virtio_mmio"
    "virtio_net"
    "virtio_pci"
    "virtio_scsi"
    "xhci_pci"
  ];

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-partlabel/NIXOS";

  fileSystems."/" = {
    # device = "/dev/disk/by-label/nixos";
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=root" "compress=zstd" "noatime" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
    options = [ "subvol=home" "compress=zstd" "noatime" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
    options = [ "subvol=nix" "compress=zstd" "noatime" ];
  };

  fileSystems."/var/log" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
    options = [ "subvol=log" "compress=zstd" "noatime" ];
  };

  fileSystems."/persist" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
    options = [ "subvol=persist" "compress=zstd" "noatime" ];
  };

  swapDevices = [{ device = "/dev/disk/by-label/swap"; }];

  networking.useDHCP = lib.mkDefault true;
  networking.hostId = "7051ab3a";
}
