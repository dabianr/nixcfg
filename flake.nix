{
  description = "Optimized NixOS Flake Configuration";

  nixConfig = {
    extra-substituters = ["https://pwndbg.cachix.org"];
    extra-trusted-public-keys = [
      "pwndbg.cachix.org-1:HhtIpP7j73SnuzLgobqqa8LVTng5Qi36sQtNt79cD3k="
    ];
  };

  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";

    nixpkgs.follows = "nixpkgs-unstable";

    pwndbg = {
      url = "github:pwndbg/pwndbg";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
    };

    # DroidLoom 上游只发 Arch 包; 此 flake 用官方 release 重打包并提供 NixOS 模块。
    # 固定在已审计的 rev (2026-11-12), 避免 update 时被替换成未审计提交。
    droidloom = {
      url = "github:pharra/droidloom-flake/d4521ba871280e3223ebc38d64bdc81b4eda4fbe";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mango = {
      url = "github:DreamMaoMao/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 不能 follows: 26.11 的 nixpkgs 已把 patchelf 回退到 0.15.2, 而 hermes 的
    # 补丁按 0.19.2 编写, 打不上; 显式钉到 hermes 自己 flake.lock 的 0.19.2 rev。
    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.url = "github:NixOS/nixpkgs/02c087f3fe673c9e317f206a627cb6b910336dbe";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    linuwowo = {
      url = "github:loystonpais/linuwowo";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }: let
    system = "x86_64-linux";

    sharedModules = [
      inputs.home-manager.nixosModules.home-manager
      inputs.nixvim.nixosModules.nixvim
      inputs.sops-nix.nixosModules.sops
      inputs.hermes-agent.nixosModules.default
      inputs.mango.nixosModules.mango
      inputs.stylix.nixosModules.stylix
      inputs.linuwowo.nixosModules.default
      ({username, ...}: {
        system.stateVersion = "25.11";
        nixpkgs.overlays = [
          (final: prev: {
            stable = import inputs.nixpkgs-stable {
              inherit system;
              config.allowUnfree = true;
            };
          })
        ];
        home-manager.backupFileExtension = "backup";
        home-manager.startAsUserService = nixpkgs.lib.mkDefault true;
        home-manager.users.${username}.home.stateVersion = "26.05";
      })
    ];

    mkSystem = hostName: modules:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit self inputs hostName;};
        modules = sharedModules ++ modules;
      };
  in {
    nixosConfigurations = {
      lap = mkSystem "lap" [./host/lap/configuration.nix];
      pc = mkSystem "pc" [./host/pc/configuration.nix];
      install-iso = mkSystem "iso-installer" [./host/install-iso/configuration.nix];
    };
  };
}
