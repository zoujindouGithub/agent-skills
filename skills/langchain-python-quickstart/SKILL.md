---
name: langchain-python-quickstart
description: "按照官方快速入门指南，在 Python 中快速搭建一个最小化的本地 LangChain Agent。适用于用户希望在本地快速构建或体验 LangChain Agent 的场景。"
---

# LangChain Python 快速入门

请遵循实时官方文档 —— 切勿凭记忆捏造其他 API：

**https://docs.langchain.com/oss/python/langchain/quickstart**

获取该页面内容（通过 Docs MCP 或 HTTP）并实现其演示的功能（天气 Agent + `create_agent`）。

## 本地配置约束

在遵循快速入门的基础上应用以下规则（以保持最小化配置并兼顾模型无关性）：

1. **询问**用户要使用哪个提供商/模型。展示 LangChain 的模型无关（model-agnostic）特性。建议提示词：

   > 该 Agent 应该使用哪个模型？请提供一个 `provider:model` 格式的字符串 —— 例如 `openai:gpt-5.5`、`anthropic:claude-sonnet-5`、`google_genai:gemini-2.5-flash-lite`。如果不确定，默认使用：**`anthropic:claude-sonnet-5`**。

   将快速入门中的模型字符串替换为用户的选择（或默认值）。

2. 创建一个**新**目录（例如 `langchain-agent/`）并在其中完成所有工作 —— 切勿污染当前打开的项目。

3. 唯一需要的密钥：保存在 `.env`（已加入 gitignore）中的提供商 API 密钥。除非用户主动要求，否则不要引入 LangSmith / Tavily。优先建议用户自行编辑 `.env` —— 请勿将密钥直接粘贴到聊天中。

4. 如果快速入门的基础安装包无法满足需求，请安装其模型对应的提供商扩展包。

5. 运行示例，展示输出结果，然后停止。引导用户参考 `langchain-fundamentals` 以了解后续步骤。