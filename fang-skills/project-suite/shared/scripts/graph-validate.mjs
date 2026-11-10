#!/usr/bin/env node
/**
 * Structural Graph Validator v1.2.0
 *
 * 校验 `.project-knowledge/graph.json` 是否符合 graph.schema.json v3.0.0。
 * 机器规则只有 schema 一份：本脚本执行 schema 的**可机算子集**
 *   - required / additionalProperties / type / const / enum / pattern / minLength
 *   - format: date-time（RFC3339）
 *   - minimum / integer
 *   - items（递归数组校验）
 *   - allOf/if/then（按 type 的条件必填与 ID 命名空间）
 * 再加 JSON Schema 表达不了的业务约束：
 *   - 禁止 knowledge object 字段与节点 dependsOn（关系只写在顶层 edges）
 *   - 节点 id 唯一；边端点必须存在
 *
 * 支持范围**明确写在这里**：不实现 oneOf/anyOf/not、跨文档 $ref、exclusiveMinimum 等数值约束、
 * 字符串 format 的其他类型。新增 schema 关键字若不在上述范围，需同步扩展本脚本。
 *
 * Usage:
 *   node graph-validate.mjs <graph.json> [--strict] [--allow-legacy] [--quiet]
 *
 * Exit:
 *   0 = 合法（或 --allow-legacy 命中 2.0.0）
 *   1 = 非法
 *   2 = 用法 / 读取 / JSON 解析错误
 */
'use strict';

import fs from 'node:fs';

const SCHEMA_PATH = new URL('../schemas/graph.schema.json', import.meta.url);
let SCHEMA;
try {
  SCHEMA = JSON.parse(fs.readFileSync(SCHEMA_PATH, 'utf8'));
} catch (e) {
  process.stderr.write(`graph-validate: 无法读取 graph.schema.json: ${e.message}\n`);
  process.exit(2);
}

const ALLOWED_ROOT_KEYS = Object.keys(SCHEMA.properties);
const ALLOWED_NODE_KEYS = Object.keys(SCHEMA.$defs.node.properties);
const ALLOWED_EDGE_KEYS = Object.keys(SCHEMA.$defs.edge.properties);

// JSON Schema 无法表达的“知识字段回流”黑名单（结构图不允许 Knowledge Object 字段）。
const KNOWLEDGE_FIELDS = [
  'statement', 'confidence', 'scope', 'category', 'obviousness', 'tags',
  'predictive_power', 'related', 'occurrences', 'source', 'evidence', 'promotion',
];

const args = process.argv.slice(2);
const flags = new Set(args.filter((a) => a.startsWith('--')));
const file = args.find((a) => !a.startsWith('--'));

if (!file) {
  process.stderr.write('usage: node graph-validate.mjs <graph.json> [--strict] [--allow-legacy] [--quiet]\n');
  process.exit(2);
}

const strict = flags.has('--strict');
const allowLegacy = flags.has('--allow-legacy');
const quiet = flags.has('--quiet');

let graph;
try {
  graph = JSON.parse(fs.readFileSync(file, 'utf8'));
} catch (e) {
  process.stderr.write(`graph-validate: 读取/解析失败: ${e.message}\n`);
  process.exit(2);
}

const errors = [];
const err = (msg) => errors.push(msg);

// ── Schema 子集执行器 ─────────────────────────────────────────────────────
function resolveRef(ref) {
  if (typeof ref !== 'string' || !ref.startsWith('#/')) return null;
  let cur = SCHEMA;
  for (const part of ref.slice(2).split('/')) {
    cur = cur?.[part];
    if (cur === undefined) return null;
  }
  return cur;
}

function actualType(v) {
  if (v === null) return 'null';
  if (Array.isArray(v)) return 'array';
  return typeof v;
}

function typeMatches(spec, v) {
  const types = Array.isArray(spec) ? spec : [spec];
  return types.some((t) => {
    if (t === 'integer') return Number.isInteger(v);
    if (t === 'number') return typeof v === 'number' && !Number.isNaN(v);
    return actualType(v) === t;
  });
}

// RFC3339 子集；Date.parse 兜底拒绝 2026-13-45 这类结构合法但日期非法的值。
function isDateTime(v) {
  return typeof v === 'string' &&
    /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$/.test(v) &&
    !Number.isNaN(Date.parse(v));
}

function matchesCondition(cond, val) {
  if (!cond || typeof cond !== 'object') return true;
  if (cond.required && !cond.required.every((k) => k in val)) return false;
  for (const [k, sub] of Object.entries(cond.properties || {})) {
    if (!(k in val)) continue;
    if (sub.const !== undefined && val[k] !== sub.const) return false;
    if (sub.enum && !sub.enum.includes(val[k])) return false;
    if (sub.type && !typeMatches(sub.type, val[k])) return false;
  }
  return true;
}

