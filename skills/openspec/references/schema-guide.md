# OpenSpec Schema 自定义指南

## 目录

1. [Schema 概述](#schema-概述)
2. [Schema 结构](#schema-结构)
3. [schema.yaml 详解](#schemayaml-详解)
4. [模板系统](#模板系统)
5. [创建自定义 Schema](#创建自定义-schema)
6. [常见自定义模式](#常见自定义模式)
7. [验证与调试](#验证与调试)
8. [Schema 优先级](#schema-优先级)

---

## Schema 概述

Schema 定义 OpenSpec 工作流中的**工件类型**和**依赖关系**。通过自定义 schema，你可以：

- 添加/移除工件类型（如增加 review 步骤）
- 修改工件依赖关系
- 自定义 AI 生成工件的提示模板
- 适配团队特定流程

---

## Schema 结构

```
openspec/schemas/<schema-name>/
├── schema.yaml           # 工作流定义（必需）
└── templates/            # Markdown 模板（可选）
    ├── proposal.md
    ├── specs.md
    ├── design.md
    ├── tasks.md
    └── ...               # 自定义工件模板
```

---

## schema.yaml 详解

### 基本结构

```yaml
name: my-workflow
version: 1
description: My team's custom workflow

artifacts:
  - id: proposal
    generates: proposal.md
    description: Initial proposal document
    template: proposal.md
    instruction: |
      Create a proposal that explains WHY this change is needed.
      Focus on the problem, not the solution.
    requires: []

  - id: design
    generates: design.md
    description: Technical design
    template: design.md
    instruction: |
      Create a design document explaining HOW to implement.
    requires:
      - proposal

  - id: tasks
    generates: tasks.md
    description: Implementation checklist
    template: tasks.md
    instruction: |
      Create a checklist of atomic implementation tasks.
    requires:
      - design

apply:
  requires: [tasks]
  tracks: tasks.md
```

### 字段说明

#### 顶层字段

| 字段 | 必需 | 说明 |
|------|------|------|
| `name` | 是 | Schema 名称（kebab-case） |
| `version` | 否 | Schema 版本号 |
| `description` | 否 | Schema 描述 |

#### artifacts 数组

每个工件定义：

| 字段 | 必需 | 说明 |
|------|------|------|
| `id` | 是 | 唯一标识符，用于命令和规则引用 |
| `generates` | 是 | 输出文件名（支持 glob，如 `specs/**/*.md`） |
| `description` | 否 | 人类可读的描述 |
| `template` | 否 | `templates/` 目录中的模板文件名 |
| `instruction` | 否 | AI 生成此工件时的额外指令 |
| `requires` | 否 | 依赖的工件 ID 数组（空数组表示无依赖） |

#### apply 配置

| 字段 | 必需 | 说明 |
|------|------|------|
| `requires` | 是 | 执行 apply 前必须存在的工件 ID 数组 |
| `tracks` | 否 | 用于跟踪进度的文件（通常是 `tasks.md`） |

---

## 模板系统

### 模板位置

模板存放在 `templates/` 目录，文件名与 `schema.yaml` 中 `template` 字段对应。

### 模板内容

模板是 Markdown 文件，包含：
- 章节标题（AI 应填充）
- HTML 注释（给 AI 的指导）
- 示例格式（展示预期结构）

### 示例模板

**templates/proposal.md：**

```markdown
## Why

<!-- Explain the motivation for this change. What problem does this solve? -->

## What Changes

<!-- Describe what will change. Be specific about new capabilities or modifications. -->

## Impact

<!-- Affected code, APIs, dependencies, systems -->

## Risks

<!-- What could go wrong? How do we mitigate? -->

## Rollback Plan

<!-- How do we revert if something goes wrong? -->
```

**templates/design.md：**

```markdown
## Technical Approach

<!-- High-level approach to implementation -->

## Data Model Changes

<!-- Database schema changes, migrations -->

## API Changes

<!-- New endpoints, modified contracts -->

## Frontend Changes

<!-- UI components, state management -->

## Testing Strategy

<!-- Unit tests, integration tests, e2e tests -->

## Deployment Plan

<!-- Rollout strategy, feature flags -->
```

**templates/tasks.md：**

```markdown
## Implementation Tasks

### Phase 1: Foundation
- [ ] 1.1 <Task description>
- [ ] 1.2 <Task description>

### Phase 2: Core Implementation
- [ ] 2.1 <Task description>
- [ ] 2.2 <Task description>

### Phase 3: Integration & Testing
- [ ] 3.1 <Task description>
- [ ] 3.2 <Task description>
```

---

## 创建自定义 Schema

### 方法一：复刻内置 Schema（推荐）

```bash
openspec schema fork spec-driven my-workflow
```

这会复制整个 `spec-driven` schema 到 `openspec/schemas/my-workflow/`，你可以自由编辑。

### 方法二：从零创建

```bash
# 交互式
openspec schema init my-workflow

# 非交互式
openspec schema init rapid \
  --description "Rapid iteration workflow" \
  --artifacts "proposal,tasks" \
  --default
```

---

## 常见自定义模式

### 模式一：极简工作流

适合快速原型、个人项目：

```yaml
name: rapid
version: 1
description: Fast iteration with minimal overhead

artifacts:
  - id: proposal
    generates: proposal.md
    description: Quick proposal
    template: proposal.md
    instruction: |
      Create a brief proposal for this change.
      Focus on what and why, skip detailed specs.
    requires: []

  - id: tasks
    generates: tasks.md
    description: Implementation checklist
    template: tasks.md
    instruction: |
      Create a checklist of implementation tasks.
      Keep it brief but actionable.
    requires: [proposal]

apply:
  requires: [tasks]
  tracks: tasks.md
```

### 模式二：增加 Review 步骤

适合需要预实现审查的团队：

```yaml
name: with-review
version: 1
description: Spec-driven with pre-implementation review

artifacts:
  - id: proposal
    generates: proposal.md
    template: proposal.md
    requires: []

  - id: specs
    generates: specs/**/*.md
    template: specs.md
    requires: [proposal]

  - id: design
    generates: design.md
    template: design.md
    requires: [specs]

  - id: review
    generates: review.md
    template: review.md
    instruction: |
      Create a review checklist based on the design.
      Include security, performance, and testing considerations.
    requires: [design]

  - id: tasks
    generates: tasks.md
    template: tasks.md
    requires: [specs, design, review]

apply:
  requires: [tasks]
  tracks: tasks.md
```

**templates/review.md：**

```markdown
## Security Review

<!-- Check for: input validation, auth, data exposure, injection risks -->

## Performance Review

<!-- Check for: N+1 queries, memory leaks, unnecessary re-renders -->

## Testing Review

<!-- Check for: test coverage, edge cases, integration points -->

## Approval

- [ ] Security: Approved / Needs changes
- [ ] Performance: Approved / Needs changes
- [ ] Testing: Approved / Needs changes
```

### 模式三：研究优先工作流

适合探索性项目、技术调研：

```yaml
name: research-first
version: 1
description: Research before committing to implementation

artifacts:
  - id: research
    generates: research.md
    template: research.md
    instruction: |
      Research and document:
      - Existing solutions and their trade-offs
      - Technical constraints and requirements
      - Recommended approach with rationale
    requires: []

  - id: proposal
    generates: proposal.md
    template: proposal.md
    requires: [research]

  - id: specs
    generates: specs/**/*.md
    template: specs.md
    requires: [proposal]

  - id: design
    generates: design.md
    template: design.md
    requires: [specs]

  - id: tasks
    generates: tasks.md
    template: tasks.md
    requires: [design]

apply:
  requires: [tasks]
  tracks: tasks.md
```

### 模式四：多规格能力工作流

适合大型系统，按 capability 组织规格：

```yaml
name: multi-capability
version: 1
description: Organize specs by capability domain

artifacts:
  - id: proposal
    generates: proposal.md
    template: proposal.md
    requires: []

  - id: specs
    generates: specs/**/*.md
    template: specs.md
    instruction: |
      Create delta specs organized by capability:
      - specs/auth/ for authentication changes
      - specs/billing/ for billing changes
      - specs/ui/ for frontend changes
      Only create directories for affected capabilities.
    requires: [proposal]

  - id: design
    generates: design.md
    template: design.md
    requires: [specs]

  - id: tasks
    generates: tasks.md
    template: tasks.md
    instruction: |
      Group tasks by capability, matching the specs structure.
      Reference specific spec files in task descriptions.
    requires: [design]

apply:
  requires: [tasks]
  tracks: tasks.md
```

### 模式五：文档驱动工作流

适合以文档更新为主的变更：

```yaml
name: docs-driven
version: 1
description: For documentation and content changes

artifacts:
  - id: proposal
    generates: proposal.md
    template: proposal.md
    instruction: |
      Explain what documentation needs to change and why.
    requires: []

  - id: outline
    generates: outline.md
    template: outline.md
    instruction: |
      Create a detailed outline of the new/updated documentation structure.
    requires: [proposal]

  - id: tasks
    generates: tasks.md
    template: tasks.md
    instruction: |
      Break documentation work into sections to write/revise.
    requires: [outline]

apply:
  requires: [tasks]
  tracks: tasks.md
```

---

## 验证与调试

### 验证 Schema

```bash
openspec schema validate my-workflow
```

检查：
- `schema.yaml` 语法正确
- 所有引用的模板存在
- 无循环依赖
- 工件 ID 有效

### 查看模板路径

```bash
openspec templates --schema my-workflow
```

### 查看 Schema 来源

```bash
openspec schema which my-workflow
openspec schema which --all
```

### 调试 Schema 解析

Schema 解析优先级：

1. 项目级：`openspec/schemas/<name>/`
2. 用户级：`~/.local/share/openspec/schemas/<name>/`
3. 包级：内置 schema

如果自定义 schema 未生效，检查：
- 名称拼写是否正确
- 文件是否在正确的目录
- 是否有同名 schema 在更高优先级位置

---

## Schema 优先级

### 使用自定义 Schema

```bash
# 命令行指定
openspec new change feature --schema my-workflow

# 设为项目默认（在 config.yaml 中）
schema: my-workflow

# 设为全局默认
openspec config set schema my-workflow
```

### 变更级覆盖

在变更目录中创建 `.openspec.yaml`：

```yaml
schema: my-workflow
```

这会覆盖项目配置和全局配置。

---

## 高级：动态模板

模板中可以使用占位符，在生成时被替换：

```markdown
<!-- templates/proposal.md -->
## Change: {{change_name}}

### Motivation

<!-- Why are we making this change? -->

### Affected Areas

<!-- Which capabilities are affected? -->
```

**注意：** 占位符支持取决于 OpenSpec CLI 版本，请查阅最新文档确认。

---

## 社区 Schema

OpenSpec 支持社区维护的 schema，通过独立仓库分发：

| Schema | 维护者 | 仓库 | 描述 |
|--------|--------|------|------|
| `superpowers-bridge` | @JiangWay | JiangWay/openspec-schemas | 集成 obra/superpowers 执行技能 |

使用社区 schema：

1. 复制 schema  bundle 到 `openspec/schemas/<schema-name>/`
2. 按仓库 README 中的安装说明操作
3. 使用 `openspec schema validate <name>` 验证

贡献社区 schema：在 GitHub 上开 issue 或提交 PR 添加到你的仓库链接。
