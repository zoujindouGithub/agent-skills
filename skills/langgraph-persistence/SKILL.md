---
name: langgraph-persistence
description: "当你的 LangGraph 需要持久化状态、记忆对话、回溯历史（时光旅行）或配置子图检查点作用域时调用此技能。涵盖 Checkpointer（检查点保存器）、thread_id、时光旅行、Store（存储）以及子图持久化模式。"
---

<overview>
LangGraph 的持久化层通过对图状态进行检查点记录（checkpointing）来实现持久化执行：

- **Checkpointer（检查点保存器）**：在每个超级步（super-step）保存/加载图状态
- **Thread ID（线程 ID）**：标识独立的检查点序列（对话）
- **Store（存储）**：用于保存用户偏好、事实的跨线程记忆

**两种记忆类型：**
- **短期记忆**（Checkpointer）：线程范围内的对话历史
- **长期记忆**（Store）：跨线程的用户偏好、事实
</overview>

<checkpointer-selection>

| Checkpointer | 使用场景 | 是否生产就绪 |
|--------------|----------|------------------|
| `InMemorySaver` | 测试、开发 | 否 |
| `SqliteSaver` | 本地开发 | 部分支持 |
| `PostgresSaver` | 生产环境 | 是 |

</checkpointer-selection>

---

## 检查点保存器设置

<ex-basic-persistence>
<python>
设置一个具有内存检查点和基于线程的状态持久化的基础图。

```python
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.graph import StateGraph, START, END
from typing_extensions import TypedDict, Annotated
import operator

class State(TypedDict):
    messages: Annotated[list, operator.add]

def add_message(state: State) -> dict:
    return {"messages": ["Bot response"]}

checkpointer = InMemorySaver()

graph = (
    StateGraph(State)
    .add_node("respond", add_message)
    .add_edge(START, "respond")
    .add_edge("respond", END)
    .compile(checkpointer=checkpointer)  # 在编译时传入
)

# 务必提供 thread_id
config = {"configurable": {"thread_id": "conversation-1"}}

result1 = graph.invoke({"messages": ["Hello"]}, config)
print(len(result1["messages"]))  # 2

result2 = graph.invoke({"messages": ["How are you?"]}, config)
print(len(result2["messages"]))  # 4 (之前的内容 + 新内容)
```
</python>
<typescript>
设置一个具有内存检查点和基于线程的状态持久化的基础图。

```typescript
import { MemorySaver, StateGraph, StateSchema, MessagesValue, START, END } from "@langchain/langgraph";
import { HumanMessage } from "@langchain/core/messages";

const State = new StateSchema({ messages: MessagesValue });

const addMessage = async (state: typeof State.State) => {
  return { messages: [{ role: "assistant", content: "Bot response" }] };
};

const checkpointer = new MemorySaver();

const graph = new StateGraph(State)
  .addNode("respond", addMessage)
  .addEdge(START, "respond")
  .addEdge("respond", END)
  .compile({ checkpointer });

// 务必提供 thread_id
const config = { configurable: { thread_id: "conversation-1" } };

const result1 = await graph.invoke({ messages: [new HumanMessage("Hello")] }, config);
console.log(result1.messages.length);  // 2

const result2 = await graph.invoke({ messages: [new HumanMessage("How are you?")] }, config);
console.log(result2.messages.length);  // 4 (之前的内容 + 新内容)
```
</typescript>
</ex-basic-persistence>

<ex-production-postgres>
<python>
为生产部署配置基于 PostgreSQL 的检查点保存。

```python
import os
from langgraph.checkpoint.postgres import PostgresSaver

# 在部署期间运行一次（不要在应用程序启动时运行）：
#   PostgresSaver.from_conn_string(os.environ["DATABASE_URL"]).setup()

with PostgresSaver.from_conn_string(os.environ["DATABASE_URL"]) as checkpointer:
    graph = builder.compile(checkpointer=checkpointer)
```
</python>
<typescript>
为生产部署配置基于 PostgreSQL 的检查点保存。

