{ inputs, ... }:
{
  flake.nixosModules.macbookHardware =
    { lib, modulesPath, ... }:
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
        inputs.nixos-apple-silicon.nixosModules.apple-silicon-support
      ];

      # MacBookPro17,1: 13" M1, 8 GB RAM, 256 GB SSD, Touch Bar.
      # Peripheral firmware (Wi-Fi, webcam, ALS) is loaded from the ESP at
      # boot; refresh it from macOS with the Asahi installer's "Rebuild
      # vendor firmware package" option.
      hardware = {
        asahi.enable = true;
        apple.touchBar.enable = true;
      };

      boot = {
        initrd.luks.devices.cryptroot = {
          device = "/dev/disk/by-label/cryptnixos";
          allowDiscards = true;
          bypassWorkqueues = true;
        };

        # US ANSI keyboard: stop ` and < (and ~ and >) being swapped.
        extraModprobeConfig = ''
          options hid_apple iso_layout=0
        '';

        tmp.cleanOnBoot = true;

        kernel.sysctl = {
          "vm.swappiness" = 180;
          "vm.watermark_boost_factor" = 0;
          "vm.watermark_scale_factor" = 125;
          "vm.page-cluster" = 0;
        };
      };

      services = {
        fstrim.enable = true;

        # Stop charging at 80% to preserve the battery when docked. Set when
        # the battery device appears, so it cannot lose a race with boot.
        udev.extraRules = ''
          ACTION=="add", SUBSYSTEM=="power_supply", KERNEL=="macsmc-battery", ATTR{charge_control_end_threshold}="80"
        '';

        journald.settings.Journal.SystemMaxUse = "200M";
      };

      # 8 GB of RAM: under sustained memory pressure, kill the heaviest app
      # instead of letting the whole desktop freeze.
      systemd.oomd.enableUserSlices = true;

      nix.settings = {
        # The Asahi kernel is the only large local build; two parallel
        # all-core builds would exhaust 8 GB.
        max-jobs = lib.mkForce 1;
        # 256 GB shared with macOS: collect garbage mid-build once free space
        # drops below 10 GiB, until 30 GiB is free.
        min-free = 10 * 1024 * 1024 * 1024;
        max-free = 30 * 1024 * 1024 * 1024;
      };

      zramSwap = {
        enable = true;
        algorithm = "zstd";
        memoryPercent = 50;
      };

      # Disk-backed overflow behind zram, so local Asahi kernel builds
      # (there is no binary cache) don't OOM on 8 GB. Lives inside LUKS.
      swapDevices = [
        {
          device = "/var/lib/swapfile";
          size = 8 * 1024;
        }
      ];

      fileSystems = {
        "/" = {
          device = "/dev/disk/by-label/nixos";
          fsType = "ext4";
        };
        # The Asahi installer's ESP, relabelled during installation. Nothing
        # in the boot chain reads the label: m1n1 and the firmware loader
        # find the ESP by PARTUUID.
        "/boot" = {
          device = "/dev/disk/by-label/NIXBOOT";
          fsType = "vfat";
          options = [
            "fmask=0077"
            "dmask=0077"
          ];
        };
      };

      nixpkgs.hostPlatform = "aarch64-linux";
    };
}
