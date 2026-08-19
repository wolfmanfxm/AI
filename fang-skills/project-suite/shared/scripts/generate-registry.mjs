#!/usr/bin/env node
// Registry Generator v3.0
// 从各 skill.yaml 生成 4 份 registry 文件，消除多头权威：
//   - skills.generated.yaml   ← 完整 per-skill 数据（Skill Contract 单一派生源）
//   - skill-catalog.yaml      ← category 分组 + decision_model（框架常量）
//   - capabilities.yaml       ← capability_types + capability_order（框架常量 + DAG 派生）
//   - capability-routing.yaml ← routing（skill.yaml 派生）+ matching + dependency_graph
//
// 权威边界（消除"同一事实两处定义"，而非"所有配置只剩一个"）：
//   - skill.yaml              = Skill Contract（intrinsic：description/capabilities/produces/consumes/...）
//   - scheduler.yaml          = 路由/调度顺序（skill_order.decision_order / priority）
//   - workflow-library.yaml   = Workflow 编排（workflow_ref 的权威，即 used_by）
//   - gates.yaml              = Gate/checkpoint policy（requires_checkpoint/tests/review 的权威）
//   - compatibility.yaml      = 版本兼容矩阵（depends_on_skill 的权威）
//   - profiles.yaml           = Profile 编排（任务复杂度 → skill 激活范围）
//
// Capability DAG（能力依赖）不再手工维护，由 produces/consumes 自动推导：
//   B 依赖 A 的能力 ⇔ B.consumes ∩ A.produces ≠ ∅
//   注意：这是「能力依赖」（B 需要 A 产出的能力），不是「强制 skill 执行顺序」——
//   能力可能来自已有 .project-knowledge（如 KnowledgeBase），是否真跑 A 由 workflow/profile 决定。
//
// Usage:
//   node shared/scripts/generate-registry.mjs          # 生成 4 份 registry
//   node shared/scripts/generate-registry.mjs --check  # 漂移检测（不一致 exit 1）