```typescript
import { PostgresSaver } from "@langchain/langgraph-checkpoint-postgres";

// 在部署期间运行一次（不要在应用程序启动时运行）：
//   await PostgresSaver.fromConnString(process.env.DATABASE_URL!).setup();

const checkpointer = PostgresSaver.fromConnString(process.env.DATABASE_URL!);
const graph = builder.compile({ checkpointer });
```
</typescript>
</ex-production-postgres>

---

## 线程管理

<ex-separate-threads>
<python>
演示不同线程 ID 之间的状态隔离。

```python
# 不同的线程维护各自独立的状态
alice_config = {"configurable": {"thread_id": "user-alice"}}
bob_config = {"configurable": {"thread_id": "user-bob"}}

graph.invoke({"messages": ["Hi from Alice"]}, alice_config)
graph.invoke({"messages": ["Hi from Bob"]}, bob_config)

# Alice 的状态与 Bob 的状态互相隔离
```
</python>
<typescript>
演示不同线程 ID 之间的状态隔离。

```typescript
// 不同的线程维护各自独立的状态
const aliceConfig = { configurable: { thread_id: "user-alice" } };
const bobConfig = { configurable: { thread_id: "user-bob" } };

await graph.invoke({ messages: [new HumanMessage("Hi from Alice")] }, aliceConfig);
await graph.invoke({ messages: [new HumanMessage("Hi from Bob")] }, bobConfig);

// Alice 的状态与 Bob 的状态互相隔离
```
</typescript>
</ex-separate-threads>

---

## 状态历史与时光旅行

<ex-resume-from-checkpoint>
<python>
时光旅行：浏览检查点历史，并从过去的状态重放或分叉（fork）。

```python
config = {"configurable": {"thread_id": "session-1"}}

result = graph.invoke({"messages": ["start"]}, config)

# 浏览检查点历史
states = list(graph.get_state_history(config))

# 从过去的检查点重放
past = states[-2]
result = graph.invoke(None, past.config)  # None = 从检查点恢复

# 或者分叉：在过去的检查点更新状态，然后恢复执行
fork_config = graph.update_state(past.config, {"messages": ["edited"]})
result = graph.invoke(None, fork_config)
```
</python>
<typescript>
时光旅行：浏览检查点历史，并从过去的状态重放或分叉（fork）。

```typescript
const config = { configurable: { thread_id: "session-1" } };

const result = await graph.invoke({ messages: ["start"] }, config);

// 浏览检查点历史（异步可迭代对象，收集到数组中）
const states: Awaited<ReturnType<typeof graph.getState>>[] = [];
for await (const state of graph.getStateHistory(config)) {
  states.push(state);
}

// 从过去的检查点重放
const past = states[states.length - 2];
const replayed = await graph.invoke(null, past.config);  // null = 从检查点恢复

// 或者分叉：在过去的检查点更新状态，然后恢复执行
const forkConfig = await graph.updateState(past.config, { messages: ["edited"] });
const forked = await graph.invoke(null, forkConfig);
```
</typescript>
</ex-resume-from-checkpoint>

<ex-update-state>
<python>
在恢复执行之前手动更新图状态。

```python
config = {"configurable": {"thread_id": "session-1"}}

# 在恢复之前修改状态
graph.update_state(config, {"data": "manually_updated"})

# 使用更新后的状态恢复执行
result = graph.invoke(None, config)
```
</python>
<typescript>
在恢复执行之前手动更新图状态。

```typescript
const config = { configurable: { thread_id: "session-1" } };

// 在恢复之前修改状态
await graph.updateState(config, { data: "manually_updated" });

// 使用更新后的状态恢复执行
const result = await graph.invoke(null, config);
```
</typescript>
</ex-update-state>

---

## 子图检查点保存器作用域

在编译子图时，`checkpointer` 参数控制着持久化行为。这对于使用中断、需要多轮对话记忆或并行运行的子图至关重要。

<subgraph-checkpointer-scoping-table>

