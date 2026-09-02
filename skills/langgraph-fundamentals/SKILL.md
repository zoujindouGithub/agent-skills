---
name: langgraph-fundamentals
description: "编写任何 LangGraph 代码时请调用此技能。涵盖 StateGraph、状态模式 (State Schemas)、节点 (Nodes)、边 (Edges)、Command、Send、invoke、流式传输 (Streaming) 以及错误处理。"
---

<overview>
LangGraph 将 Agent 工作流建模为**有向图**：

- **StateGraph**：构建有状态图的主类
- **Nodes（节点）**：执行任务并更新状态的函数
- **Edges（边）**：定义执行顺序（静态或条件式）
- **START/END**：标记入口和退出点的特殊节点
- **带 Reducer 的 State**：控制状态更新的合并方式

图在执行前必须先进行 `compile()`。
</overview>

<design-methodology>

### 设计 LangGraph 应用程序

构建新图时，请遵循以下 5 个步骤：

1. **梳理离散步骤** —— 绘制工作流的流程图。每个步骤都将成为一个节点。
2. **明确每个步骤的职责** —— 划分节点类型：LLM 步骤、数据步骤、动作步骤或用户输入步骤。针对每个步骤，确定其静态上下文（Prompt）、动态上下文（来自 State）、重试策略以及预期结果。
3. **设计状态 (State)** —— 状态是所有节点共享的内存。存储原始数据，并在节点内按需格式化 Prompt。
4. **构建节点** —— 将每个步骤实现为一个接收状态并返回部分更新的函数。
5. **串联成图** —— 用边连接节点，添加条件路由，并在需要时配合 checkpointer 进行编译。

</design-methodology>

<when-to-use-langgraph>

| 适合使用 LangGraph 的场景 | 适合使用替代方案的场景 |
|---|---|
| 需要对 Agent 编排进行细粒度控制 | 快速原型开发 → LangChain agents |
| 构建包含分支/循环的复杂工作流 | 简单的无状态工作流 → 直接使用 LangChain |
| 需要人机协作 (Human-in-the-loop)、持久化存储 | 开箱即用型功能特性 → Deep Agents |

</when-to-use-langgraph>

---

## 状态管理 (State Management)

<state-update-strategies>

| 需求 | 解决方案 | 示例 |
|---|---|---|
| 覆盖原有值 | 无 Reducer（默认） | 简单字段，如计数器 |
| 追加到列表 | Reducer (`operator.add` / `concat`) | 消息历史、日志 |
| 自定义逻辑 | 自定义 Reducer 函数 | 复杂合并逻辑 |

</state-update-strategies>

<ex-state-with-reducer>
<python>
定义包含 Reducer 的状态模式，用于累加列表和对整数求和。

```python
from typing_extensions import TypedDict, Annotated
import operator

class State(TypedDict):
    name: str  # 默认：更新时直接覆盖
    messages: Annotated[list, operator.add]  # 追加到列表中
    total: Annotated[int, operator.add]  # 整数求和累加
```
</python>
<typescript>
使用带有 `ReducedValue` 的 `StateSchema` 来累积数组。

```typescript
import { StateSchema, ReducedValue, MessagesValue } from "@langchain/langgraph";
import { z } from "zod";

const State = new StateSchema({
  name: z.string(),  // 默认：直接覆盖
  messages: MessagesValue,  // 用于消息的内置类型
  items: new ReducedValue(
    z.array(z.string()).default(() => []),
    { reducer: (current, update) => current.concat(update) }
  ),
});
```
</typescript>
</ex-state-with-reducer>

<fix-forgot-reducer-for-list>
<python>
若不使用 Reducer，返回列表将直接覆盖先前的值。

```python
# 错误写法：列表将被覆盖 (OVERWRITTEN)
class State(TypedDict):
    messages: list  # 没有 Reducer！

# 节点 1 返回：{"messages": ["A"]}
# 节点 2 返回：{"messages": ["B"]}
# 最终结果：{"messages": ["B"]}  # "A" 丢失了！

# 正确写法：使用带有 operator.add 的 Annotated
from typing import Annotated
import operator

class State(TypedDict):
    messages: Annotated[list, operator.add]
# 最终结果：{"messages": ["A", "B"]}
```
</python>
<typescript>
若不使用 `ReducedValue`，数组会被覆盖而不是追加。

