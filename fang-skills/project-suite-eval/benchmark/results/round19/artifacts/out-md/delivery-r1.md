<!-- arm=delivery-r1 session=8c2d907e-b5b3-4642-a487-e2efc19a9ed8 turns=21 subagents=0 -->
Skill 调用: 成功（project-releaser）

Delivery[userInfo→user-info：新键优先/旧键回退迁移/兼容期双写]
  Evidence:
    Before: verify.mjs before → PASS A / FAIL B(got stale)
    After: verify.mjs after → PASS A / PASS B
  Merge Danger:
    Door: one-way（持久化键迁移，双写仅窗口内可回滚）
    Blast: getUser/setUser 调用方+存量旧键；findConsumers 无 graph，project 仅 userStore.js
    Safety Invariant: 读路径旧键回退恒在且写路径兼容期双写旧键，缺一即回滚丢数据
    Proof: 同一命令 before FAIL B→after PASS A/B；回滚未跑→UNPROVEN（未模拟双写），不计 PASS
    Rollback: 回退 KEY=userInfo，旧键双写可读；验证 verify.mjs before→PASS A
  迁移: 新键优先+旧键回退迁移+双写→观察期后停旧键
