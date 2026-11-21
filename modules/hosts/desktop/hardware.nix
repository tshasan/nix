_: {
  flake.nixosModules.desktopHardware =
    {
      config,
      lib,
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
        };
        kernelModules = [
          "kvm-amd"
          "nct6775"
        ];
        blacklistedKernelModules = [ "amdgpu" ];
        extraModulePackages = [ ];
        # Disable NVMe APST: Samsung 990 PRO firmware 4B2QJXD7 can drop off the
        # bus or remount read-only when entering deep power states.
        kernelParams = [
          "nvme_core.default_ps_max_latency_us=0"
        ];
        kernel.sysctl = {
          "vm.swappiness" = 180;
          "vm.watermark_boost_factor" = 0;
          "vm.watermark_scale_factor" = 125;
          "vm.page-cluster" = 0;
        };
        tmp.cleanOnBoot = true;
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

      # A second boot entry per generation on the stock LTS kernel and the
      # nixpkgs build of the same NVIDIA driver, so a bad CachyOS or NVIDIA
      # build is one boot-menu pick away from working.
      specialisation.lts.configuration = {
        boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
        hardware.nvidia.package = lib.mkForce pkgs.linuxPackages.nvidiaPackages.latest;
      };

      hardware = {
        block.scheduler."nvme[0-9]*" = "none";

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
        cpu.amd.ryzen-smu.enable = true;
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
        # Unconnected NCT6799 thermistor inputs and PCH registers that read
        # noise (AUXTIN5 floats near 110 °C), plus the unwired intrusion switch.
        etc."sensors.d/desktop.conf".text = ''
          chip "nct6799-isa-*"
            label temp7 "CPU (SB-TSI)"
            ignore temp3
            ignore temp6
            ignore temp9
            ignore temp10
            ignore temp11
            ignore temp12
            ignore intrusion0
            ignore intrusion1
        '';
      };

      fileSystems = {
        "/" = {
          device = "/dev/disk/by-uuid/822b0651-38e5-4055-ac85-17804e3f086b";
          fsType = "ext4";
          options = [ "noatime" ];
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
