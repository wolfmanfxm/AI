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

Engine 解析 → 查 adapter-registry.yaml → 找 provider → 执行。

## 示例

```
# Skill prompts/ 中:
@adapter:filesystem.search "PageTable" "src/views/"
  → Engine: Bash("grep -r 'PageTable' src/views/")

@adapter:browser.navigate "http://localhost:3000"
  → Engine: mcp__playwright__browser_navigate("http://localhost:3000")

@adapter:git.diff
  → Engine: Bash("git diff")

# Provider 不可用时自动降级:
@adapter:filesystem.search → mcp__filesystem 不可用 → fallback: Bash(grep)
```

## Provider 降级

Engine 按 adapter-registry.yaml 的 `providers` 顺序尝试：
1. primary → 可用则使用
2. fallback → primary 不可用时降级

## 新增 Adapter

1. 在 `adapter-registry.yaml` 注册新 domain
2. 定义 operations + providers
3. Skill 立即可用 `@adapter:<domain>.<operation>`

## 新增 Provider

1. 在 domain 的 `providers` 加新条目
2. 现有 Skill 自动获得新 provider（无需修改）
