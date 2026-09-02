---
name: deep-agents-orchestration
description: "在 Deep Agents 中使用子智能体（subagents）、任务规划或人工审批时调用此 SKILL。涵盖 SubAgentMiddleware、用于规划的 TodoList 以及 HITL 中断机制。"
---

<overview>
Deep Agents 包含三种编排能力：

1. **SubAgentMiddleware**：通过 `task` 工具将工作委托给专用子智能体
2. **TodoListMiddleware**：通过 `write_todos` 工具规划和跟踪任务
3. **HumanInTheLoopMiddleware**：在执行敏感操作前需要人工审批

这三项功能均已自动包含在 `create_deep_agent()` 中。
</overview>

---

## 子智能体（任务委托）

<when-to-use-subagents>

| 何时使用子智能体 | 何时使用主智能体 |
|-------------------|-------------------|
| 任务需要专用工具 | 通用工具已足够 |
| 希望隔离复杂工作 | 单步操作 |
| 主智能体需要保持上下文清晰干净 | 上下文膨胀可接受 |

</when-to-use-subagents>

<how-subagents-work>
主智能体拥有 `task` 工具 -> 创建全新的子智能体 -> 子智能体自主执行 -> 返回最终报告。

**默认子智能体**："general-purpose"（通用型）- 自动可用，拥有与主智能体相同的工具和配置。
</how-subagents-work>

<ex-custom-subagents>
<python>
创建一个自定义的 "researcher" 子智能体，配备用于学术论文检索的专用工具。

```python
from deepagents import create_deep_agent
from langchain.tools import tool

@tool
def search_papers(query: str) -> str:
    """搜索学术论文。"""
    return f"Found 10 papers about {query}"

agent = create_deep_agent(
    subagents=[
        {
            "name": "researcher",
            "description": "开展网络研究并汇总结果",
            "system_prompt": "深入检索，返回简明扼要的总结",
            "tools": [search_papers],
        }
    ]
)

# 主智能体进行委托：task(agent="researcher", instruction="Research AI trends")
```
</python>
<typescript>
创建一个自定义的 "researcher" 子智能体，配备用于学术论文检索的专用工具。

```typescript
import { createDeepAgent } from "deepagents";
import { tool } from "@langchain/core/tools";
import { z } from "zod";

const searchPapers = tool(
  async ({ query }) => `Found 10 papers about ${query}`,
  { name: "search_papers", description: "Search papers", schema: z.object({ query: z.string() }) }
);

const agent = await createDeepAgent({
  subagents: [
    {
      name: "researcher",
      description: "开展网络研究并汇总结果",
      systemPrompt: "深入检索，返回简明扼要的总结",
      tools: [searchPapers],
    }
  ]
});

// 主智能体进行委托：task(agent="researcher", instruction="Research AI trends")
```
</typescript>
</ex-custom-subagents>

<ex-subagent-with-hitl>
<python>
为子智能体配置敏感操作的 HITL 审批。

```python
from deepagents import create_deep_agent
from langgraph.checkpoint.memory import MemorySaver

agent = create_deep_agent(
    subagents=[
        {
            "name": "code-deployer",
            "description": "部署代码到生产环境",
            "system_prompt": "你在测试通过后部署代码。",
            "tools": [run_tests, deploy_to_prod],
            "interrupt_on": {"deploy_to_prod": True},  # 需要审批
        }
    ],
    checkpointer=MemorySaver()  # 中断功能所必需
)
```
</python>
</ex-subagent-with-hitl>

<fix-subagents-are-stateless>
<python>
子智能体是无状态的 - 需在单次调用中提供完整的指令。

```python
# 错误做法：子智能体不会记住先前的调用
# task(agent='research', instruction='Find data')
# task(agent='research', instruction='What did you find?')  # 会重新从头开始！

# 正确做法：预先提供完整的指令
# task(agent='research', instruction='Find data on AI, save to /research/, return summary')
```
</python>
<typescript>
子智能体是无状态的 - 需在单次调用中提供完整的指令。

```typescript
// 错误做法：子智能体不会记住先前的调用
// task research: Find data
// task research: What did you find?  // 会重新从头开始！

// 正确做法：预先提供完整的指令
// task research: Find data on AI, save to /research/, return summary
```
</typescript>
</fix-subagents-are-stateless>

<fix-custom-subagents-dont-inherit-skills>
<python>
自定义子智能体不会继承主智能体的技能（skills）。

```python
# 错误做法：自定义子智能体不会拥有主智能体的技能
agent = create_deep_agent(
    skills=["/main-skills/"],
    subagents=[{"name": "helper", ...}]  # 未继承任何技能
)

# 正确做法：显式提供技能（通用型 general-purpose 子智能体确实会继承）
agent = create_deep_agent(
    skills=["/main-skills/"],
    subagents=[{"name": "helper", "skills": ["/helper-skills/"], ...}]
)
```
</python>
</fix-custom-subagents-dont-inherit-skills>

