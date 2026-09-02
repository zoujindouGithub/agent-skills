---
name: openspec
description: >
  OpenSpec 规范驱动开发（Spec-Driven Development）完整技能套件。
  支持通过结构化规范文档驱动 AI 辅助开发，涵盖提案、规范、设计、任务、实现、验证、归档全生命周期。

  触发场景：
  - 用户使用 /opsx:propose、/opsx:apply、/opsx:archive 等 OpenSpec 命令
  - 用户需要创建或编辑 proposal.md、specs/、design.md、tasks.md 等 OpenSpec 工件
  - 用户需要初始化 OpenSpec 项目、配置 schema、自定义工作流
  - 用户需要理解 OpenSpec 规范格式（Gherkin 风格 Given/When/Then）
  - 用户需要验证 OpenSpec 变更或合并 Delta Specs 到 Main Specs
  - 用户提及 "openspec"、"spec-driven"、"规范驱动"、"opsx"、"变更提案" 等关键词
  - 用户需要编写需求规格、技术设计文档、任务清单或进行代码实现规划
---

# OpenSpec 规范驱动开发

OpenSpec 是一个 AI 辅助的规范驱动开发框架。核心思想：**先对齐规范，再编写代码**。

## 核心理念

- **Fluid not rigid** — 灵活迭代，非僵化流程
- **Iterative not waterfall** — 随时可回溯修改任何工件
- **Easy not complex** — 轻量级 Markdown 规范，非重量级文档
- **Built for brownfield** — 同时适用于遗留项目和全新项目
- **Scalable** — 从个人项目到企业级均可使用

## 项目结构

```
openspec/
├── config.yaml          # 项目配置（技术栈、规则、默认 schema）
├── specs/               # Main Specs — 系统当前完整行为（源真相）
│   └── <capability>/
│       └── spec.md
└── changes/             # 变更目录
    ├── active/          # 活跃变更
    │   └── <change-name>/
    │       ├── proposal.md      # 为什么做？变更动机与范围
    │       ├── specs/           # 做什么？Delta Specs（增量规格）
    │       │   └── <capability>/
    │       │       └── spec.md
    │       ├── design.md        # 怎么做？技术设计方案
    │       └── tasks.md         # 具体步骤？原子化任务清单
    └── archive/         # 归档变更
        └── <date>-<change-name>/
```

## 工件依赖关系

```
proposal ──→ specs ──→ design ──→ tasks ──→ implement
   ↑          ↑          ↑                    │
   └──────────┴──────────┴────────────────────┘
              随时更新，持续迭代
```

依赖是**使能关系**而非**门禁**——你可以随时修改任何工件，AI 生成新工件时会参考已有工件作为输入。

## 两种工作模式

### 快速路径（Core Profile）

适合需求明确、快速迭代的日常开发：

```
/opsx:propose add-dark-mode   →  一键生成 proposal + specs + design + tasks
/opsx:apply                    →  按 tasks.md 执行任务实现
/opsx:archive                  →  归档变更，合并 specs 到 Main Specs
```

### 扩展路径（Expanded Profile）

适合复杂变更、需要精细控制：

```
/opsx:new add-rate-limiter     →  创建变更脚手架
/opsx:continue                 →  逐个生成工件（proposal → specs → design → tasks）
/opsx:ff                       →  快速生成所有规划工件
/opsx:apply                    →  执行任务实现
/opsx:verify                   →  验证实现是否符合规范
/opsx:archive                  →  归档
```

## 完整命令速查

| 命令 | 功能 | 工作流 |
|------|------|--------|
| `/opsx:explore` | 探索式调研，澄清需求 | 通用 |
| `/opsx:propose` | 一键创建提案+所有规划工件 | Core |
| `/opsx:new` | 新建变更脚手架 | Expanded |
| `/opsx:continue` | 创建下一个工件 | Expanded |
| `/opsx:ff` | 快速生成所有规划工件 | Expanded |
| `/opsx:apply` | 按任务清单执行开发 | 通用 |
| `/opsx:verify` | 验证实现是否符合规范 | Expanded |
| `/opsx:sync` | 同步 Delta Specs 到 Main Specs | Core |
| `/opsx:archive` | 归档完成，合并规格 | 通用 |
| `/opsx:bulk-archive` | 批量归档多个已完成变更 | Expanded |
| `/opsx:onboard` | 引导式端到端演示 | Expanded |

## CLI 命令速查

```bash
# 初始化与更新
openspec init                          # 交互式初始化项目
openspec init --tools all              # 为所有支持的 AI 工具配置
openspec update                        # 升级后更新 AI 工具配置

# 浏览与查看
openspec list                          # 列出活跃变更
openspec list --specs                  # 列出 Main Specs
openspec show <change-name>            # 查看变更详情
openspec show <spec-name> --type spec  # 查看规格详情
openspec view                          # 交互式仪表板

# 验证
openspec validate <change-name>        # 验证变更结构
openspec validate --all                # 验证所有变更和规格
openspec validate --all --json         # JSON 输出（适合 CI）

# 工作流
openspec new change <name>             # 创建变更脚手架
openspec status --change <name>        # 查看工件完成状态
openspec instructions --change <name>  # 获取 AI 生成工件的指令

# 归档
openspec archive <change-name>           # 归档变更
openspec archive <name> --yes          # 跳过确认
openspec archive <name> --skip-specs   # 不合并规格（纯工具/文档变更）

# Schema 管理
openspec schemas                       # 列出可用 schema
openspec schema init <name>            # 创建自定义 schema
openspec schema fork spec-driven <name> # 复刻内置 schema
openspec schema validate <name>        # 验证 schema

# 配置
openspec config list                   # 查看配置
openspec config set <key> <value>      # 设置配置项
openspec config profile                # 切换工作流 profile
```

