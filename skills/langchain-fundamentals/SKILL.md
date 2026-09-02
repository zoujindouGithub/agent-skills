---
name: langchain-fundamentals
description: 使用 create_agent 创建 LangChain Agent，定义工具，并利用中间件实现人机协同（human-in-the-loop）和错误处理。
---

<oneliner>
使用 `create_agent()`、中间件模式以及 `@tool` 装饰器 / `tool()` 函数构建生产级 Agent。创建 LangChain Agent 时，必须使用 `create_agent()`，并通过中间件实现自定义流程。所有其他替代方案均已过时。
</oneliner>

<create_agent>
## 使用 create_agent 创建 Agent

`create_agent()` 是构建 Agent 的推荐方式。它负责处理 Agent 循环、工具执行以及状态管理。

### Agent 配置项

| 参数 | 用途 | 示例 |
|-----------|---------|---------|
| `model` | 所使用的 LLM | `"anthropic:claude-sonnet-4-5"` 或模型实例 |
| `tools` | 工具列表 | `[search, calculator]` |
| `system_prompt` / `systemPrompt` | Agent 指令 | `"You are a helpful assistant"` |
| `checkpointer` | 状态持久化 | `MemorySaver()` |
| `middleware` | 处理钩子（Hooks） | `[HumanInTheLoopMiddleware]` (Python) / `[humanInTheLoopMiddleware({...})]` (TypeScript) |
</create_agent>

<ex-basic-agent>
<python>

```python
from langchain.agents import create_agent
from langchain_core.tools import tool

@tool
def get_weather(location: str) -> str:
    """获取指定位置的当前天气。

    Args:
        location: 城市名称
    """
    return f"Weather in {location}: Sunny, 72F"

agent = create_agent(
    model="anthropic:claude-sonnet-4-5",
    tools=[get_weather],
    system_prompt="You are a helpful assistant."
)

result = agent.invoke({
    "messages": [{"role": "user", "content": "What's the weather in Paris?"}]
})
print(result["messages"][-1].content)
```
</python>
<typescript>

```typescript
import { createAgent } from "langchain";
import { tool } from "@langchain/core/tools";
import { z } from "zod";

const getWeather = tool(
  async ({ location }) => `Weather in ${location}: Sunny, 72F`,
  {
    name: "get_weather",
    description: "Get current weather for a location.",
    schema: z.object({ location: z.string().describe("City name") }),
  }
);

const agent = createAgent({
  model: "anthropic:claude-sonnet-4-5",
  tools: [getWeather],
  systemPrompt: "You are a helpful assistant.",
});

const result = await agent.invoke({
  messages: [{ role: "user", content: "What's the weather in Paris?" }],
});
console.log(result.messages[result.messages.length - 1].content);
```
</typescript>
</ex-basic-agent>

<ex-agent-with-persistence>
<python>
添加 MemorySaver checkpointer 以在多次调用之间保持对话状态。

```python
from langchain.agents import create_agent
from langgraph.checkpoint.memory import MemorySaver

checkpointer = MemorySaver()

agent = create_agent(
    model="anthropic:claude-sonnet-4-5",
    tools=[search],
    checkpointer=checkpointer,
)

config = {"configurable": {"thread_id": "user-123"}}
agent.invoke({"messages": [{"role": "user", "content": "My name is Alice"}]}, config=config)
result = agent.invoke({"messages": [{"role": "user", "content": "What's my name?"}]}, config=config)
# Agent 记住了："Your name is Alice"
```
</python>
<typescript>
添加 MemorySaver checkpointer 以在多次调用之间保持对话状态。

```typescript
import { createAgent } from "langchain";
import { MemorySaver } from "@langchain/langgraph";

const checkpointer = new MemorySaver();

const agent = createAgent({
  model: "anthropic:claude-sonnet-4-5",
  tools: [search],
  checkpointer,
});

const config = { configurable: { thread_id: "user-123" } };
await agent.invoke({ messages: [{ role: "user", content: "My name is Alice" }] }, config);
const result = await agent.invoke({ messages: [{ role: "user", content: "What's my name?" }] }, config);
// Agent 记住了："Your name is Alice"
```
</typescript>
</ex-agent-with-persistence>

<tools>
## 定义工具

工具是 Agent 可以调用的函数。使用 `@tool` 装饰器 (Python) 或 `tool()` 函数 (TypeScript)。
</tools>

<ex-basic-tool>
<python>