| 特性 | `checkpointer=False` | `None`（默认） | `True` |
|---|---|---|---|
| 中断（人机交互/HITL） | 否 | 是 | 是 |
| 多轮记忆 | 否 | 否 | 是 |
| 多次调用（不同子图） | 是 | 是 | 警告（可能发生命名空间冲突） |
| 多次调用（相同子图） | 是 | 是 | 否 |
| 状态检查 | 否 | 警告（仅限当前调用） | 是 |

</subgraph-checkpointer-scoping-table>

<subgraph-checkpointer-when-to-use>

### 各模式的使用场景

- **`checkpointer=False`** — 子图不需要中断或持久化。最简单的选项，无检查点开销。
- **`None`（默认 / 省略 `checkpointer`）** — 子图需要 `interrupt()` 但不需要多轮记忆。每次调用都会全新开始，但可以暂停/恢复。支持并行执行，因为每次调用都会获得一个唯一的命名空间。
- **`checkpointer=True`** — 子图需要跨调用记忆状态（多轮对话）。每次调用都会接着上一次的状态继续。

</subgraph-checkpointer-when-to-use>

<warning-stateful-subgraphs-parallel>

**警告**：有状态子图（`checkpointer=True`）**不**支持在单个节点内多次调用相同的子图实例——这些调用会写入相同的检查点命名空间并发生冲突。

</warning-stateful-subgraphs-parallel>

<ex-subgraph-checkpointer-modes>
<python>
为你的子图选择正确的检查点模式。

```python
# 不需要中断 — 禁用检查点保存
subgraph = subgraph_builder.compile(checkpointer=False)

# 需要中断但不需要跨调用持久化（默认）
subgraph = subgraph_builder.compile()

# 需要跨调用持久化（有状态）
subgraph = subgraph_builder.compile(checkpointer=True)
```
</python>
<typescript>
为你的子图选择正确的检查点模式。

```typescript
// 不需要中断 — 禁用检查点保存
const subgraph = subgraphBuilder.compile({ checkpointer: false });

// 需要中断但不需要跨调用持久化（默认）
const subgraph = subgraphBuilder.compile();

// 需要跨调用持久化（有状态）
const subgraph = subgraphBuilder.compile({ checkpointer: true });
```
</typescript>
</ex-subgraph-checkpointer-modes>

<parallel-subgraph-namespacing>

### 并行子图命名空间隔离

当多个**不同**的有状态子图并行运行时，将每个子图包装在其自有的 `StateGraph` 中并使用唯一的节点名称，以实现稳定的命名空间隔离：

<python>

```python
from langgraph.graph import MessagesState, StateGraph

def create_sub_agent(model, *, name, **kwargs):
    """使用唯一的节点名称包装智能体以实现命名空间隔离。"""
    agent = create_agent(model=model, name=name, **kwargs)
    return (
        StateGraph(MessagesState)
        .add_node(name, agent)  # 唯一名称 -> 稳定的命名空间
        .add_edge("__start__", name)
        .compile()
    )

fruit_agent = create_sub_agent(
    "gpt-4.1-mini", name="fruit_agent",
    tools=[fruit_info], prompt="...", checkpointer=True,
)
veggie_agent = create_sub_agent(
    "gpt-4.1-mini", name="veggie_agent",
    tools=[veggie_info], prompt="...", checkpointer=True,
)
```
</python>
<typescript>

```typescript
import { StateGraph, StateSchema, MessagesValue, START } from "@langchain/langgraph";

function createSubAgent(model: string, { name, ...kwargs }: { name: string; [key: string]: any }) {
  const agent = createAgent({ model, name, ...kwargs });
  return new StateGraph(new StateSchema({ messages: MessagesValue }))
    .addNode(name, agent)  // 唯一名称 -> 稳定的命名空间
    .addEdge(START, name)
    .compile();
}

const fruitAgent = createSubAgent("gpt-4.1-mini", {
  name: "fruit_agent", tools: [fruitInfo], prompt: "...", checkpointer: true,
});
const veggieAgent = createSubAgent("gpt-4.1-mini", {
  name: "veggie_agent", tools: [veggieInfo], prompt: "...", checkpointer: true,
});
```
</typescript>

