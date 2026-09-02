---
name: obsidian-vault
description: 在 Obsidian 知识库中搜索、创建和管理带有 wikilinks 和索引笔记的笔记。当用户想要在 Obsidian 中查找、创建或整理笔记时使用。
---

# Obsidian 知识库 (Obsidian Vault)

## 知识库位置

`/mnt/d/Obsidian Vault/AI Research/`

根目录下基本采用扁平化结构。

## 命名规范

- **索引笔记（Index notes）**：聚合相关主题（例如：`Ralph Wiggum Index.md`、`Skills Index.md`、`RAG Index.md`）
- 所有笔记名称均采用**首字母大写（Title Case）**
- 不使用文件夹进行组织——改用链接和索引笔记

## 链接规范

- 使用 Obsidian `[[wikilinks]]` 语法：`[[Note Title]]`
- 笔记在底部链接到依赖项/相关笔记
- 索引笔记本质上就是 `[[wikilinks]]` 列表

## 工作流

### 搜索笔记

```bash
# 按文件名搜索
find "/mnt/d/Obsidian Vault/AI Research/" -name "*.md" | grep -i "keyword"

# 按内容搜索
grep -rl "keyword" "/mnt/d/Obsidian Vault/AI Research/" --include="*.md"
```

或者直接在知识库路径上使用 Grep/Glob 工具。

### 创建新笔记

1. 文件名使用**首字母大写（Title Case）**
2. 将内容作为一个独立的知识单元编写（遵循知识库规则）
3. 在底部添加指向相关笔记的 `[[wikilinks]]`
4. 如果属于编号序列的一部分，请使用层级编号方案

### 查找相关笔记

在整个知识库中搜索 `[[Note Title]]` 以查找反向链接（backlinks）：

```bash
grep -rl "\\[\\[Note Title\\]\\]" "/mnt/d/Obsidian Vault/AI Research/"
```

### 查找索引笔记

```bash
find "/mnt/d/Obsidian Vault/AI Research/" -name "*Index*"
```