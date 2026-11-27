<!-- arm=routing-r2 session=9b04f64f-8c18-418f-8652-56a1e1ea064a turns=7 subagents=0 -->
证据级别: L1（无对应 Skill 可加载）

**Gate 原始判定**：无判定输出，脚本崩溃 `exit 1`：
`line 89: is_simple�: unbound variable`
根因在 `complexity-gate.sh:96`：`$is_simple，` 后紧跟全角逗号（EF BC 8C），bash 把该字符首字节并入变量名，`set -u` 即报错。已用同构用例复现，且换任意输入仍失败，属无条件失效。按协议第 44 行，脚本结果以 LLM 按 rubric 复核为准。

**最终调度**：Standard Path — planner → generator → reviewer（深度 standard），`风险: HIGH`，reviewer 必跑并触发安全独立 QA。

**理由**：仅 2 文件、单模块缺陷修复，属 simple 规模，非新模块/架构变更；但命中敏感面「权限/鉴权」→ 至少 medium（协议 39–42 行；反例表第 108 行正是「2 文件权限校验」场景）。脚本关键词「权限」本会误判 complex → Full，复核降为 medium。
