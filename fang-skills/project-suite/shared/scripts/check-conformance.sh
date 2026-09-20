#!/bin/bash
# Conformance Checker v1.0 — SUITE_SPEC G1-G17 automated verification
# Usage: bash shared/scripts/check-conformance.sh
# Exit code: 0 = all pass, 1 = warnings found, 2 = errors found

set -euo pipefail
SUITE_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILLS_DIR="$SUITE_ROOT/skills"
ERRORS=0
WARNINGS=0

red() { echo -e "\033[31m$1\033[0m"; }
yellow() { echo -e "\033[33m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }

echo "========================================"
echo " Conformance Checker v1.0"
echo " Target: $SKILLS_DIR"
echo "========================================"
echo ""

for skill_dir in "$SKILLS_DIR"/*/; do
  skill=$(basename "$skill_dir")
  echo "--- $skill ---"

  # G1: SKILL.md exists and ≤130 lines
  if [ -f "$skill_dir/SKILL.md" ]; then
    lines=$(wc -l < "$skill_dir/SKILL.md")
    if [ "$lines" -le 130 ]; then
      green "  G1 PASS: SKILL.md ${lines}行 ≤130"
    else
      yellow "  G1 WARN: SKILL.md ${lines}行 >130"
      WARNINGS=$((WARNINGS+1))
    fi
  else
    red "  G1 FAIL: SKILL.md missing"
    ERRORS=$((ERRORS+1))
  fi

  # G2: skill.yaml exists and has required fields
  if [ -f "$skill_dir/skill.yaml" ]; then
    required_fields=("id:" "version:" "mode:" "owner:" "produces:" "consumes:" "boundary:")
    missing_fields=()
    for field in "${required_fields[@]}"; do
      if ! grep -q "$field" "$skill_dir/skill.yaml"; then
        missing_fields+=("$field")
      fi
    done
    if [ ${#missing_fields[@]} -eq 0 ]; then
      green "  G2 PASS: skill.yaml fields complete"
    else
      yellow "  G2 WARN: skill.yaml missing: ${missing_fields[*]}"
      WARNINGS=$((WARNINGS+1))
    fi
  else
    red "  G2 FAIL: skill.yaml missing"
    ERRORS=$((ERRORS+1))
  fi

  # G3: boundary.md 反例表格行数（| N | 开头）+ SKILL.md 的禁止行 ≥3
  anti_count=0
  if [ -f "$skill_dir/references/boundary.md" ]; then
    anti_count=$(grep -cE "^\| [0-9]+ \|" "$skill_dir/references/boundary.md" 2>/dev/null || true)
  fi
  skill_anti=0
  if [ -f "$skill_dir/SKILL.md" ]; then
    skill_anti=$(grep -c "禁止:" "$skill_dir/SKILL.md" 2>/dev/null || true)
  fi
  total_anti=$((anti_count + skill_anti))
  if [ "$total_anti" -ge 3 ]; then
    green "  G3 PASS: ${total_anti} anti-patterns (boundary:${anti_count} + SKILL:${skill_anti}) ≥3"
  else
    # Check for waiver
    # ⚠️ 原判定 `grep -q "waivers:" && grep -q "G3"` 近乎恒真：每个 skill.yaml 都有 `waivers:` 键
    #    （哪怕是空列表 `waivers: []`），且文件里**任何位置**出现 "G3"（注释、TODO、别处说明）都算数。
    #    实测：`# TODO(G3): anti-patterns pending` + `waivers: []` → 直接输出
    #    「✅ G3 WAIVED: 0 anti-patterns, waiver active (no expiry)」（2026-09-18 修）。
    #    现在必须有 **G3 的豁免条目**（`gate: G3`）才认。
    if grep -q "gate: G3" "$skill_dir/skill.yaml" 2>/dev/null; then
      # Extract expires date from inline waiver: { gate: G3, reason: "...", expires: "YYYY-MM-DD", ... }
      expires=$(grep "gate: G3" "$skill_dir/skill.yaml" 2>/dev/null | grep -o 'expires: "[^"]*"' | grep -o '"[^"]*"' | tr -d '"' || echo "")
      if [ -n "$expires" ]; then
        # 原实现只有 BSD 的 `date -j`（darwin 专有）。非 darwin 上解析必失败 → 空值在
        # `[ "$now" -lt "$expires_epoch" ]` 里被当 0 → **有效豁免一律被报成「已过期」**。
        # 这里补 GNU `date -d` 回退，并把「解析不出来」明确判为无法确认（不计作有效豁免）。
        expires_epoch=$(date -j -f "%Y-%m-%d" "$expires" +%s 2>/dev/null || date -d "$expires" +%s 2>/dev/null || true)
        now_epoch=$(date +%s)
        if [ -z "$expires_epoch" ]; then
          yellow "  G3 WAIVER 无法判定：expires='$expires' 解析失败——按未获豁免处理，only ${total_anti} anti-patterns"
          WARNINGS=$((WARNINGS+1))
        elif [ "$now_epoch" -lt "$expires_epoch" ]; then
          green "  G3 WAIVED: only ${total_anti} anti-patterns, waiver active until $expires"
        else
          yellow "  G3 WAIVER EXPIRED: expired $expires, only ${total_anti} anti-patterns"
          WARNINGS=$((WARNINGS+1))
        fi
      else
        green "  G3 WAIVED: ${total_anti} anti-patterns, waiver active (no expiry)"
      fi
    else
      yellow "  G3 WARN: only ${total_anti} anti-patterns, need ≥3"
      WARNINGS=$((WARNINGS+1))
    fi
  fi

  # G4: At least 1 CHECKPOINT
  cps=0
  if [ -f "$skill_dir/SKILL.md" ]; then
    cps=$(grep -c "CHECKPOINT" "$skill_dir/SKILL.md" || true)
  fi
  # Also count CHECKPOINT in prompts/
  for prompt in "$skill_dir/prompts/"*.md; do
    if [ -f "$prompt" ]; then
      pc=$(grep -c "CHECKPOINT" "$prompt" || true)
      cps=$((cps + pc))
    fi
  done
  if [ "$cps" -ge 1 ]; then
    green "  G4 PASS: ${cps} CHECKPOINT(s) found"
  else
    yellow "  G4 WARN: no CHECKPOINT found"
    WARNINGS=$((WARNINGS+1))
  fi

  # G5: 职责边界表 with ✅/❌
  # ⚠️ 原实现只 `grep -q "✅"`——注释写的是「职责边界表 with ✅/❌」，实际不查 ❌、不查是否表格、
  #    也不查表头。任何含一个 ✅ 字符的文档都算通过（2026-09-18 修）。
  if [ -f "$skill_dir/references/boundary.md" ] \
     && grep -q "✅" "$skill_dir/references/boundary.md" \
     && grep -q "❌" "$skill_dir/references/boundary.md" \
     && grep -qE '^\|[-: ]+\|' "$skill_dir/references/boundary.md"; then
    green "  G5 PASS: boundary table found（含 ✅/❌ 两列 + 表格分隔行）"
  else
    yellow "  G5 WARN: no ✅/❌ boundary table in boundary.md（需同时含 ✅、❌ 与表格分隔行）"
    WARNINGS=$((WARNINGS+1))
  fi

  # G6: frontmatter description 含触发词（discovery 面）；产出契约在 skill.yaml produces（G2 已查），不塞进 description
  desc=$(awk '/^---/{f++} f==1' "$skill_dir/SKILL.md" 2>/dev/null | sed -n '/description:/,$p' | tr '\n' ' ')
  if echo "$desc" | grep -q "触发词\|trigger"; then
    green "  G6 PASS: description has trigger words"
  else
    yellow "  G6 WARN: description missing trigger words"
    WARNINGS=$((WARNINGS+1))
  fi

  # G7: registered in skills.generated.yaml（per-skill 唯一派生源）
  if grep -qE "^  ${skill}:" "$SUITE_ROOT/runtime/registry/skills.generated.yaml" 2>/dev/null; then
    green "  G7 PASS: registered in skills.generated.yaml"
  else
    yellow "  G7 WARN: not found in skills.generated.yaml"
    WARNINGS=$((WARNINGS+1))
  fi

  # G8: 完成后 next-step hint
  if grep -q "完成后" "$skill_dir/SKILL.md"; then
    green "  G8 PASS: next-step hint found"
  else
    yellow "  G8 WARN: no next-step hint"
    WARNINGS=$((WARNINGS+1))
  fi

  # G9: 失败处理在 boundary.md
  if grep -q "失败兜底" "$skill_dir/references/boundary.md" 2>/dev/null; then
    green "  G9 PASS: failure handling in boundary.md"
  else
    yellow "  G9 WARN: failure handling missing"
    WARNINGS=$((WARNINGS+1))
  fi

  # G10: 无 runtime-specific 措辞
  if grep -qE "在 Claude Code|Claude Code skill|Cursor only" "$skill_dir/SKILL.md" 2>/dev/null; then
    yellow "  G10 WARN: runtime-specific wording found in SKILL.md"
    WARNINGS=$((WARNINGS+1))
  else
    green "  G10 PASS: runtime-neutral"
  fi

  # G11: prompts/ 至少 1 个文件
  # ⚠️ `|| true` 不可省：`set -euo pipefail` 下，目录不存在时 find 返回非 0 → 整条管道失败
  #    → 脚本**静默中止**，后续所有门禁与 Summary 都不执行，而退出码 1 与「查出 warnings」不可区分。
  #    实测（2026-09-18）：删掉某个 skill.yaml 的 stages 行即可复现同样的中途死亡。
  prompt_count=$(find "$skill_dir/prompts" -name "*.md" 2>/dev/null | wc -l | tr -d ' ' || true); prompt_count=${prompt_count:-0}
  if [ "$prompt_count" -ge 1 ]; then
    green "  G11 PASS: prompts/ has ${prompt_count} file(s)"
  else
    yellow "  G11 WARN: prompts/ empty"
    WARNINGS=$((WARNINGS+1))
  fi

  # G12: references/ 至少 2 个文件
  ref_count=$(find "$skill_dir/references" -name "*.md" 2>/dev/null | wc -l | tr -d ' ' || true); ref_count=${ref_count:-0}
  if [ "$ref_count" -ge 2 ]; then
    green "  G12 PASS: references/ has ${ref_count} file(s)"
  else
    yellow "  G12 WARN: references/ has <2 files"
    WARNINGS=$((WARNINGS+1))
  fi

  # G13: Stage prompts exist for each declared stage
  stages=$(grep "stages:" "$skill_dir/skill.yaml" 2>/dev/null | grep -o '\[.*\]' | tr -d '[]' | tr ',' '\n' | tr -d ' ' | sed 's/^ *//' || true)
  stage_count=0
  missing_stages=()
  for stage in $stages; do
    if [ -f "$skill_dir/prompts/$stage.md" ]; then
      stage_count=$((stage_count+1))
    else
      missing_stages+=("$stage")
    fi
  done
  # ⚠️ 空集保护（2026-09-18）：stages 解析不到时，下面循环 0 次 → missing_stages 为空 →
  #    原实现会打印「✅ G13 PASS: 0/0 stage prompts exist」——**永真的空集判定**。
  #    「没有 stages 可查」与「所有 stages 都齐」必须区分。
  if [ -z "$stages" ]; then
    yellow "  G13 WARN: 读不到 stages 声明（skill.yaml 缺 stages 或格式不符）——**无法判定**，不是「全部存在」"
    WARNINGS=$((WARNINGS+1))
  elif [ ${#missing_stages[@]} -eq 0 ]; then
    green "  G13 PASS: ${stage_count}/${stage_count} stage prompts exist"
  else
    yellow "  G13 WARN: missing prompts: ${missing_stages[*]}"
    WARNINGS=$((WARNINGS+1))
  fi

  # G14: @template declarations in stage prompts
  template_count=0
  for prompt in "$skill_dir/prompts/"*.md; do
    if [ -f "$prompt" ]; then
      pc=$(grep -c "@template:" "$prompt" || true)
      template_count=$((template_count + pc))
    fi
  done
  # ⚠️ 同上：stage_count=0 时 `template_count >= 0` 恒真 → 永真 PASS。另注：本门禁比的是
  #    **prompts/ 全目录的 @template 总数** vs 阶段数（弱代理），不是「每个 stage prompt 各有 @template」——
  #    文案已如实写「in prompts」，但不要据此认为逐阶段都覆盖了。
  if [ "$stage_count" -eq 0 ]; then
    yellow "  G14 WARN: 无已声明的 stage（见 G13）——**无法判定**，不是「全部覆盖」"
    WARNINGS=$((WARNINGS+1))
  elif [ "$template_count" -ge "$stage_count" ]; then
    green "  G14 PASS: ${template_count} @template declarations in prompts（全目录总数 ≥ ${stage_count} 个阶段；非逐阶段核对）"
  else
    yellow "  G14 WARN: only ${template_count}/${stage_count} stages have @template"
    WARNINGS=$((WARNINGS+1))
  fi

  # G15: skill-policy.yaml 含 rollback
  if grep -q "rollback:" "$SUITE_ROOT/runtime/config/skill-policy.yaml"; then
    green "  G15 PASS: skill-policy.yaml has rollback"
  else
    yellow "  G15 WARN: skill-policy.yaml missing rollback"
    WARNINGS=$((WARNINGS+1))
  fi

  # G16: Skill Atlas 条目完整
  if grep -q "$skill" "$SUITE_ROOT/docs/skill-atlas.md" 2>/dev/null; then
    green "  G16 PASS: in skill-atlas.md"
  else
    yellow "  G16 WARN: not in skill-atlas.md"
    WARNINGS=$((WARNINGS+1))
  fi

  # G19: Verification Reachability —— 验证子流程在 Host 的真实执行路径上可达
  #      契约见 workflow-protocol/SKILL.md 的「Verification Contract」。
  #      补于 2026-09-18：此前 8 个 skill 的 prompts/verifier.md 运行时**永不被加载**
  #      （SKILL.md 写了 Verify 阶段行，但 stages 里没有 verify、stage-templates 也没有 verify.md）。
  #
  #      ⚠️ 本门禁是 **grep 级**：只认 markdown 链接形态 `[verifier.md](verifier.md)`——
  #         裸提及（说明文字里的 `verifier.md`）不算，否则一句散文就能骗过它（实测过）。
  #         即便收紧，它仍只能证明「有引用」，不能证明「真跑了验证」。
  #         真正证明可达的是 E2E 的行为 fixture（check-e2e-smoke.sh），本门禁不替代它。
  vmode=$(grep -oE 'verification: *\{ *mode: *[a-z-]+' "$skill_dir/skill.yaml" 2>/dev/null | grep -oE '[a-z-]+$' || true)
  vfile="$skill_dir/prompts/verifier.md"
  case "$vmode" in
    direct-verify)
      if [ ! -f "$vfile" ]; then
        yellow "  G19 WARN: mode=direct-verify 但缺 prompts/verifier.md"
        WARNINGS=$((WARNINGS+1))
      elif ! grep -q "\]\([^)]*verifier\.md\)" "$skill_dir/prompts/validation.md" 2>/dev/null; then
        yellow "  G19 WARN: mode=direct-verify 但 validation.md 未加载 verifier.md（运行时不可达）"
        WARNINGS=$((WARNINGS+1))
      else
        green "  G19 PASS: direct-verify → validation.md 加载 verifier.md"
      fi
      ;;
    candidate-verify-accept)
      if [ ! -f "$vfile" ]; then
        yellow "  G19 WARN: mode=candidate-verify-accept 但缺 prompts/verifier.md"
        WARNINGS=$((WARNINGS+1))
      elif ! grep -q "\]\([^)]*verifier\.md\)" "$skill_dir/prompts/execution.md" 2>/dev/null; then
        yellow "  G19 WARN: mode=candidate-verify-accept 但 execution.md 未加载 verifier.md（运行时不可达）"
        WARNINGS=$((WARNINGS+1))
      else
        green "  G19 PASS: candidate-verify-accept → execution.md 加载 verifier.md"
      fi
      ;;
    none)
      green "  G19 PASS: mode=none（不要求 verifier.md）"
      ;;
    "")
      yellow "  G19 WARN: skill.yaml 未声明 verification.mode（取值只能 direct-verify / candidate-verify-accept / none）"
      WARNINGS=$((WARNINGS+1))
      ;;
    *)
      yellow "  G19 WARN: 未知 verification.mode='$vmode'（取值只能 direct-verify / candidate-verify-accept / none）"
      WARNINGS=$((WARNINGS+1))
      ;;
  esac

  echo ""
