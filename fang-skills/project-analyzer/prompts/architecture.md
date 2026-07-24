# Architecture Analysis Prompt

使用模板：[templates/Architecture.md](../templates/documents/Architecture.md)

## 执行清单

### 1. 技术栈（读 package.json）
```bash
cat package.json | python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'{k}: {v}') for k,v in d.get('dependencies',{}).items() if any(w in k for w in ['vue','react','angular','vite','webpack','pinia','redux','element','antd','ant-design','mui','axios','echarts','i18n','qiankun'])]"
```
从结果提取关键依赖和版本。

### 2. 目录结构
```bash
find . -maxdepth 2 -type d ! -path '*/node_modules/*' ! -path '*/.git/*' ! -path '*/dist/*' | sort
```
标注每层目录用途。若存在多层架构（框架层+业务层），注明层级关系。

### 3. 模块列表
扫描页面/视图目录的一级子目录，每个视为一个业务模块：
```bash
for d in $(ls -d <views_dir>/*/); do echo "$(basename $d): $(find $d -name '*.vue' -o -name '*.tsx' -o -name '*.ts' -o -name '*.js' | xargs cat 2>/dev/null | wc -l) lines"; done | sort -t: -k2 -rn
```
标注前 5 大模块。

### 4. 状态管理
列出 store 目录下所有文件，标注名称、路径、职责。

### 5. 路由
搜索路由配置文件（`router/`、`routes/`），提取路由树、守卫、懒加载模式。

### 6. 风险
- 搜索循环依赖
- 标注超大规模模块（>整体 15%）
- 标注未使用的 store

## 输出
填充 Architecture.md 模板，技术栈用表格，模块用排序列表，风险用 🔴🟡🟢 标记。
