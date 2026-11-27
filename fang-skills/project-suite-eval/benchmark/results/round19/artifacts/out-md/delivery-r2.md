<!-- arm=delivery-r2 session=9bda54e3-3a7f-4f3d-9e4b-fff4cacf6ca4 turns=17 subagents=0 -->
Skill 调用: 成功（project-releaser）
（只读约束：未写 CHANGELOG/CHECKLIST 文件，以下内容可直接粘贴）

```markdown
Delivery[存储 key `userInfo`→`user-info`：新键优先、旧键回退并迁移、兼容期双写旧键]
  Evidence:
    Before: `node project/verify.mjs before` → PASS A；FAIL B: expected bob, got stale（旧键被覆盖后读到脏值），exit 1
    After:  `node project/verify.mjs after`  → PASS A、PASS B，exit 0
  Merge Danger:
    Door: one-way（持久化存储键/数据契约变更；读取会向新键回填，回滚需处理已迁移数据）
    Blast Radius: 所有直接读写 `userInfo` 的消费方。本工作区无 git/代码图谱，`findConsumers(userInfo)` 无法执行，仅由 verify 的旧键读写场景间接覆盖 → 消费方清单 UNPROVEN（单独列出）
    Safety Invariant: 读取以新键 `user-info` 为第一真相，仅当新键缺失才回退旧键并回填；故兼容期内旧代码写旧键不会污染新值（case B 证明）
    Proof: 同一命令 `node project/verify.mjs before|after`：改前 B 读 stale（FAIL，exit 1）→ 改后 A/B 均 PASS（exit 0）
    Rollback: git revert 本次发布 commit（工作区无 git 历史，以部署 commit 为准）；验证旧键读写恢复、新键不再被读取。已迁移数据需回填旧键，脚本未提供 → UNPROVEN
```

版本建议: 无 git log/package.json，semver 不能自动推导；建议 **MINOR**（新增 key+迁移能力，导出函数签名不变，旧键保留）。兼容期结束移除旧键时应改 **MAJOR**。⚠️ 需人工确认（无 REVIEW.md，审查状态未验证）。
