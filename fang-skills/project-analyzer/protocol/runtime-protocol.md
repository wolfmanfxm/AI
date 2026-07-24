# Runtime Protocol

## 执行契约

本协议是 Runtime Specification 在运行时的具体行为约束。SKILL.md 中的 Contracts 声明"保证什么"，本协议定义"如何保证"。

## manifest 状态机

```
confirmed → in_progress → completed
                ↓              ↑
             partial ──────────┘ (resume)
                ↓
           interrupted ────────┘ (resume)
```

- `confirmed`：Phase 1 完成，维度清单已写入，尚未开始执行
- `in_progress`：至少一个维度 agent 已启动，尚未全部完成
- `partial`：token 耗尽或超时，部分维度已完成
- `interrupted`：外部中断（用户取消 / session 丢失）
- `completed`：所有维度完成，固定产出已生成

## 维度状态

manifest.dimensions 中每个维度的状态独立管理：

```
pending → in_progress → completed
              ↓
          (agent 失败) → 主 agent 合成，标注 ⚠️
```

## 恢复协议

1. 读 manifest.status
2. 若 `interrupted` / `partial` / `in_progress`：进入 Phase 2 Resume
3. 遍历 dimensions：跳过 `completed`，仅执行 `pending` 和 `partial`
4. 注意：`partial` 维度的已有文件可能不完整，需全量重跑该维度

## 版本兼容

- schemaVersion 变更：主版本号变化（1.x→2.x）表示破坏性变更，需升级解析器
- knowledgeVersion 变更：仅全量刷新时递增，增量不递增
- skillVersion（analysis-config.json）：记录生成配置的 skill 版本，用于审计
