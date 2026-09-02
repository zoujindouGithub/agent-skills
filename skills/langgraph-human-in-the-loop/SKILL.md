---
name: langgraph-human-in-the-loop
description: "在 LangGraph 中实现人机协同（human-in-the-loop）模式、暂停等待审批或处理错误时调用此技能。涵盖 interrupt()、Command(resume=...)、审批/验证工作流以及 4 级错误处理策略。"
---

<overview>
LangGraph 的人机协同模式允许你暂停图的执行、向用户展示数据，并在获取用户输入后恢复执行：

- **`interrupt(value)`** — 暂停执行，向调用方展示一个值
- **`Command(resume=value)`** — 恢复执行，将值传回给 `interrupt()`
- **Checkpointer（检查点保存器）** — 暂停期间保存状态所必需
- **Thread ID（线程 ID）** — 标识需要恢复哪个已暂停的执行所必需
</overview>

---

## 前置要求

中断机制正常工作需要满足三个条件：

1. **Checkpointer** — 使用 `checkpointer=InMemorySaver()`（开发环境）或 `PostgresSaver`（生产环境）进行编译
2. **Thread ID** — 在每次 `invoke`/`stream` 调用中传入 `{"configurable": {"thread_id": "..."}}`
3. **可 JSON 序列化的负载** — 传递给 `interrupt()` 的值必须是可 JSON 序列化的

---

## 基础中断与恢复（Interrupt + Resume）

`interrupt(value)` 会暂停图的执行。该值会暴露在返回结果的 `__interrupt__` 字段中。`Command(resume=value)` 用于恢复执行 — resume 的值将成为 `interrupt()` 的返回值。

**关键注意点**：当图恢复执行时，节点会从**开头**重新启动 — `interrupt()` 之前的所有代码都会重新运行。

<ex-basic-interrupt-resume>
<python>
暂停执行以等待人工审核，并使用 Command 恢复。

```python
from langgraph.types import interrupt, Command
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.graph import StateGraph, START, END
from typing_extensions import TypedDict

class State(TypedDict):
    approved: bool

def approval_node(state: State):
    # 暂停并请求审批
    approved = interrupt("Do you approve this action?")
    # 恢复执行时，Command(resume=...) 会在此处返回该值
    return {"approved": approved}

checkpointer = InMemorySaver()
graph = (
    StateGraph(State)
    .add_node("approval", approval_node)
    .add_edge(START, "approval")
    .add_edge("approval", END)
    .compile(checkpointer=checkpointer)
)

config = {"configurable": {"thread_id": "thread-1"}}

# 初始运行 — 触发 interrupt 并暂停
result = graph.invoke({"approved": False}, config)
print(result["__interrupt__"])
# [Interrupt(value='Do you approve this action?')]

# 使用人工的响应恢复执行
result = graph.invoke(Command(resume=True), config)
print(result["approved"])  # True
```
</python>
<typescript>
暂停执行以等待人工审核，并使用 Command 恢复。

```typescript
import { interrupt, Command, MemorySaver, StateGraph, StateSchema, START, END } from "@langchain/langgraph";
import { z } from "zod";

const State = new StateSchema({
  approved: z.boolean().default(false),
});

const approvalNode = async (state: typeof State.State) => {
  // 暂停并请求审批
  const approved = interrupt("Do you approve this action?");
  // 恢复执行时，Command({ resume }) 会在此处返回该值
  return { approved };
};

const checkpointer = new MemorySaver();
const graph = new StateGraph(State)
  .addNode("approval", approvalNode)
  .addEdge(START, "approval")
  .addEdge("approval", END)
  .compile({ checkpointer });

const config = { configurable: { thread_id: "thread-1" } };

// 初始运行 — 触发 interrupt 并暂停
let result = await graph.invoke({ approved: false }, config);
console.log(result.__interrupt__);
// [{ value: 'Do you approve this action?', ... }]

// 使用人工的响应恢复执行
result = await graph.invoke(new Command({ resume: true }), config);
console.log(result.approved);  // true
```
</typescript>
</ex-basic-interrupt-resume>

---

## 审批工作流（Approval Workflow）

一种常见模式：通过中断展示草稿，然后根据人工决策进行路由。

<ex-approval-workflow>
<python>
中断执行以等待人工审核，然后根据决策路由至发送或结束。

