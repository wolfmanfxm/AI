# Development Flow

> analyzer skill 专属的开发前检查流程。通用发现/执行流程见 ../../runtime/engine/state-machine.md。

## 保障

`.claude/CLAUDE.md` 自动加载（主） + skill 触发（辅）。

## 流程

1. 查 `.project-knowledge/index.md`，若无则查 `{Vault}/Projects/{project}/`
2. 按任务选读 1-2 份文档：
   - 写组件 → `components/` + `patterns/`
   - 写页面 → `architecture/` + `patterns/`
   - 写 API → `api/` + `patterns/`
   - 不确定 → `patterns/`
3. 提取关键约定 → 用项目实际模式生成代码
4. 🛑 若知识文档不存在 → `AskUserQuestion`：🔍运行分析 / 📝通用规范 / 📂手动路径
