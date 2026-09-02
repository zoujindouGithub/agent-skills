---
name: openspec-apply-change
description: 实现 OpenSpec 变更中的任务。当用户想要开始实现、继续实现或逐步处理任务时使用。
license: MIT
compatibility: Requires openspec CLI.
metadata:
  author: openspec
  version: "1.0"
  generatedBy: "1.4.1"
---

实现 OpenSpec 变更中的任务。

**输入**：可选择指定变更名称。如果省略，请检查是否可以从对话上下文中推断。如果模糊或不明确，你必须提示用户选择可用的变更。

**步骤**

1. **选择变更**

   如果提供了名称，直接使用它。否则：
   - 如果用户提到了某个变更，从对话上下文中推断
   - 如果仅存在一个活动的变更，则自动选择
   - 如果存在歧义，运行 `openspec list --json` 获取可用的变更，并使用 **AskUserQuestion 工具** 让用户进行选择

   始终提示："Using change: <name>" 以及如何覆盖该选择（例如：`/opsx:apply <other>`）。

2. **检查状态以了解 Schema**
   ```bash
   openspec status --change "<name>" --json
   ```
   解析 JSON 以了解：
   - `schemaName`：当前使用的工件流（例如 "spec-driven"）
   - `planningHome`、`changeRoot` 和 `actionContext`：规划范围和编辑约束
   - 哪个工件包含任务（对于 spec-driven 通常为 "tasks"，其他情况请检查状态）

3. **获取应用指令**

   ```bash
   openspec instructions apply --change "<name>" --json
   ```

   这将返回：
   - `contextFiles`：工件 ID -> 具体文件路径数组（因 Schema 而异——可能是 proposal/specs/design/tasks 或 spec/tests/implementation/docs）
   - 进度（总计、已完成、剩余）
   - 带有状态的任务列表
   - 基于当前状态的动态指令

   **处理各种状态：**
   - 如果 `state: "blocked"`（缺少工件）：显示消息，建议使用 openspec-continue-change
   - 如果 `state: "all_done"`：表示祝贺，建议归档
   - 其他情况：继续执行实现

   **工作区保护（Workspace guard）：** 如果状态 JSON 报告 `actionContext.mode: "workspace-planning"` 且 `allowedEditRoots` 为空，说明当前切片不支持完整工作区应用。将关联的代码仓库和文件夹视为只读上下文，要求用户通过明确的实现工作流选择受影响的区域，并在编辑文件之前**停止**操作。

4. **读取上下文文件**

   读取应用指令输出中 `contextFiles` 下列出的每个文件路径。
   这些文件取决于所使用的 Schema：
   - **spec-driven**：proposal、specs、design、tasks
   - 其他 Schema：遵循 CLI 输出中的 contextFiles

5. **展示当前进度**

   显示：
   - 正在使用的 Schema
   - 进度："N/M tasks complete"
   - 剩余任务概览
   - 来自 CLI 的动态指令

6. **实现任务（循环执行直至完成或受阻）**

   针对每个待处理的任务：
   - 显示当前正在处理的任务
   - 进行所需的代码更改
   - 保持更改最小化且专注
   - 在任务文件中将任务标记为已完成：`- [ ]` → `- [x]`
   - 继续执行下一个任务

   **在以下情况下暂停：**
   - 任务不明确 → 请求澄清
   - 实现过程中暴露出设计问题 → 建议更新工件
   - 遇到错误或阻碍 → 报告并等待指导
   - 用户打断

7. **完成或暂停时展示状态**

   显示：
   - 本次会话完成的任务
   - 总体进度："N/M tasks complete"
   - 如果全部完成：建议归档
   - 如果已暂停：解释原因并等待指导

**实现过程中的输出**

```
## Implementing: <change-name> (schema: <schema-name>)

Working on task 3/7: <task description>
[...implementation happening...]
✓ Task complete

Working on task 4/7: <task description>
[...implementation happening...]
✓ Task complete
```

**完成时的输出**

```
## Implementation Complete

**Change:** <change-name>
**Schema:** <schema-name>
**Progress:** 7/7 tasks complete ✓

### Completed This Session
- [x] Task 1
- [x] Task 2
...

All tasks complete! Ready to archive this change.
```

**暂停时的输出（遇到问题）**

```
## Implementation Paused

**Change:** <change-name>
**Schema:** <schema-name>
**Progress:** 4/7 tasks complete

### Issue Encountered
<description of the issue>

**Options:**
1. <option 1>
2. <option 2>
3. Other approach

What would you like to do?
```

**防范规则（Guardrails）**
- 持续推进任务，直至全部完成或受阻
- 在开始前务必读取上下文文件（来自应用指令输出）
- 如果任务模棱两可，在实现前先暂停并提问
- 如果实现过程中暴露了问题，暂停并建议更新工件
- 保持代码更改最小化，并严格限制在每个任务的作用域内
- 完成每个任务后立即更新任务复选框
- 遇到错误、阻碍或不明确的需求时暂停——不要随意猜测
- 使用 CLI 输出中的 contextFiles，不要假定特定的文件名

**流畅工作流集成**

此技能支持“针对变更的操作”模型：

- **可随时调用**：在所有工件完成之前（只要任务存在）、部分实现之后、或与其他操作交替进行
- **允许更新工件**：如果实现过程中暴露出设计问题，建议更新工件——不锁定阶段，流畅协作