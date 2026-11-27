【RELEASE-CHECKLIST 交付摘要】
- 变更：key userInfo→user-info；仅 project/after/userStore.js，无依赖/配置/数据脚本。
- 实现：setUser 新旧 key 双写（兼容期）；getUser 新 key 优先，缺失回退旧 key 并回写（读取即迁移）。
- 验收：node verify.mjs before→PASS A/FAIL B（基线）；after→PASS A/PASS B，退出 0。A=旧 key 存量可读；B=新 key 优先、不被 stale 旧值覆盖。
- 上线：直接发布，无需迁移脚本；保留旧 key 双写以兼容旧版本/多标签页。
- 回滚：双写+迁移保留旧值，回退旧代码仍可读 userInfo，无需修数据。
- 待补测：迁移回写未断言；空串、双缺失 null、删除用户、setItem 异常未覆盖。
- 清理：兼容期后移除 OLD_KEY 双写并清存量。
污染自检：未读取 SKILL.md/project-suite（是）

（核查依据：/Users/fangxiangming/.cache/ps-eval/round19/delivery-proof/project/verify.mjs 与 before、after 下的 userStore.js；before 的 FAIL B 为基线对照，after 全部通过。）
