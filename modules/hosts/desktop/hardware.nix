_: {
  flake.nixosModules.desktopHardware =
    {
      config,
      pkgs,
      modulesPath,
      ...
    }:
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
      ];

      boot = {
        initrd = {
          availableKernelModules = [
            "nvme"
            "xhci_pci"
            "ahci"
            "usbhid"
            "usb_storage"
            "sd_mod"
          ];
          kernelModules = [ ];
          systemd.enable = true;
        };
        kernelModules = [ "kvm-amd" ];
        blacklistedKernelModules = [ "amdgpu" ];
        extraModulePackages = [ ];
        kernelParams = [
          "amd_pstate=active"
          "nvme_core.default_ps_max_latency_us=0"
        ];
        kernel.sysctl = {
          "vm.swappiness" = 180;
          "vm.watermark_boost_factor" = 0;
          "vm.watermark_scale_factor" = 125;
          "vm.page-cluster" = 0;
        };
        tmp.useTmpfs = true;
      };

      services = {
        fstrim.enable = true;
        xserver.videoDrivers = [ "nvidia" ];
      };

      zramSwap = {
        enable = true;
        algorithm = "zstd";
        memoryPercent = 25;
      };

      hardware = {
        nvidia = {
          modesetting.enable = true;
          open = true;
          nvidiaSettings = true;
          package = pkgs.nvidia_cachyos;
          powerManagement = {
            enable = true;
            finegrained = false;
          };
          nvidiaPersistenced = true;
        };

        graphics = {
          enable = true;
          enable32Bit = true;
          extraPackages = [ pkgs.nvidia-vaapi-driver ];
        };

        enableRedistributableFirmware = true;
        cpu.amd.updateMicrocode = config.hardware.enableRedistributableFirmware;
      };

      environment = {
        sessionVariables = {
          GBM_BACKEND = "nvidia-drm";
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
          LIBVA_DRIVER_NAME = "nvidia";
          NVD_BACKEND = "direct";
          MOZ_ENABLE_WAYLAND = "1";
          MOZ_DISABLE_RDD_SANDBOX = "1";
        };
        systemPackages = [ pkgs.nvtopPackages.nvidia ];
      };

      fileSystems = {
        "/" = {
          device = "/dev/disk/by-uuid/822b0651-38e5-4055-ac85-17804e3f086b";
          fsType = "ext4";
        };
        "/boot" = {
          device = "/dev/disk/by-uuid/6A15-FCBE";
          fsType = "vfat";
          options = [
            "fmask=0077"
            "dmask=0077"
          ];
        };
      };

      swapDevices = [
        { device = "/dev/disk/by-uuid/64b4e016-16e3-4dfc-a3a4-b40246c70e06"; }
      ];

      nixpkgs.hostPlatform = "x86_64-linux";
    };
}
