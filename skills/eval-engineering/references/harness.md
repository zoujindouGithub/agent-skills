# Harness（测试夹具）

Harness 是 Harbor 运行的完整智能体（Agent）。Harbor 的核心概念中将其称为 Agent。

它负责管理：

- 模型配置、提示词（prompts）、循环机制、路由、重试与停止条件；
- 代码库中定义的工具定义与实现，包括参数/结果解析；
- 中间件、钩子（hooks）、记忆、会话状态以及上下文组装；
- 启动智能体并记录其执行轨迹（rollout）的 Harbor 适配器。

Environment（环境）则负责管理其外部包围的一切：文件、数据、工具背后的服务、权限、网络、时间以及可变外部状态。

## 编写 `harness.md`

在实现之前，编写 `evals/specs/<task-id>/harness.md`：

```text
Status: draft | approved
Entrypoint: 确切的可调用对象或命令
Source: 代码库路径与版本号（revision）
Preserved behavior: 提示词、模型循环、工具、钩子、记忆、停止条件
Adapter: I/O 转换与依赖绑定，或填 none
Session: 单轮（single-turn）或确切的多轮持久化机制
Credentials: 仅限环境变量名称
Recorded evidence: 消息、模型/工具调用、结果、状态、错误
Reconstruction differences: none，或确切缺失/变更的行为
```

仅在用户同时审批通过此文件与 `environment.md` 及 `task.md` 后，才可将状态设置为 `Status: approved`。

## 选择 Harbor 运行的目标

优先使用当前代码库中的实际入口点。仅当该入口点无法安全或可复现地运行时，才使用重构版本（reconstruction），并明确指出所做的更改。

```text
Harness: 现有的 `support_agent.run`
Preserved: 提示词、模型设置、工具代码、重试中间件、线程记忆
Adapter: 转换 Harbor 指令/响应并记录观察到的调用
Credentials: 模型 API 密钥及只读工单服务 Token
```

任何修改了提示词、控制流、工具解析、记忆或模型行为的副本均属于重构版本。切勿将其运行结果描述为生产环境智能体的结果。

如果将源代码复制到任务镜像中，请固定版本号（revision）并包含 Harness 所拥有的每个可访问模块。仅对入口点进行哈希校验无法保证一致性。应将日志记录和 Harbor 转换逻辑保留在包装器（wrapper）中，而不是直接修改智能体本身的业务逻辑。

## 保持生产环境接口一致

遵循生产环境边界。将代码库定义的工具行为保留在 Harness 中，并在现有接口之后替换其底层依赖项。

```text
Harness: `search_docs(query)` 工具定义、校验、结果解析、重试逻辑
Environment: 搜索端点、冻结的文档/索引、延迟与错误响应
```

动态提供的 MCP 或 HTTP 工具服务器可以在 Environment 中运行；Harness 仍然负责管理其发现、调用和使用该服务器的方式。如果评测用外观相似的代码替换了代码库定义的工具代码，则必须将该 Harness 标记为重构版本。

## 会话与多轮运行

每次试验（trial）创建一个 Harness 会话。首先发送 `instruction.md`，随后通过同一个会话发送后续的用户消息。切勿预加载未来的轮次。Harness 在返回每个响应之前，可以进行任意次数的模型和工具调用。

关于多轮运行的连接配置，请参阅[模拟参考指南](multi-turn-simulation/guide.md)。

## 记录执行轨迹（Rollout）

Harness 适配器必须实时记录发生的事件：

- 用户与智能体的消息；
- 其直接观察到的模型/工具调用、参数、结果、重试与错误；
- 会话 ID 以及非机密的解析后配置；
- 最终响应与终止原因。

切勿从智能体的文本表述中推断调用。严禁将凭据、隐藏真相（hidden truth）、模拟器指令以及 Verifier（验证器）判定标准暴露给 Harness 可见的输入和产物中。