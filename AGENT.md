# AGENTS.md — nixcfg

This file is the working guide for AI coding agents in this repository.
Follow the architecture in README.md. Prefer the smallest correct change.

# Critical constraints

Never upgrade locked inputs.
flake.nix intentionally pins nixpkgs-unstable (to avoid a 7.3.4-zen kernel early-probe panic on B550) and droidloom to specific commits.
Do not change pinned revisions and do not run `nix flake update` unless the user explicitly asks.

Never auto-discover modules.
Do not use builtins.readDir, listFilesRecursive, or similar dynamic discovery.
All module imports must be maintained explicitly in `__<name>__.nix` files.

Never pass username through specialArgs.
username is injected by core/user.nix into _module.args.
specialArgs must stay `{ self, inputs, hostName }` only.

Never touch hardware or plaintext secrets.
Do not write plaintext secrets into .nix files.
Unless the user explicitly asks, do not modify:
- host/*/hardware-configuration.nix
- secrets/*/*.yaml
- .sops.yaml

Never deploy silently.
Validation is limited to read-only evaluation or dry-build.
Do not run `nixos-rebuild switch` or `nixos-rebuild boot` unless the user explicitly asks.

Always keep files visible to Flakes.
Nix Flakes only see tracked or staged Git files.
After adding modules or assets, git add them.
Do not reference gitignored paths such as tmp/, docs/, or result* from formal modules.

Limit comments to a strict minimum.
Almost never add comments, except for non-trivial expressions, custom helper functions, or workarounds (such as pinned revisions or hardware quirks).

# Repository layout

```text
nixcfg/
├── flake.nix
├── .sops.yaml
├── host/
├── core/
├── modules/
├── desktop/
├── apps/
└── secrets/
```

flake.nix is the root. It wires sharedModules (home-manager, nixvim, sops-nix, hermes-agent, mango, stylix) and provides pkgs.stable through an overlay (nixos-26.05, allowUnfree enabled).
When an unstable package fails to build, prefer pkgs.stable.<pkg>.

host/common.nix aggregates the top-level entries for core, modules, desktop, apps, and secrets.

There are four targets, all x86_64-linux:

- lap: main laptop, host/lap/configuration.nix
- pc: desktop, host/pc/configuration.nix; enables monitoring, sunshine, EasyTier relay, multi-output niri.outputs; disables upower
- hjl: separate-user host, host/hjl/configuration.nix; username = "hjl" and secrets/hjl
- install-iso: offline installer image, host/install-iso/configuration.nix; does not import host/common.nix; intentionally sets home-manager.startAsUserService = false so environment.d is ready

# Layering

Dependencies are strictly one-way: upper layers may depend on lower layers, never the reverse.
Removing any non-root node must leave the rest of the system able to evaluate and run.

- Layer 0, core/: NixOS base (console, networking, system/Nix settings, user and global username)
- Layer 1, modules/: system extensions (lang/, services/, shells/, virtual/)
- Layer 2, desktop/: desktop stack (base/, dispMgr/, winMgr/, shell/, input/, term/, fileMgr/, browser/, editor/)
- Layer 3, apps/: user applications (services/, toolkits/, pentest/, game/)

Upper layers may override lower-layer options. Example: host/hjl/configuration.nix uses lib.mkForce "" on services.xserver.xkb.options.
If the upper layer is removed, the lower layer must degrade to a valid default without errors.

Home Manager config is written in place through home-manager.users.${username} inside feature modules.
Default is startAsUserService = true.
Do not create a parallel Home Manager directory tree.

# Module rules

## Boundaries

Files named `__<name>__.nix` are independent nodes.
They aggregate imports and set defaults with lib.mkDefault.
A node must be self-contained: enabling or disabling it must bring its dependencies with it or clean them up.

