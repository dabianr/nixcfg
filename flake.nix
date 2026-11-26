{
  description = "Optimized NixOS Flake Configuration";

  # nixConfig = {
  #   extra-substituters = ["https://pwndbg.cachix.org" "https://deepseek-harness-nix.cachix.org"];
  #   extra-trusted-public-keys = [
  #     "pwndbg.cachix.org-1:HhtIpP7j73SnuzLgobqqa8LVTng5Qi36sQtNt79cD3k="
  #     "deepseek-harness-nix.cachix.org-1:5NrkwLN9veNMhiINtU5ZeV4isXFhFsOwn6Ms7J1M+TA="
  #   ];
  # };

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

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # LinUwUx (Denuvo 运行时) 2026-11-26
    linuwowo = {
      url = "github:loystonpais/linuwowo/edbce651b3816ca08f2c8d243b045caef6710858";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # herdr = {
    #   url = "github:herdrdev/herdr";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # 固定 2026-11-26 rev
    deepseek-harness = {
      url = "github:moraxyc/deepseek-harness.nix/680feca4ec92cf5acdb6107d91d04bbde1024bd5";
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
      hjl = mkSystem "hjl" [./host/hjl/configuration.nix];
      install-iso = mkSystem "iso-installer" [./host/install-iso/configuration.nix];
    };
  };
}
