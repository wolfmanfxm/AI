# Trigger Words — Planner

## 中文触发词

### 任务拆解
- 任务拆解、拆任务、分解任务、任务划分、任务拆分
- 开发计划、排期计划、迭代计划
- 需求分析（结合拆解意图时）

### 工作量评估
- 估算工作量、评估工时、估时
- 这个需求要多久、需要多少人天

### 优先级排序
- 优先级排序、排优先级、先做什么
- sprint 规划、迭代规划

### 通用
- 帮我规划一下、做一个计划
- 这个功能怎么分任务

## English Triggers

- break down tasks, task breakdown, task planning
- plan sprint, sprint planning, create dev plan
- estimate effort, effort estimation, how long will this take
- prioritize tasks, priority sort
- development roadmap, milestone plan

## 歧义处理

| 用户说 | 可能意图 | 路由决策 |
|--------|---------|---------|
| "帮我规划这个项目" | planner vs architect | 如果关注"做什么"→ planner；"怎么做"→ architect |
| "设计这个系统" | architect vs planner | 如果关注"拆功能"→ planner；"选技术"→ architect |
| "评估这个需求" | planner vs reviewer | 如果关注"实现步骤"→ planner；"代码质量"→ reviewer |

不确定时 → AskUserQuestion 确认意图。
