#!/usr/bin/env python3
"""
project-analyzer 触发词准确率验证脚本

用法:
    python3 trigger_eval.py                    # 默认读取 test-prompts.json
    python3 trigger_eval.py --verbose          # 详细模式，打印每条匹配过程
    python3 trigger_eval.py --ci               # CI 模式，精简输出 + 退出码
    python3 trigger_eval.py --config custom.json  # 自定义测试用例

退出码: 0 = 全部通过, 1 = 存在失败用例
"""

from __future__ import annotations

import json
import re
import sys
import os
from pathlib import Path
from typing import NamedTuple

# ── 路径 ──────────────────────────────────────────────
SKILL_DIR = Path(__file__).resolve().parent
TRIGGER_FILE = SKILL_DIR / "references" / "trigger-words.md"
TEST_FILE = SKILL_DIR / "test-prompts.json"

# ── 数据结构 ──────────────────────────────────────────
class Pattern(NamedTuple):
    text: str
    category: str      # analysis | resume | development
    conditional: bool   # 是否带上下文条件
    condition_note: str

class TestCase(NamedTuple):
    id: int
    category: str
    prompt: str
    expected_trigger: bool  # True = 应触发, False = 不应触发

class EvalResult(NamedTuple):
    case: TestCase
    matched: bool
    matched_by: list[str]    # 命中的触发词
    excluded_by: list[str]   # 命中的排除词
    passed: bool

# ── 解析 trigger-words.md ─────────────────────────────

def parse_triggers(filepath: Path) -> tuple[list[Pattern], list[str]]:
    """解析触发词文件，返回 (触发词列表, 排除词列表)"""
    text = filepath.read_text(encoding="utf-8")

    patterns: list[Pattern] = []
    exclusions: list[str] = []

    current_category = "analysis"
    in_exclusion = False

    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue

        # 跟踪 section
        if line.startswith("## 分析模式"):
            current_category = "analysis"
            in_exclusion = False
        elif line.startswith("## 恢复触发"):
            current_category = "resume"
            in_exclusion = False
        elif line.startswith("## 开发前检查"):
            current_category = "development"
            in_exclusion = False
        elif line.startswith("### 排除"):
            in_exclusion = True
            continue
        elif line.startswith("###") or line.startswith("##"):
            in_exclusion = False
            continue

        # 跳过非列表行
        if not line.startswith("- "):
            continue

        content = line[2:]  # 去掉 "- "

        if in_exclusion:
            # 提取排除词：去掉引号和箭头后的说明
            excl = content.strip('"').strip("'")
            # "分析这个需求" → 产品/规划类 skill  → 提取前半
            excl = re.split(r"[→>]", excl)[0].strip().strip('"').strip("'")
            if excl:
                exclusions.append(excl)
            continue

        # 解析触发词
        conditional = "→" in content
        condition_note = ""
        if conditional:
            parts = content.split("→", 1)
            content = parts[0].strip()
            condition_note = parts[1].strip() if len(parts) > 1 else ""

        # 拆分 "/" 分隔的同义词组
        for token in content.split("/"):
            token = token.strip()
            if token:
                patterns.append(Pattern(token, current_category, conditional, condition_note))

    return patterns, exclusions


def load_test_cases(filepath: Path) -> list[TestCase]:
    """加载测试用例，推断 expected_trigger"""
    data = json.loads(filepath.read_text(encoding="utf-8"))
    cases = []
    for item in data:
        expected = item["category"] != "not-trigger"
        cases.append(TestCase(
            id=item["id"],
            category=item["category"],
            prompt=item["prompt"],
            expected_trigger=expected,
        ))
    return cases


# ── SKILL.md 路由关键词 ──────────────────────────────

