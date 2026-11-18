# nixcfg

我的 NixOS 配置，用 flake 管理。包含两台机器和一个装机用的 ISO。

| 名称 | 入口 |
| --- | --- |
| `lap`（笔记本） | `host/lap/configuration.nix` |
| `pc`（台式机） | `host/pc/configuration.nix` |
| `install-iso`（装机镜像） | `host/install-iso/configuration.nix` |

## 目录

| 目录 | 内容 |
| --- | --- |
| `core/` | 系统基础、网络、用户 |
| `modules/` | 语言环境、系统服务、虚拟化 |
| `desktop/` | 窗口管理器、显示管理器、输入法、终端、编辑器 |
| `apps/` | 服务、开发工具、游戏、安全工具 |

上层可以 import 下层，反过来不行。

每个目录下有一个 `__xxx__.nix`，里面列出要 import 的子模块，不用 `readDir` 自动扫描。删掉一行 import 就是卸载这个模块和它的依赖。每个模块自己声明 `options.xxx.enable`，父模块只给默认值。

## 命令

```
sudo nixos-rebuild switch --flake .#lap
nix flake update
nix flake check
```

## 模块

- 虚拟化：libvirtd、podman、distrobox、waydroid、appimage、nix-ld
- 服务：nginx、cloudflared、prometheus、k3s、vnc
- 开发：c/c++、go、java、javascript、python、rust；neovim、typst、latex、fpga、mcu
- 桌面：niri / labwc / hypr / mangowc，输入法、字体、stylix
- 网络：dae、daed、mihomo
- 安全工具：wireshark、pwndbg、yakit、amass、dirsearch

## 密钥

sops + age。加密后的文件放在 `secrets/`，可以直接提交。解密靠各机器自己的 age key，路径 `~/.config/sops/age/keys.txt`。`secrets/__secrets__.nix` 把解密后的值传给需要的模块。

加密规则和公钥写在 `.sops.yaml`。

## 已知问题

nixpkgs 固定在 2026-10-30 的 rev。linux-zen 7.3.4 在 B550 + nvme/ahci/xhci 上会 `process_one_work` NULL deref panic。上游修好后删掉这行 pin，跑 `nix flake update`。

## 备注

个人配置，硬件和账户都写死了。换机器要先改 `host/` 下的 `hardware-configuration.nix`。
