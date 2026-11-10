#!/usr/bin/env node
/**
 * Transcript Audit v1.0
 *
 * 统计一个 Claude Code transcript（JSONL）里**真实执行**了哪些 suite 脚本。
 *
 * 为什么需要：用 grep 在 transcript 里数「timeline-append」会得到上百行——
 * skill 正文、grep 参数、Read 的路径、甚至是模型的解释文字都会命中。
 * 实测一次运行「出现 100 行、真实调用 0 次」。审计必须以
 * `message.content[].type == "tool_use"` 且 `name == "Bash"` 的 `input.command` 为准。
 *
 * Usage:
 *   node audit-transcript.mjs <transcript.jsonl> [--json] [--script <name>]...
 *   node audit-transcript.mjs --self-test
 *
 * Exit: 0 = ok；2 = 参数/读取错误；1 = self-test 失败
 */
'use strict';

import fs from 'node:fs';

const DEFAULT_SCRIPTS = [
  'task-registry.sh',
  'writer-lock.sh',
  'timeline-append.sh',
  'timeline-stats.mjs',
  'runtime-run.sh',
  'collect-metrics.sh',
  'knowledge-compiler.sh',
  'knowledge-resolver.sh',
  'check-kb-contract.sh',
  'check-claude-md.sh',
  'analysis-config-merge.mjs',
];

const INTERPRETERS = new Set(['bash', 'sh', 'zsh', 'node', 'npx', 'env']);

/**
 * 从一条 Bash command 中提取真实被调用的脚本名。
 * 只认「解释器 + 脚本路径」或命令开头的脚本，避免 echo/grep/注释里的字符串。
 */