def parse_skill_routing(filepath: Path) -> list[Pattern]:
    """从 SKILL.md 的 Quick Start 路由表中提取关键词"""
    text = filepath.read_text(encoding="utf-8")

    # 匹配路由规则: "关键词" → FlowName
    # 示例: "分析/扫描/刷新"              → Analysis Flow
    routing_re = re.compile(r'"([^"]+)"\s*→\s*(Analysis|Phase 2 Resume|Development)\s*Flow')

    patterns = []
    for m in routing_re.finditer(text):
        keywords = m.group(1)
        flow = m.group(2)
        if flow == "Analysis":
            cat = "analysis"
        elif flow == "Phase 2 Resume":
            cat = "resume"
        else:
            cat = "development"

        for kw in keywords.split("/"):
            kw = kw.strip()
            if kw and kw not in ("resume",):  # "resume" 在路由里出现但太泛
                patterns.append(Pattern(kw, cat, conditional=False, condition_note="[SKILL.md路由]"))

    return patterns


# ── 匹配引擎 ──────────────────────────────────────────

def _pattern_matches(pattern_text: str, prompt: str) -> bool:
    """判断单个触发词是否匹配 prompt。

    特殊规则：
    - "XX" 作为通配符，前缀匹配：prefix 匹配 prompt 开头即命中
      "写一个 XX" → prefix="写一个" 匹配 "写一个审批流程组件"
    - 其余做纯子串匹配
    """
    if "XX" in pattern_text:
        # 取 XX 之前的部分作为前缀，去除尾部空格
        prefix = pattern_text.split("XX")[0].rstrip()
        if not prefix:
            return True  # 纯 "XX" 匹配任意
        return prompt.startswith(prefix)
    return pattern_text in prompt


def _fuzzy_exclusion_match(exclusion: str, prompt: str) -> bool:
    """模糊排除匹配。

    策略：
    1. 精确匹配优先 — exclusion 是 prompt 子串 → 直接命中
    2. 关键词共现 — 拆出"分析"+"区分词"，两者都在 prompt 中才命中
       "分析这个 bug" → 区分词=["bug"]，prompt 需同时含 "分析"+"bug"
       "分析日志"     → 区分词=["日志"]，prompt 需同时含 "分析"+"日志"
    3. fallback — 2-gram 滑动窗口匹配（用于"代码审查""安全审查"等纯短语）
    """
    # 精确匹配优先
    if exclusion in prompt:
        return True

    # 从排除词中提取：分析类触发词 + 上下文区分词
    no_space = exclusion.replace(" ", "")
    if "分析" in no_space:
        # 去掉"分析"后剩余部分作为区分词
        remaining = no_space.replace("分析", "", 1)
        # 停用词：过于常见的中文虚词，不做区分依据
        STOP_WORDS = {"这个", "那个", "一下", "这些", "那些", "什么", "怎么", "为什么",
                      "一个", "的", "了", "是", "在", "和", "与", "或"}
        # 剩余部分按2-gram拆成关键词，过滤停用词
        context_kws = [
            remaining[i:i+2] for i in range(len(remaining) - 1)
            if remaining[i:i+2] not in STOP_WORDS
        ]
        if not context_kws and len(remaining) == 1:
            context_kws = [remaining]
        if not context_kws:
            # 无有效区分词，仅"分析"无法判断，保守放过（不排除）
            return False
        # 共现判断：分析 + 任一区分词同时在 prompt 中
        if "分析" not in prompt:
            return False
        return any(kw in prompt for kw in context_kws)

    # fallback: 复合词拆分共现匹配
    # "代码审查"(4字) → ["代码","审查"]，两词都在 prompt 中才命中
    # "安全审查"(4字) → ["安全","审查"]，同上
    if len(exclusion) == 4:
        a, b = exclusion[:2], exclusion[2:]
        return a in prompt and b in prompt
    # 其他长度：精确匹配
    return exclusion in prompt


def match_triggers(prompt: str, patterns: list[Pattern], exclusions: list[str]) -> tuple[bool, list[str], list[str]]:
    """
    对单条 prompt 执行匹配。
    返回 (是否触发, 命中的触发词列表, 命中的排除词列表)

    规则：
    1. 先检查排除词（模糊匹配）—— 命中则不触发
    2. 再检查触发词 —— 命中则触发（含 XX 通配符）
    3. 条件触发词：基础匹配 + 标注 condition
    """
    matched = []
    excluded = []

    # Step 1: 检查排除词（模糊匹配）
    for excl in exclusions:
        if _fuzzy_exclusion_match(excl, prompt):
            excluded.append(excl)

    if excluded:
        return False, matched, excluded

    # Step 2: 检查触发词
    for p in patterns:
        if _pattern_matches(p.text, prompt):
            label = p.text
            if p.conditional:
                label += f" ⚠️条件:{p.condition_note[:30]}"
            matched.append(label)

    triggered = len(matched) > 0
    return triggered, matched, excluded


