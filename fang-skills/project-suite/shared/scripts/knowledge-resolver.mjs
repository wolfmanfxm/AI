#!/usr/bin/env node
// Knowledge Resolver — 分桶 + hydrate + 候选集过滤 + tag/confidence rank。
// 读取 knowledge-index.json，按 type 分桶产出 context-package.json。
// 由 knowledge-resolver.sh 调用：node knowledge-resolver.mjs <knowledgeDir> <generatedAt> <indexPath> <outPath> <candidates>

import fs from 'node:fs';
import path from 'node:path';

const [, , knowledgeDir, generatedAt, indexPath, outPath, candidatesRaw = ''] = process.argv;

const candidates = new Set(candidatesRaw.split(',').map(c => c.trim()).filter(Boolean));
const TOP_K_KNOWLEDGE = 5;
const TOP_K_GUIDANCE = 3;

function stripQuotes(s) {
  s = (s || '').trim();
  if (s.length >= 2 && (s[0] === '"' || s[0] === "'") && s[s.length - 1] === s[0]) {
    return s.slice(1, -1);
  }
  return s;
}

function readSource(source) {
  const filePath = path.join(knowledgeDir, source);
  let content;
  try {
    content = fs.readFileSync(filePath, 'utf8');
  } catch {
    return { fm: {}, body: '' };
  }
  const m = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!m) return { fm: {}, body: content };
  const fm = {};
  for (const line of m[1].split(/\r?\n/)) {
    const idx = line.indexOf(':');
    if (idx !== -1) {
      fm[line.slice(0, idx).trim()] = line.slice(idx + 1).trim();
    }
  }
  return { fm, body: content.slice(m[0].length) };
}

