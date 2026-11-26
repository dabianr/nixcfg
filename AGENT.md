# AGENT.md — `nixcfg` 开发与架构规范

本文件为 AI Coding Agent 在本仓库工作的核心指南。所有规则以 `README.md` 架构设计为基准，并约束了实际工程中的防踩坑边界。

---

## 0. 绝对红线 (Critical Constraints)

- **NEVER 升级锁定输入**：`flake.nix` 有意将 `nixpkgs-unstable`（规避 7.3.4-zen 内核在 B550 芯片组下的早期探测 panic）与 `droidloom` 固定在特定 commit。除非用户明确要求，**严禁**修改 pinned rev 或执行 `nix flake update`。
- **NEVER 自动扫描导入**：**严禁**使用 `builtins.readDir`、`listFilesRecursive` 等动态发现机制；所有模块导入必须由 `__<name>__.nix` 手动显式维护。
- **NEVER 在 `specialArgs` 传 `username`**：`username` 由 `core/user.nix` 注入 `_module.args`，`specialArgs` 仅保留 `{ self, inputs, hostName }`，避免优先级冲突。
- **NEVER 触碰硬件与明文密钥**：**严禁**在 `.nix` 中写入明文密钥；无明确指令时**严禁**修改 `host/*/hardware-configuration.nix`、`secrets/*/*.yaml` 及 `.sops.yaml`。
- **NEVER 静默部署**：验证代码仅限只读求值或 `dry-build`，除非用户明确要求，**严禁**执行 `nixos-rebuild switch` / `boot`。
- **MUST 同步 Git 追踪**：Nix Flakes 仅可见已纳入 Git（tracked/staged）的文件。新增任何模块或资源文件后，必须确保执行过 `git add`（严禁在正式模块中引用 `.gitignore` 忽略的 `tmp/`、`docs/`、`result*`）。

---

## 1. 仓库结构与主机入口

```text
nixcfg/
├── flake.nix                # Flake 根节点：sharedModules、pkgs.stable overlay、nixosConfigurations
├── .sops.yaml               # SOPS age 加密规则 (secrets/e/*, secrets/hjl/*)
├── host/                    # 主机配置 (common.nix, lap/, pc/, hjl/, install-iso/)
├── core/                    # Layer 0: 系统核心 (__core__.nix, console, networking, system, user)
├── modules/                 # Layer 1: 系统扩展 (__modules__.nix, lang/, services/, shells/, virtual/)
├── desktop/                 # Layer 2: 桌面环境 (__desktop__.nix, base/, dispMgr/, winMgr/, shell/, input/, term/, fileMgr/, browser/, editor/)
├── apps/                    # Layer 3: 用户应用 (__apps__.nix, services/, toolkits/, pentest/, game/)
└── secrets/                 # SOPS 密钥 (__secrets__.nix, e/, hjl/)

```

### 主机与构建特征 (`x86_64-linux`)

* **`flake.nix`**：注入 `sharedModules`（`home-manager`、`nixvim`、`sops-nix`、`hermes-agent`、`mango`、`stylix`、`linuwowo`），并通过 overlay 提供 `pkgs.stable`（对应 `nixos-26.05`，已启用 `allowUnfree`）。当 `unstable` 包构建失败需回退时，优先使用 `pkgs.stable.<pkg>`。
* **`host/common.nix`**：聚合 `core`、`modules`、`desktop`、`apps`、`secrets` 顶层入口。
* **4 个目标主机**：
* `lap`：主力笔记本（`host/lap/configuration.nix`）。
* `pc`：台式机（`host/pc/configuration.nix`，启用 `monitoring`、`sunshine`、EasyTier 中继、多屏 `niri.outputs`、禁用 `upower`）。
* `hjl`：独立用户主机（`host/hjl/configuration.nix`，独立 `username = "hjl"` 与 `secrets/hjl`）。
* `install-iso`：离线安装镜像（`host/install-iso/configuration.nix`，**不引入 `host/common.nix**`，精选 imports；为确保 `environment.d` 就绪，有意覆写 `home-manager.startAsUserService = false`）。

