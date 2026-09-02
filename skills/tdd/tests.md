# 优秀与糟糕的测试

## 优秀测试

**集成风格**：通过真实接口进行测试，而不是模拟（Mock）内部组件。

```typescript
// 优秀：测试可观察的行为
test("user can checkout with valid cart", async () => {
  const cart = createCart();
  cart.add(product);
  const result = await checkout(cart, paymentMethod);
  expect(result.status).toBe("confirmed");
});
```

特征：

- 测试用户/调用方关心的行为
- 仅使用公开 API
- 内部重构后测试依然有效
- 描述“做什么”（WHAT），而不是“怎么做”（HOW）
- 每个测试包含一个逻辑断言

## 糟糕测试

**实现细节测试**：与内部结构强耦合。

```typescript
// 糟糕：测试实现细节
test("checkout calls paymentService.process", async () => {
  const mockPayment = jest.mock(paymentService);
  await checkout(cart, payment);
  expect(mockPayment.process).toHaveBeenCalledWith(cart.total);
});
```

危险信号：

- 模拟内部协作组件
- 测试私有方法
- 断言调用次数/调用顺序
- 在行为未改变的重构中测试发生损坏
- 测试名称描述的是“怎么做”而不是“做什么”
- 通过外部手段而非接口进行验证

```typescript
// 糟糕：绕过接口进行验证
test("createUser saves to database", async () => {
  await createUser({ name: "Alice" });
  const row = await db.query("SELECT * FROM users WHERE name = ?", ["Alice"]);
  expect(row).toBeDefined();
});

// 优秀：通过接口进行验证
test("createUser makes user retrievable", async () => {
  const user = await createUser({ name: "Alice" });
  const retrieved = await getUser(user.id);
  expect(retrieved.name).toBe("Alice");
});
```

**重言式测试（同义反复测试）**：期望值只是对代码实现的重述，导致测试在构造上必然通过。

```typescript
// 糟糕：期望值按照代码计算的方式重新计算了一遍
test("calculateTotal sums line items", () => {
  const items = [{ price: 10 }, { price: 5 }];
  const expected = items.reduce((sum, i) => sum + i.price, 0);
  expect(calculateTotal(items)).toBe(expected);
});

// 优秀：期望值是一个独立的、已知的字面量
test("calculateTotal sums line items", () => {
  expect(calculateTotal([{ price: 10 }, { price: 5 }])).toBe(15);
});
```