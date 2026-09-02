---
name: langchain-dependencies
description: "在初始化新项目或被问及关于 LangChain、LangGraph、LangSmith 或 Deep Agents 的包版本、安装或依赖管理时调用此 SKILL。涵盖 Python 和 TypeScript 两者的必需包、最低版本、环境要求、版本控制最佳实践以及常用社区工具包。"
---

<overview>
LangChain 生态系统被拆分为多个职责明确且独立进行版本控制的包。了解你需要哪些包及其版本约束，有助于防止不兼容问题并使依赖升级更加可控。

**核心原则：**
- **LangChain 1.0 是当前的长期支持（LTS）版本。** 新项目请始终基于 1.0+ 构建。LangChain 0.3 处于旧版维护阶段，仅接收安全修复——请勿将其用于新项目。
- **langchain-core** 是共享的基础库：请始终与其他任何包一起显式安装它。
- **langchain-community**（仅限 Python）**不遵循**语义化版本控制；请保守地锁定其版本。
- **LangGraph 与 Deep Agents 的选型：** 根据你的使用场景选择一种编排方案——它们是互为替代的方案，而非必须同时使用的技术栈（参见下方的 [框架选择](#framework-choice)）。
- 提供商集成（模型、向量数据库、工具）均单独安装，因此你只需引入实际使用的包。
</overview>

---

## 环境要求

<environment-requirements>

| 需求项 | Python | TypeScript / Node |
|-------------|--------|-------------------|
| 最低运行时版本 | **Python 3.10+** | **Node.js 20+** |
| LangChain | **1.0+ (LTS)** | **1.0+ (LTS)** |
| LangSmith SDK | >= 0.3.0 | >= 0.3.0 |

</environment-requirements>

---

## 框架选择

<framework-choice>
选择 **一种** Agent 编排层即可。无需两者同时引入。

| 框架 | 适用场景 | 核心附加包 |
|-----------|-------------|--------------------|
| **LangGraph** | 需要对图结构进行细粒度控制、自定义工作流、循环或分支 | `langgraph` / `@langchain/langgraph` |
| **Deep Agents** | 希望开箱即用内置的规划（Planning）、记忆（Memory）、文件上下文（File Context）和技能（Skills）能力 | `deepagents`（依赖 LangGraph，并会作为传递依赖自动安装） |

两者均构建于 `langchain` + `langchain-core` + `langsmith` 之上。
</framework-choice>

---

## 核心包

<python-packages>

### Python — 始终必需

| 包名 | 职责 | 最低版本 |
|---------|------|-------------|
| `langchain` | Agents、链（Chains）、检索（Retrieval） | 1.0 |
| `langchain-core` | 基础类型与接口（对等依赖） | 1.0 |
| `langsmith` | 链路追踪、评估、数据集 | 0.3.0 |

### Python — 编排层（二选一）

| 包名 | 适用场景 | 最低版本 |
|---------|----------|-------------|
| `langgraph` | 直接构建自定义图（Graphs） | 1.0 |
| `deepagents` | 使用 Deep Agents 框架 | latest |

### Python — 模型提供商（选择你实际使用的包）

| 包名 | 提供商 |
|---------|----------|
| `langchain-openai` | OpenAI (GPT-4o, o3, …) |
| `langchain-anthropic` | Anthropic (Claude) |
| `langchain-google-genai` | Google (Gemini) |
| `langchain-mistralai` | Mistral |
| `langchain-groq` | Groq（高速推理） |
| `langchain-cohere` | Cohere |
| `langchain-fireworks` | Fireworks AI |
| `langchain-together` | Together AI |
| `langchain-huggingface` | Hugging Face Hub |
| `langchain-ollama` | Ollama（本地模型） |
| `langchain-aws` | AWS Bedrock |
| `langchain-azure-ai` | Azure AI Foundry |

### Python — 常用工具与检索包

这些包具有更严格的兼容性要求——除非有特殊原因，建议始终使用最新的可用版本。

| 包名 | 附加功能 | 说明 |
|---------|------|-------|
| `langchain-tavily` | Tavily 网络搜索（`TavilySearch`） | 专属集成包；建议使用最新版 |
| `langchain-text-splitters` | 文本切分工具 | 遵循语义化版本，保持更新 |
| `langchain-community` | 1000+ 种集成（备选方案） | **不遵循语义化版本 — 需锁定到次版本系列** |
| `faiss-cpu` | FAISS 向量数据库（本地） | 通过 `langchain-community` 使用；使用最新版 |
| `langchain-chroma` | Chroma 向量数据库 | 专属集成包；建议使用最新版 |
| `langchain-pinecone` | Pinecone 向量数据库 | 专属集成包；建议使用最新版 |
| `langchain-qdrant` | Qdrant 向量数据库 | 专属集成包；建议使用最新版 |
| `langchain-weaviate` | Weaviate 向量数据库 | 专属集成包；建议使用最新版 |
| `langsmith[pytest]` | 用于 LangSmith 的 pytest 插件 | 需要 langsmith >= 0.3.4 |

> **langchain-community 稳定性说明：** 该包**不遵循**语义化版本控制。次版本（Minor）发布中可能包含破坏性变更。存在专属集成包时（例如 `langchain-chroma`、`langchain-tavily`），请优先使用专属包——它们具备独立版本控制且更加稳定。

</python-packages>

<typescript-packages>

### TypeScript — 始终必需

| 包名 | 职责 | 最低版本 |
|---------|------|-------------|
| `@langchain/core` | 基础类型与接口（对等依赖） | 1.0 |
| `langchain` | Agents、链（Chains）、检索（Retrieval） | 1.0 |
| `langsmith` | 链路追踪、评估、数据集 | 0.3.0 |

### TypeScript — 编排层（二选一）

| 包名 | 适用场景 | 最低版本 |
|---------|----------|-------------|
| `@langchain/langgraph` | 直接构建自定义图（Graphs） | 1.0 |
| `deepagents` | 使用 Deep Agents 框架 | latest |

### TypeScript — 模型提供商（选择你实际使用的包）

| 包名 | 提供商 |
|---------|----------|
| `@langchain/openai` | OpenAI (GPT-4o, o3, …) |
| `@langchain/anthropic` | Anthropic (Claude) |
| `@langchain/google-genai` | Google (Gemini) |
| `@langchain/mistralai` | Mistral |
| `@langchain/groq` | Groq（高速推理） |
| `@langchain/cohere` | Cohere |
| `@langchain/aws` | AWS Bedrock |
| `@langchain/azure-openai` | Azure OpenAI |
| `@langchain/ollama` | Ollama（本地模型） |

### TypeScript — 常用工具与检索包

| 包名 | 附加功能 | 说明 |
|---------|------|-------|
| `@langchain/tavily` | Tavily 网络搜索（`TavilySearch`） | 专属集成包；建议使用最新版 |
| `@langchain/community` | 广泛的社区集成集合 | 谨慎使用；优先使用专属集成包 |
| `@langchain/pinecone` | Pinecone 向量数据库 | 专属集成包；建议使用最新版 |
| `@langchain/qdrant` | Qdrant 向量数据库 | 专属集成包；建议使用最新版 |
| `@langchain/weaviate` | Weaviate 向量数据库 | 专属集成包；建议使用最新版 |

> 在 Yarn Workspaces 和 Monorepo 仓库中，**必须显式安装 `@langchain/core`**——作为对等依赖项，它并不总是会被自动提升（Hoist）。

</typescript-packages>

---

## 最小项目模板

<ex-langgraph-python>
<python>
LangGraph 项目的最小依赖集合（与模型提供商无关）。

```
# requirements.txt
langchain>=1.0,<2.0
langchain-core>=1.0,<2.0
langgraph>=1.0,<2.0
langsmith>=0.3.0

# 添加你使用的模型提供商，例如：
# langchain-openai
# langchain-anthropic
# langchain-google-genai
```
</python>
</ex-langgraph-python>

<ex-langgraph-typescript>
<typescript>
LangGraph 项目的 package.json 最小依赖配置（与模型提供商无关）。

```json
{
  "dependencies": {
    "@langchain/core": "^1.0.0",
    "langchain": "^1.0.0",
    "@langchain/langgraph": "^1.0.0",
    "langsmith": "^0.3.0"
  }
}
```
</typescript>
</ex-langgraph-typescript>

<ex-deepagents-python>
<python>
Deep Agents 项目的最小依赖集合（与模型提供商无关）。

```
# requirements.txt
deepagents            # 内部已打包 langgraph
langchain>=1.0,<2.0
langchain-core>=1.0,<2.0
langsmith>=0.3.0

# 添加你使用的模型提供商，例如：
# langchain-anthropic
# langchain-openai
```
</python>
</ex-deepagents-python>

<ex-deepagents-typescript>
<typescript>
Deep Agents 项目的 package.json 最小依赖配置（与模型提供商无关）。

```json
{
  "dependencies": {
    "deepagents": "latest",
    "@langchain/core": "^1.0.0",
    "langchain": "^1.0.0",
    "langsmith": "^0.3.0"
  }
}
```
</typescript>
</ex-deepagents-typescript>

<ex-with-tools-python>
<python>
为 LangGraph 项目添加 Tavily 搜索和向量数据库。

```
# requirements.txt
langchain>=1.0,<2.0
langchain-core>=1.0,<2.0
langgraph>=1.0,<2.0
langsmith>=0.3.0

# 网络搜索
langchain-tavily          # 使用最新版本；官方合作包，遵循语义化版本

# 向量数据库 — 选择一个：
langchain-chroma          # 使用最新版本；官方合作包，遵循语义化版本
# langchain-pinecone      # 使用最新版本；官方合作包，遵循语义化版本
# langchain-qdrant        # 使用最新版本；官方合作包，遵循语义化版本

# 文本处理
langchain-text-splitters  # 使用最新版本；遵循语义化版本

# 你的模型提供商：
# langchain-openai / langchain-anthropic / 等
```
</python>
</ex-with-tools-python>

<ex-with-tools-typescript>
<typescript>
为 LangGraph 项目添加 Tavily 搜索和向量数据库。

```json
{
  "dependencies": {
    "@langchain/core": "^1.0.0",
    "langchain": "^1.0.0",
    "@langchain/langgraph": "^1.0.0",
    "langsmith": "^0.3.0",
    "@langchain/tavily": "latest",
    "@langchain/pinecone": "latest"
  }
}
```
</typescript>
</ex-with-tools-typescript>

---

## 版本控制策略与升级指南

<versioning-policy>

| 软件包组 | 版本控制规范 | 安全升级策略 |
|---------------|------------|-----------------------|
| `langchain`, `langchain-core` | 严格语义化版本（1.0 LTS） | 允许次版本升级：`>=1.0,<2.0` |
| `langgraph` / `@langchain/langgraph` | 严格语义化版本（v1 LTS） | 允许次版本升级：`>=1.0,<2.0` |
| `langsmith` | 严格语义化版本 | 允许次版本升级：`>=0.3.0` |
| 专属集成包（如 `langchain-tavily`, `langchain-chroma`） | 独立版本控制 | 允许次版本升级；使用最新版 |
| `langchain-community` | **不遵循语义化版本** | 锁定具体次版本系列：`>=0.4.0,<0.5.0` |
| `deepagents` | 跟随项目发布节奏 | 在生产环境中锁定已测试的版本 |

对于所有遵循语义化版本控制的包，**破坏性变更仅发生在主版本号升级中**（1.x → 2.x）。已废弃的功能在整个 1.x 系列中仍可正常运行，并会伴随警告信息。

**优先使用专属集成包，而非 langchain-community。** 当专属包存在时（例如使用 `langchain-chroma` 替代 `langchain-community` 中的 Chroma 集成），请务必使用专属包——专属包具备独立版本控制且测试更完善。

**除非项目要求严格锁定的环境，社区工具包（Tavily、向量数据库等）应保持最新版本。** 这些包会随 LangChain/LangGraph 的更新频繁发布兼容性修复。

</versioning-policy>

---

## 环境变量

<environment-variables>
所有密钥均在运行时从环境中读取。仅需设置你实际使用的服务密钥。

```bash
# LangSmith（强烈建议配置以实现可观测性）
LANGSMITH_API_KEY=<your-key>
LANGSMITH_PROJECT=<project-name>   # 可选，默认为 "default"

# 模型提供商 — 设置你实际使用的提供商密钥
OPENAI_API_KEY=<your-key>
ANTHROPIC_API_KEY=<your-key>
GOOGLE_API_KEY=<your-key>
MISTRAL_API_KEY=<your-key>
GROQ_API_KEY=<your-key>
COHERE_API_KEY=<your-key>
FIREWORKS_API_KEY=<your-key>
TOGETHER_API_KEY=<your-key>
HUGGINGFACEHUB_API_TOKEN=<your-key>

# 常用工具/检索服务
TAVILY_API_KEY=<your-key>          # 用于 Tavily 搜索
PINECONE_API_KEY=<your-key>        # 用于 Pinecone
```
</environment-variables>

---

## 常见错误

<fix-legacy-version>
绝不要在新项目中引入 LangChain 0.3。其维护期仅持续至 2026 年 12 月。

```
# 错误做法：旧版本，无新特性，仅维护安全补丁
langchain>=0.3,<0.4

# 正确做法：LangChain 1.0 LTS
langchain>=1.0,<2.0
```
</fix-legacy-version>

<fix-community-unpinned>
`langchain-community` 在次版本升级时可能会破坏兼容性——它不遵循语义化版本控制。

```
# 错误做法：允许可能包含破坏性变更的次版本升级
langchain-community>=0.4

# 正确做法：锁定具体的次版本系列
langchain-community>=0.4.0,<0.5.0
```
同时建议：若存在对应的专属集成包，请切换使用（例如使用 `langchain-chroma` 替代 community 中的 Chroma 集成）。
</fix-community-unpinned>

<fix-community-tool-outdated>
社区工具包（如 `langchain-tavily` 和向量数据库集成）会伴随 LangChain 的更新发布兼容性修复。使用过旧的锁定版本可能导致导入错误或工具模式（Tool Schema）损坏。

```
# 风险做法：旧的锁定版本可能与 LangChain 1.0 不兼容
langchain-tavily==0.0.1

# 推荐做法：允许当前主版本内的最新版本
langchain-tavily>=0.1
```
</fix-community-tool-outdated>

<fix-community-import-deprecated>
许多以往位于 `langchain-community` 的工具现在都已拥有独立的专属包及更新后的导入路径。请始终优先从专属包中导入。

```python
# 错误做法 — 已弃用的 community 导入路径
from langchain_community.tools.tavily_search import TavilySearchResults
from langchain_community.tools import WikipediaQueryRun
from langchain_community.vectorstores import Chroma
from langchain_community.vectorstores import Pinecone

# 正确做法 — 使用专属包导入
from langchain_tavily import TavilySearch                  # pip: langchain-tavily（TavilySearchResults 已废弃）
from langchain_community.tools import WikipediaQueryRun  # 暂无专属包
from langchain_chroma import Chroma                       # pip: langchain-chroma
from langchain_pinecone import PineconeVectorStore        # pip: langchain-pinecone
```

要查找任何集成的当前规范导入方式，请查阅集成目录：
https://python.langchain.com/docs/integrations/tools/

每个条目都会标明正确的安装包和导入路径。如果存在专属包，请优先使用——虽然 community 路径可能仍然有效，但已被视为旧版遗产。
</fix-community-import-deprecated>

<fix-core-not-installed>
<typescript>
`@langchain/core` 是对等依赖（peer dependency）——它必须包含在你的 package.json 中，尤其是在 Monorepo 仓库中。

```json
// 错误做法：缺失 @langchain/core（在 yarn workspaces / 严格提升模式下会报错）
{
  "dependencies": {
    "@langchain/langgraph": "^1.0.0"
  }
}

// 正确做法：始终显式声明 @langchain/core
{
  "dependencies": {
    "@langchain/core": "^1.0.0",
    "@langchain/langgraph": "^1.0.0"
  }
}
```
</typescript>
</fix-core-not-installed>

<fix-python-version>
<python>
LangChain 1.0 不支持 Python 3.9 及以下版本。

```python
# 安装前进行校验
import sys
assert sys.version_info >= (3, 10), "LangChain 1.0 要求 Python 3.10+ 环境"
```
</python>
</fix-python-version>

<fix-node-version>
<typescript>
Node.js 20 以下版本未获得官方支持。

```bash
# 安装前进行校验
node --version   # 必须是 v20.x 或更高版本
```
</typescript>
</fix-node-version>