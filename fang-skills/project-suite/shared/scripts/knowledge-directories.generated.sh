#!/bin/sh
# 自动生成，勿手改 —— 源: shared/schemas/knowledge-directories.yaml
# 重新生成: node shared/scripts/generate-knowledge-dirs.mjs
# 契约版本: 1.0.1

KD_CONTRACT_VERSION="1.0.1"

# 进 knowledge-index 的目录（compiler 必须恰好扫这些）—— 不变量 I1
KD_INDEXED="rules decisions patterns components api architecture experience playbooks recommendations"

# 全部声明目录
KD_ALL="rules decisions patterns components api architecture experience playbooks recommendations observations conventions domain proposals reports candidates"

# 谁产出哪个目录（格式 dir:producer，多产出者逗号分隔）—— 与 artifact-types.yaml 的 producer 同义
KD_BY_PRODUCER="rules:human decisions:human,project-architect,project-analyzer patterns:project-analyzer components:project-analyzer api:project-analyzer architecture:project-analyzer experience:human playbooks:human recommendations:project-analyzer observations:project-analyzer conventions:project-analyzer domain:project-analyzer proposals:project-planner reports:project-tester,project-reviewer,project-refactorer candidates:project-analyzer"

# 死产出（既不入 index 又非人读）——不变量 I3 要求为空
KD_DEAD=""

# Producer **应当**写入的字段（规范），格式 dir:field（空格分隔）
KD_REQUIRED="rules:constraint decisions:constraint patterns:statement components:statement api:statement"

# 其中 Compiler **硬校验**的子集（缺失即拒绝生成 index）—— Producer 该写 ≠ Consumer 该拦
KD_ENFORCED="rules:constraint decisions:constraint"
