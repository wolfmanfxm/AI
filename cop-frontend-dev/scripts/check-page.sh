#!/bin/sh
# =============================================================================
# check-page.sh —— 不用看懂前端代码，机械自查
#
# 用法
#   sh .claude/skills/cop-frontend-dev/scripts/check-page.sh <目录或.vue文件>
#   sh .claude/skills/cop-frontend-dev/scripts/check-page.sh <目录> --spec <spec文件>
#
#   例
#   sh .../check-page.sh src/views/contractManage/vehicleInsurance
#   sh .../check-page.sh src/views/contractManage/vehicleInsurance/index.vue
#
#   加 --spec <file> 会多跑一项「内容出处」校验：产物里承载业务含义的标识符
#   （字段名 prop、字典码、pageKey、searchFormData/formData 的键）都必须能在
#   spec 里找到 —— 找不到说明它来自样板页而不是需求。不给 --spec 时跳过这项，
#   并在结尾说明「未校验内容出处」。
#
# 它检查的都是「不报错、只是没反应 / 显示不对」的坑 —— 这类问题打包不会失败，
# 只能靠对代码。规则全部来自 references/pitfalls.md 与 references/checklist.md。
#
# 退出码  0 = 全部通过    1 = 有必须修的问题    2 = 用法/路径错
#
# 依赖：POSIX sh + awk + grep + find。不需要 Python / Node。
# =============================================================================
set -u

SPEC=""
TARGET=""
while [ $# -gt 0 ]; do
  case "$1" in
    --spec)
      [ $# -ge 2 ] || { sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
      SPEC=$2; shift 2 ;;
    -h|--help)
      sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*)
      printf '❌ 不认识的参数：%s\n\n' "$1" >&2
      sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//' >&2
      exit 2 ;;
    *)
      [ -z "$TARGET" ] || {
        printf '❌ 只能给一个路径，多给了：%s\n\n' "$1" >&2
        sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//' >&2
        exit 2
      }
      TARGET=$1; shift ;;
  esac
done
if [ -z "$TARGET" ]; then
  sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
fi
if [ -n "$SPEC" ] && [ ! -f "$SPEC" ]; then
  printf '❌ --spec 指向的文件不存在：%s\n' "$SPEC" >&2
  exit 2
fi

# 路径按「当前目录」解析；解析不到时再试「仓库根 + 各应用目录」。
# 这样下面两种写法都能用，不需要你先想清楚该 cd 到哪一层：
#     sh .../check-page.sh cop-opr-ui/src/views/contractManage/vehicleInsurance   （站在仓库根）
#     sh .../check-page.sh src/views/contractManage/vehicleInsurance              （站在子应用里）
if [ ! -e "$TARGET" ]; then
  d=$(pwd)
  while [ "$d" != "/" ] && [ -n "$d" ]; do
    for app in cop-ucp-ui cop-opr-ui cop-fsc-ui; do
      if [ -e "$d/$app/$TARGET" ]; then
        TARGET="$d/$app/$TARGET"
        break 2
      fi
    done
    d=$(dirname "$d")
  done
fi
[ -e "$TARGET" ] || { printf '❌ 路径不存在：%s\n' "$1"; exit 2; }

# ---------------------------------------------------------------------------
# 定位应用：往上找 cop-ucp-ui / cop-opr-ui / cop-fsc-ui
# ---------------------------------------------------------------------------
if [ -f "$TARGET" ]; then
  START=$(cd "$(dirname "$TARGET")" && pwd)
  FILELIST="$TARGET"
else
  START=$(cd "$TARGET" && pwd)
  FILELIST=""
fi

APPDIR=""
d=$START
while [ "$d" != "/" ]; do
  case "$(basename "$d")" in
    cop-ucp-ui|cop-opr-ui|cop-fsc-ui) APPDIR=$d; break ;;
  esac
  d=$(dirname "$d")
done
[ -n "$APPDIR" ] || { printf '❌ 从 %s 往上找不到 cop-ucp-ui / cop-opr-ui / cop-fsc-ui\n' "$TARGET"; exit 2; }

APP=$(basename "$APPDIR")

TMP=$(mktemp -d "${TMPDIR:-/tmp}/chkpage.XXXXXX") || exit 2
trap 'rm -rf "$TMP"' EXIT INT TERM
: > "$TMP/findings"
NERR=0; NWARN=0

# 本模块自己的 service.js（生成物一定有：new-page.sh 每次都写一份）。
# 没有它就说明这个模块用的是域级共享 service，那就不做"接口名对得上吗"的检查
# —— 域级 service 里是别的模块的接口，按本页调用去核对会全量误报。
SERVICEJS=""
[ -f "$START/service.js" ] && SERVICEJS="$START/service.js"

