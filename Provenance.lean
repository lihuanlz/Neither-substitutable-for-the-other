/-
# 人机贡献的形式化 · 总入口

两个层次，本包分别给出机器验证的证明。

## 第 1 层：内容层 —— 来源可识别性（事后溯源）

* `Provenance.Basic` —— 全变差距离 TV、检验正确率、贝叶斯最优性、不可识别性。
* `Provenance.Contamination` —— TV 混合定理、递归污染的指数律、坍缩上界。
* `Provenance.Coverage` —— 覆盖函数、次模性、单样本边际增益定理。
* `Provenance.HypothesisTest` —— **集合形式的 TV 定理**与 **Neyman–Pearson 功效上界**：
  任何检验（z 检验、t 检验、任何阈值）的「命中 − 误报」都不超过 `TV`，且该上界可达。
* `Provenance.Examples` —— 精确有理数实例对拍。

核心结论：最优检测优势 = `TV/2`；`TV = 0` ⟺ 任何检验都恰为随机；
污染率 `π` 使优势**恰好**线性衰减为 `π` 倍；
**任何统计检验都无法突破 `TV`**——内容层判定的瓶颈是 `TV` 本身，不是检验不够好。

### 验证预算的修正（`Provenance.VerifyBudget`）

    漏检率(N) = max( (1−q)^N , λ·TV )        ← TV 地板

    N* = −ln( max( c/(A·d) , λ·TV ) ) / d,     A=(1−p)L,  d=ln(1/(1−q))

* `starN_le_floorRounds` —— **\(N^\star\) 有与 \(p\) 无关的硬上界**：
  人再不准，验证预算也不能无限加。
* `starN_mono_in_p` —— \(N^\star\) 关于 \(p\) 单调非增（TV 地板不 bind 时严格递减）。
* `starN_mono_in_tv` —— \(N^\star\) 关于 `TV` 单调非增：TV 越大，验证越早饱和、预算越小。

## 第 2 层：系统层 —— 观测层过滤下的贡献分解（事前定价）

* `Provenance.Refinement` —— 把"真实"从单点升级为观测层上的等价类 \([s^*]_\alpha\)，
  误差从单值升级为层级函数，贡献分解为
  **"人类改变 \(\Phi(\alpha)\)"** 与 **"AI 压缩 \(e_t^\alpha\) 到 \(\Phi(\alpha)\)"**。
* `Provenance.Value` —— **影响力与价值的可分离性**：为什么 KL / 任何信息增益
  都**不能**代理价值。
* `Provenance.VerifyBudget` —— **第 2 层落到第 1 层**：在 TV 地板下求最优验证预算
  \(N^\star\)。修正原第 6 节的 `R(N)`（漏检率压不到 0），给出闭式与三条单调性。
* `Provenance.Incommensurable` —— **不可通约性**（原第 8 节第 1 条）。
  \(\mathcal U\) = 保序 + 保加法 + \(\phi(1)=1\)，定义域取有符号 \(\mathbb{R}\)。

### 第 2 层已证的核心对偶

* **AI 层内总收益有硬上界** `log(e₀/Φ)`，且该上界**只由层决定，与步数无关**；
* **人类切层收益无上界**；
* **层不变则人类零收益**（好问题 ⟺ 严格降低 Φ，见 `positive_layer_gain_iff_strict_drop`）；
* **AI 边际贡献趋零**只在"层固定"下成立，而层固定正是人类不做贡献的状态。

### 第 2 层已证的反驳

* `influence_value_separable` —— 影响力绝对值相同的两条输出，价值可以是 `+M` 与 `−M`，
  **且 \(M\) 任意大**。故"用影响力代理价值"的方案在数学上失效。
* `separation_grows_without_bound` —— 影响大恰恰是最危险的情形，筛小样本没用。
* `cover_value_is_a_layer_gain` —— `ΔCover` 不是一个独立的第三项，它就是层间收益的特例。
* `layered_bits_decomposition` —— 两项比特分解（层间 + 层内），无重复计数、量纲统一。

### 不可通约性的判决（`Provenance.Incommensurable`）

原第 8 节第 1 条**不是一条定理，也不是一条反例——它分两个区间**：

* **TV 地板 bind（\(T \ge x_c\)）**：**完全不可通约**。
  `starN_indep_of_p_when_floor_binds` —— 任意两个不同可靠度的人给出**完全相同**的 \(N^\star\)，
  连单调性都没有。
* **TV 地板不 bind（\(T < x_c\)）**：**可通约，但非线性**。
  `starN_exp_formula` 给出 \(\exp(d\,N^\star)=A\,d/c\)，即 \(A=\tfrac{c}{d}e^{dN^\star}\)——
  **保序**，但**不是仿射**，故 \(\mathcal U\) 里没有它。

所以准确的说法是「**不可线性换算**」，而不是「**完全不可通约**」。
后者过强，会被 Lean 判死。

此外 `incommensurable_witness` 给出原第 8 节第 1 条的字面形式：
**同一个过程里，AI 工作量可以任意大而人的成本可以任意小**——两个量互不控制。

## 第 3 层：标定不可识别性 —— 符号不由数据决定

`Provenance.Calibration` 追问一个更靠前的问题：那些被用来**度量人机贡献**的量，
它自己的方向是从哪里来的？

取文献中最通行的「最小必要人类贡献」估计量（把原式除以 \(I(y)\)）：

  `minContribution s tau = 1 - tau / s`

其中 `s` = 输出的平均逐 token 无条件惊奇度，`tau` = 拟合出来的合理性门槛。

* **人不出现在式子里** —— `reported_ignores_human` / `human_cannot_move_reported`：
  报告值只依赖输出本身，换人类输入一个数都不动。
* **符号由门槛与惊奇度的大小关系决定，与协作无关** —— 主定理
  `sign_not_identified`：对任意一个输出，**都存在两组标定使 `signOf` 取相反值**；
  `sign_not_identified_exact` 进一步把见证钉死为 `tau = s/2` 与 `tau = 3s/2`。
* 门槛 `tau` 恰恰是**分布外**拟合的，所以符号不由数据识别（`sign_not_identified_in_context`）。
* 附带否证 `[0,1]` 解读在估计变体下的成立：`lt_one` 给上界，
  `estimator_not_a_proportion` 直接推翻非负性，`unbounded_below` 说明下方无界。

这一层把「符号不可识别」从散文式批评升级为可机器检查的定理：
**表面符号是标定的产物，不是测量的产物。**

## 复现

```
cd /d D:\lean_proj\source_identifiability
lake build
```

-/

import Provenance.Basic
import Provenance.Contamination
import Provenance.Coverage
import Provenance.HypothesisTest
import Provenance.Refinement
import Provenance.Value
import Provenance.VerifyBudget
import Provenance.Incommensurable
import Provenance.Calibration
import Provenance.Examples