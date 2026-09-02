---
name: langsmith-online-eval-engineering
description: 迭代式检查 trace、访谈用户，并逐个创建 LangSmith 在线评估器（online evaluators）。专门用于在 LangSmith 内部创建在线评估器——Harbor 风格的在线评估请使用 "eval-engineering"。
---

# 在线评估工程 (Online Eval Engineering)

迭代式构建在线评估器：

```text
检查 trace 并访谈用户 -> 提出方向 -> 用户选择
-> 构建评估器 -> 测试、关联、验证 -> 评审并重复
```

在创建或修改评估器之前，请阅读 [references/langsmith-api.md](references/langsmith-api.md)。

## 1. 检查 trace

向用户索取其 LangSmith 项目名称。获取近期的根级别 trace 并输出其结构。阅读 [references/trace-inspection.md](references/trace-inspection.md)。找出：

- run 名称和类型；
- 可用的输入和输出字段名称；
- 数据的形状和内容（截断的样本）；
- 哪些字段包含评估器所需的数据。

在对话中总结 trace 结构：

```text
Project: 名称
Run type: chain | llm | tool | ...
Input fields: 字段名称及其包含的内容
Output fields: 字段名称及其包含的内容
Sample: 一组具有代表性的输入/输出对（截断）
```

保持用户参与：解释 trace 结构及其含义，然后仅询问 trace 无法确定的信息。例如：“这个应用程序是做什么的？”、“最关注哪方面的质量问题？”或“绝对不能发生哪种失败？”

询问用户本次会话中的评估器是否需要命名前缀（例如 `myapp-`、`v2-`、`dogfood-`）。如果用户提供了前缀，请将其应用于所有评估器名称、prompt hub 句柄（handles）和 run rule 显示名称。如果用户拒绝，则使用普通的描述性名称。

在理解 trace 结构且用户描述其关注点之前，切勿提议评估器。

## 2. 讨论并选择评估方向

阅读 [references/evaluator-design.md](references/evaluator-design.md)。根据 trace 数据提出两到三个评估标准。如果用户提供了命名前缀，请应用步骤 1 中的前缀。对于每个方向，提供：

```text
Name: 描述性评估器名称（若设置了前缀则包含前缀）
Type: LLM-as-judge 或 code
Measures: 评估哪一维度的质量
Scoring: bool、float (0-1) 或 int；通过/失败的含义
Fields needed: 使用了哪些 trace 字段以及如何使用
Rationale: 为什么采用这种类型和方法
```

示例：

```text
Name: response-relevance
Type: LLM-as-judge
Measures: 回复是否解答了用户的问题
Scoring: bool；True = 相关，False = 离题或未作答
Fields needed: input（用户问题），output（助手回复）
Rationale: 相关性属于语义范畴，需要阅读理解能力；无法通过代码判定
```

推荐其中一个并询问用户想要构建哪一个。在用户做出选择之前不要进行实现。

## 3. 构建单个评估器

阅读 [references/langsmith-api.md](references/langsmith-api.md)。构建选定的评估器。在执行任何 API 调用之前，向用户展示完整配置并获得批准。

**LLM-as-judge 路径**：定义一个 `ResponseSchema`，将 `reasoning` 置于首位，随后是分数（score）字段。编写带有明确评分标准的 prompt 消息，评估输出结果本身，而不是评估其是否与参考答案匹配。使用在步骤 1 中发现的字段名称设置 `variable_mapping`。展示 Schema、Prompt、变量映射和评估器名称以供批准。获得批准后，推送 Prompt 并创建评估器。汇报评估器 ID。

**代码评估器路径**：编写一个 `perform_eval(run, example=None)` 函数。该函数必须是自包含的（仅使用内置函数和标准库），以字典形式访问 `run`（例如 `run.get("outputs")`），并返回 `{"key": ..., "score": ..., "comment": ...}`。展示函数代码和评估器名称以供批准。获得批准后，创建评估器。汇报评估器 ID。

## 4. 测试、关联与验证

在关联之前，询问用户所需的采样率（1.0 = 针对每条 trace，0.5 = 一半，0.1 = 10%，或自定义）。不要默默使用默认值。如果用户不确定，建议使用 1.0 进行初始测试。

询问用户在关联之前是否希望针对现有的几条 trace 测试评估器。Run rules 仅对新的 trace 生效，因此历史测试是在新流量到来之前进行验证的唯一方法。

对于代码评估器，直接针对获取到的根级别 trace 执行 `perform_eval`，传入包含 `inputs`、`outputs` 和 `attachments` 键的字典。这可以在生产环境运行前捕获运行时错误（错误的字段名、字典与对象属性访问混淆、缺失数据）。对于 LLM 评估器，验证其配置：确认 `variable_mapping` 键与 Prompt 占位符匹配，确认映射的 trace 字段存在，并检查映射的数据是否有意义。

如果测试暴露出错误，请在关联前进行修复并重新创建。如果用户拒绝测试，则直接进行关联。

创建一个 run rule 以将评估器连接到 tracing 项目。将用户的命名前缀应用于 `display_name`。确认评估器已显示在评估器列表中，并正确关联了项目。检查以下内容：

- 评估器关联情况和 run rule 状态；
- 近期的 trace 反馈和分数（来自历史测试或新 trace）；
- 分数是否符合对已检查 trace 的预期；
- 边界情况处理（空输出、报错的 run、异常的数据结构）。

当评估器崩溃、评分不正确或在边界情况下失败时，进行修复并重新关联。在最终确认前，确认评估器评分针对的是预期的质量维度，而不是基础设施或数据格式问题导致的失败。

## 5. 与用户一同评审

说明评估器名称和 ID、质量维度与评分方式、所使用的 trace 字段、采样率以及任何局限性。询问用户是批准、修改、放弃，还是选择下一个方向。如果继续，复用先前的 trace 分析结果，然后提出一个不同的质量维度。

## 不变式规则 (Invariants)

- 每个评估器仅针对一个质量维度。
- 严禁猜测字段名；在实现前务必检查 trace。
- 在发起 API 调用前，展示配置并获取用户批准。
- 代码评估器必须是自包含的：仅使用内置函数和标准库。
- 代码评估器接收到的 `run` 为普通字典；请使用 `run.get("inputs")` 和 `run.get("outputs")`，不要使用属性访问。`example` 参数必须默认为 `None`。
- 将 API 失败、认证错误和 run rule 失败视为基础设施错误，而非评估器代码缺陷。