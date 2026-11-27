**变更**：key userInfo→user-info；读优先新、缺失回退旧并迁移；写双写新旧；兼容期不删旧 key。
**验证**：verify.mjs 改前 B 失败、A 通过（exit 1），改后 A/B 通过（exit 0）。
**发布前必补**：
1. 迁移写入未被断言——mock 不记录写操作；需验证旧 key 用户读后 user-info 已落盘。
2. 双写未被断言——用例 B 用 stale 覆盖旧 key；需验证 setUser 后两 key 同时有值。
3. 仓库内直接读 userInfo 处须 grep 改走 userStore；本区不可确认。
**回滚/灰度**：双写期内可安全回滚（旧版仍读 userInfo）；停双写后回滚会丢仅存于新 key 的数据，去双写应独立发版并观察。无迁移计数，建议统计后再下线旧 key。
**边界**：新 key 为空串时不回退旧 key，需确认业务允许空串。
污染自检：未读取 SKILL.md/project-suite（是）
