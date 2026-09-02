---
name: openspec-propose
description: 一步生成包含所有产物的全新变更提议。当用户希望快速描述其构建需求，并获取包含设计、规范及可直接用于实现的任务等完整提议时使用。
license: MIT
compatibility: Requires openspec CLI.
metadata:
  author: openspec
  version: "1.0"
  generatedBy: "1.4.1"
---

提议新变更 - 一步完成变更创建并生成所有产物。

我将创建一个包含以下产物的变更：
- proposal.md（内容与原因 - what & why）
- design.md（实现方式 - how）
- tasks.md（实现步骤 - implementation steps）

准备好实施时，请运行 `/opsx:apply`

---

**输入**：用户的请求应包含变更名称（kebab-case 命名规范）或对他们想要构建的内容的描述。

**步骤**

1. **若未提供明确输入，询问用户想要构建什么**

   使用 **AskUserQuestion 工具**（开放式问题，不设预设选项）询问：
   > "你想处理什么变更？请描述你想构建或修复的内容。"

   根据用户的描述推导出一个 kebab-case 格式的名称（例如："add user authentication" → `add-user-auth`）。

   **重要提示**：在明确用户想要构建的内容之前，请勿继续操作。

2. **创建变更目录**
   ```bash
   openspec new change "<name>"
   ```
   这将在 CLI 通过 `.openspec.yaml` 解析的规划主目录（planning home）中创建一个脚手架变更。

3. **获取产物构建顺序**
   ```bash
   openspec status --change "<name>" --json
   ```
   解析 JSON 以获取：
   - `applyRequires`：实施前所需的产物 ID 数组（例如：`["tasks"]`）
   - `artifacts`：所有产物及其状态和依赖关系的列表
   - `planningHome`、`changeRoot`、`artifactPaths` 和 `actionContext`：路径和作用域上下文。请使用这些信息，而不要假定使用本地仓库路径。

4. **按顺序创建产物，直到满足应用条件（apply-ready）**

   使用 **TodoWrite 工具** 跟踪产物的生成进度。

   按依赖顺序循环处理产物（优先处理没有未决依赖项的产物）：

   a. **对于每个处于 `ready` 状态（依赖项均已满足）的产物**：
      - 获取指令：
        ```bash
        openspec instructions <artifact-id> --change "<name>" --json
        ```
      - 指令 JSON 包含：
        - `context`：项目背景（作为给你的约束条件 - 切勿包含在输出中）
        - `rules`：产物专属规则（作为给你的约束条件 - 切勿包含在输出中）
        - `template`：用于输出文件的结构模板
        - `instruction`：针对该产物类型的模式（schema）特定指导
        - `resolvedOutputPath`：写入产物的解析后路径或模式
        - `dependencies`：需读取以获取上下文的已完成产物
      - 读取所有已完成的依赖文件以获取上下文
      - 使用 `template` 作为结构创建产物文件，并将其写入 `resolvedOutputPath`
      - 将 `context` 和 `rules` 作为约束应用 - 但切勿将它们复制到文件中
      - 显示简要进度："Created <artifact-id>"

   b. **持续处理，直到所有 `applyRequires` 产物均已完成**
      - 创建每个产物后，重新运行 `openspec status --change "<name>" --json`
      - 检查 `applyRequires` 中的每个产物 ID 在 artifacts 数组中的状态是否均为 `status: "done"`
      - 当所有 `applyRequires` 产物均完成时停止

   c. **如果某个产物需要用户输入**（上下文不明确）：
      - 使用 **AskUserQuestion 工具** 进行澄清
      - 随后继续创建

5. **显示最终状态**
   ```bash
   openspec status --change "<name>"
   ```

**输出**

完成所有产物后，进行如下总结：
- 变更名称及所在位置
- 已创建产物的列表及简要描述
- 就绪提示："All artifacts created! Ready for implementation."（所有产物已创建！可随时开始实施。）
- 后续操作提示："Run `/opsx:apply` or ask me to implement to start working on the tasks."（运行 `/opsx:apply` 或让我开始实现以执行任务。）

**产物创建指南**

- 遵循来自 `openspec instructions` 中针对每种产物类型的 `instruction` 字段要求
- 模式（schema）定义了每个产物应包含的内容 - 请严格遵循
- 在创建新产物之前，先读取依赖产物以获取上下文
- 使用 `template` 作为输出文件的结构 - 填入相应章节内容
- **重要提示**：`context` 和 `rules` 是针对“你”的约束，而不是文件内容
  - 切勿将 `<context>`、`<rules>`、`<project_context>` 块复制到产物中
  - 它们用于指导你编写内容，但绝不能出现在输出文件中

**防护准则（Guardrails）**
- 创建实施所需的所有产物（由模式的 `apply.requires` 定义）
- 创建新产物之前，务必先读取依赖产物
- 如果关键上下文不明确，请向用户提问 - 但建议在合理范围内自行做出决策以保持推进势头
- 如果已存在同名变更，询问用户是继续该变更还是创建新变更
- 写入后确认每个产物文件确实存在，然后再继续处理下一个产物