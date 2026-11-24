# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{...}: {
  imports = [
    ./hardware-configuration.nix
    ./driver.nix
    ./boot.nix
    ../common.nix
  ];

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "suspend";
    HoldoffTimeoutSec = "5s";
  };

  apps.services = {
    remote-ctrl = {
      nginx.enable = false;
      vnc.enable = true;
      moonlight.enable = true;
      easytier = {
        enable = true;
        ipv4 = "10.144.144.2/24";
        peers = ["wss://app.bigdogbarks.top"];
      };
    };
  };

  apps.game.steam.enable = false;
}
