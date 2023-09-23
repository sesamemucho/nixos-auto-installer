{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];
  nixpkgs.config.allowUnfree = true;
  networking.hostName = "gabriel";
  networking.wireless = {
    enable = true;
    networks."gill".psk = "c0tton6Top3";
    userControlled.enable = true;
  };
  # Enable networking
  # networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services.avahi = {
    enable = true;
    ipv4 = true;
    ipv6 = true;
    nssmdns = true;
    publish = { enable = true; domain = true; addresses = true; };
  };
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    tmux
  ];

  security.sudo.wheelNeedsPassword = false;
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";
  users.mutableUsers = false;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGcJeeTzj074ZKNK3iE9OMaD8C/77SgbGIGkYCFr0bMk bob"
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.bob = {
    isNormalUser = true;
    description = "Bob Forgey";
    extraGroups = [ "wheel" ];
    packages = with pkgs; [
      firefox
      emacs
    #  thunderbird
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

}