```typescript
// 错误写法：数组将被覆盖
const State = new StateSchema({
  items: z.array(z.string()),  // 没有 Reducer！
});
// 节点 1：{ items: ["A"] }，节点 2：{ items: ["B"] }
// 最终结果：{ items: ["B"] }  // A 丢失了！

// 正确写法：使用 ReducedValue
const State = new StateSchema({
  items: new ReducedValue(
    z.array(z.string()).default(() => []),
    { reducer: (current, update) => current.concat(update) }
  ),
});
// 最终结果：{ items: ["A", "B"] }
```
</typescript>
</fix-forgot-reducer-for-list>

<fix-state-must-return-dict>
<python>
节点必须返回部分更新 (partial updates)，而不是直接修改并返回完整状态。

```python
# 错误写法：返回整个状态对象
def my_node(state: State) -> State:
    state["field"] = "updated"
    return state  # 切勿直接修改并返回！

# 正确写法：仅返回包含更新项的字典
def my_node(state: State) -> dict:
    return {"field": "updated"}
```
</python>
<typescript>
仅返回部分更新，不要返回完整的状态对象。

```typescript
// 错误写法：返回整个状态
const myNode = async (state: typeof State.State) => {
  state.field = "updated";
  return state;  // 切勿这样做！
};

// 正确写法：返回部分更新
const myNode = async (state: typeof State.State) => {
  return { field: "updated" };
};
```
</typescript>
</fix-state-must-return-dict>

---

## 节点 (Nodes)

<node-function-signatures>

节点函数支持接收以下参数：

<python>

| 签名 | 适用场景 |
|---|---|
| `def node(state: State)` | 仅需访问状态的简单节点 |
| `def node(state: State, config: RunnableConfig)` | 需要 `thread_id`、标签 (tags) 或可配置参数 |
| `def node(state: State, runtime: Runtime[Context])` | 需要运行时上下文、store 或 `stream_writer` |

```python
from langchain_core.runnables import RunnableConfig
from langgraph.runtime import Runtime

def plain_node(state: State):
    return {"results": "done"}

def node_with_config(state: State, config: RunnableConfig):
    thread_id = config["configurable"]["thread_id"]
    return {"results": f"Thread: {thread_id}"}

def node_with_runtime(state: State, runtime: Runtime[Context]):
    user_id = runtime.context.user_id
    return {"results": f"User: {user_id}"}
```
</python>
<typescript>

| 签名 | 适用场景 |
|---|---|
| `(state) => {...}` | 仅需访问状态的简单节点 |
| `(state, config) => {...}` | 需要 `thread_id`、标签 (tags) 或可配置参数 |

```typescript
import { GraphNode, StateSchema } from "@langchain/langgraph";

const plainNode: GraphNode<typeof State> = (state) => {
  return { results: "done" };
};

const nodeWithConfig: GraphNode<typeof State> = (state, config) => {
  const threadId = config?.configurable?.thread_id;
  return { results: `Thread: ${threadId}` };
};
```
</typescript>

</node-function-signatures>

---

## 边 (Edges)

<edge-type-selection>

| 需求 | 边类型 | 适用场景 |
|---|---|---|
| 始终流向同一节点 | `add_edge()` | 固定、确定性的流程 |
| 基于状态进行路由 | `add_conditional_edges()` | 动态分支 |
| 同时更新状态并路由 | `Command` | 在单个节点内合并逻辑 |
| 扇出到多个节点 | `Send` | 带有动态输入的并行处理 |

</edge-type-selection>

<ex-basic-graph>
<python>
包含线性边的简单双节点图。

```python
from langgraph.graph import StateGraph, START, END
from typing_extensions import TypedDict

class State(TypedDict):
    input: str
    output: str

def process_input(state: State) -> dict:
    return {"output": f"Processed: {state['input']}"}

def finalize(state: State) -> dict:
    return {"output": state["output"].upper()}

graph = (
    StateGraph(State)
    .add_node("process", process_input)
    .add_node("finalize", finalize)
    .add_edge(START, "process")
    .add_edge("process", "finalize")
    .add_edge("finalize", END)
    .compile()
)

result = graph.invoke({"input": "hello"})
print(result["output"])  # "PROCESSED: HELLO"
```
</python>
<typescript>
使用 `addEdge` 串联节点，并在调用前进行编译。

