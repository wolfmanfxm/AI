# Trigger Words — Tester

## 中文触发词

### 写测试
- 写测试、加测试、补测试、帮我测试
- 单元测试、集成测试、组件测试
- 测试用例、test case

### 测试覆盖
- 测试覆盖、覆盖率、补充覆盖
- 这个函数有没有测试

### 跑测试
- 跑测试、执行测试、运行测试
- 测试过了吗、跑一下测试

## English Triggers

- write tests, add tests, generate tests
- unit test, integration test, component test
- test coverage, code coverage
- run tests, execute tests

## 歧义处理

| 用户说 | 可能意图 | 路由决策 |
|--------|---------|---------|
| "测试一下这个功能" | tester vs 手动测试 | 写自动化测试 → tester；浏览器手动测试 → 直接做 |
| "这个 bug 怎么测" | tester vs debug | 先定位 bug → debug；为修复写测试 → tester |
