#!/bin/sh
# =============================================================================
# new-page.sh —— 按需求生成一个 CRUD 页面，并自动挂好路由
#
#   布局来自该应用里的一个**真实页面**（样板页），业务内容**全部来自需求 spec**：
#   搜索项 / 表格列 / 表单项 / data 默认值 / 接口地址 / 按钮 都由 spec 渲染，
#   方法体是按 spec 生成的通用 CRUD 骨架。样板自己的字段、字典码、接口
#   一个都不会带过来；需求里还没有的东西写成 TODO(需求缺失) 标记，收尾会列出来。
#
#   样板页是哪个、为什么、换样板要改哪几处 → references/cloning.md
#   spec 怎么写 → references/page-spec.md
#
# 用法
#   sh .claude/skills/cop-frontend-dev/scripts/new-page.sh --app opr --list
#
#   sh .claude/skills/cop-frontend-dev/scripts/new-page.sh \
#       --app opr --domain contractManage --module vehicleInsurance \
#       --spec spec.txt
#
#   --title 可省（spec 里有 title 行就行）；--pk 默认 id。
#   --dry-run 只预览不改盘；--force 跳过"样板页已退化"守卫（不推荐）。
#
# 依赖：POSIX sh + awk + grep + sed + find + diff。不需要 Python / Node。
# =============================================================================
set -u

# ---------------------------------------------------------------------------
# 找仓库根：往上找到同时含 cop-ucp-ui 与 cop-opr-ui 的那一层
#
# 先看**当前目录**，再看**脚本自己所在目录**。只看脚本目录是不安全的：
# 那样一来「在别处执行这份脚本」会静默地把文件写进脚本所属的那个仓库 ——
# 而不是你站着的地方。常规用法两者一致，结果不变。
# ---------------------------------------------------------------------------
find_root() {
  for start in "$(pwd)" "$(cd "$(dirname "$0")" 2>/dev/null && pwd)"; do
    [ -n "$start" ] || continue
    d=$start
    while [ "$d" != "/" ] && [ -n "$d" ]; do
      if [ -d "$d/cop-ucp-ui" ] && [ -d "$d/cop-opr-ui" ]; then
        printf '%s\n' "$d"; return 0
      fi
      d=$(dirname "$d")
    done
  done
  return 1
}

camelize() { # risk-manage -> riskManage
  printf '%s' "$1" | awk -F'[-_]' '{
    out = ""
    for (i = 1; i <= NF; i++) {
      p = $i
      if (i > 1 && length(p) > 0) p = toupper(substr(p,1,1)) substr(p,2)
      out = out p
    }
    if (length(out) > 0) out = tolower(substr(out,1,1)) substr(out,2)
    print out }'
}

die()  { printf '❌ %s\n' "$1" >&2; exit 1; }
warn() { printf '⚠️  %s\n' "$1" >&2; }

# ---------------------------------------------------------------------------
# 文本变换工具箱：每个都从 stdin 读、写 stdout，便于串起来
# ---------------------------------------------------------------------------

subst() { # subst <被替换> <替换成>
  awk -v s="$1" -v r="$2" '
    { line = $0
      while ((i = index(line, s)) > 0)
        line = substr(line, 1, i-1) r substr(line, i + length(s))
      print line }'
}

strip_header_comment() { # <文件> —— 去掉开头的 /* … */ 作者横幅，写到 stdout
  # 必须显式吃 "$1"：awk 不给文件名就读 stdin，而这条管道的第一段没有上游重定向
  # ——拿不到文件就等 stdin，在前台跑会直接挂住、stdin 已关时静默出空文件。
  awk '
    fin == 0 && /^\/\*/ { inb = 1; next }
    inb == 1 { if ($0 ~ /\*\//) { inb = 0; fin = 1 } ; next }
    { fin = 1; print }' "$1"
}

drop_comment_markup() { # 删掉注释掉的模板（注释里带 `<` 的），保留纯文字注释
  awk '
    function inner(s) { t = s; sub(/^[ \t]*<!--/, "", t); sub(/-->.*$/, "", t); return t }
    inblock == 0 && /^[ \t]*<!--/ {
      if ($0 ~ /-->/) { if (inner($0) ~ /</) next; print; next }
      inblock = 1; buf = $0; haslt = ($0 ~ /</); next
    }
    inblock == 1 {
      buf = buf "\n" $0; if ($0 ~ /</) haslt = 1
      if ($0 ~ /-->/) { inblock = 0; if (!haslt) printf "%s\n", buf; buf = "" }
      next
    }
    { print }'
}

replace_region() { # 首尾锚点行**都保留**，中间换成内容文件
  awk -v sre="$1" -v ere="$2" -v cf="$3" '
    fin == 0 && started == 0 { if ($0 ~ sre) { started = 1; print; next } }
    started == 1 && $0 !~ ere { next }
    started == 1 && $0 ~ ere {
      while ((getline l < cf) > 0) print l
      close(cf); started = 0; fin = 1; print; next
    }
    { print }'
}

replace_region_excl() { # 首尾锚点行**都删掉**（内容文件自己带上需要的壳）
  awk -v sre="$1" -v ere="$2" -v cf="$3" '
    fin == 1 { print; next }
    started == 0 { if ($0 ~ sre) { started = 1; next } print; next }
    started == 1 {
      if ($0 ~ ere) { while ((getline l < cf) > 0) print l; close(cf); started = 0; fin = 1 }
      next
    }'
}

drop_between() { # 删掉「起锚点行（含）→ 止锚点行（不含）」这一整段
  replace_region_excl "$1" "$2" /dev/null
}

swap_children() { # <开标签正则> <闭标签正则> <内容文件>
  # 只换**子元素**，开标签逐字保留 —— 而且开标签可以跨多行。
  # 样板里 <dc-search-form 的属性是分行写的（idKey / :model / :dcColspan / @refreshTable …），
  # 用 replace_region 只留第一行会把这些属性全吞掉，产出一个没有 idKey 的空壳
  #（check-page.sh 会报 `<dc-search-form> 上没写 idKey`）。所以在这里一直印到
  # 开标签那个 `>` 为止（按字符找，不按行；属性值里带 '>' 的极端写法不在本版处理）。
  awk -v sre="$1" -v ere="$2" -v cf="$3" '
    BEGIN { phase = 0 }
    phase == 3 { print; next }
    phase == 0 {
      if ($0 ~ sre) { print; phase = ($0 ~ />/) ? 2 : 1; next }
      print; next
    }
    phase == 1 { print; if ($0 ~ />/) phase = 2; next }
    phase == 2 {
      if ($0 ~ ere) {
        while ((getline l < cf) > 0) print l
        close(cf); print; phase = 3
      }
      next
    }'
}

drop_enclosing() { # 删掉「包住内层锚点的那一整块」：<内层锚点> <块首> <块尾>
  awk -v ire="$1" -v sre="$2" -v ere="$3" '
    { lines[NR] = $0
      if (hit == 0 && $0 ~ ire) hit = NR }
    END {
      if (hit == 0) { for (i = 1; i <= NR; i++) print lines[i]; exit }
      s = 0; e = 0
      for (i = hit; i >= 1; i--) if (lines[i] ~ sre) { s = i; break }
      for (i = hit; i <= NR; i++) if (lines[i] ~ ere) { e = i; break }
      if (s == 0 || e == 0) { for (i = 1; i <= NR; i++) print lines[i]; exit }
      for (i = 1; i <= NR; i++) if (i < s || i > e) print lines[i] }'
}

# 平衡花括号块。样板里的 data() / methods / created() / updated() 都是
# 「一行开头、一层花括号」的规整写法，按花括号配平切是安全的：字符串里的
# ${...} 与本例中的 } 都成对出现，三个样板实测都成立。
replace_brace_block() { # 保留锚点行与收尾行，中间换成内容文件
  awk -v sre="$1" -v cf="$2" '
    function braces(line,   i, c, ch) {
      c = 0
      for (i = 1; i <= length(line); i++) {
        ch = substr(line, i, 1)
        if (ch == "{") c++; else if (ch == "}") c--
      }
      return c
    }
    fin == 1 { print; next }
    started == 0 {
      if ($0 ~ sre) {
        started = 1; print; depth = braces($0)
        if (depth <= 0) { while ((getline l < cf) > 0) print l; close(cf); fin = 1 }
        next
      }
      print; next
    }
    started == 1 {
      depth += braces($0)
      if (depth <= 0) {
        while ((getline l < cf) > 0) print l
        close(cf); print; fin = 1
      }
    }'
}

drop_brace_block() { # 把整个平衡花括号块（含锚点行与收尾行）删掉
  awk -v sre="$1" '
    function braces(line,   i, c, ch) {
      c = 0
      for (i = 1; i <= length(line); i++) {
        ch = substr(line, i, 1)
        if (ch == "{") c++; else if (ch == "}") c--
      }
      return c
    }
    fin == 1 { print; next }
    started == 0 {
      if ($0 ~ sre) {
        started = 1; depth = braces($0)
        if (depth <= 0) fin = 1
        next
      }
      print; next
    }
    started == 1 { depth += braces($0); if (depth <= 0) fin = 1 }'
}

rewrite_lines() { # 在匹配的行上做逐字替换，其余行原样
  awk -v lre="$1" -v s="$2" -v r="$3" '
    $0 ~ lre {
      line = $0
      while ((i = index(line, s)) > 0)
        line = substr(line, 1, i-1) r substr(line, i + length(s))
      print line; next
    }
    { print }'
}

replace_line_first() { # 把**第一个**匹配的行整行换掉
  awk -v lre="$1" -v nl="$2" '
    hit == 0 && $0 ~ lre { print nl; hit = 1; next }
    { print }'
}

drop_lines() { # <子串> —— 删掉**含有该子串**的行
  # 这里刻意不用正则：调用方走 `awk -v`，而 BSD awk 会把 `{`/`}` 当成重复区间
  #（`{ verifyRule }` 这种），不报错却可能乱匹配。要删的都是 import 行、方法名
  # 这类纯字面量，子串匹配够了。
  #
  # 但子串匹配有个坑：删掉的行如果带着**不配平的花括号**（典型的 `    getAllRole() {`
  # 这种方法签名），后面 replace_brace_block 的花括号计数会整体错位、把替换区域
  # 提前截断 —— 症状是产物里残留样板自己的方法。所以这里数一下净花括号，不为 0 就报错。
  # 要删「整个方法」请改配 INFO_DROP_HOOKS（drop_brace_block，按花括号配对删）。
  awk -v s="$1" '
    function braces(line,   i, c, ch) {
      c = 0
      for (i = 1; i <= length(line); i++) {
        ch = substr(line, i, 1)
        if (ch == "{") c++; else if (ch == "}") c--
      }
      return c
    }
    index($0, s) > 0 { delta += braces($0); next }
    { print }
    END { exit (delta == 0) ? 0 : 3 }' || die \
    "要删的行「$1」带着不配平的花括号 → 后面 replace_brace_block 的计数会错位。
   整块（方法定义之类）请改配 INFO_DROP_HOOKS，用 drop_brace_block 删，别用 INFO_DROP_LINES。"
}

# 清单 → 逐项跑。**不要用 `for x in $清单`**：那会按空白切分，于是
# `^  updated *[(]` 被拆成 `^`、`updated`、`*[(]`（`^` 匹配一切），
# `import { verifyRule }` 被拆成 `import`、`{`、`verifyRule`、`}`（`{` 删掉所有带花括号的行
# —— Info 的整个 script 段就是这么没的）。顺带还有通配符展开的风险（项里有 `*`）。
# 所以：先按项分隔符写进文件，再用 while read 逐项跑（在当前 shell 里，die 有效）。
split_list() { # <清单> <项分隔符> <输出文件> —— 供下面的 `while IFS= read -r` 逐行取用
  [ -n "$1" ] || { : > "$3"; return 0; }
  # 末尾这个换行是必须的：`while read` 遇到**没有换行结尾的最后一行**不会执行循环体，
  # 于是清单里的最后一项（常常是唯一一项）被静默丢掉。
  printf '%s\n' "$1" | tr "$2" '\n' > "$3"
}

title_swap() { # <文件> —— 把样板页面写死的中文标题换成 --title
  split_list "$TITLE_LITERALS" '|' "$TMP/pats"
  while IFS= read -r _lit; do
    [ -n "$_lit" ] || continue
    subst "$_lit" "$TITLE" < "$1" > "$1.t" && mv "$1.t" "$1"
  done < "$TMP/pats"
}

attr_value() { # 把一个字符串字面量的值替换掉：<行匹配> <属性名> <新值>
  awk -v lre="$1" -v attr="$2" -v val="$3" '
    $0 ~ lre {
      line = $0
      if (match(line, attr "=\"[^\"]*\""))
        line = substr(line, 1, RSTART-1) attr "=\"" val "\"" substr(line, RSTART+RLENGTH)
      print line; next
    }
    { print }'
}

# 对文件做「stdin→stdout」变换（POSIX sh 没有进程替换，用临时文件中转）
on_file() { # on_file <文件> <变换命令…>
  _f=$1; shift
  "$@" < "$_f" > "$_f.tmp" || die "生成过程中的文本变换失败：$*"
  mv "$_f.tmp" "$_f"
}

# ---------------------------------------------------------------------------
# 样板页里"会被克隆出去"的文件 = 从 index.vue 出发，顺着引用能走到的那些
#
# 为什么不写死「index.vue + components/XxxList.vue + XxxInfo.vue」：
# 样板常带自己的辅助组件与 mixins，写死清单会漏 → 克隆出来的页面 import
# 指向不存在的文件。走引用图就不会漏，样板里没人引用的孤儿文件也不会被带进来。
#
# 跟两类引用：① 相对引用 './x' '../x'；② '@/views/...' —— 但只跟**落在样板
# 自己目录内的**。指向别处的（业务域级共享 service、@/mixins）不跟：那是公共资源。
#
# 例外：ucp 的「新增/修改」是独立路由指向 form/form.vue，没有任何 import
# 指向它，引用图走不到 —— 所以对 ucp 额外种一个 form/form.vue 进去。
# ---------------------------------------------------------------------------
collect_reachable() { # collect_reachable <样板绝对路径>  ->  样板内的相对路径
  _root=$(cd "$1" && pwd)
  [ -f "$_root/index.vue" ] || die "样板页 $_root 里没有 index.vue"
  _views_abs=$(cd "$VIEWS" && pwd)

  _seen=''; _nlq=''
  add() {
    case "$_seen" in *"|$1|"*) return 0 ;; esac
    case "$PRUNE_FILES" in *"|$1|"*) return 0 ;; esac
    _seen="$_seen|$1|"; _nlq="$_nlq $1"; printf '%s\n' "$1"
  }
  take() { # <所在目录(绝对)> <引用字面量>
    _d=$1; _b=$(basename "$2")
    for _c in "$_b" "$_b.vue" "$_b.js"; do
      [ -f "$_d/$_c" ] || continue
      add "${_d#"$_root/"}/$_c"
      return 0
    done
    return 0
  }

  add 'index.vue'
  [ "$UCP_TWO_ROUTES" = 1 ] && [ -f "$_root/form/form.vue" ] && add 'form/form.vue'
  _queue=$_nlq

  while [ -n "$_queue" ]; do
    _nlq=''
    for _f in $_queue; do
      _fd=$(dirname "$_f")
      for _p in $(grep -oE "'\.\.?/[^']*'" "$_root/$_f" 2>/dev/null | sed "s/^'//;s/'$//"); do
        _dir=$(cd "$_root/$_fd" && cd "$(dirname "$_p")" 2>/dev/null && pwd) || continue
        take "$_dir" "$_p"
      done
      for _p in $(grep -oE "'@/views/[^']*'" "$_root/$_f" 2>/dev/null | sed "s/^'@\/views\///;s/'$//"); do
        _dir=$(cd "$_views_abs/$(dirname "$_p")" 2>/dev/null && pwd) || continue
        case "$_dir/" in "$_root"/*) ;; *) continue ;; esac
        take "$_dir" "$_p"
      done
    done
    _queue=$_nlq
  done
}

# ---------------------------------------------------------------------------
# 参数
# ---------------------------------------------------------------------------
APP=""; DOMAIN=""; MODULE=""; TITLE=""; PK=""; SPEC=""; ARCH="crud"
DO_LIST=0; NEW_DOMAIN=0; DRY=0; FORCE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --app)        APP=${2:-};    shift 2 ;;
    --domain)     DOMAIN=${2:-}; shift 2 ;;
    --module)     MODULE=${2:-}; shift 2 ;;
    --title)      TITLE=${2:-};  shift 2 ;;
    --pk)         PK=${2:-};     shift 2 ;;
    --spec)       SPEC=${2:-};   shift 2 ;;
    --archetype)  ARCH=${2:-};   shift 2 ;;
    --list)       DO_LIST=1;     shift ;;
    --new-domain) NEW_DOMAIN=1;  shift ;;
    --dry-run)    DRY=1;         shift ;;
    --force)      FORCE=1;       shift ;;
    -h|--help)    sed -n '2,27p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)            die "不认识的参数：$1（用 --help 看用法）" ;;
  esac
done

case "$APP" in
  ucp) APP_DIR="cop-ucp-ui"; TAG="ucp" ;;
  opr) APP_DIR="cop-opr-ui"; TAG="opr" ;;
  fsc) APP_DIR="cop-fsc-ui"; TAG="fsc" ;;
  "")  die "缺少 --app（ucp | opr | fsc）" ;;
  *)   die "--app 只能是 ucp / opr / fsc，现在是 $APP" ;;
esac

ROOT=$(find_root) || die "找不到仓库根目录（往上找不到同时含 cop-ucp-ui 和 cop-opr-ui 的目录）"
SKILL_DIR=$(cd "$(dirname "$0")/.." && pwd)
CHECK="$SKILL_DIR/scripts/check-page.sh"
# 自查脚本必须真的在：少了它 gate_check 会"跑了个空命令、判定 0 项"，
# 然后一路绿着把带缺陷的产物落盘 —— 最坏的失败模式是"假通过"。
[ -f "$CHECK" ] || die "找不到机械自查脚本 $CHECK
   （new-page.sh 必须和 check-page.sh 放在同一个 scripts/ 目录里；不要把脚本单独复制出去跑）"
VIEWS="$ROOT/$APP_DIR/src/views"
[ -d "$VIEWS" ] || die "$VIEWS 不存在"

TMP=$(mktemp -d "${TMPDIR:-/tmp}/newpage.XXXXXX") || die "建不了临时目录"
trap 'rm -rf "$TMP"' EXIT INT TERM
mkdir -p "$TMP/spec"

# ---------------------------------------------------------------------------
# --spec 解析：行式文本（不是 YAML）。awk 直接吃，人也能一眼审阅 ——
# 字段清单先审后生成，比生成完再核对便宜得多。语法见 references/page-spec.md。
#
# 解析必须放在**最前面**：下面的每应用常量表要用 module 拼标识符（<module>List /
# <Module>Info / pageKey），--list 又要用到样板页路径 —— 都得等 spec 里的
# module / domain 定下来。
# ---------------------------------------------------------------------------
if [ -n "$SPEC" ]; then
  [ -f "$SPEC" ] || die "--spec 指向的文件不存在：$SPEC"
  awk '
    /^[ \t]*#/ { next }
    /^[ \t]*$/ { next }
    {
      key = $1
      rest = $0
      sub(/^[ \t]*[^ \t]+[ \t]*/, "", rest)
      sub(/[ \t]+$/, "", rest)
      if (key ~ /^(search|column|form)$/) { print rest > (OUT "/" key ".raw"); next }
      if (key ~ /^api\./)  { print substr(key, 5) "\t" rest > (OUT "/api.raw"); next }
      if (key ~ /^perm\./) {
        print "❌ spec 里有 perm.* 键（" key "）：本版不生成按钮权限判断。"
        print "   opr/fsc 全仓库没有页面在模板里用 getButton；ucp 的按钮权限由 commonBtnBox"
        print "   内部处理，页面不需要写权限码。要按按钮清单控权，生成后手工接权限。"
        bad = 1; next
      }
      if (key == "action") { print rest > (OUT "/action.raw"); next }
      if (key ~ /^(app|domain|module|title|pk|pageKey|archetype)$/) { print key "\t" rest > (OUT "/meta.raw"); next }
      print "❌ spec 里不认识的行：" key > "/dev/stderr"; bad = 1
    }
    END { exit bad ? 1 : 0 }
  ' OUT="$TMP/spec" "$SPEC" || die "spec 里有不认识的行/不支持的键（见上面）"
