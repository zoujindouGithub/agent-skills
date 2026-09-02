# agent-skills

面向 `omp` / Codex / Claude Code 的个人技能库（[SKILL.md](https://agentskills.io) 规范），共 40 个技能，用于跨机器同步复用。

## 目录结构

```
skills/<name>/SKILL.md   # 每个技能一个目录
install.ps1 / install.sh # 从仓库复原到当前机器
export.ps1 / export.sh   # 把当前机器的技能回采进仓库
```

宿主工具会从两个根目录读取技能：

| 根目录 | 读取方 |
| :-- | :-- |
| `~/.agents/skills` | omp（主目录，跨 agent 通用） |
| `~/.codex/skills` | Codex（omp 也会读取） |

`install.*` 同时写入两个根目录。脚本是**增量写入**——从不删除任何内容，
因此由 Codex 自行维护的 `~/.codex/skills/.system` 子树不会被破坏。

## 在新机器上复原

```bash
git clone https://github.com/zoujindouGithub/agent-skills.git
cd agent-skills

# Windows（PowerShell）
./install.ps1

# Linux / macOS
./install.sh
```

执行后重启 `omp` / Codex 即可加载。若只用 omp，真正起作用的是 `~/.agents/skills`。

## 把改动回传到仓库

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

- `obs-prod-status`（引用了内网主机别名与运维脚本）**有意不同步**。即便如此，
  本仓库仍应保持 **私有**：技能命名与提交历史本身就会暴露内部工具链信息。
- 本仓库不含任何凭据。密钥只存放在 `~/.omp/agent/.env` 与 `~/.ssh/`，两者均已 gitignore。
