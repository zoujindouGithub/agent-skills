---
name: deep-agents-core
description: "在构建任何 Deep Agents 应用程序时调用此技能。涵盖 create_deep_agent()、测试框架架构、SKILL.md 格式以及配置选项。"
---

<overview>
Deep Agents 是一个构建在 LangChain/LangGraph 之上的具有明确设计理念的 Agent 框架，内置以下中间件：

- **任务规划**：TodoListMiddleware 用于拆解复杂任务
- **上下文管理**：带有可插拔后端的文件系统工具
- **任务委派**：SubAgent 中间件用于生成专用子 Agent
- **长期记忆**：通过 Store 实现跨线程的持久化存储
- **人机协同（Human-in-the-loop）**：针对敏感操作的审批工作流
- **技能（Skills）**：按需加载专用能力

Agent 运行环境（harness）会自动提供这些能力——你只需进行配置，无需自行实现。
</overview>

<when-to-use>

| 何时使用 Deep Agents | 何时使用 LangChain 的 create_agent |
|---------------------|-----------------------------------|
| 需要规划的多步骤任务 | 简单的单用途任务 |
| 需要文件管理的大上下文 | 上下文可容纳于单个提示词中 |
| 需要专用子 Agent | 单个 Agent 即可胜任 |
| 跨会话的持久化记忆 | 短暂的单会话任务 |

</when-to-use>

<middleware-selection>

| 如果你需要... | 中间件 | 说明 |
|--------------|--------|------|
| 跟踪复杂任务 | TodoListMiddleware | 默认启用 |
| 管理文件上下文 | FilesystemMiddleware | 配置后端 |
| 委派工作 | SubAgentMiddleware | 添加自定义子 Agent |
| 添加人工审批 | HumanInTheLoopMiddleware | 需要 checkpointer |
| 加载技能 | SkillsMiddleware | 提供技能目录 |
| 访问记忆 | MemoryMiddleware | 需要 Store 实例 |

</middleware-selection>

<ex-basic-agent>
<python>
创建一个带有自定义工具的基础 deep agent 并使用用户消息调用它。

```python
from deepagents import create_deep_agent
from langchain.tools import tool

@tool
def get_weather(city: str) -> str:
    """获取指定城市的天气。"""
    return f"{city}的天气总是阳光明媚"

agent = create_deep_agent(
    model="claude-sonnet-4-5-20250929",
    tools=[get_weather],
    system_prompt="你是一个乐于助人的助手"
)

config = {"configurable": {"thread_id": "user-123"}}
result = agent.invoke({
    "messages": [{"role": "user", "content": "东京的天气怎么样？"}]
}, config=config)
```
</python>
<typescript>
创建一个带有自定义工具的基础 deep agent 并使用用户消息调用它。

```typescript
import { createDeepAgent } from "deepagents";
import { tool } from "@langchain/core/tools";
import { z } from "zod";

const getWeather = tool(
  async ({ city }) => `${city}的天气总是阳光明媚`,
  { name: "get_weather", description: "获取指定城市的天气", schema: z.object({ city: z.string() }) }
);

const agent = await createDeepAgent({
  model: "claude-sonnet-4-5-20250929",
  tools: [getWeather],
  systemPrompt: "你是一个乐于助人的助手"
});

const config = { configurable: { thread_id: "user-123" } };
const result = await agent.invoke({
  messages: [{ role: "user", content: "东京的天气怎么样？" }]
}, config);
```
</typescript>
</ex-basic-agent>

<ex-full-configuration>
<python>
使用所有可用选项配置 deep agent，包括子 Agent、技能和持久化。

```python
from deepagents import create_deep_agent
from deepagents.backends import FilesystemBackend
from langgraph.checkpoint.memory import MemorySaver
from langgraph.store.memory import InMemoryStore

agent = create_deep_agent(
    name="my-assistant",
    model="claude-sonnet-4-5-20250929",
    tools=[custom_tool1, custom_tool2],
    system_prompt="自定义指令",
    subagents=[research_agent, code_agent],
    backend=FilesystemBackend(root_dir=".", virtual_mode=True),
    interrupt_on={"write_file": True},
    skills=["./skills/"],
    checkpointer=MemorySaver(),
    store=InMemoryStore()
)
```
</python>
<typescript>
使用所有可用选项配置 deep agent，包括子 Agent、技能和持久化。

