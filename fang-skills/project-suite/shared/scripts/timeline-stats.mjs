#!/usr/bin/env node
/**
 * Timeline Stats v2.0.0
 *
 * 读取 timeline.jsonl（或 v1 timeline.json）并输出一行：
 *   <totalRuns> <minSeconds> <maxSeconds> <avgSeconds> <durationSamples>
 *
 * totalRuns = 行数（含缺 timing 的记录）；durationSamples = 真正参与时长统计的条数。
 *
 * 聚合在读取时计算——不读取/不依赖任何落盘的 aggregates 字段。
 * v1 兼容：接受 {runs: []} 或顶层数组两种旧形态。
 *
 * Usage: node timeline-stats.mjs <timeline.jsonl|timeline.json>
 * Exit:  0 = ok（文件可读）；2 = 文件不可读 / JSON 形态非法
 */
'use strict';

import fs from 'node:fs';

const file = process.argv[2];
if (!file) {
  process.stderr.write('usage: node timeline-stats.mjs <timeline.jsonl|timeline.json>\n');
  process.exit(2);
}

let text;
try {
  text = fs.readFileSync(file, 'utf8');
} catch (e) {
  process.stderr.write(`timeline-stats: 读取失败: ${e.message}\n`);
  process.exit(2);
}

let runs = [];
let badLines = 0;

if (file.endsWith('.jsonl')) {
  for (const line of text.split('\n')) {
    if (!line.trim()) continue;
    try {
      runs.push(JSON.parse(line));
    } catch (_) {
      badLines += 1;
    }
  }
} else {
  let doc;
  try {
    doc = JSON.parse(text);
  } catch (e) {
    process.stderr.write(`timeline-stats: JSON 解析失败: ${e.message}\n`);
    process.exit(2);
  }
  runs = Array.isArray(doc) ? doc : (Array.isArray(doc.runs) ? doc.runs : []);
}

const seconds = [];
for (const r of runs) {
  if (!r || typeof r !== 'object') continue;
  const t = r.timing || {};
  let ms = t.durationMs;
  if (!Number.isFinite(ms) && t.startedAt && t.finishedAt) {
    const s = Date.parse(t.startedAt);
    const f = Date.parse(t.finishedAt);
    if (!Number.isNaN(s) && !Number.isNaN(f) && f >= s) ms = f - s;
  }
  if (Number.isFinite(ms) && ms >= 0) seconds.push(ms / 1000);
}

if (badLines > 0) {
  process.stderr.write(`timeline-stats: ⚠️ 跳过 ${badLines} 行非法 JSON\n`);
}

if (!seconds.length) {
  process.stdout.write(`${runs.length} 0 0 0 0\n`);
} else {
  const min = Math.round(Math.min(...seconds));
  const max = Math.round(Math.max(...seconds));
  const avg = Math.round(seconds.reduce((a, b) => a + b, 0) / seconds.length);
  process.stdout.write(`${runs.length} ${min} ${max} ${avg} ${seconds.length}\n`);
}
