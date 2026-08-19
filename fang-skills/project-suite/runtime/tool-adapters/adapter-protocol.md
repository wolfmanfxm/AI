# Adapter Protocol v1.0

> Skill 如何通过 Adapter 调用工具的标准协议。

## 原则

1. **Skill 不直接调用 MCP Tool** — 通过 Adapter
2. **Skill 不直接写 Bash 命令** — 通过 Adapter（简单的读操作除外）
3. **替换 Provider 不影响 Skill** — 改 adapter-registry.yaml 即可

## 调用格式

Skill 在 prompts/ 中使用以下格式声明工具调用：

```
@adapter:<domain>.<operation> [args]
```

Host 解析 → 查 adapter-registry.yaml → 找 provider → 执行。

## 示例

```
# Skill prompts/ 中:
@adapter:filesystem.search "<统一表格>" "src/views/"
  → Host: Bash("grep -r '<统一表格>' src/views/")

@adapter:browser.navigate "http://localhost:3000"
  → Host: mcp__playwright__browser_navigate("http://localhost:3000")

@adapter:git.diff
  → Host: Bash("git diff")

# Provider 不可用时自动降级:
@adapter:filesystem.search → mcp__filesystem 不可用 → fallback: Bash(grep)
```

## Provider 降级

 Host 按 adapter-registry.yaml 的 `providers` 顺序尝试：
1. primary → 可用则使用
2. fallback → primary 不可用时降级

## 新增 Adapter

1. 在 `adapter-registry.yaml` 注册新 domain
2. 定义 operations + providers
3. Skill 立即可用 `@adapter:<domain>.<operation>`

## 直接调用 → Adapter 映射

| 直接调用 | Adapter 等价调用 | 涉及 Skill |
|---------|-----------------|-----------|
| `Read("path")` | `@adapter:filesystem.read path` | all |
| `Write("path", content)` | `@adapter:filesystem.write path` | generator, documenter |
| `Bash("grep ...")` | `@adapter:filesystem.search pattern path` | analyzer, reviewer |
| `Bash("find ...")` | `@adapter:filesystem.find pattern` | analyzer |
| `Bash("ls ...")` | `@adapter:filesystem.list path` | analyzer |
| `Bash("git log/diff/status")` | `@adapter:git.log / diff / status` | releaser, reviewer |
| `WebFetch(url)` | `@adapter:network.fetch url` | architect |
| `WebSearch(query)` | `@adapter:network.search query` | architect |
| `mcp__playwright__*` | `@adapter:browser.*` | tester (E2E) |
| `mcp__figma__*` | `@adapter:design.*` | generator (design→code) |

## 迁移优先级

只迁移 I/O 操作（filesystem/git/network/browser/design），**不迁移 Prompt/Thinking**。

| 优先级 | Skill | 直接调用数 | 迁移收益 |
|--------|-------|----------|---------|
| P0 | **analyzer** (discovery.md) | ~8 Read/Bash | 高 — 跨 runtime 最频繁 |
| P1 | **generator** (execution.md) | ~5 Read/Write | 高 — 代码生成核心 |
| P2 | **releaser** (execution.md) | ~3 Bash(git) | 中 — git 操作跨平台差异大 |
| P3 | 其余 Skill | ~22 | 低 — 逐步迁移 |

## 新增 Provider

1. 在 domain 的 `providers` 加新条目
2. 现有 Skill 自动获得新 provider（无需修改）

## 验证

`shared/scripts/check-drift.sh` 检测 `@adapter:` 引用是否 match registry 定义。未注册的 adapter → WARNING。
