---
name: deepagents-typescript-quickstart
description: "遵循官方快速入门指南，在 TypeScript 中搭建一个最小化的本地 Deep Agent，使用模型提供商原生的网络搜索替代 Tavily。当用户想要在本地快速构建或尝试 Deep Agent 时使用。"
---

# Deep Agents TypeScript 快速入门

请遵循实时官方文档 — 切勿凭记忆捏造替代 API：

**https://docs.langchain.com/oss/javascript/deepagents/quickstart**

获取该页面内容（通过 Docs MCP 或 HTTP）并实现其中展示的研究型 Agent 架构（`createDeepAgent`、研究系统提示词，使用类似“What is LangGraph?”的研究问题进行调用）。需要 Node 22+ 环境。

## 本地配置约束

在快速入门的基础上应用以下约束（以保持最简配置并实现模型无关性）：

1. **询问**用户要使用的模型提供商/模型。展示 Deep Agents 的模型无关特性。建议提示语：

   > 该 Agent 应该使用哪个模型？请传入 `provider:model` 格式的字符串 — 例如 `openai:gpt-5.5`、`anthropic:claude-sonnet-5`、`google-genai:gemini-3.5-flash`。如果不确定，默认使用：**`anthropic:claude-sonnet-5`**。  
   > 我们将使用该提供商内置的网络搜索（无需单独的搜索 API 密钥）。

2. 创建一个**新**目录（例如 `deep-agent/`）并在其中完成所有工作 — 不要污染当前打开的项目。

3. **不要使用 Tavily**（或 `@langchain/tavily`）。将快速入门中的搜索工具替换为所选提供商内置的网络搜索。在对应提供商的 LangChain 文档中查阅当前的导出/工具定义格式（以下为编写时的示例 — 必要时请重新核对）：

   | 提供商 | 内置搜索工具 |
   |----------|----------------------|
   | Anthropic | `@langchain/anthropic` `tools.webSearch_*()`（或等效的字典/对象） |
   | OpenAI | `{ type: "web_search" }` |
   | Google | `{ google_search: {} }` |

   优先推荐 Anthropic / OpenAI / Google，以便使用提供商原生的搜索能力。唯一的密钥配置：在 `.env` 中设置该提供商的 API 密钥（并加入 gitignore）。除非用户明确要求，否则跳过 LangSmith 追踪配置。

4. 安装快速入门中列出的依赖包，**排除** Tavily；并添加与其模型对应的提供商依赖包。

5. 运行研究示例，展示输出，然后结束。引导用户参考 `deep-agents-core` / 自定义配置 / 托管型 Deep Agents（Managed Deep Agents）以了解后续步骤。