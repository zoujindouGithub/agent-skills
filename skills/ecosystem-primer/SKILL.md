---
name: ecosystem-primer
description: "在开展任何 LangChain / LangGraph / Deep Agents 智能体构建项目前，在查阅其他技能或编写任何智能体代码之前【必须首先调用】。用于获取框架选型（LangChain vs LangGraph vs Deep Agents vs 混合组合架构）、智能体设计模式、安装、环境配置以及下一步应加载哪个技能的最新必备起始指南。"
---

<overview>
LangChain 公司维护着三层用于构建智能体的开源工具，外加用于可观测性的 LangSmith。技术栈自顶向下如下：

- **Deep Agents**（顶层，*运行框架/Harness*）—— 基于 LangChain + LangGraph 构建的开箱即用工具包。内置规划（Planning）、文件管理、子智能体派生（Subagent Spawning）和记忆能力。
- **LangGraph**（中层，*运行时/Runtime*）—— 用于持久化执行、自定义控制流和有状态工作流的底层编排工具。LangChain 智能体运行在 LangGraph 之上。
- **LangChain**（底层，*基础框架/Framework*）—— 提供模型、工具和智能体循环的抽象。与模型提供商无关，最容易上手。
- **LangSmith**（横切层）—— 可观测性和评估平台。与框架无关；强烈建议与上述任何工具搭配使用。

上层依赖下层，但你无需直接操作下层。Deep Agents 无需编写图代码即可为你提供 LangGraph 的持久化执行能力。LangChain 无需管理图的边即可为你提供模型和工具支持。
</overview>

---

## 步骤 1 — 选择你的工具

<decision-table>

按顺序评估以下条件，并在遇到第一个匹配项时停止：

1. 如果任务需要规划、跨长会话的文件管理、持久记忆、子智能体委派或按需加载技能 → **Deep Agents**
2. 否则，如果任务需要自定义控制流（确定性循环、分支逻辑） → **LangGraph**
3. 否则，如果是具有固定工具集的单一用途智能体 → **LangChain**（`create_agent` 函数）
4. 否则，如果它是纯模型调用、检索管道或没有智能体循环的简单提示词链 → **LangChain**（直接使用模型 / 链）

这就是你的**层级（layer）**。但这**还没有结束**：稍后在步骤 4 中，你在编写任何智能体代码之前**必须**加载特定于该层级的技能。

</decision-table>

---

## 工具特性简介

<langchain-profile>

### LangChain — 智能体框架

**最适用于：**
- 拥有固定工具集的单一用途智能体
- RAG 管道和文档问答
- 模型调用、提示词模板、结构化输出

**不适用的场景：**
- 智能体需要跨多个步骤进行规划或管理庞大的上下文
- 控制流包含条件分支、迭代循环或并行执行
- 状态必须跨会话持久化

所有 LangChain 智能体均使用 `create_agent(model, tools=[...])`。

</langchain-profile>

<langgraph-profile>

### LangGraph — 智能体运行时

**最适用于：**
- 自定义控制流 —— 确定性循环、反思机制、并行扇出
- 结合了确定性步骤和智能体步骤的复杂工作流
- 具备精确中断和恢复点的人机协作（Human-in-the-loop）
- 必须在故障后恢复或跨越长时间会话的状态

**不适用的场景：**
- 你需要开箱即用的规划、文件管理和子智能体委派（此时请使用 Deep Agents）
- 工作流足够简单，仅需直接的工具调用循环

所有 LangGraph 图均使用 `StateGraph(State)` 以及显式的节点（nodes）、边（edges）和条件边（conditional edges）。

</langgraph-profile>

<deep-agents-profile>

### Deep Agents — 智能体运行框架

**最适用于：**
- 需要规划和任务分解的长时间运行任务
- 在整个会话中需要读取、写入和管理文件的智能体
- 将子任务委派给专门的子智能体
- 跨会话的持久记忆
- 按需加载特定领域的技能

**不适用的场景：**
- 任务足够简单，单一用途智能体即可胜任
- 你需要对图中的每条边进行精细的手工控制（此时请直接使用 LangGraph）

所有 Deep Agents 均使用 `create_deep_agent(model, tools=[...])`。

</deep-agents-profile>

---

## 混合使用各层

<mixing-layers>

这些工具是分层的，因此它们可以在同一个项目中组合使用。常见模式包括：