---

## 待办列表（任务规划）

<when-to-use-todolist>

| 何时使用 TodoList | 何时跳过 TodoList |
|------------------|-------------------|
| 复杂的多步骤任务 | 简单的单步操作任务 |
| 长时间运行的操作 | 快速操作（少于 3 步） |

</when-to-use-todolist>

<todolist-tool>

```
write_todos(todos: list[dict]) -> None
```

每个待办事项包含：
- `content`：任务描述
- `status`：`"pending"`、`"in_progress"`、`"completed"` 之一
</todolist-tool>

<ex-todolist-usage>
<python>
调用智能体，自动为多步骤任务创建待办列表。

```python
from deepagents import create_deep_agent

agent = create_deep_agent()  # 默认包含 TodoListMiddleware

result = agent.invoke({
    "messages": [{"role": "user", "content": "Create a REST API: design models, implement CRUD, add auth, write tests"}]
}, config={"configurable": {"thread_id": "session-1"}})

# 智能体通过 write_todos 进行的规划：
# [
#   {"content": "Design data models", "status": "in_progress"},
#   {"content": "Implement CRUD endpoints", "status": "pending"},
#   {"content": "Add authentication", "status": "pending"},
#   {"content": "Write tests", "status": "pending"}
# ]
```
</python>
<typescript>
调用智能体，自动为多步骤任务创建待办列表。

```typescript
import { createDeepAgent } from "deepagents";

const agent = await createDeepAgent();  // 已包含 TodoListMiddleware

const result = await agent.invoke({
  messages: [{ role: "user", content: "Create a REST API: design models, implement CRUD, add auth, write tests" }]
}, { configurable: { thread_id: "session-1" } });
```
</typescript>
</ex-todolist-usage>

<ex-access-todo-state>
<python>
在调用后从智能体的最终状态中访问待办列表。

```python
result = agent.invoke({...}, config={"configurable": {"thread_id": "session-1"}})

# 从最终状态中访问待办列表
todos = result.get("todos", [])
for todo in todos:
    print(f"[{todo['status']}] {todo['content']}")
```
</python>
</ex-access-todo-state>

<fix-todolist-requires-thread-id>
<python>
待办列表状态需要 thread_id 才能在多次调用之间实现持久化。

```python
# 错误做法：没有 thread_id，每次都是全新状态
agent.invoke({"messages": [...]})

# 正确做法：使用 thread_id
config = {"configurable": {"thread_id": "user-session"}}
agent.invoke({"messages": [...]}, config=config)  # 待办事项得以保留
```
</python>
</fix-todolist-requires-thread-id>

---

## 人在回路（审批工作流）

<when-to-use-hitl>

| 何时使用 HITL | 何时跳过 HITL |
|--------------|---------------|
| 高风险操作（数据库写入、部署等） | 只读操作 |
| 合规要求必须有人工监督 | 全自动化工作流 |

</when-to-use-hitl>

<ex-hitl-setup>
<python>
配置哪些工具在执行前需要人工审批。

```python
from deepagents import create_deep_agent
from langgraph.checkpoint.memory import MemorySaver

agent = create_deep_agent(
    interrupt_on={
        "write_file": True,  # 允许所有决策类型
        "execute_sql": {"allowed_decisions": ["approve", "reject"]},
        "read_file": False,  # 不中断
    },
    checkpointer=MemorySaver()  # 中断功能所必需
)
```
</python>
<typescript>
配置哪些工具在执行前需要人工审批。

```typescript
import { createDeepAgent } from "deepagents";
import { MemorySaver } from "@langchain/langgraph";

const agent = await createDeepAgent({
  interruptOn: {
    write_file: true,
    execute_sql: { allowedDecisions: ["approve", "reject"] },
    read_file: false,
  },
  checkpointer: new MemorySaver()  // 必需项
});
```
</typescript>
</ex-hitl-setup>

<ex-approval-workflow>
<python>
完整工作流：触发中断、检查状态、批准操作并恢复执行。

```python
from deepagents import create_deep_agent
from langgraph.checkpoint.memory import MemorySaver
from langgraph.types import Command

agent = create_deep_agent(
    interrupt_on={"write_file": True},
    checkpointer=MemorySaver()
)

config = {"configurable": {"thread_id": "session-1"}}

# 步骤 1：智能体提议执行 write_file - 执行暂停
result = agent.invoke({
    "messages": [{"role": "user", "content": "Write config to /prod.yaml"}]
}, config=config)

# 步骤 2：检查是否存在中断
state = agent.get_state(config)
if state.next:
    print(f"Pending action")

# 步骤 3：批准并恢复执行
result = agent.invoke(Command(resume={"decisions": [{"type": "approve"}]}), config=config)
```
</python>
<typescript>
完整工作流：触发中断、检查状态、批准操作并恢复执行。

