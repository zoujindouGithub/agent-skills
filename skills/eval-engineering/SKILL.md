---
name: eval-engineering
description: 迭代检查 Agent 代码库及可选的用户提供 Traces、访谈用户，并逐一创建、运行和审计 Harbor 评测任务。适用于 Agent 评测、Harbor 任务、基准测试用例、验证器设计或受控 Agent 环境。
---

# 评测工程 (Eval Engineering)

与用户协同定义、构建、运行和审计 Harbor 任务。

```text
映射 Harness 与环境 -> 提出评测方向 -> 用户选择
-> 起草规范 -> 用户批准 -> 构建 + 运行 + 审计 -> 迭代重复
```

请使用最新的 Harbor 版本。将任务源码存放在 `evals/` 下。当后续任务依赖尚未验证的 Harness、Environment 或 Verifier 时，采用串行构建；当用户提出要求时，可并行构建相互独立的多项任务。

## 概念边界

- **Task（任务）：** `instruction.md` 加上一个 Environment（环境）和 Verifier（验证器）。
- **Harness（测试夹具）：** Harbor 运行的完整 Agent：模型、Prompt、主循环、代码库定义的工具、中间件/钩子（hooks）、记忆/会话行为以及 Harbor 适配器。Harbor 将其统称为 Agent。
- **Environment（环境）：** 包围 Harness 的容器/外部世界：操作系统、文件、底层支撑数据、服务、身份凭证、权限、网络、时钟和可变状态。
- **Verifier（验证器）：** 独立对最终产物或生成的 Environment 状态进行打分的测试脚本；仅在最终状态无法提供所需证据时才使用执行轨迹（trajectory）。

代码库定义的工具代码归属于 Harness。工具背后的数据或服务归属于 Environment。例如：文档 Agent 的 `search_docs` 定义和结果解析保留在 Harness 中；冻结的搜索索引及其错误处理行为存在于 Environment 中。如果生产环境动态提供工具服务器，则将该服务器保留在 Environment 中，并维持 Harness 发现和调用它的原有方式。

## 对预期产出进行打分

- 对于有状态的操作，优先对独立观测到的最终 Environment 状态打分。例如：存在对应请求房间的预订记录，且不存在冲突的预订。
- 默认将 ATIF 作为诊断性证据。仅在最终状态无法证实需求时才使用轨迹或会话证据，例如证明后续的用户轮次（turns）复用了同一个会话。
- 除非是面向用户的硬性需求，否则不要强制限制工具名称、子 Agent、重试次数、精确的更新次数或完全一致的措辞。
- 在构建之前，明确声明 Agent 可见的内容、面向用户的必要产出、禁止产生的副作用以及必须判定为通过的实质等价产出。切勿根据评估者隐藏的个人偏好进行打分。

## 参考文档

在涉及对应决策时查阅各参考文档：

- [Trace sourcing](references/trace-sourcing.md)：仅在用户提供数据源时选择并分析 Traces。
- [Harness](references/harness.md)：识别 Harbor 将要运行的实际 Agent 并保留其行为特性。
- [Task design](references/task-design.md)：将选定的某项能力转化为可判定的请求。
- [Environment building](references/environment-building.md)：选择使用实时（live）、冻结（frozen）还是模拟（simulated）的底层数据与服务。
- [Multi-turn simulation](references/multi-turn-simulation/guide.md)：通过单个 Harness 会话运行脚本化或由 LLM 生成的多轮用户对话。
- [Verifier design](references/verifier-design.md)：定义独立证据、打分机制与校准方法。
- [Harbor](references/harbor.md)：创建、运行和检查 Harbor 任务。

## 1. 映射 Harness 与生产 Environment

从公共 Agent 入口点开始，追踪所有可达代码。

```text
Harness: 入口点；Prompt；模型；循环；路由；重试；钩子；记忆；
         代码库定义的工具、输入、输出与副作用
Environment: 文件；记录；索引；工具背后的服务；身份凭证；
             权限；网络；时间；可变状态
Purpose: 目标用户、任务与有价值的产出
Evidence: 测试、Fixtures、Issues、现有评测及记录的故障案例
```

映射期间切勿启动服务、安装软件包或使用凭据。在对话中解释该映射关系，且仅询问代码无法解答的问题，例如“哪个用户任务最关键？”或“本次评测必须拦截哪类故障？”

如果用户提供了 Traces，请阅读 [Trace sourcing](references/trace-sourcing.md)。仅在 Trace 证据能够改变评测方向、依赖行为、真实请求或故障案例时才加以使用。切勿将 Trace 中记录的答案直接视作绝对真值（ground truth）。

## 2. 提出评测方向

基于映射分析及提供的 Traces，提出两到三个具体的能力评测方向：