```python
from langgraph.types import interrupt, Command
from langgraph.graph import StateGraph, START, END
from typing import Literal
from typing_extensions import TypedDict

class EmailAgentState(TypedDict):
    email_content: str
    draft_response: str
    classification: dict

def human_review(state: EmailAgentState) -> Command[Literal["send_reply", "__end__"]]:
    """使用 interrupt 暂停以等待人工审核，并根据决策进行路由。"""
    classification = state.get("classification", {})

    # interrupt() 必须放在最前面 — 其前面的任何代码都会在恢复时重新运行
    human_decision = interrupt({
        "email_id": state.get("email_content", ""),
        "draft_response": state.get("draft_response", ""),
        "urgency": classification.get("urgency"),
        "action": "Please review and approve/edit this response"
    })

    # 处理人工决策
    if human_decision.get("approved"):
        return Command(
            update={"draft_response": human_decision.get("edited_response", state.get("draft_response", ""))},
            goto="send_reply"
        )
    else:
        # 拒绝 — 将由人工直接处理
        return Command(update={}, goto=END)
```
</python>
<typescript>
中断执行以等待人工审核，然后根据决策路由至发送或结束。

```typescript
import { interrupt, Command, END, GraphNode } from "@langchain/langgraph";

const humanReview: GraphNode<typeof EmailAgentState> = async (state) => {
  const classification = state.classification!;

  // interrupt() 必须放在最前面 — 其前面的任何代码都会在恢复时重新运行
  const humanDecision = interrupt({
    emailId: state.emailContent,
    draftResponse: state.responseText,
    urgency: classification.urgency,
    action: "Please review and approve/edit this response",
  });

  // 处理人工决策
  if (humanDecision.approved) {
    return new Command({
      update: { responseText: humanDecision.editedResponse || state.responseText },
      goto: "sendReply",
    });
  } else {
    return new Command({ update: {}, goto: END });
  }
};
```
</typescript>
</ex-approval-workflow>

---

## 验证循环（Validation Loop）

在循环中使用 `interrupt()` 来验证人工输入，如果输入无效则重新提示。

<ex-validation-loop>
<python>
在循环中验证人工输入，重复提示直到输入有效。

```python
from langgraph.types import interrupt

def get_age_node(state):
    prompt = "What is your age?"

    while True:
        answer = interrupt(prompt)

        # 验证输入
        if isinstance(answer, int) and answer > 0:
            break
        else:
            # 输入无效 — 使用更具体的提示重新询问
            prompt = f"'{answer}' is not a valid age. Please enter a positive number."

    return {"age": answer}
```

每次 `Command(resume=...)` 调用都会提供下一次的回答。如果输入无效，循环会带着更明确的提示信息再次中断。

```python
config = {"configurable": {"thread_id": "form-1"}}
first = graph.invoke({"age": None}, config)
# __interrupt__: "What is your age?"

retry = graph.invoke(Command(resume="thirty"), config)
# __interrupt__: "'thirty' is not a valid age..."

final = graph.invoke(Command(resume=30), config)
print(final["age"])  # 30
```
</python>
<typescript>
在循环中验证人工输入，重复提示直到输入有效。

```typescript
import { interrupt } from "@langchain/langgraph";

const getAgeNode = (state: typeof State.State) => {
  let prompt = "What is your age?";

  while (true) {
    const answer = interrupt(prompt);

    // 验证输入
    if (typeof answer === "number" && answer > 0) {
      return { age: answer };
    } else {
      // 输入无效 — 使用更具体的提示重新询问
      prompt = `'${answer}' is not a valid age. Please enter a positive number.`;
    }
  }
};
```
</typescript>
</ex-validation-loop>

---

## 多重中断（Multiple Interrupts）

当多个并行分支各自调用 `interrupt()` 时，可以通过将每个中断 ID 映射到其对应的 resume 值，在单次调用中恢复所有中断。

<ex-multiple-interrupts>
<python>
通过将中断 ID 映射到对应值来恢复多个并行中断。

