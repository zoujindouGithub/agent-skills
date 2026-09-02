# 多轮模拟 (Multi-turn Simulation)

Harbor 适配器通过一个保持不变的 Harness 会话发送常规消息。在返回响应之前，一个 Harness 轮次（turn）可以包含任意数量的模型或工具调用。

```text
instruction.md -> Harness -> 下一条用户消息 -> 同一个 Harness 会话 -> 重复
                                      |
                                      +-> 停止 (stop)
```

选择一种跟踪模式：

- **脚本化对话 (Scripted conversation)：** 针对稳定作业步骤的预定义消息。例如：“检查失败的结算测试” → “实施修复” → “运行测试”。
- **LLM 模拟用户 (LLM-simulated user)：** 当用户必须根据 Harness 响应进行回答、纠正、拒绝或停止时生成的动态消息。例如：旅客拒绝不合适的航班并确认有效航班。

两种模式均使用 [runner.py](runner.py)：`run_scripted_conversation` 发送固定的轮次，而 `run_llm_user_conversation` 则交替执行 Harness 与 [model_user.py](model_user.py)。LLM 用户接收已批准的契约（contract）、可见的对话记录（transcript）以及用户可见的状态；仅当 JSON 格式错误时才会重试。

## Harbor 接入配置

将 [runner.py](runner.py)、[model_user.py](model_user.py) 和 [harbor_example.py](harbor_example.py) 复制到 `evals/harbor_agents/multi_turn/` 中，然后继承 `MultiTurnHarborAgent`。实现其显式代码库绑定：

1. `create_harness_session`：启动真实的 Harness 一次，并返回一个其 `send` 方法可维持该会话的对象。
2. `scripted_followups` 或 `user_contract`：选择一种模拟模式。
3. `SIMULATOR_MODEL` 和 `call_user_model`：在使用 LLM 用户时，记录模型名称并连接其经批准的客户端。
4. `read_user_observation`：仅返回模拟用户可见的状态；当对话记录已足够时返回 `{}`。

该包装器返回 `HarnessReply(message, evidence)`。其中 `message` 会传递给用户。`evidence` 是在该 Harness 轮次中直接记录的 JSON 安全活动，例如工具调用、结果、状态变更和用量信息。切勿从文本中推断工具使用情况，也切勿在 `public_config`、观测数据（observations）或证据（evidence）中包含凭据。

```python
class FlightSession:
    def __init__(self, real_agent, thread_id):
        self.real_agent = real_agent
        self.session_id = thread_id
        self.public_config = {"model": "agent-model", "tools": ["search", "book"]}

    async def send(self, user_message):
        result = await self.real_agent.send(user_message, thread_id=self.session_id)
        return HarnessReply(result.text, {"tool_calls": result.observed_tool_calls})

class FlightAdapter(MultiTurnHarborAgent):
    SIMULATOR_MODEL = "gpt-5.5"

    def user_contract(self) -> str:
        return """You are Sam, changing an August 12 return flight.
You know username sam. Require departure after 11am and added cost at most $100.
Answer questions, reject invalid options, and stop after confirmed booking or unrecoverable failure."""

    async def create_harness_session(self, environment, context):
        return FlightSession(real_agent, thread_id=self.logs_dir.parent.name)

    async def call_user_model(self, system, payload):
        return await approved_llm_json(system=system, prompt=payload)

    async def read_user_observation(self, environment):
        state = await booking_state(environment)
        return {"booking_confirmed": state["booked"] is not None}
```

`instruction.md` 是第一个 Harness 输入。随后，适配器交替执行已完成的 Harness 轮次和用户消息；它不会向 Harness 添加工具或提示词。停止决策不会添加任何消息，也不会再发起 Harness 调用。停止绝不意味着成功：只有验证器（Verifier）才会判定奖励。

## 校准与审计

运行真实的 Harness 经历与任务相关的各种行为：正确结果、错误结果、澄清请求以及适用情况下的不可恢复故障。检查模拟用户的响应和停止行为是否合情合理。修订契约或模拟器模型，并向用户展示具有代表性的对话。切勿将契约重复实现为脆弱的关键词检查。

当用户提供真实的会话记录（threads）时，仅使用与当前任务相关的观测事实、反应和停止行为来校准模拟用户。切勿将身份信息、原始消息或生产环境记录直接复制到模拟中。

适配器会写入 `interaction.json` 以及按时间顺序排列的 ATIF `trajectory.json`，在 Harness 或模拟器发生故障时还会包含部分证据。确认会话得到了复用、未来的消息未被预加载、停止后没有再调用 Harness、产物和验证器输出可读，并且验证器衡量的是 Harness 而不是模拟器。针对所要求的最终状态和禁止的副作用进行评分；除非特定次数就是预期的结果，否则不要对内部编辑或工具调用的确切次数做硬性要求。