# ── 评估 ──────────────────────────────────────────────

def evaluate(cases: list[TestCase], patterns: list[Pattern], exclusions: list[str]) -> list[EvalResult]:
    results = []
    for case in cases:
        triggered, matched_by, excluded_by = match_triggers(case.prompt, patterns, exclusions)
        passed = triggered == case.expected_trigger
        results.append(EvalResult(case, triggered, matched_by, excluded_by, passed))
    return results


# ── 报告 ──────────────────────────────────────────────

class Colors:
    GREEN = "\033[92m"
    RED = "\033[91m"
    YELLOW = "\033[93m"
    CYAN = "\033[96m"
    BOLD = "\033[1m"
    RESET = "\033[0m"

def color(text: str, code: str, use_color: bool = True) -> str:
    if not use_color:
        return text
    return f"{code}{text}{Colors.RESET}"

def print_report(results: list[EvalResult], patterns: list[Pattern], exclusions: list[str], verbose: bool = False, ci: bool = False):
    use_color = sys.stdout.isatty() and not ci

    total = len(results)
    passed = sum(1 for r in results if r.passed)
    failed = total - passed

    # 分类统计
    tp = sum(1 for r in results if r.case.expected_trigger and r.matched)
    fp = sum(1 for r in results if not r.case.expected_trigger and r.matched)
    tn = sum(1 for r in results if not r.case.expected_trigger and not r.matched)
    fn = sum(1 for r in results if r.case.expected_trigger and not r.matched)

    precision = tp / (tp + fp) if (tp + fp) > 0 else 0.0
    recall = tp / (tp + fn) if (tp + fn) > 0 else 0.0
    f1 = 2 * precision * recall / (precision + recall) if (precision + recall) > 0 else 0.0

    # ── 头部 ──
    if not ci:
        print()
        print(color("═══ trigger_eval · project-analyzer ═══", Colors.BOLD, use_color))
        print(f"  测试用例: {total}  触发词: {len(patterns)}  排除词: {len(exclusions)}")
        print()

    # ── 汇总 ──
    print(color("── 混淆矩阵 ──", Colors.BOLD, use_color))
    print(f"  TP(应触发✓): {tp:3d}    FP(误触发✗): {fp:3d}")
    print(f"  FN(漏触发✗): {fn:3d}    TN(正确不触发✓): {tn:3d}")
    print()

    pbar = _bar(precision)
    rbar = _bar(recall)
    fbar = _bar(f1)
    print(color("── 指标 ──", Colors.BOLD, use_color))
    print(f"  Precision: {precision:.1%} {pbar}")
    print(f"  Recall:    {recall:.1%} {rbar}")
    print(f"  F1 Score:  {f1:.1%} {fbar}")
    print()

    # ── 分类明细 ──
    by_cat: dict[str, dict] = {}
    for r in results:
        cat = r.case.category
        if cat not in by_cat:
            by_cat[cat] = {"total": 0, "passed": 0, "fn": 0, "fp": 0}
        by_cat[cat]["total"] += 1
        if r.passed:
            by_cat[cat]["passed"] += 1
        if r.case.expected_trigger and not r.matched:
            by_cat[cat]["fn"] += 1
        if not r.case.expected_trigger and r.matched:
            by_cat[cat]["fp"] += 1

    print(color("── 分类准确率 ──", Colors.BOLD, use_color))
    for cat in sorted(by_cat):
        stats = by_cat[cat]
        acc = stats["passed"] / stats["total"]
        bar = _bar(acc, width=12)
        status = color("✓", Colors.GREEN, use_color) if stats["fn"] == 0 and stats["fp"] == 0 else color("✗", Colors.RED, use_color)
        issues = ""
        if stats["fn"] > 0:
            issues += f" 漏触发×{stats['fn']}"
        if stats["fp"] > 0:
            issues += f" 误触发×{stats['fp']}"
        print(f"  {status} {cat:<18s} {acc:.0%} {bar}{issues}")
    print()

    # ── 逐条明细 ──
    if verbose or failed > 0:
        print(color("── 用例明细 ──", Colors.BOLD, use_color))
        for r in results:
            status = color("PASS", Colors.GREEN, use_color) if r.passed else color("FAIL", Colors.RED, use_color)
            expected_str = "应触发" if r.case.expected_trigger else "不应触发"
            actual_str = "触发了" if r.matched else "未触发"

            print(f"  [{status}] #{r.case.id} ({r.case.category}) {r.case.prompt}")
            print(f"         期望: {expected_str}  实际: {actual_str}")

            if r.matched_by and verbose:
                for m in r.matched_by:
                    print(f"         ↳ 命中: {color(m, Colors.CYAN, use_color)}")
            if r.excluded_by:
                for e in r.excluded_by:
                    print(f"         ↳ 排除: {color(e, Colors.YELLOW, use_color)}")
            if not r.matched_by and not r.excluded_by and r.case.expected_trigger:
                print(f"         ↳ {color('未命中任何触发词！', Colors.RED, use_color)}")
            print()

    # ── 结论 ──
    print(color("── 结论 ──", Colors.BOLD, use_color))
    if failed == 0:
        print(color("  ✓ 全部通过", Colors.GREEN, use_color))
    else:
        print(color(f"  ✗ {failed}/{total} 用例失败", Colors.RED, use_color))

        # 分类失败原因
        fn_cases = [r for r in results if r.case.expected_trigger and not r.matched]
        fp_cases = [r for r in results if not r.case.expected_trigger and r.matched]

        if fn_cases:
            print(color(f"\n  漏触发 ({len(fn_cases)} 条) — 应触发但未命中:", Colors.YELLOW, use_color))
            for r in fn_cases:
                print(f"    · #{r.case.id} \"{r.case.prompt}\"")
                print(f"      建议: 在 trigger-words.md 中添加对应触发词")

        if fp_cases:
            print(color(f"\n  误触发 ({len(fp_cases)} 条) — 不应触发但命中了:", Colors.YELLOW, use_color))
            for r in fp_cases:
                print(f"    · #{r.case.id} \"{r.case.prompt}\"")
                print(f"      命中: {', '.join(r.matched_by)}")
                print(f"      建议: 添加排除规则或细化触发词条件")

    print()
    return failed