```typescript
import { StateGraph, StateSchema, START, END } from "@langchain/langgraph";
import { z } from "zod";

const State = new StateSchema({
  input: z.string(),
  output: z.string().default(""),
});

const processInput = async (state: typeof State.State) => {
  return { output: `Processed: ${state.input}` };
};

const finalize = async (state: typeof State.State) => {
  return { output: state.output.toUpperCase() };
};

const graph = new StateGraph(State)
  .addNode("process", processInput)
  .addNode("finalize", finalize)
  .addEdge(START, "process")
  .addEdge("process", "finalize")
  .addEdge("finalize", END)
  .compile();

const result = await graph.invoke({ input: "hello" });
console.log(result.output);  // "PROCESSED: HELLO"
```
</typescript>
</ex-basic-graph>

<ex-conditional-edges>
<python>
使用条件边根据状态路由到不同的节点。

```python
from typing import Literal
from langgraph.graph import StateGraph, START, END

class State(TypedDict):
    query: str
    route: str
    result: str

def classify(state: State) -> dict:
    if "weather" in state["query"].lower():
        return {"route": "weather"}
    return {"route": "general"}

def route_query(state: State) -> Literal["weather", "general"]:
    return state["route"]

graph = (
    StateGraph(State)
    .add_node("classify", classify)
    .add_node("weather", lambda s: {"result": "Sunny, 72F"})
    .add_node("general", lambda s: {"result": "General response"})
    .add_edge(START, "classify")
    .add_conditional_edges("classify", route_query, ["weather", "general"])
    .add_edge("weather", END)
    .add_edge("general", END)
    .compile()
)
```
</python>
<typescript>
`addConditionalEdges` 根据函数的返回值进行路由。

```typescript
import { StateGraph, StateSchema, START, END } from "@langchain/langgraph";
import { z } from "zod";

const State = new StateSchema({
  query: z.string(),
  route: z.string().default(""),
  result: z.string().default(""),
});

const classify = async (state: typeof State.State) => {
  if (state.query.toLowerCase().includes("weather")) {
    return { route: "weather" };
  }
  return { route: "general" };
};

const routeQuery = (state: typeof State.State) => state.route;

const graph = new StateGraph(State)
  .addNode("classify", classify)
  .addNode("weather", async () => ({ result: "Sunny, 72F" }))
  .addNode("general", async () => ({ result: "General response" }))
  .addEdge(START, "classify")
  .addConditionalEdges("classify", routeQuery, ["weather", "general"])
  .addEdge("weather", END)
  .addEdge("general", END)
  .compile();
```
</typescript>
</ex-conditional-edges>

---

## Command

`Command` 将状态更新和路由逻辑整合在单个返回值中。字段说明：
- **`update`**：要应用的状态更新（类似于从节点返回字典）
- **`goto`**：下一步要跳转的目标节点名称（可为单个或多个）
- **`resume`**：在 `interrupt()` 之后恢复执行时传入的值 —— 参见人机协作 (HITL) 技能

<ex-command-state-and-routing>
<python>
通过 `Command`，可以在单次返回中同时更新状态并指定下一个节点。

```python
from langgraph.types import Command
from typing import Literal

class State(TypedDict):
    count: int
    result: str

def node_a(state: State) -> Command[Literal["node_b", "node_c"]]:
    """在单次返回中更新状态并决定下一个跳转的节点。"""
    new_count = state["count"] + 1
    if new_count > 5:
        return Command(update={"count": new_count}, goto="node_c")
    return Command(update={"count": new_count}, goto="node_b")

graph = (
    StateGraph(State)
    .add_node("node_a", node_a)
    .add_node("node_b", lambda s: {"result": "B"})
    .add_node("node_c", lambda s: {"result": "C"})
    .add_edge(START, "node_a")
    .add_edge("node_b", END)
    .add_edge("node_c", END)
    .compile()
)
```
</python>
<typescript>
返回带有 `update` 和 `goto` 的 `Command`，将状态更改与路由整合在一起。

