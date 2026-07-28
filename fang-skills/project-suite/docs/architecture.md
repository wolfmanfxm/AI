# Suite Architecture v0.7.0

> project-suite 自身的架构设计决策记录。

**当前版本: v0.7.0** — 核心变化：
- Knowledge Lifecycle v2.0（Artifact→Candidate→Accepted→Deprecated）
- 10 字段标准 Interface（9 Skill 对齐）
- Artifact Registry（12 个统一类型）
- User-as-Dispatcher（用户始终是 Dispatcher）
- YAML 配置（scheduler.yaml + gates.yaml + artifact-types.yaml + workflow YAML）

## 设计原则

### 1. Skill 即插件

每个 skill 是独立的、可单独触发的单元。skill 不感知其他 skill 的存在，只通过 `runtime/` 和 `shared/` 与外界交互。

**含义**：
- 用户可以只装 analyzer + generator，不需要装全部 9 个
- 新增 skill 不需要修改已有 skill
- runtime/ 中的协议向下兼容

### 2. Protocol 属于框架，不属于 skill

skill 内部不包含 protocol 文件。所有 skill 共享 `runtime/` 中的协议定义。

**决策记录**：最初 analyzer 自带 protocol/，但扩展到 9 个 skill 后如果每个 skill 都维护自己的状态机、断点续传、异常处理，必然产生 9 份重复且不一致的实现。

### 3. 数据通过文件传递

skill 之间不通过内存或函数调用通信，而是通过 manifest.json + 产出文件。

**理由**：
- Claude Code skill 之间没有内存共享机制
- 文件是唯一可靠的跨 session 通信方式
- 方便 debug（直接读中间文件）

### 4. 最小可触发单元

每个 skill 可以在缺少上游产出的情况下独立运行——以默认模式执行并标注"缺少上游上下文"。

## 目录设计

```
project-suite/
├── README.md              ← 入口
├── skills/               ← 9 个独立 skill（可插拔）
├── runtime/              ← 共享运行时协议（不包含 skill 专属内容）
│   ├── engine/           ← 单 skill 执行层
│   └── protocols/        ← 多 skill 协作层
├── shared/               ← 静态制品（JSON Schema、模板、约定、示例）
└── docs/                 ← suite 自身文档
```

### 为什么 runtime/ 分 engine/ 和 protocols/

- **engine/** 解决"一个 skill 怎么执行"——状态、断点、调度、异常
- **protocols/** 解决"多个 skill 怎么协作"——路由、编排

这是两个正交的维度。放在一起会混淆单 skill 行为和跨 skill 行为。

### 为什么 shared/ 不放 protocol 逻辑

shared/ 只放静态制品——schemas、templates、conventions、examples。不放任何涉及运行时决策的文件。`routing` 和 `orchestration` 是运行时决策，放 `runtime/protocols/`。

### 为什么 skills/ 下不设 protocol/

最初设计（方案一）每个 skill 有 `protocol/` 目录。但 protocol 是框架能力，skill 只是使用者。类比：React 组件不自己实现 React 运行时。

## 已拒绝的备选方案

| 方案 | 拒绝理由 |
|------|---------|
| 每个 skill 自带 protocol/ | 9 份重复，一致性无法保证 |
| shared/protocols/ 放路由规则 | 路由规则是运行时行为，非静态制品 |
| runtime/ 扁平结构（不分子目录） | engine 和 protocols 职责不同，平铺混淆 |
| runtime/ 合并 engine + protocols | 两件不同的事不应放在同一层 |

## Skill 创建规范

### 最小 skill（骨架）

```
skills/<name>/
├── SKILL.md          ← 必须：name + description frontmatter + 使用说明
├── prompts/          ← 必须：至少一个 prompt 模板
│   └── main.md
└── references/       ← 必须：至少能力边界说明
    └── capability-matrix.md
```

### 正式版 skill（当前 v0.7.0 标准）

```
skills/<name>/
├── SKILL.md              ← 完整工作流 + 核心原则 + 边界处理 + runtime 引用表 + references 索引
├── prompts/
│   ├── main.md           入口 + 路由到专用 prompt
│   ├── <specialized-1>.md  专用领域 prompt
│   └── <specialized-2>.md
└── references/
    ├── capability-matrix.md   保证能力 + 不做 + 前置条件
    ├── trigger-words.md       触发词 + 歧义处理
    ├── anti-patterns.md       禁止操作 + 常见反模式 + 反例对比
    └── examples.md            真实输入→输出示例
```

### 可选扩展（按需添加）
- `references/<domain-guide>.md` — 领域专项指南（如 tester 的 mock-strategy.md、refactorer 的 safety-protocol.md）
- `prompts/<specialized-3>.md` — 第三个专用 prompt
- `resources/` — skill 专属静态资源