---

## 2. 分层架构（严格单向依赖）

依赖方向严格单向：**上层只能依赖下层，严禁反向依赖**。移除任意非根节点不得影响系统其余部分正常运行。

| 层级 | 目录 | 职责 |
| --- | --- | --- |
| Layer 0 | `core/` | NixOS 内核基础配置（控制台、网络、系统/Nix 设置、用户与全局 `username`） |
| Layer 1 | `modules/` | 系统级模块扩展（`lang/`、`services/`、`shells/`、`virtual/`） |
| Layer 2 | `desktop/` | 桌面环境（`base/`、`dispMgr/`、`winMgr/`、`shell/`、`input/`、`term/`、`fileMgr/`、`browser/`、`editor/`） |
| Layer 3 | `apps/` | 用户应用（`services/`、`toolkits/`、`pentest/`、`game/`） |

* **上层覆盖原则**：上层可覆盖下层引用的 NixOS option（如 `host/hjl/configuration.nix` 使用 `lib.mkForce ""` 覆写 `services.xserver.xkb.options`）；移除上层后，下层必须能无报错降级到默认行为。
* **Home Manager 集成方式**：用户级配置统一通过 `home-manager.users.${username}` 在各功能模块内部就地编写（默认 `startAsUserService = true`），不单独拆分平行目录树。

---

## 3. 模块编写与组织规范

### 3.1 节点边界与独立性

* **独立模块 (`__*__.nix`)**：每个模块目录内包含 `__<name>__.nix` 聚合子模块导入，并通过 `lib.mkDefault` 设置默认开关。凡以 `__*__.nix` 命名的文件代表“摘出去可独立复用”的完整节点，依赖与配置必须在节点内闭环，禁用即清理依赖。
* **普通子模块**：目录内未以 `__*__.nix` 命名的子文件无需强求独立性，可直接依赖所属 `__*__.nix` 中定义的共享资源（如 `apps/services/ai/*` 可直接读取 `apps/services/ai/__ai__.nix` 的 `config.sops.secrets.api-key-env`）。
* **外部配置与脚本存放**：模块引用的非 `.nix` 配置文件（dotfiles、脚本、补丁）必须存放在该模块同级目录（或子目录）下，使用相对路径 `./...` 引用，禁止集中堆放在仓库根目录。

### 3.2 标准叶子模块模板

所有包含 `config` 的模块（含不再细分的叶子模块）**MUST** 自行声明选项并用 `lib.mkIf cfg.enable` 包裹配置，删除 `import` 即彻底清理：

```nix
{ config, lib, pkgs, ... }:
let
  # 必须与文件目录路径严格一致
  cfg = config.apps.services.aaa;
in
{
  options.apps.services.aaa.enable = lib.mkEnableOption "Enable aaa";

  config = lib.mkIf cfg.enable {
    # 依赖与配置实现
  };
}

```

### 3.3 命名、路径与接口约束

* **路径强一致**：文件物理路径、`options.<ns>.<name>` 与 `cfg = config.<ns>.<name>` 必须一一对应。重命名或移动目录时（如 `desktop/shell/bar/xxx/` $\rightarrow$ `desktop/shell/xxx/`），必须同步修改模块内路径及所有 `__*__.nix`、`host/*` 引用。
* **`_` 前缀（全家桶）**：以 `_` 开头的目录（如 `desktop/shell/_noctalia/`）代表替换同级碎片组件的完整集成实现，与父目录子项平级，选项路径同步保留 `_`（`desktop.shell._noctalia.enable`）。
* **仅暴露 `.enable`（与存量特例）**：
* 新模块对外**只暴露 `.enable`（boolean）**，严禁新增 `.select` / `.list` 聚合层；互斥关系（如显示管理器）由主机配置自行保证。
* **存量历史接口（兼容性红线）**：仓库仍保留 `modules.lang.list`（`modules/lang/__lang__.nix`）、`desktop.base.theme`（`desktop/base/__base__.nix`）、`desktop.browser.default`（`desktop/browser/__browser__.nix`）。修改这些模块或 `install-iso` 时勿破坏既有调用，新模块不得效仿。