# ---------------------------------------------------------------------------
# 本应用合法的 dcType 值 —— 从源码现读，不硬编码
# （三应用不一样：fsc 比 ucp/opr 多 textDecimal / remoteSelect 两个）
# ---------------------------------------------------------------------------
FORMITEM="$APPDIR/src/plugin/form-item/form-item.vue"
LEGAL="$TMP/legal.txt"
if [ -f "$FORMITEM" ]; then
  # 注意：BSD awk 不支持 \s，只能写 [ \t]
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
    }' "$FORMITEM" > "$LEGAL"
fi
NLEGAL=$(wc -l < "$LEGAL" | tr -d ' ')

# ---------------------------------------------------------------------------
# 本应用的成功码白名单 —— 也从源码现读
# （三个应用各不相同，而且判断写在各 requestXxx 函数体里、不在 interceptors，
#   所以硬编码 'S000000' 会在白名单调整后变成误报）
# 取法：所有 [...].includes(result.data.code) 数组里的字面量，外加
#       result.data.code === 'X' 这种单值比较。
# ---------------------------------------------------------------------------
CODES="$TMP/codes.txt"
: > "$CODES"
AXIOSJS="$APPDIR/src/axios/index.js"
if [ -f "$AXIOSJS" ]; then
  awk '
  {
    if ($0 ~ /\[/) buf = ""
    buf = buf " " $0
    if ($0 ~ /includes\(result\.data\.code\)/) { print buf; buf = "" }
    else if ($0 ~ /result\.data\.code[ \t]*[!=]=/) print $0
  }' "$AXIOSJS" | grep -oE "'[A-Za-z0-9_]+'" | tr -d "'" \
    | awk 'length($0) >= 3' | sort -u > "$CODES"
fi
CODELIST=$(tr '\n' ' ' < "$CODES" | sed 's/ *$//')

# ---------------------------------------------------------------------------
# 工具
# ---------------------------------------------------------------------------
CURFILE=""; CURREL=""
CLEAN="$TMP/clean.txt"

# 把注释替换成等长空白（行号不变）
# 这一步很关键：仓库里"注释掉但看起来是活的"代码特别多（pitfalls P10），
# 不剔注释就会把注释里的示例值当成真代码，误报一片。
clean_comments() {
  awk 'BEGIN { html = 0 }
  {
    line = $0
    if (html) {
      p = index(line, "-->")
      if (p > 0) { html = 0; line = substr(line, p + 3) } else { print ""; next }
    }
    while ((a = index(line, "<!--")) > 0) {
      rest = substr(line, a + 4)
      b = index(rest, "-->")
      if (b > 0) { line = substr(line, 1, a - 1) substr(rest, b + 3) }
      else       { html = 1; line = substr(line, 1, a - 1); break }
    }
    if (match(line, /[ \t]\/\//)) line = substr(line, 1, RSTART)
    if (line ~ /^[ \t]*\/\//)    line = ""
    print line
  }' "$1"
}

report() { # report <ERR|WARN> <行号> <消息> <建议>
  if [ "$1" = ERR ]; then NERR=$((NERR + 1)); else NWARN=$((NWARN + 1)); fi
  printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$CURREL" "$2" "$3" "${4:-}" >> "$TMP/findings"
}

# 命中就报：chk <级别> <ERE> <消息> [建议]
chk() {
  ln=$(grep -n -E -m1 "$2" "$CLEAN" 2>/dev/null | cut -d: -f1)
  [ -n "${ln:-}" ] && report "$1" "$ln" "$3" "${4:-}"
  return 0
}

# 必须有：need <ERE> <消息> [建议]
need() {
  grep -q -E "$1" "$CLEAN" 2>/dev/null || report ERR 0 "$2" "${3:-}"
  return 0
}

# ---------------------------------------------------------------------------
# 逐文件检查
# ---------------------------------------------------------------------------
check_file() {
  f=$1
  CURFILE=$f
  CURREL=${f#"$APPDIR"/}
  case "$f" in
    "$TARGET") CURREL=$f ;;
  esac
  clean_comments "$f" > "$CLEAN"

  base=$(basename "$f")

  # ---------------- 通用：import 的 @/ 模块必须在本应用真实存在 ----------------
  # 抓「模板引用了本应用没有的文件」这类编译期才会炸的坑。
  # 真实案例：ucp 没有 @/mixins/searchCacheMixin.js（只有 opr/fsc 有），
  # 生成的页面会报模块找不到 —— 这条检查就是为了让它在自查阶段就暴露。
  {
    grep -oE "from[[:space:]]*['\"]@/[^'\"]+['\"]"      "$CLEAN" 2>/dev/null
    grep -oE "require\([[:space:]]*['\"]@/[^'\"]+['\"]" "$CLEAN" 2>/dev/null
    grep -oE "import[[:space:]]+['\"]@/[^'\"]+['\"]"    "$CLEAN" 2>/dev/null
  } | grep -oE "@/[^'\"]+" | sort -u > "$TMP/imports" 2>/dev/null

  while read -r spec; do
    [ -n "$spec" ] || continue
    rel=${spec#@/}
    ok=""
    for cand in "$APPDIR/src/$rel"       "$APPDIR/src/$rel.js" \
                "$APPDIR/src/$rel.vue"   "$APPDIR/src/$rel/index.js" \
                "$APPDIR/src/$rel/index.vue"; do
      if [ -f "$cand" ]; then ok=1; break; fi
    done
    [ -n "$ok" ] || report ERR 0 \
      "import 的模块在本应用不存在：$spec → 找不到 $APP/src/$rel（打包会报模块找不到）" \
      "换成本应用真实存在的模块；三应用 mixin 差异见 references/conventions.md §八"
  done < "$TMP/imports"

  # ---------------- 通用：dcType ----------------
  awk -v F="$CURREL" '
  {
    line = $0; pos = 1
    while (pos <= length(line)) {
      p = index(substr(line, pos), "dcType=\"")
      if (p == 0) break
      abs = pos + p - 1
      before = (abs > 1) ? substr(line, abs - 1, 1) : ""
      if (before != ":") {                       # :dcType="变量" 是动态的，跳过
        rest = substr(line, abs + 8)
        q = index(rest, "\"")
        val = (q > 0) ? substr(rest, 1, q - 1) : ""
        printf "%s\t%s\t%s\n", F, NR, val
      }
      pos = abs + 8
    }
  }' "$CLEAN" > "$TMP/dct.txt"

  while IFS='	' read -r _f ln val; do
    [ -n "${val:-}" ] || {
      report ERR "$ln" 'dcType="" 是空的 → 该字段什么都不渲染' \
                      '要输入框就写 dcType="text"；要自定义内容就整个删掉 dcType（走默认插槽）'
      continue
    }
    grep -qxF "$val" "$LEGAL" && continue
    hint=""
    case "$val" in
      date)  hint='，这里应该写 dcType="datePicker"' ;;
      dict)  hint='，这里应该写 dcType="dictSelect"（表格列才用 dict）' ;;
      input) hint='，这里应该写 dcType="text"' ;;
    esac
    report ERR "$ln" "dcType=\"$val\" 不在本应用的合法值里 → 整行字段空白且不报错$hint" \
                    '合法值见 references/components.md 的 dcType 全表'
  done < "$TMP/dct.txt"

  # ---------------- 通用：dc-form 没有 @submit 事件 ----------------
  chk ERR '<dc-form[^>]*@submit' \
      'dc-form 没有 submit 事件（只 emit submitForm / cancelForm）→ 点保存没反应' \
      '改成 :clickButtonFlag="false" 自己渲染按钮 + this.$refs.xxx.validate()'

  # ---------------- 通用：裸 axios ----------------
  chk ERR 'axios[[:space:]]*\.[[:space:]]*(get|post|put|delete)[[:space:]]*\(' \
      '裸用 axios → 绕过了统一封装（token / 错误提示 / loading 全丢）' \
      '改用 @/axios 的 requestGet / requestPost'

  # ---------------- 通用：不该直接用的 Element 组件 ----------------
  chk WARN '<el-table'    '直接用了 <el-table> → 本应用惯例是 <dc-ft-table>'      '用 dc-ft-table 替代'
  chk WARN '<el-form'     '直接用了 <el-form> → 本应用惯例是 <dc-form>'          '用 dc-form 替代'
  chk WARN '<el-dialog'   '直接用了 <el-dialog> → 本应用惯例是 <dc-dialog>'      '用 dc-dialog 替代'
  chk WARN '<el-pagination' '直接用了 <el-pagination> → 分页由 dc-ft-table 自带' '用 dc-ft-table 的 @pageChange'

  # ---------------- 通用：脚手架示例还没换 ----------------
  # prop="tpCode" 全仓 0 处命中，是"这页还是脚手架"的可靠标记
  # （别用 prop="name"，真实代码里有 3 处，会误报）
  chk ERR 'prop[[:space:]]*=[[:space:]]*"tpCode"' \
      '这一页还是脚手架示例，字段名没换（tpCode / name / num / staSteCode / rmrk 都是示例）' \
      '换成后端接口里的真实字段名；dictCode="COP0109" / "COP0002" 也要换成真实字典码'

  # 占位符统一是 xxxModuleList / XxxModuleInfo 这种形状 —— 要求 xxx/Xxx 后面
  # 紧跟一个大写字母，避免把业务里的兜底字符串（:x="a ? a : 'xxxx'"）误判
  chk ERR '\bxxx[A-Z]|\bXxx[A-Z]' \
      '模板占位符没替换' '换成真实的组件名 / 接口方法名 / service 路径'

  # 生成的 service.js 里三条 URL 是给使用者填的，所以这里必然命中一次 ——
  # 单独报是为了给出能照着做的提示（并让"生成物一定带 1 处必改"这件事在文档里有据可查）。
  chk ERR 'CHANGE_ME' \
      'service.js 里的接口地址还是 CHANGE_ME 占位符 → 请求会打到一个不存在的地址' \
      '填上后端给的真实 URL（新增 / 修改 / 查询各一条）'

  # 需求里还没定的东西由 new-page.sh 标成这个字面量。它必须是唯一可 grep 的：
  # 仓库里本来就有 10 处裸 TODO 注释，按 TODO 判会连它们一起报。
  chk ERR 'TODO\(需求缺失\)' \
      '这一处标着「需求缺失」→ 字段名 / 字典码 / 接口地址还没确定，这块功能是空的' \
      '拿到需求后填上；本页确实不需要这块内容时，连同标记一起删掉（要的是你想过这件事）'

  # ---------------- 通用：httpService.Xxx 必须在本模块 service.js 里有导出 ----------------
  # 页面与 service.js 是同一份 spec 渲染出来的，名字本该对得上；对不上就是
  # 运行时报 "httpService.xxx is not a function"，或请求静默打到 undefined。
  if [ -n "$SERVICEJS" ]; then
    grep -oE 'httpService\.[A-Za-z0-9_]+' "$CLEAN" 2>/dev/null \
      | sed 's/^httpService\.//' | sort -u > "$TMP/svcuse"
    while read -r _m; do
      [ -n "$_m" ] || continue
      grep -qE "^[[:space:]]*$_m[[:space:]]*:" "$SERVICEJS" && continue
      report ERR 0 \
        "调了 httpService.$_m，但本模块 service.js 里没有这个名字（运行时报 xxx is not a function）" \
        '改成 service.js 里已有的接口名，或把它补进 service.js 的 api 与 export 两处'
    done < "$TMP/svcuse"
  fi

  # ---------------- 通用：<script> 里的花括号配平 ----------------
  # 「多贴 / 少贴一行」这类错误打包时才炸，而且报的位置常常指向别的文件。
  # 只数「{」与「}」的个数，不做语法分析：字符串与 ${} 插值里成对出现的括号不影响差值。
  if ! awk '
      /<\/script>/ { ins = 0; next }
      /<script/    { ins = 1; next }
      ins { o += gsub(/\{/, "{"); c += gsub(/\}/, "}") }
      END { exit (o == c) ? 0 : 1 }' "$CLEAN"; then
    report ERR 0 '<script> 里的花括号不配平（{ 与 } 数量不等）→ 语法错误，打包会失败' \
      '多半是贴字段 / 贴方法时多贴或少贴了一行，用编辑器的括号高亮从头对一遍'
  fi

  # ---------------- 通用：<script> 真的能解析吗 ----------------
  # 花括号配平只能抓最粗的错误：「对象字面量少一个逗号」之类配平完全正常，
  # 照样是语法错误、照样白屏。装了 node 就让它判（这个仓库要 node 才能构建，
  # 所以几乎总在）；没装就跳过，不假装查过。
  if command -v node >/dev/null 2>&1; then
    awk '/<\/script>/ { ins = 0; next } /<script/ { ins = 1; next } ins' "$CLEAN" > "$TMP/syntax.mjs"
    if [ -s "$TMP/syntax.mjs" ] && ! _serr=$(node --check "$TMP/syntax.mjs" 2>&1); then
      _sline=$(printf '%s\n' "$_serr" | sed -n 's/.*syntax\.mjs:\([0-9]*\).*/\1/p' | head -1)
      report ERR "${_sline:-0}" "<script> 不是合法 JS（node --check 报错）→ 打包才会炸，页面打不开" \
        "$(printf '%s' "$_serr" | awk 'NR <= 3' | sed "s|$TMP/||g" | tr '\n' ' ')"
    fi
  fi

  chk WARN "rowIdKey[[:space:]]*:[[:space:]]*'pyhid'" \
      "rowIdKey 是模板遗留的 'pyhid' → 确认接口返回的每行里真的有这个字段" \
      '不确定就改成真实主键字段名；它只影响多选表跨页勾选'

  # ---------------- List.vue ----------------
  # 只有「查询 + 表格」这种列表页才查下面这一整套。
  # 仓库里大量 *List.vue 是嵌在详情页里的选择器 / 子表（selectUsrList、imgList、
  # SelectedCityManagerList …），根本没有查询区，对它们报"缺少查询区"是误伤。
  # 判据：文件里出现了 <dc-form-table 或 <dc-search-form —— 这才是查询列表的骨架。
  if [ "${base%List.vue}" != "$base" ]; then
    islist=1
  else
    islist=0
    # ucp 的列表页就叫 index.vue（表单在 form/form.vue，走独立路由），
    # opr/fsc 没有 form/ 子目录、列表一律是 *List.vue —— 所以这里按 app 分流。
    if [ "$APP" = "cop-ucp-ui" ] && [ "$base" = "index.vue" ]; then
      { grep -q '<dc-ft-table' "$CLEAN" || grep -q '<dc-search-form' "$CLEAN"; } && islist=1
    fi
  fi
  if [ "$islist" = 1 ]; then
    if ! grep -q '<dc-form-table' "$CLEAN" && ! grep -q '<dc-search-form' "$CLEAN"; then
      report WARN 0 \
        '这个 List.vue 没有查询区骨架（既无 dc-form-table 也无 dc-search-form）→ 已跳过列表页严格检查' \
        '如果它本该是脚手架那种「查询 + 表格」页，说明两层容器被删掉了'
    else
      need '<dc-form-table'        '缺少 <dc-form-table> → 最外层不是它，查询区找不到表格，查询静默失效'
      need '<dc-search-form'       '缺少 <dc-search-form> 查询区'
      need '<dc-base-table-column' '没看到 <dc-base-table-column> 数据列'

      tl=$(grep -n -E -m1 '<dc-ft-table|<dc-table[ >]' "$CLEAN" 2>/dev/null | cut -d: -f1)
      if [ -z "${tl:-}" ]; then
        report ERR 0 '没找到 <dc-ft-table> 或 <dc-table> 表格标签'
      else
        head -n $((tl - 1)) "$CLEAN" > "$TMP/before"
        tail -n +"$tl"      "$CLEAN" > "$TMP/after"

        a=$(grep -o 'idKey="[^"]*"' "$TMP/before" 2>/dev/null | tail -1 | sed 's/idKey="//; s/"$//')
        b=$(grep -o 'idKey="[^"]*"' "$TMP/after"  2>/dev/null | head -1 | sed 's/idKey="//; s/"$//')

        [ -n "$a" ] || report ERR "$tl" '<dc-search-form> 上没写 idKey'
        [ -n "$b" ] || report ERR "$tl" '表格上没写 idKey'
        if [ -n "$a" ] && [ -n "$b" ] && [ "$a" != "$b" ]; then
          report ERR "$tl" "idKey 两边不一致：查询区 \"$a\"，表格 \"$b\" → 点查询没反应" \
                          '两边写成同一个值，仓库惯例是 multipleTable'
        fi
        # 表格上的 ref / :key 也是按应用区分的：
        #   opr/fsc 的表格 ref 一律是 multipleTable（59/51、29/30），且都有
        #   :key="reloadTable"；ucp 的表格 ref 惯例是 refTableList（27 处），
        #   :key="reloadTable" 只有 22/40 个页面有 —— 对 ucp 按 opr 的标准报，
        #   等于给 ucp 一半以上的列表页报必改项。
        if [ "$APP" = "cop-ucp-ui" ]; then
          grep -qE 'ref="[^"]+"' "$TMP/after" || report ERR "$tl" \
            '表格上没有 ref → 列设置、跨页勾选、表格高度全部失效'
        else
          grep -q 'ref="multipleTable"' "$TMP/after" || report ERR "$tl" \
            '表格上没有 ref="multipleTable" → 列设置、跨页勾选、表格高度全部失效'
          grep -q ':key="reloadTable"' "$TMP/after" || report ERR "$tl" \
            '表格上没有 :key="reloadTable" → 列显示/隐藏设置不生效'
        fi
      fi

        # 搜索对象名三应用不一样，不能一刀切：
        #   opr 33 个页面 / fsc 26 个页面用 searchFormData（searchCacheMixin 按这个名字
        #   存取缓存），ucp 则是 searchForm（29 个）多于 searchFormData（17 个）。
        #   拿 opr 的名字去要求 ucp 会对 ucp 的列表页整体误报。
        if [ "$APP" = "cop-ucp-ui" ]; then
          grep -qE 'searchForm(Data)?' "$CLEAN" || report ERR 0 \
            '没有搜索数据对象（ucp 惯例叫 searchForm）→ 查询条件传不出去，点查询等于查全表' \
            '在 data() 里写 searchForm: {}，查询区绑 :model="searchForm"'
        else
          need 'searchFormData' '数据字段名不是 searchFormData → 仓库惯例按这个名字存取（searchCacheMixin 依赖它），改名后搜索条件缓存恢复失效'
        fi
      need '@pageChange'    '没有绑 @pageChange → 翻页没反应'
      need '\bpageNum\b'    '请求参数里没有 pageNum（后端要的分页字段名）'
      need '\bparam\b'      '请求参数里没有 param（业务条件必须包在这一层里）'
      need 'tableMixins'    '没有引 tableMixins → 分页 / 跨页勾选 / 表格高度都要自己重写'
      # 成功码：拿本应用白名单现读的结果对（白名单见脚本开头）。
      # 两处分级不同，别一刀切 —— 查询回调和写回调能做的事不一样：
      #   · 文件里有写操作（XxxAdd / XxxUpdate / XxxDelete）→ 必改项：写回调
      #     要自己判码才谈得上返回值校验。
      #   · 只有查询的列表页 → 只提醒。查询回调**判不了码**：code 不在白名单里时
      #     requestPost 既不 resolve 也不 reject（见 src/axios/index.js 的 else 分支，
      #     只 hideLoading + authError），回调里一行都不会执行，写 if 是摆设。
      #     fsc 31 个列表页里 10 个就是这样，样板页 regionManageList 本身也是。
      #   · ucp 的 requestPost 无论成败都 resolve，本来就不判码，不报。
      if [ "$APP" != "cop-ucp-ui" ]; then
        _lvl=WARN
        grep -qE 'httpService\.[A-Za-z_]*(Add|Update|Delete|Save)\(' "$CLEAN" && _lvl=ERR
        if [ -n "$CODELIST" ]; then
          _hit=""
          for _c in $CODELIST; do
            grep -q "'$_c'" "$CLEAN" && { _hit=1; break; }
          done
          if [ -z "$_hit" ] && [ "$_lvl" = ERR ]; then
            report ERR 0 \
              "没有成功码判断（本应用白名单：$CODELIST）→ 写回调拿到什么都不校验，失败也会当成功用" \
              '照邻近页面写 if (res.code === 白名单里的某个值)；见 pitfalls.md P1'
          elif [ -z "$_hit" ]; then
            report WARN 0 \
              "查询回调里没有成功码判断（本应用白名单：$CODELIST）→ code 不在白名单里时 requestPost 不 settle，页面停在 loading" \
              '本页没有写操作，查询回调里补 if 也没用（失败时它根本不会执行）—— 排查要看 src/axios/index.js 的 requestPost'
          fi
        else
          need 'S000000' "没有成功码判断 'S000000'"
        fi
      fi

      chk ERR 'handleSizeChange|handleCurrentChange' \
          '用了 el-pagination 的翻页事件 → dc-ft-table 只对外暴露 @pageChange' \
          '改成 @pageChange="pageChange"（方法由 tableMixins 提供，不用自己写）'

      # searchCacheMixin 只有 opr/fsc 有（ucp 的 src/mixins 里没有这个文件），
      # 对 ucp 报「没有 searchCacheOptions」是纯误报。
      if [ -f "$APPDIR/src/mixins/searchCacheMixin.js" ]; then
        grep -q 'searchCacheOptions' "$CLEAN" || report WARN 0 \
          '没有 searchCacheOptions.pageKey → 搜索条件不会被记住'
      fi
    fi
  fi

  # ---------------- Info.vue / ucp 的 form/form.vue ----------------
  isform=0
  [ "${base%Info.vue}" != "$base" ] && isform=1
  # ucp 没有 Info.vue，表单在 form/form.vue（全仓 form/ 子目录 8 个，全在 ucp）
  if [ "$APP" = "cop-ucp-ui" ] && [ "$base" = "form.vue" ]; then isform=1; fi
  if [ "$isform" = 1 ]; then
    grep -q ':clickButtonFlag="false"' "$CLEAN" || report WARN 0 \
      'dc-form 没有 :clickButtonFlag="false" → 会多出一行组件自带的按钮行' \
      '关掉它，自己渲染「返回 / 保存」'
    # 套容器这条只对 *Info.vue 报：ucp 全族的 form/form.vue 都套 dc-card，是 ucp 的惯例
    if [ "${base%Info.vue}" != "$base" ] \
       && { grep -q '<dc-form-table' "$CLEAN" || grep -q '<dc-card' "$CLEAN"; }; then
      report WARN 0 '表单页外面套了 dc-form-table / dc-card' '仓库惯例是表单页不套这两层'
    fi
    if grep -q 'verifyRule\.' "$CLEAN"; then
      grep -qE 'verifyRule[[:space:]]*[,:]' "$CLEAN" || report ERR 0 \
        '模板里用了 verifyRule.xxx，但 verifyRule 没放进 data → 校验规则是 undefined，校验静默失效' \
        '在 data() { return { verifyRule, ... } } 里加上它'
    fi
  fi

  # ---------------- index.vue ----------------
  # 只有「列表 + 表单」容器模式才查这些。
  # 仓库里 index.vue 大量是普通页面（41/74），对它们查 @jump/@back 是纯误报。
  # 判据：同目录下有 components/*List.vue —— 这才是脚手架生成的那种容器。
  if [ "$base" = "index.vue" ]; then
    is_container=0
    for _sib in "$(dirname "$f")"/components/*List.vue; do
      [ -f "$_sib" ] && is_container=1 && break
    done
    if [ "$is_container" = 1 ]; then
      # 标签属性可以换行写，不能要求 <component 和 :is= 在同一行
      if ! grep -q '<component' "$CLEAN" || ! grep -q ':is=' "$CLEAN"; then
        report WARN 0 '容器里没看到 <component :is="params.where">'
      fi
      need '@jump' '容器没接 @jump → 列表切不到表单'
      need '@back' '容器没接 @back → 表单回不到列表'
      need 'components[[:space:]]*:' '容器没有注册子组件'
    fi
  fi
}

# ---------------------------------------------------------------------------
# 遍历
# ---------------------------------------------------------------------------
if [ -n "$FILELIST" ]; then
  check_file "$FILELIST"
else
  # .vue 和 .js 都要查 —— service.js 里最容易漏的就是没换掉的 CHANGE_ME URL
  find "$START" \( -name '*.vue' -o -name '*.js' \) -type f | sort > "$TMP/files"
  if [ ! -s "$TMP/files" ]; then
    printf '❌ %s 下没有 .vue / .js 文件\n' "$TARGET"; exit 2
  fi
  while IFS= read -r f; do check_file "$f"; done < "$TMP/files"
fi

NFILE=$(grep -c . "$TMP/files" 2>/dev/null || echo 1)
[ -n "$FILELIST" ] && NFILE=1

# ---------------------------------------------------------------------------
# 残留检查（WARN）：相对引用伸出了本模块目录
# ---------------------------------------------------------------------------
# 骨架是从样板页克隆来的，最常见的残留就是页里还引用着样板模块旁边的兄弟文件：
#   · 指向别的模块的文件 → 打包报「模块找不到」
#   · 指向样板模块自己的逻辑 → 更糟：能跑，但跑的是别的模块的代码
# 只查相对引用（'./x' / '../x'）。**@/… 一律不查**：本仓的域级共享模块
# （<域>/service/service.js、<域>/components/xxx.vue、<域>/mixins/xxx.js）
# 就是被各模块跨目录引用的，查它会全量误报。
# 按 WARN 输出、不阻断：脚本分不清某个名字是你有意的还是样板带过来的
# （见 references/cloning.md §1）。
# ---------------------------------------------------------------------------
residue_scan() {
  [ -d "$START" ] || return 0
  for f in $(find "$START" \( -name '*.vue' -o -name '*.js' \) -type f | sort); do
    clean_comments "$f" > "$CLEAN" 2>/dev/null || continue
    specs=$(
      {
        grep -oE "from[[:space:]]*['\"]\.\.?/[^'\"]*"      "$CLEAN"
        grep -oE "require\([[:space:]]*['\"]\.\.?/[^'\"]*" "$CLEAN"
        grep -oE "import[[:space:]]+['\"]\.\.?/[^'\"]*"    "$CLEAN"
      } 2>/dev/null | grep -oE "['\"]\.\.?/[^'\"]*" | sed "s/^['\"]//" | sort -u
    )
    for spec in $specs; do
      _d=$(cd "$(dirname "$f")" 2>/dev/null && cd "$(dirname "$spec")" 2>/dev/null && pwd) || continue
      case "$_d/" in "$START"/*) continue ;; esac
      CURREL=${f#"$APPDIR"/}
      report WARN 0 "相对引用伸出了本模块目录：$spec（→ ${_d#"$APPDIR"/}）" \
        '样板页带过来的残留：这个引用指的是别的模块，克隆出来的页面会引到没建的目录。确认后删掉或改成 @/… 的公共模块'
    done
  done
}
residue_scan

# ---------------------------------------------------------------------------
# 内容出处检查（ERR，只在给了 --spec 时跑）
#
# 判据是**可计算的一条**：产物里承载业务含义的标识符，必须都能在需求 spec 里找到 ——
# 找不到，就说明它是样板页带过来的，而不是需求要的。抽的是这五类（就是 business content
# 真正落地的位置）：
#   · prop="X"                   字段名（搜索项 / 表格列 / 表单项）
#   · dictCode="X" / 'X'         字典码
#   · cachePageKey="X" / pageKey 列表页唯一标识
#   · searchFormData.X / formData.X / searchForm.X   数据键
#
# **盲点（不假装全覆盖）**：方法体里的业务条件（scope.row.staSteCode === '2'、
# roleCodes: ['JS00002'] 这种）不是上面任何一类，抽不出来；对象字面量的键
# （data() 里 { a: '', b: '' }）也没抽。这两处只能靠人看 —— 见 references/cloning.md。
# ---------------------------------------------------------------------------
provenance_scan() {
  [ -n "$SPEC" ] || return 0
  [ -d "$START" ] || return 0
  for f in $(find "$START" \( -name '*.vue' -o -name '*.js' \) -type f | sort); do
    clean_comments "$f" > "$CLEAN" 2>/dev/null || continue
    CURREL=${f#"$APPDIR"/}
    : > "$TMP/prov"
    grep -oE 'prop="[^"]+"'          "$CLEAN" 2>/dev/null | sed 's/^prop="//; s/"$//'              >> "$TMP/prov"
    grep -oE 'dictCode="[^"]+"'      "$CLEAN" 2>/dev/null | sed 's/^dictCode="//; s/"$//'          >> "$TMP/prov"
    grep -oE "dictCode:[[:space:]]*'[^']+'" "$CLEAN" 2>/dev/null | sed "s/^dictCode:[[:space:]]*'//; s/'\$//" >> "$TMP/prov"
    grep -oE 'cachePageKey="[^"]+"'  "$CLEAN" 2>/dev/null | sed 's/^cachePageKey="//; s/"$//'      >> "$TMP/prov"
    grep -oE "pageKey:[[:space:]]*'[^']+'" "$CLEAN" 2>/dev/null | sed "s/^pageKey:[[:space:]]*'//; s/'\$//" >> "$TMP/prov"
    grep -oE '(searchForm|searchFormData|formData)\.[A-Za-z0-9_]+' "$CLEAN" 2>/dev/null \
      | sed 's/^[A-Za-z]*\.//'                                                                      >> "$TMP/prov"
    sort -u "$TMP/prov" > "$TMP/prov.uniq"; mv "$TMP/prov.uniq" "$TMP/prov"
    while IFS= read -r _id; do
      [ -n "$_id" ] || continue
      grep -qwF "$_id" "$SPEC" && continue
      report ERR 0 "「$_id」不在需求 spec 里 → 这个字段名 / 字典码 / 键来自样板页，不是需求要的" \
        '要么把它补进 spec，要么从页面里去掉；spec 语法见 references/page-spec.md'
    done < "$TMP/prov"
  done
}
provenance_scan

# 计数以 findings 文件为准（report 可能在子 shell 里被调用，累加值会丢）
NERR=$(grep -c '^ERR' "$TMP/findings" 2>/dev/null || true)
NWARN=$(grep -c '^WARN' "$TMP/findings" 2>/dev/null || true)

# ---------------------------------------------------------------------------
# 路由有没有挂上
# ---------------------------------------------------------------------------
NOTE=""
if [ -d "$START" ]; then MODDIR=$START; else MODDIR=$(dirname "$START"); fi
RELVIEW=${MODDIR#"$APPDIR"/}
case "$RELVIEW" in
  src/views/*/*)
    DOM=$(printf '%s' "$RELVIEW" | awk -F/ '{ print $3 }')
    MOD=$(printf '%s' "$RELVIEW" | awk -F/ '{ print $4 }')
    RF=""
    [ -f "$APPDIR/src/views/$DOM/$DOM-router.js" ] && RF="$APPDIR/src/views/$DOM/$DOM-router.js"
    [ -f "$APPDIR/src/views/$DOM/$DOM.js" ]        && RF="$APPDIR/src/views/$DOM/$DOM.js"
    if [ -n "$RF" ] && ! grep -q "\./$MOD/index\.vue" "$RF"; then
      NOTE="⚠️  路由未挂：$DOM/$(basename "$RF") 里没有 './$MOD/index.vue'
    后端菜单的 menuUrl 需要是 /$DOM/$MOD/index"
    fi
    ;;
esac

# ---------------------------------------------------------------------------
# 输出
# ---------------------------------------------------------------------------
printf '\n应用 %s   合法 dcType %s 个   检查文件 %s 个\n\n' "$APP" "$NLEGAL" "$NFILE"

if [ ! -s "$TMP/findings" ]; then
  printf '✅ 全部通过，没有发现问题。\n'
else
  sort -t'	' -k2,2 -k3,3n "$TMP/findings" | while IFS='	' read -r lvl file ln msg fix; do
    if [ "$lvl" = ERR ]; then printf '❌ %s' "$file"; else printf '⚠️  %s' "$file"; fi
    [ "${ln:-0}" -gt 0 ] 2>/dev/null && printf ':%s' "$ln"
    printf '\n   %s\n' "$msg"
    [ -n "${fix:-}" ] && printf '   → %s\n' "$fix"
    printf '\n'
  done
  printf '小结：❌ 必须修 %s 项   ⚠️ 确认一下 %s 项\n' "$NERR" "$NWARN"
fi

if [ -z "$SPEC" ]; then
  printf '\n注：没给 --spec，「内容出处」未校验 —— 产物里的字段名 / 字典码 / pageKey\n'
  printf '    没有跟需求对过，可能还带着样板页的东西。加上 --spec <spec文件> 再跑一次。\n'
fi

[ -n "$NOTE" ] && printf '\n%s\n' "$NOTE"
printf '\n细节说明见 .claude/skills/cop-frontend-dev/references/pitfalls.md\n\n'

[ "$NERR" -gt 0 ] && exit 1
exit 0