```text
名称：选择正确的账户查询方式
示例请求：“账户 A 使用的是什么套餐？”
测试项：查询 A，使用返回的套餐信息，且不捏造账户详情
依赖项：现有只读查询背后的已知账户记录
```

推荐其中一个方向并说明理由。在开始实现之前由用户做出选择。

## 3. 起草并审批规范

阅读关于 Harness、Task、Environment 和 Verifier 的参考文档。在用户选定方向后，编写以下文件：

```text
evals/<task-id>/
├── harness.md
├── environment.md
└── task.md
```

这些是位于可运行任务旁的控制面审查文件。切勿将它们复制或挂载到 Harness 工作区或任务镜像中。`task.md` 是审查规范；Harbor 的 `instruction.md` 则是根据审批通过的规范所生成的 Harness 可见请求。

- `harness.md`：入口点、保留行为、适配器、会话、凭据、记录的证据以及重构差异。
- `environment.md`：实时/冻结/模拟依赖、后端契约、生成或复制的数据、架构与关联关系、存储、副作用、重置机制及保真度限制。
- `task.md`：能力定义、请求内容、初始条件、通过条件、Verifier 证据及可接受的替代方案。

针对每个依赖项，推荐采用实时、冻结还是模拟方案。由难以复现的数据支撑的只读、低成本服务是强烈的实时候选对象；稳定的复制数据是强烈的冻结候选对象；写入操作、不稳定服务和可重置状态是强烈的模拟候选对象。若使用实时服务，需声明所需的凭据名称。

在终端中完整打印这三份规范的内容，保持简洁明了。展示它们的文件路径及你的建议，然后请用户审批或提出修改。只有在获得用户明确批准后，才可将规范标记为已批准。在三份规范全部获批前，切勿构建 Harbor 任务。如果用户反馈或具体实现改变了请求、Harness、Environment 或 Verifier 边界，需更新受影响的规范，展示变更内容并重新获取批准。

对于多轮用户对话，当后续输入不依赖 Harness 的响应时，优先使用固定的追问。仅在回复必须进行反应、纠错、拒绝或终止时才使用 LLM 模拟用户；请查阅多轮对话参考文档，并在方案中包含模拟器所需的凭据。

## 4. 构建单个 Harbor 任务

```text
evals/<task-id>/
├── task.toml
├── instruction.md
├── task.md
├── harness.md
├── environment.md
├── environment/
└── tests/
```

尽可能直接使用批准的 Harness 而不做修改。仅在 Harbor 调用需要时才添加适配器。切勿向 Harness 泄露隐藏真值、模拟器指令、验证标准或裁判模型（judge）凭据。

优先针对最终状态、产物、测试和独立重新计算的事实使用程序化检查。仅对代码无法合理裁决的语义含义使用 LLM 裁判。在调用裁判之前先运行确定性检查；仅将最终产物和针对该未决语义问题的独立证据传给裁判。输出单一的主奖励分（primary reward）。

## 5. 运行与审计

利用从提供的 Traces、历史评测运行或类生产任务变体中提取的真实案例来校准 Verifier：包括合法的同义改写、看似合理的错误结果以及所有已知的边界情况。使用 Harbor 所用的相同 Verifier 命令运行它们。通过 Harbor 运行 Harness，随后检查：

- Harness 记录的消息、模型/工具调用、结果、重试和错误；
- Environment 观测到的服务调用结果、初始/最终状态以及重置情况；
- Verifier 证据、判定、原因、奖励分和错误；
- 解析后的 Harness 和 Environment 配置。

对于每一个零分（zero reward），将证据归类为：合理的 Agent 失败、Verifier 缺陷、Environment 缺陷或泄露、或基础设施错误。在将非 Agent 失败作为评测结果之前，必须先修复并重新运行。如果 Environment 泄露了答案、错误答案被判定通过、或有效结果被判定失败，则该评测未完成。

对于 LLM 模拟用户，检查具有代表性的正确、错误、澄清和终止路径。当其回复不符合常理时，修改其交互契约或模型。模拟器终止并不代表成功，唯有 Verifier 能赋予奖励分。

## 6. 复盘与迭代

详细说明任务路径及准确的 Harbor 命令、请求内容、Harness、Environment、运行行为、Verifier 判定和主要局限性。任务完成的标志是：完成一次真实的 Harbor 运行、具备证明 Verifier 已度量目标能力的证据、并获得用户批准。若继续进行，复用现有证据并提出另一项不同的能力评测方向。

## 不变式规则 (Invariants)

- 每个 Harbor 任务仅评测一项能力。
- 禁止向生产环境写入；在各次试验（trials）之间重置可变状态。
- 确保隐藏真值以及模拟器/裁判凭据对 Harness 绝对不可见。
- 将构建失败、凭据错误、重置失败、超时、裁判异常和 Verifier 故障视为基础设施错误，而非 Agent 任务执行失败。