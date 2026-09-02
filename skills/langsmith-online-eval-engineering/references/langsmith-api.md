# LangSmith 在线评估器 API 参考

用于创建和管理 LangSmith 在线评估器的有效代码模式。所有代码片段均派生自 [online-evals](https://github.com/langchain-ai/langchain-skills) 参考脚本，并在 `langsmith >= 0.9.8` 版本下测试通过。

## 安装与配置

```python
from langsmith import Client

client = Client()  # 使用环境变量中的 LANGSMITH_API_KEY
```

必需的环境变量：

```
LANGSMITH_API_KEY=lsv2_pt_...
LANGSMITH_ENDPOINT=https://api.smith.langchain.com   # 可选，此为默认值
```

## 检查追踪（Traces）

追踪检查使用同步 SDK 方法。在构建评估器之前，可以使用此方法来发现字段名称。

```python
import json
from langsmith import Client

client = Client()
runs = list(client.list_runs(project_name="my-project", limit=5))

for i, run in enumerate(runs):
    print(f"--- Run {i + 1} (id: {run.id}) ---")
    print(f"Name: {run.name}")
    print(f"Run type: {run.run_type}")
    print(f"Input keys: {list(run.inputs.keys()) if run.inputs else 'None'}")
    print(f"Inputs: {json.dumps(run.inputs, indent=2, default=str)[:2000]}")
    print(f"Output keys: {list(run.outputs.keys()) if run.outputs else 'None'}")
    print(f"Outputs: {json.dumps(run.outputs, indent=2, default=str)[:2000]}")
```

每个 run 对象都暴露以下属性：`.id`、`.name`、`.run_type`、`.inputs`（dict）、`.outputs`（dict）。

## 创建 LLM 评审评估器（LLM-as-judge）

LLM 评估器使用推送到 LangSmith Prompt Hub 的结构化提示词。所有评估器操作均为异步。

### 1. 定义响应 Schema

```python
from pydantic import BaseModel, Field

class ResponseSchema(BaseModel):
    reasoning: str = Field(
        description="Step-by-step reasoning for the evaluation."
    )
    score: bool = Field(
        description="Whether the response meets the criterion."
    )
```

将 `reasoning` 放在最前面，以便 LLM 在打分前先输出推理过程。

### 2. 构建并推送提示词

```python
from langchain_core.prompts.structured import StructuredPrompt

PROMPT_MESSAGES = [
    ("system", "Evaluate the following response against the criterion: ..."),
    (
        "human",
        "User question: {input}\n\nAssistant response: {output}",
    ),
]

prompt = StructuredPrompt.from_messages_and_schema(
    PROMPT_MESSAGES,
    schema=ResponseSchema.model_json_schema(),
)

url = client.push_prompt("my-evaluator", object=prompt)
```

### 3. 创建评估器

```python
import asyncio

async def create_llm_evaluator():
    created = await client.evaluators.create(
        name="my-evaluator",
        type="llm",
        llm_evaluator={
            "prompt_repo_handle": "my-evaluator",
            "commit_hash_or_tag": "latest",
            "variable_mapping": {
                "input": "input",
                "output": "output",
            },
        },
    )
    return created.evaluator.id

evaluator_id = asyncio.run(create_llm_evaluator())
```

### 变量映射（Variable mapping）

`variable_mapping` 将提示词模板变量连接到顶层追踪字段。键为模板变量名（在提示词中显示为 `{name}`），值为追踪字段路径。

常见映射：

| 模板变量 | 追踪字段 | 说明 |
|---|---|---|
| `input` | `input` | 顶层 `run.inputs` |
| `output` | `output` | 顶层 `run.outputs` |

可使用上方的追踪检查方法来发现可用字段。

## 创建代码评估器

代码评估器针对每个追踪直接运行一个 Python 函数。该函数必须自包含（不能包含外部导入）。

### 函数签名

```python
def perform_eval(run, example=None):
    """
    参数：
        run: 包含键 "inputs" (dict)、"outputs" (dict)、"attachments" 的字典
        example: 在线评估器为 None（仅在数据集评估中设置）

    返回：
        包含以下键的字典：
            "key": str       -- 评估器标识符
            "score": value   -- bool、int 或 float
            "comment": str   -- 可选的解释说明
    """
```

> **重要提示：** 需要注意两个运行时限制：
> 1. `example` 的默认值必须为 `None`。在线评估器运行时调用 `perform_eval(run)` 时仅传入单个参数 —— `example` 仅在数据集评估器中传递。
> 2. `run` 是一个普通 **dict**，而非对象。请使用 `run.get("inputs")` 和 `run.get("outputs")` —— 不要使用 `run.inputs` 或 `run.outputs`。属性访问会引发 `AttributeError`。

### 示例：检查输出是否存在

```python
import textwrap

EVALUATOR_CODE = textwrap.dedent("""\
    def perform_eval(run, example=None):
        \"\"\"Check whether the run produced any output.\"\"\"
        outputs = run.get("outputs")
        has_output = (
            outputs is not None
            and len(outputs) > 0
        )
        return {
            "key": "has_output",
            "score": bool(has_output),
            "comment": "Run produced output" if has_output else "Run had no output",
        }
""")
```

### 创建评估器

```python
async def create_code_evaluator():
    created = await client.evaluators.create(
        name="has-output",
        type="code",
        code_evaluator={
            "code": EVALUATOR_CODE,
            "language": "python",
        },
    )
    return created.evaluator.id

evaluator_id = asyncio.run(create_code_evaluator())
```

## 将评估器附加到项目（运行规则 / run rules）

运行规则（Run rules）用于将评估器连接到追踪项目。SDK 没有专门的 run-rules 包装器，因此需使用 `httpx` 调用 REST API。

```python
import os
import httpx
from langsmith import Client

client = Client()
api_key = os.environ["LANGSMITH_API_KEY"]
endpoint = os.environ.get("LANGSMITH_ENDPOINT", "https://api.smith.langchain.com")

# 查询项目 ID
project = client.read_project(project_name="my-project")

# 创建运行规则
resp = httpx.post(
    f"{endpoint}/api/v1/runs/rules",
    headers={"x-api-key": api_key},
    json={
        "display_name": f"eval-{project.name}",
        "session_id": str(project.id),
        "sampling_rate": 1.0,        # 1.0 = 评估所有追踪, 0.1 = 10%
        "evaluator_id": EVALUATOR_ID,
        "is_enabled": True,
    },
    timeout=30,
)
resp.raise_for_status()

rule = resp.json()
print(f"Run rule created -> {rule['id']}")
```

### 请求载荷参考

| 字段 | 类型 | 说明 |
|---|---|---|
| `display_name` | str | 在 UI 中显示的人类可读标签 |
| `session_id` | str (UUID) | 项目 ID（来自 `client.read_project`） |
| `sampling_rate` | float | 0.0--1.0；要评估的追踪比例 |
| `evaluator_id` | str (UUID) | 来自创建步骤的评估器 ID |
| `is_enabled` | bool | 规则是否处于激活状态 |

## 列出、更新和删除评估器

### 列出所有评估器

```python
async def list_evaluators():
    result = await client.evaluators.list()
    for ev in result.evaluators:
        projects = ""
        if ev.run_rules:
            projects = ", ".join(
                r.session_name or str(r.session_id)
                for r in ev.run_rules
                if r.session_id
            )
        print(f"{ev.name:<30} {str(ev.id):<38} {ev.type:<6} {projects}")

asyncio.run(list_evaluators())
```

> **注意：** 分页结果对象使用 `.evaluators` 来访问评估器对象列表。某些较旧的示例可能会使用 `.data` —— 在最近的 SDK 版本中该属性已被重命名。

### 更新评估器

```python
async def update_evaluator():
    updated = await client.evaluators.update(
        evaluator_id=EVALUATOR_ID,
        name="renamed-evaluator",
    )
    print("Updated ->", updated.evaluator.id)

asyncio.run(update_evaluator())
```

### 删除评估器

```python
async def delete_evaluator():
    await client.evaluators.delete(
        evaluator_id=EVALUATOR_ID,
        delete_run_rules=True,  # 同时移除附加的运行规则
    )
    print("Deleted ->", EVALUATOR_ID)

asyncio.run(delete_evaluator())
```

## 异步模式

- **评估器操作**（`create`、`list`、`update`、`delete`）是异步的 —— 在异步上下文中使用 `asyncio.run()` 或 `await`。
- **追踪检查**（`client.list_runs`）和**项目查询**（`client.read_project`）是同步的。
- **运行规则**使用 `httpx`（同步 POST）。
- `client.push_prompt` 是同步的。