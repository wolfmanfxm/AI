#!/usr/bin/env node
/**
 * Knowledge Directory Contract → shell fragment
 *
 * 源（SSOT）: shared/schemas/knowledge-directories.yaml
 * 产出      : shared/scripts/knowledge-directories.generated.sh
 *
 * 为什么生成而不是让 bash 直接读 YAML：knowledge-compiler.sh 是 bash，Suite 保持零依赖
 * （见 trigger-eval.mjs 的 "zero dependencies, built-in modules only"）。沿用本仓库既有做法
 * （skills.generated.yaml 由 generate-registry.mjs 用 regex 解析 skill.yaml 生成），
 * 这里同样用 regex 解析契约并生成 shell 变量，编译器 source 即可。
 *
 * Usage:
 *   node shared/scripts/generate-knowledge-dirs.mjs           # 生成
 *   node shared/scripts/generate-knowledge-dirs.mjs --check   # 只校验是否与契约同步（漂移检测）
 */

import { readFileSync, writeFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const SUITE_ROOT = join(__dirname, '..', '..');
const SRC = join(SUITE_ROOT, 'shared', 'schemas', 'knowledge-directories.yaml');
const OUT = join(__dirname, 'knowledge-directories.generated.sh');

function parseContract(text) {
  const dirs = [];
  let cur = null;
  for (const line of text.split('\n')) {
    const mName = line.match(/^  ([a-z][a-z-]*):\s*$/);
    if (mName) { cur = { name: mName[1] }; dirs.push(cur); continue; }
    if (!cur) continue;
    const mKV = line.match(/^    ([a-z_]+):\s*(.*?)\s*$/);
    if (!mKV) continue;
    const key = mKV[1];
    // 剥掉行内注释（`value  # 说明`）——否则布尔/枚举值会被整串比对而误判
    const raw = mKV[2].replace(/\s+#.*$/, '').trim();
    if (key === 'required_frontmatter' || key === 'compiler_enforced') {
      cur[key] = (raw.match(/\[(.*)\]/)?.[1] || '')
        .split(',').map(s => s.trim()).filter(Boolean);
    } else if (key === 'indexed_by_compiler' || key === 'human_readable') {
      cur[key] = raw === 'true';
    } else {
      cur[key] = raw.replace(/^["']|["']$/g, '');
    }
  }
  // 只保留有 path 的条目（排除顶层 version 等）
  return dirs.filter(d => d.path);
}

function render(dirs, version) {
  const indexed  = dirs.filter(d => d.indexed_by_compiler).map(d => d.name);
  // 产出者**不做二值切分**（analyzer/human）：planner/reviewer 等两者都不是，硬切会迫使其被误标。
  // 原样带出 dir:producer（多产出者逗号分隔），与 KD_REQUIRED/KD_ENFORCED 同为 dir:值 形状。
  const byProducer = dirs.map(d => `${d.name}:${d.producer.split(',').map(s => s.trim()).join(',')}`);
  const dead     = dirs.filter(d => !d.indexed_by_compiler && !d.human_readable).map(d => d.name);
  // 注意键名与 parseContract 里 cur[key] 的 key 一致：required_frontmatter / compiler_enforced
  const required = dirs.filter(d => d.required_frontmatter && d.required_frontmatter.length)
                       .flatMap(d => d.required_frontmatter.map(f => `${d.name}:${f}`));
  const enforced = dirs.filter(d => d.compiler_enforced && d.compiler_enforced.length)
                       .flatMap(d => d.compiler_enforced.map(f => `${d.name}:${f}`));

  return `#!/bin/sh
# 自动生成，勿手改 —— 源: shared/schemas/knowledge-directories.yaml
# 重新生成: node shared/scripts/generate-knowledge-dirs.mjs
# 契约版本: ${version}

KD_CONTRACT_VERSION="${version}"

# 进 knowledge-index 的目录（compiler 必须恰好扫这些）—— 不变量 I1
KD_INDEXED="${indexed.join(' ')}"

# 全部声明目录
KD_ALL="${dirs.map(d => d.name).join(' ')}"

# 谁产出哪个目录（格式 dir:producer，多产出者逗号分隔）—— 与 artifact-types.yaml 的 producer 同义
KD_BY_PRODUCER="${byProducer.join(' ')}"

# 死产出（既不入 index 又非人读）——不变量 I3 要求为空
KD_DEAD="${dead.join(' ')}"

# Producer **应当**写入的字段（规范），格式 dir:field（空格分隔）
KD_REQUIRED="${required.join(' ')}"

# 其中 Compiler **硬校验**的子集（缺失即拒绝生成 index）—— Producer 该写 ≠ Consumer 该拦
KD_ENFORCED="${enforced.join(' ')}"
`;
}

function main() {
  if (!existsSync(SRC)) { console.error(`❌ 契约文件不存在: ${SRC}`); process.exit(1); }
  const text = readFileSync(SRC, 'utf-8');
  const dirs = parseContract(text);
  if (!dirs.length) { console.error('❌ 未从契约解析到任何目录（格式或缩进变了？）'); process.exit(1); }

  const version = text.match(/^version:\s*"([^"]+)"/m)?.[1] || 'unknown';
  const out = render(dirs, version);

  if (process.argv.includes('--check')) {
    const current = existsSync(OUT) ? readFileSync(OUT, 'utf-8') : '';
    if (current !== out) {
      console.error('❌ knowledge-directories.generated.sh 与契约不同步（运行 node shared/scripts/generate-knowledge-dirs.mjs）');
      process.exit(1);
    }
    console.log(`✅ knowledge-directories.generated.sh 与契约同步（${dirs.length} 个目录）`);
    process.exit(0);
  }

  writeFileSync(OUT, out);
  console.log(`✅ 生成 ${dirs.length} 个目录契约 → ${OUT.replace(SUITE_ROOT + '/', '')}`);
  console.log(`   入 index: ${dirs.filter(d => d.indexed_by_compiler).length} | 人读产出: ${dirs.filter(d => d.human_readable).length}`);
}

main();