export function scriptsInCommand(command) {
  const found = [];
  if (typeof command !== 'string' || !command.trim()) return found;
  // 去掉 heredoc 正文：`<<'EOF' ... EOF` 里可能写脚本名做说明
  const withoutHeredoc = command.replace(/<<-?\s*['"]?([A-Za-z_][A-Za-z0-9_]*)['"]?[\s\S]*?(?:\n\1|\n?$)/g, ' ');
  for (const rawLine of withoutHeredoc.split(/\n|;|&&|\|\|/)) {
    const line = rawLine.trim().replace(/^\(+/, '').replace(/\)+$/, '');
    if (!line) continue;
    const tokens = line.split(/\s+/);
    // 命令前可能有 `PROJECT=... cmd` 之类的环境变量赋值
    let i = 0;
    while (i < tokens.length && /^[A-Za-z_][A-Za-z0-9_]*=/.test(tokens[i])) i += 1;
    if (i >= tokens.length) continue;
    let cmd = tokens[i];
    if (cmd === 'sudo') { i += 1; cmd = tokens[i]; }
    if (!INTERPRETERS.has(cmd.split('/').pop())) continue;
    // 解释器后面的第一个「像脚本」的参数
    for (let j = i + 1; j < tokens.length; j += 1) {
      const tok = tokens[j].replace(/^['"]|['"]$/g, '');
      if (/\.(sh|mjs|js)$/.test(tok)) {
        found.push(tok.split('/').pop());
        break;
      }
      // --flag 跳过；遇到非脚本参数就停止（避免把 `node -e "...x.sh..."` 计进去）
      if (tok.startsWith('-')) {
        if (tok === '-e' || tok === '--eval') break;
        continue;
      }
      break;
    }
    // 直接以脚本开头（`./shared/scripts/x.sh` / `x.sh`）且可执行
    if (/^(?:\.{0,2}\/)?\S*\.(sh|mjs|js)$/.test(cmd)) {
      found.push(cmd.split('/').pop());
    }
  }
  return found;
}

/** 遍历 transcript 行，收集所有真实 tool_use。 */
export function auditLines(lines) {
  const counts = Object.fromEntries(DEFAULT_SCRIPTS.map((s) => [s, 0]));
  const reads = Object.create(null);
  let bashCalls = 0;
  let proseMentions = 0;

  for (const line of lines) {
    if (!line.trim()) continue;
    let row;
    try { row = JSON.parse(line); } catch (_) { continue; }
    const content = row && row.message && Array.isArray(row.message.content) ? row.message.content : [];
    for (const block of content) {
      if (!block || block.type !== 'tool_use') continue;
      const name = block.name;
      const input = block.input || {};
      if (name === 'Bash') {
        bashCalls += 1;
        for (const script of scriptsInCommand(input.command)) {
          if (counts[script] === undefined) counts[script] = 0;
          counts[script] += 1;
        }
      } else if (name === 'Read') {
        const p = String(input.file_path || '');
        for (const s of Object.keys(counts)) if (p.includes(s)) reads[s] = (reads[s] || 0) + 1;
      } else if (name === 'Grep' || name === 'Glob') {
        const p = String(input.pattern || '') + ' ' + String(input.path || '');
        for (const s of Object.keys(counts)) if (p.includes(s)) proseMentions += 1;
      }
    }
  }
  return { counts, reads, bashCalls, proseMentions };
}

function selfTest() {
  const fixture = [
    JSON.stringify({ type: 'assistant', message: { content: [{ type: 'text', text: '运行 bash shared/scripts/timeline-append.sh 即可' }] } }),
    JSON.stringify({ type: 'assistant', message: { content: [{ type: 'tool_use', name: 'Read', input: { file_path: '/x/timeline-append.sh' } }] } }),
    JSON.stringify({ type: 'assistant', message: { content: [{ type: 'tool_use', name: 'Grep', input: { pattern: 'timeline-append.sh', path: '/x' } }] } }),
    JSON.stringify({ type: 'assistant', message: { content: [{ type: 'tool_use', name: 'Bash', input: { command: 'bash "$KIT/shared/scripts/timeline-append.sh" "$P" - <<\'EOF\'\n{"a":1}\nEOF' } }] } }),
    JSON.stringify({ type: 'assistant', message: { content: [{ type: 'tool_use', name: 'Bash', input: { command: 'PROJECT=/p bash /suite/shared/scripts/task-registry.sh create "x" --dir /p/.project-knowledge && echo timeline-append.sh' } }] } }),
    JSON.stringify({ type: 'assistant', message: { content: [{ type: 'tool_use', name: 'Bash', input: { command: 'node -e "console.log(\'timeline-stats.mjs\')"' } }] } }),
  ];
  const r = auditLines(fixture);
  const checks = [
    ['真实 bash 调用计数', r.counts['timeline-append.sh'], 1],
    ['env 前缀仍识别', r.counts['task-registry.sh'], 1],
    ['Read 路径不计入执行', r.counts['timeline-append.sh'], 1],
    ['grep/echo 不计入执行', r.counts['timeline-stats.mjs'], 0],
    ['Read 次数单独统计', r.reads['timeline-append.sh'], 1],
    ['Bash 调用总数', r.bashCalls, 3],
  ];
  let failed = 0;
  for (const [label, got, want] of checks) {
    if (got === want) {
      process.stdout.write(`  ✅ ${label} = ${got}\n`);
    } else {
      failed += 1;
      process.stdout.write(`  ❌ ${label}: expected ${want}, got ${got}\n`);
    }
  }
  process.stdout.write(failed === 0 ? 'AUDIT SELF-TEST: PASS\n' : `AUDIT SELF-TEST: FAIL (${failed})\n`);
  process.exit(failed === 0 ? 0 : 1);
}

function main() {
  const args = process.argv.slice(2);
  if (args.includes('--self-test')) return selfTest();

  const json = args.includes('--json');
  const scripts = [];
  let file = '';
  for (let i = 0; i < args.length; i += 1) {
    if (args[i] === '--json') continue;
    if (args[i] === '--script') { if (args[i + 1]) scripts.push(args[++i]); continue; }
    if (!file) file = args[i];
  }
  if (!file) {
    process.stderr.write('usage: node audit-transcript.mjs <transcript.jsonl> [--json] [--script <name>]\n');
    process.exit(2);
  }

  let text;
  try {
    text = fs.readFileSync(file, 'utf8');
  } catch (e) {
    process.stderr.write(`audit-transcript: 读取失败: ${e.message}\n`);
    process.exit(2);
  }

  const r = auditLines(text.split('\n'));
  const wanted = scripts.length ? scripts : DEFAULT_SCRIPTS;
  if (json) {
    const out = {};
    for (const s of wanted) out[s] = r.counts[s] || 0;
    process.stdout.write(JSON.stringify({ bashCalls: r.bashCalls, counts: out, reads: r.reads }, null, 2) + '\n');
    return;
  }
  for (const s of wanted) {
    const c = r.counts[s] || 0;
    const rd = r.reads[s] || 0;
    process.stdout.write(`${s}\texecuted=${c}\tread=${rd}\n`);
  }
  process.stdout.write(`BASH_CALLS=${r.bashCalls}\n`);
}

main();
