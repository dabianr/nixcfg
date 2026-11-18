# nixcfg

我用 Nix flake 管理两台机器的 NixOS 配置：笔记本 `lap`、台式机 `pc`，外加一个装机用的 ISO 镜像。

目标很简单：**换机器时一条命令重建全部环境**，改动全程进 Git，出问题能回滚。

## 三套系统

| 名称 | 用途 | 入口 |
| --- | --- | --- |
| `lap` | 笔记本 | `host/lap/configuration.nix` |
| `pc` | 台式机 | `host/pc/configuration.nix` |
| `install-iso` | 装机镜像（带工具的最小系统） | `host/install-iso/configuration.nix` |

## 目录结构

四层，只允许上层依赖下层：

| 层 | 目录 | 放什么 |
| --- | --- | --- |
| 0 | `core/` | 内核层配置：系统基础、网络、用户 |
| 1 | `modules/` | 系统级模块：语言工具链、系统服务、虚拟化 |
| 2 | `desktop/` | 桌面环境：窗口管理器、显示管理器、输入法、终端、编辑器 |
| 3 | `apps/` | 应用：后台服务、开发工具、游戏、安全工具 |

每个目录下有一个 `__xxx__.nix` 索引文件，**显式列出**要 import 的子模块（不用 `readDir` 自动发现）。所以：

- 删掉一行 import，就等于把这个模块连同它的依赖一起卸载，不会留残余
- 每个模块自己声明 `options.xxx.enable`，父模块只给默认值，互不干扰

## 常用命令

```bash
sudo nixos-rebuild switch --flake .#lap   # 应用配置（换成 .#pc 切到台式机）
nix flake update                          # 更新依赖
nix flake check                           # 检查求值是否通过
```

## 已经启用的东西

| 类别 | 内容 |
| --- | --- |
| 虚拟化 | KVM（libvirtd）、podman + distrobox、waydroid、AppImage/flatpak、nix-ld |
| 服务 | nginx 反代、Cloudflare Tunnel、Prometheus 监控、k3s、VNC 远程控制 |
| 开发环境 | C/C++、Go、Java、JavaScript、Python、Rust 工具链；neovim、typst、LaTeX、FPGA、MCU |
| 桌面 | 多个窗口管理器可切（niri / labwc / hypr / mangowc）、输入法、字体、主题（stylix） |
| 网络 | dae / daed、mihomo |
| 安全工具 | wireshark、pwndbg、yakit、amass、dirsearch |

## 密钥怎么管

用 `sops` + `age`：

- 加密后的文件在 `secrets/`，可以安全地提交到公开仓库
- 解密靠每台机器自己的 age key（`~/.config/sops/age/keys.txt`），不需要手工分发
- `secrets/__secrets__.nix` 负责把解密后的值注入到需要它的模块里

`.sops.yaml` 里定义了加密规则和允许解密的公钥。

## 约定

新增一个模块时：

1. 在对应层建目录，写 `xxx.nix`，自带 `options.xxx.enable`
2. 在同层的 `__xxx__.nix` 索引文件里加一行 import
3. 在父层的索引或 `host/*/configuration.nix` 里按需开启

这样模块之间不互相 import，只通过 option 暴露开关。

## 踩过的坑

**内核固定（pin）**：`nixpkgs` 停在 2026-10-30 的 rev，因为 linux-zen 7.3.4 在 B550 + nvme/ahci/xhci 上会触发 `process_one_work` 的 NULL deref panic。上游修好之后，删掉这行 pin、跑 `nix flake update` 就能回到 unstable。

## 说明

这是个人配置仓库，不是通用发行版。里面是我的硬件、账户和服务偏好，克隆到别的机器上需要先改 `host/` 下的硬件配置。