done

# ═══ G17: Review Cadence (cross-skill check) ═══
echo "--- review-cadence ---"
current_date=$(date +%s)
for skill_dir in "$SKILLS_DIR"/*/; do
  skill=$(basename "$skill_dir")
  yaml_file="$skill_dir/skill.yaml"
  if [ -f "$yaml_file" ]; then
    last_reviewed=$(grep "last_reviewed:" "$yaml_file" | sed 's/.*"\(.*\)".*/\1/' || echo "")
    cadence_days=$(grep "review_cadence_days:" "$yaml_file" | grep -o '[0-9]*' || echo "90")
    if [ -n "$last_reviewed" ]; then
      # Convert to epoch on macOS
      if [[ "$OSTYPE" == "darwin"* ]]; then
        review_epoch=$(date -j -f "%Y-%m-%d" "$last_reviewed" +%s 2>/dev/null || true)
      else
        review_epoch=$(date -d "$last_reviewed" +%s 2>/dev/null || true)
      fi
      days_since=$(( (current_date - review_epoch) / 86400 ))
      if [ "$days_since" -gt "$cadence_days" ]; then
        yellow "  G17 WARN: $skill last reviewed ${days_since}d ago (cadence: ${cadence_days}d)"
        WARNINGS=$((WARNINGS+1))
      else
        green "  G17 PASS: $skill reviewed ${days_since}d ago ≤ ${cadence_days}d"
      fi
    else
      yellow "  G17 WARN: $skill missing last_reviewed field"
      WARNINGS=$((WARNINGS+1))
    fi
  fi