```typescript
import { createDeepAgent, FilesystemBackend } from "deepagents";
import { MemorySaver, InMemoryStore } from "@langchain/langgraph";

const agent = await createDeepAgent({
  name: "my-assistant",
  model: "claude-sonnet-4-5-20250929",
  tools: [customTool1, customTool2],
  systemPrompt: "自定义指令",
  subagents: [researchAgent, codeAgent],
  backend: new FilesystemBackend({ rootDir: ".", virtualMode: true }),
  interruptOn: { write_file: true },
  skills: ["./skills/"],
  checkpointer: new MemorySaver(),
  store: new InMemoryStore()
});
```
</typescript>
</ex-full-configuration>

<built-in-tools>
每个 deep agent 都可以访问：

1. **规划**：`write_todos` - 跟踪多步骤任务
2. **文件系统**：`ls`、`read_file`、`write_file`、`edit_file`、`glob`、`grep`
3. **委派**：`task` - 生成专用子 Agent
</built-in-tools>

---

## SKILL.md 格式

<skill-md-format>
技能采用**渐进式披露（progressive disclosure）**机制——Agent 仅在相关时才加载内容。

### 目录结构

```
skills/
└── my-skill/
    ├── SKILL.md        # 必需：主技能文件
    ├── examples.py     # 可选：支持文件
    └── templates/      # 可选：模板
```

### SKILL.md 格式

```markdown
---
name: my-skill
description: 清晰、具体地描述该技能的功能
---

# 技能名称

## 概述
简要说明该技能的目的。

## 何时使用
该技能适用的条件。

## 说明指南
为 Agent 提供的逐步操作指南。
```
</skill-md-format>

<skills-vs-memory>

| 技能（Skills） | 记忆（AGENTS.md） |
|---------------|-------------------|
| 按需加载 | 启动时始终加载 |
| 任务特定指令 | 通用偏好设置 |
| 大型文档 | 紧凑上下文 |
| 目录中的 SKILL.md | 单个 AGENTS.md 文件 |

</skills-vs-memory>

<ex-skills-with-filesystem-backend>
<python>
为 Agent 配置技能目录和文件系统后端，以实现技能的按需加载。

```python
from deepagents import create_deep_agent
from deepagents.backends import FilesystemBackend
from langgraph.checkpoint.memory import MemorySaver

agent = create_deep_agent(
    backend=FilesystemBackend(root_dir=".", virtual_mode=True),
    skills=["./skills/"],
    checkpointer=MemorySaver()
)

result = agent.invoke({
    "messages": [{"role": "user", "content": "使用 python-testing 技能"}]
}, config={"configurable": {"thread_id": "session-1"}})
```
</python>
<typescript>
为 Agent 配置技能目录和文件系统后端，以实现技能的按需加载。

```typescript
import { createDeepAgent, FilesystemBackend } from "deepagents";
import { MemorySaver } from "@langchain/langgraph";

const agent = await createDeepAgent({
  backend: new FilesystemBackend({ rootDir: ".", virtualMode: true }),
  skills: ["./skills/"],
  checkpointer: new MemorySaver()
});

const result = await agent.invoke({
  messages: [{ role: "user", content: "使用 python-testing 技能" }]
}, { configurable: { thread_id: "session-1" } });
```
</typescript>
</ex-skills-with-filesystem-backend>

<ex-skills-with-store-backend>
<python>
将技能内容加载到 Store 后端中，适用于没有文件系统访问权限的环境。

```python
from deepagents import create_deep_agent
from deepagents.backends import StoreBackend
from deepagents.backends.utils import create_file_data
from langgraph.store.memory import InMemoryStore

store = InMemoryStore()

# 将技能内容加载到 store 中
skill_content = """---
name: python-testing
description: 使用 pytest 进行 Python 测试的最佳实践
---
# Python Testing Skill
..."""

store.put(
    namespace=("filesystem",),
    key="/skills/python-testing/SKILL.md",
    value=create_file_data(skill_content)
)

agent = create_deep_agent(
    backend=lambda rt: StoreBackend(rt),
    store=store,
    skills=["/skills/"]
)
```
</python>
</ex-skills-with-store-backend>

<boundaries>

### Agent 可以配置的内容

- 模型选择和参数
- 额外的自定义工具
- 系统提示词自定义
- 后端存储策略
- 哪些工具需要审批
- 带有专用工具的自定义子 Agent