```typescript
import { StateGraph, StateSchema, START, END, Command } from "@langchain/langgraph";
import { z } from "zod";

const State = new StateSchema({
  count: z.number().default(0),
  result: z.string().default(""),
});

const nodeA = async (state: typeof State.State) => {
  const newCount = state.count + 1;
  if (newCount > 5) {
    return new Command({ update: { count: newCount }, goto: "node_c" });
  }
  return new Command({ update: { count: newCount }, goto: "node_b" });
};

const graph = new StateGraph(State)
  .addNode("node_a", nodeA, { ends: ["node_b", "node_c"] })
  .addNode("node_b", async () => ({ result: "B" }))
  .addNode("node_c", async () => ({ result: "C" }))
  .addEdge(START, "node_a")
  .addEdge("node_b", END)
  .addEdge("node_c", END)
  .compile();
```
</typescript>
</ex-command-state-and-routing>

<command-return-type-annotations>

**Python**：使用 `Command[Literal["node_a", "node_b"]]` 作为返回类型注解，以声明合法的 `goto` 跳转目标。

**TypeScript**：将 `{ ends: ["node_a", "node_b"] }` 作为第三个参数传给 `addNode`，以声明合法的 `goto` 跳转目标。

</command-return-type-annotations>

<warning-command-static-edges>

**警告**：`Command` 仅添加**动态**边 —— 使用 `add_edge` / `addEdge` 定义的静态边仍会照常执行。如果 `node_a` 返回了 `Command(goto="node_c")`，同时图中存在 `graph.add_edge("node_a", "node_b")`，那么 `node_b` 和 `node_c` **都会**被执行。

</warning-command-static-edges>

---

## Send API

使用 `Send` 实现扇出 (Fan-out)：从条件边返回 `[Send("worker", {...})]` 以派生并行 Worker。这要求在结果字段上配置 Reducer。

<ex-orchestrator-worker>
<python>
使用 Send API 将任务分发给并行 Worker 并聚合结果。

```python
from langgraph.types import Send
from typing import Annotated
import operator

class OrchestratorState(TypedDict):
    tasks: list[str]
    results: Annotated[list, operator.add]
    summary: str

def orchestrator(state: OrchestratorState):
    """将任务分发给 Worker。"""
    return [Send("worker", {"task": task}) for task in state["tasks"]]

def worker(state: dict) -> dict:
    return {"results": [f"Completed: {state['task']}"]}

def synthesize(state: OrchestratorState) -> dict:
    return {"summary": f"Processed {len(state['results'])} tasks"}

graph = (
    StateGraph(OrchestratorState)
    .add_node("worker", worker)
    .add_node("synthesize", synthesize)
    .add_conditional_edges(START, orchestrator, ["worker"])
    .add_edge("worker", "synthesize")
    .add_edge("synthesize", END)
    .compile()
)

result = graph.invoke({"tasks": ["Task A", "Task B", "Task C"]})
```
</python>
<typescript>
使用 Send API 将任务分发给并行 Worker 并聚合结果。

```typescript
import { Send, StateGraph, StateSchema, ReducedValue, START, END } from "@langchain/langgraph";
import { z } from "zod";

const State = new StateSchema({
  tasks: z.array(z.string()),
  results: new ReducedValue(
    z.array(z.string()).default(() => []),
    { reducer: (curr, upd) => curr.concat(upd) }
  ),
  summary: z.string().default(""),
});

const orchestrator = (state: typeof State.State) => {
  return state.tasks.map((task) => new Send("worker", { task }));
};

const worker = async (state: { task: string }) => {
  return { results: [`Completed: ${state.task}`] };
};

const synthesize = async (state: typeof State.State) => {
  return { summary: `Processed ${state.results.length} tasks` };
};

const graph = new StateGraph(State)
  .addNode("worker", worker)
  .addNode("synthesize", synthesize)
  .addConditionalEdges(START, orchestrator, ["worker"])
  .addEdge("worker", "synthesize")
  .addEdge("synthesize", END)
  .compile();
```
</typescript>
</ex-orchestrator-worker>

<fix-send-accumulator>
<python>
使用 Reducer 聚合并行 Worker 的结果（否则最后一个 Worker 会覆盖其他 Worker 的结果）。

