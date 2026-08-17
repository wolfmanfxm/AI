# Verification Prompt — Shared Library v1.0.0

> 所有 Skill 的通用自检规范。被 generator/reviewer/tester/documenter 引用。
> 产出前必须逐项验证，禁止跳过。

---

## 通用自检清单

每个 Skill 产出前跑一遍：

### 边界覆盖

- [ ] **loading** — 异步操作有 loading 状态，`finally` 中复位
- [ ] **error** — 异常有 `try/catch`，空 catch 禁止
- [ ] **empty** — 空列表/空数据有 `v-if` 或空状态提示
- [ ] **类型边界** — TypeScript 类型正确，无裸 `any`

### 代码质量

- [ ] **命名一致** — 与项目已有命名风格一致（检查 2+ 个现有文件）
- [ ] **import 正确** — 路径别名 `@/` `<业务层别名>/` 使用正确，路径存在
- [ ] **复用** — 已检查 graph.json，已有组件不重复生成

### 契约遵守

- [ ] **路径规范** — 产出写入 `.project-knowledge/` 对应目录
- [ ] **Evidence Header** — `.md` 文件包含完整 frontmatter
- [ ] **CHECKPOINT** — 关键决策后用户已确认

## Skill 专属验证

### Generator

- [ ] `defineOptions({ name: '...' })` 已添加
- [ ] 表单使用 <统一表单封装>（非原生表单），弹窗使用 <统一弹窗>
- [ ] API 使用 `export function` + `Promise<AxiosResponse<T>>`
- [ ] 错误提示使用 `ElMessage.error(data?.msg || '默认提示')`
- [ ] 分页使用 `pageIndex`/`pageSize`（数字）

### Reviewer

- [ ] 每个发现标注 `file:line`
- [ ] BLOCKER 附：触发条件 + 生产影响 + 修复理由
- [ ] 至少 1 个 PRAISE
- [ ] AC 逐条对照表完整

### Tester

- [ ] 测试文件命名与项目一致
- [ ] Mock 结构与 `api/request.md` 中的响应解包层级匹配
- [ ] Given-When-Then 结构完整
- [ ] 边界 case 覆盖：null/空/超长/并发

## 反例

| ❌ 跳过验证 | ✅ 逐项验证后标注 |
|-----------|----------------|
| "大概没问题" | "✅ 边界覆盖: loading=有, error=有, empty=有, types=ok" |
| 只跑 happy path | 至少测 1 个错误路径 + 1 个边界值 |
| 不检查 import 是否存在 | `grep -r "import.*from.*<业务层别名>"` 确认路径可达 |
