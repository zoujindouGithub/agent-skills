# Trace 溯源 (Trace Sourcing)

仅当用户提供 Trace 数据源或要求使用 Trace 时，才使用本参考指南。

## 适用范围

Trace 是对代码仓库、测试、Issue 和用户优先级的补充。它们展示的是**实际发生了什么**，而不是**应该发生什么**。发起操作的主体可以是一个人、另一个 Agent、一次 API 调用、一个事件或一个定时任务。

如果用户尚未明确范围，需说明数据源、时间窗口或文件、首批抓取数量、所需字段以及临时存储位置。仅在缺少访问权限或范围不明确时进行询问。将原始导出文件保存在代码仓库外部，并在分析和任务验证后将其删除。切勿打印敏感凭据。

## 检索 Trace

首先从提供的范围内检索最多 25 条完整的 Trace。在可用时检索以下内容：

- 初始输入、上下文以及在多轮对话相关时的完整会话线程（Thread）；
- Agent/模型的交互消息及子运行（Child Runs）；
- 工具调用、参数、结果、顺序、重试和错误；
- 最终输出、状态、反馈或其他结果证据；
- Agent 版本（Revision）及相关配置。

保留 Trace ID 或等效的源标识符。删除重复的导出记录；但保留单条完整 Trace 内部的重试记录。

仅在为了弥补审查过程中发现的具体信息缺失时，才拉取新的一批数据。示例：如果第一批数据中仅包含 `search_docs` 超时，则检索成功的 `search_docs` 调用以了解正常的结果 Schema。不要从小样本批次中推断生产环境的实际发生频率。

## 审查批次

仅记录可观察到的事实：

```text
请求的工作内容:
上下文:
Harness 行为:
依赖项行为:
结果证据:
可能的相关性: Harness、Environment、task、Verifier 或无
```

结果证据可以是用户反馈、最终状态、测试结果或外部状态。缺少结果证据并不等于失败。工具错误并不直接等同于 Harness 错误：重复的相同调用可能表明存在死循环，而服务的 `429` 状态码则属于依赖项行为。

## 总结相关证据

仅对出现且会影响评测（Eval）决策的模式进行归纳：

```text
模式:
观察于: Trace ID
发生了什么:
可能提供的信息/启示:
局限性:
```

不要强行凑成“好/坏”对照组，也不要将每个模式都转化为评测用例。仅当批次数据足以支持对比时，才对成功和失败的行为进行对比分析。

## 在评测中使用 Trace

综合代码仓库、测试、Issue、用户优先级和 Trace 来选择评测方向。某个方向并不一定必须有 Trace 支持。当 Trace 确实对其产生影响时：

- **Harness（测试夹具/驱动框架）：** 保留相关的 Prompt、控制流、工具使用、重试机制和会话行为。
- **Environment（环境）：** 通过生产接口复现相关的 Schema、排序、分页、权限、错误和状态，使用受控数据而非直接复制生产记录。
- **Task（任务）：** 保留考察该能力的前提条件，而非完全照搬生产环境的具体交互。
- **Verifier（验证器）：** 使用独立的真值标准；类似 Trace 中的不良结果可以作为负向校准夹具，但绝不能作为隐藏的参考答案。

运行之后，确认任务确实复现了所引用的条件，且 Verifier 评估的是预期的 Harness 行为，而非依赖项或基础设施的临时异常。

## LangSmith 命令

当用户提供 LangSmith 项目时，请使用官方的 `langsmith` CLI：

```bash
langsmith trace stats --project <project> --last-n-minutes <window>

langsmith trace list \
  --project <project> \
  --limit <metadata-limit> \
  --include-metadata \
  --include-feedback \
  --show-hierarchy

langsmith trace export <temporary-outside-repo-dir> \
  --project <project> \
  --trace-ids <comma-separated-ids> \
  --full
```

确认导出内容包含子模型调用和工具运行记录。使用此数据源需要配置 `LANGSMITH_API_KEY`。