---
name: deepagents-python-quickstart
description: "遵循官方快速入门指南，在 Python 中搭建最小化的本地 Deep Agent，并使用模型提供商原生的网络搜索替代 Tavily。当用户希望在本地快速构建或体验 Deep Agent 时使用。"
---

# Deep Agents Python 快速入门

遵循实时官方文档 — 切勿凭记忆捏造替代 API：

**https://docs.langchain.com/oss/python/deepagents/quickstart**

获取该页面内容（通过 Docs MCP 或 HTTP）并实现其展示的研究型智能体（research-agent）结构（`create_deep_agent`、研究系统提示词、使用诸如“What is LangGraph?”之类的研究问题进行调用）。

## 本地配置约束

在快速入门指南的基础上应用以下约束（以保持配置的极简和模型无关性）：

1. **询问**用户要使用的模型提供商/模型。展示 Deep Agents 的模型无关特性。建议提示语：

   > 该智能体应使用哪个模型？请传入 `provider:model` 格式的字符串 — 例如 `openai:gpt-5.5`、`anthropic:claude-sonnet-5`、`google_genai:gemini-3.5-flash`。如果不确定，默认使用：**`anthropic:claude-sonnet-5`**。  
   > 我们将使用该提供商内置的网络搜索（无需单独的搜索 API 密钥）。

2. 创建一个**新**目录（例如 `deep-agent/`）并在其中完成所有工作 — 不要污染当前打开的项目。

3. **不要使用 Tavily**（或任何第三方搜索服务商）。使用所选提供商内置的网络搜索替代快速入门中的 `internet_search` / Tavily 工具。查阅该提供商的 LangChain chat 文档以获取最新的工具格式（编写时的示例如下 — 必要时请重新核对）：

   | 提供商 | 内置搜索工具 |
   |----------|----------------------|
   | Anthropic | `{"type": "web_search_20260209", "name": "web_search", "max_uses": 5}` |
   | OpenAI | `{"type": "web_search"}` |
   | Google | `{"google_search": {}}` |

   优先推荐 Anthropic / OpenAI / Google，以确保提供商原生搜索可用。唯一需要的密钥：在 `.env`（已添加到 gitignore）中配置该提供商的 API 密钥。除非用户要求，否则跳过 LangSmith 链路追踪配置。

4. 安装 `deepagents`（+ `python-dotenv`）以及对应模型的提供商依赖包 — 而不是 `tavily-python`。

5. 运行研究示例，展示输出结果，然后停止。后续步骤引导用户参考 `deep-agents-core` / 自定义配置 / 托管式 Deep Agents。