```python
from langchain_core.tools import tool

@tool
def add(a: float, b: float) -> float:
    """将两个数字相加。

    Args:
        a: 第一个数字
        b: 第二个数字
    """
    return a + b
```
</python>
<typescript>

```typescript
import { tool } from "@langchain/core/tools";
import { z } from "zod";

const add = tool(
  async ({ a, b }) => a + b,
  {
    name: "add",
    description: "Add two numbers.",
    schema: z.object({
      a: z.number().describe("First number"),
      b: z.number().describe("Second number"),
    }),
  }
);
```
</typescript>
</ex-basic-tool>

<middleware>
## 用于控制 Agent 的中间件

中间件会拦截 Agent 循环以添加人工审批、错误处理、日志记录等功能。深入理解中间件对于构建生产级 Agent 至关重要 —— 使用 `HumanInTheLoopMiddleware` (Python) / `humanInTheLoopMiddleware` (TypeScript) 实现审批工作流，使用 `@wrap_tool_call` (Python) / `createMiddleware` (TypeScript) 实现自定义钩子。

核心导入：

```python
from langchain.agents.middleware import HumanInTheLoopMiddleware, wrap_tool_call
```

```typescript
import { humanInTheLoopMiddleware, createMiddleware } from "langchain";
```

核心模式：
- **HITL（人机协同）**：`middleware=[HumanInTheLoopMiddleware(interrupt_on={"dangerous_tool": True})]` —— 需要 `checkpointer` + `thread_id`
- **中断后恢复**：`agent.invoke(Command(resume={"decisions": [{"type": "approve"}]}), config=config)`
- **自定义中间件**：`@wrap_tool_call` 装饰器 (Python) 或 `createMiddleware({ wrapToolCall: ... })` (TypeScript)
</middleware>

<structured_output>
## 结构化输出

使用 `response_format` 或 `with_structured_output()` 从 Agent 获取类型化且经过验证的响应。

<python>

```python
from langchain.agents import create_agent
from pydantic import BaseModel, Field

class ContactInfo(BaseModel):
    name: str
    email: str
    phone: str = Field(description="带区号的电话号码")

# 选项 1：带有结构化输出的 Agent
agent = create_agent(model="gpt-4.1", tools=[search], response_format=ContactInfo)
result = agent.invoke({"messages": [{"role": "user", "content": "Find contact for John"}]})
print(result["structured_response"])  # ContactInfo(name='John', ...)

# 选项 2：模型级结构化输出（无需 Agent）
from langchain_openai import ChatOpenAI
model = ChatOpenAI(model="gpt-4.1")
structured_model = model.with_structured_output(ContactInfo)
response = structured_model.invoke("Extract: John, john@example.com, 555-1234")
# ContactInfo(name='John', email='john@example.com', phone='555-1234')
```
</python>
<typescript>

```typescript
import { ChatOpenAI } from "@langchain/openai";
import { z } from "zod";

const ContactInfo = z.object({
  name: z.string(),
  email: z.string().email(),
  phone: z.string().describe("带区号的电话号码"),
});

// 模型级结构化输出
const model = new ChatOpenAI({ model: "gpt-4.1" });
const structuredModel = model.withStructuredOutput(ContactInfo);
const response = await structuredModel.invoke("Extract: John, john@example.com, 555-1234");
// { name: 'John', email: 'john@example.com', phone: '555-1234' }
```
</typescript>
</structured_output>

<model_config>
## 模型配置

`create_agent` 接受模型字符串（`"anthropic:claude-sonnet-4-5"`、`"openai:gpt-4.1"`）或用于自定义设置的模型实例：

```python
from langchain_anthropic import ChatAnthropic
agent = create_agent(model=ChatAnthropic(model="claude-sonnet-4-5", temperature=0), tools=[...])
```
</model_config>


<fix-missing-tool-description>
<python>
清晰的描述有助于 Agent 了解何时该使用每个工具。

```python
# 错误：描述模糊或缺失
@tool
def bad_tool(input: str) -> str:
    """处理事务。"""
    return "result"

# 正确：清晰具体的描述，并附带 Args 说明
@tool
def search(query: str) -> str:
    """在网络上搜索关于某个主题的最新信息。

    当需要获取最新的数据或事实时使用此工具。

    Args:
        query: 搜索查询词（建议 2-10 个词）
    """
    return web_search(query)
```
</python>
<typescript>
清晰的描述有助于 Agent 了解何时该使用每个工具。

