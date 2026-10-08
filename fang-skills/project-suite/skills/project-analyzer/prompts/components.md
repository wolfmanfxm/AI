# Component Analysis

## Goal
编目项目中的可复用组件，标注接口、引用次数、耦合度，识别候选提升组件。

## Context
组件目录结构取决于项目类型（Vue/React/Angular），先通过架构分析确定目录位置。

## Evidence
- 全局组件目录
- 页面/视图目录下的 `components/` 子目录
- 框架层组件目录（如有）

## Analysis
1. 对每个全局组件提取名称、路径、用途、Props/Emits/Slots/Expose、引用次数、业务耦合度
2. 复用度分级：高（≥5次引用，无业务耦合）/ 中（2-4次）/ 低（1次）
3. 扫描模块内 components/，标记候选提升：2+模块引用、接口清晰、无业务硬编码
4. 识别对 UI 库组件的二次封装，标注封装目的

统计引用时尝试 PascalCase 和 kebab-case 两种标签格式。

## Output
`components/catalog.md`（按需）+ 高复用组件独立 `.md`（按需）

**多应用项目**（同一仓库含 ≥2 个可独立运行的应用：monorepo / 微前端）额外产出
`components/reuse-ledger.md` —— **组件复用总账**：

- 逐组件记录：在哪些应用出现、各应用是共享还是各自重写、接口是否一致
- 汇总跨应用复用率 + 「可提升为共享组件」的候选（依据：≥2 应用出现 + 接口清晰 + 无业务硬编码）
- 落点必须是 `components/reuse-ledger.md`

> ⚠️ **不要为复用账新建目录**（如 `component-inventory/`）：契约未声明该目录 → 不进 index、
> 下游读不到，且违反 `check-io-connectivity.sh` 的不变量 I2。并入 `components/` 即符合契约且可被 Compiler 索引。