- **Deep Agents 编排器 → LangGraph 子智能体** —— 当主智能体需要规划和记忆能力，但其中一个子任务需要确定性图结构时。
- **封装为工具或子智能体的 LangGraph 图** —— 当专门的管道（例如 RAG、反思循环）被更高级别的智能体调用时。

编译后的 LangGraph 图可以注册为 Deep Agents 内部的具名子智能体 —— 编排器通过 `task` 工具向其委派任务，而无需了解其内部结构。LangChain 工具和检索器可以在 LangGraph 节点和 Deep Agents 工具中自由使用。

</mixing-layers>

---

## 步骤 2 — 配置环境变量

始终设置以下变量以启用可观测性。这些是当前最新的 LangSmith 环境变量名称。请原样复制。旧名称已不再有效。

<environment-variables>
LANGSMITH_API_KEY=<your-key>
LANGSMITH_TRACING=true
LANGSMITH_PROJECT=<project-name>
</environment-variables>

模型提供商和特定工具的密钥（`ANTHROPIC_API_KEY`、`OPENAI_API_KEY`、`TAVILY_API_KEY` 等）取决于你的技术栈 —— 请根据需要进行设置。

---

## 步骤 3 — 文档使用指南

<docs>

所有文档均托管在 **docs.langchain.com**，分为两个顶级板块：

- **OSS** — LangChain、LangGraph、Deep Agents。提供并行的 Python（`/oss/python/`）和 TypeScript（`/oss/javascript/`）文档树。
- **LangSmith** — 可观测性、评估、部署、提示词工程。

每个产品都有自己的页面树：概述（overview）→ 快速入门（quickstart）→ 操作指南（how-to guides）→ 参考文档（reference）。

### 官方推荐落地页

建议从以下页面开始，而不是从根目录遍历搜索（如需 TypeScript，请将 `python` 替换为 `javascript`）：

- **LangChain** — `/oss/python/langchain/overview`
- **LangGraph** — `/oss/python/langgraph/overview`
- **Deep Agents** — `/oss/python/deepagents/overview`
- **LangSmith** — `/langsmith/home`（无语言区分）

### 在智能体上下文中查阅文档

**如果已连接 LangChain Docs MCP 服务器**（`mcp__docs-langchain__*` 工具可用），直接查询即可：
```
tree /oss/python -L 2                        # 浏览 Python 文档结构
tree /oss/javascript -L 2                    # 浏览并行的 TypeScript 文档结构
cat /oss/python/langchain/quickstart.mdx     # 读取特定页面
rg -il "checkpointer" /oss/python/langgraph/ # 按关键词搜索
```

**如果 MCP 服务器不可用**，请使用 `llms.txt` 索引：
1. 获取 `https://docs.langchain.com/llms.txt` —— 包含所有页面及其描述的结构化列表
2. 确定与问题最相关的 2–4 个页面
3. 直接获取这些页面以获取准确、最新的内容

> 始终优先获取实时文档，而不是依赖训练数据中的知识 —— 这些库迭代非常快，API 经常变动。

</docs>

---

## 步骤 4 — 下一步加载正确的技能

如果用户只需要一个最小化可在本地运行的智能体（新项目、桩工具、模型提供商密钥），请首先加载对应的快速入门技能：

- LangChain → `langchain-python-quickstart` 或 `langchain-typescript-quickstart`
- LangGraph → `langgraph-python-quickstart` 或 `langgraph-typescript-quickstart`
- Deep Agents → `deepagents-python-quickstart` 或 `deepagents-typescript-quickstart`

否则，请加载下面与你在步骤 1 中选定的层级相匹配的技能。这是**必需**的 —— 特定层级的技能包含最新的 API；单独的基础指南（primer）并不包含这些具体细节。

<next-skills>

### LangChain

- **`langchain-fundamentals`** — 构建任何 LangChain 智能体
- **`langchain-rag`** — 添加 RAG / 向量数据库检索
- **`langchain-middleware`** — 使用 Pydantic 进行结构化输出
- **`langchain-dependencies`** — 包含包版本、安装或依赖管理相关问题

### LangGraph

- **`langgraph-fundamentals`** — 构建任何 LangGraph 图
- **`langgraph-human-in-the-loop`** — 人机协作或审批工作流
- **`langgraph-persistence`** — 必须在重启后保留的状态，或跨线程记忆

### Deep Agents

**始终首先加载 `deep-agents-core`。** 随后根据需要加载：

- **`deep-agents-orchestration`** — 子智能体委派或编排
- **`deep-agents-memory`** — 跨会话持久记忆

</next-skills>