done

# ═══ G18: Scheduler Contract (cross-skill check) ═══
echo "--- scheduler-contract ---"
scheduler_file="$SUITE_ROOT/runtime/config/scheduler.yaml"
if [ -f "$scheduler_file" ]; then
  # G18a: 每个 skill 有 scheduler entry
  missing_sched=()
  for skill_dir in "$SKILLS_DIR"/*/; do
    skill=$(basename "$skill_dir")
    if ! grep -qE "^  ${skill}:" "$scheduler_file"; then
      missing_sched+=("$skill")
    fi
  done
  if [ ${#missing_sched[@]} -eq 0 ]; then
    green "  G18a PASS: all skills have scheduler entry"
  else
    yellow "  G18a WARN: missing scheduler entry: ${missing_sched[*]}"
    WARNINGS=$((WARNINGS+1))
  fi

  # G18b: priority 唯一
  priority_dupes=$(grep -oE "priority: [0-9]+" "$scheduler_file" 2>/dev/null | grep -oE "[0-9]+" | sort | uniq -d || true)
  if [ -z "$priority_dupes" ]; then
    green "  G18b PASS: priority values unique"
  else
    yellow "  G18b WARN: duplicate priority: $priority_dupes"
    WARNINGS=$((WARNINGS+1))
  fi

  # G18c: decision_order 唯一
  order_dupes=$(grep -oE "decision_order: [0-9]+" "$scheduler_file" 2>/dev/null | grep -oE "[0-9]+" | sort | uniq -d || true)
  if [ -z "$order_dupes" ]; then
    green "  G18c PASS: decision_order values unique"
  else
    yellow "  G18c WARN: duplicate decision_order: $order_dupes"
    WARNINGS=$((WARNINGS+1))
  fi
else
  red "  G18 FAIL: scheduler.yaml missing"
  ERRORS=$((ERRORS+1))
fi

echo ""

# ── G21: Stage Registry Contract（stage 声明的注册闭合）──────────────────
# stage-library.yaml 头部声明「Host 据此验证 Skill 声明的 stages 是否合法」——
# 本门禁把这条声明接到一个真实消费者上：Skill 声明的 stage 必须已在库里注册。
# 真实缺口（2026-09-20 发现）：pipeline-orchestrator 声明 stages [discovery, orchestrate, validation, delivery]，
# 而库里只有 6 个 stage、**没有 orchestrate** —— 声明合法却无库可依。
echo "========================================"
echo " G21 Stage Registry Contract（stage 注册闭合）"
echo "========================================"
if node -e '
  const fs=require("fs"),path=require("path");
  const root=path.resolve(process.argv[1]);
  const lib=fs.readFileSync(process.argv[2],"utf8");
  const keyRe=/^  ([a-z][a-z0-9-]*):[ ]*$/gm;
  const stagesPart=lib.split(/^contracts:/m)[0]||"";
  const contractsPart=lib.split(/^contracts:/m)[1]||"";
  const declared=new Set([...stagesPart.matchAll(keyRe)].map(m=>m[1]));
  const contracted=new Set([...contractsPart.matchAll(keyRe)].map(m=>m[1]));
  const errs=[];
  // 退化保护：解析失败时不能静默通过
  if(!declared.size) errs.push("stage-library.yaml 未解析出任何 stage —— 断言退化，契约或缩进已变");
  if(!contracted.size) errs.push("stage-library.yaml 未解析出任何 contract —— 断言退化");
  for(const name of fs.readdirSync(root)){
    const dir=path.join(root,name);
    if(!fs.statSync(dir).isDirectory()) continue;
    const ymlP=path.join(dir,"skill.yaml");
    if(!fs.existsSync(ymlP)) continue;
    const yml=fs.readFileSync(ymlP,"utf8");
    const m=yml.match(/stages:\s*\[([^\]]*)\]/);
    if(!m) continue;
    for(const s of m[1].split(",").map(x=>x.trim()).filter(Boolean))
      if(!declared.has(s)) errs.push(name+" 声明 stage=" + s + "，但 stage-library.yaml 未注册该 stage");
  }
  for(const s of declared) if(!contracted.has(s))
    errs.push("stage=" + s + " 在 stages: 里注册，但 contracts: 里没有对应 I/O 契约");
  for(const e of errs) console.log("    - " + e);
  process.exit(errs.length?1:0);
' "$SKILLS_DIR" "$SUITE_ROOT/runtime/registry/stage-library.yaml" 2>&1; then
  green "  G21 PASS: 所有 skill 声明的 stage 均已注册，且每个 stage 都有 I/O 契约"
else
  red "  G21 FAIL: stage 声明与 stage-library.yaml 不一致（见上）"
  ERRORS=$((ERRORS+1))
fi

echo ""

# ── G20: Prompt Reachability（SUITE_SPEC §0.1 的机器强制）──────────────
# 原则：「任何声明存在的行为，都必须能沿 Host 的真实执行路径找到入口」。
# 本门禁是它的**通用形式**——G19 只查 verifier 这一个特例，G20 查**全部** prompts/*.md：
# 每个提示词必须能沿「SKILL.md / 默认 Prompt(main.md) / stage prompts」的引用链传递可达。
# 只被静态工具提到、或完全没人引用的提示词 = 写了但永远不会被加载。
#
# ⚠️ 入口集合依据 SUITE_SPEC.md §1 的目录契约：`main.md` 是「默认 Prompt」。
echo "========================================"
echo " G20 Prompt Reachability（提示词可达性）"
echo "========================================"
if node -e '
  const fs=require("fs"),path=require("path");
  const root=path.resolve(process.argv[1]);
  let any=false;
  for(const name of fs.readdirSync(root)){
    const dir=path.join(root,name);
    if(!fs.statSync(dir).isDirectory()) continue;
    const ymlP=path.join(dir,"skill.yaml");
    if(!fs.existsSync(ymlP)) continue;
    const yml=fs.readFileSync(ymlP,"utf8");
    const stages=((yml.match(/stages:\s*\[([^\]]*)\]/)||[])[1]||"").split(",").map(s=>s.trim()).filter(Boolean);
    const pdir=path.join(dir,"prompts");
    if(!fs.existsSync(pdir)) continue;
    const all=fs.readdirSync(pdir).filter(f=>f.endsWith(".md"));
    // 入口：SKILL.md + 默认 Prompt main.md + 各 stage prompt
    const seeds=[path.join(dir,"SKILL.md"),path.join(pdir,"main.md"),
                 ...stages.map(s=>path.join(pdir,s+".md"))].filter(f=>fs.existsSync(f)).map(f=>path.resolve(f));
    const seen=new Set(), stack=[...seeds];
    const links=f=>{ try{ return [...fs.readFileSync(f,"utf8").matchAll(/\]\(([^)#]+\.md)\)/g)]
                       .map(m=>path.resolve(path.dirname(f),m[1])); }catch{return[]} };
    while(stack.length){ const f=stack.pop(); if(seen.has(f)) continue; seen.add(f);
      for(const l of links(f)) if(!seen.has(l)) stack.push(l); }
    const orphans=all.map(f=>path.resolve(pdir,f)).filter(f=>!seen.has(f));
    if(orphans.length){ any=true; console.log("  " + name + ": " + orphans.map(o=>path.basename(o)).join(", ")); }
  }
  process.exit(any?1:0);
' "$SKILLS_DIR" 2>&1; then
  green "  G20 PASS: 所有 prompts/*.md 均可沿引用链传递可达"
else
  yellow "  G20 WARN: 存在不可达的提示词（写了但永远不会被加载，见上）"
  WARNINGS=$((WARNINGS+1))
fi

echo ""

# ── 声明链一致性检查（skill.yaml → skill-ir → registry → compatibility → benchmarks）──
# 任何一层不一致 → 报错。实际行为层（L5）排除，需 benchmark 手动验证。
echo "========================================"
echo " 声明链一致性（check-consistency.sh）"
echo "========================================"
if [ -f "$SUITE_ROOT/shared/scripts/check-consistency.sh" ]; then
  if bash "$SUITE_ROOT/shared/scripts/check-consistency.sh"; then
    green "  ✅ 声明链一致性通过"
  else
    red "  ❌ 声明链不一致（skill.yaml/skill-ir/registry/compatibility/benchmarks 某层漂移）"
    ERRORS=$((ERRORS+1))
  fi
else
  yellow "  ⚠️  check-consistency.sh 缺失，跳过一致性检查"
fi

echo ""

echo "========================================"
echo " Summary"
echo "========================================"
echo " Errors:   $ERRORS"
echo " Warnings: $WARNINGS"
echo ""

if [ "$ERRORS" -gt 0 ]; then
  red "❌ CONFORMANCE FAILED — $ERRORS error(s) must be fixed"
  exit 2
elif [ "$WARNINGS" -gt 0 ]; then
  yellow "⚠️  CONFORMANCE WARNING — $WARNINGS warning(s), review recommended"
  exit 1
else
  green "✅ CONFORMANCE PASSED — all gates green"
  exit 0
fi
