# Context Protocol

> skill 间传递项目知识的标准化协议。解决每个 skill 重复解析 `.project-knowledge/` 的问题。

## 定位

```
manifest.json  → 执行状态（完成了哪些、卡在哪一步）
context.json   → 项目知识（用了什么技术栈、有什么约定、有哪些模块）
                 ↑ 本协议定义
```

## 生产者 / 消费者

| 角色 | Skill | 时机 |
|------|-------|------|
| **生产者** | analyzer | Finish 阶段，在写 manifest.json 之后 |
| **消费者** | planner, architect, generator, reviewer, refactorer | 启动时第一步加载 |

## Schema

> 下面所有值都是**占位符**（`<...>`），表示字段结构；真实值由 analyzer 从项目提取、写入 `.project-knowledge/context.json`。协议文件不含任何具体项目的技术栈/路径/组件名。

```json
{
  "schemaVersion": "1.0.0",
  "generatedBy": "project-analyzer",
  "generatedAt": "ISO-8601",
  "gitCommit": "<commit-hash>",

  "techStack": {
    "framework": "<detected>",
    "uiLibrary": "<detected>",
    "language": "<detected>",
    "buildTool": "<detected>",
    "stateManagement": "<detected>",
    "cssPreprocessor": "<detected>",
    "microFrontend": "<detected-or-absent>"
  },

  "paths": {
    "sourceRoots": ["<source-root-1>", "<source-root-2>"],
    "aliases": { "<alias>": "<target-path>" },
    "apiPrefix": "<api-base>"
  },

  "conventions": {
    "componentStyle": "<detected>",
    "componentNaming": "<detected>",
    "propsDefinition": "<detected>",
    "stateManagement": "<detected>",
    "apiClient": "<detected>",
    "apiParams": {
      "pagination": { "<page-index-field>": "<type>", "<page-size-field>": "<type>" },
      "responseWrapper": "<response-wrapper-type>"
    },
    "errorDisplay": "<detected>",
    "loadingPattern": "<detected>",
    "formPattern": "<detected>"
  },

  "modules": {
    "views": { "<source-root>": ["<module>", "..."], "total": "<N>" },
    "stores": { "<source-root>": ["<store>", "..."], "total": "<N>" },
    "apis": { "srcModules": "<N>", "workspaceModules": "<N>", "totalFunctions": "<N>" },
    "components": {
      "global": ["<component>", "..."],
      "highReuse": ["<component> (<N> refs)", "..."]
    }
  },

  "quality": {
    "consoleLogTotal": "<N>",
    "unusedComponents": ["<component>", "..."],
    "dualPatterns": ["<pattern-A> vs <pattern-B>", "..."]
  }
}
```

## 与 manifest.json 的分工

| | manifest.json | context.json |
|---|--------------|-------------|
| **内容** | 执行进度 | 项目知识 |
| **变化频率** | 每次分析更新 | 技术栈变更时更新 |
| **谁写** | 所有 skill | 仅 analyzer |
| **谁读** | analyzer resume | 所有下游 skill |
| **不读后果** | 重复分析 | 用错技术栈/路径/约定 |

## 加载方式

下游 skill 启动时：

```
1. 读 context.json（若存在）→ 注入项目上下文
2. 读 manifest.json（若存在）→ 了解分析状态
3. context.json 不存在 → 降级：从 .project-knowledge/ 提取
4. 两者都不存在 → 降级：通用模式
```