fi

spec_meta() { awk -v k="$1" -F'\t' '$1 == k { print $2; exit }' "$TMP/spec/meta.raw" 2>/dev/null; }

# spec 与命令行说的是同一件事：命令行给了就以命令行为准，两边不一致就停下；
# 命令行没给就用 spec 里的 —— 所以 --title / --pk / --module 都可以省。
if [ -n "$SPEC" ]; then
  pick() { # <键> <命令行给的值>
    _k=$1; _cur=$2; _v=$(spec_meta "$_k")
    [ -n "$_v" ] || { printf '%s' "$_cur"; return 0; }
    if [ -z "$_cur" ]; then printf '%s' "$_v"; return 0; fi
    [ "$_v" = "$_cur" ] || die "spec 里 $_k=$_v，命令行给的是 $_cur，两者必须一致"
    printf '%s' "$_cur"
  }
  DOMAIN=$(pick domain "$DOMAIN")
  MODULE=$(pick module "$MODULE")
  TITLE=$(pick  title  "$TITLE")
  PK=$(pick     pk     "$PK")
  _v=$(spec_meta app);       [ -z "$_v" ] || [ "$_v" = "$APP"  ] || die "spec 里 app=$_v，命令行 --app $APP，两者必须一致"
  _v=$(spec_meta archetype); [ -z "$_v" ] || [ "$_v" = "$ARCH" ] || die "spec 里 archetype=$_v，只实现了 crud"
fi

# 模块名在这里定下来（下面的每应用常量表要用它拼标识符）
case "${MODULE:-}" in
  '') : ;;
  [!a-z]*|*[!A-Za-z0-9]*) die "--module 必须是小驼峰字母数字（如 vehicleInsurance），现在是 $MODULE" ;;
esac
PASCAL=$(printf '%s' "${MODULE:-}" | awk '{ print toupper(substr($0,1,1)) substr($0,2) }')

# ---------------------------------------------------------------------------
# 形态注册表：<应用>:<形态> → 样板页相对路径
#   ⚠️ 加一个形态**不只是加一行 case** —— 还要给它写内容区锚点、裁剪表与
#      方法体模板（下面每应用的那一段）。opr 侧已确认存在的其它形态
#      （report-manage 的导出型、*-audit 的只读型）见 references/cloning.md。
# ---------------------------------------------------------------------------
exemplar_for() { # exemplar_for <app> <archetype>
  case "$1:$2" in
    opr:crud) printf '%s\n' 'contractManage/contractTemplateManage/contractTemplateConfig' ;;
    fsc:crud) printf '%s\n' 'region-manage/region-manageInfo' ;;
    ucp:crud) printf '%s\n' 'system-manage/organization-manage/role-manage/role-group' ;;
    *)        return 1 ;;
  esac
}
[ "$ARCH" = "crud" ] || die "目前只实现了 crud 形态（--archetype crud）。注册表见 exemplar_for()"
EXEMPLAR_REL=$(exemplar_for "$APP" "$ARCH") || die "$APP 没有 $ARCH 形态的样板页（exemplar_for()）"
EXEMPLAR_ABS="$VIEWS/$EXEMPLAR_REL"
[ -d "$EXEMPLAR_ABS" ] || die "样板页不存在：$APP_DIR/src/views/$EXEMPLAR_REL
   脚本里的样板常量与仓库现状对不上了，见 references/cloning.md。"

