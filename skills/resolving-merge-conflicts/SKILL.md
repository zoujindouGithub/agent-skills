---
name: resolving-merge-conflicts
description: "当需要解决正在进行中的 git merge/rebase 冲突时使用。"
---

1. **查看 merge/rebase 的当前状态**。检查 git 历史记录以及存在冲突的文件。

2. **查找每个冲突的原始来源**。深入理解每次更改的原因以及最初的意图。阅读 commit 提交信息，检查 PR，查看原始 issue/ticket。

3. **解决每个冲突块（hunk）**。尽可能保留双方的意图。在两者不兼容的情况下，选择符合本次合并既定目标的一方，并记录下权衡取舍。**切勿**捏造新的行为。务必解决冲突；绝对不要使用 `--abort`。

4. 查找项目的**自动化检查**并运行它们，通常顺序为类型检查（typecheck）、测试（tests）、格式化（format）。修复因合并导致损坏的任何内容。

5. **完成 merge/rebase**。暂存（stage）所有修改并提交。如果是 rebase，则继续 rebase 流程，直到所有 commit 都完成 rebase。