```python
# 错误写法：没有 Reducer - 最后一个 Worker 会覆盖其他结果
class State(TypedDict):
    results: list

# 正确写法
class State(TypedDict):
    results: Annotated[list, operator.add]  # 自动累加聚合
```
</python>
<typescript>
使用 `ReducedValue` 聚合并行 Worker 的结果。

```typescript
// 错误写法：没有 Reducer
const State = new StateSchema({ results: z.array(z.string()) });

// 正确写法
const State = new StateSchema({
  results: new ReducedValue(z.array(z.string()).default(() => []), { reducer: (curr, upd) => curr.concat(upd) }),
});
```
</typescript>
</fix-send-accumulator>

---

## 运行图：Invoke 与 Stream

<invoke-basics>

调用 `graph.invoke(input, config)` 会运行图直到执行完毕，并返回最终状态。

<python>

```python
result = graph.invoke({"input": "hello"})
# 携带 config 配置（用于持久化、标签等）
result = graph.invoke({"input": "hello"}, {"configurable": {"thread_id": "1"}})
```
</python>
<typescript>

```typescript
const result = await graph.invoke({ input: "hello" });
// 携带 config 配置
const result = await graph.invoke({ input: "hello" }, { configurable: { thread_id: "1" } });
```
</typescript>

</invoke-basics>

<stream-mode-selection>

| 模式 | 流式传输内容 | 适用场景 |
|---|---|---|
| `values` | 每一步执行后的完整状态 | 监控完整状态 |
| `updates` | 状态增量变更 (deltas) | 追踪增量更新 |
| `messages` | LLM Token 与元数据 | 聊天 UI 界面 |
| `custom` | 用户自定义数据 | 进度指示器 |

</stream-mode-selection>

<ex-stream-llm-tokens>
<python>
实时流式传输 LLM Token，以便在聊天 UI 中展示。

```python
for chunk in graph.stream(
    {"messages": [HumanMessage("Hello")]},
    stream_mode="messages"
):
    token, metadata = chunk
    if hasattr(token, "content"):
        print(token.content, end="", flush=True)
```
</python>
<typescript>
实时流式传输 LLM Token，以便在聊天 UI 中展示。

```typescript
for await (const chunk of graph.stream(
  { messages: [new HumanMessage("Hello")] },
  { streamMode: "messages" }
)) {
  const [token, metadata] = chunk;
  if (token.content) {
    process.stdout.write(token.content);
  }
}
```
</typescript>
</ex-stream-llm-tokens>

<ex-stream-custom-data>
<python>
在节点内使用 Stream Writer 发送自定义进度更新。

```python
from langgraph.config import get_stream_writer

def my_node(state):
    writer = get_stream_writer()
    writer("Processing step 1...")
    # 执行任务
    writer("Complete!")
    return {"result": "done"}

for chunk in graph.stream({"data": "test"}, stream_mode="custom"):
    print(chunk)
```
</python>
<typescript>
在节点内使用 Stream Writer 发送自定义进度更新。

```typescript
import { getWriter } from "@langchain/langgraph";

const myNode = async (state: typeof State.State) => {
  const writer = getWriter();
  writer("Processing step 1...");
  // 执行任务
  writer("Complete!");
  return { result: "done" };
};

for await (const chunk of graph.stream({ data: "test" }, { streamMode: "custom" })) {
  console.log(chunk);
}
```
</typescript>
</ex-stream-custom-data>

---

## 错误处理 (Error Handling)

将错误类型与正确的处理策略相匹配：

<error-handling-table>

| 错误类型 | 解决方 | 策略 | 示例 |
|---|---|---|---|
| 瞬态错误（网络抖动、速率限制） | 系统 | `RetryPolicy(max_attempts=3)` | `add_node(..., retry_policy=...)` |
| LLM 可恢复错误（工具调用失败） | LLM | `ToolNode(tools, handle_tool_errors=True)` | 错误作为 `ToolMessage` 返回 |
| 用户可修复错误（缺失信息） | 人工 | `interrupt({"message": ...})` | 收集缺失数据（参见 HITL 技能） |
| 非预期错误 | 开发者 | 向外冒泡 | `raise` |

</error-handling-table>

<ex-retry-policy>
<python>
针对瞬态错误（网络问题、速率限制）使用 `RetryPolicy`。

