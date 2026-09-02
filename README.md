# agent-skills

面向 `omp` / Codex / Claude Code 的个人技能库（[SKILL.md](https://agentskills.io) 规范），共 40 个技能。

## 目录结构

```
skills/<name>/SKILL.md   # 每个技能一个目录，自包含
export.ps1 / export.sh   # 维护者把本机技能回采进仓库
```

本仓库**不提供安装脚本**：技能落盘位置取决于你用哪个 agent 工具，目录差异也多由本地环境决定，
直接照下面的约定复制、或把「安装任务说明」丢给你的 AI agent 执行，比维护一份跨平台脚本更可靠。

## 技能安装位置

宿主工具从两个根目录读取技能：

| 根目录 | 读取方 |
| :-- | :-- |
| `~/.agents/skills` | omp（主目录，跨 agent 通用） |
| `~/.codex/skills` | Codex（omp 也会读取） |

只用 omp 的话，`~/.agents/skills` 就是唯一必需的目录。

### 手动安装

Windows（在 clone 下来的仓库根目录执行 PowerShell）：

```powershell
$src = Join-Path $PWD "skills"
foreach ($t in @("$env:USERPROFILE\.agents\skills", "$env:USERPROFILE\.codex\skills")) {
    New-Item -ItemType Directory -Force -Path $t | Out-Null
    Copy-Item (Join-Path $src "*") $t -Recurse -Force
}
```

Linux / macOS：

```bash
for t in ~/.agents/skills ~/.codex/skills; do
  mkdir -p "$t"
  cp -R skills/. "$t/"
done
```

装完重启 `omp` / Codex 即可加载。

### 安装任务说明（交给 AI agent 执行时可直接粘贴）

> 把本仓库 `skills/` 下的**每一个技能目录**原样复制到 `~/.agents/skills/`（只用 Codex 则复制到 `~/.codex/skills/`）。
> 要求：
>
> 1. **增量复制**，绝不删除或清空目标目录——目标里可能已有本地技能，以及由 Codex 自行维护的 `~/.codex/skills/.system` 子树。
> 2. 保持目录结构不变，技能目录内文件名（`SKILL.md`、`references/`、`scripts/`、`agents/` 等）不要重命名。
> 3. 遇到同名技能目录时**先比对差异**再决定是否覆盖，并向用户说明冲突，不要静默覆盖用户自定义内容。
> 4. 复制完成后，列出实际写入的技能数量，并提示重启 agent 工具生效。
> 5. 技能内可能引用外部命令或本地路径；本仓库只负责分发文本，不负责安装任何依赖。

## 维护者：把改动回传到仓库

在 `~/.agents/skills`（omp 的主目录）里编辑技能，然后：

```bash
./export.ps1    # 或 ./export.sh
git add -A && git commit -m "skills: update" && git push
```

`export.*` 采用固定的合并优先级：冲突时以 `~/.agents/skills` 为准，再补入只存在于
`~/.codex/skills` 中的技能。`*.bak` 会被丢弃，`SKIP_DIRS` 列表（`.system`、
`obs-prod-status`）永不采集。

两个脚本都会**先校验**解析出的根目录中确实存在 `SKILL.md`，否则直接报错退出——
这样即使 `$HOME` 被解析错（Git-Bash 子进程的 `$HOME` 会指向 omp 并不读取的
MSYS 幻影目录），也不会把一份残缺集合推上仓库。

## 说明

- 本仓库为公开仓库，内容经过个人信息扫描：不含主机名、内网 IP、账号与任何凭据。
- 维护者本地的 `obs-prod-status` 技能（引用内网主机别名与运维脚本）**永久排除在同步范围外**。
- 密钥只存放在 `~/.omp/agent/.env` 与 `~/.ssh/`，两者均在 `.gitignore` 中。
