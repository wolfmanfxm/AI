#!/usr/bin/env node
/**
 * Structural Graph Validator v1.0.0
 *
 * 校验 `.project-knowledge/graph.json` 是否符合 graph.schema.json v3.0.0 的**业务约束**：
 *   - schemaVersion 必须是 3.0.0（2.0.0 旧 Knowledge Objects 图默认报错）
 *   - 节点类型白名单；禁止 knowledge object 字段（statement/confidence/...）
 *   - 禁止节点 dependsOn 数组（关系只在 edges）
 *   - 节点 id 唯一；边端点必须存在；edge.relation 枚举
 *   - module.domain / 非 module.layer 的条件必填
 *
 * JSON Schema 表达不了引用完整性；本脚本是 check-e2e-smoke 与 check-graph-contract 共用的
 * **同一把尺子**，避免两处各写一份 enum。
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

const ALLOWED_NODE_TYPES = ['module', 'file', 'component', 'api', 'view', 'store', 'infrastructure'];
const ALLOWED_LAYERS = ['view', 'component', 'api', 'store', 'infrastructure'];
const ALLOWED_RELATIONS = ['imports', 'depends_on', 'uses', 'composes', 'configures'];
const ALLOWED_CAPABILITIES = ['module', 'file', 'symbol', 'call', 'reference', 'impact'];
const ALLOWED_ROOT_KEYS = ['schemaVersion', 'capabilities', 'generatedAt', 'project', 'nodes', 'edges'];
const ALLOWED_NODE_KEYS = ['id', 'type', 'label', 'group', 'layer', 'domain', 'files', 'refs', 'functions'];
const ALLOWED_EDGE_KEYS = ['from', 'to', 'relation'];
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

  // ── 根键白名单 ──────────────────────────────────────────────────────
  for (const k of Object.keys(graph)) {
    if (!ALLOWED_ROOT_KEYS.includes(k)) err(`根对象含不允许的键: ${k}`);
  }

  // ── capabilities ────────────────────────────────────────────────────
  if (!Array.isArray(graph.capabilities)) {
    err('capabilities 必须是数组');
  } else {
    for (const c of graph.capabilities) {
      if (!ALLOWED_CAPABILITIES.includes(c)) err(`capabilities 含非法值: ${JSON.stringify(c)}`);
    }
  }

  // ── nodes ───────────────────────────────────────────────────────────
  if (!Array.isArray(graph.nodes)) {
    err('nodes 必须是数组');
  } else {
    const ids = new Set();
    graph.nodes.forEach((n, i) => {
      const at = `nodes[${i}]`;
      if (!n || typeof n !== 'object' || Array.isArray(n)) {
        err(`${at} 必须是对象`);
        return;
      }
      for (const k of Object.keys(n)) {
        if (!ALLOWED_NODE_KEYS.includes(k)) {
          if (KNOWLEDGE_FIELDS.includes(k)) err(`${at} 含 Knowledge Object 字段 "${k}"（结构图不允许）`);
          else if (k === 'dependsOn') err(`${at} 含 dependsOn；关系只允许写在顶层 edges`);
          else err(`${at} 含不允许的键: ${k}`);
        }
      }
      for (const k of ['id', 'type', 'label']) {
        if (typeof n[k] !== 'string' || !n[k]) err(`${at}.${k} 必须是非空字符串`);
      }
      if (typeof n.id === 'string') {
        if (ids.has(n.id)) err(`${at}.id 重复: ${n.id}`);
        ids.add(n.id);
      }
      if (typeof n.type === 'string') {
        if (!ALLOWED_NODE_TYPES.includes(n.type)) {
          err(`${at}.type=${JSON.stringify(n.type)} 非法（允许: ${ALLOWED_NODE_TYPES.join('/')}）`);
        } else if (n.type === 'module') {
          if (typeof n.domain !== 'string' || !n.domain) err(`${at}.domain 是 module 节点必填`);
        } else if (n.type !== 'file') {
          if (typeof n.layer !== 'string' || !n.layer) err(`${at}.layer 是 ${n.type} 节点必填`);
          else if (!ALLOWED_LAYERS.includes(n.layer)) {
            err(`${at}.layer=${JSON.stringify(n.layer)} 非法（允许: ${ALLOWED_LAYERS.join('/')}）`);
          }
        }
      }
      if (n.files !== undefined) {
        if (!Array.isArray(n.files)) err(`${at}.files 必须是字符串数组`);
        else for (const f of n.files) {
          if (typeof f !== 'string' || !f) err(`${at}.files 含空/非字符串路径`);
        }
      }
      for (const k of ['refs', 'functions']) {
        if (n[k] !== undefined && (!Number.isInteger(n[k]) || n[k] < 0)) {
          err(`${at}.${k} 必须是非负整数`);
        }
      }
    });

    // ── edges ─────────────────────────────────────────────────────────
    if (!Array.isArray(graph.edges)) {
      err('edges 必须是数组');
    } else {
      graph.edges.forEach((e, i) => {
        const at = `edges[${i}]`;
        if (!e || typeof e !== 'object' || Array.isArray(e)) {
          err(`${at} 必须是对象`);
          return;
        }
        for (const k of Object.keys(e)) {
          if (!ALLOWED_EDGE_KEYS.includes(k)) err(`${at} 含不允许的键: ${k}`);
        }
        for (const k of ['from', 'to', 'relation']) {
          if (typeof e[k] !== 'string' || !e[k]) err(`${at}.${k} 必须是非空字符串`);
        }
        if (typeof e.relation === 'string' && !ALLOWED_RELATIONS.includes(e.relation)) {
          err(`${at}.relation=${JSON.stringify(e.relation)} 非法（允许: ${ALLOWED_RELATIONS.join('/')}）`);
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
