# 何时进行 Mock

仅在**系统边界**处进行 Mock：

- 外部 API（支付、电子邮件等）
- 数据库（视情况而定——优先使用测试数据库）
- 时间 / 随机性
- 文件系统（视情况而定）

不要 Mock：

- 你自己的类/模块
- 内部协作者
- 任何由你控制的代码

## 针对可 Mock 性进行设计

在系统边界处，设计易于 Mock 的接口：

**1. 使用依赖注入**

将外部依赖项传入，而不是在内部创建它们：

```typescript
// 易于 Mock
function processPayment(order, paymentClient) {
  return paymentClient.charge(order.total);
}

// 难以 Mock
function processPayment(order) {
  const client = new StripeClient(process.env.STRIPE_KEY);
  return client.charge(order.total);
}
```

**2. 优先选择 SDK 风格的接口，而非通用的请求方法**

为每个外部操作创建具体的函数，而不是使用一个带有条件逻辑的通用函数：

```typescript
// 推荐：每个函数都可以独立进行 Mock
const api = {
  getUser: (id) => fetch(`/users/${id}`),
  getOrders: (userId) => fetch(`/users/${userId}/orders`),
  createOrder: (data) => fetch('/orders', { method: 'POST', body: data }),
};

// 不推荐：Mock 时需要在 Mock 内部编写条件逻辑
const api = {
  fetch: (endpoint, options) => fetch(endpoint, options),
};
```

采用 SDK 风格意味着：
- 每个 Mock 返回一种特定的数据结构
- 测试设置中无需编写条件逻辑
- 更容易看清测试涉及了哪些端点
- 每个端点都具备类型安全