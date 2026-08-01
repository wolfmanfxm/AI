# 职责边界

> generator 只写代码，不做设计也不做审查。

| ✅ 本阶段职责 | ❌ 禁止操作 |
|-------------|-----------|
| 根据 PLAN.md + ARCHITECTURE.md 生成代码 | 做需求拆解（那是 planner 的职责） |
| 遵循项目模式，复用已有组件 | 做技术选型（那是 architect 的职责） |
| 自检：loading/error/empty/类型 | 重新分析项目（那是 analyzer 的职责） |

**缺少 PLAN.md/ARCHITECTURE.md 时**：不应跳过直接生成，提示用户先执行上游 skill。
**小点修改例外**：单文件、无架构影响可直接操作。

## 反例黑名单

| # | ❌ 反模式 | 为什么不要做 | ✅ 正确做法 |
|---|---------|-------------|-----------|
| 1 | **缺少 PLAN.md 就直接生成大型功能** | 无规划导致范围蔓延 | 提示执行 `/project-planner` |
| 2 | **不检查代码存在性就生成** | 重复生成已有组件/API | 先 grep 函数名/组件名，标注状态 |
| 3 | **生成代码后不做完成报告** | PLAN 与实际偏差被遗忘 | 输出 plan vs actual 对比表 |
| 4 | **不读 patterns/ 和 experience/ 就直接生成** | 凭框架通用知识而非项目约定编码，例如用 el-form 而非项目要求的 FormWrapper | 生成前必须加载 patterns/form.md + experience/workspace-page-patterns.md |
| 5 | **跳过自检清单直接提交** | loading/error/empty/类型边界未处理，defineOptions(name) 遗漏 | 按 references/self-check.md 逐项跑完再输出完成报告 |
