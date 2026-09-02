# Trace 检查

如何探查 Trace 字段名称，以便在评估器的 `variable_mapping`（LLM 评估器）以及 `run.inputs`/`run.outputs`（代码评估器）中使用。

在构建评估器之前，务必先检查 Trace。切勿猜测字段名称。

## 操作流程

1. 向用户询问其 LangSmith 项目名称。
2. 获取 3–5 条最近的 Trace：

```python
from langsmith import Client

client = Client()
runs = list(client.list_runs(project_name="<project>", limit=5))
```

3. 针对每个 Run，打印以下内容：
   - `run.name` —— Run 名称（通常是链或 Agent 的类名）
   - `run.run_type` —— `chain`、`llm`、`tool`、`retriever` 等
   - `list(run.inputs.keys())` —— 可用的输入字段名称
   - `list(run.outputs.keys())` —— 可用的输出字段名称
   - `run.inputs` 和 `run.outputs` 的截断样本（限制在约 2000 个字符以内）

4. 确定哪些字段包含了评估器所需的数据。

## 常见字段名模式

### 聊天机器人 / 对话型 Agent

```
inputs:  {"input": "user message"}      或  {"messages": [...]}
outputs: {"output": "assistant reply"}  或  {"messages": [...]}
```

典型的 `variable_mapping`：`{"input": "input", "output": "output"}`

### RAG / 检索链

```
inputs:  {"input": "user question", "chat_history": [...]}
outputs: {"output": "answer", "context": [...]}
```

上下文可能以 `"context"`、`"documents"` 或 `"source_documents"` 的形式出现。请检查实际的键名。

### 工具调用型 Agent

```
inputs:  {"input": "user request"}
outputs: {"output": "final answer"}
```

工具调用会出现在子 Run 中，而不是顶层 Run 的 inputs/outputs 中。顶层 Run 仍然使用 `input` 和 `output` 来表示面向用户的请求和响应。

### 自定义链

字段名取决于链的具体实现。不存在通用的 Schema —— 这也是为什么必须进行检查的原因。

## 将字段映射到评估器

### LLM 评估器：`variable_mapping`

`variable_mapping` 用于将 Prompt 模板变量连接到顶层 Trace 字段。仅支持顶层字段。

```python
# 如果 Prompt 模板使用了 {question} 和 {answer}：
VARIABLE_MAPPING = {
    "question": "input",    # 模板变量 -> Trace 字段
    "answer": "output",
}
```

模板变量必须与 Prompt 消息中的 `{placeholders}` 相匹配。Trace 字段的值必须与 `run.inputs` 或 `run.outputs` 中的键匹配。

### 代码评估器：`run["inputs"]` 和 `run["outputs"]`

代码评估器通过 `run` 字典访问 Trace 数据：

```python
def perform_eval(run, example=None):
    inputs = run.get("inputs") or {}
    outputs = run.get("outputs") or {}
    user_input = inputs.get("input", "")
    agent_output = outputs.get("output", "")
    # ... 执行评估 ...
```

在运行时 `run` 是一个普通字典 —— 请使用 `run.get("inputs")`，而不是 `run.inputs`。务必使用带有默认值的 `.get()`，并针对 `None` 输出做好防护处理。

## 处理异常情况

### 嵌套结构

某些 Trace 会将数据嵌套在包装键内：

```
inputs: {"input": {"question": "...", "context": "..."}}
```

对于 LLM 评估器，`variable_mapping` 仅映射到顶层键。如果数据是嵌套的，可以采取以下任一做法：
- 映射到顶层键并在 Prompt 中处理嵌套结构
- 改用能够遍历嵌套字典的代码评估器

### Schema 不一致

如果多个链类型写入同一个项目，同一项目中的不同 Run 可能会具有不同的字段名。请检查多条 Trace 以找出通用模式。如果 Schema 各不相同，带有防御性 `.get()` 调用的代码评估器会比带有固定 `variable_mapping` 的 LLM 评估器更加健壮。

### 缺失输出

发生错误的 Run，其 `run["outputs"]` 可能被设置为 `None`。代码评估器必须处理这种情况：

```python
def perform_eval(run, example=None):
    outputs = run.get("outputs")
    if outputs is None:
        return {"key": "my_check", "score": 0, "comment": "No output (run may have errored)"}
    # ... 正常评估流程 ...
```

当 Trace 字段缺失时，LLM 评估器的映射字段将接收到一个空字符串。