// opts.skipUnknown：未知键由调用方的业务扫描负责（给出 knowledge object 等专用提示）。
function validate(schema, val, at, opts = {}) {
  if (!schema || typeof schema !== 'object') return;
  if (schema.$ref) {
    const resolved = resolveRef(schema.$ref);
    if (!resolved) {
      err(`${at} 引用了无法解析的 $ref: ${schema.$ref}`);
      return;
    }
    schema = resolved;
  }

  if (schema.const !== undefined && val !== schema.const) {
    err(`${at} 必须是 ${JSON.stringify(schema.const)}，收到 ${JSON.stringify(val)}`);
  }
  if (schema.enum && !schema.enum.includes(val)) {
    err(`${at}=${JSON.stringify(val)} 不在 ${schema.enum.join('/')}`);
  }
  if (schema.type && !typeMatches(schema.type, val)) {
    err(`${at} 类型应为 ${[].concat(schema.type).join('|')}，收到 ${JSON.stringify(val)}`);
    return; // 类型不符时后续格式检查没有意义
  }

  if (typeof val === 'string') {
    if (schema.minLength !== undefined && val.length < schema.minLength) {
      err(`${at} 长度必须 >= ${schema.minLength}`);
    }
    if (schema.pattern && !new RegExp(schema.pattern).test(val)) {
      err(`${at}=${JSON.stringify(val)} 不符合 schema pattern /${schema.pattern}/`);
    }
    if (schema.format === 'date-time' && !isDateTime(val)) {
      err(`${at}=${JSON.stringify(val)} 不是合法的 date-time（RFC3339）`);
    }
  }

  if (typeof val === 'number' && schema.minimum !== undefined && val < schema.minimum) {
    err(`${at} 必须 >= ${schema.minimum}`);
  }

  if (Array.isArray(val) && schema.items) {
    val.forEach((item, i) => validate(schema.items, item, `${at}[${i}]`, opts));
  }

  if (val && typeof val === 'object' && !Array.isArray(val)) {
    for (const k of schema.required || []) {
      if (!(k in val)) err(`${at}.${k} 必填`);
    }
    const props = schema.properties || {};
    for (const k of Object.keys(val)) {
      if (k in props) {
        validate(props[k], val[k], `${at}.${k}`, opts);
      } else if (schema.additionalProperties === false) {
        if (!opts.skipUnknown) err(`${at} 含不允许的键: ${k}`);
      } else if (schema.additionalProperties && typeof schema.additionalProperties === 'object') {
        validate(schema.additionalProperties, val[k], `${at}.${k}`, opts);
      }
    }
    for (const rule of schema.allOf || []) {
      if (!rule.if || matchesCondition(rule.if, val)) {
        validate(rule.then || {}, val, at, opts);
      }
    }
  }
}

if (!graph || typeof graph !== 'object' || Array.isArray(graph)) {
  err('顶层必须是 JSON 对象');
} else {
  // ── schemaVersion / legacy ───────────────────────────────────────────
  const version = graph.schemaVersion;
  if (version !== '3.0.0') {
    if (allowLegacy && !strict && version === '2.0.0') {
      process.stderr.write(
        'graph-validate: ⚠️ legacy graph schemaVersion=2.0.0（Knowledge Objects 形状）；' +
        '不是结构图。请重跑 project-analyzer 全量重建。\n'
      );
      process.exit(0);
    }
    err(`schemaVersion 必须是 "3.0.0"，收到 ${JSON.stringify(version)}` +
        (version === '2.0.0' ? '（2.0.0 是旧 Knowledge Objects 图，需重跑 Analyzer）' : ''));
  }

  // ── 根键白名单（业务扫描负责专用提示，因此 schema 层的未知键检查跳过） ──
  for (const k of Object.keys(graph)) {
    if (!ALLOWED_ROOT_KEYS.includes(k)) err(`根对象含不允许的键: ${k}`);
  }

  // ── schema 可机算子集：根字段类型 / date-time / 嵌套 nodes/edges ──
  validate(SCHEMA, graph, 'graph', { skipUnknown: true });

  // ── 业务约束（JSON Schema 表达不了） ─────────────────────────────────
  if (Array.isArray(graph.nodes)) {
    const ids = new Set();
    graph.nodes.forEach((n, i) => {
      const at = `nodes[${i}]`;
      if (!n || typeof n !== 'object' || Array.isArray(n)) return;
      for (const k of Object.keys(n)) {
        if (ALLOWED_NODE_KEYS.includes(k)) continue;
        if (KNOWLEDGE_FIELDS.includes(k)) err(`${at} 含 Knowledge Object 字段 "${k}"（结构图不允许）`);
        else if (k === 'dependsOn') err(`${at} 含 dependsOn；关系只允许写在顶层 edges`);
        else err(`${at} 含不允许的键: ${k}`);
      }
      if (typeof n.id === 'string') {
        if (ids.has(n.id)) err(`${at}.id 重复: ${n.id}`);
        ids.add(n.id);
      }
    });

    if (Array.isArray(graph.edges)) {
      graph.edges.forEach((e, i) => {
        const at = `edges[${i}]`;
        if (!e || typeof e !== 'object' || Array.isArray(e)) return;
        for (const k of Object.keys(e)) {
          if (!ALLOWED_EDGE_KEYS.includes(k)) err(`${at} 含不允许的键: ${k}`);
        }
        if (typeof e.from === 'string' && !ids.has(e.from)) err(`${at}.from=${e.from} 指向不存在的 node`);
        if (typeof e.to === 'string' && !ids.has(e.to)) err(`${at}.to=${e.to} 指向不存在的 node`);
      });
    }
  }
}

if (errors.length) {
  for (const e of errors) process.stderr.write(`graph-validate: ❌ ${e}\n`);
  process.exit(1);
}

if (!quiet) process.stdout.write('graph-validate: ✅ structural graph v3.0.0 valid\n');
process.exit(0);
