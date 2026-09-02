# 任务设计 (Task Design)

设计一个能够使所选能力成为必不可少的请求。

## 编写 `task.md`

在实现之前，编写 `evals/<task-id>/task.md`：

```text
Status: draft | approved
Capability: 正在衡量的行为
Request: 稍后放入 Harbor 的 instruction.md 中的确切指令
Initial conditions: 可用的信息、权限和状态
Why this requires the capability: 该任务排除了哪些捷径
Pass iff: 独立可观察的成功结果
Verifier: LLM 评判器、确定性检查或两者兼有
Verifier evidence: 确切来源、轨迹字段或初始/最终状态
Prohibited effects: 绝不能发生的最终变更
Agent-visible information: Harness 可以使用的请求、工具结果、文件和状态
Accepted alternatives: 实质上等效的成功结果
```

`task.md` 是控制平面的审查规范，而不是 Harness 的输入。仅在用户将其与 `harness.md` 和 `environment.md` 一同批准后，才设置 `Status: approved`。

## 契约 (The Contract)

在实现之前定义以下内容：

~~~text
Capability: 正在衡量的行为
Request: 发送给 Harness 的具体指令
Initial conditions: 可用的信息、权限和状态
Required outcome: 独立可观察的成功
Prohibited effects: 绝不能发生的最终变更
Accepted alternatives: 实质上等效的成功结果
Agent-visible information: Harness 可以使用的请求、工具结果、文件和状态
~~~

在以下情况下予以驳回：Harness 可以在不具备该能力的情况下成功、缺少必要信息、成功标准模棱两可，或者通过条件依赖于 Harness 无法推断出的信息。

当任务参考了真实调用追踪（trace）时，应保留需要该能力的前提条件，而非保留生产环境的原样措辞或记录。例如：使用合成账户重新复现“查询返回了两个同名账户并需要进行消除歧义”这一场景。

将其与现有的评测进行比对。如果某个用例仅仅更改了名称、措辞或测试固件（fixtures），请予以驳回。只有当新用例引入了不同的障碍、状态、证据条件或失败模式时，重用某项能力才具有价值。

## 评判证据 (Judge Evidence)

独立于 Harness 的回答来选择证据。参考答案仅在来自独立源材料时才有效：

| 领域 | 证据 |
|---|---|
| 编码 (Coding) | 失败用例以及行为和回归测试 |
| 搜索 / 问答 (Search / Q&A) | 支持或反驳该回答的固定来源记录 |
| 分析 (Analysis) | 根据提供的原始数据独立重新计算得出的结果 |
| 工具使用 (Tool use) | 环境观察到的结果/状态；仅当最终状态无法确立要求时，才使用 Harness 记录的调用 |
| 有状态操作 (Stateful action) | 初始状态、策略/权限、最终状态以及允许的变更 |

如果评判器无法根据这些证据判断是否成功，请在编写评分标准（rubric）之前修改问题或环境。

## 示例

| 领域 | 能力 | 问题形态 | 最小环境 |
|---|---|---|---|
| 编码 | 无回归修复 | 复现并修复特定故障 | 仓库、失败用例、可运行的测试 |
| 搜索 / 问答 | 基于证据的综合 | 回答需要结合多个来源的问题 | 包含相关记录和干扰记录的可搜索语料库 |
| 分析 | 基于数据正确推理 | 计算并解释与决策相关的结果 | 原始数据、定义、相关边缘用例 |
| 工具使用 | 选择并使用正确的工具 | 在存在竞争工具的情况下完成请求 | 逼真的工具接口、结果和错误 |
| 有状态操作 | 执行安全变更 | 在保持约束的同时更新请求的状态 | 已知的初始状态、权限、可观察的最终状态 |

## 规则

- 将任务放置在 `evals/<task-id>/` 下。
- 仅包含此能力所需的上下文。
- 切勿暴露预期的结论或验证器标准。
- 除非其本身就是能力的一部分，否则切勿规定工具序列、文件、措辞或具体实现方式。
- 当请求的最终结果足以确立成功时，切勿对工具、子 Agent、重试次数或更新的确切次数做强制要求。
- 允许实质上等效的有效解决方案。
- 可变任务应从已知状态开始，并在每次运行后重置。