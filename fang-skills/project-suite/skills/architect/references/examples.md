# Examples — Architect

> 真实设计示例。

---

## 示例 1：技术选型

### 输入

> "我们项目要做文件导出（Excel/PDF），选什么库？团队主要用 Vue3+TS。"

### 输出（ARCHITECTURE.md 摘要）

```
ADR-0003: 文件导出库选型

状态: 已采纳

背景: 报表模块需要支持 Excel 和 PDF 导出，前端生成还是后端生成待定。

候选方案:
| 方案 | 优点 | 缺点 |
|------|------|------|
| ExcelJS | 纯前端、支持样式、TS类型完整 | 包体较大(~300KB) |
| xlsx(SheetJS) | 社区最流行、功能全 | 商业版收费、文档乱 |
| 后端生成 | 前端无性能压力、支持复杂排版 | 需要后端配合开发 |

决策: ExcelJS（前端导出 < 10000 行时）+ 后端导出（大数据量时）

理由:
1. 前端导出简单表格用 ExcelJS，无需后端改动
2. 大数据量（>1万行）导出走后端，避免浏览器卡死
3. ExcelJS TS 支持好，与项目技术栈匹配
```

---

## 示例 2：模块设计

### 输入

> "设计一个工单系统：用户提交工单，客服处理，支持转派、升级、关闭。"

### 输出

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│  auth    │────→│  ticket  │←────│  notify  │
│  认证鉴权  │     │  工单核心  │     │  通知    │
└──────────┘     └────┬─────┘     └──────────┘
                      │
                ┌─────┴─────┐
                │  sla      │
                │  时效管理  │
                └───────────┘

| 模块 | 职责 | 对外接口 | 依赖 |
|------|------|---------|------|
| ticket | 创建/转派/升级/关闭/查询 | createTicket(), assignTicket(), escalateTicket(), closeTicket() | auth |
| sla | 计算响应时限、超时告警 | checkSLA(), getOverdueTickets() | ticket |
| notify | 状态变更通知（站内+邮件） | sendNotification() | ticket |
```

---

## 示例 3：API 契约

### 输入

> "设计工单分配的 API"

### 输出

```
PATCH /api/tickets/:id/assign — 分配工单

描述: 将工单分配给指定客服
鉴权: 需要登录 + ticket:assign 权限
幂等: 是（同一客服重复分配不报错）

Request:
{
  assigneeId: number  // 必填，客服 ID
  remark?: string     // 可选，分配备注
}

Response 200:
{
  data: {
    ticketId: 123,
    status: "processing",
    assignee: { id: 5, name: "张三" },
    assignedAt: "2026-07-27T15:00:00Z"
  }
}

Response 400: { error: "TICKET_CLOSED", message: "工单已关闭，无法分配" }
Response 403: { error: "FORBIDDEN", message: "无工单分配权限" }
Response 404: { error: "NOT_FOUND", message: "工单不存在" }
```