function firstHeading(body) {
  const m = body.match(/^#\s+(.+)$/m);
  return m ? m[1].trim() : '';
}

function hydrateStatement(source) {
  const { fm, body } = readSource(source);
  let statement = stripQuotes(fm.statement || fm.summary || fm.pattern || '');
  if (!statement) {
    const title = firstHeading(body);
    const sections = [];
    const re = /^##\s+(.+)$/gm;
    let m;
    while ((m = re.exec(body)) !== null && sections.length < 5) {
      sections.push(m[1].trim());
    }
    statement = sections.length ? `${title} — ${sections.join(' / ')}` : title;
  }
  let constraints = [];
  const raw = stripQuotes(fm.constraints || '');
  if (raw) {
    constraints = raw.split(/[,;；]/).map(c => c.trim()).filter(Boolean);
  } else {
    const c = stripQuotes(fm.constraint || '');
    if (c) constraints = [c];
  }
  return { statement, constraints };
}

function confidenceOf(fm) {
  const v = parseFloat(stripQuotes(fm.confidence || '0'));
  return Number.isFinite(v) ? v : 0;
}

function tagsOf(fm) {
  const raw = stripQuotes(fm.tags || '');
  return raw ? raw.split(/[,;；]/).map(t => t.trim()).filter(Boolean) : [];
}

function isCandidate(capName, source, tags) {
  if (candidates.size === 0) return true;
  const base = path.basename(source);
  const baseNoExt = path.basename(source, path.extname(source));
  return candidates.has(source)
    || candidates.has(capName)
    || candidates.has(base)
    || candidates.has(baseNoExt)
    || tags.some(t => candidates.has(t));
}

const index = JSON.parse(fs.readFileSync(indexPath, 'utf8'));

const rules = [];
const knowledge = [];
const guidance = [];
// 项目级应然建议（新代码改进方向，非现状规范）——独立桶。
// 2026-09-18 修：此前**没有这个桶也没有分支**，recommendation 落进下面的 `else` → 被塞进 knowledge 桶，
// 于是「Analyzer → recommendations/ → index → resolver → context.recommendations[] → Planner/Generator」
// 这条链在最后两段断开（schema 里也从未定义过 context.recommendations）。
const recommendations = [];

for (const [capName, cap] of Object.entries(index.capabilities || {})) {
  for (const fe of cap.files || []) {
    const typ = fe.type || '';
    const source = fe.source || '';
    const enforcement = fe.enforcement || 'recommended';
    const priority = fe.priority || 'P2';
    const { fm } = readSource(source);
    const conf = confidenceOf(fm);
    const tags = tagsOf(fm);

    if (typ === 'rule') {
      rules.push({
        rule: fm.id || path.basename(source, path.extname(source)),
        type: typ,
        constraint: stripQuotes(fm.constraint || ''),
        source,
        enforcement: 'blocking',
        blocking: true,
      });
    } else if (typ === 'decision') {
      if (enforcement === 'blocking') {
        // project-scope decision → 恒 blocking constraints
        rules.push({
          rule: fm.id || path.basename(source, path.extname(source)),
          type: typ,
          scope: fe.scope || 'project',
          constraint: stripQuotes(fm.constraint || ''),
          source,
          enforcement,
          blocking: true,
        });
      } else {
        // task-scope decision → 不进 blocking，作 advisory 参考
        if (!isCandidate(capName, source, tags)) continue;
        const { statement, constraints } = hydrateStatement(source);
        guidance.push({
          type: 'decision',
          scope: fe.scope || 'task',
          source,
          enforcement,
          priority,
          pattern: statement,
          constraints,
          confidence: conf,
          tags,
        });
      }
    } else if (typ === 'experience' || typ === 'playbook') {
      if (!isCandidate(capName, source, tags)) continue;
      const { statement, constraints } = hydrateStatement(source);
      guidance.push({
        type: typ,
        source,
        enforcement,
        priority,
        pattern: statement,
        constraints,
        confidence: conf,
        tags,
      });
    } else if (typ === 'recommendation') {
      // 项目级应然建议：与 knowledge 桶的区别是「现状 vs 应然」，故独立成桶，不混入 knowledge
      if (!isCandidate(capName, source, tags)) continue;
      const { statement, constraints } = hydrateStatement(source);
      recommendations.push({
        capability: capName,
        type: typ,
        source,
        enforcement,
        priority,
        statement,
        constraints,
        confidence: conf,
        tags,
      });
    } else {
      // pattern / component / api
      if (!isCandidate(capName, source, tags)) continue;
      const { statement, constraints } = hydrateStatement(source);
      knowledge.push({
        capability: capName,
        source,
        enforcement,
        priority,
        pattern: statement,
        constraints,
        confidence: conf,
        tags,
      });
    }
  }
}

// rank：priority → confidence↓ → tag-overlap↓ → source 字母序
function prio(e) {
  return { P1: 0, P2: 1, P3: 2 }[e.priority || 'P2'] ?? 1;
}
function rankKey(e) {
  const overlap = candidates.size ? (e.tags || []).filter(t => candidates.has(t)).length : 0;
  return [prio(e), -(e.confidence || 0), -overlap, e.source || ''];
}
function cmp(a, b) {
  for (let i = 0; i < a.length; i++) {
    if (a[i] < b[i]) return -1;
    if (a[i] > b[i]) return 1;
  }
  return 0;
}
knowledge.sort((a, b) => cmp(rankKey(a), rankKey(b)));
guidance.sort((a, b) => cmp(rankKey(a), rankKey(b)));

// Top-K 仅当传了 candidates 才裁；无 candidates = 全量，不裁
if (candidates.size) {
  knowledge.length = Math.min(knowledge.length, TOP_K_KNOWLEDGE);
  guidance.length = Math.min(guidance.length, TOP_K_GUIDANCE);
}

// 保护：candidates 全未命中 → 显式告警（避免「garbage candidates → 静默空 knowledge」）
if (candidates.size > 0 && knowledge.length === 0 && guidance.length === 0) {
  console.warn(`⚠️  ${candidates.size} 个 candidates 未命中任何 pattern/component/api/experience/playbook（knowledge/guidance 桶）`);
  console.warn(`   candidates 应为 source 路径（patterns/table.md）/ capability 名（patterns）/ tag / basename（table）`);
  console.warn(`   实际传入：[${[...candidates].join(', ')}]`);
}

const pkg = {
  schemaVersion: '2.1.0',
  generatedBy: 'knowledge-resolver',
  generatedAt,
  context: { rules, knowledge, guidance, recommendations },
};

fs.writeFileSync(outPath, JSON.stringify(pkg, null, 2));

console.log(`Generated: ${outPath}`);
console.log(`  rules: ${rules.length}  knowledge: ${knowledge.length}  guidance: ${guidance.length}`);
