# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{ lib, username, self, ... }:
{
	imports = [
		./hardware-configuration.nix
		./driver.nix
		./boot.nix
		../common.nix
	];

	services.logind.settings.Login = {
		HandleLidSwitch = "suspend";
		HandleLidSwitchExternalPower = "lock";
	};

    home-manager.users.${username}.xdg.configFile."containers/storage.conf".text = lib.mkForce "";
    # Esc  cap
    services.xserver.xkb.options = lib.mkForce "";
    
    secrets.path = "${self}/host/hjl/secrets";

    apps = {
        toolkits ={
            # mcu.enable = true;
            # fpga.enable = true;
            misc.enable = true;
            typst.enable = true;
            latex.enable = false;
            hive.enable = false;
            vm-managers.enable = true;
            git.enable = true;
            neovim.enable = true;
            yazi.enable = true;
            devops.enable = false;
        };

        services = {
            ai.enable = true;
            ai.hermes.enable = false;
            ai.litellm.enable = false;
            ai.opencode.enable = true;
            ai.pi.enable = true;
            ai.grok.enable = false;
            proxy.enable = true;
            proxy.mihomo.enable = true;
            # proxy.daed.enable = true;# TODO WPI
            # proxy.dae.enable  = true;
            ingress.enable = false;
            remote-ctrl.enable = false;
            monitoring.enable = false;
        };
        game={
            steam.enable = false;
            wine.enable = false;
            linuwowo.enable = false;
        };
        pentest = {
            misc.enable = false;
            c2.enable = false;
            pwndbg.enable = false;
            wireshark.enable = false;
            yakit.enable = false;
            # yakit.chromePath = "/run/current-system/sw/bin/brave";
        };
    };
}