```python
from typing import Annotated, TypedDict
import operator
from langgraph.checkpoint.memory import InMemorySaver
from langgraph.graph import START, END, StateGraph
from langgraph.types import Command, interrupt

class State(TypedDict):
    vals: Annotated[list[str], operator.add]

def node_a(state):
    answer = interrupt("question_a")
    return {"vals": [f"a:{answer}"]}

def node_b(state):
    answer = interrupt("question_b")
    return {"vals": [f"b:{answer}"]}

graph = (
    StateGraph(State)
    .add_node("a", node_a)
    .add_node("b", node_b)
    .add_edge(START, "a")
    .add_edge(START, "b")
    .add_edge("a", END)
    .add_edge("b", END)
    .compile(checkpointer=InMemorySaver())
)

config = {"configurable": {"thread_id": "1"}}

# 两个并行节点均触发 interrupt() 并暂停
result = graph.invoke({"vals": []}, config)
# result["__interrupt__"] 包含带有 ID 的两个 Interrupt 对象

# 使用 id -> value 的映射一次性恢复所有挂起的中断
resume_map = {
    i.id: f"answer for {i.value}"
    for i in result["__interrupt__"]
}
result = graph.invoke(Command(resume=resume_map), config)
# result["vals"] = ["a:answer for question_a", "b:answer for question_b"]
```
</python>
<typescript>
通过将中断 ID 映射到对应值来恢复多个并行中断。

```typescript
import { Command, END, MemorySaver, START, StateGraph, interrupt, isInterrupted, INTERRUPT, Annotation } from "@langchain/langgraph";

const State = Annotation.Root({
  vals: Annotation<string[]>({
    reducer: (left, right) => left.concat(Array.isArray(right) ? right : [right]),
    default: () => [],
  }),
});

function nodeA(_state: typeof State.State) {
  const answer = interrupt("question_a") as string;
  return { vals: [`a:${answer}`] };
}

function nodeB(_state: typeof State.State) {
  const answer = interrupt("question_b") as string;
  return { vals: [`b:${answer}`] };
}

const graph = new StateGraph(State)
  .addNode("a", nodeA)
  .addNode("b", nodeB)
  .addEdge(START, "a")
  .addEdge(START, "b")
  .addEdge("a", END)
  .addEdge("b", END)
  .compile({ checkpointer: new MemorySaver() });

const config = { configurable: { thread_id: "1" } };

const interruptedResult = await graph.invoke({ vals: [] }, config);

// 一次性恢复所有挂起的中断
const resumeMap: Record<string, string> = {};
if (isInterrupted(interruptedResult)) {
  for (const i of interruptedResult[INTERRUPT]) {
    if (i.id != null) {
      resumeMap[i.id] = `answer for ${i.value}`;
    }
  }
}
const result = await graph.invoke(new Command({ resume: resumeMap }), config);
// result.vals = ["a:answer for question_a", "b:answer for question_b"]
```
</typescript>
</ex-multiple-interrupts>

用户可修复的错误可以使用 `interrupt()` 暂停并收集缺失的数据 — 这正是本技能所涵盖的模式。有关完整的 4 级错误处理策略（RetryPolicy、Command 错误循环等），请参阅 **fundamentals** 技能。

---

## 中断前的副作用必须具备幂等性

当图恢复执行时，节点会从**开头**重新启动 — `interrupt()` 之前的**所有**代码都会重新运行。在子图中，父节点和子图节点**都会**重新执行。

<idempotency-rules>

**推荐做法（Do）：**
- 在 `interrupt()` 之前使用 **upsert**（更新或插入，而非纯插入）操作
- 使用**先检查后创建（check-before-create）**模式
- 尽可能将副作用放置在 `interrupt()` **之后**
- 将副作用拆分到独立的节点中

**禁止做法（Don't）：**
- 在 `interrupt()` 之前创建新记录 — 每次恢复时都会产生重复记录
- 在 `interrupt()` 之前向列表中追加元素 — 每次恢复时都会产生重复项

</idempotency-rules>

<ex-idempotent-patterns>
<python>
中断前的幂等操作与非幂等操作（错误示范）对比。

```python
# 正确：Upsert 具有幂等性 — 在 interrupt 之前执行是安全的
def node_a(state: State):
    db.upsert_user(user_id=state["user_id"], status="pending_approval")
    approved = interrupt("Approve this change?")
    return {"approved": approved}

# 正确：副作用放在 interrupt 之后 — 仅运行一次
def node_a(state: State):
    approved = interrupt("Approve this change?")
    if approved:
        db.create_audit_log(user_id=state["user_id"], action="approved")
    return {"approved": approved}

# 错误：Insert 在每次恢复执行时都会创建重复记录！
def node_a(state: State):
    audit_id = db.create_audit_log({  # 恢复执行时会再次运行！
        "user_id": state["user_id"],
        "action": "pending_approval",
    })
    approved = interrupt("Approve this change?")
    return {"approved": approved}
```
</python>
<typescript>
中断前的幂等操作与非幂等操作（错误示范）对比。