## 规范文档格式（Spec Format）

OpenSpec 使用 **Gherkin 风格** 的 Given/When/Then 描述场景，配合规范性术语（SHALL/MUST/SHOULD）：

```markdown
## ADDED Requirements

### Requirement: 用户会话过期
系统 SHALL 支持可配置的会话过期时间。

#### Scenario: 默认超时
- **GIVEN** 用户已认证
- **WHEN** 24 小时无活动
- **THEN** 使会话令牌失效

#### Scenario: 记住我扩展会话
- **GIVEN** 用户在登录时勾选"记住我"
- **WHEN** 30 天已过
- **THEN** 使会话令牌失效
- **AND** 清除持久化 Cookie
```

Delta 类型标记：
- `ADDED` — 全新功能需求
- `MODIFIED` — 修改现有逻辑（须包含完整修订后文本）
- `REMOVED` — 废弃功能

详细格式指南见 [references/spec-format.md](references/spec-format.md)。

## 配置项目（config.yaml）

```yaml
schema: spec-driven

context: |
  Tech stack: TypeScript, React, Node.js, PostgreSQL
  API style: RESTful, documented in docs/api.md
  Testing: Jest + React Testing Library
  We value backwards compatibility for all public APIs

rules:
  proposal:
    - Include rollback plan
    - Identify affected teams
  specs:
    - Use Given/When/Then format
    - Reference existing patterns before inventing new ones
  design:
    - Include database migration plan if schema changes
    - Document API changes with before/after comparison
```

- `context` — 注入到**所有**工件生成提示中
- `rules.<artifact>` — 仅注入到对应工件类型

## 自定义 Schema

当项目配置不足以满足需求时，创建自定义工作流：

```bash
# 复刻内置 schema
openspec schema fork spec-driven my-workflow

# 或从零创建
openspec schema init my-workflow \
  --description "Rapid iteration workflow" \
  --artifacts "proposal,tasks" \
  --default
```

自定义 schema 结构：

```
openspec/schemas/my-workflow/
├── schema.yaml           # 工件定义与依赖关系
└── templates/
    ├── proposal.md       # 各工件的 Markdown 模板
    ├── specs.md
    ├── design.md
    └── tasks.md
```

详细指南见 [references/schema-guide.md](references/schema-guide.md)。

## 使用模式与最佳实践

### 模式一：需求明确，快速落地

```
/opsx:propose add-dark-mode
/opsx:apply
/opsx:archive
```

### 模式二：需求模糊，先探索

```
/opsx:explore "用户反馈登录流程太复杂，如何简化？"
# ... 讨论后需求清晰 ...
/opsx:propose simplify-login-flow
/opsx:apply
/opsx:archive
```

### 模式三：复杂变更，精细控制

```
/opsx:new add-rate-limiter
/opsx:continue              # 生成 proposal
# 人工审阅 proposal，修改后：
/opsx:continue              # 生成 specs
/opsx:continue              # 生成 design
# 发现设计问题，直接修改 design.md
/opsx:ff                    # 生成剩余工件（tasks）
/opsx:apply
/opsx:verify               # 验证实现
/opsx:archive
```

### 模式四：实现中发现设计问题

```
/opsx:apply
# 发现 design.md 中的方案不可行
# 直接修改 design.md 和 tasks.md
/opsx:apply                 # 从中断处继续，无需重新开始
```

## 参考文档导航

| 文档 | 内容 | 何时查阅 |
|------|------|----------|
| [references/workflow-guide.md](references/workflow-guide.md) | 完整工作流指南，含所有命令详解 | 需要深入理解某个命令或工作流时 |
| [references/spec-format.md](references/spec-format.md) | 规范文档格式详解，含 Delta/Merge 规则 | 编写或审阅 specs/ 下的规范文件时 |
| [references/cli-reference.md](references/cli-reference.md) | CLI 命令完整参考，含所有选项和 JSON 输出 | 使用 CLI 进行高级操作或脚本化时 |
| [references/schema-guide.md](references/schema-guide.md) | Schema 自定义完整指南 | 需要自定义工作流或模板时 |
| [references/examples/](references/examples/) | proposal、spec、design、tasks 完整示例 | 需要参考模板或理解预期输出格式时 |

## 与 Kimi 的集成

OpenSpec 原生支持 Kimi CLI。运行 `openspec init --tools kimi` 后，会在 `.kimi/skills/` 下生成对应工作流的技能文件。

本技能（`openspec`）提供更全面的参考文档和示例，作为原生技能的补充。当用户需要：
- 理解 OpenSpec 概念和哲学
- 查看完整命令参考和 CLI 用法
- 学习规范文档格式和最佳实践
- 参考示例模板
- 自定义 Schema 和工作流

时，使用本技能。

## 关键原则

1. **先规范，后代码** — 在编写任何代码前，确保 proposal、specs、design 已对齐
2. **小步快跑** — 每个变更聚焦单一功能，保持变更目录清晰
3. **随时迭代** — 实现中发现问题？直接修改 design.md 或 tasks.md，然后继续
4. **场景驱动** — 用 Given/When/Then 描述具体场景，避免模糊形容词
5. **任务原子化** — tasks.md 中的任务应足够小，可独立验证
6. **及时归档** — 变更完成后立即归档，保持 `changes/active/` 为活跃工作队列
7. **上下文卫生** — 规划阶段和实现阶段之间，建议清理上下文或开启新会话
