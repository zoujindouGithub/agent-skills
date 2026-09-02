---
name: git-guardrails-claude-code
description: 设置 Claude Code 钩子以在执行前拦截危险的 git 命令（push、reset --hard、clean、branch -D 等）。适用于用户希望防止破坏性 git 操作、添加 git 安全钩子或在 Claude Code 中拦截 git push/reset 的场景。
---

# 设置 Git 防护栏（Guardrails）

设置一个 `PreToolUse` 钩子，在 Claude 执行危险的 git 命令之前对其进行拦截并阻止。

## 拦截内容

- `git push`（包括 `--force` 在内的所有变体）
- `git reset --hard`
- `git clean -f` / `git clean -fd`
- `git branch -D`
- `git checkout .` / `git restore .`

被拦截时，Claude 会看到一条提示信息，表明其无权访问或执行这些命令。

## 操作步骤

### 1. 确认作用域

询问用户：是**仅为当前项目**安装（`.claude/settings.json`），还是为**所有项目**全局安装（`~/.claude/settings.json`）？

### 2. 复制钩子脚本

捆绑的脚本位于：[scripts/block-dangerous-git.sh](scripts/block-dangerous-git.sh)

根据作用域将其复制到目标位置：

- **项目级**：`.claude/hooks/block-dangerous-git.sh`
- **全局级**：`~/.claude/hooks/block-dangerous-git.sh`

使用 `chmod +x` 为其赋予可执行权限。

### 3. 将钩子添加到配置中

添加到对应的配置文件中：

**项目级** (`.claude/settings.json`):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/block-dangerous-git.sh"
          }
        ]
      }
    ]
  }
}
```

**全局级** (`~/.claude/settings.json`):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/block-dangerous-git.sh"
          }
        ]
      }
    ]
  }
}
```

如果配置文件已存在，请将该钩子合并到现有的 `hooks.PreToolUse` 数组中。请勿覆盖其他配置项。

### 4. 询问自定义需求

询问用户是否需要从拦截列表中添加或删除任何命令规则模式。根据需要编辑复制的脚本。

### 5. 验证

运行快速测试：

```bash
echo '{"tool_input":{"command":"git push origin main"}}' | <path-to-script>
```

该命令应以退出码 2 退出，并向 stderr 输出 BLOCKED 拦截消息。