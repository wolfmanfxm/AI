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

```json
{
  "schemaVersion": "1.0.0",
  "generatedBy": "project-analyzer",
  "generatedAt": "ISO-8601",
  "gitCommit": "abc1234",

  "techStack": {
    "framework": "Vue 3.4",
    "uiLibrary": "Element Plus 2.13",
    "language": "TypeScript 5.4",
    "buildTool": "Vite 7",
    "stateManagement": "Pinia 2.1",
    "cssPreprocessor": "SCSS",
    "microFrontend": "qiankun 2.10"
  },

  "paths": {
    "sourceRoots": ["src", "workspace"],
    "aliases": {
      "@": "src",
      "@workspace": "workspace",
      "@bcapnext": "src/views/bcapnext"
    },
    "apiPrefix": "baseService = api/v1"
  },

  "conventions": {
    "componentStyle": "script setup lang=ts",
    "componentNaming": "PascalCase file, kebab-case tag",
    "propsDefinition": "defineProps<T>()",
    "stateManagement": "ref() / reactive()",
    "apiClient": "request from @/utils/service",
    "apiParams": {
      "pagination": { "pageindex": "string", "pagesize": "string" },
      "responseWrapper": "IResponseResultRows<T> / IResponseResultRow<T>"
    },
    "errorDisplay": "ElMessage.error()",
    "loadingPattern": "ref(false) + try/catch/finally",
    "formPattern": "reactive() + defineExpose({ getFormData, getEditorForm })"
  },

  "modules": {
    "views": {
      "src": ["PlatformManagement", "OrgManage", "AuthorityManagement", "bcapnext", "dynamicDashboard", "Login"],
      "workspace": ["creditManage", "customerManage", "trustManage", "collection", "vehicleMonitor", "..."],
      "total": 40
    },
    "stores": {
      "src": ["user", "menu", "uiSetting", "pending", "industry", "region"],
      "workspace": ["docs", "area", "dealer", "finReport", "counter"],
      "total": 11
    },
    "apis": {
      "srcModules": 36,
      "workspaceModules": 110,
      "totalFunctions": 2084
    },
    "components": {
      "global": ["MpTable", "OrgTreeVirtual", "BaseDrawer", "..."],
      "highReuse": ["MpTable (69 refs)", "SchemaTable (605 refs)", "PageTable (334 refs)"]
    }
  },

  "quality": {
    "consoleLogTotal": 1356,
    "unusedComponents": ["BigFileUpload", "RoleSelector"],
    "dualPatterns": [
      "src/pageindex vs workspace/pageNum pagination",
      "src/Swagger URL vs workspace/RESTful URL",
      "src/script setup vs bcapnext/JSX+Options API"
    ]
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
