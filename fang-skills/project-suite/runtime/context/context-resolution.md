# Context Resolution

> context.json 与当前代码不一致时，如何裁决。

## 核心原则

**代码事实 > context.json > 通用默认值**

context.json 是 analyzer 运行时的快照，可能过时。当与当前代码冲突时，以代码为准。

## 裁决链

```
代码事实（grep/read 确认）
  ↓ 代码不可读 / 不确定
context.json（最新一次 analyzer 快照）
  ↓ context.json 不存在 / 字段缺失
通用默认值（框架内置 fallback）
```

## 逐字段裁决规则

| 字段 | 代码验证方式 | 不一致时的处理 |
|------|------------|--------------|
| techStack.framework | 读 `package.json` → `dependencies.vue` | 以 package.json 为准，标注 `⚠️ context.json outdated` |
| techStack.uiLibrary | 同上 `element-plus` | 同上 |
| paths.aliases | 读 `vite.config.ts` / `tsconfig.json` | 以配置文件为准 |
| conventions.componentStyle | 抽样 5 个 `.vue` 文件统计 | 以多数为准 |
| conventions.apiClient | 读 `src/utils/service/` | 以实际文件名为准 |
| conventions.pagination | 抽样 3 个 API 调用 | 以多数为准 |
| modules.views | `ls src/views/ workspace/views/` | 并入新发现的，标注 `[NEW]` |
| modules.stores | `ls src/stores/ workspace/stores/` | 同上 |
| modules.apis | 读 `workspace/api/index.ts` | 同上 |
| quality.* | 无法快速验证，信任 context | 标注 `⚠️ 基于 analyzer 快照` |

## 冲突通知

发现不一致时，下游 skill 不应静默覆盖：

```
⚠️ context.json 记录 Vue 3.4，但 package.json 显示 Vue 3.5
→ 以 package.json 为准（Vue 3.5）
→ 建议: 运行 /project-analyzer 增量更新 context.json
```

## 版本标记

context.json 含 `gitCommit` 字段，下游 skill 可对比当前 HEAD：

```bash
if [ "$(cat context.json | jq -r .gitCommit)" != "$(git rev-parse HEAD)" ]; then
  echo "⚠️ context.json may be outdated (generated at $(cat context.json | jq -r .gitCommit))"
fi
```
