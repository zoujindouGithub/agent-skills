---
name: managed-deep-agents
description: "当使用 mda CLI 在 LangSmith 中构建、测试或部署托管深度智能体（Managed Deep Agents）时调用此技能。引导用户端到端完成其第一个智能体的构建——调研其构建需求，将其映射到 MDA 实际支持的功能，然后进行脚手架搭建与部署。内容涵盖基于文件的项目布局；define_deep_agent / defineDeepAgent；指令（instructions）、技能（skills）、记忆（memory）、身份认证（identity）、工具（tools）、中间件（middleware）、沙箱（sandboxes）、定时调度（schedules）、通道（channels）以及评测（evals）；mda init/build/dev/deploy/logs/delete 命令；以及 Context Hub。"
---

# 托管深度智能体 (Managed Deep Agents)

## 概述

托管深度智能体（Managed Deep Agents，简称 MDA）是 LangSmith 中面向“代码优先（code-first）”深度智能体的托管运行时。你可以使用 Python 或 TypeScript 编写智能体，通过 `mda dev` 在本地进行测试，并使用 `mda deploy` 进行发布。它将开源的 Deep Agents 框架（参见 [[deep-agents-core]]）与托管基础设施相结合：持久化运行、沙箱、基于 Context Hub 的指令和技能、记忆、链路追踪（traces）以及托管的 LangGraph 部署。

其核心理念是**智能体即目录**。文件的存放位置决定了其角色，CLI 会将该目录编译为一个托管的 LangGraph 应用。

MDA 目前处于**公开公测阶段（public beta）**，且**仅运行在 US LangSmith Cloud（美区）**。

## 适用场景

当用户希望通过代码构建深度智能体并在 LangSmith 上运行（无需自行运维服务器），或为其添加工具、中间件、记忆、身份认证、定时调度、通道、技能、沙箱或评测时，请使用此技能。

当用户需要自定义应用程序代码、自定义 HTTP 路由、除 LangSmith 密钥或 Supabase 之外的身份认证、更强的隔离性、最大化的可扩展性或美区以外的其他地域时，应改用标准 LangSmith 部署（参见 [[langgraph-cli]] 中的 `langgraph deploy`）。

---

# 引导用户构建其第一个智能体

当用户刚接触 MDA，或提出类似“帮我构建一个智能体”的请求时，**不要立即生成项目脚手架**。请遵循以下流程。只需提问两三个问题，即可避免构建出平台无法托管的内容。

```text
询问用户想构建什么 -> 对照限制进行核对 -> 确认架构方案
-> 生成脚手架 -> 接入最简可行代码 -> mda dev -> 部署
```

## 1. 询问用户想构建什么

使用通俗易懂的语言提问，不要使用 MDA 专业术语。用户此时还不了解什么是“通道（channel）”或“沙箱（sandbox）”。

首先询问以下两个问题：

- **该智能体需要实现什么功能？**（“回答关于我们文档的问题”、“对收到的 Bug 进行分类排查”、“每天早上发送一份摘要”。）
- **谁或什么会与它交互，从哪里交互？**（用户在浏览器中、其应用程序的用户、Slack 工作区、无人交互——按定时器自动运行。）

然后仅提出由上述答案直接引发的后续问题：

- 它是否需要在不同的独立对话之间记住某些信息？
- 它是否需要访问私有 API、数据库或内部服务？
- 在执行某些操作之前，是否需要人工审批？
- 它是否需要写入文件或运行代码？

一旦能够明确所需的功能特性，即可停止提问。通常两到三个问题就足够了。

## 2. 对照平台限制核对需求

