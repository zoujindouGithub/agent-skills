---
name: langgraph-cli
description: "在使用 langgraph CLI 进行 LangGraph 应用程序的脚手架搭建、开发、构建或部署时调用此技能。涵盖 langgraph new、dev、build、up、deploy 以及 langgraph.json 配置。"
---

<overview>
`langgraph` CLI 用于管理 LangGraph 应用程序的完整生命周期 —— 从新项目脚手架搭建到部署至 LangGraph Platform（LangSmith 部署）。

核心命令：
- **`langgraph new`** — 从模板脚手架搭建新项目
- **`langgraph dev`** — 本地热重载运行（无需 Docker）
- **`langgraph build`** — 构建 Docker 镜像
- **`langgraph up`** — 通过 Docker Compose 在本地启动
- **`langgraph deploy`** — 部署发布至 LangGraph Platform
- **`langgraph dockerfile`** — 生成 Dockerfile

除 `new` 外的所有命令都会读取项目根目录下的 `langgraph.json` 配置文件。
</overview>

## 适用场景

在用户需要执行以下操作时使用此技能：
- 脚手架搭建新的 LangGraph 项目
- 运行本地开发或类生产环境服务器
- 构建或部署 LangGraph 应用程序
- 理解或编辑 `langgraph.json` 配置
- 管理 LangSmith 部署（列表查看、删除、查看日志）

## 安装

```bash
# Python
pip install 'langgraph-cli[inmem]'   # 包含 langgraph dev 支持
pip install langgraph-cli             # 不包含开发服务器（仅支持 build/up/deploy）

# 如果使用 UV 作为包管理器
uv add "langgraph-cli[inmem]"       # 包含 langgraph dev 支持
uv add langgraph-cli                # 不包含开发服务器（仅支持 build/up/deploy）

# JavaScript
npx @langchain/langgraph-cli         # 按需直接运行
npm install -g @langchain/langgraph-cli  # 全局安装（命令为 langgraphjs）
```

## 命令列表

### `langgraph new [PATH]`

从模板脚手架搭建新项目。

```bash
langgraph new                          # 交互式模板选择
langgraph new ./my-agent               # 在指定目录创建
langgraph new --template agent-python  # 跳过提示，直接使用指定模板
```

可用模板：`deep-agent-python`、`deep-agent-js`、`agent-python`、`new-langgraph-project-python`、`new-langgraph-project-js`

### `langgraph dev`

运行带有热重载功能的本地开发服务器。无需 Docker。

```bash
langgraph dev                              # 默认端口：localhost:2024
langgraph dev --port 8000                  # 自定义端口
langgraph dev --config ./langgraph.json    # 显式指定配置文件路径
langgraph dev --no-reload                  # 禁用热重载
langgraph dev --no-browser                 # 不自动打开 LangGraph Studio
langgraph dev --host 0.0.0.0              # 绑定所有网络接口（仅限可信网络）
langgraph dev --tunnel                     # 通过 Cloudflare tunnel 暴露以进行远程访问
langgraph dev --debug-port 5678            # 启用远程调试器（需要 debugpy）
langgraph dev --n-jobs-per-worker 20       # 每个 worker 的最大并发任务数（默认：10）
```

### `langgraph build`

为 LangGraph API 服务器构建 Docker 镜像。

```bash
langgraph build -t my-image                # 必选参数：标记镜像标签
langgraph build -t my-image --no-pull      # 使用本地构建的基础镜像
langgraph build -t my-image -c langgraph.json  # 显式指定配置
langgraph build -t my-image --base-image langchain/langgraph-server:0.2.18  # 锁定基础镜像版本
```

### `langgraph up`

通过 Docker Compose 启动 LangGraph API 服务器（包含 Postgres）。

```bash
langgraph up                               # 默认端口 8123
langgraph up --port 8000                   # 自定义端口
langgraph up --watch                       # 文件变更时自动重启
langgraph up --recreate                    # 强制重新构建（用于部署前验证）
langgraph up --postgres-uri postgresql://...  # 使用外部 Postgres
langgraph up --no-pull                     # 使用本地镜像（在 langgraph build 之后）
langgraph up --image my-image              # 跳过构建，使用预构建镜像
langgraph up -d docker-compose.yml         # 添加额外的 Docker 服务
langgraph up --debugger-port 8124          # 提供调试器 UI
langgraph up --wait                        # 阻塞等待直到所有服务处于健康状态
```