# ---------------------------------------------------------------------------
# 每个应用的形与约定（换样板页要改的就是这一段 + references/cloning.md）
#
#   LIST_FILE / INFO_FILE   样板里「列表」「表单」两份文件（相对样板目录）
#   UCP_TWO_ROUTES          1 = 列表与表单是两条独立路由（ucp）；0 = 容器内切换（opr/fsc）
#   COL_START / COL_END     内容列区间的锚点（两端保留）
#   ACTION_COL              1 = 有行内操作列（opr/fsc）；0 = 动作走悬停按钮组（ucp）
#   LIST_DROP_HOOKS         列表页要整体删掉的样板钩子（花括号块锚点，多项用 | 分隔）
#   INFO_DROP_BLOCKS        「起锚点|止锚点」成对，删掉样板特有的整块模板（多项用 ! 分隔）
#   INFO_DROP_ENCLOSING     「内层锚点|块首|块尾」三段（多项用 ! 分隔）
#   INFO_DROP_HOOKS         表单页要整体删掉的样板钩子（多项用 | 分隔）
#   INFO_DROP_LINES         表单页要删掉的行（**逐字子串**，多项用 | 分隔，不是正则）
#   INFO_MIXIN_DROPS        要从 mixins 数组里摘掉的条目（逐字）
#   INFO_STYLE              1 = 样式块只留被保留模板用到的选择器
#   ACTIVE_NAMES            dc-collapse 的 activeNames 默认值（要与保留的模板一致）
#   TITLE_LITERALS          样板页面里写死的中文标题字面量（多项用 | 分隔），逐字换成 --title
#                           没列全的话，产物里就会留着别人页面的标题（注释、span、i18n key）
#   PRUNE_FILES             引用图里要排除的文件（样板特有构件的配套 mixin）
#   IDENTITY_SUBST          样板模块标识 → 新模块标识（逐字替换，按顺序）
#
# ⚠️ 这些锚点最后都走 `awk -v sre=…`（动态正则）。BSD awk（macOS 自带）对 `\(`
#    这类反斜杠转义直接报 "illegal primary"，且在 -v 赋值时就把 `\(` 折成 `(` ——
#    于是正则变成不配对。**写字符类，不要写反斜杠转义**：`(` → `[(]`，`{` → `[{]`。
#    改锚点后记得拿 `awk -v sre=…` 实跑一遍，别只看 grep 过不过。
# ---------------------------------------------------------------------------
M=${MODULE:-MODULE}
case "$APP" in
  opr)
    LIST_FILE="components/contractTemplateConfigList.vue"
    INFO_FILE="components/contractTemplateConfigInfo.vue"
    UCP_TWO_ROUTES=0
    COL_START='<dc-base-table-column label="序号"'
    COL_END='<dc-table-column fixed="right"'
    ACTION_COL=1
    LIST_DROP_HOOKS=''
    INFO_DROP_BLOCKS=''
    INFO_DROP_ENCLOSING=''
    INFO_DROP_HOOKS=''
    INFO_DROP_LINES='import { verifyRule }'
    INFO_MIXIN_DROPS=''
    INFO_STYLE=0
    ACTIVE_NAMES="['baseInfo']"
    TITLE_LITERALS='合同模板配置'
    PRUNE_FILES=''
    # name="template" 是样板的分组键，会原样印在产物里；跟需求无关，统一成 baseInfo
    IDENTITY_SUBST="contractTemplateConfigInfo|${M}Info contractTemplateConfigList|${M}List name=\"template\"|name=\"baseInfo\""
    ;;
  fsc)
    LIST_FILE="components/regionManageList.vue"
    INFO_FILE="components/regionManageInfo.vue"
    UCP_TWO_ROUTES=0
    COL_START='<dc-base-table-column label="序号"'
    COL_END='<dc-table-column fixed="right"'
    ACTION_COL=1
    # 样板 List 的 created() 调的是样板自己的 getRoleUser（硬编码角色码数组）
    LIST_DROP_HOOKS='^  created *[(]'
    # 样板 Info 里「城市经理选择」整块（含它自己那两张表）是主从构件：
    # 起锚点到「样板那个只装备注的 <dc-form> 的收尾」为止整段删掉 ——
    # drop_between 走的是 replace_region_excl，**首尾锚点行都删**，
    # 所以止锚点要落在那个 form 的 `</dc-form>` 上；写成 `<dc-form ` 会把开标签
    # 吃掉、把它的子项留在模板里（标签不配对）。
    INFO_DROP_BLOCKS='<div class="contentFlex">|^ *</dc-form>$'
    INFO_DROP_ENCLOSING=''
    # updated 里 dealHeight('multipleTable1') 指向被删掉的子表；created 调 getRoleUser
    INFO_DROP_HOOKS='^  updated *[(]|^  created *[(]'
    INFO_DROP_LINES='import { verifyRule }|import areaSelect'
    INFO_MIXIN_DROPS=', areaSelect'
    INFO_STYLE=1
    ACTIVE_NAMES="['baseInfo']"
    TITLE_LITERALS='区域管理---区域管理|区域信息'
    PRUNE_FILES=''
    # regionInfo 是样板自己的域名（区域），跟需求无关；统一成 baseInfo
    # （放在 regionManageInfo 之后：先换模块名，再换分组键）
    IDENTITY_SUBST="regionManageInfo|${M}Info regionManageList|${M}List RegionManageInfo|${PASCAL}Info RegionManageList|${PASCAL}List regionInfo|baseInfo"
    ;;
  ucp)
    LIST_FILE="index.vue"
    INFO_FILE="form/form.vue"
    UCP_TWO_ROUTES=1
    # 序号列是样板里的一段多行插值，保留；内容列从它之后到 </dc-ft-table> 之前替换
    COL_START='</dc-table-column>'
    COL_END='</dc-ft-table>'
    ACTION_COL=0
    LIST_DROP_HOOKS='^  created *[(]'
    INFO_DROP_BLOCKS=''
    # 样板表单里两样特有构件（都靠唯一的内层锚点定位）：
    #   ① 「选法人」弹窗       choose-data-list ← <dc-dialog … </dc-dialog>
    #   ② 「角色穿梭框」卡片   el-transfer     ← <dc-card   … </dc-card>
    INFO_DROP_ENCLOSING='choose-data-list|<dc-dialog|</dc-dialog>!el-transfer|<dc-card|</dc-card>'
    INFO_DROP_HOOKS=''
    # 只删 import 行和 created() 里那一行**调用**（带 this. 前缀，0 个花括号）。
    # 别写成裸 `getAllRole` —— 那会连方法签名 `    getAllRole() {` 一起删掉，
    # 少一个 `{`，后面的 replace_brace_block 会提前截断、把样板方法留在产物里。
    INFO_DROP_LINES='import minxinsDialog|this.getAllRole()|// 获取所有角色'
    INFO_MIXIN_DROPS=', minxinsDialog'
    INFO_STYLE=1
    ACTIVE_NAMES=''
    # {{$t('roleGropInfo')}} —— 整串都要逐字命中模板里的写法，所以用单引号拼、
    # 别在双引号里写：`"{{\$t('x')}}"` 那种写法多出两层花括号，锚点必然落空。
    TITLE_LITERALS='{{$t('"'"'roleGropInfo'"'"')}}'
    PRUNE_FILES='|mixins/superiorLegalEntity.js|'
    IDENTITY_SUBST="role-group|${M} roleGroup|${M}"
    ;;
esac

LIST_EXEMPLAR="$EXEMPLAR_ABS/$LIST_FILE"
INFO_EXEMPLAR="$EXEMPLAR_ABS/$INFO_FILE"
[ -f "$LIST_EXEMPLAR" ] || die "样板里没有列表文件：$LIST_FILE"
[ -f "$INFO_EXEMPLAR" ] || die "样板里没有表单文件：$INFO_FILE"

# ---------------------------------------------------------------------------
# 从样板**现读**几个名字：三个应用叫法不一样，写死就会在另一个应用上炸
#   · 搜索 / 表单绑定的数据对象名（ucp 是 searchForm，opr/fsc 是 searchFormData）
#   · <dc-form> 的 ref（ucp 是 refForm，opr/fsc 是 fromRule）
#   · 保存 / 返回按钮绑的方法名（opr 是 handleSubmit，fsc/ucp 是 handleConfirm）
#   ↑ 这一批全是**骨架**（模板上的绑定），方法体由脚本照着这些名字生成。
# ---------------------------------------------------------------------------
SEARCH_MODEL=$(awk '/<dc-search-form/{f=1} f && /:model="/{ if (match($0, /:model="[^"]*"/)) { s = substr($0, RSTART, RLENGTH); gsub(/^:model="|"$/, "", s); print s; exit } }' "$LIST_EXEMPLAR")
[ -n "$SEARCH_MODEL" ] || die "读不出样板列表页 <dc-search-form> 上的 :model（$LIST_FILE）"
FORM_MODEL=$(awk '/<dc-form /{ if (match($0, /:model="[^"]*"/)) { s = substr($0, RSTART, RLENGTH); gsub(/^:model="|"$/, "", s); print s; exit } }' "$INFO_EXEMPLAR")
[ -n "$FORM_MODEL" ] || die "读不出样板表单页 <dc-form> 上的 :model（$INFO_FILE）"
FORM_REF=$(awk '/<dc-form /{ if (match($0, /ref="[^"]*"/)) { s = substr($0, RSTART, RLENGTH); gsub(/^ref="|"$/, "", s); print s; exit } }' "$INFO_EXEMPLAR")
[ -n "$FORM_REF" ] || FORM_REF='fromRule'
SAVE_HANDLER=$(grep 'type="primary"' "$INFO_EXEMPLAR" | head -1 | grep -o '@click="[a-zA-Z0-9_]*"' | head -1 | sed 's/@click="//; s/"$//')
[ -n "$SAVE_HANDLER" ] || die "读不出样板表单页保存按钮绑的方法名（$INFO_FILE）"
BACK_HANDLER=$(grep -o '@click="[a-zA-Z0-9_]*"' "$INFO_EXEMPLAR" | head -1 | sed 's/@click="//; s/"$//')
[ -n "$BACK_HANDLER" ] || die "读不出样板表单页返回/取消按钮绑的方法名（$INFO_FILE）"

# （spec 解析已挪到脚本开头 —— 每应用常量表要用 spec 里的 module 拼标识符，
#   --list 也要用 spec 定下来的 domain，见上面「--spec 解析」。）

# ---------------------------------------------------------------------------
# --list：列出该应用能作为落点的业务域
# ---------------------------------------------------------------------------
if [ "$DO_LIST" = 1 ]; then
  printf '\n%s 可选的业务域（只有这些能当 --domain）：\n\n' "$APP_DIR"
  found=0
  for d in "$VIEWS"/*/; do
    [ -d "$d" ] || continue
    dom=$(basename "$d")
    rf=''
    [ -f "$d$dom-router.js" ] && rf="$dom-router.js"
    [ -f "$d$dom.js" ]        && rf="$dom.js"
    [ -n "$rf" ] || continue
    n=$(grep -c 'path *:' "$d$rf" 2>/dev/null || printf 0)
    printf '  %-24s 路由文件 %-28s 已挂 %s 条\n' "$dom" "$rf" "$n"
    found=1
  done
  [ "$found" = 1 ] || printf '  （没有找到任何带路由文件的业务域）\n'
  printf '\n没有路由文件的目录（components / micros / publicConfig 等）是公共资源，不能当落点。\n'
  printf '\n%s 形态克隆的样板页：%s\n\n' "$ARCH" "$EXEMPLAR_REL"
  exit 0
fi

# --list 已经在上面提前退出了，所以这里该有的必须有
[ -n "$TITLE" ]  || die "缺少 --title（菜单中文名，如「车辆保险管理」），或在 spec 里写一行 title"
[ -n "$PK" ]     || PK="id"
[ -n "$DOMAIN" ] || die "缺少 --domain（可用 --list 查可选项）"
[ -n "$MODULE" ] || die "缺少 --module（模块目录名，小驼峰，如 vehicleInsurance）"
PAGE_KEY=$(spec_meta pageKey); [ -n "$PAGE_KEY" ] || PAGE_KEY="${MODULE}List"

# ---------------------------------------------------------------------------
# 合法 dcType 词表：**从该应用的 form-item.vue 现读**（三个应用不一样）。
#   fsc 多 textDecimal / remoteSelect，把 fsc 的写法搬到 opr/ucp 是真实踩坑点。
#   在写任何文件之前校验 spec 里的 widget，非法直接退出（不留半个目录）。
# ---------------------------------------------------------------------------
FORM_ITEM_VUE="$ROOT/$APP_DIR/src/plugin/form-item/form-item.vue"
[ -f "$FORM_ITEM_VUE" ] || die "找不到 $APP_DIR 的 form-item.vue，无法校验 dcType"
# ⚠️ 取法与 check-page.sh 的 LEGAL 抽取**必须一致**（那边从 `const obj = {` 数到
#    `}` 为止）。别图省事从 `getComponentName()` 一路扫到 `return obj[...]`：
#   模板里第 39 行也有一个 getComponentName()，那样会把 name/extends 之类的键
#    也当成 dcType，两个脚本的词表就对不上了（一个收、一个拒）。
awk '
  /getComponentName\(\)/      { get = 1 }
  get && /const obj = \{/     { obj = 1; next }
  obj {
    if ($0 ~ /^[ \t]*\}/) exit
    if (match($0, /^[ \t]*[A-Za-z_][A-Za-z0-9_]*[ \t]*:/)) {
      s = $0
      sub(/^[ \t]*/, "", s)
      sub(/[ \t]*:.*$/, "", s)
      print s
    }
  }' "$FORM_ITEM_VUE" > "$TMP/dctypes"
