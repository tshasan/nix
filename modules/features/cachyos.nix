{ inputs, ... }:
{
  flake.nixosModules.cachyos =
    { pkgs, ... }:
    {
      imports = [ inputs.chaotic.nixosModules.default ];

      boot.kernelPackages = pkgs.linuxPackages_cachyos;

      # sched_ext is compiled into the CachyOS kernel; load scx_lavd, its
      # latency-aware desktop scheduler, for smoother UI/scroll under load.
      services.scx = {
        enable = true;
        scheduler = "scx_lavd";
      };

      # BBR + fq: better real-world page-load throughput than cubic/fq_codel.
      boot.kernel.sysctl = {
        "net.core.default_qdisc" = "fq";
        "net.ipv4.tcp_congestion_control" = "bbr";
      };
    };
}
