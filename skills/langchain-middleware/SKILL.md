---
name: langchain-middleware
description: "当需要人机协同（HITL）审批、自定义中间件或结构化输出时调用此技能。涵盖用于危险工具调用人工审批的 HumanInTheLoopMiddleware、使用 Hook 创建自定义中间件、Command 恢复模式以及使用 Pydantic/Zod 的结构化输出。"
---

<overview>
生产级 LangChain Agent 的中间件模式：

- **HumanInTheLoopMiddleware** / **humanInTheLoopMiddleware**：在执行危险工具调用前暂停，等待人工审批
- **自定义中间件**：拦截工具调用以进行错误处理、日志记录和重试逻辑
- **Command 恢复**：在人工做出决策（批准、编辑、拒绝）后继续执行

**要求：** 所有 HITL 工作流都需要配置 Checkpointer + thread_id。
</overview>

---

## 人机协同（Human-in-the-Loop）

<ex-basic-hitl-setup>
<python>
设置带有 HITL 中间件的 Agent，在发送邮件前暂停以等待审批。

```python
from langchain.agents import create_agent
from langchain.agents.middleware import HumanInTheLoopMiddleware
from langgraph.checkpoint.memory import MemorySaver
from langchain.tools import tool

@tool
def send_email(to: str, subject: str, body: str) -> str:
    """发送一封电子邮件。"""
    return f"Email sent to {to}"

agent = create_agent(
    model="gpt-4.1",
    tools=[send_email],
    checkpointer=MemorySaver(),  # HITL 必须
    middleware=[
        HumanInTheLoopMiddleware(
            interrupt_on={
                "send_email": {"allowed_decisions": ["approve", "edit", "reject"]},
            }
        )
    ],
)
```
</python>
<typescript>
设置带有 HITL 的 Agent，在发送邮件前暂停以等待人工审批。

```typescript
import { createAgent, humanInTheLoopMiddleware } from "langchain";
import { MemorySaver } from "@langchain/langgraph";
import { tool } from "@langchain/core/tools";
import { z } from "zod";

const sendEmail = tool(
  async ({ to, subject, body }) => `Email sent to ${to}`,
  {
    name: "send_email",
    description: "Send an email",
    schema: z.object({ to: z.string(), subject: z.string(), body: z.string() }),
  }
);

const agent = createAgent({
  model: "anthropic:claude-sonnet-4-5",
  tools: [sendEmail],
  checkpointer: new MemorySaver(),
  middleware: [
    humanInTheLoopMiddleware({
      interruptOn: { send_email: { allowedDecisions: ["approve", "edit", "reject"] } },
    }),
  ],
});
```
</typescript>
</ex-basic-hitl-setup>

<ex-running-with-interrupts>
<python>
运行 Agent，检测中断，然后在人工审批后恢复执行。

```python
from langgraph.types import Command

config = {"configurable": {"thread_id": "session-1"}}

# 步骤 1：Agent 运行直至需要调用工具
result1 = agent.invoke({
    "messages": [{"role": "user", "content": "Send email to john@example.com"}]
}, config=config)

# 检查是否存在中断
if "__interrupt__" in result1:
    print(f"Waiting for approval: {result1['__interrupt__']}")

# 步骤 2：人工批准
result2 = agent.invoke(
    Command(resume={"decisions": [{"type": "approve"}]}),
    config=config
)
```
</python>
<typescript>
运行 Agent，检测中断，然后在人工审批后恢复执行。

```typescript
import { Command } from "@langchain/langgraph";

const config = { configurable: { thread_id: "session-1" } };

// 步骤 1：Agent 运行直至需要调用工具
const result1 = await agent.invoke({
  messages: [{ role: "user", content: "Send email to john@example.com" }]
}, config);

// 检查是否存在中断
if (result1.__interrupt__) {
  console.log(`Waiting for approval: ${result1.__interrupt__}`);
}

// 步骤 2：人工批准
const result2 = await agent.invoke(
  new Command({ resume: { decisions: [{ type: "approve" }] } }),
  config
);
```
</typescript>
</ex-running-with-interrupts>

<ex-editing-tool-arguments>
<python>
当原始参数需要更正时，在批准前编辑工具参数。

```python
# 人工编辑参数 —— edited_action 必须包含 name + args
result2 = agent.invoke(
    Command(resume={
        "decisions": [{
            "type": "edit",
            "edited_action": {
                "name": "send_email",
                "args": {
                    "to": "alice@company.com",  # 修正后的邮箱
                    "subject": "Project Meeting - Updated",
                    "body": "...",
                },
            },
        }]
    }),
    config=config
)
```
</python>
<typescript>
当原始参数需要更正时，在批准前编辑工具参数。

```typescript
// 人工编辑参数 —— editedAction 必须包含 name + args
const result2 = await agent.invoke(
  new Command({
    resume: {
      decisions: [{
        type: "edit",
        editedAction: {
          name: "send_email",
          args: {
            to: "alice@company.com",  // 修正后的邮箱
            subject: "Project Meeting - Updated",
            body: "...",
          },
        },
      }]
    }
  }),
  config
);
```
</typescript>
</ex-editing-tool-arguments>

<ex-rejecting-with-feedback>
<python>
拒绝工具调用并提供反馈以解释拒绝原因。

```python
# 人工拒绝
result2 = agent.invoke(
    Command(resume={
        "decisions": [{
            "type": "reject",
            "feedback": "Cannot delete customer data without manager approval",
        }]
    }),
    config=config
)
```
</python>
</ex-rejecting-with-feedback>

<ex-multiple-tools-different-policies>
<python>
根据风险等级为每个工具配置不同的 HITL 策略。

