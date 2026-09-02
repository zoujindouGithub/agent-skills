---
name: openspec-sync-specs
description: 将变更中的增量规范（delta specs）同步到主规范（main specs）。当用户希望使用增量规范中的变更来更新主规范，而无需归档该变更时使用。
license: MIT
compatibility: Requires openspec CLI.
metadata:
  author: openspec
  version: "1.0"
  generatedBy: "1.4.1"
---

将变更中的增量规范（delta specs）同步到主规范（main specs）。

这是一个**智能体驱动（agent-driven）**的操作——你将读取增量规范并直接编辑主规范以应用变更。这允许进行智能合并（例如：仅添加一个场景而无需复制整个需求）。

**输入**：可选指定变更名称。如果省略，检查是否可以从对话上下文中推断。如果模糊或不明确，你**必须**提示用户选择可用的变更。

**步骤**

1. **若未提供变更名称，提示用户选择**

   运行 `openspec list --json` 获取可用变更。使用 **AskUserQuestion 工具** 让用户进行选择。

   展示包含增量规范（位于 `specs/` 目录下）的变更。

   **重要提示**：切勿猜测或自动选择变更。始终让用户做出选择。

2. **解析变更上下文**

   运行：
   ```bash
   openspec status --change "<name>" --json
   ```

   如果状态报告显示 `actionContext.mode: "workspace-planning"`，请说明当前切片不支持工作区规范同步并**停止**操作。不要回退到仓库本地路径或编辑关联仓库。

3. **查找增量规范**

   使用状态 JSON 中的 `artifactPaths.specs.existingOutputPaths` 作为增量规范文件列表。

   每个增量规范文件包含如下小节：
   - `## ADDED Requirements` - 待添加的新需求
   - `## MODIFIED Requirements` - 对现有需求的变更
   - `## REMOVED Requirements` - 待移除的需求
   - `## RENAMED Requirements` - 待重命名的需求（FROM:/TO: 格式）

   如果未找到增量规范，通知用户并停止。

4. **针对每个增量规范，将变更应用到主规范**

   对于 CLI 返回的每个仓库本地能力增量规范路径：

   a. **读取增量规范**以理解预期的变更

   b. **读取位于 `openspec/specs/<capability>/spec.md` 的主规范**（可能尚不存在）

   c. **智能应用变更**：

      **ADDED Requirements：**
      - 如果主规范中不存在该需求 → 添加它
      - 如果需求已存在 → 更新它以保持匹配（视为隐式的 MODIFIED）

      **MODIFIED Requirements：**
      - 在主规范中找到该需求
      - 应用变更——这可以是：
        - 添加新场景（无需复制现有场景）
        - 修改现有场景
        - 更改需求描述
      - 保留增量规范中未提及的场景/内容

      **REMOVED Requirements：**
      - 从主规范中移除整个需求块

      **RENAMED Requirements：**
      - 找到 FROM 需求，重命名为 TO

   d. 如果能力尚不存在，**创建新的主规范**：
      - 创建 `openspec/specs/<capability>/spec.md`
      - 添加 Purpose（目的）小节（可以简短，标记为 TBD）
      - 添加包含 ADDED 需求的 Requirements（需求）小节

5. **展示总结**

   应用所有变更后，总结：
   - 更新了哪些能力
   - 进行了哪些变更（添加/修改/移除/重命名的需求）

**增量规范格式参考**

```markdown
## ADDED Requirements

### Requirement: New Feature
The system SHALL do something new.

#### Scenario: Basic case
- **WHEN** user does X
- **THEN** system does Y

## MODIFIED Requirements

### Requirement: Existing Feature
#### Scenario: New scenario to add
- **WHEN** user does A
- **THEN** system does B

## REMOVED Requirements

### Requirement: Deprecated Feature

## RENAMED Requirements

- FROM: `### Requirement: Old Name`
- TO: `### Requirement: New Name`
```

**核心原则：智能合并**

与程序化合并不同，你可以应用**部分更新**：
- 要添加场景，只需在 MODIFIED 下包含该场景即可——无需复制现有场景
- 增量代表*意图*，而不是整体替换
- 运用你的判断力合理合并变更

**成功输出示例**

```
## Specs Synced: <change-name>

Updated main specs:

**<capability-1>**:
- Added requirement: "New Feature"
- Modified requirement: "Existing Feature" (added 1 scenario)

**<capability-2>**:
- Created new spec file
- Added requirement: "Another Feature"

Main specs are now updated. The change remains active - archive when implementation is complete.
```

**安全防线（Guardrails）**
- 在进行修改之前，同时读取增量规范和主规范
- 保留增量中未提及的现有内容
- 如果有任何不明确之处，请要求澄清
- 在执行过程中展示你正在修改的内容
- 操作应具备幂等性——运行两次应得到相同的结果