```typescript
// 正确：Upsert 具有幂等性 — 在 interrupt 之前执行是安全的
const nodeA = async (state: typeof State.State) => {
  await db.upsertUser({ userId: state.userId, status: "pending_approval" });
  const approved = interrupt("Approve this change?");
  return { approved };
};

// 正确：副作用放在 interrupt 之后 — 仅运行一次
const nodeA = async (state: typeof State.State) => {
  const approved = interrupt("Approve this change?");
  if (approved) {
    await db.createAuditLog({ userId: state.userId, action: "approved" });
  }
  return { approved };
};

// 错误：Insert 在每次恢复执行时都会创建重复记录！
const nodeA = async (state: typeof State.State) => {
  await db.createAuditLog({  // 恢复执行时会再次运行！
    userId: state.userId,
    action: "pending_approval",
  });
  const approved = interrupt("Approve this change?");
  return { approved };
};
```
</typescript>
</ex-idempotent-patterns>

<subgraph-interrupt-re-execution>

### 子图在恢复执行时的重复执行行为

当子图中包含 `interrupt()` 时，恢复执行会同时重新执行父节点（调用子图的节点）**以及**子图节点（调用 `interrupt()` 的节点）：

<python>

```python
def node_in_parent_graph(state: State):
    some_code()  # <-- 恢复执行时会重新运行
    subgraph_result = subgraph.invoke(some_input)
    # ...

def node_in_subgraph(state: State):
    some_other_code()  # <-- 恢复执行时也会重新运行
    result = interrupt("What's your name?")
    # ...
```
</python>
<typescript>

```typescript
async function nodeInParentGraph(state: State) {
  someCode();  // <-- 恢复执行时会重新运行
  const subgraphResult = await subgraph.invoke(someInput);
  // ...
}

async function nodeInSubgraph(state: State) {
  someOtherCode();  // <-- 恢复执行时也会重新运行
  const result = interrupt("What's your name?");
  // ...
}
```
</typescript>
</subgraph-interrupt-re-execution>

---

## Command(resume) 警告

`Command(resume=...)` 是**唯一定义用于**作为 `invoke()`/`stream()` 输入的 Command 模式。**切勿**将 `Command(update=...)` 作为输入传入 — 它会从最新检查点恢复，并导致图看起来处于卡死状态。有关反面模式的完整解释，请参阅 fundamentals 技能。

---

## 修复指南（Fixes）

<fix-checkpointer-required-for-interrupts>
<python>
中断功能必须配置 Checkpointer。

```python
# 错误
graph = builder.compile()

# 正确
graph = builder.compile(checkpointer=InMemorySaver())
```
</python>
<typescript>
中断功能必须配置 Checkpointer。

```typescript
// 错误
const graph = builder.compile();

// 正确
const graph = builder.compile({ checkpointer: new MemorySaver() });
```
</typescript>
</fix-checkpointer-required-for-interrupts>

<fix-resume-with-command>
<python>
使用 Command 从中断中恢复（传入常规 dict 会重新启动图）。

```python
# 错误
graph.invoke({"resume_data": "approve"}, config)

# 正确
graph.invoke(Command(resume="approve"), config)
```
</python>
<typescript>
使用 Command 从中断中恢复（传入常规对象会重新启动图）。

```typescript
// 错误
await graph.invoke({ resumeData: "approve" }, config);

// 正确
await graph.invoke(new Command({ resume: "approve" }), config);
```
</typescript>
</fix-resume-with-command>

<boundaries>
### 禁止事项（What You Should NOT Do）

- 在未配置 checkpointer 的情况下使用中断 — 将会导致失败
- 恢复执行时未传入相同的 thread_id — 会创建新线程而非恢复原流程
- 将 `Command(update=...)` 作为 invoke 输入传入 — 图会看似卡死（请使用普通 dict）
- 在 `interrupt()` 之前执行非幂等的副作用 — 恢复时会产生重复数据
- 假定 `interrupt()` 之前的代码只会执行一次 — 每次恢复时它都会重新运行
</boundaries>