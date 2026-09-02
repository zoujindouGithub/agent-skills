# OpenSpec 完整工作流指南

## 目录

1. [快速路径（Core Profile）](#快速路径)
2. [扩展路径（Expanded Profile）](#扩展路径)
3. [探索模式（Explore）](#探索模式)
4. [实现模式（Apply）](#实现模式)
5. [验证模式（Verify）](#验证模式)
6. [归档模式（Archive）](#归档模式)
7. [批量归档（Bulk Archive）](#批量归档)
8. [引导模式（Onboard）](#引导模式)
9. [同步规格（Sync）](#同步规格)
10. [工作空间（Workspace）](#工作空间)

---

## 快速路径

适合需求明确、需要快速迭代的日常开发场景。

### 完整流程

```
/opsx:propose <change-name>  →  /opsx:apply  →  /opsx:archive
```

### 第一步：创建提案

```
/opsx:propose add-dark-mode
```

AI 执行：
1. 读取项目配置（`openspec/config.yaml`）和现有 Main Specs
2. 创建 `openspec/changes/active/add-dark-mode/` 目录
3. 生成以下工件：
   - `proposal.md` — 变更动机、范围、影响
   - `specs/` — Delta Specs，描述新增/修改/删除的行为
   - `design.md` — 技术设计方案
   - `tasks.md` — 原子化实现任务清单

### 第二步：执行实现

```
/opsx:apply
```

AI 执行：
1. 读取 `tasks.md`
2. 将 `proposal.md` 和 `specs/` 中的 Delta Specs 作为不可违背的指令
3. 按任务顺序逐步修改源代码
4. 完成每个任务后更新 `tasks.md` 中的复选框状态

如果同时处理多个变更，可以指定变更名：
```
/opsx:apply add-dark-mode
```

### 第三步：归档

```
/opsx:archive
```

AI 执行：
1. 验证变更结构
2. 将 Delta Specs 合并到 `openspec/specs/`（Main Specs）
3. 将变更目录移动到 `openspec/changes/archive/<date>-<name>/`

---

## 扩展路径

适合复杂变更、需要精细控制每个工件的生成过程。

### 完整流程

```
/opsx:new <change-name>  →  /opsx:continue|ff  →  /opsx:apply  →  /opsx:verify  →  /opsx:archive
```

### 第一步：创建脚手架

```
/opsx:new add-rate-limiter
```

AI 执行：
1. 创建 `openspec/changes/active/add-rate-limiter/` 目录
2. 生成基础结构（可能包含空的 `README.md`）
3. 提示下一步可生成的工件

### 第二步：逐个生成工件

```
/opsx:continue
```

AI 执行：
1. 检查当前变更目录中已存在的工件
2. 根据依赖关系确定下一个可生成的工件
3. 生成一个工件并提示下一步

重复执行 `/opsx:continue` 直到所有工件生成完毕。

### 第二步（替代）：快速生成所有工件

```
/opsx:ff
```

AI 执行：
1. 一次性生成所有缺失的规划工件
2. 效果等同于多次执行 `/opsx:continue`

适用场景：你对要构建的内容已有清晰图景，不需要逐个审阅。

### 第三步：执行实现

同快速路径的 `/opsx:apply`。

### 第四步：验证

```
/opsx:verify
```

AI 执行：
1. 读取 `specs/` 中的 Delta Specs
2. 检查源代码实现是否符合规范要求
3. 报告差异或确认通过

### 第五步：归档

同快速路径的 `/opsx:archive`。

---

## 探索模式

当你不确定需求、需要调研或比较方案时使用。

```
/opsx:explore
```

AI 作为思考伙伴，帮助你：
- 梳理问题空间
- 比较不同技术方案
- 澄清模糊需求
- 识别潜在风险

**无结构要求** — 自由讨论即可。

当思路清晰后，过渡到 `/opsx:propose`（快速路径）或 `/opsx:new`（扩展路径）。

---

## 实现模式

### 基本用法

```
/opsx:apply
```

AI 读取 `tasks.md` 并按顺序执行：
1. 加载任务清单
2. 参考 `proposal.md`、`specs/`、`design.md` 作为实现约束
3. 逐个完成任务，更新复选框

### 指定变更

```
/opsx:apply add-dark-mode
```

当同时处理多个活跃变更时使用。

### 迭代实现

实现过程中发现设计问题？

1. 直接修改 `design.md` 或 `tasks.md`
2. 重新执行 `/opsx:apply`
3. AI 会从中断处继续，无需重新开始

这是 OpenSpec 的核心优势：**实现阶段仍可回流修改规划和设计**。

---

## 验证模式

验证实现是否符合规范要求。

```
/opsx:verify
```

AI 执行：
1. 读取 `specs/` 中的所有 Delta Specs
2. 逐条检查 Given/When/Then 场景是否在代码中有对应实现
3. 检查 SHALL/MUST 要求是否被满足
4. 输出验证报告

适用时机：
- `/opsx:apply` 完成后，归档前
- 代码审查前，作为自检
- 长期维护后，确认实现未偏离规范

---

## 归档模式

标记变更完成，合并规格到 Main Specs。

```
/opsx:archive
```

AI 执行：
1. 验证变更结构完整性
2. 将 Delta Specs 合并到 `openspec/specs/`
   - ADDED：追加到对应 capability
   - MODIFIED：替换原有需求文本
   - REMOVED：标记为已删除或物理移除
3. 移动变更目录到 `openspec/changes/archive/<date>-<name>/`

### 跳过规格合并

纯工具/文档/配置变更，不影响系统行为：

```
/opsx:archive --skip-specs
```

### 归档后状态

```
openspec/
├── specs/               # 已更新，包含归档变更的规格
└── changes/
    ├── active/          # 清空或保留其他活跃变更
    └── archive/
        └── 2025-01-23-add-dark-mode/
            ├── proposal.md
            ├── specs/
            ├── design.md
            └── tasks.md
```

---

## 批量归档

当多个变更同时完成时，一次性归档。

```
/opsx:bulk-archive
```

AI 执行：
1. 列出所有活跃变更
2. 提示选择要归档的变更
3. 逐个验证并归档

---

## 引导模式

新用户首次使用 OpenSpec 时的端到端演示。

```
/opsx:onboard
```

AI 引导完成一个完整的示例变更，展示：
1. 如何创建提案
2. 如何编写规格
3. 如何设计技术方案
4. 如何拆解任务
5. 如何执行实现
6. 如何验证和归档

---

## 同步规格

将 Delta Specs 合并到 Main Specs，但不归档变更。

```
/opsx:sync
```

适用场景：
- 需要保持 Main Specs 最新，但变更仍在进行中
- 多人协作时，希望其他开发者看到最新规格
- 变更依赖其他变更的规格更新

---

## 工作空间

工作空间（Workspace）是机器本地的视图，覆盖多个关联的仓库或文件夹。

### 设置工作空间

```bash
openspec workspace setup
# 或
openspec workspace setup --no-interactive --name platform --link /repos/api --link web=/repos/web
```

### 工作空间命令

```bash
openspec workspace list              # 列出已知工作空间
openspec workspace link <path>       # 关联仓库/文件夹
openspec workspace relink <name> <path>  # 修复链接路径
openspec workspace doctor            # 检查工作空间健康状态
openspec workspace update            # 刷新工作空间配置和技能
openspec workspace open              # 打开工作空间
```

### 共享上下文（Beta）

```bash
openspec context-store setup team-context
openspec initiative create billing-launch --title "Billing Launch" --summary "Launch new billing system"
openspec new change add-billing-api --initiative billing-launch
```

Initiative 提供跨仓库的共享协调上下文，repo-local 变更可以链接到 initiative 而无需在每个仓库复制共享计划。

---

## 状态检查

随时查看变更进度：

```bash
openspec status --change add-dark-mode
```

输出示例：
```
Change: add-dark-mode
Schema: spec-driven
Progress: 2/4 artifacts complete

[x] proposal
[ ] design
[x] specs
[-] tasks (blocked by: design)
```

JSON 输出（适合脚本）：
```bash
openspec status --change add-dark-mode --json
```

---

## 指令获取

获取 AI 生成特定工件的完整指令：

```bash
openspec instructions --change add-dark-mode          # 下一个工件的指令
openspec instructions design --change add-dark-mode   # 特定工件的指令
openspec instructions apply --change add-dark-mode    # 实现阶段的指令
```

输出包含：
- 模板内容
- 项目配置中的 context 和 rules
- 依赖工件的内容

---

## 上下文卫生最佳实践

1. **规划阶段结束后清理上下文** — 开启新会话，只附加 spec 文件
2. **实现阶段保持专注** — 只加载当前变更的工件，避免加载无关历史
3. **长线程积累噪音** — 定期清理，或分阶段使用不同会话
4. **归档后清理** — 变更完成后，移除相关上下文，保持窗口清洁

---

## 故障排查

### 变更无法 apply

```bash
openspec status --change <name>          # 检查工件完成状态
openspec validate <name>                 # 检查结构问题
openspec instructions apply --change <name>  # 查看 apply 指令
```

### Schema 问题

```bash
openspec schema which --all              # 查看所有 schema 来源
openspec schema validate <name>          # 验证自定义 schema
openspec templates --schema <name>       # 查看模板路径
```

### 配置问题

```bash
openspec config list                     # 查看当前配置
openspec config path                     # 查看配置文件位置
```