def _bar(value: float, width: int = 16) -> str:
    """简单的 ASCII 进度条"""
    filled = int(round(value * width))
    if filled > width:
        filled = width
    blocks = "█" * filled + "░" * (width - filled)
    return f"[{blocks}]"


# ── CLI ────────────────────────────────────────────────

def main():
    verbose = "--verbose" in sys.argv or "-v" in sys.argv
    ci = "--ci" in sys.argv

    # 可选自定义配置路径
    config_path = TEST_FILE
    for i, arg in enumerate(sys.argv):
        if arg == "--config" and i + 1 < len(sys.argv):
            config_path = Path(sys.argv[i + 1])

    if not TRIGGER_FILE.exists():
        print(f"错误: 触发词文件不存在: {TRIGGER_FILE}")
        sys.exit(2)

    if not config_path.exists():
        print(f"错误: 测试用例文件不存在: {config_path}")
        sys.exit(2)

    patterns, exclusions = parse_triggers(TRIGGER_FILE)
    # 合并 SKILL.md 路由表中的关键词（它们也是实际触发入口）
    skill_md = SKILL_DIR / "SKILL.md"
    if skill_md.exists():
        routing_patterns = parse_skill_routing(skill_md)
        patterns.extend(routing_patterns)
    cases = load_test_cases(config_path)
    results = evaluate(cases, patterns, exclusions)
    failed = print_report(results, patterns, exclusions, verbose=verbose, ci=ci)

    # CI 模式输出机器可读摘要
    if ci:
        total = len(results)
        passed = total - failed
        print(f"JSON_SUMMARY: {{ \"total\": {total}, \"passed\": {passed}, \"failed\": {failed} }}")

    sys.exit(0 if failed == 0 else 1)


if __name__ == "__main__":
    main()
