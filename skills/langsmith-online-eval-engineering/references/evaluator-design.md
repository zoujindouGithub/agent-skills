# 评估器设计 (Evaluator Design)

设计 LangSmith 在线评估器的最佳实践。每个评估器仅关注一个质量维度。

## LLM 评审员 vs 代码评估器：决策框架

| 考量因素 | LLM 评审员 (LLM-as-judge) | 代码评估器 (Code evaluator) |
|---|---|---|
| **适用场景** | 成功标准是主观的或语义层面的 | 成功标准是客观的或确定性的 |
| **示例** | 相关性、实用性、安全性、语气、事实依据 (Grounding) | 输出是否存在、格式验证、长度阈值、JSON 结构、关键词是否存在 |
| **速度** | 较慢（每次追踪都需要 LLM 推理） | 快速（直接执行） |
| **成本** | 每次评估都会消耗 LLM Token 成本 | 无额外成本 |
| **确定性** | 非确定性；不同运行之间可能存在差异 | 完全确定 |

**经验法则：**
- 如果你可以编写一个 Python 表达式来判断通过/失败，请使用代码。
- 如果需要人类去阅读并对输出进行推理思考，请使用 LLM 评审员。
- 拿不准时，先从 LLM 评审员开始——如果后续发现该标准完全是可判定的，随时可以将其替换为代码评估器。

## LLM 评审员最佳实践

### 推理优先模式 (Reasoning-first schema)

始终在 Pydantic 模式中的评分字段之前放置 `reasoning`（推理）字段。这会强制 LLM 在给出评分之前先进行解释，从而提高准确性。

```python
class ResponseSchema(BaseModel):
    reasoning: str = Field(
        description="Step-by-step reasoning for the evaluation." # 评估的分步推理过程。
    )
    score: bool = Field(
        description="Whether the response meets the criterion." # 回复是否符合标准。
    )
```

### 基于事实的评分标准 (Grounded rubrics)

将系统提示词编写为明确的评分标准。评估器应该评估生成的结果本身，而不是评估它是否与参考答案或偏好的流程相匹配。

好的示例：“回复是否使用了所提供上下文中的信息来回答用户的问题？”

差的示例：“回复是否与预期答案一致？”（在线评估中不存在预期答案）

### 单个评估器仅对应一个质量维度

每个评估器应该且仅测量一个质量维度。在单个评估器中组合多个标准（例如：相关性、语气和安全性混在一起）会导致分数难以解释且难以调试。

为不同的关注点创建独立的评估器：
- `relevance-evaluator` -- 回复是否切题？
- `safety-evaluator` -- 回复中是否包含有害内容？
- `tone-evaluator` -- 语气是否适合当前上下文？

### 变量映射 (Variable mapping)

仅映射提示词中实际使用的追踪字段。传递未使用的字段会增加噪声。有关如何发现可用字段，请参阅 [trace-inspection.md](trace-inspection.md)。

### 评分类型

- **布尔值** (`bool`): 通过/失败 -- 最简单，适用于二元判断标准。
- **数值型** (`float`, 0--1): 精细评分 -- 适用于需要部分给分的情况。
- **分类标签** (`str`): 标签分类 -- 适用于结果是一个类别而非分值量表的情况。

使用能够捕获所需区分度的最简单类型。对于在线评估，布尔值通常就足够了。

## 代码评估器最佳实践

### 将 `run` 作为字典访问

`run` 在运行时是一个普通字典，而不是对象。请使用 `run.get("inputs")` 和 `run.get("outputs")` -- 绝不要使用 `run.inputs` 或 `run.outputs`。

如果运行出错，`run.get("outputs")` 可能是 `None`。始终进行检查：

```python
def perform_eval(run, example=None):
    outputs = run.get("outputs")
    if outputs is None:
        return {"key": "my_check", "score": 0, "comment": "No output"}
    # ... 执行评估 ...
```

### 独立自包含 (Self-contained)

代码评估器无法导入外部第三方包。所有逻辑必须在 `perform_eval` 函数体内，仅使用 Python 内置函数和标准库。不能使用 `import numpy`、`import requests`、`import langchain`。

### 描述性键名

返回字典中的 `"key"` 会显示为 LangSmith UI 中的得分名称。请使用具有描述性的、全小写并用下划线分隔的名称：
- `"has_output"` -- 不要使用 `"check1"`
- `"response_length"` -- 不要使用 `"len"`
- `"contains_greeting"` -- 不要使用 `"g"`

### 返回类型

```python
# 布尔值（通过/失败）
return {"key": "has_output", "score": True, "comment": "Output exists"}

# 数值型（0-1 范围）
return {"key": "response_length", "score": 0.75, "comment": "375 of 500 char target"}

# 整数型
return {"key": "word_count", "score": 42, "comment": "42 words in response"}
```

## 反模式 (Anti-patterns)

| 反模式 | 产生的问题 | 修复方案 |
|---|---|---|
| 猜测字段名 | 评估器静默获取到空数据 | 评估前先检查追踪结构 |
| 使用 `run.inputs`（属性访问方式） | 报错 `AttributeError` -- `run` 是一个字典 | 使用 `run.get("inputs")` |
| `def perform_eval(run, example)` 未设置默认值 | 报错 `TypeError` -- 运行时只传递一个参数 | 使用 `example=None` |
| 单个评估器中包含多个评估标准 | 评分模棱两可、含义不清 | 每个评估器仅负责一个质量维度 |
| 对照参考答案进行评分 | 在线评估中不存在参考答案 | 对照评分标准规则进行评分 |
| 在代码评估器中导入外部包 | 运行时错误 (Runtime error) | 仅使用内置函数/标准库 |
| 忽略 `None` 输出 | 当运行出错时程序崩溃崩溃 | 检查 `run.get("outputs") is None` |
| 通用评分键名（`"score"`、`"result"`） | 在 UI 中无法区分 | 使用具有描述性的键名 |
| 在评分之后进行推理 | LLM 会进行事后合理化解释，而非先思考再评分 | 将 `reasoning` 字段放在最前面 |

## 脑内验证清单 (Mental verification checklist)

在部署评估器之前，请在脑海中针对以下三种情况进行验证：

1. **正常追踪 (Good trace)**：智能体表现良好的运行。评估器是否给出了及格/通过分数？
2. **异常追踪 (Bad trace)**：在目标质量维度上存在明显失败的运行。评估器是否给出了不及格/失败分数？
3. **边界情况 (Edge case)**：缺少输出、输入为空或结构异常的运行。评估器能否正常处理且不崩溃？

如果任何一种情况产生了意外结果，请在部署前修改评估器。