```python
agent = create_agent(
    model="gpt-4.1",
    tools=[send_email, read_email, delete_email],
    checkpointer=MemorySaver(),
    middleware=[
        HumanInTheLoopMiddleware(
            interrupt_on={
                "send_email": {"allowed_decisions": ["approve", "edit", "reject"]},
                "delete_email": {"allowed_decisions": ["approve", "reject"]},  # 不允许编辑
                "read_email": False,  # 读取操作不需要 HITL
            }
        )
    ],
)
```
</python>
</ex-multiple-tools-different-policies>

<boundaries>
### 支持配置的功能

- 哪些工具需要审批（针对单个工具的策略）
- 每个工具允许的决策类型（approve、edit、reject）
- 自定义中间件 Hook：`before_model`、`after_model`、`wrap_tool_call`、`before_agent`、`after_agent`
- 工具级中间件（仅应用于特定工具）
</boundaries>

---

## 自定义中间件 Hook

提供六个装饰器 Hook，分为两种模式：

- **包装型 Hook（Wrap hooks）**（`wrap_tool_call`、`wrap_model_call`）：`(request, handler)` —— 调用 `handler(request)` 继续执行，或提前返回以短路中断。
- **前置/后置 Hook（Before/after hooks）**（`before_model`、`after_model`、`before_agent`、`after_agent`）：`(state, runtime)` —— 检查或修改状态。返回 `None` 或包含状态更新的字典。

<ex-wrap-tool-call>
<python>
`@wrap_tool_call` 用于拦截工具执行。**请勿使用 `yield`** —— 它会创建生成器并导致 `NotImplementedError`。

```python
from langchain.agents.middleware import wrap_tool_call

@wrap_tool_call
def retry_middleware(request, handler):
    for attempt in range(3):
        try:
            return handler(request)
        except Exception:
            if attempt == 2:
                raise

@wrap_tool_call
def guard_middleware(request, handler):
    if request.tool_call["name"] == "dangerous_tool":
        return "This tool is disabled"  # 短路中断
    return handler(request)
```
</python>
<typescript>
`createMiddleware({ wrapToolCall })` 用于拦截工具执行。

```typescript
import { createMiddleware } from "langchain";

const retryMiddleware = createMiddleware({
  wrapToolCall: async (request, handler) => {
    for (let attempt = 0; attempt < 3; attempt++) {
      try { return await handler(request); }
      catch (e) { if (attempt === 2) throw e; }
    }
  },
});
```
</typescript>
</ex-wrap-tool-call>

<ex-before-after-hooks>
<python>
`before_model` / `after_model` / `before_agent` / `after_agent` 均采用 `(state, runtime)` 签名。

```python
from langchain.agents.middleware import before_model, after_model

@before_model
def log_calls(state, runtime):
    print(f"Calling model with {len(state['messages'])} messages")

@after_model
def check_output(state, runtime):
    print(f"Model responded")
```
</python>
<typescript>
所有前置/后置 Hook 在 `createMiddleware` 中均采用相同的 `(state, runtime)` 签名。

```typescript
import { createMiddleware } from "langchain";

const loggingMiddleware = createMiddleware({
  beforeModel: (state, runtime) => {
    console.log(`Calling model with ${state.messages.length} messages`);
  },
  afterModel: (state, runtime) => {
    console.log("Model responded");
  },
});
```
</typescript>
</ex-before-after-hooks>

<boundaries>
### 不支持配置的功能

- 在工具执行后中断（必须在执行前中断）
- 在 HITL 中跳过 Checkpointer 的要求
</boundaries>

<fix-missing-checkpointer>
<python>
HITL 中间件需要 Checkpointer 来持久化状态。

```python
# 错误
agent = create_agent(model="gpt-4.1", tools=[send_email], middleware=[HumanInTheLoopMiddleware({...})])

# 正确
agent = create_agent(
    model="gpt-4.1", tools=[send_email],
    checkpointer=MemorySaver(),  # 必需
    middleware=[HumanInTheLoopMiddleware({...})]
)
```
</python>
<typescript>
HITL 需要 Checkpointer 来持久化状态。

```typescript
// 错误：缺少 checkpointer
const agent = createAgent({
  model: "anthropic:claude-sonnet-4-5", tools: [sendEmail],
  middleware: [humanInTheLoopMiddleware({ interruptOn: { send_email: true } })],
});

// 正确：添加 checkpointer
const agent = createAgent({
  model: "anthropic:claude-sonnet-4-5", tools: [sendEmail],
  checkpointer: new MemorySaver(),
  middleware: [humanInTheLoopMiddleware({ interruptOn: { send_email: true } })],
});
```
</typescript>
</fix-missing-checkpointer>

<fix-no-thread-id>
<python>
使用 HITL 时始终需要提供 thread_id 以跟踪对话状态。

```python
# 错误
agent.invoke(input)  # 未传入 config！

# 正确
agent.invoke(input, config={"configurable": {"thread_id": "user-123"}})
```
</python>
</fix-no-thread-id>

<fix-wrong-resume-syntax>
<python>
在中断后使用 Command 类恢复执行。

```python
# 错误
agent.invoke({"resume": {"decisions": [...]}})

# 正确
from langgraph.types import Command
agent.invoke(Command(resume={"decisions": [{"type": "approve"}]}), config=config)
```
</python>
<typescript>
在中断后使用 Command 类恢复执行。

```typescript
// 错误
await agent.invoke({ resume: { decisions: [...] } });

// 正确
import { Command } from "@langchain/langgraph";
await agent.invoke(new Command({ resume: { decisions: [{ type: "approve" }] } }), config);
```
</typescript>
</fix-wrong-resume-syntax>