DCTYPE_N=$(wc -l < "$TMP/dctypes" | tr -d ' ')
[ "$DCTYPE_N" -gt 0 ] || die "从 form-item.vue 读不出 dcType 词表（写法变了？）"

# 能从 spec 直接渲染出来的 widget（不需要额外选项数据源）
WIDGET_OK='text textarea dictSelect dictCheckbox dictRadio datePicker timePicker switch isThounsand'
case "$APP" in fsc) WIDGET_OK="$WIDGET_OK textDecimal" ;; esac
# 需要外部选项数据源、脚本给不出来的（select/cascader/radio/… 要配 optionList 数组）
WIDGET_NO='select cascader radio checkbox checkboxGroup remoteSelect blankRow timeSelect'

widget_render() { # <widget> <label> <prop> <dictCode> <required>
  _w=$1; _l=$2; _p=$3; _d=$4; _r=$5
  case "$_w" in
    dictSelect|dictCheckbox|dictRadio) _extra=$(printf ' dictCode="%s"' "$_d") ;;
    datePicker)   _extra=' value-format="yyyy-MM-dd"' ;;
    timePicker)   _extra=' value-format="HH:mm:ss"' ;;
    text)         _extra=' maxlength="128"' ;;
    textarea)     _extra=' maxlength="500"' ;;
    isThounsand)  _extra=' maxlength="15"' ;;
    *)            _extra='' ;;
  esac
  _req=''
  [ "$_r" = "required" ] && _req=' :rules="true"'
  printf '            <dc-form-item label="%s" prop="%s" dcType="%s"%s%s />\n' "$_l" "$_p" "$_w" "$_extra" "$_req"
}

TODO_LIT='TODO(需求缺失)'
: > "$TMP/todo"
note_todo() { printf '%s\n' "$1" >> "$TMP/todo"; }

# 空内容区的占位：留一个显式标记，check-page.sh 会作为必改项报出来。
# （本页确实不需要这块内容时，把那行注释删掉即可 —— 要的是"你想过这件事"。）
printf '          <!-- %s: 搜索条件（spec 的 search 行） -->\n' "$TODO_LIT" > "$TMP/search-todo"
printf '          <!-- %s: 表格列（spec 的 column 行） -->\n' "$TODO_LIT" > "$TMP/column-todo"
printf '            <!-- %s: 表单项（spec 的 form 行） -->\n' "$TODO_LIT" > "$TMP/form-todo"

if [ -n "$SPEC" ]; then
  # ① 校验 widget 并渲染 search / form
  for _kind in search form; do
    [ -f "$TMP/spec/$_kind.raw" ] || continue
    _ln=0
    while IFS= read -r _line; do
      _ln=$((_ln + 1))
      _prop=$(printf '%s' "$_line"  | cut -d'|' -f1 | sed 's/^ *//; s/ *$//')
      _label=$(printf '%s' "$_line" | cut -d'|' -f2 | sed 's/^ *//; s/ *$//')
      _wid=$(printf '%s' "$_line"  | cut -d'|' -f3 | sed 's/^ *//; s/ *$//')
      _dict=$(printf '%s' "$_line" | cut -d'|' -f4 | sed 's/^ *//; s/ *$//')
      _flag=$(printf '%s' "$_line" | cut -d'|' -f5 | sed 's/^ *//; s/ *$//')
      [ -n "$_prop" ] && [ -n "$_wid" ] || die "spec 的 $_kind 第 ${_ln} 行缺字段（要 prop|label|widget[|dictCode][|required]）：$_line"
      grep -qx "$_wid" "$TMP/dctypes" || die "spec 的 $_kind 第 ${_ln} 行用了 $APP 不存在的 dcType：$_wid
   $APP_DIR 的合法值（共 $DCTYPE_N 个）：$(tr '\n' ' ' < "$TMP/dctypes")"
      case " $WIDGET_NO " in
        *" $_wid "*) die "spec 的 $_kind 第 ${_ln} 行用了需要外部选项数据源的 dcType：$_wid
   它要配 optionList / radioLabels 之类的数组，脚本从 spec 生不出来。
   改用 dictSelect + 字典码，或生成后手工补这个字段。" ;;
      esac
      case " $WIDGET_OK " in *" $_wid "*) ;; *) die "spec 的 $_kind 第 ${_ln} 行的 dcType 脚本还不支持渲染：$_wid" ;; esac
      case "$_wid" in
        dictSelect|dictCheckbox|dictRadio)
          [ -n "$_dict" ] || die "spec 的 $_kind 第 ${_ln} 行是 $_wid，必须给字典码（第 4 栏）：
   $_prop|$_label|$_wid|COP0002" ;;
      esac
      if [ "$_kind" = "form" ]; then _r="$_flag"; else _r=''; fi
      widget_render "$_wid" "$_label" "$_prop" "$_dict" "$_r" >> "$TMP/spec/$_kind.out"
    done < "$TMP/spec/$_kind.raw"
  done

  # ② 渲染 column
  if [ -f "$TMP/spec/column.raw" ]; then
    _ln=0
    while IFS= read -r _line; do
      _ln=$((_ln + 1))
      _prop=$(printf '%s' "$_line"  | cut -d'|' -f1 | sed 's/^ *//; s/ *$//')
      _label=$(printf '%s' "$_line" | cut -d'|' -f2 | sed 's/^ *//; s/ *$//')
      _type=$(printf '%s' "$_line"  | cut -d'|' -f3 | sed 's/^ *//; s/ *$//')
      [ -n "$_prop" ] && [ -n "$_label" ] || die "spec 的 column 第 ${_ln} 行缺字段（要 prop|label[|dict:字典码]）：$_line"
      case "$_type" in
        '')      printf '          <dc-base-table-column prop="%s" label="%s" />\n' "$_prop" "$_label" >> "$TMP/spec/column.out" ;;
        dict:*)  _d=${_type#dict:}
                 printf "          <dc-base-table-column prop=\"%s\" label=\"%s\" type=\"dict\" :inputParam=\"{ dictCode: '%s' }\" />\n" \
                   "$_prop" "$_label" "$_d" >> "$TMP/spec/column.out" ;;
        *)       die "spec 的 column 第 ${_ln} 行第 3 栏只认 dict:<字典码>（或留空），现在是 $_type" ;;
      esac
    done < "$TMP/spec/column.raw"
  fi

  # ③ 按钮：样板有对应处理函数的动作才允许声明
  case "$APP" in
    opr|fsc) ACTION_SUPPORTED='add edit view delete' ;;
    ucp)     ACTION_SUPPORTED='add edit delete' ;;
  esac
  if [ -f "$TMP/spec/action.raw" ]; then
    _ln=0
    while IFS= read -r _line; do
      _ln=$((_ln + 1))
      _v=$(printf '%s' "$_line" | cut -d'|' -f1 | sed 's/^ *//; s/ *$//')
      _l=$(printf '%s' "$_line" | cut -d'|' -f2 | sed 's/^ *//; s/ *$//')
      [ -n "$_v" ] || die "spec 的 action 第 ${_ln} 行缺动作名（要 add|按钮文字）"
      case " $ACTION_SUPPORTED " in
        *" $_v "*) ;;
        *) die "spec 的 action 第 ${_ln} 行声明的动作 $APP 的 CRUD 样板不支持：$_v
   本样板支持：$ACTION_SUPPORTED
   （没有对应处理函数的按钮不生成 —— 免得给你一个点了没反应的按钮）" ;;
      esac
      printf '%s|%s\n' "$_v" "$_l" >> "$TMP/spec/action.out"
    done < "$TMP/spec/action.raw"
  fi
fi

if [ -s "$TMP/spec/search.out" ]; then cp "$TMP/spec/search.out" "$TMP/search-out"; else cp "$TMP/search-todo" "$TMP/search-out"; fi
if [ -s "$TMP/spec/column.out" ]; then cp "$TMP/spec/column.out" "$TMP/column-out"; else cp "$TMP/column-todo" "$TMP/column-out"; fi
if [ -s "$TMP/spec/form.out" ];   then cp "$TMP/spec/form.out"   "$TMP/form-out";   else cp "$TMP/form-todo"   "$TMP/form-out"; fi

# 按钮：spec 没给 action 行就用该应用的默认按钮组
[ -s "$TMP/spec/action.out" ] || {
  case "$APP" in
    opr|fsc) printf 'add|新增\nedit|编辑\nview|查看\n' > "$TMP/spec/action.out" ;;
    ucp)     printf 'add|新增\nedit|修改\ndelete|删除\n' > "$TMP/spec/action.out" ;;
  esac
}
has_action() { grep -q "^$1|" "$TMP/spec/action.out" 2>/dev/null; }
label_of() { # 按钮文字：spec 给的，没有就按默认
  _l=$(awk -v v="$1" -F'|' '$1 == v { print $2; exit }' "$TMP/spec/action.out" 2>/dev/null)
  [ -n "$_l" ] && { printf '%s' "$_l"; return; }
  case "$1" in add) printf '新增' ;; edit) printf '编辑' ;; view) printf '查看' ;; delete) printf '删除' ;; esac
}

# 接口地址：spec 给了就用；没给就留 CHANGE_ME 占位 + TODO 标记
api_url() { awk -v k="$1" -F'\t' '$1 == k { print $2; exit }' "$TMP/spec/api.raw" 2>/dev/null; }
api_line() { # <名字> <默认尾段>
  _u=$(api_url "$1")
  [ -n "$_u" ] && { printf '%s' "$_u"; return; }
  note_todo "api.$1 没给接口地址 → service.js 里留了 CHANGE_ME"
  printf '/api/%s/web/CHANGE_ME/%s' "$TAG" "$2"
}

# ---------------------------------------------------------------------------
# 样板页守卫：断言**生成器依赖的那些锚点还在**。
#
# 为什么不直接拿 check-page.sh 当门槛：它的规则是「生成物」的契约（按 opr/fsc
# 的惯例要求 searchFormData、ref="multipleTable"、:key="reloadTable"…），而样板页
# 是早于本 skill 存在的真实页面 —— ucp 的搜索对象叫 searchForm、表格 ref 叫
# refTableList，fsc 那个样板目录里还躺着一个没人引用的死文件。拿它当门槛，
# ucp 和 fsc 会 100% 生成不了，而拦住的东西一条都不会进产物（内容区、data()、
# methods 全都是重新生成的）。
# 该守的是锚点漂移：样板页被人改过 / 换样板时锚点表没同步 → 立刻停。
# 产物本身的机械自查放在生成之后做（下面的 gate_check）。
# ---------------------------------------------------------------------------
REACHABLE=$(collect_reachable "$EXEMPLAR_ABS") || die "读不出样板页的引用图：$EXEMPLAR_REL"

