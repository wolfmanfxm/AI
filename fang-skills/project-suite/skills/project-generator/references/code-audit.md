# 代码存在性检查

> Discover 阶段必做，避免重复生成。

## 步骤

```bash
grep -r "export function <name>" workspace/api/ --include='*.ts'
ls workspace/views/<module>/<page>/
grep -r "<ComponentName>" workspace/components/ src/components/ --include='*.vue' -l
grep -r "interface <Name>" workspace/types/ --include='*.d.ts'
```

## 标注

| 状态 | 处理 |
|------|------|
| `[已存在]` | 跳过，完成报告注明 |
| `[部分存在]` | 仅生成缺失部分 |
| `[不存在]` | 正常生成 |