---

## 4. 全局变量、密钥与桌面专项约定

1. **全局 `username**`：`core/user.nix` 声明 `core.user.username`（`default = "e"`）并桥接至 `_module.args.username`。模块统一通过 `{ username, ... }:` 接收，严禁硬编码用户名或 `/home/e`。主机覆盖直接在 `host/<name>/configuration.nix` 设置 `core.user.username = "foo";`。
2. **新增主机流程**：复制 `host/lap` 为 `host/<new-host>`，在 `flake.nix` 的 `nixosConfigurations` 中登记 `new-host = mkSystem "new-host" [./host/new-host/configuration.nix];`，其余主机差异全部留在 `host/<new-host>/` 内。
3. **SOPS `secrets.path` 断言**：`secrets/__secrets__.nix` 默认设置 `secrets.path = "${self}/secrets/${username}"`。若某主机/镜像使用非已有密钥目录的 `username`（如 `install-iso` 使用 `"nixos"`），**MUST** 显式覆盖 `secrets.path = "${self}/secrets/e";`，否则无法构建/激活。
4. **桌面环境隔离与接管**：
* `desktop.winMgr` 支持同时启用多个 WM，各 WM 专属的 `xdg.portal` 依赖**MUST** 写在各自 `mkIf cfg.enable` 内部。
* **文件管理器接管**：浏览器 `ShowItems` 走 D-Bus `org.freedesktop.FileManager1`（不受 `xdg.portal` 控制）。多文件管理器共存时，`thunar.nix` 已通过 `xdg.mime.defaultApplications."inode/directory" = "thunar.desktop"` 接管目录关联；如需固定浏览器 `ShowItems` 归属，需在用户级 `~/.local/share/dbus-1/services` 覆写 `org.freedesktop.FileManager1.service`。



---

## 5. 修改原则、验证命令与交付清单

* **最小改动原则**：新增或修改功能时，用最简洁的 Nix 语法做最小范围改动（能改一处变量不改多处）；删除/简化代码不受此限，但需同步清理 `import` 与失效默认选项。
* **跨主机影响检查**：改动 `core/`、`desktop/`、`apps/toolkits/` 或 `apps/services/ai/` 的选项名与默认行为时，同步检查 `host/install-iso/configuration.nix` 及各主机配置。

Limit the amount of comments you put in the code to a strict minimum.
You should almost never add comments, except sometimes on non-trivial code, function definitions if the arguments aren't self-explanatory, and class definitions and their members.  Do not remove existing comments unless they are directly related to what you are changing. 

### 只读验证命令（修改后优先执行）

```bash
nix eval .#nixosConfigurations.lap.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.pc.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.hjl.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.install-iso.config.system.build.isoImage.drvPath
# 按需执行空跑构建：
# nixos-rebuild dry-build --flake .#<host>

```

### 交付前自检清单 (Checklist)

* [ ] 模块位于正确分层目录，且未引入下层依赖上层的反向引用。
* [ ] 叶子模块按标准模板自声明 `options.<ns>.<name>.enable` 并用 `lib.mkIf cfg.enable` 包裹。
* [ ] 选项路径与文件物理路径严格一致，并在所属 `__<name>__.nix` 中显式 `import`。
* [ ] 如需默认开启，已在顶层 `__modules__.nix` / `__desktop__.nix` / `__apps__.nix` 中设置 `lib.mkDefault`。
* [ ] 新增文件已考虑 `git add` 使其对 Flake 可见；目录结构变更已同步更新本文件与 `README.md`。