anchor_ok() { # <文件> <ERE> <说明>
  grep -qE "$2" "$1" || die "样板页锚点漂移：$3
   在 ${1#"$ROOT/"} 里找不到 /$2/
   样板页被改过，或者换样板时没同步本脚本的锚点常量与 references/cloning.md 的锚点表。"
}
anchor_ok "$LIST_EXEMPLAR" '<dc-search-form'      '列表页查询区起点 <dc-search-form'
anchor_ok "$LIST_EXEMPLAR" '</dc-search-form>'    '列表页查询区终点 </dc-search-form>'
anchor_ok "$LIST_EXEMPLAR" "$COL_START"           '内容列区间起点（COL_START）'
anchor_ok "$LIST_EXEMPLAR" "$COL_END"             '内容列区间终点（COL_END）'
anchor_ok "$LIST_EXEMPLAR" '^  data *[(]'          '列表页 data()'
anchor_ok "$LIST_EXEMPLAR" '^  methods *: *[{]'    '列表页 methods'
anchor_ok "$INFO_EXEMPLAR" '<dc-form '            '表单页 <dc-form '
anchor_ok "$INFO_EXEMPLAR" '</dc-form>'           '表单页 </dc-form>'
anchor_ok "$INFO_EXEMPLAR" '^  data *[(]'          '表单页 data()'
anchor_ok "$INFO_EXEMPLAR" '^  methods *: *[{]'    '表单页 methods'
if [ "$ACTION_COL" = 1 ]; then
  anchor_ok "$LIST_EXEMPLAR" '<dc-table-column fixed="right"' '行内操作列起点'
  anchor_ok "$LIST_EXEMPLAR" '</dc-table-column>'             '行内操作列终点'
fi
split_list "$LIST_DROP_HOOKS" '|' "$TMP/pats"
while IFS= read -r _h; do
  [ -n "$_h" ] || continue
  anchor_ok "$LIST_EXEMPLAR" "$_h" "列表页待删钩子 $_h"
done < "$TMP/pats"
split_list "$INFO_DROP_HOOKS" '|' "$TMP/pats"
while IFS= read -r _h; do
  [ -n "$_h" ] || continue
  anchor_ok "$INFO_EXEMPLAR" "$_h" "表单页待删钩子 $_h"
done < "$TMP/pats"
# 标题字面量：容器和表单页里各有写死的样板标题，找不到就说明样板被人改过
split_list "$TITLE_LITERALS" '|' "$TMP/pats"
while IFS= read -r _lit; do
  [ -n "$_lit" ] || continue
  grep -qF "$_lit" "$EXEMPLAR_ABS/index.vue" "$INFO_EXEMPLAR" 2>/dev/null || die \
    "样板页锚点漂移：标题字面量「$_lit」在样板页里找不到了
   （常量 TITLE_LITERALS，见 references/cloning.md 的锚点表）"
done < "$TMP/pats"

# ---------------------------------------------------------------------------
# 域 / 模块 / 路由登记位置
# ---------------------------------------------------------------------------
DOMAIN_DIR="$VIEWS/$DOMAIN"
MOD_DIR="$DOMAIN_DIR/$MODULE"
IS_NEW_DOMAIN=0
ROUTER_FILE=''
if [ -d "$DOMAIN_DIR" ]; then
  if [ -f "$DOMAIN_DIR/$DOMAIN-router.js" ]; then
    ROUTER_FILE="$DOMAIN_DIR/$DOMAIN-router.js"
  elif [ -f "$DOMAIN_DIR/$DOMAIN.js" ]; then
    ROUTER_FILE="$DOMAIN_DIR/$DOMAIN.js"
  fi
fi

if [ -z "$ROUTER_FILE" ]; then
  if [ -d "$DOMAIN_DIR" ]; then
    die "业务域 $DOMAIN 里没有路由文件 —— 它不是可落地的业务域
   （components / micros / publicConfig 这类是公共资源）。用 --list 看可选项。"
  elif [ "$NEW_DOMAIN" != 1 ]; then
    die "业务域 $DOMAIN 不存在。
   先用 --list 挑一个既有业务域（推荐，能复用同域既有代码风格）；
   确实要新建业务域，加 --new-domain。"
  else
    ROUTER_FILE="$DOMAIN_DIR/$DOMAIN-router.js"
    IS_NEW_DOMAIN=1
  fi
fi
[ -d "$MOD_DIR" ] && die "$MOD_DIR 已存在，换个 --module 名，或先手工确认要不要覆盖。"

ROUTER_REL=${ROUTER_FILE#"$ROOT/"}
ROUTER_REL_APP=${ROUTER_REL#"$APP_DIR/"}
[ "$ROUTER_REL_APP" = "$ROUTER_REL" ] && ROUTER_REL_APP=$ROUTER_REL
MOD_REL="src/views/$DOMAIN/$MODULE"
ROUTER_STEM=$(basename "$ROUTER_FILE" .js)
ROUTER_VAR="$(camelize "${ROUTER_STEM%-router}")Router"

VIEW_ROUTER="$VIEWS/view-router.js"
[ -f "$VIEW_ROUTER" ] || die "$VIEW_ROUTER 不存在，无法注册路由"
VR_TOUCH=0
grep -q "from '\./$DOMAIN/" "$VIEW_ROUTER" || VR_TOUCH=1

# ucp 的「新增/修改」是独立路由，方法里要 push 到 /view/<分组路径>/<模块>/add。
# 分组路径 = view-router.js 里 children 指向本域路由的那个 path（**不一定等于目录名**）。
VIEW_GROUP=''
if [ "$APP" = "ucp" ]; then
  if [ "$VR_TOUCH" = 1 ]; then
    VIEW_GROUP="$DOMAIN"
  else
    VIEW_GROUP=$(awk -v v="$ROUTER_VAR" -v q="'" '
      { lines[NR] = $0
        if (index($0, "children: " v) > 0) hit = NR }
      END {
        for (i = hit; i >= 1; i--)
          if (match(lines[i], "path: *" q "[^" q "]*" q)) {
            s = substr(lines[i], RSTART, RLENGTH)
            gsub("path: *" q, "", s); gsub(q, "", s)
            print s; exit
          }
      }' "$VIEW_ROUTER")
    [ -n "$VIEW_GROUP" ] || die "在 view-router.js 里找不到 $ROUTER_VAR 对应的分组 path"
  fi
fi

# ---------------------------------------------------------------------------
# service.js：三个接口（delete 只在需要时）
# ---------------------------------------------------------------------------
gen_service() { # <输出>
  _page=$(api_line page listPage); _add=$(api_line add add); _upd=$(api_line update update)
  _has_del=0; _del=''
  if has_action delete; then
    _del=$(api_url delete)
    if [ -n "$_del" ]; then _has_del=1
    else _has_del=2; _del=$(api_line delete delete)
    fi
  fi
  {
    printf '// %s —— 接口地址表\n' "$TITLE"
    printf '//\n'
    printf '// 地址全部来自需求 spec；带 CHANGE_ME 的表示需求里还没给。\n'
    printf "import { requestPost } from '@/axios'\n\n"
    printf 'const api = {\n'
    printf "  %sPage: '%s', // 分页查询\n" "$MODULE" "$_page"
    printf "  %sAdd: '%s', // 新增\n" "$MODULE" "$_add"
    if [ "$_has_del" = 0 ]; then
      printf "  %sUpdate: '%s' // 修改\n" "$MODULE" "$_upd"
    else
      printf "  %sUpdate: '%s', // 修改\n" "$MODULE" "$_upd"
      printf "  %sDelete: '%s' // 删除\n" "$MODULE" "$_del"
    fi
    printf '}\n\n'
    printf 'export default {\n'
    printf '  %sPage: (params) => { return requestPost(api.%sPage, params) },\n' "$MODULE" "$MODULE"
    printf '  %sAdd: (params) => { return requestPost(api.%sAdd, params) },\n' "$MODULE" "$MODULE"
    if [ "$_has_del" = 0 ]; then
      printf '  %sUpdate: (params) => { return requestPost(api.%sUpdate, params) }\n' "$MODULE" "$MODULE"
    else
      printf '  %sUpdate: (params) => { return requestPost(api.%sUpdate, params) },\n' "$MODULE" "$MODULE"
      printf '  %sDelete: (params) => { return requestPost(api.%sDelete, params) }\n' "$MODULE" "$MODULE"
    fi
    printf '}\n'
  } > "$1"
}

# ---------------------------------------------------------------------------
# 列表页 data() 的成员
# ---------------------------------------------------------------------------
search_data_members() { # 搜索对象的成员（spec 的 search 行）
  sed -n 's/.*prop="\([^"]*\)".*/\1/p' "$TMP/spec/search.out" | sed "s/.*/&: '', /" | tr -d '\n'
}
gen_list_data() { # <输出>
  case "$APP" in
    opr|fsc)
      {
        printf '    return {\n'
        printf '      // 配置缓存参数（唯一 pageKey）\n'
        printf '      searchCacheOptions: {\n'
        printf "        pageKey: '%s' // 每个列表页唯一标识\n" "$PAGE_KEY"
        printf '      },\n'
        printf '      tableData: [], // 表格数据\n'
        printf '      multipleSelection: [], // 选中数据\n'
        printf '      loading: false,\n'
        printf '      multiSelectFlag: false, // 表格是否可多选\n'
        printf "      rowIdKey: '%s', // 列表行数据唯一标识\n" "$PK"
        if [ -s "$TMP/spec/search.out" ]; then
          printf '      %s: { %s} // 搜索数据\n' "$SEARCH_MODEL" "$(search_data_members)"
        else
          printf '      %s: {} // 搜索数据（%s: 搜索条件）\n' "$SEARCH_MODEL" "$TODO_LIT"
        fi
        printf '    }\n'
      } > "$1"
      ;;
    ucp)
      {
        printf '    return {\n'
        printf '      tableData: [], // 表格数据\n'
        printf '      // 分页参数配置\n'
        printf '      paginationParam: {\n'
        printf '        pageSize: 10,\n'
        printf '        currentPage: 1,\n'
        printf '        pgTotal: 0\n'
        printf '      },\n'
        printf '      multiSelect: false, // 表格是否多选\n'
        printf '      multipleSelection: [], // 选中数据\n'
        printf '      currentRow: null, // 选中的当前行\n'
        # 末尾这个逗号不能省：后面还跟着 hoverBtnConfig，少了就是语法错误
        if [ -s "$TMP/spec/search.out" ]; then
          printf '      %s: { %s}, // 搜索数据\n' "$SEARCH_MODEL" "$(search_data_members)"
        else
          printf '      %s: {}, // 搜索数据（%s: 搜索条件）\n' "$SEARCH_MODEL" "$TODO_LIT"
        fi
        printf '      hoverBtnConfig: {\n'
        printf '        hoverBtnList: [\n'
        while IFS='|' read -r _v _l; do
          [ -n "$_v" ] || continue
          case "$_v" in
            add)    _m='addFun';    _i='el-icon-circle-plus-outline'; _k='newItem' ;;
            edit)   _m='updateFun'; _i='el-icon-edit';                _k='update' ;;
            delete) _m='deleteFun'; _i='el-icon-delete';              _k='delete' ;;
            *)      continue ;;
          esac
          if [ -n "$_l" ]; then _n="'$_l'"; else _n="this.\$t('$_k')"; fi
          printf '          {\n'
          printf '            btnName: %s, // 按钮名称\n' "$_n"
          printf "            btnType: '%s',\n" "$_v"
          printf "            btnIcon: '%s', // 按钮图标\n" "$_i"
          printf "            buttonMethod: '%s' // 点击调用的方法名\n" "$_m"
          printf '          },\n'
        done < "$TMP/spec/action.out"
        printf '        ],\n'
        printf '        ifShowName: true // 是否显示按钮名称\n'
        printf '      }\n'
        printf '    }\n'
      } > "$1"
      ;;
  esac
}

