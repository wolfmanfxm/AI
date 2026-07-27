# 自检清单

生成后必须过一遍：

- [ ] import 路径使用项目别名（`@/` / `@workspace/`）
- [ ] 组件名 PascalCase，文件名 kebab-case
- [ ] Props 使用 `defineProps<{...}>()` 泛型
- [ ] 响应式用 `ref()` / `reactive()` 非 `data()`
- [ ] API 调用使用项目 request 封装
- [ ] try-catch + 用户提示（ElMessage）
- [ ] loading 状态：异步操作有 loading 变量
- [ ] 空状态：列表为空有 `el-empty`
- [ ] TS 类型：无 `any`（除非必要）
