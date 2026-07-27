# Trigger Words — Reviewer

## 中文触发词

### 代码审查
- 代码审查、review 一下、帮我 review
- 检查代码、看看这段代码、审查这个文件
- 代码质量检查、代码走查

### PR 审查
- 审查 PR、review PR、这个 PR 怎么样
- 帮我看下这个改动、这个提交有什么问题

### 专项审查
- 安全审查、安全检查、有没有安全问题
- 性能审查、有没有性能问题
- 架构 review

### 日常对话
- 这段代码有什么问题
- 这样写对吗
- 有没有更好的写法

## English Triggers

- code review, review this code, review PR
- security review, security audit
- check this code, audit this
- any issues with this code, is this safe

## 歧义处理

| 用户说 | 可能意图 | 路由决策 |
|--------|---------|---------|
| "看看这段代码" | reviewer vs generator | 如果要评价/找问题 → reviewer；要修改/补充 → generator |
| "这个功能有问题" | reviewer vs debug | 如果描述具体 bug 现象 → debug（systematic-debugging）；"看看哪里不对" → reviewer |
| "安全问题" | reviewer vs security-auditor | 如果是应用代码级别 → reviewer 安全轴；如果是全系统审计 → 独立 security-auditor |
