---
name: langchain-typescript-quickstart
description: "按照官方快速入门指南，在 TypeScript 中搭建一个极简的本地 LangChain 智能体（Agent）。当用户希望在本地快速构建或尝试 LangChain 智能体时使用。"
---

# LangChain TypeScript 快速入门

请遵循实时官方文档 — 切勿凭记忆捏造替代 API：

**https://docs.langchain.com/oss/javascript/langchain/quickstart**

获取该页面内容（通过 Docs MCP 或 HTTP）并实现其中展示的内容（天气智能体 + `createAgent`）。需要 Node 22+ 环境。

## 本地环境搭建约束

在快速入门的基础上应用以下规则（以保持极简配置并确保与模型无关）：

1. **询问**用户要使用哪个提供商/模型。展示 LangChain 与模型无关的特性。建议提示语：

   > 该智能体应使用哪个模型？请传入 `provider:model` 格式的字符串 — 例如 `openai:gpt-5.5`、`anthropic:claude-sonnet-5`、`google-genai:gemini-2.5-flash-lite`。如果不确定，默认使用：**`anthropic:claude-sonnet-5`**。

   将快速入门中的模型字符串替换为用户的选择（或默认值）。

2. 创建一个**新**目录（例如 `langchain-agent/`）并在其中完成所有工作 — 不要污染当前打开的项目。

3. 唯一的密钥配置：在 `.env` 中配置提供商 API 密钥（已加入 gitignore）。除非用户要求，否则无需配置 LangSmith / Tavily。建议让用户自行编辑 `.env` — 不要将密钥直接粘贴到聊天中。

4. 如果快速入门的基础安装包不够用，请安装其所选模型对应的提供商软件包。

5. 运行示例，展示输出结果，然后停止。引导用户查看 `langchain-fundamentals` 以了解后续步骤。