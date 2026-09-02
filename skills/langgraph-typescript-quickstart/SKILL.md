---
name: langgraph-typescript-quickstart
description: "遵循官方快速入门指南，在 TypeScript 中脚手架搭建一个最小化的本地 LangGraph Agent。当用户希望在本地快速构建或体验 LangGraph Agent 时使用。"
---

# LangGraph TypeScript 快速入门

请遵循实时官方文档 —— 不要凭记忆虚构替代 API：

**https://docs.langchain.com/oss/javascript/langgraph/quickstart**

获取该页面（通过 Docs MCP 或 HTTP）并实现其中展示的内容（使用 Graph API 构建计算器 / 数学 Agent）。除非用户另有要求，否则优先使用 Graph API 路径而不是 Functional API。跳过图可视化步骤。

## 本地环境配置约束

在快速入门的基础上应用以下约束（以保持最小化配置且与模型无关）：

1. **询问**要使用的提供商/模型。展示 LangGraph 可以与任何 LangChain 聊天模型协同工作。建议提示词：

   > 该 Agent 应该使用哪个模型？请传入 `provider:model` 格式的字符串 —— 例如 `openai:gpt-5.5`、`anthropic:claude-sonnet-5`、`google-genai:gemini-2.5-flash-lite`。如果不确定，默认使用：**`anthropic:claude-sonnet-5`**。

   文档通常硬编码为 Anthropic —— 请根据用户的选择替换为 `initChatModel("<MODEL>")`（或等效代码）。如果使用 Claude Sonnet 5+，请忽略 `temperature` / `top_p` / `top_k`（不受支持）。

2. 创建一个**新**目录（例如 `langgraph-agent/`）并在其中完成所有操作 —— 不要污染当前打开的项目。

3. 唯一需要的密钥：`.env` 中的提供商 API 密钥（加入 gitignore）。除非用户要求，否则无需配置 LangSmith / Tavily。建议用户自行编辑 `.env` —— 不要将密钥直接粘贴到对话中。

4. 安装快速入门所需的包，以及对应其模型的提供商包。

5. 运行示例（例如“3 加 4 等于多少”），展示输出，然后停止。引导用户参考 `langgraph-fundamentals` 了解后续步骤。如果需要更高级别的 Agent API，请改用 LangChain 的 `createAgent`。