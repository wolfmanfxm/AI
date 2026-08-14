# Framework Extractor

> 只提取技术栈和框架配置。不分析业务代码。

## Actions

1. 读 `package.json` → dependencies/devDependencies/scripts
2. 读 `tsconfig.json` → paths/aliases/strict
3. 读 `vite.config.*` → plugins/alias/resolve
4. 识别：框架、UI库、状态管理、路由、构建工具、测试框架

## Output

```yaml
framework: Vue 3.4
language: TypeScript 5.x
build: Vite 5.x
ui: Element Plus 2.13 (el-mp prefix)
state: Pinia
router: Vue Router 4
test: Vitest
package_manager: pnpm
aliases: { "@": "src", "@workspace": "workspace", "@cms": "cms" }
strict_mode: true
```

## Evidence

每个结论标注来源文件 + 行号：
- `framework: Vue 3.4` ← package.json:15 `"vue": "^3.4.29"`
- `ui: Element Plus 2.13` ← package.json:22 `"element-plus": "^2.13"`