import { readdirSync, readFileSync, existsSync, writeFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const SUITE_ROOT = join(__dirname, '..', '..');
const SKILLS_DIR = join(SUITE_ROOT, 'skills');
const REGISTRY_DIR = join(SUITE_ROOT, 'runtime', 'registry');

function grab(content, key) {
  const re = new RegExp(`^${key}:\\s*(.+)$`, 'm');
  const m = content.match(re);
  if (!m) return '';
  let v = m[1].trim();
  if (v.length >= 2 && v.startsWith('"') && v.endsWith('"')) v = v.slice(1, -1);
  return v;
}
function grabList(content, key) {
  const re = new RegExp(`^\\s*${key}:\\s*\\[([^\\]]*)\\]`, 'm');
  const m = content.match(re);
  if (!m) return [];
  return m[1].split(',').map(s => s.trim()).filter(Boolean);
}
// 提取顶层 key 的完整缩进块（到下一个顶层 key 或 EOF），用于 context_contract / interface 等嵌套结构
function grabBlock(content, key) {
  const lines = content.split('\n');
  const start = lines.findIndex(l => new RegExp(`^${key}:`).test(l));
  if (start === -1) return '';
  const out = [];
  for (let i = start; i < lines.length; i++) {
    const line = lines[i];
    if (i > start && /^\S/.test(line) && !line.trim().startsWith('#')) break;
    out.push(line);
  }
  while (out.length && out[out.length - 1].trim() === '') out.pop();
  return out.join('\n');
}
// 整体右移缩进（空白行保持空）
function indent(block, n) {
  const pad = ' '.repeat(n);
  return block.split('\n').map(l => (l.trim() === '' ? '' : pad + l)).join('\n');
}

// ── 读取 skills（只 intrinsic）──────────────────────────────────
const skills = [];
for (const name of readdirSync(SKILLS_DIR).sort()) {
  const yamlPath = join(SKILLS_DIR, name, 'skill.yaml');
  if (!existsSync(yamlPath)) continue;
  const c = readFileSync(yamlPath, 'utf8');
  skills.push({
    id: grab(c, 'id'),
    version: grab(c, 'version'),
    mode: grab(c, 'mode'),
    owner: grab(c, 'owner'),
    category: grab(c, 'category'),
    complexity: grab(c, 'complexity').replace(/[{}]/g, '').trim(),
    cost: grab(c, 'cost'),
    description: grab(c, 'description'),
    capabilities: grabList(c, 'capabilities'),
    requires: grabList(c, 'requires'),
    produces: grabList(c, 'produces'),
    consumes: grabList(c, 'consumes'),
    boundary: grab(c, 'boundary'),
    last_reviewed: grab(c, 'last_reviewed'),
    review_cadence_days: grab(c, 'review_cadence_days'),
    stages: grabList(c, 'stages'),
    triggers_cn: grabList(c, 'triggers_cn'),
    triggers_en: grabList(c, 'triggers_en'),
    context_contract: grabBlock(c, 'context_contract'),
    interface: grabBlock(c, 'interface'),
  });
}

// ── 从 produces/consumes 推导 Capability DAG ────────────────────
// B 依赖 A 的能力 ⇔ B.consumes ∩ A.produces ≠ ∅（能力依赖，非强制执行顺序）
function dependsOn(s) {
  return skills
    .filter(o => o.id !== s.id && s.consumes.some(c => o.produces.includes(c)))
    .map(o => o.id);
}

// 拓扑排序（Kahn），返回 wave 数组（每个 wave 是并行组）
function topoWaves(list) {
  const remaining = new Set(list.map(s => s.id));
  const edges = new Map(list.map(s => [s.id, dependsOn(s)]));
  const waves = [];
  while (remaining.size > 0) {
    const ready = list.filter(s =>
      remaining.has(s.id) && edges.get(s.id).every(d => !remaining.has(d))
    );
    if (ready.length === 0) {
      // 兜底：依赖环时，剩余全部并入当前 wave
      const leftover = list.filter(s => remaining.has(s.id));
      waves.push(leftover);
      leftover.forEach(s => remaining.delete(s.id));
      break;
    }
    ready.sort((a, b) => a.id.localeCompare(b.id));
    waves.push(ready);
    ready.forEach(s => remaining.delete(s.id));
  }
  return waves;
}

// 全量拓扑顺序（展平 waves），用于 catalog/routing 的确定性排序
const allWaves = topoWaves(skills);
const orderMap = new Map();
allWaves.forEach((wave, wi) => wave.forEach((s, si) => orderMap.set(s.id, wi * 1000 + si)));
function byTopo(a, b) { return orderMap.get(a.id) - orderMap.get(b.id); }

const orderedSkills = [...skills].sort(byTopo);

// ── 框架常量（非 per-skill，编排层之外）──────────────────────────
const CATEGORY_LABELS = {
  analysis: { label: '分析与理解', desc: '代码库结构、组件、API、模式分析' },
  planning: { label: '规划与设计', desc: '需求收敛、任务规划、架构设计' },
  creation: { label: '生成与实现', desc: '代码生成、文档生成' },
  verification: { label: '验证与审查', desc: '测试、代码审查' },
  evolution: { label: '演进与发布', desc: '重构、发布' },
  orchestration: { label: '编排', desc: '跨 Skill 流水线编排' },
};

const CAPABILITY_NAMES = {
  'project-analyzer': 'ProjectAnalysis',
  'project-planner': 'Planning',
  'project-architect': 'ArchitectureDesign',
  'project-generator': 'CodeGeneration',
  'project-tester': 'Testing',
  'project-reviewer': 'CodeReview',
  'project-refactorer': 'Refactoring',
  'project-documenter': 'Documentation',
  'project-releaser': 'Release',
  'pipeline-orchestrator': 'PipelineOrchestration',
};

const CAPABILITY_TYPES = `# --- 能力类型定义 ---
capability_types:
  KnowledgeBase:    # .project-knowledge/ + context.json
    description: 项目结构化知识（架构/组件/API/模式/编码约定），含生命周期状态
    format: [.md, .json]
  KnowledgeIndex:   # knowledge-index.json
    description: Capability→文件映射，Skill 按能力标签而非文件路径查询知识
    format: [.json]
  Context:          # context.json
    description: 下游 skill 标准上下文（技术栈/路径别名/约定/模块清单）
    format: [.json]
  State:            # .project-runtime/state.json + knowledge.json
    description: 项目持久化状态（执行历史/置信度/知识生命周期）
    format: [.json]
  Graph:            # graph.json
    description: 项目结构关系图谱（nodes+edges），支持 6 种标准查询
    format: [.json]
  Plan:             # PLAN.md（9 模块 Contract）
    description: Goal / Scope / Context / Reuse / Decision / Task / Deps / Risk / Acceptance
    format: [.md]
  Architecture:     # ARCHITECTURE.md
    description: 技术选型 + 模块设计 + API 契约（ADR 格式）
    format: [.md]
  Code:             # 源码文件（扩展名按项目技术栈）
    description: 生产级代码
    format: [.ts, .js]
  Test:             # .test.ts / .spec.ts + TEST-REPORT.md
    description: 测试文件 + 测试报告
    format: [.ts, .md]
  Review:           # REVIEW.md
    description: 五轴审查报告（分级问题 + 修复建议）
    format: [.md]
  RefactoredCode:   # 源码文件（重构后）
    description: 重构后代码（行为不变）+ REFACTOR.md
    format: [.ts, .js, .md]
  Documentation:    # API/组件/Changelog 文档
    description: 结构化技术文档
    format: [.md]
  Release:          # CHANGELOG.md + RELEASE-CHECKLIST.md
    description: 发布产物
    format: [.md]
  PipelinePlan: # pipeline-state.json + pipeline-report.md（编排建议，非执行）
    description: Pipeline 执行记录 + 报告
    format: [.json, .md]`;

const DECISION_MODEL = `# 四步决策模型
decision_model:
  step_1:
    name: Skill Resolver
    question: "哪个 Skill？"
    input: user_task
    output: matched_skill
    source: skill-catalog.yaml + capability-routing.yaml
  step_2:
    name: Knowledge Resolver
    question: "需要哪些知识？"
    input: matched_skill + project_context
    output: curated_knowledge
    source: context-resolver.md + graph.json
  step_3:
    name: Decision Engine
    question: "基于这些知识应该怎么做？"
    input: curated_knowledge + requirement
    output: decision_context
    source: completeness-check.md + adaptive-interview
  step_4:
    name: Execution
    question: "怎么执行？"
    input: decision_context + skill_contract
    output: artifacts
    source: workflow-protocol + skill prompts`;

// ── 1. skills.generated.yaml ───────────────────────────────────
function genSkillsGenerated() {
  const lines = [];
  lines.push('# skills.generated.yaml — 自动生成，勿手改');
  lines.push('# 单一派生源：从 skills/*/skill.yaml 生成，包含全部 per-skill intrinsic 数据。');
  lines.push('# catalog/capabilities/routing 不再包含 per-skill 字段，均以此文件为准。');
  lines.push('# 能力依赖由 produces/consumes 自动推导（见 capabilities.yaml capability_order，非强制执行顺序）。');
  lines.push('# 重新生成: node shared/scripts/generate-registry.mjs');
  lines.push('');
  lines.push('version: "3.0.0"');
  lines.push('generated: true');
  lines.push('');
  lines.push('skills:');
  for (const s of orderedSkills) {
    lines.push(`  ${s.id}:`);
    lines.push(`    version: "${s.version}"`);
    lines.push(`    mode: ${s.mode}`);
    lines.push(`    owner: ${s.owner}`);
    lines.push(`    category: ${s.category}`);
    lines.push(`    description: "${s.description}"`);
    lines.push(`    capabilities: [${s.capabilities.join(', ')}]`);
    lines.push(`    complexity: {${s.complexity}}`);
    lines.push(`    cost: ${s.cost}`);
    lines.push(`    requires: [${s.requires.join(', ')}]`);
    lines.push(`    produces: [${s.produces.join(', ')}]`);
    lines.push(`    consumes: [${s.consumes.join(', ')}]`);
    lines.push(`    boundary: "${s.boundary}"`);
    lines.push(`    last_reviewed: "${s.last_reviewed}"`);
    lines.push(`    review_cadence_days: ${s.review_cadence_days}`);
    lines.push(`    stages: [${s.stages.join(', ')}]`);
    lines.push(`    triggers_cn: [${s.triggers_cn.join(', ')}]`);
    lines.push(`    triggers_en: [${s.triggers_en.join(', ')}]`);
    if (s.context_contract) lines.push(indent(s.context_contract, 4));
    if (s.interface) lines.push(indent(s.interface, 4));
  }
  return lines.join('\n') + '\n';
}

// ── 2. skill-catalog.yaml ──────────────────────────────────────
function genSkillCatalog() {
  const lines = [];
  lines.push('# Skill Catalog v3.0 — 自动生成，勿手改');
  lines.push('# 单一源：category 分组从 skills.generated.yaml 派生，decision_model 为框架常量。');
  lines.push('# 回答"这个任务应该用哪个 Skill？"');
  lines.push('');
  lines.push('version: "3.0.0"');
  lines.push('generated: true');
  lines.push('');
  lines.push('categories:');
  for (const [key, meta] of Object.entries(CATEGORY_LABELS)) {
    const inCategory = orderedSkills.filter(s => s.category === key).map(s => s.id);
    if (inCategory.length === 0) continue;
    lines.push(`  ${key}:`);
    lines.push(`    label: ${meta.label}`);
    lines.push(`    description: ${meta.desc}`);
    lines.push(`    skills: [${inCategory.join(', ')}]`);
  }
  lines.push('');
  lines.push(DECISION_MODEL);
  return lines.join('\n') + '\n';
}

// ── 3. capabilities.yaml ───────────────────────────────────────
function genCapabilities() {
  const lines = [];
  lines.push('# Capability Registry v3.0 — 自动生成，勿手改');
  lines.push('# 单一源：per-skill 调度数据以 skills.generated.yaml 为准；本文件只存能力类型 + 能力依赖顺序。');
  lines.push('# Scheduler 读本文件构建 DAG。capability_order 从 produces/consumes 自动推导（能力依赖，非强制执行）。');
  lines.push('');
  lines.push('version: "3.0.0"');
  lines.push('generated: true');
  lines.push('');
  lines.push(CAPABILITY_TYPES);
  lines.push('');

  // 调度顺序（拓扑排序，从 produces/consumes 推导，排除 orchestration 元执行器）
  const pipeline = orderedSkills.filter(s => s.category !== 'orchestration');
  const waves = topoWaves(pipeline);
  lines.push('# --- 能力依赖顺序（拓扑排序，由 produces/consumes 推导，排除 orchestrator）---');
  lines.push('# 注意：这是「能力满足的先后」，不是「强制 skill 执行顺序」。');
  lines.push('# 能力可能来自已有 .project-knowledge（如 KnowledgeBase），是否真跑 producer 由 workflow/profile 决定。');
  lines.push('capability_order:');
  waves.forEach((wave, i) => {
    lines.push(`  wave_${i + 1}: [${wave.map(s => s.id).join(', ')}]`);
  });
  return lines.join('\n') + '\n';
}

// ── 4. capability-routing.yaml ─────────────────────────────────
function genCapabilityRouting() {
  const lines = [];
  lines.push('# Capability Routing v3.0 — 自动生成，勿手改');
  lines.push('# 用户意图 → 能力匹配 → Skill 路由。');
  lines.push('# 单一源：provider/intents/produces 从 skills.generated.yaml 派生，capability 名称为框架常量。');
  lines.push('');
  lines.push('version: "3.0.0"');
  lines.push('generated: true');
  lines.push('');
  lines.push('routing:');
  for (const s of orderedSkills) {
    const cap = CAPABILITY_NAMES[s.id] || s.id;
    lines.push(`  ${cap}:`);
    lines.push(`    description: ${s.description}`);
    lines.push(`    intents:`);
    lines.push(`      cn: [${s.triggers_cn.join(', ')}]`);
    lines.push(`      en: [${s.triggers_en.join(', ')}]`);
    lines.push(`    provider: ${s.id}`);
    lines.push(`    produces: [${s.produces.join(', ')}]`);
  }
  lines.push('');
  lines.push('# 匹配规则');
  lines.push('matching:');
  lines.push('  # 1. 精确 Intent 匹配 → 直接路由');
  lines.push('  # 2. 模糊 Intent 匹配 → 展示 Top-3 能力让用户选择');
  lines.push('  # 3. 多能力匹配 → 按 consumes 是否有上游产出排序');
  lines.push('  # 4. 无匹配 → 展示全部能力列表');
  lines.push('  strategy: [exact_intent, fuzzy_top3, availability_sort, full_list]');
  lines.push('');
  lines.push('# 能力依赖图（从 produces/consumes 推导，Capability DAG，非强制执行顺序）');
  lines.push('dependency_graph:');
  for (const s of orderedSkills) {
    const cap = CAPABILITY_NAMES[s.id] || s.id;
    lines.push(`  ${cap}: { provides: [${s.produces.join(', ')}], needs: [${s.consumes.join(', ')}] }`);
  }
  return lines.join('\n') + '\n';
}

// ── 写文件 / 漂移检测 ─────────────────────────────────────────
const outputs = {
  'skills.generated.yaml': genSkillsGenerated(),
  'skill-catalog.yaml': genSkillCatalog(),
  'capabilities.yaml': genCapabilities(),
  'capability-routing.yaml': genCapabilityRouting(),
};

const CHECK_MODE = process.argv.includes('--check');

if (CHECK_MODE) {
  let drift = false;
  for (const [name, content] of Object.entries(outputs)) {
    const filePath = join(REGISTRY_DIR, name);
    const existing = existsSync(filePath) ? readFileSync(filePath, 'utf8') : '';
    if (existing === content) {
      console.log(`✅ ${name} — 一致`);
    } else {
      drift = true;
      console.log(`❌ ${name} — 漂移`);
    }
  }
  if (drift) {
    console.log('');
    console.log('❌ Registry drift detected');
    console.log('runtime/registry/skills.generated.yaml');
    console.log('runtime/registry/capabilities.yaml');
    console.log('runtime/registry/skill-catalog.yaml');
    console.log('runtime/registry/capability-routing.yaml');
    console.log('');
    console.log('Run: node shared/scripts/generate-registry.mjs');
    process.exit(1);
  } else {
    console.log('');
    console.log(`✅ 无漂移 — ${skills.length} 个 skill 的 registry 与 skill.yaml 一致`);
    process.exit(0);
  }
} else {
  for (const [name, content] of Object.entries(outputs)) {
    writeFileSync(join(REGISTRY_DIR, name), content);
  }
  console.log(`✅ 生成 ${skills.length} 个 skill → 4 份 registry（依赖从 produces/consumes 推导）`);
}
