# Observation Analysis Prompt

生成纯数据报告，不加推断。

## 执行清单

1. **统计** → `statistics.md`
   ```bash
   echo "总文件: $(find <src_dir> -name '*.vue' -o -name '*.ts' | wc -l)"
   echo "总行数: $(find <src_dir> -name '*.vue' -o -name '*.ts' | xargs cat | wc -l)"
   ```

2. **组件使用** → `component-usage.md`
   列出每个组件的引用次数、与上次对比的趋势

3. **API 使用** → `api-usage.md`
   每个 API 模块的文件数、函数数

4. **重复代码** → `duplicate-code.md`
   用 `grep -r` 搜索相似片段（可选，大项目跳过）

5. **死代码** → `dead-code.md`
   搜索零引用组件、注释超过 20 行的代码块

## 输出
按分析结果动态创建 observations/ 目录下的文件。只记录数字和事实，不做推断。
