---
name: openspec-archive-change
description: 在实验性工作流中归档已完成的变更。当用户希望在实现完成后对变更进行最终确认并归档时使用。
license: MIT
compatibility: Requires openspec CLI.
metadata:
  author: openspec
  version: "1.0"
  generatedBy: "1.4.1"
---

在实验性工作流中归档已完成的变更。

**输入**：可选择性指定变更名称。若省略，请检查是否能从对话上下文中推断。若不明确或存在歧义，则**必须**提示用户选择可用的变更。

**步骤**

1. **若未提供变更名称，提示用户选择**

   运行 `openspec list --json` 获取可用变更。使用 **AskUserQuestion 工具**让用户进行选择。

   仅显示活跃的变更（尚未归档的变更）。
   若可用，请包含每个变更所使用的 schema。

   **重要提示**：切勿猜测或自动选择变更。始终由用户进行选择。

2. **检查工件（artifact）完成状态**

   运行 `openspec status --change "<name>" --json` 检查工件完成情况。

   解析 JSON 以了解：
   - `schemaName`：正在使用的工作流
   - `planningHome`、`changeRoot`、`artifactPaths` 和 `actionContext`：路径和作用域上下文
   - `artifacts`：工件列表及其状态（`done` 或其他）

   如果状态报告 `actionContext.mode: "workspace-planning"`，请说明此切片（slice）不支持工作区归档并**终止**操作。不要将工作区变更移动到仓库本地归档中，也不要编辑关联的仓库。

   **如果存在任何未处于 `done` 状态的工件：**
   - 显示警告并列出未完成的工件
   - 使用 **AskUserQuestion 工具**确认用户是否要继续
   - 若用户确认，则继续执行

3. **检查任务完成状态**

   读取任务文件（通常为 `tasks.md`）以检查是否存在未完成的任务。

   统计标记为 `- [ ]`（未完成）与 `- [x]`（已完成）的任务数量。

   **如果发现未完成的任务：**
   - 显示警告，指出未完成任务的数量
   - 使用 **AskUserQuestion 工具**确认用户是否要继续
   - 若用户确认，则继续执行

   **如果任务文件不存在：** 继续执行，不显示与任务相关的警告。

4. **评估增量规范（delta spec）同步状态**

   使用状态 JSON 中的 `artifactPaths.specs.existingOutputPaths` 检查是否存在增量规范。如果不存在，则无需同步提示直接继续。

   **如果存在增量规范：**
   - 将每个增量规范与位于 `openspec/specs/<capability>/spec.md` 的对应主规范进行比较
   - 确定将应用哪些变更（新增、修改、删除、重命名）
   - 在提示之前显示合并后的摘要

   **提示选项：**
   - 如果需要变更："立即同步（推荐）"、"不同步直接归档"
   - 如果已同步："立即归档"、"仍然同步"、"取消"

   如果用户选择同步，使用 Task 工具（subagent_type: "general-purpose"，prompt: "Use Skill tool to invoke openspec-sync-specs for change '<name>'. Delta spec analysis: <include the analyzed delta spec summary>"）。无论选择如何，之后都继续进行归档。

5. **执行归档**

   如果 `planningHome.changesDir` 下不存在 `archive` 目录，则创建该目录：
   ```bash
   mkdir -p "<planningHome.changesDir>/archive"
   ```

   使用当前日期生成目标名称：`YYYY-MM-DD-<change-name>`

   **检查目标是否已存在：**
   - 如果存在：失败并报错，建议重命名现有归档或使用其他日期
   - 如果不存在：将 `changeRoot` 移动到归档目录

   ```bash
   mv "<changeRoot>" "<planningHome.changesDir>/archive/YYYY-MM-DD-<name>"
   ```

6. **显示摘要**

   显示归档完成摘要，包括：
   - 变更名称
   - 所使用的 Schema
   - 归档位置
   - 规范是否已同步（若适用）
   - 关于任何警告的说明（未完成的工件/任务）

**成功时的输出**

```
## Archive Complete

**Change:** <change-name>
**Schema:** <schema-name>
**Archived to:** the archive path derived from `planningHome.changesDir`/YYYY-MM-DD-<name>/
**Specs:** ✓ Synced to main specs (or "No delta specs" or "Sync skipped")

All artifacts complete. All tasks complete.
```

**防范机制（Guardrails）**
- 若未提供变更名称，始终提示用户选择变更
- 使用工件图（`openspec status --json`）检查完成状态
- 不要因警告而阻断归档 —— 仅做提示并确认
- 移动到归档时保留 `.openspec.yaml`（它会随目录一起移动）
- 清晰展示已执行操作的摘要
- 如果请求同步，请使用 openspec-sync-specs 方式（Agent 驱动）
- 如果存在增量规范，始终在提示前运行同步评估并显示合并摘要