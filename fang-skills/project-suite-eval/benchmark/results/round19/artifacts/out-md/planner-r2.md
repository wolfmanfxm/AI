<!-- arm=planner-r2 session=af2ffea9-c542-442a-beb0-3d36d1a8ea9e turns=13 subagents=0 -->
Skill 调用: 成功（project-planner）

## 需求结论（Discovery 阶段）

- **Goal**：客户联系人登记页：录入姓名、手机、邮箱、职务并保存，作为客户档案的联系人入口。
- **In**：登记表单、字段校验、提交保存；复用 `FormWrapper` 与现有客户 API。
- **Out**：联系人列表、编辑、删除，客户其他字段，权限改造。
- **Code Audit**：`FormWrapper` [基本完成]，直接复用；客户 API [有骨架]，目前只有查询，联系人写入端点 ⤳ 待确认；短信验证 [未实现]，无发送、校验接口。
- **Confidence：63%**。已知：字段与表单封装。未知：G-01 联系人写入的接口约定；G-02 手机号是否必填、唯一性。

## 🔴 CHECKPOINT：待用户决策

**PD-001：手机号是否需要短信验证？**

- **A 不需要**：纯登记，约 1d，不新增后端。
- **B 需要**：短信服务商、发送与校验接口、验证码状态，约 +3~5d，新增外部依赖、费用与合规决策。

影响：Scope 边界、Task 数量、依赖图、RSK-001（供应商未接入）。Interview 预算已用尽；按 skill 规则，高影响未决项不得写成 Assumption，须交回你决定。

**请你确认 Goal 与 In、Out，并选择 A 或 B。** 确认前我停在此处，不产出 Task Breakdown，也不进入 Architect 或 Generator。

下一步：选 A，进入 `/project-generator`；选 B，先由 `/project-architect` 产出短信方案 ADR，再回 Planner 补计划。

（本次为只读评测，未执行 `runtime-run.sh` 登记任务，未写任何文件。）