Ordinary child modules under a node do not need full independence.
They may use shared resources defined by their parent `__<name>__.nix`.
Example: apps/services/ai/* may read config.sops.secrets.api-key-env from apps/services/ai/__ai__.nix.

Non-Nix assets used by a module (dotfiles, scripts, patches) must live next to that module, or in a subdirectory of it, and be referenced with relative paths such as ./.
Do not dump shared assets at the repository root.

## Leaf module template

Every module that defines config must declare its own option and wrap the body in lib.mkIf cfg.enable.
Removing the import must fully remove the feature.

```nix
{ config, lib, pkgs, ... }:
let
  # Must match the file path exactly
  cfg = config.apps.services.aaa;
in
{
  options.apps.services.aaa.enable = lib.mkEnableOption "Enable aaa";

  config = lib.mkIf cfg.enable {
    # implementation
  };
}
```

## Naming and interfaces

Physical path, options.<ns>.<name>, and cfg = config.<ns>.<name> must stay in lockstep.
If you rename or move a directory, update the module path and every reference in `__*__.nix` and host/*.

Directories starting with _ are bundled replacements for sibling fragment components.
They sit at the same level as sibling modules, and the option path keeps the underscore.
Example: desktop/shell/_noctalia/ -> desktop.shell._noctalia.enable.

New modules expose only .enable (boolean).
Do not add .select or .list aggregation layers.
Mutual exclusion, such as display managers, is enforced by host configuration.

Historical interfaces that still exist and must not be broken:

- modules.lang.list in modules/lang/__lang__.nix
- desktop.base.theme in desktop/base/__base__.nix
- desktop.browser.default in desktop/browser/__browser__.nix

When editing those modules or install-iso, keep the existing call sites working.
Do not copy this pattern in new modules.

# Global variables, secrets, and desktop notes

username is declared in core/user.nix as core.user.username with default "e", then bridged into _module.args.username.
Modules receive it as `{ username, ... }:`.
Do not hardcode usernames or paths like /home/e.
Hosts override with core.user.username = "foo"; in host/<name>/configuration.nix.

To add a host:

1. Copy host/lap to host/<new-host>
2. Register it in flake.nix nixosConfigurations:
   new-host = mkSystem "new-host" [./host/new-host/configuration.nix];
3. Keep all host-specific differences under host/<new-host>/

secrets/__secrets__.nix defaults to secrets.path = "${self}/secrets/${username}".
If a host or image uses a username without a matching secrets directory, for example install-iso with "nixos", you must override:
secrets.path = "${self}/secrets/e";
Otherwise evaluation or activation will fail.

desktop.winMgr may enable multiple window managers at once.
Each WM's xdg.portal dependencies must live inside its own mkIf cfg.enable block.

Browser ShowItems uses D-Bus org.freedesktop.FileManager1 and is not controlled by xdg.portal.
When multiple file managers coexist, thunar.nix already claims inode/directory through:
xdg.mime.defaultApplications."inode/directory" = "thunar.desktop"
To pin browser ShowItems ownership, override org.freedesktop.FileManager1.service under ~/.local/share/dbus-1/services.

# Change policy and verification

Prefer the smallest change that works.
If one variable can carry the intent, do not spread the change.
Deletion and simplification are unrestricted, but clean up dead imports and stale defaults at the same time.

When changing option names or defaults in core/, desktop/, apps/toolkits/, or apps/services/ai/, also check:
- host/install-iso/configuration.nix
- every host/*/configuration.nix

After edits, prefer read-only checks first:

```bash
nix eval .#nixosConfigurations.lap.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.pc.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.hjl.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.install-iso.config.system.build.isoImage.drvPath

# optional:
# nixos-rebuild dry-build --flake .#<host>
```

Before finishing a change, confirm:

- the module sits in the correct layer and does not create reverse dependencies
- leaf modules declare options.<ns>.<name>.enable and wrap config with lib.mkIf cfg.enable
- option paths match file paths and are imported from the parent `__<name>__.nix`
- defaults that should be on use lib.mkDefault in the relevant top-level aggregator
- new files were git added so Flakes can see them
- structural changes were reflected in this file and README.md