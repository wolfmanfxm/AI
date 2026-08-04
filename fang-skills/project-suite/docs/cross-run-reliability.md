# Cross-Run Reliability v1.0

> 同一 Skill 在相同输入下多次运行的稳定性度量。yao-meta-skill Governed 模式要求。

## 可靠性维度

| 维度 | 定义 | 阈值 | 度量方式 |
|------|------|------|---------|
| **Structural** | 产出文件数量和类型一致 | 文件数差异 ≤20% | 对比两次运行的 output 文件列表 |
| **Confidence** | 置信度评分稳定 | 两次运行 confidence 差值 ≤15 | 对比 state.json history 中同 skill 的 confidence |
| **Stage** | 阶段完成情况一致 | 相同 stages 全部 completed | 对比 manifest.json subtask 状态 |
| **Fixture** | file-backed fixture 输入一致 | 相同 fixture 的 checksum 不变 | md5 对比 `interface.inputs[fixture=true]` |
| **Output** | 关键产出文件结构稳定 | Section 数量差异 ≤1 | 对比产出 .md 的 `##` 标题数量 |

## 不可度量（诚实标注）

| 维度 | 原因 |
|------|------|
| **语义等价** | 内容可以不同表述，需人工判断质量是否等价 |
| **用户满意度 delta** | 无满意度采集机制 |
| **下游消费正确性** | generator 生成的代码是否能通过 tester 的测试，需实际执行 |

## 对比工具

`shared/scripts/check-reliability.sh` — 输入两次运行的 `.project-runtime/` 快照，输出可靠性报告。

```
bash shared/scripts/check-reliability.sh <snapshot-A-dir> <snapshot-B-dir>
```

## 可靠性契约

每个 Skill 声明其可靠性预期：

```yaml
# skill.yaml 新增
reliability:
  structural_stability: high | medium | low
  expected_confidence_delta: 10       # 两次运行 confidence 最大允许差
  output_file_count_tolerance: 20%    # 文件数允许波动范围
```

- **high**: 纯分析型 skill（analyzer/reviewer/documenter）— 输出高度确定
- **medium**: 半生成型 skill（planner/architect/tester）— 有合理变体空间
- **low**: 生成型 skill（generator/refactorer）— 输出可能显著不同但都正确

## 可靠性报告格式

```markdown
# Cross-Run Reliability Report

> Run A: <timestamp> | Run B: <timestamp> | Skill: <name>

| Dimension | Run A | Run B | Delta | Pass? |
|-----------|-------|-------|-------|-------|
| Output files | 12 | 13 | +1 (8%) | ✅ |
| Confidence | 85 | 78 | -7 | ✅ |
| Stages completed | 4/4 | 4/4 | 0 | ✅ |
| Fixture checksums | 3/3 match | 3/3 match | 0 | ✅ |
| Output sections | 24 | 23 | -1 | ✅ |

**Verdict**: PASS — all dimensions within threshold
```
