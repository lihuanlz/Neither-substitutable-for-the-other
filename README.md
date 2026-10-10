# Neither substitutable for the other

**人机协同条件下，人与机器的作用都不可替代。**

形式化载体：Lean 4 + Mathlib，117 条定理 + 20 个实例，零 `sorry`、零公理。

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

### 关键数字

- 标定自 2,500 条 WildChat prompt；1,500 对中 95.9% 可分
- \(T = 0.09\)（\(\lambda=1\), TV=0.09, q=0.5）时：\(N_c = 3.793\)、\(N_0 = 3.474\)，
  **83.97% 的参数组由地板起约束**
- \(\bar s = 0.50\)；Llama-3 \(\bar\tau = 0.5496 \to -0.099\)；Mixtral \(\bar\tau = 0.4155 \to +0.169\)
- 构建：2,532 / 2,533 个 target

---

## 目录结构

```
Provenance.lean          总入口（模块导览 + 复现说明）
Provenance/              9 个 Lean 模块
  Basic.lean             全变差距离、检验最优性、不可识别性
  Contamination.lean     TV 混合定理、递归污染的指数律、坍缩上界
  Coverage.lean          覆盖函数、次模性、单样本边际增益
  HypothesisTest.lean    集合形式 TV 定理 + Neyman–Pearson 功效上界
  Refinement.lean        观测层等价类 [s*]_α，两种货币的形式化
  Value.lean             影响力与价值的可分离性
  VerifyBudget.lean      TV 地板下的最优验证预算 N*
  Incommensurable.lean   不可线性换算（分区间）
  Calibration.lean       标定不可识别性：符号不由数据决定
  Examples.lean          精确有理数实例对拍

paper/
  manuscript.md          正式论文原始稿（事实基准，全程未被改写）
  human_value.md         图解长文（面向普通读者）
  final_check.py         对 manuscript.md 的 16 项一致性检查
  verify_dois.py         18 条参考文献的 DOI 在线校验（12/12 通过）
  figures/               Figure 1–6（PNG + PDF），anime/ 为 AI 生成科普插画
  docx_build/            Word/PDF 生成工程
    content.py             论文正文与参考文献（唯一编辑入口）
    render_eqs.py          LaTeX → 600 dpi PNG，渲染 11 条公式
    make_figs_en.py        重生成英文版 Figure 4/5（色盲安全配色）
    polish.py              ASCII → 正式排版符号
    emit_json.py           content.py → content.json
    assets_eq/             11 条公式的最终 PNG（已跟踪）
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
python render_eqs.py        # LaTeX 渲染 11 条公式 → assets_eq/*.png
python make_figs_en.py      # 重生成英文 Figure 4/5
python polish.py            # ASCII → 正式排版符号
python emit_json.py         # content.py → content.json
dotnet run --project Gen -- content.json out.docx
soffice --headless --convert-to pdf --outdir . out.docx
```

依赖：Python + matplotlib、`MiKTeX`（`pdflatex`）、.NET SDK 9 + `DocumentFormat.OpenXml 3.1.0`、LibreOffice。

### 一致性检查

```powershell
cd paper
python final_check.py      # 16 项：数字、定理数、引用、构建目标
python verify_dois.py      # 18 条参考文献的 DOI 在线校验
```

---

## 为什么 `paper/refcheck/` 没有推送

该目录存放的是**其他作者已发表论文的原文**（Xie et al., ACL 2026；
Dorner et al., arXiv 2507.12399；Li et al., arXiv 2603.29121；以及两个 Zenodo 镜像）。
它们只是本地下载来核对 `paper/manuscript.md` 里每一条引用是否与原文一致的。

把它们放进 public 仓库等于再分发受版权保护的材料，因此**按版权原因排除，
不是按体积排除**。需要自己按 DOI 取用；`verify_dois.py` 走网络校验，不依赖本地副本。

## License

尚未选择。论文正文的著作权保留；代码部分的授权待定。
