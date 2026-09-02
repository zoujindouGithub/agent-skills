# OpenSpec CLI 完整参考

## 目录

1. [全局选项](#全局选项)
2. [环境变量](#环境变量)
3. [退出码](#退出码)
4. [Setup 命令](#setup-命令)
5. [浏览命令](#浏览命令)
6. [验证命令](#验证命令)
7. [生命周期命令](#生命周期命令)
8. [工作流命令](#工作流命令)
9. [Schema 命令](#schema-命令)
10. [配置命令](#配置命令)
11. [工作空间命令](#工作空间命令)
12. [共享上下文命令](#共享上下文命令)
13. [工具命令](#工具命令)

---

## 全局选项

所有命令均支持：

| 选项 | 说明 |
|------|------|
| `--version`, `-V` | 显示版本号 |
| `--no-color` | 禁用彩色输出 |
| `--help`, `-h` | 显示命令帮助 |

---

## 环境变量

| 变量 | 说明 |
|------|------|
| `OPENSPEC_TELEMETRY` | 设为 `0` 禁用遥测 |
| `DO_NOT_TRACK` | 设为 `1` 禁用遥测（标准 DNT 信号） |
| `OPENSPEC_CONCURRENCY` | 批量验证默认并发数（默认：6） |
| `EDITOR` / `VISUAL` | `openspec config edit` 使用的编辑器 |
| `NO_COLOR` | 设置时禁用彩色输出 |

---

## 退出码

| 码 | 含义 |
|----|------|
| `0` | 成功 |
| `1` | 错误（验证失败、文件缺失等） |

---

## Setup 命令

### `openspec init`

初始化项目，创建目录结构，配置 AI 工具集成。

```bash
openspec init [path] [options]
```

**参数：**

| 参数 | 必需 | 说明 |
|------|------|------|
| `path` | 否 | 目标目录（默认：当前目录） |

**选项：**

| 选项 | 说明 |
|------|------|
| `--tools <list>` | 非交互式配置 AI 工具。`all`、`none` 或逗号分隔列表 |
| `--force` | 自动清理旧文件，不提示 |
| `--profile <profile>` | 覆盖全局 profile（`core` 或 `custom`） |

**支持的 tool ID：** `amazon-q`, `antigravity`, `auggie`, `bob`, `claude`, `cline`, `codex`, `forgecode`, `codebuddy`, `continue`, `costrict`, `crush`, `cursor`, `factory`, `gemini`, `github-copilot`, `iflow`, `junie`, `kilocode`, `kimi`, `kiro`, `lingma`, `opencode`, `pi`, `qoder`, `qwen`, `roocode`, `trae`, `windsurf`

**示例：**

```bash
openspec init                                    # 交互式初始化
openspec init ./my-project                       # 指定目录
openspec init --tools claude,cursor              # 配置特定工具
openspec init --tools all                        # 配置所有工具
openspec init --profile core                     # 使用 core profile
openspec init --force                            # 跳过提示，自动清理
```

**创建内容：**

```
openspec/
├── specs/              # 规格（源真相）
├── changes/            # 变更
└── config.yaml         # 项目配置

.kimi/skills/           # Kimi 技能（如选择 kimi）
.claude/skills/         # Claude 技能（如选择 claude）
.cursor/skills/         # Cursor 技能（如选择 cursor）
...（其他工具配置）
```

---

### `openspec update`

升级 CLI 后更新 AI 工具配置。

```bash
openspec update [path] [options]
```

**选项：**

| 选项 | 说明 |
|------|------|
| `--force` | 强制更新，即使文件已是最新 |

**示例：**

```bash
npm update @fission-ai/openspec
openspec update
```

---

## 浏览命令

### `openspec list`

列出变更或规格。

```bash
openspec list [options]
```

**选项：**

| 选项 | 说明 |
|------|------|
| `--specs` | 列出规格而非变更 |
| `--changes` | 列出变更（默认） |
| `--sort <order>` | 排序：`recent`（默认）或 `name` |
| `--json` | JSON 输出 |

**示例：**

```bash
openspec list                    # 列出活跃变更
openspec list --specs            # 列出 Main Specs
openspec list --json             # JSON 输出
```

**文本输出：**

```
Active changes:
  add-dark-mode     UI theme switching support
  fix-login-bug     Session timeout handling
```

---

### `openspec view`

交互式仪表板，浏览规格和变更。

```bash
openspec view
```

---

### `openspec show`

显示变更或规格的详情。

```bash
openspec show [item-name] [options]
```

**参数：**

| 参数 | 必需 | 说明 |
|------|------|------|
| `item-name` | 否 | 变更或规格名称（省略时提示） |

**选项：**

| 选项 | 说明 |
|------|------|
| `--type <type>` | 指定类型：`change` 或 `spec`（无歧义时自动检测） |
| `--json` | JSON 输出 |
| `--no-interactive` | 禁用提示 |
| `--deltas-only` | 仅显示 Delta Specs（JSON 模式） |
| `--requirements` | 仅显示需求，排除场景（JSON 模式） |
| `--no-scenarios` | 排除场景内容（JSON 模式） |
| `-r, --requirement <id>` | 显示特定需求（1-based 索引，JSON 模式） |

**示例：**

```bash
openspec show                      # 交互式选择
openspec show add-dark-mode        # 显示变更
openspec show auth --type spec     # 显示规格
openspec show add-dark-mode --json # JSON 输出
```

---

## 验证命令

### `openspec validate`

验证变更和规格的结构问题。

```bash
openspec validate [item-name] [options]
```

**参数：**

| 参数 | 必需 | 说明 |
|------|------|------|
| `item-name` | 否 | 要验证的项（省略时提示） |

**选项：**

| 选项 | 说明 |
|------|------|
| `--all` | 验证所有变更和规格 |
| `--changes` | 验证所有变更 |
| `--specs` | 验证所有规格 |
| `--type <type>` | 名称有歧义时指定：`change` 或 `spec` |
| `--strict` | 启用严格验证模式 |
| `--json` | JSON 输出 |
| `--concurrency <n>` | 最大并行验证数（默认：6） |
| `--no-interactive` | 禁用提示 |

**示例：**

```bash
openspec validate                    # 交互式验证
openspec validate add-dark-mode      # 验证特定变更
openspec validate --changes          # 验证所有变更
openspec validate --all --json     # 全部验证，JSON 输出（CI 用）
openspec validate --all --strict --concurrency 12
```

**文本输出：**

```
Validating add-dark-mode...
  ✓ proposal.md valid
  ✓ specs/ui/spec.md valid
  ⚠ design.md: missing "Technical Approach" section

1 warning found
```

**JSON 输出：**

```json
{
  "version": "1.0.0",
  "results": {
    "changes": [
      {
        "name": "add-dark-mode",
        "valid": true,
        "warnings": ["design.md: missing 'Technical Approach' section"]
      }
    ]
  },
  "summary": {
    "total": 1,
    "valid": 1,
    "invalid": 0
  }
}
```

---

## 生命周期命令

### `openspec archive`

归档已完成变更，合并 Delta Specs 到 Main Specs。

```bash
openspec archive [change-name] [options]
```

**参数：**

| 参数 | 必需 | 说明 |
|------|------|------|
| `change-name` | 否 | 要归档的变更（省略时提示） |

**选项：**

| 选项 | 说明 |
|------|------|
| `-y, --yes` | 跳过确认提示 |
| `--skip-specs` | 跳过规格更新（纯工具/文档变更） |
| `--no-validate` | 跳过验证（需要确认） |

**示例：**

```bash
openspec archive                    # 交互式归档
openspec archive add-dark-mode      # 归档特定变更
openspec archive add-dark-mode --yes # 跳过提示
openspec archive update-ci-config --skip-specs  # 不合并规格
```

**执行步骤：**

1. 验证变更（`--no-validate` 时跳过）
2. 确认（`--yes` 时跳过）
3. 合并 Delta Specs 到 `openspec/specs/`
4. 移动变更目录到 `openspec/changes/archive/YYYY-MM-DD-<name>/`

---

## 工作流命令

### `openspec new change`

创建 repo-local 变更目录和可选的 checked-in 元数据。

```bash
openspec new change <name> [options]
```

**参数：**

| 参数 | 必需 | 说明 |
|------|------|------|
| `name` | 是 | 变更名称（kebab-case） |

**选项：**

| 选项 | 说明 |
|------|------|
| `--description <text>` | 添加到 `README.md` 的描述 |
| `--goal <text>` | 与变更一起存储的工作空间产品目标 |
| `--areas <names>` | 逗号分隔的受影响工作空间链接名 |
| `--initiative <id>` | 将 repo-local 变更链接到 initiative |
| `--store <id>` | `--initiative` 的 context store id |
| `--store-path <path>` | `--initiative` 的现有本地 context store 根目录 |
| `--schema <name>` | 使用的工作流 schema |
| `--json` | JSON 输出 |

**示例：**

```bash
openspec new change add-billing-api
openspec new change add-billing-api --initiative billing-launch --store platform
openspec new change add-billing-api --initiative platform/billing-launch --json
```

---

### `openspec set change`

更新 checked-in repo-local 变更元数据，不重新创建变更。

```bash
openspec set change <name> [options]
```

**选项：**

| 选项 | 说明 |
|------|------|
| `--initiative <id>` | 链接到 initiative |
| `--store <id>` | Context store id |
| `--store-path <path>` | 现有本地 context store 根目录 |
| `--json` | JSON 输出 |

**注意：** `--initiative` 是幂等的，不会替换已存在的不同 initiative 链接。

---

### `openspec status`

显示变更的工件完成状态。

```bash
openspec status [options]
```

**选项：**

| 选项 | 说明 |
|------|------|
| `--change <id>` | 变更名称（省略时提示） |
| `--schema <name>` | Schema 覆盖（自动检测变更配置） |
| `--json` | JSON 输出 |

**示例：**

```bash
openspec status
openspec status --change add-dark-mode
openspec status --change add-dark-mode --json
```

**文本输出：**

```
Change: add-dark-mode
Schema: spec-driven
Progress: 2/4 artifacts complete

[x] proposal
[ ] design
[x] specs
[-] tasks (blocked by: design)
```

**JSON 输出：**

```json
{
  "changeName": "add-dark-mode",
  "schemaName": "spec-driven",
  "isComplete": false,
  "applyRequires": ["tasks"],
  "artifacts": [
    {"id": "proposal", "outputPath": "proposal.md", "status": "done"},
    {"id": "design", "outputPath": "design.md", "status": "ready"},
    {"id": "specs", "outputPath": "specs/**/*.md", "status": "done"},
    {"id": "tasks", "outputPath": "tasks.md", "status": "blocked", "missingDeps": ["design"]}
  ]
}
```

---

### `openspec instructions`

获取创建工件或执行任务的完整指令。AI 代理使用此命令了解下一步该做什么。

```bash
openspec instructions [artifact] [options]
```

**参数：**

| 参数 | 必需 | 说明 |
|------|------|------|
| `artifact` | 否 | 工件 ID：`proposal`, `specs`, `design`, `tasks`, `apply` |

**选项：**

| 选项 | 说明 |
|------|------|
| `--change <id>` | 变更名称（非交互模式必需） |
| `--schema <name>` | Schema 覆盖 |
| `--json` | JSON 输出 |

**特殊用法：** `apply` 作为 artifact 获取任务实现指令。

**示例：**

```bash
openspec instructions --change add-dark-mode          # 下一个工件的指令
openspec instructions design --change add-dark-mode     # 特定工件的指令
openspec instructions apply --change add-dark-mode      # 实现阶段指令
openspec instructions design --change add-dark-mode --json
```

**输出包含：**
- 模板内容
- 项目配置中的 context 和 rules
- 依赖工件的内容

---

### `openspec templates`

显示 schema 中所有工件的解析模板路径。

```bash
openspec templates [options]
```

**选项：**

| 选项 | 说明 |
|------|------|
| `--schema <name>` | 要检查的 schema（默认：`spec-driven`） |
| `--json` | JSON 输出 |

**示例：**

```bash
openspec templates
openspec templates --schema my-workflow
openspec templates --json
```

**输出：**

```
Schema: spec-driven

Templates:
  proposal  → ~/.openspec/schemas/spec-driven/templates/proposal.md
  specs     → ~/.openspec/schemas/spec-driven/templates/specs.md
  design    → ~/.openspec/schemas/spec-driven/templates/design.md
  tasks     → ~/.openspec/schemas/spec-driven/templates/tasks.md
```

---

### `openspec schemas`

列出可用的工作流 schema。

```bash
openspec schemas [options]
```

**选项：**

| 选项 | 说明 |
|------|------|
| `--json` | JSON 输出 |

**输出：**

```
Available schemas:

  spec-driven (package)
    The default spec-driven development workflow
    Flow: proposal → specs → design → tasks

  my-custom (project)
    Custom workflow for this project
    Flow: research → proposal → tasks
```

---

## Schema 命令

### `openspec schema init`

创建新的项目级 schema。

```bash
openspec schema init <name> [options]
```

**参数：**

| 参数 | 必需 | 说明 |
|------|------|------|
| `name` | 是 | Schema 名称（kebab-case） |

**选项：**

| 选项 | 说明 |
|------|------|
| `--description <text>` | Schema 描述 |
| `--artifacts <list>` | 逗号分隔的工件 ID（默认：`proposal,specs,design,tasks`） |
| `--default` | 设为项目默认 schema |
| `--no-default` | 不提示设为默认 |
| `--force` | 覆盖现有 schema |
| `--json` | JSON 输出 |

**示例：**

```bash
openspec schema init research-first
openspec schema init rapid \
  --description "Rapid iteration workflow" \
  --artifacts "proposal,tasks" \
  --default
```

**创建内容：**

```
openspec/schemas/<name>/
├── schema.yaml           # Schema 定义
└── templates/
    ├── proposal.md       # 各工件的模板
    ├── specs.md
    ├── design.md
    └── tasks.md
```

---

### `openspec schema fork`

复制现有 schema 到项目进行自定义。

```bash
openspec schema fork <source> [name] [options]
```

**参数：**

| 参数 | 必需 | 说明 |
|------|------|------|
| `source` | 是 | 要复制的 schema |
| `name` | 否 | 新 schema 名称（默认：`<source>-custom`） |

**选项：**

| 选项 | 说明 |
|------|------|
| `--force` | 覆盖现有目标 |
| `--json` | JSON 输出 |

**示例：**

```bash
openspec schema fork spec-driven my-workflow
```

---

### `openspec schema validate`

验证 schema 的结构和模板。

```bash
openspec schema validate [name] [options]
```

**参数：**

| 参数 | 必需 | 说明 |
|------|------|------|
| `name` | 否 | 要验证的 schema（省略时验证所有） |

**选项：**

| 选项 | 说明 |
|------|------|
| `--verbose` | 显示详细验证步骤 |
| `--json` | JSON 输出 |

**示例：**

```bash
openspec schema validate my-workflow
openspec schema validate
```

**验证内容：**
- `schema.yaml` 语法正确
- 所有引用的模板存在
- 无循环依赖
- 工件 ID 有效

---

### `openspec schema which`

显示 schema 的解析来源（调试优先级）。

```bash
openspec schema which [name] [options]
```

**参数：**

| 参数 | 必需 | 说明 |
|------|------|------|
| `name` | 否 | Schema 名称 |

**选项：**

| 选项 | 说明 |
|------|------|
| `--all` | 列出所有 schema 及其来源 |
| `--json` | JSON 输出 |

**示例：**

```bash
openspec schema which spec-driven
openspec schema which --all
```

**输出：**

```
Schema: my-workflow
Source: project
Path: /path/to/project/openspec/schemas/my-workflow
```

**Schema 优先级：**

1. 项目：`openspec/schemas/<name>/`
2. 用户：`~/.local/share/openspec/schemas/<name>/`
3. 包：内置 schema

---

## 配置命令

### `openspec config`

查看和修改全局配置。

```bash
openspec config <subcommand> [options]
```

**子命令：**

| 子命令 | 说明 |
|--------|------|
| `path` | 显示配置文件位置 |
| `list` | 显示所有当前设置 |
| `get <key>` | 获取特定值 |
| `set <key> <value>` | 设置值 |
| `unset <key>` | 移除键 |
| `reset` | 重置为默认值 |
| `edit` | 在 `$EDITOR` 中打开 |
| `profile [preset]` | 交互式或通过 preset 配置工作流 profile |

**示例：**

```bash
openspec config path
openspec config list
openspec config get telemetry.enabled
openspec config set telemetry.enabled false
openspec config set user.name "My Name" --string
openspec config unset user.name
openspec config reset --all --yes
openspec config edit
openspec config profile
openspec config profile core
```

**Profile 配置：**

`openspec config profile` 启动交互式向导：
- 更改 delivery + workflows
- 仅更改 delivery
- 仅更改 workflows
- 保持当前设置

可用 workflow ID：`propose`, `explore`, `new`, `continue`, `apply`, `ff`, `sync`, `archive`, `bulk-archive`, `verify`, `onboard`

---

## 工作空间命令（Beta）

### `openspec workspace setup`

创建工作空间并关联至少一个现有仓库或文件夹。

```bash
openspec workspace setup [options]
```

**选项：**

| 选项 | 说明 |
|------|------|
| `--name <name>` | 工作空间名称（kebab-case） |
| `--link <path>` | 关联现有仓库/文件夹，从文件夹名推断链接名 |
| `--link <name>=<path>` | 关联并指定显式链接名 |
| `--opener <id>` | 存储首选打开器：`codex-cli`, `claude`, `github-copilot`, `editor` |
| `--tools <tools>` | 为代理安装工作空间级技能。`all`、`none` 或逗号分隔 tool ID |
| `--no-interactive` | 禁用提示；需要 `--name` 和至少一个 `--link` |
| `--json` | JSON 输出；需要 `--no-interactive` |

**示例：**

```bash
openspec workspace setup
openspec workspace setup --no-interactive --name platform --link /repos/api --link web=/repos/web
openspec workspace setup --no-interactive --name platform --link /repos/api --opener codex-cli
openspec workspace setup --no-interactive --name platform --link /repos/api --tools codex,claude
```

---

### `openspec workspace list`

列出已知工作空间。

```bash
openspec workspace list [--json]
openspec workspace ls [--json]
```

---

### `openspec workspace link`

为工作空间记录现有仓库或文件夹。

```bash
openspec workspace link [name] <path> [options]
```

**选项：**

| 选项 | 说明 |
|------|------|
| `--workspace <name>` | 从本地注册表中选择已知工作空间 |
| `--json` | JSON 输出 |
| `--no-interactive` | 禁用工作空间选择提示 |

**示例：**

```bash
openspec workspace link /repos/api
openspec workspace link api-service /repos/api
openspec workspace link --workspace platform /repos/platform/apps/checkout
```

---

### `openspec workspace relink`

修复或更改现有链接的本地路径。

```bash
openspec workspace relink <name> <path> [options]
```

---

### `openspec workspace doctor`

检查工作空间在当前机器上的可解析状态。

```bash
openspec workspace doctor [options]
```

**选项：**

| 选项 | 说明 |
|------|------|
| `--workspace <name>` | 选择工作空间 |
| `--json` | JSON 输出 |
| `--no-interactive` | 禁用提示 |

---

### `openspec workspace update`

刷新工作空间级 OpenSpec 指导和代理技能。

```bash
openspec workspace update [name] [options]
```

**选项：**

| 选项 | 说明 |
|------|------|
| `--workspace <name>` | 选择工作空间 |
| `--tools <tools>` | 选择代理。`all`、`none` 或逗号分隔 tool ID |
| `--json` | JSON 输出 |
| `--no-interactive` | 禁用提示 |

**示例：**

```bash
openspec workspace update
openspec workspace update platform
openspec workspace update --workspace platform --tools codex,claude
```

---

### `openspec workspace open`

通过存储的首选打开器、单会话代理覆盖或 VS Code 编辑器模式打开工作空间。

```bash
openspec workspace open [name] [options]
```

**选项：**

| 选项 | 说明 |
|------|------|
| `--workspace <name>` | 工作空间名称别名 |
| `--initiative <id>` | 打开 initiative 作为本地工作空间视图 |
| `--store <id>` | `--initiative` 的注册 context store id |
| `--store-path <path>` | `--initiative` 的现有本地 context store 根目录 |
| `--agent <tool>` | 单会话代理覆盖：`codex-cli`, `claude`, `github-copilot` |
| `--editor` | 以普通编辑器工作空间打开维护的 VS Code 工作空间文件 |
| `--no-interactive` | 禁用提示 |

**示例：**

```bash
openspec workspace open
openspec workspace open platform
openspec workspace open platform --agent github-copilot
openspec workspace open --agent codex-cli
openspec workspace open --editor
openspec workspace open --initiative billing-launch --store platform
```

---

## 共享上下文命令（Beta）

### `openspec context-store setup`

创建并注册本地 context store。

```bash
openspec context-store setup [id] [options]
```

**选项：**

| 选项 | 说明 |
|------|------|
| `--path <path>` | Context store 文件夹路径 |
| `--init-git` | 在 context store 中初始化 Git 仓库 |
| `--no-init-git` | 不初始化 Git 仓库 |
| `--json` | JSON 输出 |

**示例：**

```bash
openspec context-store setup
openspec context-store setup team-context
openspec context-store setup team-context --path /repos/team-context --no-init-git
```

---

### `openspec context-store register`

注册现有本地 context store 文件夹。

```bash
openspec context-store register [path] [options]
```

**选项：**

| 选项 | 说明 |
|------|------|
| `--id <id>` | Context store id（默认：store 元数据或文件夹名） |
| `--json` | JSON 输出 |

---

### `openspec context-store unregister`

遗忘本地 context store 注册，不删除文件。

```bash
openspec context-store unregister <id> [--json]
```

---

### `openspec context-store remove`

遗忘注册并删除本地文件夹。

```bash
openspec context-store remove <id> [--yes] [--json]
```

---

### `openspec context-store list`

列出已注册的本地 context stores。

```bash
openspec context-store list [--json]
openspec context-store ls [--json]
```

---

### `openspec context-store doctor`

检查本地 context store 注册、元数据和 Git 状态。

```bash
openspec context-store doctor [id] [--json]
```

---

### `openspec initiative create`

在 context store 中创建 initiative。

```bash
openspec initiative create <id> --title <title> --summary <summary> [options]
```

**选项：**

| 选项 | 说明 |
|------|------|
| `--store <id>` | 本地注册表中的 context store id |
| `--store-path <path>` | 现有本地 context store 根目录 |
| `--title <title>` | Initiative 标题 |
| `--summary <summary>` | Initiative 摘要 |
| `--json` | JSON 输出 |

---

### `openspec initiative list`

列出 initiatives。

```bash
openspec initiative list [options]
openspec initiative ls [options]
```

**选项：**

| 选项 | 说明 |
|------|------|
| `--store <id>` | 列出特定注册 context store |
| `--store-path <path>` | 列出特定现有本地 context store |
| `--json` | JSON 输出 |

---

### `openspec initiative show`

解析 initiative 并打印其规范位置。

```bash
openspec initiative show <id> [options]
openspec initiative show <store>/<id> [options]
```

**选项：**

| 选项 | 说明 |
|------|------|
| `--store <id>` | Context store id |
| `--store-path <path>` | 现有本地 context store 根目录 |
| `--json` | JSON 输出 |

---

## 工具命令

### `openspec feedback`

提交 OpenSpec 反馈，创建 GitHub issue。

```bash
openspec feedback <message> [options]
```

**参数：**

| 参数 | 必需 | 说明 |
|------|------|------|
| `message` | 是 | 反馈消息 |

**选项：**

| 选项 | 说明 |
|------|------|
| `--body <text>` | 详细描述 |

**要求：** 必须安装并认证 GitHub CLI (`gh`)。

**示例：**

```bash
openspec feedback "Add support for custom artifact types" \
  --body "I'd like to define my own artifact types beyond the built-in ones."
```

---

### `openspec completion`

管理 shell 补全。

```bash
openspec completion <subcommand> [shell]
```

**子命令：**

| 子命令 | 说明 |
|--------|------|
| `generate [shell]` | 输出补全脚本到 stdout |
| `install [shell]` | 为当前 shell 安装补全 |
| `uninstall [shell]` | 移除已安装的补全 |

**支持的 shell：** `bash`, `zsh`, `fish`, `powershell`

**示例：**

```bash
openspec completion install
openspec completion install zsh
openspec completion generate bash > ~/.bash_completion.d/openspec
openspec completion uninstall
```