```typescript
import { createDeepAgent } from "deepagents";
import { MemorySaver, Command } from "@langchain/langgraph";

const agent = await createDeepAgent({
  interruptOn: { write_file: true },
  checkpointer: new MemorySaver()
});

const config = { configurable: { thread_id: "session-1" } };

// 步骤 1：智能体提议执行 write_file - 执行暂停
let result = await agent.invoke({
  messages: [{ role: "user", content: "Write config to /prod.yaml" }]
}, config);

// 步骤 2：检查是否存在中断
const state = await agent.getState(config);
if (state.next) {
  console.log("Pending action");
}

// 步骤 3：批准并恢复执行
result = await agent.invoke(
  new Command({ resume: { decisions: [{ type: "approve" }] } }), config
);
```
</typescript>
</ex-approval-workflow>

<ex-reject-with-feedback>
<python>
附带反馈拒绝待处理操作，提示智能体尝试其他方法。

```python
result = agent.invoke(
    Command(resume={"decisions": [{"type": "reject", "message": "Run tests first"}]}),
    config=config,
)
```
</python>
<typescript>
附带反馈拒绝待处理操作，提示智能体尝试其他方法。

```typescript
const result = await agent.invoke(
  new Command({ resume: { decisions: [{ type: "reject", message: "Run tests first" }] } }),
  config,
);
```
</typescript>
</ex-reject-with-feedback>

<ex-edit-before-execution>
<python>
在允许执行前编辑提议操作的参数。

```python
result = agent.invoke(
    Command(resume={"decisions": [{
        "type": "edit",
        "edited_action": {
            "name": "execute_sql",
            "args": {"query": "DELETE FROM users WHERE last_login < '2020-01-01' LIMIT 100"},
        },
    }]}),
    config=config,
)
```
</python>
</ex-edit-before-execution>

<boundaries>
### 智能体可以配置的内容

- 子智能体名称、工具、模型、系统提示词（system prompts）
- 哪些工具需要审批
- 每个工具允许的决策类型
- TodoList 的内容和结构

### 智能体不可配置的内容

- 工具名称（`task`、`write_todos`）
- HITL 协议（approve/edit/reject 结构）
- 跳过中断所需的 checkpointer 配置
- 让子智能体变为有状态（它们是临时无状态的）
</boundaries>

<fix-checkpointer-required>
<python>
在 HITL 工作流中使用 interrupt_on 时，checkpointer 是必需的。

```python
# 错误做法
agent = create_deep_agent(interrupt_on={"write_file": True})

# 正确做法
agent = create_deep_agent(interrupt_on={"write_file": True}, checkpointer=MemorySaver())
```
</python>
<typescript>
在 HITL 工作流中使用 interruptOn 时，checkpointer 是必需的。

```typescript
// 错误做法
const agent = await createDeepAgent({ interruptOn: { write_file: true } });

// 正确做法
const agent = await createDeepAgent({ interruptOn: { write_file: true }, checkpointer: new MemorySaver() });
```
</typescript>
</fix-checkpointer-required>

<fix-thread-id-required-for-resumption>
<python>
恢复被中断的工作流需要一致的 thread_id。

```python
# 错误做法：没有 thread_id 无法恢复
agent.invoke({"messages": [...]})

# 正确做法
config = {"configurable": {"thread_id": "session-1"}}
agent.invoke({...}, config=config)
# 使用包含相同 config 的 Command 恢复执行
agent.invoke(Command(resume={"decisions": [{"type": "approve"}]}), config=config)
```
</python>
<typescript>
恢复被中断的工作流需要一致的 thread_id。

```typescript
// 错误做法：没有 thread_id 无法恢复
await agent.invoke({ messages: [...] });

// 正确做法
const config = { configurable: { thread_id: "session-1" } };
await agent.invoke({ messages: [...] }, config);
// 使用包含相同 config 的 Command 恢复执行
await agent.invoke(new Command({ resume: { decisions: [{ type: "approve" }] } }), config);
```
</typescript>
</fix-thread-id-required-for-resumption>

<fix-interrupt-checks-between-invocations>
<python>
中断发生在 invoke() 调用之间，而不是执行中间。

```python
result = agent.invoke({...}, config=config)       # 步骤 1：触发中断
if "__interrupt__" in result:                      # 步骤 2：检查是否存在中断
    result = agent.invoke(                         # 步骤 3：恢复执行
        Command(resume={"decisions": [{"type": "approve"}]}),
        config=config,
    )
```
</python>
</fix-interrupt-checks-between-invocations>