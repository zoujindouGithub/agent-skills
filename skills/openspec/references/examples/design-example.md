# 技术设计：深色模式支持

## Technical Approach

采用 CSS 变量（Custom Properties）方案，在 `:root` 和 `[data-theme="dark"]` 作用域下定义两套颜色 token。通过切换 `data-theme` 属性实现主题切换，利用 CSS transition 实现平滑过渡。

替代方案评估：
- CSS-in-JS（Styled Components）：运行时开销大，不适合本项目
- 类名切换（如 `.dark`）：与 CSS 变量方案类似，但变量方案更灵活
- 独立 CSS 文件：增加请求数，维护成本高

**选定方案：CSS 变量 + data-theme 属性**

## Data Model Changes

无数据库变更。主题偏好存储在客户端 localStorage。

```typescript
// localStorage key: "theme"
// values: "light" | "dark" | "system"
```

## API Changes

无 API 变更。主题切换为纯客户端功能。

## Frontend Changes

### 1. 主题上下文提供者

```typescript
// src/theme/ThemeProvider.tsx
interface ThemeContextType {
  theme: 'light' | 'dark' | 'system';
  setTheme: (theme: 'light' | 'dark' | 'system') => void;
  resolvedTheme: 'light' | 'dark';  // 实际应用的主题（system 已解析）
}
```

### 2. 主题检测与初始化

```typescript
// src/theme/useSystemTheme.ts
// 监听 matchMedia('(prefers-color-scheme: dark)')
// 当 theme === 'system' 时，跟随系统偏好
```

### 3. 主题切换组件

```typescript
// src/components/ThemeToggle.tsx
// 下拉选择：浅色 / 深色 / 跟随系统
// 实时预览，无需确认
```

### 4. CSS 变量定义

```css
/* src/styles/theme.css */
:root {
  --color-bg-primary: #ffffff;
  --color-bg-secondary: #f5f5f5;
  --color-text-primary: #1a1a1a;
  --color-text-secondary: #666666;
  --color-border: #e0e0e0;
  --color-accent: #0066cc;
  /* ... 其他 token */
}

[data-theme="dark"] {
  --color-bg-primary: #1a1a1a;
  --color-bg-secondary: #2d2d2d;
  --color-text-primary: #ffffff;
  --color-text-secondary: #a0a0a0;
  --color-border: #404040;
  --color-accent: #4d9fff;
  /* ... 其他 token */
}

/* 过渡动画 */
* {
  transition: background-color 200ms ease,
              color 200ms ease,
              border-color 200ms ease;
}
```

### 5. 组件更新清单

| 组件 | 变更内容 |
|------|----------|
| Button | 使用 `--color-accent` 替代硬编码蓝色 |
| Card | 使用 `--color-bg-secondary` 替代 `#f5f5f5` |
| Input | 使用 `--color-border` 替代 `#e0e0e0` |
| Text | 使用 `--color-text-primary` 替代 `#1a1a1a` |
| Header | 使用 `--color-bg-primary` 替代 `#ffffff` |
| Modal | 使用 `--color-bg-primary` 和 `--color-border` |
| Table | 使用 `--color-bg-secondary` 作为斑马纹背景 |
| Toast | 使用 `--color-accent` 作为成功色 |

### 6. 设置页面更新

在 `/settings` 添加"外观"分组：

```typescript
// src/pages/Settings/AppearanceSection.tsx
// 包含 ThemeToggle 组件
// 显示当前主题名称
```

## Testing Strategy

### 单元测试

- `ThemeProvider`：主题切换、localStorage 读写、系统偏好监听
- `useSystemTheme`：matchMedia 监听、回调清理
- `ThemeToggle`：用户交互、下拉选择

### 视觉回归测试

- 关键页面截图对比（浅色 vs 深色）
- 使用 Chromatic 或 Percy
- 覆盖：首页、设置页、表单页、表格页

### 手动测试清单

- [ ] 浅色 → 深色切换平滑
- [ ] 深色 → 浅色切换平滑
- [ ] 系统偏好为深色时首次访问正确
- [ ] 系统偏好变化时实时跟随（当选择"跟随系统"）
- [ ] 刷新页面后主题偏好保持
- [ ] 所有组件在两种主题下可读
- [ ] 第三方组件（如图表库）不破坏主题

## Deployment Plan

### Phase 1：功能开发（本次变更）

- 实现 ThemeProvider、ThemeToggle、CSS 变量
- 更新所有组件
- 添加测试

### Phase 2：灰度发布（后续变更）

- 添加 feature flag `darkMode`
- 仅对 10% 用户开放
- 收集反馈

### Phase 3：全量发布（后续变更）

- 移除 feature flag
- 全量用户可用
- 更新用户文档

## Performance Considerations

- CSS 变量方案零运行时开销
- 200ms transition 使用 GPU 加速的 `transform` 和 `opacity`
- localStorage 读取在初始化时同步完成，无闪烁
- 系统偏好监听使用 `matchMedia`，内存占用极小

## Accessibility

- 确保深色模式下对比度符合 WCAG AA 标准（4.5:1）
- 主题切换控件有明确的 aria-label
- 尊重 `prefers-color-scheme` 媒体查询（无障碍需求）
