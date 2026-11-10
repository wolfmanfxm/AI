#!/usr/bin/env node
/**
 * Analysis Config Merge v1.0
 *
 * 把「本次运行的草稿配置」合并进项目级 analysis-config.json。
 *
 * 为什么需要：Discovery 直接写根配置时，一次探针运行（monitor-only / 中途取消）
 * 会把上一轮的用户配置覆盖掉——实测 monitorOnly:true 落进了根文件，且没有备份。
 * 现在 Discovery 只写任务目录下的草稿，根配置的写入收敛到这里：
 *   - 先备份（runtime/backups/），再合并；
 *   - 项目身份（projectName / createdAt）稳定，不被后续运行改写；
 *   - 任务级字段（monitorOnly / taskScoped 等）拒绝进入根配置。
 *
 * Usage:
 *   node analysis-config-merge.mjs <project-root> <draft-config.json> [--apply]
 *
 * 默认 dry-run（只打印将要发生的变更）；--apply 才写盘。
 * Exit: 0 = ok；2 = 参数/IO 错误；3 = 草稿非法（缺必填字段/枚举）
 */
'use strict';

import fs from 'node:fs';
import path from 'node:path';

const VALID_MODES = new Set(['quick', 'standard', 'deep', 'incremental']);
const VALID_OUTPUT = new Set(['vault', 'local']);
// output 不是必填：真实项目（afc）的 analysis-config.json 只记录 mode/scope/depth 等，
// 从来没有 output 字段。把它设为必填会让既有项目无法合并。
const REQUIRED = ['projectName', 'mode', 'scope'];

// 任务级字段：只属于某次运行，不得进入项目级配置。
// 注意方向——这里是**黑名单**，不是白名单：根配置是用户长期维护的文件，
// 允许存在 schema 之外的字段（depth / dimensions / driftHotspots / baseCommit …）。
// 用白名单会把 afc 实测的 10/15 个字段静默删掉（depth、dimensions、driftHotspots、
// baseCommit、headCommit、commitsInRange、driftedFiles、workspacePriority、vaultSync、updatedAt）。
const TASK_SCOPED = new Set([
  'monitorOnly', 'taskScoped', 'taskId', 'probe', 'dryRun', 'runId',
]);

function die(msg, code = 2) {
  process.stderr.write(`❌ analysis-config-merge: ${msg}\n`);
  process.exit(code);
}

const args = process.argv.slice(2);
const apply = args.includes('--apply');
const [root, draftPath] = args.filter((a) => a !== '--apply');
if (!root || !draftPath) {
  die('usage: node analysis-config-merge.mjs <project-root> <draft-config.json> [--apply]');
}

let draft;
try {
  draft = JSON.parse(fs.readFileSync(draftPath, 'utf8'));
} catch (e) {
  die(`读取草稿失败: ${e.message}`);
}
if (!draft || typeof draft !== 'object' || Array.isArray(draft)) die('草稿必须是 JSON 对象', 3);

for (const key of REQUIRED) {
  if (!(key in draft)) die(`草稿缺少必填字段 ${key}`, 3);
}
if (!VALID_MODES.has(draft.mode)) die(`mode 非法: ${JSON.stringify(draft.mode)}`, 3);
if (!Array.isArray(draft.scope)) die('scope 必须是数组', 3);
if (draft.output !== undefined &&
    (!Array.isArray(draft.output) || draft.output.some((v) => !VALID_OUTPUT.has(v)))) {
  die(`output 非法: ${JSON.stringify(draft.output)}（允许 vault/local）`, 3);
}

const kd = path.join(root, '.project-knowledge');
const target = path.join(kd, 'analysis-config.json');
const backupsDir = path.join(kd, 'runtime', 'backups');

let existing = null;
let existed = false;
try {
  existing = JSON.parse(fs.readFileSync(target, 'utf8'));
  existed = true;
} catch (_) {
  existed = false;
}

const merged = {};
// 1) 草稿里除任务级开关外的字段（新项目首次写入 / 本次运行明确声明的值）
for (const [k, v] of Object.entries(draft)) {
  if (!TASK_SCOPED.has(k)) merged[k] = v;
}
// 2) 项目身份稳定：已有 projectName / createdAt 不被覆盖
if (existed) {
  for (const k of ['projectName', 'createdAt', 'schemaVersion']) {
    if (existing[k] !== undefined) merged[k] = existing[k];
  }
  // 3) 根配置里已存在、草稿没提的字段一律保留（用户手工维护的配置不能被合并抹掉）
  for (const [k, v] of Object.entries(existing)) {
    if (!TASK_SCOPED.has(k) && merged[k] === undefined) merged[k] = v;
  }
  // 4) 空的 vaultPath 不覆盖已有值
  if (!merged.vaultPath && existing.vaultPath) merged.vaultPath = existing.vaultPath;
}
// firstAnalysis：草稿可显式声明；否则沿用根配置；新项目默认 true。
// 不能写成「existed ? existing : true」——那会让 firstAnalysis 永远为 true。
if (!('firstAnalysis' in draft)) {
  merged.firstAnalysis = existed && existing.firstAnalysis !== undefined
    ? existing.firstAnalysis
    : true;
}
if (!merged.schemaVersion) merged.schemaVersion = '1.0.0';
if (!merged.createdAt) merged.createdAt = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');

// 任务级字段被丢弃时必须显式告知，避免「以为写进去了」。
const dropped = Object.keys(draft).filter((k) => TASK_SCOPED.has(k));
const changed = JSON.stringify(merged) !== JSON.stringify(existing);

process.stdout.write(`TARGET=${target}\n`);
process.stdout.write(`CHANGED=${changed ? 1 : 0}\n`);
process.stdout.write(`CREATED=${existed ? 0 : 1}\n`);
process.stdout.write(`DROPPED=${dropped.join(',')}\n`);

if (!apply) {
  process.stdout.write('APPLIED=0 (dry-run; pass --apply to write)\n');
  process.exit(0);
}

if (changed || !existed) {
  fs.mkdirSync(backupsDir, { recursive: true });
  if (existed) {
    const stamp = new Date().toISOString().replace(/[:.]/g, '-');
    fs.copyFileSync(target, path.join(backupsDir, `analysis-config.${stamp}.json`));
  }
  fs.mkdirSync(kd, { recursive: true });
  fs.writeFileSync(target, JSON.stringify(merged, null, 2) + '\n');
}
process.stdout.write('APPLIED=1\n');