### `langgraph deploy`

构建并部署到 LangGraph Platform（LangSmith 部署）。需要 Docker。在 Apple Silicon（M1/M2/M3）上，还需要 Docker Buildx 以便交叉编译至 `linux/amd64`。

```bash
langgraph deploy                           # 部署，名称默认为目录名
langgraph deploy --name my-agent           # 显式指定部署名称
langgraph deploy --deployment-type prod    # 生产环境部署（默认：dev）
langgraph deploy --tag v1.2.0              # 自定义镜像标签（默认：latest）
langgraph deploy --deployment-id <id>      # 根据 ID 更新现有部署
langgraph deploy --config ./langgraph.json # 显式指定配置文件路径
langgraph deploy --no-wait                 # 不等待部署状态返回
langgraph deploy --verbose                 # 显示详细的服务端日志
```

前提条件：环境变量或 `.env` 中需配置 `LANGSMITH_API_KEY`。

`langgraph deploy` 也支持构建相关参数：`--base-image`、`--pull`/`--no-pull`。

#### `langgraph deploy list`

```bash
langgraph deploy list                      # 列出所有部署
langgraph deploy list --name-contains bot  # 按名称筛选
```

#### `langgraph deploy delete`

```bash
langgraph deploy delete <deployment-id>          # 交互式确认删除
langgraph deploy delete <deployment-id> --force  # 跳过确认强制删除
```

#### `langgraph deploy logs`

```bash
langgraph deploy logs                                  # 运行时日志，最新 100 条
langgraph deploy logs --name my-agent                  # 按部署名称查看
langgraph deploy logs --deployment-id <id>             # 按部署 ID 查看
langgraph deploy logs --type build                     # 查看构建日志而非运行时日志
langgraph deploy logs -f                               # 持续跟踪/流式输出日志
langgraph deploy logs --level error                    # 按级别筛选（debug|info|warning|error|critical）
langgraph deploy logs -q "timeout"                     # 搜索关键字筛选
langgraph deploy logs --limit 500                      # 增加返回条数
langgraph deploy logs --start-time 2026-03-08T00:00:00Z  # 指定时间范围
```

### `langgraph dockerfile <SAVE_PATH>`

仅生成 Dockerfile（以及可选的 Docker Compose 文件），不执行构建。

```bash
langgraph dockerfile ./Dockerfile                      # 生成 Dockerfile
langgraph dockerfile ./Dockerfile --add-docker-compose # 同时生成 compose + .env + .dockerignore
```

## `langgraph.json` 配置参考

所有 CLI 命令（`dev`、`build`、`up`、`deploy`）使用的配置文件。默认读取当前目录下的 `langgraph.json`。

### 最小配置（Python）

```json
{
    "dependencies": ["."],
    "graphs": {
        "agent": "./my_agent/agent.py:graph"
    },
    "env": "./.env"
}
```

### 最小配置（JavaScript）

```json
{
    "dependencies": ["."],
    "graphs": {
        "agent": "./src/agent.js:graph"
    },
    "env": "./.env"
}
```

### 包含所有字段的完整配置

```json
{
    "dependencies": [".", "langchain_openai", "./local_package"],
    "graphs": {
        "agent": "./my_agent/agent.py:graph",
        "retriever": "./my_agent/rag.py:rag_graph"
    },
    "env": "./.env",
    "python_version": "3.12",
    "pip_config_file": "./pip.conf",
    "dockerfile_lines": [
        "RUN apt-get update && apt-get install -y ffmpeg"
    ]
}
```

### 配置项参考

