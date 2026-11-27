路径：Standard

需要：开发者 + 安全审查员（security-auditor）+ 测试员

理由：只动 2 个文件、无架构变更，Quick 即可控范围；但「权限校验绕过」属高危漏洞，必须做安全复审并补回归测试，故升到 Standard；无需 Full 的全量规划与架构评审。

污染自检：未读取 SKILL.md/project-suite（是）