# ---------------------------------------------------------------------------
# 列表页 methods
# ---------------------------------------------------------------------------
gen_list_methods() { # <输出>
  case "$APP" in
    opr|fsc)
      {
        printf '    // 初始数据\n'
        printf '    init() {\n'
        printf '      // 表格数据\n'
        printf '      this.queryWithCache(() => this.queryList())\n'
        printf '    },\n'
        printf '    /**\n'
        printf '     * @description: 获取表格数据\n'
        printf '     * @param: paginationParam:分页参数\n'
        printf '     */\n'
        printf '    queryList() {\n'
        printf '      if (this.loading) return\n'
        printf '      this.loading = true\n'
        printf '      const { paginationParam } = this\n'
        printf '      this.tableData = []\n'
        printf '      const params = {\n'
        printf '        pageSize: paginationParam.pageSize,\n'
        printf '        pageNum: paginationParam.currentPage,\n'
        printf '        param: {\n'
        printf '          ...this.%s\n' "$SEARCH_MODEL"
        printf '        }\n'
        printf '      }\n'
        printf '      httpService\n'
        printf '        .%sPage(params)\n' "$MODULE"
        printf '        .then(res => {\n'
        printf '          this.tableData = res.data\n'
        printf '          this.paginationParam.total = res.total\n'
        printf '          this.currentRow = {}\n'
        printf '          // 多选时跨页保留勾选状态，单选时不需要\n'
        printf '          this.setTableSelected()\n'
        printf '        })\n'
        printf '        .finally(() => {\n'
        printf '          this.loading = false\n'
        printf '        })\n'
        printf '    },\n'
        printf '    // 勾选表格\n'
        printf '    handleSelectionChange(val) {\n'
        printf '      this.multipleSelection = val\n'
        printf '    },\n'
        if has_action add; then
          printf '    // 新增\n'
          printf '    handleAdd() {\n'
          printf '      // 触发jump事件 跳转到新增页面\n'
          printf "      this.\$emit('jump', '%sInfo', 'add', '')\n" "$MODULE"
          printf '    },\n'
        fi
        if has_action edit; then
          printf '    // 修改\n'
          printf '    handleEdit(row) {\n'
          printf '      this.jumpWithCache(() => {\n'
          printf "        this.\$emit('jump', '%sInfo', 'edit', row)\n" "$MODULE"
          printf '      })\n'
          printf '    },\n'
        fi
        if has_action view; then
          printf '    // 查看\n'
          printf '    viewrate(row) {\n'
          printf '      this.jumpWithCache(() => {\n'
          printf "        this.\$emit('jump', '%sInfo', 'view', row)\n" "$MODULE"
          printf '      })\n'
          printf '    },\n'
        fi
        if has_action delete; then
          printf '    // 删除\n'
          printf '    handleDelete(row) {\n'
          printf "      this.\$confirm('确定删除该数据？', '提示', {\n"
          printf "        confirmButtonText: '确定',\n"
          printf "        cancelButtonText: '取消',\n"
          printf "        type: 'warning',\n"
          printf '        closeOnClickModal: false\n'
          printf '      })\n'
          printf '        .then(() => {\n'
          [ -n "$(api_url delete)" ] || printf '          // %s: api.delete 接口地址\n' "$TODO_LIT"
          printf '          httpService.%sDelete(row).then(res => {\n' "$MODULE"
          printf "            if (res.code === 'S000000') {\n"
          printf '              this.$message.success(res.msg)\n'
          printf '              this.queryList()\n'
          printf '            } else {\n'
          printf '              this.$message.error(res.msg)\n'
          printf '            }\n'
          printf '          })\n'
          printf '        })\n'
          printf '        .catch(() => {\n'
          printf "          this.\$message({ type: 'info', message: '已取消操作' })\n"
          printf '        })\n'
          printf '    },\n'
        fi
      } > "$1"
      ;;
    ucp)
      {
        printf '    // 初始数据\n'
        printf '    init() {\n'
        printf '      // 表格数据\n'
        printf '      this.getData()\n'
        printf '    },\n'
        printf '    // 悬停按钮分发\n'
        printf '    operate(obj) {\n'
        printf '      if (obj.buttonMethod) {\n'
        printf '        this[obj.buttonMethod](this.currentRow)\n'
        printf '      }\n'
        printf '    },\n'
        printf '    /**\n'
        printf '     * @description: 获取表格数据\n'
        printf '     * @param: paginationParam:分页参数\n'
        printf '     */\n'
        printf '    getData(paginationParam) {\n'
        printf '      paginationParam &&\n'
        printf '        paginationParam.pageSize &&\n'
        printf '        (this.paginationParam.pageSize = paginationParam.pageSize)\n'
        printf '      paginationParam &&\n'
        printf '        paginationParam.currentPage &&\n'
        printf '        (this.paginationParam.currentPage = paginationParam.currentPage)\n'
        printf '      let params = {\n'
        printf '        pageNum: this.paginationParam.currentPage,\n'
        printf '        pageSize: this.paginationParam.pageSize,\n'
        printf '        param: this.%s\n' "$SEARCH_MODEL"
        printf '      }\n'
        printf '      httpService.%sPage(params).then((res) => {\n' "$MODULE"
        printf '        this.tableData = res.data\n'
        printf '        this.paginationParam.pgTotal = res.total\n'
        printf '      })\n'
        printf '    },\n'
        printf '    // 勾选表格\n'
        printf '    handleSelectionChange(val) {\n'
        printf '      this.multipleSelection = val\n'
        printf '    },\n'
        printf '    // 行点击\n'
        printf '    rowClick(row) {\n'
        printf '      this.currentRow = row\n'
        if has_action edit; then
          printf '      this.updateFun(row)\n'
        else
          printf '      // %s: 行点击后的动作（样板这里是打开修改）\n' "$TODO_LIT"
        fi
        printf '    },\n'
        if has_action add; then
          printf '    // 新增\n'
          printf '    addFun() {\n'
          printf '      this.$router.push({\n'
          printf "        path: '/view/%s/%s/add',\n" "$VIEW_GROUP" "$MODULE"
          printf "        query: { handleType: 'add' }\n"
          printf '      })\n'
          printf '    },\n'
        fi
        if has_action edit; then
          printf '    // 修改\n'
          printf '    updateFun(row) {\n'
          printf '      if (!row) return\n'
          printf '      this.currentRow = row\n'
          printf '      this.$router.push({\n'
          printf "        path: '/view/%s/%s/update',\n" "$VIEW_GROUP" "$MODULE"
          printf "        query: { row: JSON.stringify(row), handleType: 'edit' }\n"
          printf '      })\n'
          printf '    },\n'
        fi
        if has_action delete; then
          printf '    // 删除\n'
          printf '    deleteFun(row) {\n'
          printf '      if (!row) return\n'
          printf "      this.\$confirm('此操作将永久删除该数据，是否继续？', '提示', {\n"
          printf "        confirmButtonText: '确定',\n"
          printf "        cancelButtonText: '取消',\n"
          printf "        type: 'warning',\n"
          printf '        closeOnClickModal: false\n'
          printf '      })\n'
          printf '        .then(() => {\n'
          [ -n "$(api_url delete)" ] || printf '          // %s: api.delete 接口地址\n' "$TODO_LIT"
          printf '          httpService.%sDelete(row).then((res) => {\n' "$MODULE"
          printf '            this.$message.success(res.msg)\n'
          printf '            this.getData()\n'
          printf '          })\n'
          printf '        })\n'
          printf '        .catch(() => {\n'
          printf "          this.\$message.info('已取消删除')\n"
          printf '        })\n'
          printf '    },\n'
        fi
      } > "$1"
      ;;
  esac
}

# ---------------------------------------------------------------------------
# 表单页 data() / methods
#   · 保存/返回按钮绑的方法名从样板现读，所以生成的函数名与模板对得上
#   · ucp 的表单是独立路由，handleType/row 来自 $route.query（样板里的 computed）
# ---------------------------------------------------------------------------
gen_info_data() { # <输出>
  {
    printf '    return {\n'
    [ -n "$ACTIVE_NAMES" ] && printf '      activeNames: %s,\n' "$ACTIVE_NAMES"
    if [ -s "$TMP/spec/form.out" ]; then
      # 末尾的逗号不能省：formData 后面还跟着 formRules，少一个逗号就是语法错误
      printf '      %s: { %s}, // 表单数据\n' "$FORM_MODEL" \
        "$(sed -n 's/.*prop="\([^"]*\)".*/\1/p' "$TMP/spec/form.out" | sed "s/.*/&: '', /" | tr -d '\n')"
    else
      # 末尾的逗号同样不能省（后面跟着 formRules）—— 漏了就是语法错误，
      # check-page.sh 的 node --check 会当场报出来
      printf '      %s: {}, // 表单数据（%s: 表单项）\n' "$FORM_MODEL" "$TODO_LIT"
    fi
    printf '      formRules: {}\n'
    printf '    }\n'
  } > "$1"
}

gen_info_methods() { # <输出>
  {
    printf '    init() {\n'
    case "$APP" in
      opr|fsc)
        printf "      if (this.actionType !== 'add') {\n"
        printf '        this.%s = Object.assign(this.%s, this.formParam)\n' "$FORM_MODEL" "$FORM_MODEL"
        printf '      }\n'
        printf '      this.$nextTick(function () {\n'
        printf '        this.$refs.%s.clearValidate()\n' "$FORM_REF"
        printf '      })\n'
        ;;
      ucp)
        printf "      if (this.handleType === 'edit') {\n"
        printf '        this.%s = { ...this.row }\n' "$FORM_MODEL"
        printf '      }\n'
        ;;
    esac
    printf '    },\n'
    printf '    // 保存\n'
    printf '    %s() {\n' "$SAVE_HANDLER"
    printf '      this.$refs.%s.validate((valid) => {\n' "$FORM_REF"
    printf '        if (valid) {\n'
    case "$APP" in
      opr|fsc)
        printf "          if (this.actionType === 'add') {\n"
        printf '            this.handleAdd()\n'
        printf '          } else {\n'
        printf '            this.handleEdit()\n'
        printf '          }\n'
        ;;
      ucp)
        printf '          const type = {\n'
        printf '            add: httpService.%sAdd,\n' "$MODULE"
        printf '            edit: httpService.%sUpdate\n' "$MODULE"
        printf '          }\n'
        printf '          type[this.handleType]({ ...this.%s }).then((res) => {\n' "$FORM_MODEL"
        printf '            this.$message.success(res.msg)\n'
        printf '            this.%s()\n' "$BACK_HANDLER"
        printf '          })\n'
        ;;
    esac
    printf '        } else {\n'
    case "$APP" in
      opr|fsc) printf "          this.\$message.error('必填信息没有完成')\n" ;;
      ucp)     printf "          this.\$message.warning('请填写必填项！')\n" ;;
    esac
    printf '        }\n'
    printf '      })\n'
    printf '    },\n'
    if [ "$APP" != "ucp" ]; then
      printf '    handleAdd() {\n'
      printf '      const params = this.%s\n' "$FORM_MODEL"
      printf '      httpService.%sAdd(params).then((res) => {\n' "$MODULE"
      printf "        if (res.code === 'S000000') {\n"
      printf '          this.$message.success(res.msg)\n'
      printf '          this.%s()\n' "$BACK_HANDLER"
      printf '        } else {\n'
      printf '          this.$message.error(res.msg)\n'
      printf '        }\n'
      printf '      })\n'
      printf '    },\n'
      printf '    handleEdit() {\n'
      printf '      const params = this.%s\n' "$FORM_MODEL"
      printf '      httpService.%sUpdate(params).then((res) => {\n' "$MODULE"
      printf "        if (res.code === 'S000000') {\n"
      printf '          this.$message.success(res.msg)\n'
      printf '          this.%s()\n' "$BACK_HANDLER"
      printf '        } else {\n'
      printf '          this.$message.error(res.msg)\n'
      printf '        }\n'
      printf '      })\n'
      printf '    },\n'
    fi
    printf '    // 返回\n'
    printf '    %s() {\n' "$BACK_HANDLER"
    case "$APP" in
      opr|fsc) printf "      this.\$emit('back')\n" ;;
      ucp)     printf "      this.\$router.push('/view/%s/%s')\n" "$VIEW_GROUP" "$MODULE" ;;
    esac
    printf '    }\n'
  } > "$1"
}

# ---------------------------------------------------------------------------
# 片段：操作列按钮（opr/fsc）与内容列
# ---------------------------------------------------------------------------
if [ "$ACTION_COL" = 1 ]; then
  {
    printf '              <template slot-scope="scope">\n'
    while IFS='|' read -r _v _l; do
      [ -n "$_v" ] || continue
      [ "$_v" = "add" ] && continue
      case "$_v" in
        edit)   _call='handleEdit(scope.row)' ;;
        view)   _call='viewrate(scope.row)' ;;
        delete) _call='handleDelete(scope.row)' ;;
        *)      continue ;;
      esac
      printf '                <el-button @click="%s" type="text" size="small">%s</el-button>\n' "$_call" "$(label_of "$_v")"
    done < "$TMP/spec/action.out"
    printf '              </template>\n'
  } > "$TMP/action-btns"
else
  : > "$TMP/action-btns"
  # ucp 的按钮组由 data 里的 hoverBtnConfig 驱动，模板不动
fi

{
  if [ -s "$TMP/spec/column.out" ]; then cat "$TMP/spec/column.out"
  else printf '          <!-- %s: 表格列 -->\n' "$TODO_LIT"; fi
} > "$TMP/columns"

# ---------------------------------------------------------------------------
# 组装列表页
# ---------------------------------------------------------------------------
build_list_file() { # <输入> <输出>
  on_file "$1" drop_comment_markup
  on_file "$1" swap_children '<dc-search-form' '</dc-search-form>' "$TMP/search-out"
  if [ "$ACTION_COL" = 1 ]; then
    if has_action add; then
      on_file "$1" replace_line_first 'handleAdd' \
        "            <dc-button type=\"primary\" @click=\"handleAdd\">$(label_of add)</dc-button>"
    else
      on_file "$1" drop_lines 'handleAdd'
    fi
    on_file "$1" replace_region '<dc-table-column fixed="right"' '</dc-table-column>' "$TMP/action-btns"
  fi
  on_file "$1" replace_region "$COL_START" "$COL_END" "$TMP/columns"
  split_list "$LIST_DROP_HOOKS" '|' "$TMP/pats"
  while IFS= read -r _h; do
    [ -n "$_h" ] && on_file "$1" drop_brace_block "$_h"
  done < "$TMP/pats"
  gen_list_data "$TMP/list-data"
  gen_list_methods "$TMP/list-methods"
  on_file "$1" replace_brace_block '^  data *[(]' "$TMP/list-data"
  on_file "$1" replace_brace_block '^  methods *: *[{]' "$TMP/list-methods"
  on_file "$1" attr_value 'cachePageKey=' 'cachePageKey' "$PAGE_KEY"
  cp "$1" "$2"
}

