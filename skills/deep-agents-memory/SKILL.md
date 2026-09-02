---
name: deep-agents-memory
description: "当你的 Deep Agent 需要记忆、持久化或文件系统访问时调用此 SKILL。涵盖 StateBackend（临时）、StoreBackend（持久化）、FilesystemMiddleware 以及用于路由的 CompositeBackend。"
---

<overview>
Deep Agent 使用可插拔后端进行文件操作和记忆管理：

**短期（StateBackend）**：在单个线程（thread）内持久化，线程结束时丢失
**长期（StoreBackend）**：跨线程和跨会话持久化
**混合（CompositeBackend）**：将不同路径路由到不同的后端

FilesystemMiddleware 提供了以下工具：`ls`、`read_file`、`write_file`、`edit_file`、`glob`、`grep`
</overview>

<backend-selection>

| 使用场景 | 后端 | 原因 |
|----------|---------|-----|
| 临时工作文件 | StateBackend | 默认配置，无需额外设置 |
| 本地开发 CLI | FilesystemBackend | 直接访问磁盘 |
| 跨会话记忆 | StoreBackend | 跨线程持久化 |
| 混合存储 | CompositeBackend | 混合使用临时 + 持久化存储 |

</backend-selection>

<ex-default-state-backend>
<python>
默认的 StateBackend 在线程内临时存储文件。

```python
from deepagents import create_deep_agent

agent = create_deep_agent()  # 默认：StateBackend
result = agent.invoke({
    "messages": [{"role": "user", "content": "Write notes to /draft.txt"}]
}, config={"configurable": {"thread_id": "thread-1"}})
# 线程结束时 /draft.txt 将丢失
```
</python>
<typescript>
默认的 StateBackend 在线程内临时存储文件。

```typescript
import { createDeepAgent } from "deepagents";

const agent = await createDeepAgent();  // 默认：StateBackend
const result = await agent.invoke({
  messages: [{ role: "user", content: "Write notes to /draft.txt" }]
}, { configurable: { thread_id: "thread-1" } });
// 线程结束时 /draft.txt 将丢失
```
</typescript>
</ex-default-state-backend>

<ex-composite-backend-for-hybrid>
<python>
配置 CompositeBackend 将路径路由到不同的存储后端。

```python
from deepagents import create_deep_agent
from deepagents.backends import CompositeBackend, StateBackend, StoreBackend
from langgraph.store.memory import InMemoryStore

store = InMemoryStore()

composite_backend = lambda rt: CompositeBackend(
    default=StateBackend(rt),
    routes={"/memories/": StoreBackend(rt)}
)

agent = create_deep_agent(backend=composite_backend, store=store)

# /draft.txt -> 临时 (StateBackend)
# /memories/user-prefs.txt -> 持久化 (StoreBackend)
```
</python>
<typescript>
配置 CompositeBackend 将路径路由到不同的存储后端。

```typescript
import { createDeepAgent, CompositeBackend, StateBackend, StoreBackend } from "deepagents";
import { InMemoryStore } from "@langchain/langgraph";

const store = new InMemoryStore();

const agent = await createDeepAgent({
  backend: (config) => new CompositeBackend(
    new StateBackend(config),
    { "/memories/": new StoreBackend(config) }
  ),
  store
});

// /draft.txt -> 临时 (StateBackend)
// /memories/user-prefs.txt -> 持久化 (StoreBackend)
```
</typescript>
</ex-composite-backend-for-hybrid>

<ex-cross-session-memory>
<python>
/memories/ 中的文件通过 StoreBackend 路由跨线程持久化。

```python
# 使用前例中的 CompositeBackend
config1 = {"configurable": {"thread_id": "thread-1"}}
agent.invoke({"messages": [{"role": "user", "content": "Save to /memories/style.txt"}]}, config=config1)

config2 = {"configurable": {"thread_id": "thread-2"}}
agent.invoke({"messages": [{"role": "user", "content": "Read /memories/style.txt"}]}, config=config2)
# 线程 2 可以读取线程 1 保存的文件
```
</python>
<typescript>
/memories/ 中的文件通过 StoreBackend 路由跨线程持久化。

```typescript
// 使用前例中的 CompositeBackend
const config1 = { configurable: { thread_id: "thread-1" } };
await agent.invoke({ messages: [{ role: "user", content: "Save to /memories/style.txt" }] }, config1);

const config2 = { configurable: { thread_id: "thread-2" } };
await agent.invoke({ messages: [{ role: "user", content: "Read /memories/style.txt" }] }, config2);
// 线程 2 可以读取线程 1 保存的文件
```
</typescript>
</ex-cross-session-memory>

<ex-filesystem-backend-local-dev>
<python>
在本地开发中使用 FilesystemBackend 进行实际磁盘访问并支持人机协同（human-in-the-loop）。

```python
from deepagents import create_deep_agent
from deepagents.backends import FilesystemBackend
from langgraph.checkpoint.memory import MemorySaver

agent = create_deep_agent(
    backend=FilesystemBackend(root_dir=".", virtual_mode=True),  # 限制访问路径
    interrupt_on={"write_file": True, "edit_file": True},
    checkpointer=MemorySaver()
)

# Agent 可以读写磁盘上的实际文件
```
</python>
<typescript>
在本地开发中使用 FilesystemBackend 进行实际磁盘访问并支持人机协同（human-in-the-loop）。

