{
  config,
  lib,
  pkgs,
  username,
  ...
}: let
  cfg = config.apps.game.linuwowo;
  system = pkgs.stdenv.hostPlatform.system;

  # 不进 flake inputs: 开关关闭时整段不求值、不下载、不占 lock, 源可被 GC。
  # 版本手动钉, nix flake update 管不到。
  luw = builtins.getFlake "github:loystonpais/linuwowo/edbce651b3816ca08f2c8d243b045caef6710858";
  json = builtins.fromJSON (builtins.readFile ./linuwowo.json);

  kernel = config.boot.kernelPackages.kernel;
  # nixpkgs 内核用 kmodigest 给每个模块签名并生成 .ko.cer,
  # 原包只手工 install .ko, 聚合器 cat 不到 .cer 会构建失败 → 改走 kbuild modules_install
  emulationPkg =
    (config.boot.kernelPackages.callPackage "${luw.outPath}/cpuid-fault-emulation.nix" {})
    .overrideAttrs (_: {
      installPhase = ''
        make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build M=$PWD \
          ${lib.concatStringsSep " " (map lib.escapeShellArg (kernel.commonMakeFlags
      ++ [
        "KBUILD_OUTPUT=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
        "DEPMOD=true"
        "INSTALL_MOD_STRIP=1"
      ]))} \
          INSTALL_MOD_PATH=$out INSTALL_MOD_DIR=extra modules_install
      '';
    });
in {
  options.apps.game.linuwowo.enable =
    lib.mkEnableOption "LinUwUx Denuvo runtime (patched GE-Proton + cpuid_fault_emulation, AMD only)";

  config = lib.mkIf cfg.enable {
    # 内联自 linuwowo@edbce65 的 nixosModules.default (imports 不能条件化, 只能内联)
    boot.kernelParams = lib.optional json.disableUmip "clearcpuid=umip";
    boot.extraModulePackages = lib.optional json.cpuidFaultEmulation emulationPkg;

    # 不随开机自载: 服务按需 start/stop, 避免第三方 ring0 模块常驻并抢占 KVM
    systemd.services.cpuid-fault-emulation = lib.mkIf json.cpuidFaultEmulation {
      description = "CPUID Fault Emulation Service";
      wantedBy = [];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "cpuid-fault-emulation-start" ''
          export PATH=${lib.makeBinPath (with pkgs; [kmod gnugrep])}:$PATH
          if lsmod | grep -q "^kvm_amd"; then
            modprobe -r kvm_amd
          elif lsmod | grep -q "^kvm_intel"; then
            modprobe -r kvm_intel
          fi
          modprobe -r kvm || true
          modprobe cpuid_fault_emulation
        '';
        ExecStop = pkgs.writeShellScript "cpuid-fault-emulation-stop" ''
          export PATH=${lib.makeBinPath (with pkgs; [kmod gnugrep])}:$PATH
          modprobe -r cpuid_fault_emulation
          modprobe kvm || true
          if grep -q "AuthenticAMD" /proc/cpuinfo; then
            modprobe kvm_amd || true
          elif grep -q "GenuineIntel" /proc/cpuinfo; then
            modprobe kvm_intel || true
          fi
        '';
      };
    };

    # 把改版 GE-Proton 挂给 Steam/Heroic
    home-manager.users.${username}.home.file = {
      ".config/heroic/tools/proton/GE-Proton11-1-LinUwUx-patch".source =
        luw.packages.${system}.GE-Proton11-1-LinUwUx-patch;
      ".steam/root/compatibilitytools.d/GE-Proton11-1-LinUwUx-patch".source =
        luw.packages.${system}.GE-Proton11-1-LinUwUx-patch;
    };
  };
}