# ---------------------------------------------------------------------------
# 组装表单页
# ---------------------------------------------------------------------------
# 表单项区间：第一个 <dc-form> 里的 dc-form-item 整段换成 spec 的表单项
#（dc-form-item 会嵌套子组件，所以要按开闭配对整段丢，不能只丢开标签那行）；
# 第二个及以后的 <dc-form> 整块删掉（样板里常把"备注"单放一个 form）。
form_items_swap() {
  awk -v cf="$TMP/form-out" '
    begun == 0 { if ($0 ~ /<dc-form /) { begun = 1 } ; print; next }
    begun == 1 {
      if ($0 ~ /<\/dc-form>/) { while ((getline l < cf) > 0) print l; close(cf); begun = 2; print; next }
      if ($0 ~ /<dc-form-item/) { initem = 1; next }
      if (initem == 1) { if ($0 ~ /<\/dc-form-item>/) initem = 0; next }
      print; next
    }
    begun == 2 {
      if ($0 ~ /<dc-form /) { inext = 1; next }
      if (inext == 1) { if ($0 ~ /<\/dc-form>/) inext = 0; next }
      print; next
    }'
}

build_info_file() { # <输入> <输出>
  on_file "$1" drop_comment_markup
  # 整块模板：清单里每项是「起锚点|止锚点」，项与项之间用 !
  split_list "$INFO_DROP_BLOCKS" '!' "$TMP/pats"
  while IFS= read -r _pair; do
    [ -n "$_pair" ] || continue
    on_file "$1" drop_between "${_pair%%|*}" "${_pair#*|}"
  done < "$TMP/pats"
  # 包住的块：每项「内层锚点|块首|块尾」，项与项之间用 !
  split_list "$INFO_DROP_ENCLOSING" '!' "$TMP/pats"
  while IFS= read -r _triple; do
    [ -n "$_triple" ] || continue
    _rest=${_triple#*|}
    on_file "$1" drop_enclosing "${_triple%%|*}" "${_rest%%|*}" "${_rest#*|}"
  done < "$TMP/pats"
  on_file "$1" form_items_swap
  split_list "$INFO_DROP_HOOKS" '|' "$TMP/pats"
  while IFS= read -r _h; do
    [ -n "$_h" ] && on_file "$1" drop_brace_block "$_h"
  done < "$TMP/pats"
  split_list "$INFO_DROP_LINES" '|' "$TMP/pats"
  while IFS= read -r _re; do
    [ -n "$_re" ] && on_file "$1" drop_lines "$_re"
  done < "$TMP/pats"
  [ -n "$INFO_MIXIN_DROPS" ] && on_file "$1" rewrite_lines '^  mixins:' "$INFO_MIXIN_DROPS" ''
  if [ "$INFO_STYLE" = 1 ]; then
    printf '<style lang="scss" scoped>\n' > "$TMP/style-min"
    if [ "$APP" = "fsc" ]; then
      printf '.xin-dw-header {\n  display: flex;\n  justify-content: space-between;\n  align-items: center;\n  padding: 10px 0 10px 20px;\n}\n' >> "$TMP/style-min"
    fi
    printf '</style>\n' >> "$TMP/style-min"
    on_file "$1" replace_region_excl '^<style' '^</style>' "$TMP/style-min"
  fi
  gen_info_data "$TMP/info-data"
  gen_info_methods "$TMP/info-methods"
  on_file "$1" replace_brace_block '^  data *[(]' "$TMP/info-data"
  on_file "$1" replace_brace_block '^  methods *: *[{]' "$TMP/info-methods"
  # 页面标题字面量统一在落盘前由 title_swap() 换（容器 + 表单页都覆盖，见 TITLE_LITERALS）
  cp "$1" "$2"
}

# ---------------------------------------------------------------------------
# 克隆：引用图里每个文件 → 改名 → 替换模块标识 → 走内容渲染
# ---------------------------------------------------------------------------
SELF_SENTINEL='@@SELF_DIR@@'
subst_exemplar() { # stdin → stdout；指向样板自己目录的绝对引用先打哨兵
  # 不打哨兵就会出这种事：文件里写 '@/views/<域>/<样板目录>/mixins/y.js'，
  # 短名替换把目录名换成新模块名后会多留一层原目录 → 模块找不到（真实踩过）。
  #
  # 逐对替换必须串行作用在**同一条流**上。写成
  #     for _pair in $IDENTITY_SUBST; do subst …; done
  # 会让第一趟的 subst 一次吃光 stdin，第二对开始读到 EOF —— 于是只有第一对生效
  #（opr 的 <module>List 名字就因此没被换掉）。所以用临时文件把每一趟串起来。
  subst "@/views/$EXEMPLAR_REL" "$SELF_SENTINEL" > "$TMP/subst-pass"
  split_list "$IDENTITY_SUBST" ' ' "$TMP/pats"
  while IFS= read -r _pair; do
    [ -n "$_pair" ] || continue
    subst "${_pair%%|*}" "${_pair#*|}" < "$TMP/subst-pass" > "$TMP/subst-next"
    mv "$TMP/subst-next" "$TMP/subst-pass"
  done < "$TMP/pats"
  subst "$SELF_SENTINEL" "@/views/$DOMAIN/$MODULE" < "$TMP/subst-pass"
  rm -f "$TMP/subst-pass"
}

# 样板引用的共享 service 换成新模块自己的 service.js
subst_service() {
  case "$APP" in
    opr) subst '@/views/contractManage/service/service.js' "@/views/$DOMAIN/$MODULE/service.js" ;;
    fsc) subst '@/views/region-manage/service/service.js' "@/views/$DOMAIN/$MODULE/service.js" ;;
    ucp) subst '@/views/system-manage/service/service.js' "@/views/$DOMAIN/$MODULE/service.js" ;;
  esac
}

rename_rel() { # 文件名里的样板标识 → 新模块标识
  _d=$(dirname "$1"); _b=$(basename "$1")
  case "$APP" in
    opr) _b=$(printf '%s' "$_b" | sed "s/^contractTemplateConfigList/${MODULE}List/;s/^contractTemplateConfigInfo/${MODULE}Info/") ;;
    fsc) _b=$(printf '%s' "$_b" | sed "s/^regionManageList/${MODULE}List/;s/^regionManageInfo/${MODULE}Info/") ;;
  esac
  case "$_d" in .) printf '%s\n' "$_b" ;; *) printf '%s/%s\n' "$_d" "$_b" ;; esac
}

# ---------------------------------------------------------------------------
# 落盘前的全部产物先在 $TMP/pkg 里做出来
# ---------------------------------------------------------------------------
mkdir -p "$TMP/pkg"
CLONED=''
if [ "$UCP_TWO_ROUTES" != 1 ]; then
  strip_header_comment "$EXEMPLAR_ABS/index.vue" | subst_exemplar > "$TMP/pkg/index.vue"
  CLONED="index.vue"
fi

LIST_OUT=$(rename_rel "$LIST_FILE")
INFO_OUT=$(rename_rel "$INFO_FILE")
mkdir -p "$TMP/pkg/$(dirname "$LIST_OUT")" "$TMP/pkg/$(dirname "$INFO_OUT")"

strip_header_comment "$LIST_EXEMPLAR" | subst_exemplar | subst_service > "$TMP/pkg/$LIST_OUT"
strip_header_comment "$INFO_EXEMPLAR" | subst_exemplar | subst_service > "$TMP/pkg/$INFO_OUT"
build_list_file "$TMP/pkg/$LIST_OUT" "$TMP/pkg/$LIST_OUT.new"; mv "$TMP/pkg/$LIST_OUT.new" "$TMP/pkg/$LIST_OUT"
build_info_file "$TMP/pkg/$INFO_OUT" "$TMP/pkg/$INFO_OUT.new"; mv "$TMP/pkg/$INFO_OUT.new" "$TMP/pkg/$INFO_OUT"
title_swap "$TMP/pkg/$LIST_OUT"
title_swap "$TMP/pkg/$INFO_OUT"
[ -f "$TMP/pkg/index.vue" ] && title_swap "$TMP/pkg/index.vue"
CLONED="$CLONED $LIST_OUT $INFO_OUT"

# 引用图里其余的辅助文件（ucp 的 mixins/ 之类）原样带过去
for _rel in $REACHABLE; do
  _out=$(rename_rel "$_rel")
  case " $CLONED " in *" $_out "*) continue ;; esac
  mkdir -p "$TMP/pkg/$(dirname "$_out")"
  strip_header_comment "$EXEMPLAR_ABS/$_rel" | subst_exemplar | subst_service > "$TMP/pkg/$_out"
  CLONED="$CLONED $_out"
done

gen_service "$TMP/pkg/service.js"

# ---------------------------------------------------------------------------
# 路由条目
# ---------------------------------------------------------------------------
gen_route_entries() {
  {
    _entry "$MODULE"          "$TITLE"      "./$MODULE/index.vue"     false
    if [ "$UCP_TWO_ROUTES" = 1 ]; then
      _entry "$MODULE/add"    "$TITLE新增"  "./$MODULE/form/form.vue" true
      _entry "$MODULE/update" "$TITLE修改"  "./$MODULE/form/form.vue" true
    fi
  } | sed '$s/,$//'
}
_entry() {
  printf '  {\n'
  printf "    path: '%s',\n" "$1"
  printf "    name: '%s',\n" "$2"
  printf "    component: () => import('%s'),\n" "$3"
  printf '    meta: {\n'
  printf "      title: '%s',\n" "$2"
  printf '      noTag: %s\n' "$4"
  printf '    }\n'
  printf '  },\n'
}
gen_view_router_entry() {
  printf '  // %s\n' "$TITLE"
  printf '  {\n'
  printf "    path: '%s',\n" "$DOMAIN"
  printf '    component: RouterEnter,\n'
  printf "    children: %s\n" "$ROUTER_VAR"
  printf '  }\n'
}

# ---------------------------------------------------------------------------
# 往 `export default [ ... ]` 末尾追加一个元素
#   锚点 = 最后一个顶格的 ]；给它前面最后一个非空/非注释行补逗号
# ---------------------------------------------------------------------------
append_to_array() { # <目标文件> <条目文件> <输出文件>
  skip=$(awk '/^\]/{ n = NR } END { print n+0 }' "$1")
  [ "$skip" -gt 0 ] || die "$1 里找不到顶格的 ]，无法安全插入。请手工加路由。"
  j=$(awk -v end="$skip" '
        NR < end && $0 !~ /^[[:space:]]*$/ && $0 !~ /^[[:space:]]*\/\// { n = NR }
        END { print n+0 }' "$1")
  [ "$j" -gt 0 ] || die "$1 结构异常，无法定位数组末尾。"
  tail_=$(awk -v n="$j" 'NR == n { print }' "$1")
  case "$tail_" in *","|*"[") ADDCOMMA=0 ;; *) ADDCOMMA=1 ;; esac
  awk -v end="$skip" -v j="$j" -v addc="$ADDCOMMA" -v ef="$2" '
    NR == j && addc == 1 { print $0 "," ; next }
    NR == end { while ((getline l < ef) > 0) print l; close(ef) }
    { print }' "$1" > "$3"
}

gen_route_entries > "$TMP/route-entry"
gen_view_router_entry > "$TMP/vr-entry"

# 幂等：同一个模块再跑一次时，别把路由项追加第二遍 —— 否则路由器里会堆出一串
# 重复条目（删掉模块目录重跑是常见情形）。判据是路由器里已经出现该模块的 path，
# 生成器产出的 path 就是 "$MODULE" 本身。
SKIP_ROUTE=0
if [ "$IS_NEW_DOMAIN" != 1 ] && grep -qF "path: '$MODULE'" "$ROUTER_FILE"; then
  SKIP_ROUTE=1
fi

