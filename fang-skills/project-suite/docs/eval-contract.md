# Eval Contract — 评估证据与治理契约分离

> `project-suite` = 要执行的能力 / 协议；`project-suite-eval` = 判断能力是否有效的实验数据。
> 两者分离，但本文件定义它们之间的**契约**：Suite 需要什么证据、字段是什么、判定标准是什么、证据放在哪。
> 本文件是 Suite 内唯一描述「外部 eval 证据」的入口——其他文档不再引用 `../../project-suite-eval/...` 相对路径。

## 为什么分离

- **project-suite** = 可执行能力 + 治理契约（Skill / Protocol / Registry / Gate）。随 zip 分发。
- **project-suite-eval** = 判断「这条 Skill 规则是否真的改变了 Agent 行为」的实验数据（benchmark / pressure-tests / results / ledger）。
- 证据不属于 skill 本身：pressure test 数据、ledger 记录、benchmark round 是「能力验证」，不是「能力定义」，不随 Suite 分发。

## 外部仓库（sibling，非 Suite 内相对路径）

`project-suite-eval/` 是 project-suite 的**兄弟仓库 / workspace package**，需单独获取，不是 `project-suite/` 内的目录。约定结构：

```
project-suite-eval/
├── benchmark/
│   └── pressure-tests/<skill>.yaml    # 反例场景（设计时预测）
├── results/*.yaml                     # naive vs suite 真实跑出的产出对比
├── mechanism-verification-ledger.md   # 判定结论唯一入口
└── hooks/                             # Host adapter 脚本（如 command-guard-hook.sh）
```

## 契约字段

### 判定结论唯一入口：ledger

`mechanism-verification-ledger.md` 记录「机制是否改变行为 + 可复现性」，字段：

| 字段 | 含义 |
|------|------|
| `hypothesis` | 这条机制要改变什么行为 |
| `native_baseline` | 朴素 Agent（不加载 Skill）的真实产出 |
| `suite_behavior` | 加载 Skill 后的真实产出 |
| `evidence` | 反例 / 证据（真实任务） |
| `repeatability` | 可复现性（跨 run 是否稳定） |
| `pass_fail` | 判定结论 |

### 三层流水线（同一件事的三个视图）

| 层 | 文件 | 字段 |
|----|------|------|
| 设计（预测） | `benchmark/pressure-tests/<skill>.yaml` | `scenario` / `naive_failure` / `skill_mechanism` / `assertion` |
| 运行（观察） | `results/*.yaml` | `native:` / `suite:` 块 |
| 记录（判定） | `mechanism-verification-ledger.md` | `hypothesis` / `native_baseline` / `suite_behavior` / `evidence` / `repeatability` / `pass_fail` |

> `naive_failure`（预测）与 `native_baseline`（观察）是同一件事的「事前 / 事后」两态；判断有效性的结论只写在 ledger。

### 两种 baseline（ablation）

四象限表要能判「装饰品」，前提是有一个**关掉它的对照臂**。但本契约此前只定义了**一种** baseline：

| 类型 | 对照臂是什么 | 用来判 |
|------|-------------|--------|
| `native_baseline` | 朴素 Agent，**不加载任何 Skill** | 这条 **Skill** 是否改变行为 |
| `mechanism_baseline` | **加载 Skill，但关掉这一个机制** | 这条**机制**是否值得存在 |

**为什么必须分开**：用 skill 级 baseline 去判机制，得到的永远是「skill 整体有用」，
而不是「**这一层机制**有用」——于是机制可以无限叠加而没有任何一条能被证伪。
实证：round8 的「14/14 机制装饰品」是 **skill 级**结论；而 Resolver / Registry / Gate / 新 prompt /
新 artifact / 新字段这类**机制级**对象，至今**没有一条 ablation 记录**（见 roadmap「已知缺口」G1）。

### 新增机制的准入义务

新增**机制**（上列任一类）进入核心前，必须：

1. 先在本契约的 ledger 里写一条 `hypothesis` —— 它打算改变什么行为
2. 给出 `mechanism_baseline`（关掉它）与 `suite_behavior`（打开它）的对比
3. 照走四象限：**「❌ 不失败 / ✅ 通过 → 装饰品，删」同样适用于机制**

> 给不出 ablation 的机制**不进核心**——可留在实验层并显式标注 experimental，
> 但**不得被其他组件依赖**（否则它会通过依赖关系变成事实上的核心）。
>
> **状态：Specified。** 本义务是治理约定，**无机器强制**（本文件的性质即是两仓之间的契约，
> 靠评审把关，不是可执行门禁）。不要假装它是 enforced——这正是 roadmap 四态模型要避免的
> 「假完成」。若将来要自动化，正确做法是在 CI 里跑 eval 仓的 ablation，而不是在本仓加一条
> 永远为真的声明。

## 判定标准（四象限）

| naive 失败 | suite 通过 | 结论 |
|-----------|-----------|------|
| ✅ 失败 | ✅ 通过 | 规则有效，保留 |
| ✅ 失败 | ❌ 不通过 | 规则不够，补规则 |
| ❌ 不失败 | ✅ 通过 | 规则是装饰品，删 |
| ❌ 不失败 | ❌ 不通过 | 场景本身无效，改场景 |

## Suite 内引用规则

- Suite 内文档（`pressure-testing.md` / `benchmarks.md` / `cross-run-reliability.md` / `adapters/*.md`）**不引用** `../../project-suite-eval/...` 相对路径。
- 需要指向行为评估结论时，统一引用本文件；由本文件说明外部证据在哪、如何获取。
