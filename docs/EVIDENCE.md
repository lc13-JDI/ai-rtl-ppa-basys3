# 证据定位与整理记录

本页用于追溯事实，招聘技术附件保持约两页篇幅。原课程目录仅只读访问。

## 指标与来源

| 内容 | 公开证据 | 原提交对应位置 |
|---|---|---|
| 1486/2089 LUT，312/322 FF，1/3 DSP | `reports/*/utilization.rpt` 和 `utilization_hierarchical.rpt` | `vivado_ai_compare_reports/*/` 同名文件 |
| +0.068/−46.225 ns WNS，0/59 setup 失败端点 | `reports/*/timing_summary.rpt` 的 Design Timing Summary | 同上；Design State 为 Synthesized |
| 三模块层次资源 | `reports/*/utilization_hierarchical.rpt` | 同上 |
| AI 蜂鸣器 55.488 ns、140 级逻辑、111 CARRY4 | `reports/ai_draft/setup_paths.rpt` 第一条路径 | 同上 |
| 相同顶层、器件、XDC，只替换三个模块 | `scripts/run_synth_case.tcl` | 改编自 `vivado_ai_compare_reports/run_synth_case.tcl` |
| LCG、取模、变量除法与最终实现 | `ai_drafts/`、`rtl/` 同名三个文件 | 字节不变，见 manifest |
| 最终版实现后 WNS +0.473、WHS +0.087 ns | `assets/post_route_timing.png` | `report.pdf` 第20页图19嵌入图片 |
| 最终版 RESULT 实板显示 0226 ms | `assets/board_result.jpg` | `report.pdf` 第22页图21嵌入图片 |
| 功能仿真与实板记录 | 四个 `sim/*.v`；README 视频链接 | 原报告第15–18、22–24页；视频链接位于第30页 |

PDF 页号按文件页序计，恰与报告正文页码一致。两图从 PDF 原样提取，未重新绘制。报告文末链接去掉了 `vd_source` 和评论定位片段，保留同一 BV 号；未声称已完整观看视频。网页抓取工具未能访问 Bilibili 页面。

## 解释数据时的限制

- 三个模块同时替换，层次资源随顶层优化归属变化，无法当作三个独立受控实验。
- 没有单模块 WNS；综合阶段尚未放置布线，其 route delay 为估计值。
- 没有功耗测量，故本展示实测指标限于 FPGA 资源与时序。
- 实现后截图属于最终版；未保存相应文本报告、checkpoint 或 AI 替换版实现结果。
- AI 初稿只证明接口接入并完成综合，不等于完整功能正确或与最终版等价。随机数算法、蜂鸣器同周期事件优先级不同，不能声称进行了严格等价优化。
- `score_history` AI 初稿使用变量除数，但本例 LUT 更少；最终版显式分支便于解释边界，不可称其已改善本模块面积。
- 最终随机映射为 `500 + floor(lfsr[12:0] × 4501 / 8192)`，范围为 500–5000 ms，未做随机分布质量或不可预测性测试。
- 原 testbench 部分输入在 `posedge` 上用阻塞赋值驱动，可能与 DUT 竞争；保持原样以便追溯。蜂鸣器测试降低 `CLK_FREQ_HZ` 加速仿真；不能外推已精确测量全部音调频率和事件优先级。
- `check_timing` 报告列出 no_input_delay=2、no_output_delay=42，不将正 WNS 表述为完整外部接口签核。
- 未保留 AI 提示词、模型版本、生成记录；没有开发耗时、模型准确率或效率收益的量化实验。

## 整理时的变更

RTL、AI 初稿、XDC、testbench 保持逐字节一致。删除的是展示副本中的工程产物选择，不涉及原目录。8 份公开报告副本只处理 Host 行、Command 中的绝对输出根路径和换行，未改动指标、设计名、时间、版本和版权。`source_manifest.json` 保存原件和公开件 SHA-256。复现脚本根据原综合／工程重建 Tcl 改编，新增 Python 指标提取和仿真日志检查。

## 2026-10-15 本地整理验证

- 原件与公开副本指标解析一致：通过；顶层和三模块 LUT / FF / DSP 及顶层时序指标均核对。
- 来源 SHA-256 与公开副本匹配：通过；原课程目录全文件哈希前后相同。
- Python 三个入口语法解析：通过；报告提取实际运行成功，CSV / JSON 正常生成。
- 综合 Tcl 的路径和模块选择：使用 Tcl 命令桩检查 baseline / ai_draft，各选择 11 个且无重名 RTL，通过。此检查不执行 EDA 综合。
- 本机未安装 Vivado / XSim、Icarus Verilog；两种仿真入口均按预期报告缺失依赖并退出 2，没有产生功能通过记录。
- 本次没有重新执行综合、布局布线或实板实验。历史实验与本次整理检查分开记录。
- 公开内容扫描未发现凭据、联系方式、学号、原主机名或绝对个人目录；两张图片已目视检查。来源文件哈希留存在 manifest，便于与原件核对。
