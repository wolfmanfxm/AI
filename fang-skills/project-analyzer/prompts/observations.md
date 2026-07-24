# Observation Analysis

## Goal
生成纯数据报告，只记录事实，不做推断。

## Context
数据依赖于前几个维度的分析结果，在所有分析完成后执行，汇总项目统计和趋势。

## Evidence
- 项目文件（`.vue`、`.ts`、`.tsx` 等）
- 组件引用关系
- API 模块文件数
- 注释块

## Analysis
1. 总文件数、总行数、各类型文件分布
2. 每个组件的引用次数，与上次对比的趋势
3. 每个 API 模块的文件数和函数数
4. 搜索高度相似的文件片段（大项目可跳过）
5. 搜索零引用组件、大段注释代码

## Output
`observations/` 下按需创建：`statistics.md`、`component-usage.md`、`api-usage.md`、`duplicate-code.md`、`dead-code.md`
只记录数字和事实，标注"⚠️ 未检测到"而非编造
