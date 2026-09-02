## 新增需求 (ADDED Requirements)

### Requirement: 深色模式主题切换
系统 SHALL 支持深色模式主题切换，以提升低光环境下的用户体验。

#### Scenario: 用户手动切换主题
- **GIVEN** 用户处于浅色模式
- **WHEN** 用户点击设置中的主题切换开关
- **THEN** 界面立即应用深色模式样式
- **AND** 将 "dark" 保存到 localStorage 的 "theme" 键

#### Scenario: 系统主题偏好跟随
- **GIVEN** 用户首次访问且未设置过主题偏好
- **WHEN** 系统检测到操作系统偏好为深色模式
- **THEN** 默认应用深色模式
- **AND** 不覆盖 localStorage（允许后续手动切换）

#### Scenario: 主题持久化
- **GIVEN** 用户之前选择了深色模式
- **WHEN** 用户重新打开应用
- **THEN** 系统读取 localStorage 中的主题偏好
- **AND** 应用对应的主题样式

#### Scenario: 主题切换动画
- **GIVEN** 用户处于浅色模式
- **WHEN** 用户切换主题
- **THEN** 主题过渡在 200ms 内完成
- **AND** 使用 CSS transition 实现平滑切换

## 修改需求 (MODIFIED Requirements)

### Requirement: 设置页面布局
设置页面 SHALL 支持分组展示配置项，主题设置作为独立分组。

#### Scenario: 访问设置页面
- **GIVEN** 用户已登录
- **WHEN** 用户导航到 /settings
- **THEN** 页面显示"外观"分组，包含主题切换开关
- **AND** 显示当前选中的主题名称（浅色/深色/跟随系统）

#### Scenario: 主题设置交互
- **GIVEN** 用户在设置页面
- **WHEN** 用户点击主题选择下拉框
- **THEN** 显示选项：浅色、深色、跟随系统
- **AND** 选择后立即应用预览（无需保存按钮）

## 移除需求 (REMOVED Requirements)

### Requirement: 旧版主题硬编码颜色
移除原因：所有颜色值已迁移到 CSS 变量，不再使用硬编码颜色。