### Agent 不能配置的内容

- 核心中间件的移除（TodoList、Filesystem、SubAgent 始终存在）
- write_todos、task 或文件系统工具的名称
- SKILL.md frontmatter 格式
</boundaries>

<fix-checkpointer-for-interrupts>
<python>
中断（interrupts）需要配置 checkpointer。

```python
# 错误
agent = create_deep_agent(interrupt_on={"write_file": True})

# 正确
agent = create_deep_agent(interrupt_on={"write_file": True}, checkpointer=MemorySaver())
```
</python>
<typescript>
中断（interrupts）需要配置 checkpointer。

```typescript
// 错误
const agent = await createDeepAgent({ interruptOn: { write_file: true } });

// 正确
const agent = await createDeepAgent({ interruptOn: { write_file: true }, checkpointer: new MemorySaver() });
```
</typescript>
</fix-checkpointer-for-interrupts>

<fix-store-for-memory>
<python>
StoreBackend 需要 Store 实例来实现跨线程的持久化记忆。

```python
# 错误
agent = create_deep_agent(backend=lambda rt: StoreBackend(rt))

# 正确
agent = create_deep_agent(backend=lambda rt: StoreBackend(rt), store=InMemoryStore())
```
</python>
<typescript>
StoreBackend 需要 Store 实例来实现跨线程的持久化记忆。

```typescript
// 错误
const agent = await createDeepAgent({ backend: (config) => new StoreBackend(config) });

// 正确
const agent = await createDeepAgent({ backend: (config) => new StoreBackend(config), store: new InMemoryStore() });
```
</typescript>
</fix-store-for-memory>

<fix-thread-id-for-conversations>
<python>
使用一致的 thread_id 在多次调用之间保持对话上下文。

```python
# 错误：每次调用都是相互隔离的
agent.invoke({"messages": [{"role": "user", "content": "Hi"}]})
agent.invoke({"messages": [{"role": "user", "content": "What did I say?"}]})

# 正确
config = {"configurable": {"thread_id": "user-123"}}
agent.invoke({"messages": [...]}, config=config)
agent.invoke({"messages": [...]}, config=config)
```
</python>
<typescript>
使用一致的 thread_id 在多次调用之间保持对话上下文。

```typescript
// 错误：每次调用都是相互隔离的
await agent.invoke({ messages: [{ role: "user", content: "Hi" }] });
await agent.invoke({ messages: [{ role: "user", content: "What did I say?" }] });

// 正确
const config = { configurable: { thread_id: "user-123" } };
await agent.invoke({ messages: [...] }, config);
await agent.invoke({ messages: [...] }, config);
```
</typescript>
</fix-thread-id-for-conversations>

<fix-frontmatter-required>

```markdown
# 错误：SKILL.md 中缺少 frontmatter
# My Skill
This is my skill...

# 正确：包含 YAML frontmatter
---
name: my-skill
description: 包含 pytest fixture 和 mock 的 Python 测试最佳实践
---
# My Skill
This is my skill...
```
</fix-frontmatter-required>

<fix-backend-for-skills>
<python>
技能需要合适的后端才能从文件系统中加载。

```python
# 错误：没有合适的后端，技能将无法加载
agent = create_deep_agent(skills=["./skills/"])

# 正确：本地技能使用 FilesystemBackend
agent = create_deep_agent(
    backend=FilesystemBackend(root_dir=".", virtual_mode=True),
    skills=["./skills/"]
)
```
</python>
</fix-backend-for-skills>

<fix-specific-skill-descriptions>
使用具体的描述来帮助 Agent 确定何时使用该技能。

```markdown
# 错误：描述模糊
---
name: helper
description: 有用的技能
---

# 正确：描述具体
---
name: python-testing
description: 包含 pytest fixture、mock 和异步模式的 Python 测试最佳实践
---
```
</fix-specific-skill-descriptions>

<fix-subagent-skills>
<python>
子 Agent 不会继承技能——必须显式提供。

```python
# 错误：自定义子 Agent 不会继承技能
agent = create_deep_agent(
    skills=["/main-skills/"],
    subagents=[{"name": "helper", ...}]  # 没有技能
)

# 正确：显式提供技能
agent = create_deep_agent(
    skills=["/main-skills/"],
    subagents=[{"name": "helper", "skills": ["/helper-skills/"], ...}]
)
```
</python>
</fix-subagent-skills>