在做出任何承诺之前，请先对照下方的 **[MDA 不支持的功能](#mda-不支持的功能)** 核对需求。如果请求中的某部分超出了支持范围，请用一句话说明，提供最接近的受支持替代方案，并继续处理其余部分。切勿默默构建一个功能缩水的智能体并将其冒充为用户要求的内容。

常见的重定向情况：如果用户需要自定义 HTTP 路由、自建认证体系或非美区托管，请告知他们 MDA 不适用于该层级，并指引他们使用 `langgraph deploy`（[[langgraph-cli]]）。

## 3. 将需求映射为具体功能特性

| 用户描述的需求 | 采用的组件/机制 | 存放位置 |
| --- | --- | --- |
| 行为方式、语气、遵循的规则 | 指令 (Instructions) | `instructions.md` |
| 调用我们的 API / 数据库 / 内部服务 | 自定义编写的工具 (Authored tools) | `tools/` |
| 针对特定任务应遵循的标准化流程 | 技能 (Skills) | `skills/<name>/SKILL.md` |
| 跨对话记住信息 | 持久化记忆 (Durable memory，请阅读警告) | `memory.py` |
| 定时运行，无需用户发送消息 | 定时调度 (Schedules) | `schedules/<name>.py` |
| 运行在 Slack 中 | 通道 (Channels) | `channels/slack.py` |
| 写入文件、运行代码或 Shell 命令 | 沙箱 (Sandbox) | `sandbox/__init__.py` |
| 在执行 X 操作之前向我请示 | 人机协同 (Human-in-the-loop) | `interrupt_on=` |
| 用户之间不得查看彼此的对话 | Supabase 身份认证 | `identity.py` |
| 必须返回结构化数据而非纯文本 | 结构化输出 (Structured output) | `response_format=` |
| 移交处理专业化任务 | 子智能体 (Subagents) | `subagents=` |
| PII 脱敏、调用限制、重试、日志记录 | 中间件 (Middleware) | `middleware/` |
| 验证在迭代变更过程中功能依然正常 | Harbor 评测 (Harbor evals) | `evals/tasks/` |

## 4. 在编写文件前确认架构方案

用一个简短的代码块复述计划并征得用户同意。指明所使用的模型，并仅列出你实际将要创建的功能特性：

```text
research-assistant, Python, 运行于 anthropic:claude-sonnet-4-6
  instructions.md   调研与引用规则
  tools/search.py   网络搜索
  schedules/        工作日早 8 点摘要
  无记忆，无沙箱，无通道
```

## 5. 生成脚手架并接入最简可行代码

使用与计划匹配的标志（flags）生成脚手架，使项目从一开始就保持准确，而不是后续再进行修剪改动：

```bash
mda init research-assistant --model anthropic:claude-sonnet-4-6
cd research-assistant
uv sync
```

然后**逐一**添加功能特性，并在添加下一个特性之前确认当前特性工作正常。一个包含良好指令和一个真实工具的初版智能体，远比一个每个目录都填满的脚手架更适合作为起点。

切勿创建计划中未要求的目录。空置或未使用的 `skills/`、`channels/` 或 `schedules/` 目录会带来干扰；而用户并不需要的 `sandbox/` 目录则会开启一个他们不得不额外费心关注的沙箱（使用 `mda init --no-sandbox` 可跳过沙箱创建）。

## 6. 处理密钥且不触碰用户敏感凭据

`mda init` 会生成带有空占位符的 `.env` 文件。填写项目所需的*变量名称*，并让用户自行粘贴*具体值*：

- 切勿自行将真实的凭据值写入 `.env`，也不要从其他项目目录复制密钥。
- 切勿将密钥值打印到终端或输出在你的回复中。
- 确认 `.gitignore` 包含了 `.env` 和 `.env.*`（`mda init` 已默认配置）。

项目需要 `LANGSMITH_API_KEY`（用于部署）以及模型所需的提供商密钥（`ANTHROPIC_API_KEY`、`OPENAI_API_KEY` 等）。取消对应提供商行的注释，并提示用户粘贴这两项密钥。

## 7. 本地运行，随后部署

```bash
mda dev .       # 编译、打开 LangSmith Studio、支持热重载
mda deploy .    # 同步 Context Hub、上传、等待状态变为 DEPLOYED
```

在部署之前，让用户实际在 Studio 中发送一条消息，确认智能体成功调用了工具。`mda deploy` 会输出部署控制台的 URL；打开该链接可查看构建记录、修订版本和链路追踪。

---

## MDA 不支持的功能

在同意构建之前，请*务必*对照此列表核对需求。尽早坦白限制比在部署时才发现问题的代价要低得多。

| 限制项 | 影响/后果 |
| --- | --- |
| 仅限 US LangSmith Cloud（美区） | 不支持自托管、混合部署或欧洲（EU）区域。需要使用 `langgraph deploy`。 |
| CLI 优先，处于公开公测阶段 | 没有公开的创建/更新/调用 REST API 接口。公测期间未公开从自定义应用程序调用已部署智能体的文档——请告知用户联系其 LangChain 团队。 |
| 无 MCP 连接器 | `connectors/mcp.*` 和 `define_mcp_servers` 接口已**移除**。请勿编写相关代码。应改为为智能体提供自定义编写的工具。 |
| Slack 是唯一的通道 | 不支持 Discord、Teams、电子邮件或短信（SMS）通道。 |
| 记忆为部署级共享 | **所有**调用方共用同一个 `/memories/agent/` 目录树。不存在单用户独立的记忆。 |
| 身份认证仅限 LangSmith 密钥或 Supabase | 不支持 OIDC、SAML 或自定义 JWT 签发者。实现用户独立的私有会话线程必须使用 Supabase。 |
| 仅限 LangSmith 沙箱 | 不支持其他沙箱提供商。 |
| 每个项目仅限一个智能体入口 | 单个项目中不能包含多个 Graph。委托任务请使用 `subagents=`。 |
| 定时调度必须为静态字面量 | 调度声明中不得使用环境变量、函数调用或计算出的动态值。 |
| 构建产物压缩包上限为 200 MB | 项目中包含大型测试固件（fixtures）或模型权重会导致部署失败。 |
| 托管字段不可由用户自行配置 | `backend`、`store`、`checkpointer`、`memory`、`skills` 以及系统提示词均由运行时自动注入。 |

## 前提条件

- 拥有 Managed Deep Agents 公测访问权限的工作区，以及该工作区的 LangSmith API 密钥。
- Python 项目需安装 Python 和 [`uv`](https://docs.astral.sh/uv/)；TypeScript 项目需安装 Node.js 和 npm。
- 模型提供商的 API 密钥。

安装 CLI。两个包均提供相同的 `mda` 可执行文件：

```bash
uv tool install --prerelease allow managed-deepagents   # Python
npm install -g managed-deepagents@dev                    # TypeScript
```

`mda init` 会生成带有自身依赖清单的项目——在执行 `mda dev` 之前，请*在该项目内部*运行 `uv sync`（或 `npm install`）。

## 项目布局

传递给 `mda` 的路径即为项目根目录。文件的存放位置决定了其角色：

```text
my-agent/
  agent.py | agent.ts              # 必需：导出命名的 `agent`

  instructions.md                  # 系统提示词 -> Context Hub
  skills/<name>/SKILL.md           # 任务专属标准化流程 -> Context Hub

  tools/                           # 智能体导入的自定义工具
  middleware/                      # 智能体导入的自定义中间件

  identity.py | identity.ts        # 谁有权调用该部署
  memory.py | memory.ts            # 按需启用的持久化记忆
  channels/<name>.py               # 外部消息通道（Slack）
  schedules/<name>.py              # 托管的 Cron 定时调度
  sandbox/__init__.py | index.ts   # 托管沙箱

  pyproject.toml | package.json    # 项目依赖配置
  .env                             # 认证 + 运行时密钥，绝不会被打包归档

  evals/tasks/<task>/              # Harbor 评测任务，不进行部署
```

仅智能体入口文件是必需的。`tools/` 和 `middleware/` 仅为常规目录约定——MDA 会原样复制项目文件，因此智能体导入的任何本地模块均可正常工作。其他路径在存在时会具有托管意义。TypeScript 声明文件也支持 `.tsx`、`.mts` 和 `.cts`。

## 定义智能体

智能体入口返回的是运行前规范（pre-runtime spec），而非已编译的 Graph。

```python
# agent.py
from managed_deepagents import define_deep_agent

from tools.search import web_search

agent = define_deep_agent(
    name="research-assistant",
    model="anthropic:claude-sonnet-4-6",
    tools=[web_search],
)
```

```ts
// agent.ts
import { defineDeepAgent } from "managed-deepagents";

import { webSearch } from "./tools/search";

export const agent = defineDeepAgent({
  name: "research-assistant",
  model: "anthropic:claude-sonnet-4-6",
  tools: [webSearch],
});
```

**`name` 为必填项。** 请传入一个以字母开头且仅包含字母、数字、下划线或连字符的静态字符串。它将作为 LangGraph 助手 ID 和默认部署名称；后者可以通过 `mda deploy --name` 进行覆盖。

**开发者可配置字段：** `name`、`model`、`tools`、`middleware`、`subagents`、`permissions`、`interrupt_on` / `interruptOn`、`response_format` / `responseFormat`、`context_schema` / `contextSchema`、`cache`、`debug`、`metadata`。

**托管字段——切勿自行设置：** `backend`、`store`、`checkpointer`、`memory`、`skills`、`system_prompt` / `systemPrompt`。

模型 ID 使用 `{provider}:{model_id}` 格式，并通过 `init_chat_model` 进行解析，因此其支持的所有提供商均可使用。注意提供商标识符在不同语言中有所不同：Python 使用 `google_genai:gemini-3.6-flash`，TypeScript 使用 `google-genai:gemini-3.6-flash`。当需要在代码中配置模型参数时，可以传入 Chat Model 实例而不是字符串。

如需通过 LangSmith Gateway 路由（获取速率限制、故障回退、按工作区结算额度等功能），请在初始化时使用 `mda init <name> --gateway`。Gateway 模型标识使用 `provider/model-name`，而非 `provider:model-name`。

## 指令 (Instructions)

项目根目录下的 `instructions.md` 即为系统提示词。它会在每次运行时注入。

```markdown
# 调研助手

你是一名严谨的调研助手。负责寻找信息来源、记录笔记并提供带有引用的简明回答。

## 行为规范

- 使用 `web_search` 工具查找来源，严禁主观臆测。
- 注明你所使用的信息来源。
```

`mda dev` 会在本地嵌入该文件。`mda deploy` 会将其同步至 Context Hub，之后可在 LangSmith UI 中直接编辑而无需重新部署。

## 技能 (Skills)

归部署所有的任务流程存放在 `skills/<name>/SKILL.md` 下，每个文件都包含 `name` 和 `description` 的 frontmatter。启动时，智能体只能看到技能名称和描述，仅当任务匹配时才会读取完整文件——因此在需要之前，详细流程不会占用任何上下文。技能目录还可以存放脚本、参考资料和模板；可在 `SKILL.md` 中引用它们。

部署操作会将 `skills/` 下的所有 UTF-8 文件同步到 Context Hub，并删除本地已不存在但已部署的技能文件。智能体无法修改技能。

对于始终生效的行为使用**指令（instructions）**，对于按需加载的流程使用**技能（skills）**，对于智能体自行更新的知识使用**记忆（memory）**。

## 记忆 (Memory)

持久化记忆是**可选的，且默认处于关闭状态**。在项目根目录下进行声明：

```python
# memory.py
from managed_deepagents import define_memory

memory = define_memory(scope="agent")
```

```ts
// memory.ts
import { defineMemory } from "managed-deepagents";

export const memory = defineMemory({ scope: "agent" });
```

删除该文件即可关闭记忆功能。启用后，系统会在 `/memories/agent/` 下挂载一个 Context Hub 目录树：

- `/memories/agent/AGENTS.md` 为**热记忆（hot memory）**——每次运行都会加载，因此请保持其内容精炼。
- 该目录树下的其他文件为**冷记忆（cold memory）**——仅在相关时读取。

智能体通过 `read_file`、`edit_file` 和 `write_file` 读写记忆。写入其他任何位置（包括 `/memories/` 下的其他子路径）均不具备持久性。

> **警告——记忆由该部署的所有调用方共享，且每个调用方均可影响记忆内容。** 严禁在其中存储个人数据、客户数据、凭据、API 密钥或 Token。应将记忆内容视为不可信输入：绝不能通过记忆赋予权限、更改工具权限或绕过审批——这些必须硬编码在智能体定义中。如果调用方之间不应相互影响，切勿启用共享记忆。

智能体根据提示词决定要记住什么内容，因此请在 `instructions.md` 中阐明记忆策略——哪些内容可以存储、哪些绝不能存储，并说明已有记忆仅作为参考笔记而非系统指令。

## 身份认证 (Identity)

`identity.py` 用于控制谁可以调用该部署。`mda init` 会生成一个安全的默认配置：

```python
# identity.py
from managed_deepagents import auth, define_identity

identity = define_identity(auth=auth.langsmith_api_key())
```

调用方需在请求头中以 `x-api-key` 形式发送 LangSmith 工作区 API 密钥。这解决了*调用方是否有权限访问*的问题——但它**不会**为每个人分配私有线程。持有该密钥的任何人均可访问该部署。

对于需要拥有私有线程的已登录终端用户，请使用 Supabase：

```python
identity = define_identity(auth=auth.supabase(project_ref="your-project-ref"))
```

此时客户端需发送 `Authorization: Bearer <access_token>`；MDA 会根据该项目的 JWKS URL 验证 JWT。在此模式下，客户端仅可发送 Supabase 可公开（anon）密钥用于登录——绝不能发送 LangSmith 密钥。

> 为现有部署添加 Supabase 身份认证**不会**回填现有会话线程的拥有者元数据。在依赖基于身份的访问控制之前，请规划并测试数据迁移。

认证失败将返回 401；跨用户访问线程将返回 403。

## 工具 (Tools)

在项目中定义 LangChain 工具，将其导入智能体入口文件，并传入 `tools` 列表。

```python
# tools/customer.py
from langchain.tools import tool


@tool(parse_docstring=True)
def lookup_customer(customer_id: str) -> str:
    """根据 ID 查询客户记录。

    Args:
        customer_id: CRM 中的客户 ID。
    """
    return f"客户 {customer_id} 为企业版套餐。"
```

```ts
// tools/customer.ts
import { tool } from "langchain";
import { z } from "zod";

export const lookupCustomer = tool(
  async ({ customerId }) => `客户 ${customerId} 为企业版套餐。`,
  {
    name: "lookup_customer",
    description: "根据 ID 查询客户记录。",
    schema: z.object({ customerId: z.string().describe("CRM 中的客户 ID。") }),
  },
);
```

模块导入方式与普通本地项目完全一致。请使用清晰、唯一的工具名称以避免命名冲突。工具从环境变量中读取部署密钥；本地调试值放入 `.env` 中。对于单次运行的专属参数（如请求元数据或特性开关），请使用标准的 LangChain 运行时上下文 API。

在受支持的情况下，可以以内联形式传递提供商服务端工具——例如 OpenAI 的 `tools=[{"type": "web_search"}]`——这样可以免去配置第二套 API 密钥。

## 中间件 (Middleware)

中间件用于包装模型调用、工具调用和生命周期钩子。执行顺序由列表中的先后顺序明确指定；MDA 绝不会自动推断顺序。可以使用预构建的 LangChain 中间件或自行编写（参见 [[langchain-middleware]]）。

```python
from langchain.agents.middleware import ModelCallLimitMiddleware, PIIMiddleware
from managed_deepagents import define_deep_agent

agent = define_deep_agent(
    name="support-agent",
    model="anthropic:claude-sonnet-4-6",
    middleware=[
        PIIMiddleware("email", strategy="redact", apply_to_input=True),
        ModelCallLimitMiddleware(run_limit=50),
    ],
)
```

中间件非常适合用于 PII 处理、速率限制、重试、模型故障回退、动态模型选择以及工具调用监控。

## 沙箱 (Sandboxes)

沙箱为智能体提供隔离的文件系统和 Shell 环境。`mda init` 默认会生成沙箱；**删除 `sandbox/` 目录即可取消配置**，这对于只需要提示词、工具和记忆的智能体而言是正确的选择。

```python
# sandbox/__init__.py
from managed_deepagents import define_sandbox

sandbox = define_sandbox(
    scope="thread",
    idle_ttl_seconds=600,
    default_timeout=600,
)
```

```ts
// sandbox/index.ts
import { defineSandbox } from "managed-deepagents";

export const sandbox = defineSandbox({
  scope: "thread",
  idleTtlSeconds: 600,
  defaultTimeout: 600,
});
```

`scope="thread"`（默认值）会为每个持久化线程创建一个独立的沙箱。`scope="agent"` 则跨线程共享单个文件系统——**请仅在需要有意共享状态时使用**，因为各线程将能够相互读取和修改文件。创建来源需通过 `template_name` *或* `snapshot_id` 指定，二者不可兼得。

智能体通过 `ls`、`read_file`、`write_file`、`edit_file`、`glob`、`grep` 和 `execute` 操作沙箱。可使用 `instructions.md` 规定其工作目录以及禁止触碰的文件。执行 `mda delete` 时也会一并删除托管的沙箱。

在 `mda dev` 期间，如果提供商不可用，运行时会回退到本地临时目录并打印路径。该回退仅用于开发调试——请在开发部署环境中验证真实的沙箱行为。

## 定时调度 (Schedules)

`schedules/` 下每个文件对应一个定时调度，每个文件需导出一个命名的 `schedule`。文件名即为调度名称。

```python
# schedules/daily_digest.py
from managed_deepagents import define_schedule

schedule = define_schedule(
    cron="0 8 * * 1-5",
    timezone="America/Los_Angeles",
    prompt="总结昨天学到的内容并列出未解决的问题。",
)
```

必须在 `prompt`（转换为用户消息）或 `input`（结构化 LangGraph 输入）中**恰好定义其中一个**。`cron` 必须是标准的五位表达式；如果不指定 `timezone`，Cron 将按 UTC 时间运行。

定时调度默认使用临时线程（ephemeral threads）——每次运行创建全新线程，运行结束后即删除。仅当运行需要累积持久线程状态时，才传入 `thread={"mode": "persistent", "id": "..."}`。设置 `deliver_to` 可将结果投递到配置好的 Slack 通道中。

调度声明在编译时**无需运行代码即可直接提取**：因此只能使用字面量和顶级字面量常量。不得使用环境变量、函数调用或 `**kwargs`。

`mda deploy` 会在部署就绪后对调度进行对齐同步（reconcile）——它会删除 MDA 管理的历史 Cron 并根据当前文件重新创建，因此删除文件并重新部署即可移除对应的 Cron。**`--no-wait` 会完全跳过调度同步**，因此在添加、修改或删除调度时切勿使用该参数。

## 通道 (Channels)

通道将智能体连接到外部消息服务：入站事件触发运行，响应则返回至同一对话中。**Slack 是唯一受支持的提供商。** `channels/` 下每个文件对应一个通道，每个文件需导出一个命名的 `channel`。

```python
# channels/slack.py
from managed_deepagents import channels

channel = channels.slack()
```

文件名决定了通道名称及其入站路由——`channels/slack.py` 将在 `POST /channels/slack/events` 接收事件。名称必须唯一；切勿将文件命名为 `channels/channel.py`。

源自通道的运行会向工具和中间件暴露 `runtime.channel`，其中包含规范化的事件和对话地址，以及用于发送和更新消息的方法。普通的 HTTP 运行和定时运行没有发起通道，因此不会包含 `runtime.channel`。

配置 Slack 需要在项目根目录下提供 `slack-app-manifest.json`，并在 `.env` 中配置 `SLACK_SIGNING_SECRET` + `SLACK_BOT_TOKEN`。请将该清单文件视为唯一真实数据源；`.mda/` 下生成的文件属于构建产物，切勿提交到版本控制中。`runtime.channel` 绝不会暴露 Bot Token。

通道的作用是*接收*触发运行的消息。这与为智能体提供用于主动发起操作的 Slack *工具*不同——项目可以根据需要配置其中之一或两者兼备。

## 评测 (Evals)

MDA 评测基于 [Harbor](https://www.harborframework.com/docs/tasks) 评测体系。`evals/tasks/` 为标准数据集目录；可在其中编写完整的 Harbor 任务。`mda evals` 不引入独立的文件格式，也不直接运行试验——它负责将智能体打包以供 Harbor 使用，并输出一条 `harbor run` 命令。

```bash
mda evals init smoke      # 可选：在 evals/scaffold/ 下生成初始模板
mda evals compile .       # 将模板复制到 evals/tasks/ 并写入交接配置
```

`evals/` 不会包含在部署构建产物中。Harbor 的默认环境依赖 Docker，且**不会读取 `.env`**——生成的作业配置会写入 `${VAR}` 占位符，因此请在运行 Harbor 的 Shell 中导出这些环境变量。验证器会将数值奖励写入 `/logs/verifier/reward.txt`，或将指标写入 `/logs/verifier/reward.json`。关于更深入的评测设计，参见 [[eval-engineering]]。

## CLI 命令参考

| 命令 | 用途 |
| --- | --- |
| `mda init <name>` | 生成项目脚手架。如果目标目录已存在则报错退出。 |
| `mda build [path]` | 编译为托管 LangGraph 应用，不执行部署。 |
| `mda dev [path]` | 编译并在 LangSmith Studio 中运行本地开发服务器。 |
| `mda deploy [path]` | 编译、同步 Context Hub、上传、部署并对齐定时调度。 |
| `mda logs [path]` | 实时查看已部署智能体的 Agent Server 日志。 |
| `mda delete [path]` | 删除部署及其创建的 LangSmith 资源。别名：`destroy`。 |
| `mda evals init\|compile` | 生成 Harbor 任务脚手架；为 Harbor 打包智能体。别名：`eval`。 |

核心参数选项：

- `init`: `--model SPEC`, `--instructions TEXT`, `--instructions-file PATH`, `--memory agent|none`, `--gateway`, `--no-sandbox`
- `build`: `--out OUT`（默认为 `<path>/.mda/build`，每次构建前会清空）
- `dev`: `--port`, `--hostname`, `--no-browser`, `--no-reload`
- `deploy`: `--name`, `--deployment-type dev|prod`, `--workspace-id`, `--no-wait`
- `logs`: `--name`, `--lines`, `--level`, `--follow` / `--no-follow`, `--workspace-id`
- `delete`: `--name`, `--workspace-id`, `--yes`

`mda init` 会根据当前目录自动检测语言（存在 `pyproject.toml` → Python，存在 `package.json` → TypeScript，两者皆有或皆无 → 交互式提示选择）。`mda dev` 在 Python 环境下需要 `uv`，并会自动解析 LangGraph 开发服务器。

> `mda delete` 属于破坏性操作，会删除部署及其关联的 LangSmith 资源。**在运行前请务必向用户确认，绝不要在未提示的情况下直接传入 `--yes`**——该标志的作用是跳过本应向用户确认的步骤。

## 部署与 Context Hub

身份认证信息的解析顺序为：`LANGGRAPH_HOST_API_KEY`、`LANGSMITH_API_KEY`、`LANGCHAIN_API_KEY`——优先从项目 `.env` 读取，其次从当前 Shell 环境读取。在交互式终端中若未找到密钥，`mda deploy` 会提示输入并将其保存到 `.env`。使用组织级密钥时，请配合 `--workspace-id` 或 `LANGSMITH_WORKSPACE_ID` 使用。

`mda deploy` 会将本地输入分发到不同的托管服务平面：

```text
instructions.md + skills/**   -> Context Hub 归部署所有的上下文
.env                          -> 部署认证 + 非保留的托管密钥（绝不打包归档）
项目源代码                    -> .mda/build 归档包 -> 托管部署
schedules/**                  -> LangSmith Cron 作业（部署就绪后生效）
```

`.env` 中的非保留项（提供商密钥、工具凭据、数据库连接串）将作为托管部署密钥进行转发。平台保留变量（`LANGSMITH_API_KEY`、`LANGGRAPH_HOST_API_KEY`、`LANGCHAIN_API_KEY`、`LANGSMITH_WORKSPACE_ID`）仅用于认证部署请求并进行路由，绝不会作为用户托管密钥上传。如果模型所需的提供商密钥在 `.env`、Shell 或 LangSmith 工作区密钥中均不存在，部署将在上传前直接失败。

Context Hub 存放 `/instructions.md` 和 `/skills/**`（归部署所有，每次部署时重新同步）以及 `/memories/agent/**`（归运行时所有，跨部署持久保留）。

排错指南：提示 `no agent entry file found` → 在根目录添加 `agent.py`。提示 401/403 → 该密钥所在工作区缺少公测权限。提示 Context Hub conflict → 重新运行部署。构建产物超过 200 MB → 清理生成的构建缓存与文件。状态显示 `BUILD_FAILED` / `DEPLOY_FAILED` → 打开输出的 URL 查看修订版本日志。

## 人机协同 (Human-in-the-loop)

使用 `interrupt_on` 在执行敏感工具调用前暂停，使用 `permissions` 控制文件系统访问路径：

```python
agent = define_deep_agent(
    name="support-agent",
    model="anthropic:claude-sonnet-4-6",
    tools=[refund_customer],
    interrupt_on={"refund_customer": True},
)
```

`interrupt_on` 的作用机制与 LangChain 的人机协同中间件相同；有关审批/编辑/拒绝语义，参见 [[langgraph-human-in-the-loop]]。中断机制依赖持久化的线程状态，而托管运行时拥有 Checkpointer 的管理权，因此无需额外配置。

在 `mda dev` 期间，可在 Studio 中直接响应中断。对于已部署的智能体，可通过 LangGraph 服务端 API 发送 `Command(resume=...)` 负载来恢复执行——但请注意，公测期间未提供从自定义应用程序进行编程式调用的公开文档。

## 常见易错点与注意事项

- **`define_deep_agent` / `defineDeepAgent` 中 `name=` 为必填项。** 缺少该字段定义将报错。
- **模型 ID 必须包含提供商前缀**：必须是 `anthropic:claude-sonnet-4-6`，不能仅写模型名。Python 使用 `google_genai:`，TypeScript 使用 `google-genai:`，Gateway 使用 `provider/model`。
- **切勿在智能体定义中设置托管字段**（`backend`、`store`、`checkpointer`、`memory`、`skills`、系统提示词）。
- **记忆功能通过 `memory.py` 按需启用**，而非构造函数参数。`disable_memory` 为旧版废弃用法——请通过声明或删除 `memory.py` 来控制。
- **不存在 MCP 连接器。** `connectors/mcp.*` 和 `define_mcp_servers` 已被移除；编写它们会导致报错。
- **添加托管文件后需重启 `mda dev`。** 新增的 `memory.py`、`identity.py`、`schedules/` 或 `channels/` 声明是在编译时发现的，不支持热重载。
- **`--no-wait` 会跳过调度同步**并在状态变为 `DEPLOYED` 之前提前退出。
- **定时调度声明必须是静态字面量**——编译器在不执行代码的情况下提取它们。
- **`.env` 绝不会被打包归档**，且必须在 `.gitignore` 中将其排除在版本控制之外。切勿代表用户直接向其中写入真实密钥。
- **文档更新略超前于已发布的 CLI 版本。** 在采纳某个标志或导入路径之前，请先通过 `mda --help` 和已安装的依赖包进行验证。截至 `mda` 0.5.0 版本：沙箱文档中写的是 `sandboxes.langsmith(...)`，但该导入会引发 `ImportError`——请按上文所示使用 `define_sandbox(...)`；文档中记载的 `mda init --identity` 和 `mda deploy --configure-slack` 标志实际并不存在（`identity.py` 默认会自动生成脚手架）。