```typescript
import { createDeepAgent, FilesystemBackend } from "deepagents";
import { MemorySaver } from "@langchain/langgraph";

const agent = await createDeepAgent({
  backend: new FilesystemBackend({ rootDir: ".", virtualMode: true }),
  interruptOn: { write_file: true, edit_file: true },
  checkpointer: new MemorySaver()
});
```
</typescript>

**安全性：切勿在 Web 服务器中使用 FilesystemBackend——请改用 StateBackend 或沙箱（sandbox）。**
</ex-filesystem-backend-local-dev>

<ex-store-in-custom-tools>
<python>
在自定义工具中直接访问 store 以执行长期记忆操作。

```python
from langchain.tools import tool, ToolRuntime
from langchain.agents import create_agent
from langgraph.store.memory import InMemoryStore

@tool
def get_user_preference(key: str, runtime: ToolRuntime) -> str:
    """从长期存储中获取用户偏好设置。"""
    store = runtime.store
    result = store.get(("user_prefs",), key)
    return str(result.value) if result else "Not found"

@tool
def save_user_preference(key: str, value: str, runtime: ToolRuntime) -> str:
    """将用户偏好设置保存到长期存储中。"""
    store = runtime.store
    store.put(("user_prefs",), key, {"value": value})
    return f"Saved {key}={value}"

store = InMemoryStore()

agent = create_agent(
    model="gpt-4.1",
    tools=[get_user_preference, save_user_preference],
    store=store
)
```
</python>
</ex-store-in-custom-tools>

<boundaries>
### Agent 可以配置的内容

- 后端类型与配置
- CompositeBackend 的路由规则
- FilesystemBackend 的根目录
- 文件操作的人机协同（Human-in-the-loop）

### Agent 不能配置的内容

- 工具名称（ls、read_file、write_file、edit_file、glob、grep）
- 访问 virtual_mode 限制之外的文件
- 在没有正确配置后端的情况下进行跨线程文件访问
</boundaries>

<fix-storebackend-requires-store>
<python>
StoreBackend 需要一个 store 实例。

```python
# 错误
agent = create_deep_agent(backend=lambda rt: StoreBackend(rt))

# 正确
agent = create_deep_agent(backend=lambda rt: StoreBackend(rt), store=InMemoryStore())
```
</python>
<typescript>
StoreBackend 需要一个 store 实例。

```typescript
// 错误
const agent = await createDeepAgent({ backend: (c) => new StoreBackend(c) });

// 正确
const agent = await createDeepAgent({ backend: (c) => new StoreBackend(c), store: new InMemoryStore() });
```
</typescript>
</fix-storebackend-requires-store>

<fix-statebackend-files-dont-persist>
<python>
StateBackend 文件作用域仅限于线程——跨线程访问请使用相同的 thread_id 或 StoreBackend。

```python
# 错误：thread-2 无法读取 thread-1 的文件
agent.invoke({"messages": [...]}, config={"configurable": {"thread_id": "thread-1"}})  # 写入
agent.invoke({"messages": [...]}, config={"configurable": {"thread_id": "thread-2"}})  # 文件未找到！
```
</python>
<typescript>
StateBackend 文件作用域仅限于线程——跨线程访问请使用相同的 thread_id 或 StoreBackend。

```typescript
// 错误：thread-2 无法读取 thread-1 的文件
await agent.invoke({ messages: [...] }, { configurable: { thread_id: "thread-1" } });  // 写入
await agent.invoke({ messages: [...] }, { configurable: { thread_id: "thread-2" } });  // 文件未找到！
```
</typescript>
</fix-statebackend-files-dont-persist>

<fix-path-prefix-for-persistence>
<python>
路径必须匹配 CompositeBackend 路由前缀才能实现持久化。

```python
# 当 routes={"/memories/": StoreBackend(rt)} 时：
agent.invoke(...)  # /prefs.txt -> 临时（未匹配）
agent.invoke(...)  # /memories/prefs.txt -> 持久化（匹配路由）
```
</python>
<typescript>
路径必须匹配 CompositeBackend 路由前缀才能实现持久化。

```typescript
// 当 routes: { "/memories/": StoreBackend } 时：
await agent.invoke(...);  // /prefs.txt -> 临时（未匹配）
await agent.invoke(...);  // /memories/prefs.txt -> 持久化（匹配路由）
```
</typescript>
</fix-path-prefix-for-persistence>

<fix-production-store>
<python>
生产环境中请使用 PostgresStore（InMemoryStore 在重启时会丢失数据）。

```python
# 错误                               # 正确
store = InMemoryStore()              store = PostgresStore(connection_string="postgresql://...")
```
</python>
<typescript>
生产环境中请使用 PostgresStore（InMemoryStore 在重启时会丢失数据）。

```typescript
// 错误                                     // 正确
const store = new InMemoryStore();          const store = new PostgresStore({ connectionString: "..." });
```
</typescript>
</fix-production-store>

<fix-filesystem-backend-needs-virtual-mode>
<python>
启用 virtual_mode=True 限制路径访问（防止 ../ 和 ~/ 越界逃逸）。

```python
backend = FilesystemBackend(root_dir="/project", virtual_mode=True)  # 安全
```
</python>
</fix-filesystem-backend-needs-virtual-mode>

<fix-longest-prefix-match>
<python>
CompositeBackend 优先匹配最长前缀。

```python
routes = {"/mem/": StoreBackend(rt), "/mem/temp/": StateBackend(rt)}
# /mem/file.txt -> StoreBackend, /mem/temp/file.txt -> StateBackend（匹配更长前缀）
```
</python>
</fix-longest-prefix-match>