| 字段 | 必填 | 描述 |
|-----|----------|-------------|
| `dependencies` | 是 | 依赖项数组。`"."` 会通过 `pyproject.toml`、`setup.py`、`requirements.txt` 或 `package.json` 查找本地包。也可以是子目录路径（`"./my_pkg"`）或包名称（`"langchain_openai"`）。 |
| `graphs` | 是 | 图 ID 到路径的映射。格式为：`./path/to/file.py:variable`（Python）或 `./path/to/file.js:function`（JS）。变量必须是一个 `CompiledGraph` 或返回该对象的函数。支持配置多个图。 |
| `env` | 否 | `.env` 文件路径（字符串）或环境变量名称到值的内联映射（对象）。由本地的 `langgraph dev` 和 `langgraph up` 使用。`langgraph deploy` 会读取该文件并将变量添加为部署密钥（Secrets）。 |
| `python_version` | 否 | `"3.11"`、`"3.12"` 或 `"3.13"`。默认值为 `"3.11"`。 |
| `node_version` | 否 | JS 项目使用的 Node.js 版本。 |
| `pip_config_file` | 否 | 用于自定义包索引源的 pip 配置文件路径。 |
| `dockerfile_lines` | 否 | 在基础镜像导入后附加的额外 Dockerfile 指令数组。用于安装系统软件包、二进制文件或自定义设置。 |

## 典型工作流

1. **脚手架搭建** — 使用 `langgraph new` 从模板创建项目。
2. **配置** — 编辑 `langgraph.json`：设置依赖项，将 `graphs` 指向已编译的图（Compiled Graph），添加 `.env`。
3. **开发** — 使用 `langgraph dev` 进行快速本地热重载迭代（无需 Docker，端口 2024）。
4. **验证** — 使用 `langgraph up --recreate` 在类生产环境的 Docker 技术栈中进行测试（端口 8123，包含 Postgres）。
5. **部署** — 使用 `langgraph deploy` 发布至 LangGraph Platform（LangSmith 部署）。
6. **监控** — 使用 `langgraph deploy logs -f` 实时查看运行时日志；使用 `--type build` 查看构建日志。

## `langgraph dev` 与 `langgraph up` 对比

| 特性 | `langgraph dev` | `langgraph up` |
|---------|----------------|----------------|
| 依赖 Docker | 否 | 是 |
| 安装方式 | `pip install 'langgraph-cli[inmem]'` | `pip install langgraph-cli` |
| 主要用途 | 快速开发与测试 | 类生产环境验证 |
| 状态持久化 | 内存中 / pickle 序列化至本地目录 | PostgreSQL |
| 热重载 | 是（默认开启） | 可选（`--watch`） |
| 默认端口 | 2024 | 8123 |
| 资源占用 | 轻量级 | 较高（包含 Server、Postgres、Redis 的 Docker 容器） |
| IDE 调试 | 内置 DAP 支持（`--debug-port`） | 容器内调试 |

## 注意事项

- **`langgraph deploy` 需要 Docker** — 在 Apple Silicon（M1/M2/M3）上，还需要 Docker Buildx 以便交叉编译至 `linux/amd64`。
- **`langgraph deploy` 只能更新由其自身创建的部署** — 通过 LangSmith UI 或 GitHub 集成创建的部署无法使用 `langgraph deploy` 进行更新，这些部署请使用 UI 界面进行操作。
- **`dependencies` 必须包含所有包** — `langgraph.json` 中的 `dependencies` 数组必须指向包配置所在的位置（例如根目录用 `"."`）。实际安装的包将根据该路径下的 `pyproject.toml`、`requirements.txt` 或 `package.json` 进行解析。
- **`langgraph dev` 在脱离 Docker 的环境下运行** — 它直接在您的本地环境中运行。如果代码依赖系统级软件包（例如 `ffmpeg`），必须在本地自行安装。使用 `langgraph up` 可以验证 Docker 构建情况。
- **JavaScript CLI** — 请使用 `npx @langchain/langgraph-cli <command>`（如果通过 `npm install -g @langchain/langgraph-cli` 全局安装，则使用 `langgraphjs`）。
- **API Key** — 执行 `langgraph deploy` 时必须提供 `LANGSMITH_API_KEY`。对于 `langgraph dev`，该项为可选配置 —— 服务器在没有它的情况下也可以正常运行，但不会向 LangSmith 发送链路追踪数据。也可以通过 `LANGGRAPH_HOST_API_KEY` 或 `LANGCHAIN_API_KEY` 进行配置。