注意：通过 `add_node` 作为节点添加的子图会自动获得基于名称的命名空间，不需要此包装器。

</parallel-subgraph-namespacing>

---

## 长期记忆 (Store)

<ex-long-term-memory-store>
<python>
使用 Store 实现跨线程记忆，从而在不同对话之间共享用户偏好。

```python
from langgraph.store.memory import InMemoryStore

store = InMemoryStore()

# 保存用户偏好（在所有线程中均可访问）
store.put(("alice", "preferences"), "language", {"preference": "short responses"})

# 带有 store 的节点 — 通过 runtime 访问
from langgraph.runtime import Runtime

def respond(state, runtime: Runtime):
    prefs = runtime.store.get((state["user_id"], "preferences"), "language")
    return {"response": f"Using preference: {prefs.value}"}

# 同时使用 checkpointer 和 store 进行编译
graph = builder.compile(checkpointer=checkpointer, store=store)

# 两个线程访问相同的长期记忆
graph.invoke({"user_id": "alice"}, {"configurable": {"thread_id": "thread-1"}})
graph.invoke({"user_id": "alice"}, {"configurable": {"thread_id": "thread-2"}})  # 偏好设置相同！
```
</python>
<typescript>
使用 Store 实现跨线程记忆，从而在不同对话之间共享用户偏好。

```typescript
import { MemoryStore } from "@langchain/langgraph";

const store = new MemoryStore();

// 保存用户偏好（在所有线程中均可访问）
await store.put(["alice", "preferences"], "language", { preference: "short responses" });

// 带有 store 的节点 — 通过 runtime 访问
const respond = async (state: typeof State.State, runtime: any) => {
  const item = await runtime.store?.get(["alice", "preferences"], "language");
  return { response: `Using preference: ${item?.value?.preference}` };
};

// 同时使用 checkpointer 和 store 进行编译
const graph = builder.compile({ checkpointer, store });

// 两个线程访问相同的长期记忆
await graph.invoke({ userId: "alice" }, { configurable: { thread_id: "thread-1" } });
await graph.invoke({ userId: "alice" }, { configurable: { thread_id: "thread-2" } });  // 偏好设置相同！
```
</typescript>
</ex-long-term-memory-store>

<ex-store-operations>
<python>
基础 Store 操作：put、get、search 和 delete。

```python
from langgraph.store.memory import InMemoryStore

store = InMemoryStore()

store.put(("user-123", "facts"), "location", {"city": "San Francisco"})  # 写入 (Put)
item = store.get(("user-123", "facts"), "location")  # 获取 (Get)
results = store.search(("user-123", "facts"), filter={"city": "San Francisco"})  # 搜索 (Search)
store.delete(("user-123", "facts"), "location")  # 删除 (Delete)
```
</python>
</ex-store-operations>

---

## 修复方案

<fix-thread-id-required>
<python>
务必在 config 中提供 thread_id 以启用状态持久化。

```python
# 错误：没有 thread_id - 状态不会被持久化！
graph.invoke({"messages": ["Hello"]})
graph.invoke({"messages": ["What did I say?"]})  # 无法记住！

# 正确：务必提供 thread_id
config = {"configurable": {"thread_id": "session-1"}}
graph.invoke({"messages": ["Hello"]}, config)
graph.invoke({"messages": ["What did I say?"]}, config)  # 成功记住！
```
</python>
<typescript>
务必在 config 中提供 thread_id 以启用状态持久化。

```typescript
// 错误：没有 thread_id - 状态不会被持久化！
await graph.invoke({ messages: [new HumanMessage("Hello")] });
await graph.invoke({ messages: [new HumanMessage("What did I say?")] });  // 无法记住！

// 正确：务必提供 thread_id
const config = { configurable: { thread_id: "session-1" } };
await graph.invoke({ messages: [new HumanMessage("Hello")] }, config);
await graph.invoke({ messages: [new HumanMessage("What did I say?")] }, config);  // 成功记住！
```
</typescript>
</fix-thread-id-required>


