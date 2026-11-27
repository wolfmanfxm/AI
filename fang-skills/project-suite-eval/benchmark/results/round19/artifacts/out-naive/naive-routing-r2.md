路径：Standard（不走 Quick）
需要：最小变更工程师实施改动、security-auditor 复核、test-engineer 补回归用例、code-reviewer 终审
理由：权限校验绕过属高风险安全缺陷；2 个文件虽小，但必须做威胁建模、越权路径回归与安全复核，防二次绕过。改动局部、无架构变更，无需 Full。
污染自检：未读取 SKILL.md/project-suite（是）
