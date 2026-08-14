# Execution — Analyzer

> @engine: execution
> v2.1: Multi-Extractor + 5-Verify + CHECKPOINT + Pipeline Resume

## Resume（跨 Session）

启动时检查 `.project-knowledge/.sessions/project-analyzer/state.json` → [session-snapshot](../../../runtime/engine/session-snapshot.md)：

1. 存在 + status = paused → 展示已完成 phases + extracted knowledge → 用户选择"继续/重新开始"
2. 继续 → 从 `current_phase` 开始，跳过已完成
3. 不存在 → 正常启动

每 Phase 完成后立即写入 snapshot（current_phase + knowledge_extracted + git_commit）。解决了"5000 文件项目 Context 爆炸 → Claude 重启 → 重来"的问题。

## Actions

### Phase 1: Parallel Extraction

从 [extractor-registry.yaml](../../../runtime/registry/extractor-registry.yaml) 读取 Extractor 列表 → 按 category 并行 spawn agent。

**Registry 驱动**：不硬编码 Extractor 表。读 registry → 对每个 category 下的 extractor spawn agent → 输出到 `candidates/accepted/<id>.yaml`。

**两层架构**：

| Category | Extractors |
|----------|-----------|
| **Structural** | directory, framework, architecture |
| **Semantic** | glossary, decision, principle |
| **Behavioral** | pattern, convention |
| **Quality** | risk, antipattern |

每个 Extractor 输出 [Evidence Format](extractors/evidence-format.md) 的 YAML Candidate → `candidates/accepted/<id>.yaml`。

Agent 协调规则：禁止提前返回 → 全部完成后一次性写入 → 验证文件 ≥100 bytes。

### Phase 2: Candidate Verification

→ [prompts/verifier.md](verifier.md)

对每个 Candidate 执行 **5-Verify**（存在性 + 频率 + 反例 + 预测力 + 非显而易见性）：
1. **存在性** — Claim 中的文件路径/行号是否真实存在？
2. **频率** — Occurrences 计数是否准确？
3. **反例** — 是否存在 Claim 不成立的反例？
4. **预测力** — 能否回答代码未显式说明的问题？（cangjie V2）
5. **非显而易见性** — 是否任何有经验的开发者都能一眼看出？（cangjie V3）

判定：全部 5 项 + Occur ≥3 → ✅ Accepted → 进入 CHECKPOINT
      发现反例 >50% 或频率偏差 >50% → ❌ Rejected → `candidates/rejected/`

🔴 **CHECKPOINT** — Phase 2 完成后暂停。展示 Verifier 结果（Accepted/Adjusted/Rejected 计数），用户确认后进入 Phase 3（Cross-Validator）。

### Phase 3: Cross-Extractor Validation

→ [prompts/cross-validator.md](cross-validator.md)

不同 Extractor 互相验证：Pattern↔Principle、Decision↔Architecture、Glossary↔Pattern/API、Risk↔AntiPattern 等 8 对交叉检查。发现矛盾 → 标注 + confidence 降级。发现互补 → confidence 提升。

### Phase 4: Knowledge Assembly

→ [prompts/knowledge-builder.md](knowledge-builder.md)

合并 Accepted Candidates → 生成最终 `.project-knowledge/` 产出 + Evidence Score Section。

### Phase 5: INDEX Generation

→ [prompts/index-generator.md](index-generator.md)

生成 Zettelkasten 风格 `INDEX.md` — 可导航的知识链接图。

### Phase 6: Knowledge Classification

→ [prompts/classifier.md](classifier.md)

对每个 Knowledge Object 分配 promotion level → 输出 `classification-report.yaml`。

### Phase 7: Instinct Extraction

→ [prompts/instinct-extractor.md](instinct-extractor.md)

从 `personal_candidates` 中提炼跨项目 Instinct（Always/Prefer/Avoid/Never）。

### Phase 8: Promotion Review

→ [prompts/promotion-reviewer.md](promotion-reviewer.md)

自动评分 personal_candidates：CrossProject / Reusability / FrameworkCoupling / EvidenceStrength。
≥9 分 → Auto-Promote。7-8 分 → 人工确认。5-6 分 → Keep as Project。<5 分 → Reject。

输出 `promotion-review.yaml`。Delivery 据此执行 Knowledge Promotion。

## Phase Gates

每个 Phase 完成后**必须**验证产出才进入下一 Phase：

| Gate | 检查 | 不满足时 |
|------|------|---------|
| Phase 1→2 | 10 个 `candidates/accepted/*.yaml` 全部存在且 ≥500 bytes | 补跑缺失 Extractor |
| Phase 2→3 | `candidates/verification-report.md` 存在 + 每个 Candidate 有 verdict | 返回 Verifier 补判定 |
| Phase 3→4 | `cross-validation-report.yaml` 存在 + 所有 pairs checked | 返回 Cross-Validator 补检查 |
| Phase 4→5 | `graph.json` + `.md` 双轨输出已写入 `.project-knowledge/` | 补跑 Knowledge Builder |
| Phase 5→6 | `INDEX.md` 已更新 + 所有 `[[link]]` 目标可达 | 补跑 INDEX Generator |
| Phase 6→7 | `classification-report.yaml` 存在 + 所有 knowledge object 已分类 | 补跑 Classifier |
| Phase 7→8 | `instincts.yaml` 存在 + personal_candidates 已提炼 | 补跑 Instinct Extractor |
| Phase 8→Exit | `promotion-review.yaml` 存在 + all candidates scored | 补跑 Promotion Reviewer |

**禁止提前退出**：全部 Phase 完成前不可进入 Delivery。每个 Phase 完成后 → 写入 session snapshot → 下一 Phase。Context 爆炸时下次 session 从 snapshot 继续，不重来。

## Exit

- 10 个 Extractor 全部返回结果（Phase 1 ✅）
- Verifier 已判定所有 Candidate（Phase 2 ✅）
- Cross-Validator 已完成所有 pairs 检查（Phase 3 ✅）
- Knowledge Builder 双轨输出已写入（Phase 4 ✅）
- INDEX.md 已重新生成（Phase 5 ✅）
- Classifier 已分配所有 promotion level（Phase 6 ✅）
