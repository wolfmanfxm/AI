# Delivery — Planner

> @template: delivery

## Actions

1. 写入 `.project-knowledge/proposals/PLAN-<feature>.md`（完整 Contract，含 `# Knowledge Constraints` 块——rules/decisions/relevant_patterns 的机器可读 ID 清单）
2. 调用 `knowledge-resolver.sh` 生成 `context-package.json`（预消化知识包，Generator 直接消费），
   传入 `candidates` = `# Reuse Analysis` 命中的 source 路径/capability（只 hydrate 命中集 + Top-K）：
   ```json
   {
     "plan": "PLAN-<feature>.md",
     "context": {
       "rules": [ { "rule": "form-component-standard", "type": "rule", "constraint": "所有表单必须用 FormWrapper + FormFields", "blocking": true } ],
       "knowledge": [ { "capability": "patterns", "source": "patterns/table.md", "enforcement": "recommended" } ],
       "guidance": [ { "type": "experience", "source": "experience/xxx.md", "enforcement": "advisory" } ]
     }
   }
   ```
   > `# Knowledge Constraints` 与 context-package.json 的 rules[]/knowledge[] **同源**——Generator 交叉核对，不重猜。
3. 写入 state.json（confidence + suggested_next）
4. 写入 timeline.json

## Exit

- `PLAN-<feature>.md` 9 模块完整且已写入
- `context-package.json` 已生成
- state.json 已更新

## Failure

| Condition | Action |
|-----------|--------|
| 写入失败（权限/磁盘满） | 重试一次 → 仍失败标注 `❌ FAILED`，不阻塞其他产出 |