```python
from langgraph.types import RetryPolicy

workflow.add_node(
    "search_documentation",
    search_documentation,
    retry_policy=RetryPolicy(max_attempts=3, initial_interval=1.0)
)
```
</python>
<typescript>
针对瞬态错误使用 `retryPolicy`。

```typescript
workflow.addNode(
  "searchDocumentation",
  searchDocumentation,
  {
    retryPolicy: { maxAttempts: 3, initialInterval: 1.0 },
  },
);
```
</typescript>
</ex-retry-policy>

<ex-tool-node-error-handling>
<python>
使用 `langgraph.prebuilt` 中的 `ToolNode` 处理工具执行及错误。当 `handle_tool_errors=True` 时，错误将作为 `ToolMessage` 返回，以便 LLM 进行自我修正。

```python
from langgraph.prebuilt import ToolNode

tool_node = ToolNode(tools, handle_tool_errors=True)

workflow.add_node("tools", tool_node)
```
</python>
<typescript>
使用 `@langchain/langgraph/prebuilt` 中的 `ToolNode` 处理工具执行及错误。当 `handleToolErrors` 为 `true` 时，错误将作为 `ToolMessage` 返回，以便 LLM 进行自我修正。

```typescript
import { ToolNode } from "@langchain/langgraph/prebuilt";

const toolNode = new ToolNode(tools, { handleToolErrors: true });

workflow.addNode("tools", toolNode);
```
</typescript>
</ex-tool-node-error-handling>

---

## 常见问题修复

<fix-compile-before-execution>
<python>
必须调用 `compile()` 生成可执行的图。

```python
# 错误写法
builder.invoke({"input": "test"})  # 抛出 AttributeError！

# 正确写法
graph = builder.compile()
graph.invoke({"input": "test"})
```
</python>
<typescript>
必须调用 `compile()` 生成可执行的图。

```typescript
// 错误写法
await builder.invoke({ input: "test" });

// 正确写法
const graph = builder.compile();
await graph.invoke({ input: "test" });
```
</typescript>
</fix-compile-before-execution>

<fix-infinite-loop-needs-exit>
<python>
提供通往 `END` 的条件路径以避免死循环。

```python
# 错误写法：无限循环
builder.add_edge("node_a", "node_b")
builder.add_edge("node_b", "node_a")

# 正确写法
def should_continue(state):
    return END if state["count"] > 10 else "node_b"
builder.add_conditional_edges("node_a", should_continue)
```
</python>
<typescript>
使用返回 `END` 的条件边来跳出循环。

```typescript
// 错误写法：无限循环
builder.addEdge("node_a", "node_b").addEdge("node_b", "node_a");

// 正确写法
builder.addConditionalEdges("node_a", (state) => state.count > 10 ? END : "node_b");
```
</typescript>
</fix-infinite-loop-needs-exit>

<fix-common-mistakes>
其他常见错误：

```python
# 路由函数返回的节点名称必须已存在于图中
builder.add_node("my_node", func)  # 在边中引用之前必须先添加节点
builder.add_conditional_edges("node_a", router, ["my_node"])

# Python 中 Command 的返回类型需要用 Literal 标注合法的路由目标
def node_a(state) -> Command[Literal["node_b", "node_c"]]:
    return Command(goto="node_b")

# START 仅作为入口使用 —— 不能将边路由回 START
builder.add_edge("node_a", START)  # 错误！
builder.add_edge("node_a", "entry")  # 请使用具名的入口节点代替

# Reducer 要求类型匹配
return {"items": ["item"]}  # 对于列表 Reducer 请传入 List，而不是普通字符串
```

```typescript
// 始终 await graph.invoke() —— 它返回一个 Promise
const result = await graph.invoke({ input: "test" });

// TS 中的 Command 节点需要传入 { ends } 来声明路由目标
builder.addNode("router", routerFn, { ends: ["node_b", "node_c"] });
```
</fix-common-mistakes>

<boundaries>
### 禁止事项 (What You Should NOT Do)

- 直接修改状态 (Mutate state) —— 务必从节点返回部分更新字典
- 将边路由回 `START` —— `START` 仅作为入口，请改用具名节点
- 遗漏列表字段的 Reducer —— 没有 Reducer 时，最后一次写入会覆盖先前的值
- 在未理解其均会执行的情况下混用静态边与 `Command.goto`
</boundaries>