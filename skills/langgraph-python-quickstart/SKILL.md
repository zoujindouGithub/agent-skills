---
name: langgraph-python-quickstart
description: "按照官方快速入门指南，在 Python 中搭建最小化的本地 LangGraph Agent。当用户希望快速在本地构建或体验 LangGraph Agent 时使用。"
---

# LangGraph Python 快速入门

遵循实时官方文档 —— 切勿凭记忆捏造替代 API：

**https://docs.langchain.com/oss/python/langgraph/quickstart**

获取该页面（通过 Docs MCP 或 HTTP）并实现其展示的内容（使用 Graph API 实现计算器 / 数学 Agent）。除非用户另有要求，否则优先选择 Graph API 路径而非 Functional API。跳过 IPython 图形可视化。

## 本地配置限制

在快速入门的基础上应用以下规则（以保持最小化配置并与具体模型解耦）：

1. **询问**用户要使用哪个提供商/模型。展示 LangGraph 可与任何 LangChain 聊天模型配合使用。建议的提示词：

   > 该 Agent 应该使用哪个模型？请传入 `provider:model` 格式的字符串 —— 例如 `openai:gpt-5.5`、`anthropic:claude-sonnet-5`、`google_genai:gemini-2.5-flash-lite`。若不确定，默认使用：**`anthropic:claude-sonnet-5`**。

   文档中通常硬编码了 Anthropic —— 请根据用户的选择，替换为 `init_chat_model("<MODEL>")`（或等效代码）。如果使用 Claude Sonnet 5+，请省略 `temperature` / `top_p` / `top_k`（不支持）。

2. 创建一个**新**目录（例如 `langgraph-agent/`）并在其中完成所有工作 —— 切勿污染当前打开的项目。

3. 唯一的密钥配置：在 `.env` 中配置提供商 API 密钥（已加入 gitignore）。除非用户要求，否则无需配置 LangSmith / Tavily。建议用户自行编辑 `.env` —— 切勿将密钥直接粘贴到聊天中。

4. 安装快速入门所需的包，以及对应模型的提供商包。

5. 运行示例（例如“3 加 4 等于多少”），展示输出，然后结束。引导用户参考 `langgraph-fundamentals` 了解后续进阶步骤。如果需要更高级别的 Agent API，请改用 LangChain 的 `create_agent`。