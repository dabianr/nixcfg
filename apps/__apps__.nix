{lib, ...}: {
  imports = [
    ./services/__services__.nix
    ./toolkits/__toolkits__.nix
    ./pentest/__pentest__.nix
    ./game/__game__.nix
  ];

  config.apps = lib.mkDefault {
    toolkits ={
      # mcu.enable = true;
      # fpga.enable = true;
      misc.enable = true;
      typst.enable = true;
      latex.enable = true;
      hive.enable = true;
      vm-managers.enable = true;
      git.enable = true;
      neovim.enable = true;
      yazi.enable = true;
      devops.enable = true;
    };

    services = {
      ai.enable = true;
      ai.hermes.enable = true;
      ai.herdr.enable = false;
      ai.litellm.enable = false;
      ai.opencode.enable = false;
      ai.pi.enable = true;
      ai.grok.enable = false;
      proxy.enable = true;
      proxy.mihomo.enable = true;
      # proxy.daed.enable = true;# TODO WPI
      # proxy.dae.enable  = true;
      ingress.enable = false;
      remote-ctrl = {
        nginx.enable = false;
        vnc.enable = true;
        easytier.enable = true;
      };
      monitoring.enable = true;
    };

    pentest = {
      misc.enable = true;
      c2.enable = true;
      pwndbg.enable = true;
      wireshark.enable = true;
      yakit.enable = true;
      # yakit.chromePath = "/run/current-system/sw/bin/brave";
    };

    game={
      steam.enable = true;
      wine.enable = true;
      linuwowo.enable = false;
      misc.enable = true;
    };
  };
}