```typescript
// 错误：描述模糊
const badTool = tool(async ({ input }) => "result", {
  name: "bad_tool",
  description: "Does stuff.", // 太模糊了！
  schema: z.object({ input: z.string() }),
});

// 正确：清晰具体的描述
const search = tool(async ({ query }) => webSearch(query), {
  name: "search",
  description: "Search the web for current information about a topic. Use this when you need recent data or facts.",
  schema: z.object({
    query: z.string().describe("The search query (2-10 words recommended)"),
  }),
});
```
</typescript>
</fix-missing-tool-description>

<fix-no-checkpointer>
<python>
添加 checkpointer 和 thread_id，以实现跨调用的对话记忆。

```python
# 错误：没有持久化 - Agent 在多次调用之间会遗忘
agent = create_agent(model="anthropic:claude-sonnet-4-5", tools=[search])
agent.invoke({"messages": [{"role": "user", "content": "I'm Bob"}]})
agent.invoke({"messages": [{"role": "user", "content": "What's my name?"}]})
# Agent 记不住！

# 正确：添加 checkpointer 和 thread_id
from langgraph.checkpoint.memory import MemorySaver

agent = create_agent(
    model="anthropic:claude-sonnet-4-5",
    tools=[search],
    checkpointer=MemorySaver(),
)
config = {"configurable": {"thread_id": "session-1"}}
agent.invoke({"messages": [{"role": "user", "content": "I'm Bob"}]}, config=config)
agent.invoke({"messages": [{"role": "user", "content": "What's my name?"}]}, config=config)
# Agent 记住了："Your name is Bob"
```
</python>
<typescript>
添加 checkpointer 和 thread_id，以实现跨调用的对话记忆。

```typescript
// 错误：没有持久化
const agent = createAgent({ model: "anthropic:claude-sonnet-4-5", tools: [search] });
await agent.invoke({ messages: [{ role: "user", content: "I'm Bob" }] });
await agent.invoke({ messages: [{ role: "user", content: "What's my name?" }] });
// Agent 记不住！

// 正确：添加 checkpointer 和 thread_id
import { MemorySaver } from "@langchain/langgraph";

const agent = createAgent({
  model: "anthropic:claude-sonnet-4-5",
  tools: [search],
  checkpointer: new MemorySaver(),
});
const config = { configurable: { thread_id: "session-1" } };
await agent.invoke({ messages: [{ role: "user", content: "I'm Bob" }] }, config);
await agent.invoke({ messages: [{ role: "user", content: "What's my name?" }] }, config);
// Agent 记住了："Your name is Bob"
```
</typescript>
</fix-no-checkpointer>

<fix-infinite-loop>
<python>
在 invoke 配置中设置 recursion_limit，以防止 Agent 循环失控。

```python
# 错误：没有迭代限制 - 可能会无限循环
result = agent.invoke({"messages": [("user", "Do research")]})

# 正确：在 config 中设置 recursion_limit
result = agent.invoke(
    {"messages": [("user", "Do research")]},
    config={"recursion_limit": 10},  # 在 10 步后停止
)
```
</python>
<typescript>
在 invoke 配置中设置 recursionLimit，以防止 Agent 循环失控。

```typescript
// 错误：没有迭代限制
const result = await agent.invoke({ messages: [["user", "Do research"]] });

// 正确：在 config 中设置 recursionLimit
const result = await agent.invoke(
  { messages: [["user", "Do research"]] },
  { recursionLimit: 10 }, // 在 10 步后停止
);
```
</typescript>
</fix-infinite-loop>

<fix-accessing-result-wrong>
<python>
从结果中访问 messages 数组，而不是直接访问 result.content。

```python
# 错误：尝试直接访问 result.content
result = agent.invoke({"messages": [{"role": "user", "content": "Hello"}]})
print(result.content)  # AttributeError!

# 正确：从结果字典中访问 messages
result = agent.invoke({"messages": [{"role": "user", "content": "Hello"}]})
print(result["messages"][-1].content)  # 最后一条消息的内容
```
</python>
<typescript>
从结果中访问 messages 数组，而不是直接访问 result.content。

```typescript
// 错误：尝试直接访问 result.content
const result = await agent.invoke({ messages: [{ role: "user", content: "Hello" }] });
console.log(result.content); // undefined!

// 正确：从结果对象中访问 messages
const result = await agent.invoke({ messages: [{ role: "user", content: "Hello" }] });
console.log(result.messages[result.messages.length - 1].content); // 最后一条消息的内容
```
</typescript>
</fix-accessing-result-wrong>