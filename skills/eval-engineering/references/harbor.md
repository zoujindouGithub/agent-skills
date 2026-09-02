# Harbor 任务与运行契约

使用最新版本的 Harbor。通过 Docker 在本地安装并运行，或使用受支持的云环境；请参阅 [Harbor 文档](https://www.harborframework.com/docs)。使用已安装的 CLI 帮助信息作为命令契约。

## 源码与运行输出

将任务源码保存在 `evals/` 目录下，生成的运行凭证保存在 `evals/jobs/` 目录下：

```text
evals/
├── <task-id>/
│   ├── task.toml
│   ├── instruction.md
│   ├── environment/
│   └── tests/
├── harbor_agents/              # Harness 适配器，仅在需要时提供
├── configs/                    # 仅在需要非默认配置时提供
└── jobs/                       # 生成的运行凭证
```

每个包含 `task.toml` 的目录都是一个任务。将指令、环境资产（Environment assets）、验证器代码（Verifier code）、隐藏裁判凭证（hidden judge evidence），以及任务的 `task.md`、`harness.md` 和 `environment.md` 审查文件保留在其中。切勿将审查文件挂载到 Harness 工作区或任务镜像中。请勿添加规划方案、追踪导出文件、审计文件、凭据或复制的运行输出。

Harness 适配器可以转换输入/输出并绑定已批准的依赖项。它绝不能对任务进行判定、包含答案或伪造动作。适配器和 Verifier 必须将 Harness 响应/动作记录、Verifier 凭据、裁决/原因、奖励和错误保留在 Harbor 制品或日志中。

记录任务目录之外的 Harness 源码摘要（digest），因为 Harbor 的任务校验和（checksum）可能未覆盖它。源码的任何变更都会导致先前的运行凭证失效。

## 生命周期

```bash
mkdir -p evals
harbor tasks init "<task-id>" --tasks-dir evals --no-solution

harbor run \
  --path evals \
  --include-task-name <task-id> \
  --agent <harness-or-adapter> \
  --env docker \
  --jobs-dir evals/jobs \
  --print-config

harbor run \
  --path evals \
  --include-task-name <task-id> \
  --agent <harness-or-adapter> \
  --env docker \
  --jobs-dir evals/jobs \
  --job-name <job-name>
```

`--print-config` 仅解析配置而不执行。删除仅用于脚手架生成的文件，例如生成的任务 README。Harbor 脚手架默认生成 `network_mode = "public"`；在进行任何带有凭据的运行之前，请将其替换为已批准的网络策略。

在 Harness 运行之前，通过 Harbor 将使用的相同镜像和命令执行 Verifier 的针对性测试用例（fixtures）。将校准结果保留在其日志或制品中。

## 环境与凭证

Docker 为默认环境。在完成场景之前，启动任务所需的最小镜像、服务、挂载和网络配置。在运行时仅通过环境变量引用的方式传递已批准的凭据。

默认无网络连接。仅允许已批准的实时依赖项所需的主机。确保 Verifier 凭据和隐藏凭证对 Harness 不可用。如果 Docker 无法提供所需功能，请进行说明并商定受支持的 Harbor 环境；切勿隐默地削弱隔离性。

通过解析后的后端状态，或通过受控的允许主机与拒绝主机探测来验证实际生效的网络边界。仅在 `task.toml` 中声明并不能证明已强制执行。如果后端无法暴露或测试该策略，请报告该限制，而不是声称白名单已通过验证。

job 目录即为运行记录。读取实际的试验（trial）文件并关联分析：

- 来自 ATIF 或等效制品的 Harness 响应和动作；
- Harness 记录的调用以及环境观测到的结果/状态；
- Verifier 凭据、裁决、原因和日志；
- 奖励、解析后的配置、耗时和阶段错误。

仅在 Harness 或环境观测到动作和状态时才信任它们。智能体工作出错将获得 0 奖励；构建、适配器、凭据、重置、超时、裁判或 Verifier 失败均属于基础设施错误。保留 `evals/jobs/`，直到用户接受、修改或放弃该评测。

在每个事件发生时记录消息、调用、观测和响应，以使 ATIF 时间戳保持按时间顺序排列。在审查之前，确保每次尝试的试验均已完成，或被明确归类为已取消或基础设施错误；不要将无限期挂起的试验视为凭证。

对于多轮运行，还需从 ATIF 和适配器凭据中验证：

- 第一个 Harness 输入与 `instruction.md` 完全一致；
- 随后的每条用户消息均被记录为脚本预设或关联至 LLM 用户的决策；
- 每次 Harness 调用均使用相同的已批准会话（session）或线程（thread）；
- 没有将未来的用户消息预先加载到 Harness 上下文中；
- 终止状态具有适配器记录的原因，且随后未发生 Harness 调用。