<fix-inmemory-not-for-production>
<python>
在生产环境持久化中使用 PostgresSaver 替代 InMemorySaver。

```python
# 错误：进程重启后数据丢失
checkpointer = InMemorySaver()  # 仅限内存！

# 正确：在生产环境中使用持久化存储
from langgraph.checkpoint.postgres import PostgresSaver
with PostgresSaver.from_conn_string("postgresql://...") as checkpointer:
    checkpointer.setup()  # 仅首次使用创建数据表时需要
    graph = builder.compile(checkpointer=checkpointer)
```
</python>
<typescript>
在生产环境持久化中使用 PostgresSaver 替代 MemorySaver。

```typescript
// 错误：进程重启后数据丢失
const checkpointer = new MemorySaver();  // 仅限内存！

// 正确：在生产环境中使用持久化存储
import { PostgresSaver } from "@langchain/langgraph-checkpoint-postgres";
const checkpointer = PostgresSaver.fromConnString("postgresql://...");
await checkpointer.setup(); // 仅首次使用创建数据表时需要
```
</typescript>
</fix-inmemory-not-for-production>


<fix-update-state-with-reducers>
<python>
使用 Overwrite 替换状态值，而不是经过 reducer 处理。

```python
from langgraph.types import Overwrite

# 带有 reducer 的状态：items: Annotated[list, operator.add]
# 当前状态：{"items": ["A", "B"]}

# update_state 会经过 reducers 处理
graph.update_state(config, {"items": ["C"]})  # 结果：["A", "B", "C"] - 已追加！

# 若要进行替换，请使用 Overwrite
graph.update_state(config, {"items": Overwrite(["C"])})  # 结果：["C"] - 已替换
```
</python>
<typescript>
使用 Overwrite 替换状态值，而不是经过 reducer 处理。

```typescript
import { Overwrite } from "@langchain/langgraph";

// 带有 reducer 的状态：items 使用 concat reducer
// 当前状态：{ items: ["A", "B"] }

// updateState 会经过 reducers 处理
await graph.updateState(config, { items: ["C"] });  // 结果：["A", "B", "C"] - 已追加！

// 若要进行替换，请使用 Overwrite
await graph.updateState(config, { items: new Overwrite(["C"]) });  // 结果：["C"] - 已替换
```
</typescript>
</fix-update-state-with-reducers>

<fix-store-injection>
<python>
在图节点中通过 Runtime 对象访问 store。

```python
# 错误：store 在节点中不可用
def my_node(state):
    store.put(...)  # NameError! store 未定义

# 正确：通过 runtime 访问 store
from langgraph.runtime import Runtime

def my_node(state, runtime: Runtime):
    runtime.store.put(...)  # 正确的 store 实例
```
</python>
<typescript>
在图节点中通过 runtime 参数访问 store。

```typescript
// 错误：store 在节点中不可用
const myNode = async (state) => {
  store.put(...);  // ReferenceError!
};

// 正确：通过 runtime 访问 store
const myNode = async (state, runtime) => {
  await runtime.store?.put(...);  // 正确的 store 实例
};
```
</typescript>
</fix-store-injection>

<boundaries>
### 禁止事项

- 不要在生产环境中使用 `InMemorySaver` — 重启后数据会丢失；请使用 `PostgresSaver`
- 不要遗漏 `thread_id` — 没有它状态将无法持久化
- 不要期望 `update_state` 能绕过 reducer — 它会经过 reducer 处理；如需直接替换请使用 `Overwrite`
- 不要在单个节点内并行运行相同的有状态子图（`checkpointer=True`）— 会导致命名空间冲突
- 不要直接在节点内部访问 store — 应该通过 `Runtime` 参数使用 `runtime.store` 访问
</boundaries>