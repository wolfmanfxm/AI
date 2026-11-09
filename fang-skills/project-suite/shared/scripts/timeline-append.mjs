#!/usr/bin/env node
/**
 * Timeline Append v2.0.0
 *
 * 向 .project-knowledge/runtime/metrics/timeline.jsonl 追加一条 run 记录。
 *
 * 为什么必须先校验再写：append-only 的价值建立在「每一行都是完整 JSON」上。
 * 若先追加半条再报错，读取方（collect-metrics / knowledge-health）会在 JSON.parse
 * 处整行丢弃，且无法区分「坏行」与「未写完」——所以校验失败时**一行都不写**。
 *
 * Usage:
 *   node timeline-append.mjs <project-root> -           # JSON from stdin
 *   node timeline-append.mjs <project-root> record.json
 *
 * Exit: 0 = appended; 2 = invalid record; 3 = usage / IO
 */
'use strict';

import fs from 'node:fs';
import path from 'node:path';

const SKILLS = new Set([
  'project-analyzer', 'project-planner', 'project-architect', 'project-generator',
  'project-tester', 'project-reviewer', 'project-refactorer', 'project-documenter',
  'project-releaser',
]);
const STATUSES = new Set(['completed', 'degraded', 'blocked', 'failed']);
const TASK_RE = /^task-[0-9]{8}(-[A-Za-z0-9][A-Za-z0-9._-]*)?$/;

function die(msg, code) {
  process.stderr.write(`❌ timeline-append: ${msg}\n`);
  process.exit(code);
}

function readProjectName(root) {
  const cfg = path.join(root, '.project-knowledge', 'analysis-config.json');
  try {
    const doc = JSON.parse(fs.readFileSync(cfg, 'utf8'));
    const name = doc.project || doc.projectName || doc.name;
    if (typeof name === 'string' && name.trim()) return name.trim();
  } catch (_) { /* config 缺失是正常路径 */ }
  return path.basename(path.resolve(root)) || 'unknown-project';
}

function isIsoDate(v) {
  return typeof v === 'string' && !Number.isNaN(Date.parse(v));
}

function validate(rec) {
  const errors = [];
  if (!rec || typeof rec !== 'object' || Array.isArray(rec)) {
    errors.push('record 必须是 JSON 对象');
    return errors;
  }
  if (!SKILLS.has(rec.skill)) errors.push(`skill 非法: ${JSON.stringify(rec.skill)}`);
  if (!STATUSES.has(rec.status)) errors.push(`status 非法: ${JSON.stringify(rec.status)}（允许 completed/degraded/blocked/failed）`);
  const timing = (rec.timing && typeof rec.timing === 'object') ? rec.timing : null;
  if (!timing) {
    errors.push('timing 缺失或不是对象');
  } else {
    if (!isIsoDate(timing.startedAt)) errors.push('timing.startedAt 缺失或不是 ISO 时间');
    if (!isIsoDate(timing.finishedAt)) errors.push('timing.finishedAt 缺失或不是 ISO 时间');
    if ('durationMs' in timing &&
        !(Number.isInteger(timing.durationMs) && timing.durationMs >= 0)) {
      errors.push('timing.durationMs 必须是 >= 0 的整数');
    }
  }
  if (!(rec.quality && typeof rec.quality === 'object' &&
        Number.isInteger(rec.quality.confidence) &&
        rec.quality.confidence >= 0 && rec.quality.confidence <= 100)) {
    errors.push('quality.confidence 缺失或不在 0-100 的整数范围内');
  }
  return errors;
}

function main() {
  const [root, src] = process.argv.slice(2);
  if (!root) die('缺少 <project-root>', 3);

  let raw;
  try {
    raw = src && src !== '-'
      ? fs.readFileSync(src, 'utf8')
      : fs.readFileSync(0, 'utf8');
  } catch (e) {
    die(`读取记录失败: ${e.message}`, 3);
  }

  let rec;
  try {
    rec = JSON.parse(raw);
  } catch (e) {
    die(`记录不是合法 JSON: ${e.message}`, 2);
  }

  // 身份补齐（在 validate 之前，因为 taskId/runId 是必填但可由环境推导）
  if (!rec.taskId) rec.taskId = process.env.PS_TASK_ID || '';
  if (!TASK_RE.test(rec.taskId)) {
    die(`taskId 缺失或格式非法: ${JSON.stringify(rec.taskId)}（先执行 Task Resolution，或设置 $PS_TASK_ID）`, 2);
  }
  if (!rec.project) rec.project = readProjectName(root);
  if (!rec.schemaVersion) rec.schemaVersion = '2.0.0';
  if (rec.schemaVersion !== '2.0.0') {
    die(`schemaVersion 必须是 2.0.0，收到 ${JSON.stringify(rec.schemaVersion)}`, 2);
  }
  if (!rec.runId) {
    rec.runId = `${rec.taskId}/${rec.skill || 'unknown'}/${(rec.timing && rec.timing.startedAt) || 'unknown'}`;
  }
  if (rec.timing && !('durationMs' in rec.timing)) {
    const s = Date.parse(rec.timing.startedAt);
    const f = Date.parse(rec.timing.finishedAt);
    if (!Number.isNaN(s) && !Number.isNaN(f) && f >= s) rec.timing.durationMs = f - s;
  }

  const errors = validate(rec);
  if (errors.length) {
    die(`记录校验失败，未写入任何行:\n  - ${errors.join('\n  - ')}`, 2);
  }

  const outDir = path.join(root, '.project-knowledge', 'runtime', 'metrics');
  const out = path.join(outDir, 'timeline.jsonl');
  try {
    fs.mkdirSync(outDir, { recursive: true });
    // O_APPEND：单次写入，不读旧文件，因此并发追加不会互相覆盖。
    fs.appendFileSync(out, JSON.stringify(rec) + '\n');
  } catch (e) {
    die(`追加失败: ${e.message}`, 3);
  }
  process.stdout.write(out + '\n');
}

main();
