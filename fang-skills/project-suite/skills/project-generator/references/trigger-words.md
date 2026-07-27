# Trigger Words — Generator

## 中文触发词

### 组件
- 写一个组件、创建组件、新建组件
- 封装一个 XX 组件、做一个 XX 组件

### 页面
- 新增页面、写一个页面、创建页面
- 实现 XX 页面、开发 XX 页面

### 通用实现
- 实现这个功能、开发这个需求
- 帮我写、帮我实现、帮我写代码
- 生成代码、写代码
- 开发、编写、添加一个

### 修改/补充
- 改一下、修改这个、补充
- 加一个字段、加一个按钮
- 把这个逻辑抽出来

## English Triggers

- implement, create, build, develop, write
- create component, build feature
- generate code, write code
- add a, create a new

## 歧义处理

| 用户说 | 可能意图 | 路由决策 |
|--------|---------|---------|
| "帮我写这个功能" | generator vs planner | 如果已明确具体要写什么 → generator；需要先拆解 → planner |
| "重构这个函数" | generator vs refactorer | 如果改行为+结构 → generator；只改结构不改行为 → refactorer |
| "加个测试" | generator vs tester | 如果是写测试文件 → tester；写功能代码 → generator |

不确定时 → AskUserQuestion。
