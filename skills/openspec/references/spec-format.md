# OpenSpec 规范文档格式详解

## 目录

1. [文件结构](#文件结构)
2. [Delta Specs 格式](#delta-specs-格式)
3. [Main Specs 格式](#main-specs-格式)
4. [需求编写规范](#需求编写规范)
5. [场景编写规范](#场景编写规范)
6. [Delta 类型详解](#delta-类型详解)
7. [合并规则](#合并规则)
8. [规范性术语](#规范性术语)
9. [示例完整规格](#示例完整规格)

---

## 文件结构

### Delta Specs（变更级）

```
openspec/changes/<change-name>/specs/
└── <capability>/
    └── spec.md
```

一个变更可以影响多个 capability，每个 capability 对应一个 spec.md。

### Main Specs（项目级）

```
openspec/specs/
└── <capability>/
    └── spec.md
```

描述系统当前的完整行为，是“唯一事实来源（Single Source of Truth）”。

---

## Delta Specs 格式

Delta Specs 使用 diff 风格标记变更：

```markdown
## ADDED Requirements

### Requirement: <需求名称>
<需求描述>

#### Scenario: <场景名称>
- **GIVEN** <前置条件>
- **WHEN** <触发条件>
- **THEN** <预期结果>
- **AND** <附加结果>

## MODIFIED Requirements

### Requirement: <需求名称>
<修改后的完整需求描述>

#### Scenario: <场景名称>
- **GIVEN** <前置条件>
- **WHEN** <触发条件>
- **THEN** <预期结果>

## REMOVED Requirements

### Requirement: <需求名称>
<简要说明移除原因>
```

---

## Main Specs 格式

Main Specs 不使用 Delta 标记，直接描述当前系统行为：

```markdown
# Capability: <能力名称>

## Requirements

### Requirement: <需求名称>
<需求描述>

#### Scenario: <场景名称>
- **GIVEN** <前置条件>
- **WHEN** <触发条件>
- **THEN** <预期结果>

### Requirement: <另一个需求>
...
```

---

## 需求编写规范

### 需求标题

使用简洁、具有描述性的标题：

```markdown
### Requirement: 用户会话过期
### Requirement: 双因子认证
### Requirement: 密码重置流程
```

### 需求描述

描述应回答：
- **What** — 系统应该做什么
- **Why** — 为什么需要这个功能
- **Who** — 谁受益

```markdown
### Requirement: 用户会话过期
系统 SHALL 支持可配置的会话过期时间，以平衡安全性和用户体验。
```

### 需求粒度

- 每个需求聚焦于单一行为
- 避免使用“和”、“或”连接多个独立行为
- 复杂需求拆分为多个独立需求

**反例**（过于复杂）：
```markdown
### Requirement: 用户认证和授权
系统 SHALL 支持用户登录，并且 SHALL 根据角色分配权限，并且 SHALL 记录审计日志。
```

**正例**（拆分后）：
```markdown
### Requirement: 用户认证
系统 SHALL 支持用户名密码登录。

### Requirement: 基于角色的授权
系统 SHALL 根据用户角色限制资源访问。

### Requirement: 审计日志
系统 SHALL 记录所有认证和授权事件。
```

---

## 场景编写规范

### Given/When/Then 结构

```markdown
#### Scenario: <具体场景名称>
- **GIVEN** <系统处于什么状态>
- **WHEN** <发生什么事件/操作>
- **THEN** <系统应产生什么结果>
- **AND** <附加结果>
- **BUT** <例外或约束>
```

### 场景命名

使用具体、可识别的名称：

```markdown
#### Scenario: 默认会话超时
#### Scenario: 记住我延长会话
#### Scenario: 管理员强制注销所有用户
```

避免模糊名称：

```markdown
#### Scenario: 正常情况      ← 太模糊
#### Scenario: 边界情况      ← 太模糊
```

### Given 子句

描述系统状态，而非用户心理状态：

**反例**：
```markdown
- **GIVEN** 用户想要登录
```

**正例**：
```markdown
- **GIVEN** 用户已注册且账户处于激活状态
- **GIVEN** 系统配置会话超时时间为 24 小时
```

### When 子句

描述触发事件，使用主动语态：

```markdown
- **WHEN** 用户提交有效的用户名和密码
- **WHEN** 24 小时内无任何活动
- **WHEN** 管理员调用强制注销 API
```

### Then 子句

描述可验证的结果：

```markdown
- **THEN** 系统返回认证令牌
- **THEN** 会话令牌被标记为无效
- **THEN** 系统向用户发送注销通知邮件
```

避免模糊描述：

```markdown
- **THEN** 系统应该正常工作      ← 不可验证
- **THEN** 用户体验良好         ← 不可验证
```

### 多场景覆盖

每个需求应覆盖：
- 正常流程（Happy Path）
- 边界条件
- 错误处理
- 并发/时序场景（如适用）

```markdown
### Requirement: 用户登录
系统 SHALL 验证用户凭据并建立认证会话。

#### Scenario: 有效凭据登录
- **GIVEN** 用户已注册且账户处于激活状态
- **WHEN** 用户提交有效的用户名和密码
- **THEN** 系统返回认证令牌
- **AND** 记录登录事件到审计日志

#### Scenario: 密码错误
- **GIVEN** 用户已注册且账户处于激活状态
- **WHEN** 用户提交有效的用户名和错误的密码
- **THEN** 系统返回 401 Unauthorized
- **AND** 递增失败登录计数

#### Scenario: 账户已锁定
- **GIVEN** 用户账户因连续 5 次登录失败而被锁定
- **WHEN** 用户提交任何凭据
- **THEN** 系统返回 423 Locked
- **AND** 提示用户联系管理员解锁

#### Scenario: 并发登录限制
- **GIVEN** 用户已在设备 A 上登录
- **WHEN** 用户在设备 B 上登录且系统配置为单设备会话
- **THEN** 系统使设备 A 的会话失效
- **AND** 在设备 B 上建立新会话
```

---

## Delta 类型详解

### ADDED

全新的功能需求。归档时追加到 Main Specs 中。

```markdown
## ADDED Requirements

### Requirement: 深色模式支持
系统 SHALL 支持深色模式主题切换。

#### Scenario: 用户切换主题
- **GIVEN** 用户当前处于浅色模式
- **WHEN** 用户点击主题切换按钮
- **THEN** 界面切换为深色模式
- **AND** 将用户偏好保存到 localStorage
```

### MODIFIED

修改现有逻辑。归档时替换 Main Specs 中的对应需求。

**必须包含修改后的完整文本**，而不仅是描述差异：

```markdown
## MODIFIED Requirements

### Requirement: 会话过期
系统 SHALL 支持可配置的会话过期周期。

#### Scenario: 默认会话超时
- **GIVEN** 用户已认证
- **WHEN** 24 小时无活动且未勾选“记住我”
- **THEN** 使会话令牌失效

#### Scenario: 延长会话
- **GIVEN** 用户在登录时勾选了“记住我”
- **WHEN** 30 天已过
- **THEN** 使会话令牌失效
- **AND** 清除持久化 Cookie
```

### REMOVED

已废弃的功能。归档时从 Main Specs 中移除或标记为已删除。

```markdown
## REMOVED Requirements

### Requirement: 旧版 OAuth 1.0 支持
移除原因：OAuth 1.0 已被 OAuth 2.0 + PKCE 完全替代，不再进行维护。
```

---

## 合并规则

归档时，Delta Specs 按以下规则合并到 Main Specs 中：

### ADDED → 追加

在对应 capability 的 Main Spec 中追加新增需求。

### MODIFIED → 替换

在 Main Spec 中查找对应的需求，用 Delta 中的完整修订文本进行替换。

### REMOVED → 删除或标记

- 默认：物理删除需求文本
- 可选：保留但标记为 `~~已删除~~`，并附带移除原因与日期

### 冲突处理

当多个变更同时修改同一需求时：
1. 后归档的变更覆盖先归档的变更
2. 或根据变更创建的时间戳决定优先级
3. 复杂冲突需人工介入解决

---

## 规范性术语

使用 RFC 2119 风格的术语表达约束强度：

| 术语 | 含义 | 使用场景 |
|------|------|----------|
| **SHALL** / **MUST** | 绝对要求 | 核心功能、安全要求 |
| **SHALL NOT** / **MUST NOT** | 绝对禁止 | 安全限制、法律合规 |
| **SHOULD** | 强烈推荐 | 最佳实践、默认行为 |
| **SHOULD NOT** | 不推荐 | 反模式、已弃用做法 |
| **MAY** | 可选 | 增强功能、扩展点 |

### 示例

```markdown
### Requirement: 密码策略
系统 SHALL 要求密码长度至少为 12 个字符。
系统 SHALL NOT 允许使用常见密码（如 "password123"）。
系统 SHOULD 提示用户启用双因子认证。
系统 MAY 支持生物识别认证作为替代方案。
```

---

## 示例完整规格

### Delta Spec 示例

```markdown
## ADDED Requirements

### Requirement: 深色模式支持
系统 SHALL 支持深色模式主题切换，以提升弱光环境下的用户体验。

#### Scenario: 用户手动切换主题
- **GIVEN** 用户当前处于浅色模式
- **WHEN** 用户点击设置中的主题切换开关
- **THEN** 界面立即应用深色模式样式
- **AND** 将 "dark" 保存到 localStorage 的 "theme" 键中

#### Scenario: 跟随系统主题偏好
- **GIVEN** 用户首次访问且未设置过主题偏好
- **WHEN** 系统检测到操作系统偏好为深色模式
- **THEN** 默认应用深色模式
- **AND** 不覆盖 localStorage（允许后续手动切换）

#### Scenario: 主题持久化
- **GIVEN** 用户之前选择了深色模式
- **WHEN** 用户重新打开应用
- **THEN** 系统读取 localStorage 中的主题偏好
- **AND** 应用对应的主题样式

## MODIFIED Requirements

### Requirement: 设置页面布局
设置页面 SHALL 支持分组展示配置项，主题设置作为独立分组展示。

#### Scenario: 访问设置页面
- **GIVEN** 用户已登录
- **WHEN** 用户导航到 /settings
- **THEN** 页面显示“外观”分组，包含主题切换开关
- **AND** 显示当前选中的主题名称
```

### Main Spec 示例

```markdown
# Capability: 主题与外观

## Requirements

### Requirement: 深色模式支持
系统 SHALL 支持深色模式主题切换，以提升弱光环境下的用户体验。

#### Scenario: 用户手动切换主题
- **GIVEN** 用户当前处于浅色模式
- **WHEN** 用户点击设置中的主题切换开关
- **THEN** 界面立即应用深色模式样式
- **AND** 将 "dark" 保存到 localStorage 的 "theme" 键中

#### Scenario: 跟随系统主题偏好
- **GIVEN** 用户首次访问且未设置过主题偏好
- **WHEN** 系统检测到操作系统偏好为深色模式
- **THEN** 默认应用深色模式
- **AND** 不覆盖 localStorage（允许后续手动切换）

#### Scenario: 主题持久化
- **GIVEN** 用户之前选择了深色模式
- **WHEN** 用户重新打开应用
- **THEN** 系统读取 localStorage 中的主题偏好
- **AND** 应用对应的主题样式

### Requirement: 设置页面布局
设置页面 SHALL 支持分组展示配置项，主题设置作为独立分组展示。

#### Scenario: 访问设置页面
- **GIVEN** 用户已登录
- **WHEN** 用户导航到 /settings
- **THEN** 页面显示“外观”分组，包含主题切换开关
- **AND** 显示当前选中的主题名称
```

---

## 常见反模式

### 1. 模糊描述

```markdown
#### Scenario: 正常登录
- **GIVEN** 一切正常
- **WHEN** 用户做正确的事
- **THEN** 系统应该正常工作
```

### 2. 泄露技术实现细节

```markdown
### Requirement: 用户登录
系统 SHALL 使用存储在 Redis 中的 JWT 令牌，过期时间设置为 3600 秒。
```

**修正**：技术细节应放在 `design.md` 中，spec 仅描述行为：

```markdown
### Requirement: 用户登录
系统 SHALL 验证用户凭据并建立具有时效性的认证会话。
```

### 3. 过度拆分

将紧密耦合的行为拆分为过多独立需求，导致阅读与维护困难。

### 4. 忽略边界条件

只写正常流程（Happy Path），不处理错误、异常和边界情况。

### 5. 使用被动语态

```markdown
- **THEN** 令牌被生成      ← 被动
- **THEN** 系统生成令牌     ← 主动
```