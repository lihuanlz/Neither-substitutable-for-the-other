# Neither substitutable for the other

[![CI](https://github.com/lihuanlz/Neither-substitutable-for-the-other/actions/workflows/ci.yml/badge.svg)](https://github.com/lihuanlz/Neither-substitutable-for-the-other/actions/workflows/ci.yml)
[![Lean 4](https://img.shields.io/badge/lean-4.15.0-blue.svg)](https://github.com/leanprover/lean4/releases/tag/v4.15.0)

**人机协同条件下，人与机器的作用都不可替代。**

形式化载体：Lean 4 + Mathlib，**153 条定理 + 20 个实例**，零 `sorry`、零公理。
其中主线（不可替代性）117 条，碎片化侧题 19 条，语料筛选 17 条。

> Two operations, two objects. A machine compresses; a human refines. There is
> no exchange rate between them — not because nobody has found one yet, but
> because the two move quantities that no single currency can hold.

---

## 这个仓库在说什么

人们习惯把"AI 贡献了多少"换算成一个百分比。这个换算预设了人机在同一
种货币里记账。形式化的结果是：**这个预设不成立。**

论文里唯一的一组"两种货币"（式 1）：

| | 动的东西 | 有没有上限 |
|---|---|---|
| 人类做**精炼 refinement** | 目标本身 \(\Phi(\alpha)\)，即层 | 无上限 |
| 机器做**压缩 compression** | 编码熵 \(e_t^\alpha\) | 硬上界 \(\log(e_0/\Phi(\alpha))\) |

压缩的天花板只由层决定，与步数无关；精炼可以把层推到任意远。
方向相反、量纲不同，所以没有换算率。

> A machine that compresses perfectly has not moved the target.
> A human who refines perfectly has not closed the distance.

---

## 三层结论

### 第 1 层 · 内容层 —— 事后溯源能识别到什么程度

最优检测优势 \(=\mathrm{TV}/2\)，错误率 \(=(1-\mathrm{TV})/2\)，且这个界**可取到**。
所以瓶颈不是"检验不够好"，而是 TV 本身。

重复验证也压不下去，因为存在一个 **TV 地板**：

```
漏检率(N) = max( (1−q)^N , λ·TV )
```

于是最优验证预算 \(N^\star\) 有与人的准确率 \(p\) **无关**的硬上界。

### 第 2 层 · 系统层 —— 事前定价为什么做不了

影响力不能代理价值：`influence_value_separable` 构造出影响力绝对值相同、
价值一正一负、且幅度 \(M\) 任意大的两条输出。用信息增益代理价值的方案在
数学上失效。

不可通约性要分两个区间说：

- **TV 地板 bind**（\(T \ge x_c\)）：完全不可通约，两个不同可靠度的人给出
  **完全相同**的 \(N^\star\)；
- **地板不 bind**：可通约但非线性（保序、非仿射），故不落在线性效用 \(\mathcal U\) 里。

准确的说法是"**不可线性换算**"，不是"完全不可通约"——后者过强，会被 Lean 判死。

### 第 3 层 · 标定层 —— 连符号都不是测出来的

用文献里最通行的"最小必要人类贡献"估计量 \(\hat\varphi = 1 - \bar\tau/\bar s\)。
主定理 `sign_not_identified`：对任意一个输出，**都存在两组标定使符号取相反值**
（见证钉死为 \(\tau = s/2\) 与 \(\tau = 3s/2\)）。

门槛 \(\tau\) 恰恰是分布外拟合的，所以：

> 表面符号是标定的产物，不是测量的产物。

### 侧题 · 碎片化

上面三层回答的是"是什么"。`Provenance.Fragmentation` 换了一个问题：
**人机协同下，人的创新会规模化，还是会碎片化？**
这是独立课题，结论是**碎片化**，两截机制：
**协作侧（内生）** —— 在同一层上，协作体达成的层移动**等于其中最好那个人的层移动**。
第 N+1 个人的收益精确为 0，成本精确为 \(\log(\Phi/a)\)：

```lean
theorem marginal_agent_pure_waste ...
  : gain Φ (insert a D) _ = gain Φ D hD          -- 收益不变
    ∧ totalIndividual Φ (insert a D) = ... + log (Φ / a)   -- 成本严格增加
```

**时间侧（外生）** —— 把增量攒着不发，等的是一个会被盖掉的窗口。覆盖是吸收的，
所以持有收益**单调不增**（`holdValue_antitone`）；一旦被盖掉，收益精确归零
（`publish_dominates_when_covered`）。

两截合起来（`fragmentation_squeeze`）堵死通往"大故事"的两条常规路径。
**唯一的出口是换一个新的层** —— 而那正是 `human_gain_unbounded` 证过的无上界空间：

> 大故事赚的是时间差，而时间差正是 AI 唯一拿走的东西。

与主线的接口在 `saturation_duality`：AI 的收益**与步数无关**有硬上界
（`ai_total_gain_bounded`），人的收益**与人数无关**也有硬上界
（`marginal_agent_pure_waste`）。两边同时饱和 —— 不是谁替代谁，而是谁都加不上去。

**可证伪点**：该模块把协作建模为"取最好成员"（`max` 型）。若现实中两人协作
确实能超过其中较好的一人，`add_member_same_reach` 立刻失败。这是本课题最容易被
现实推翻的地方，写成定理而不是留给直觉。

### 侧题 · 语料即筛选

`Provenance.Corpus` 问第三个问题：**语料越滚越大，筛选能力会跟着涨吗？**
答案是不会，而且它和碎片化共用同一个 `max`/`min` 对称结构 ——
人数饱和在**最好的人**身上，语料饱和在**最好的一条**身上。

认证地板 `floorOf D = D.min'`（只认最好的那一条），于是：

- **稀释不变性**：`floorOf (D₁ ∪ D₂) = min (floorOf D₁) (floorOf D₂)`。
  99 条噪声 + 1 条信号，与那 1 条信号本身认证到的东西**完全一样**
  （`selection_filter_survives_dilution`）
- **换语料零收益**：不把地板压低就换语料，收益精确为 0
  （`uninformative_corpus_gains_nothing`）
- **地板定上界**：`floor_determines_bound` 说两条认证到同一地板的语料，
  不管规模、成分、新旧程度，一律不可区分

**刻意没有形式化的两件事**（和 \(\Phi>0\) 那条焊点同性质，写进了 §8）：
articulability（默会知识过滤器在类型层根本表达不出来）、语料是 stream 而非 set
（recency 与重加权都建模不了）。这两个缺口和 \(\Phi>0\) 一样，是留下来的焊点，
不是遗漏。

### 关键数字

- 标定自 2,500 条 WildChat prompt；1,500 对中 95.9% 可分
- \(T = 0.09\)（\(\lambda=1\), TV=0.09, q=0.5）时：\(N_c = 3.793\)、\(N_0 = 3.474\)，
  **83.97% 的参数组由地板起约束**
- \(\bar s = 0.50\)；Llama-3 \(\bar\tau = 0.5496 \to -0.099\)；Mixtral \(\bar\tau = 0.4155 \to +0.169\)
- 公理审计：153 条声明全部解析，只依赖 `Classical.choice` / `Quot.sound` / `propext`，零 `sorryAx`

---

## 目录结构

```
Provenance.lean          总入口（模块导览 + 复现说明）
.github/workflows/ci.yml GitHub Actions：构建 + 公理审计 + 一致性检查
tools/audit_axioms.py    153 条定理的公理依赖审计（CI 关卡）
tools/sync_refs.py       从 manuscript.md 生成 docx 的参考文献块（防漂移）
tools/strip_bom.py       清掉 Python 源码的 UTF-8 BOM（ast.parse 需要）
Provenance/              11 个 Lean 模块（+ Examples 对拍）
  Basic.lean             全变差距离、检验最优性、不可识别性
  Contamination.lean     TV 混合定理、递归污染的指数律、坍缩上界
  Coverage.lean          覆盖函数、次模性、单样本边际增益
  HypothesisTest.lean    集合形式 TV 定理 + Neyman–Pearson 功效上界
  Refinement.lean        观测层等价类 [s*]_α，两种货币的形式化
  Value.lean             影响力与价值的可分离性
  VerifyBudget.lean      TV 地板下的最优验证预算 N*
  Incommensurable.lean   不可线性换算（分区间）
  Calibration.lean       标定不可识别性：符号不由数据决定
  Fragmentation.lean     侧题：碎片化 —— 加人不加收益，等待收益单调不增
  Corpus.lean            侧题：语料即筛选 —— 稀释不变性与选择过滤上限
  Examples.lean          精确有理数实例对拍

paper/
  manuscript.md          正式论文原始稿（事实基准，全程未被改写）
  human_value.md         图解长文（面向普通读者）
  final_check.py         对 manuscript.md 的一致性检查
  verify_dois.py         23 条参考文献的 DOI 在线校验（16/16 通过）
  figures/               Figure 1–7（PNG + PDF），anime/ 为 AI 生成科普插画
  docx_build/            Word/PDF 生成工程
    content.py             论文正文与参考文献（唯一编辑入口）
    render_eqs.py          LaTeX → 600 dpi PNG，渲染 12 条公式
    make_figs_en.py        重生成英文版 Figure 4/5（色盲安全配色）
    make_figs_saturation.py 新增 Figure 6/7：人数饱和、语料饱和
    polish.py              ASCII → 正式排版符号
    emit_json.py           content.py → content.json
    assets_eq/             12 条公式的最终 PNG（已跟踪）
    eq/                    LaTeX 中间产物（已忽略，可重新生成）
    Gen/                   C# + OpenXML SDK 生成器
    preview/               DOCX 逐页预览
    Non-detection_is_not_absence.docx / .pdf
  slides/                22 页科普 PPT 工程（python-pptx）
    assets/                图表
    output/                PPTX + PDF + 22 张逐页预览
  refcheck/              第三方论文 PDF —— **故意不推送**，见下
```

---

## 复现

### Lean 证明

需要 [Elan](https://github.com/leanprover/elan)：

```powershell
lake build
```

工具链见 `lean-toolchain`（`leanprover/lean4:v4.15.0`），依赖见 `lake-manifest.json`。
`.lake/` 不在本仓库中，首次构建会拉取 Mathlib，耗时较长。

### Word / PDF 论文

```powershell
cd paper\docx_build
python render_eqs.py        # LaTeX 渲染 12 条公式 → assets_eq/*.png
python make_figs_en.py      # 重生成英文 Figure 4/5
python make_figs_saturation.py  # 新增 Figure 6/7
python ..\..\tools\sync_refs.py  # 从 manuscript.md 同步参考文献（先跑）
python polish.py            # ASCII → 正式排版符号
python emit_json.py         # content.py → content.json
dotnet run --project Gen -- content.json out.docx
soffice --headless --convert-to pdf --outdir . out.docx
```

依赖：Python + matplotlib、`MiKTeX`（`pdflatex`）、.NET SDK 9 + `DocumentFormat.OpenXml 3.1.0`、LibreOffice。

### 一致性检查

```powershell
cd paper
python final_check.py      # 16 项：数字、定理数、引用编号、模块数
python verify_dois.py      # 23 条参考文献的 16 个 DOI 在线校验
```

```powershell
python tools\audit_axioms.py   # 153 条定理的公理依赖审计
```

### CI

每次推送到 `main` 以及每个 PR，GitHub Actions 会自动跑三件事：

1. `lake build` —— 用 [leanprover/lean-action](https://github.com/leanprover/lean-action) 装工具链、拉 Mathlib 缓存、编译全部证明
2. `tools/audit_axioms.py` —— 对全部 153 条声明生成 `#print axioms`，确认只依赖 `Classical.choice` / `Quot.sound` / `propext`，且零 `sorryAx`
3. `paper/final_check.py` + `paper/verify_dois.py` —— 正文一致性与 DOI 在线解析

第 2 条是关键：`lake build` 通过只说明内核接受了证明，公理审计才能挡住一个悄悄被 `sorry` 削弱的主张。

---

## 为什么 `paper/refcheck/` 没有推送

该目录存放的是**其他作者已发表论文的原文**（Xie et al., ACL 2026；
Dorner et al., arXiv 2507.12399；Li et al., arXiv 2603.29121；以及两个 Zenodo 镜像）。
它们只是本地下载来核对 `paper/manuscript.md` 里每一条引用是否与原文一致的。

把它们放进 public 仓库等于再分发受版权保护的材料，因此**按版权原因排除，
不是按体积排除**。需要自己按 DOI 取用；`verify_dois.py` 走网络校验，不依赖本地副本。

## License

尚未选择。论文正文的著作权保留；代码部分的授权待定。