# ---------------------------------------------------------------------------
# 落地前把关：把产物放进一个"长得像应用"的临时目录里，跑一遍机械自查。
#
# 软链搭骨架（src 下除 views 全软链、views 里除本域全软链、本域里除本模块全软链），
# 本模块是唯一的真目录 —— 既不碰真实仓库，又让 check-page.sh 按本应用真实的
# dcType 词表 / 成功码白名单 / 模块存在性来判。
#
# 只在给了 --spec 时当门槛。「需求还没给」的两类项（TODO(需求缺失) 标记与
# CHANGE_ME 占位）不算失败：那正是"先生成骨架、后补需求"这条路的产物。
# ---------------------------------------------------------------------------
gate_check() {
  if [ -z "$SPEC" ]; then
    printf '\n（没给 --spec，跳过落地前的机械自查 —— 产物里的 %s 标记就是待办清单）\n' "$TODO_LIT"
    return 0
  fi
  _S="$TMP/scratch/$APP_DIR"
  mkdir -p "$_S/src/views/$DOMAIN" || return 0
  for _e in "$ROOT/$APP_DIR"/src/*; do
    _b=$(basename "$_e"); [ "$_b" = "views" ] && continue
    ln -s "$_e" "$_S/src/$_b" 2>/dev/null
  done
  for _e in "$VIEWS"/*; do
    _b=$(basename "$_e"); [ "$_b" = "$DOMAIN" ] && continue
    ln -s "$_e" "$_S/src/views/$_b" 2>/dev/null
  done
  if [ -d "$DOMAIN_DIR" ]; then
    for _e in "$DOMAIN_DIR"/*; do
      _b=$(basename "$_e"); [ "$_b" = "$MODULE" ] && continue
      ln -s "$_e" "$_S/src/views/$DOMAIN/$_b" 2>/dev/null
    done
  fi
  cp -R "$TMP/pkg" "$_S/src/views/$DOMAIN/$MODULE" || return 0
  _out=$(sh "$CHECK" "$_S/src/views/$DOMAIN/$MODULE" --spec "$SPEC" 2>&1)
  # 自查脚本没跑起来（路径不对、语法错、提前退出）时，输出里既没有「小结：」
  # 也没有「全部通过」—— 这时 _nbad 会算成 0，等于"假通过"。宁可当场失败。
  case "$_out" in
    *"小结："*|*"全部通过"*) ;;
    *) die "机械自查没有正常跑完，输出里既没有小结也没有『全部通过』—— 不当成通过：
$_out" ;;
  esac
  _nbad=$(printf '%s\n' "$_out" | awk '
    /^❌/ { getline m; if (m !~ /TODO\(需求缺失\)/ && m !~ /CHANGE_ME/) n++ }
    END { print n + 0 }')
  if [ "$_nbad" -gt 0 ]; then
    printf '\n%s\n' "$_out" >&2
    if [ "$FORCE" = 1 ]; then
      warn "产物没过机械自查（$_nbad 项），--force 已跳过 —— 产物带着已知缺陷。"
      return 0
    fi
    die "产物没过机械自查（$_nbad 项，已排除「需求缺失」与 CHANGE_ME）。
   这多半是生成器的问题，不是你的 spec 写错了 —— 把上面这段输出反馈给维护者。
   确实要先拿到文件，加 --force（产物带着已知缺陷）。"
  fi
  printf '\n机械自查：产物已过 check-page.sh（除「需求缺失」待办外没有必改项）。\n'
}
gate_check

if [ "$IS_NEW_DOMAIN" = 1 ]; then
  { printf 'export default [\n'; cat "$TMP/route-entry"; printf ']\n'; } > "$TMP/router-new"
else
  cp "$ROUTER_FILE" "$TMP/router-before"
  if [ "$SKIP_ROUTE" = 1 ]; then
    cp "$TMP/router-before" "$TMP/router-after"   # 不追加，后面的 diff / 落盘都自然变成空操作
  else
    append_to_array "$TMP/router-before" "$TMP/route-entry" "$TMP/router-after"
  fi
fi

cp "$VIEW_ROUTER" "$TMP/vr-before"
if [ "$VR_TOUCH" = 1 ]; then
  n=$(awk '/^import /{ k = NR } END { print k+0 }' "$VIEW_ROUTER")
  awk -v n="$n" -v line="import $ROUTER_VAR from './$DOMAIN/$(basename "$ROUTER_FILE")'" \
      'NR == n { print; print line; next } { print }' "$TMP/vr-before" > "$TMP/vr-with-import"
  append_to_array "$TMP/vr-with-import" "$TMP/vr-entry" "$TMP/vr-after"
fi

# ---------------------------------------------------------------------------
# 预览
# ---------------------------------------------------------------------------
[ "$DRY" = 1 ] && printf '\n🔍 DRY RUN —— 不会写任何文件\n\n'
printf '应用       %s\n' "$APP_DIR"
[ "$IS_NEW_DOMAIN" = 1 ] && printf '业务域     %s  ← 新建\n' "$DOMAIN" || printf '业务域     %s\n' "$DOMAIN"
printf '模块       %s\n' "$MODULE"
printf '菜单名     %s\n' "$TITLE"
printf '形态       %s\n' "$ARCH"
printf '样板页     %s\n' "$EXEMPLAR_REL"
if [ -n "$SPEC" ]; then
  printf '需求 spec  %s（搜索 %s / 列 %s / 表单项 %s / 接口 %s）\n' "$SPEC" \
    "$(wc -l < "$TMP/spec/search.out" 2>/dev/null | tr -d ' ')" \
    "$(wc -l < "$TMP/spec/column.out" 2>/dev/null | tr -d ' ')" \
    "$(wc -l < "$TMP/spec/form.out"   2>/dev/null | tr -d ' ')" \
    "$(wc -l < "$TMP/spec/api.raw"    2>/dev/null | tr -d ' ')"
else
  printf '需求 spec  （未给 —— 只生成骨架，内容处留 %s 标记）\n' "$TODO_LIT"
fi
if [ "$IS_NEW_DOMAIN" = 1 ]; then
  printf '路由       %s   新建\n' "$ROUTER_REL"
elif [ "$SKIP_ROUTE" = 1 ]; then
  printf '路由       %s   已存在 %s 项，跳过追加\n' "$ROUTER_REL" "$MODULE"
else
  printf '路由       %s   追加\n' "$ROUTER_REL"
fi
[ "$VR_TOUCH" = 1 ] && printf 'view-router 需要新增 import + 数组项\n' || printf 'view-router 已注册，不动\n'
printf '\n── 要生成的文件（骨架来自样板，内容来自 spec）──\n'
for f in $CLONED; do printf '  + %s/%s\n' "$MOD_REL" "$f"; done
printf '  + %s/service.js\n' "$MOD_REL"

printf '\n── 按钮（来自 spec 的 action 行）──\n'
while IFS='|' read -r _v _l; do
  [ -n "$_v" ] || continue
  printf '  %-8s %s\n' "$_v" "$(label_of "$_v")"
done < "$TMP/spec/action.out"

if [ "$IS_NEW_DOMAIN" != 1 ] && [ "$SKIP_ROUTE" != 1 ]; then
  printf '\n── 改动 %s ──\n' "$ROUTER_REL"
  diff -u "$TMP/router-before" "$TMP/router-after" | sed "1s|.*|--- a/$ROUTER_REL|; 2s|.*|+++ b/$ROUTER_REL|"
fi
if [ "$VR_TOUCH" = 1 ]; then
  printf '\n── 改动 src/views/view-router.js ──\n'
  diff -u "$TMP/vr-before" "$TMP/vr-after" | sed "1s|.*|--- a/src/views/view-router.js|; 2s|.*|+++ b/src/views/view-router.js|"
fi

if [ "$DRY" = 1 ]; then
  printf '\n🔍 DRY RUN 结束，未写盘。去掉 --dry-run 即可真正生成。\n'
  exit 0
fi

# ---------------------------------------------------------------------------
# 落盘（改既有文件前先备份，且只备份一次 —— 重复跑时若已存在 .bak 就不再覆盖，
# 否则第二次会把"已改过的文件"存成 .bak，原始版本就永久丢了）
# ---------------------------------------------------------------------------
backup_once() { [ -e "$1.bak" ] && return 0; cp "$1" "$1.bak"; }

mkdir -p "$MOD_DIR"
for f in $CLONED; do
  mkdir -p "$MOD_DIR/$(dirname "$f")"
  cp "$TMP/pkg/$f" "$MOD_DIR/$f"
  printf '  + %s/%s\n' "$MOD_REL" "$f"
done
cp "$TMP/pkg/service.js" "$MOD_DIR/service.js"
printf '  + %s/service.js\n' "$MOD_REL"

if [ "$IS_NEW_DOMAIN" = 1 ]; then
  mkdir -p "$DOMAIN_DIR"
  cp "$TMP/router-new" "$ROUTER_FILE"
  printf '  ~ %s   （新建）\n' "$ROUTER_REL"
else
  if [ "$SKIP_ROUTE" = 1 ]; then
    printf '  ~ %s   已存在 %s 项，路由未改动（也就不留 .bak）\n' "$ROUTER_REL" "$MODULE"
  else
    backup_once "$ROUTER_FILE"
    cp "$TMP/router-after" "$ROUTER_FILE"
    printf '  ~ %s   （原文件已备份为 %s.bak）\n' "$ROUTER_REL" "$(basename "$ROUTER_FILE")"
  fi
fi
if [ "$VR_TOUCH" = 1 ]; then
  backup_once "$VIEW_ROUTER"
  cp "$TMP/vr-after" "$VIEW_ROUTER"
  printf '  ~ src/views/view-router.js   （原文件已备份为 view-router.js.bak）\n'
fi

cat <<EOF

========================================================================
✅ 已生成 $MOD_REL
========================================================================

骨架（模板结构、组件用法、mixins、容器与路由）克隆自样板页
$EXEMPLAR_REL；
搜索项 / 表格列 / 表单项 / data 默认值 / 接口地址 / 按钮 全部来自需求 spec，
样板自己的字段、字典码、接口不会带过来。

接下来只有这几件：

  1. 跑一遍机械自查（含「内容出处」校验：产物里每个字段名 / 字典码 / 权限码
     都必须能在 spec 里找到）：
        sh .claude/skills/cop-frontend-dev/scripts/check-page.sh $MOD_REL --spec <你的 spec>
     退出码 0 才算干净。报 ❌ 就按每条下面「→」那行的建议改，改完重跑。

  2. 检查 rowIdKey —— 现在是 '$PK'，必须等于接口返回里真实存在的主键字段名
     （写成接口里没有的字段，行选中、批量操作会静默失效）。

  3. 让后端把菜单配好。menuUrl 必须等于页面文件的路径
     （src/views/ 之后、去掉 .vue），也就是：
        $DOMAIN/$MODULE/index
     （末尾的 /index 不能省。省了会去解析 $DOMAIN/$MODULE.vue —— 不存在，
       webpack 报模块找不到、页面打不开，不是"没入口"那么轻）

  4. 确认页面没问题后，删掉路由文件的备份：
        rm -f $ROUTER_REL_APP.bak
     （它只是给你出问题时对照用的。留着不删的话，git add . 会把它一起提交进去。）
EOF

if [ -s "$TMP/todo" ]; then
  printf '\n⚠️  需求里还缺下面这些东西（产物里已留 %s / CHANGE_ME 标记）：\n' "$TODO_LIT"
  sort -u "$TMP/todo" | sed 's/^/   · /'
fi

cat <<'EOF'

方法体是按 spec 生成的**通用 CRUD 骨架**：
  列表页  init / 查询 / 勾选 / 新增 / 修改 /（查看、删除）
  表单页  init / 保存 /（新增、修改、返回）
字段映射（哪些字段怎么拼进查询参数、保存前要补哪些业务字段）属于你自己的业务逻辑，
样板不会替你决定，需要时在对应方法里加。

已裁掉的样板构件：
EOF
case "$APP" in
  fsc) printf '  · Info 里「城市经理选择」整块（含它自带的两张表）\n  · 备注那个独立 <dc-form>（备注要保留就写进 spec 的 form 行）\n  · 造型样式里只留了还用到的那几条\n' ;;
  ucp) printf '  · form 里「选法人」弹窗（含 choose-data-list 与配套 mixin 文件）\n  · form 里「角色穿梭框」卡片（el-transfer）\n' ;;
  *)   printf '  （本应用的样板没有额外构件）\n' ;;
esac
if [ "$FORCE" = 1 ] && [ -n "$SPEC" ]; then
  printf '\n⚠️  这次是 --force 生成的：产物有没过的机械自查项，照上面的输出逐条确认。\n'
fi
