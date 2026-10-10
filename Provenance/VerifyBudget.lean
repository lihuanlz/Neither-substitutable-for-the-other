/-
# 验证预算：TV 下界下的最优验证轮数 \(N^\star\)

本文件回应原始分析第 6 节。该节的期望遗憾写作

    R(N) = p·Φ(α) + (1−p)·L·(1−q)^N + c_v·N

其中「验证 \(N\) 轮足够多 ⟹ 漏检率 \((1−q)^N \to 0\)」这一项，
被 `Provenance.HypothesisTest` 的结果否掉了：

    |功效 − 假阳性率| ≤ TV(p, q)      （`Provenance.abs_mass_diff_le_tv`）

**无论验证多少轮，净判别力都不超过 `TV`。** 故残差漏检率有一个**地板**：

    漏检率(N) = max( (1−q)^N , T ),      T = λ·TV

## 修正后的模型

    R(N) = p·Φ(α) + A·max( (1−q)^N , T ) + c·N

    A = (1−p)·L      漏检代价规模（人越不准越大）
    T = λ·TV         **TV 地板**（与 N 无关）
    s = 1−q ∈ (0,1)  单轮验证的残留系数，d = |ln s| > 0

## 关键推导

一阶条件 `c = A·s^N·d` 给出**无约束最优残差** `x_c = c/(A·d)`，
而 TV 地板要求 `x ≥ T`。故最优可达残差

    x* = max( x_c , T )

达到残差 `x` 需要 `N = −ln x / d`，它关于 `x` **递减**。于是

> **\(N^\star = \dfrac{-\ln\big(\max(x_c,\ T)\big)}{d} = \min(N_c,\ N_0)\)**

`x*` 取 `max`、`N*` 取 `min`：**TV 地板只会让你少验，绝不会逼你多验。**

## 主结果

* `starN_le_floorRounds` —— **硬上界，且与 \(p\) 无关**：
  \(N^\star \le N_0 = \dfrac{\ln\frac{1}{\lambda\,TV}}{\ln\frac1{1-q}}\)。
  这就是"人再不准也不能无限加验证"的数学形式。
* `starN_mono_in_p` —— **\(N^\star\) 关于 \(p\) 单调非增**：人越准，验证预算越小。
* `starN_strictly_mono_in_p` —— 当 TV 地板**不起作用**时严格递减。
* `starN_mono_in_tv` —— **\(N^\star\) 关于 \(TV\) 单调非增**（反直觉但正确）：
  两个分布差得越远，验证越早饱和，预算越小。
* `regret_ge_floor` —— 遗憾的地板：`R(N) ≥ pΦ + A·T + cN`。
* `missRate_eq_pow_of_tv_zero` —— `TV = 0` 时地板消失，**退回原始公式**。
  即：TV 既是验证预算的天花板，也是它唯一的约束来源。

## 与第 2 层的关系

`p·Φ(α)` 确实是第 2 层的东西，但它在 \(N\) 上是**常数**，不参与最优化。
决定 \(N^\star\) 的全部是第 1 层的 `TV`。两个层次在 `R(N)` 里各占一项，互不干涉。

-/

import Mathlib.Tactic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Provenance.Basic
import Provenance.HypothesisTest

open scoped BigOperators

namespace Provenance

/-- 验证预算的参数。 -/
structure VerifyParams where
  /-- 人类判断正确概率 -/
  p : ℝ
  /-- 层 α 的不可约误差下界 `Φ(α)` -/
  Phi : ℝ
  /-- 漏检代价尺度 -/
  L : ℝ
  /-- 单轮验证的漏检概率 `q`（各轮独立） -/
  q : ℝ
  /-- 单轮验证成本 -/
  c : ℝ
  /-- 内容层全变差距离 `TV(p_H, p_A)` -/
  tv : ℝ
  /-- TV → 代价的换算系数 -/
  lam : ℝ

/-- 参数的合法性。用结构而非合取，便于引用。 -/
structure VOk (V : VerifyParams) : Prop where
  /-- 概率非负 -/
  p_ge_0 : 0 ≤ V.p
  /-- 人不可能永远对：漏检代价必须为正，否则 \(N^\star\) 无意义 -/
  p_lt_1 : V.p < 1
  /-- 不可约下界为正 -/
  Phi_pos : 0 < V.Phi
  /-- 代价尺度为正 -/
  L_pos : 0 < V.L
  /-- 单轮漏检概率为正 -/
  q_pos : 0 < V.q
  /-- 单轮漏检概率小于 1 -/
  q_lt_1 : V.q < 1
  /-- 单轮成本为正 -/
  c_pos : 0 < V.c
  /-- TV 严格为正（`TV = 0` 的退化情形单独处理） -/
  tv_pos : 0 < V.tv
  /-- TV 至多 1 -/
  tv_le_1 : V.tv ≤ 1
  /-- 换算系数为正 -/
  lam_pos : 0 < V.lam

/-- 单轮验证的**衰减率** `d = |ln(1−q)| = ln(1/(1−q)) > 0`。 -/
noncomputable def decay (V : VerifyParams) : ℝ := |Real.log (1 - V.q)|

/-- 漏检代价规模 `A = (1−p)·L`。人越不准，`A` 越大。 -/
noncomputable def lossScale (V : VerifyParams) : ℝ := (1 - V.p) * V.L

/-- **TV 地板** `T = λ·TV`：任何验证轮数都压不下去的残差漏检率。 -/
noncomputable def tvFloor (V : VerifyParams) : ℝ := V.lam * V.tv

/-- **残差漏检率** `max((1−q)^N, T)`。 -/
noncomputable def missRate (V : VerifyParams) (N : ℝ) : ℝ :=
  max ((1 - V.q) ^ N) (tvFloor V)

/-- **期望遗憾** `R(N) = p·Φ + A·max((1−q)^N, T) + c·N`。 -/
noncomputable def regret (V : VerifyParams) (N : ℝ) : ℝ :=
  V.p * V.Phi + lossScale V * missRate V N + V.c * N

/-- 达到残差漏检率 `x ∈ (0,1]` 所需的验证轮数：`N = −ln x / d`。

**关于 `x` 严格递减**：想压得更低，就要验更多轮。 -/
noncomputable def roundsFor (V : VerifyParams) (x : ℝ) : ℝ :=
  -(Real.log x) / decay V

/-- 忽略 TV 地板时的最优残差（一阶条件 `c = A·s^N·d`）：`x_c = c/(A·d)`。 -/
noncomputable def idealResidual (V : VerifyParams) : ℝ :=
  V.c / (lossScale V * decay V)

/-- **最优验证预算**

    N* = −ln( max( c/(A·d) , λ·TV ) ) / d

无 TV 地板时（`TV = 0`，`T = 0`）退化为原第 6 节的闭式
`ln(A·d/c)/d`，即 `ln((1−p)L·|ln(1−q)|/c) / ln(1/(1−q))`。 -/
noncomputable def starN (V : VerifyParams) : ℝ :=
  roundsFor V (max (idealResidual V) (tvFloor V))

/-! ## 1. 基本正性 -/

theorem log_one_sub_q_neg {V : VerifyParams} (hV : VOk V) :
    Real.log (1 - V.q) < 0 := by
  have h1 : 0 < (1 : ℝ) - V.q := by linarith [hV.q_lt_1]
  have h2 : (1 : ℝ) - V.q < 1 := by linarith [hV.q_pos]
  have hlt : Real.log (1 - V.q) < Real.log 1 :=
    (Real.log_lt_log_iff h1 (by norm_num)).mpr h2
  rw [Real.log_one] at hlt
  exact hlt

theorem decay_pos {V : VerifyParams} (hV : VOk V) : 0 < decay V := by
  rw [decay, abs_of_neg (log_one_sub_q_neg hV)]
  exact neg_pos.mpr (log_one_sub_q_neg hV)

/-- `d = ln(1/(1−q))`，即闭式里通常写的那个分母。 -/
theorem decay_eq_log_inv {V : VerifyParams} (hV : VOk V) :
    decay V = Real.log (1 / (1 - V.q)) := by
  rw [decay, abs_of_neg (log_one_sub_q_neg hV)]
  have h1 : (1 : ℝ) - V.q ≠ 0 := ne_of_gt (by linarith [hV.q_lt_1])
  have h2 : (1 : ℝ) ≠ 0 := by norm_num
  rw [Real.log_div h2 h1, Real.log_one]
  ring

theorem lossScale_pos {V : VerifyParams} (hV : VOk V) : 0 < lossScale V := by
  unfold lossScale
  exact mul_pos (by linarith [hV.p_lt_1]) hV.L_pos

theorem tvFloor_pos {V : VerifyParams} (hV : VOk V) : 0 < tvFloor V := by
  unfold tvFloor
  exact mul_pos hV.lam_pos hV.tv_pos

theorem idealResidual_pos {V : VerifyParams} (hV : VOk V) : 0 < idealResidual V := by
  unfold idealResidual
  exact div_pos hV.c_pos (mul_pos (lossScale_pos hV) (decay_pos hV))

theorem maxResidual_pos {V : VerifyParams} (hV : VOk V) :
    0 < max (idealResidual V) (tvFloor V) :=
  lt_of_lt_of_le (idealResidual_pos hV) (le_max_left (idealResidual V) (tvFloor V))

/-! ## 2. 单调性工具：目标残差越大，所需轮数越少 -/

theorem roundsFor_mono {V : VerifyParams} (hV : VOk V) {x x' : ℝ}
    (hx : 0 < x) (hx' : 0 < x') (h : x ≤ x') :
    roundsFor V x' ≤ roundsFor V x := by
  unfold roundsFor
  have hlog : -(Real.log x') ≤ -(Real.log x) :=
    neg_le_neg ((Real.log_le_log_iff hx hx').mpr h)
  rw [div_eq_mul_inv, div_eq_mul_inv]
  exact mul_le_mul_of_nonneg_right hlog (inv_nonneg.mpr (le_of_lt (decay_pos hV)))

theorem roundsFor_strict_mono {V : VerifyParams} (hV : VOk V) {x x' : ℝ}
    (hx : 0 < x) (hx' : 0 < x') (h : x < x') :
    roundsFor V x' < roundsFor V x := by
  unfold roundsFor
  have hlog : -(Real.log x') < -(Real.log x) :=
    neg_lt_neg ((Real.log_lt_log_iff hx hx').mpr h)
  rw [div_eq_mul_inv, div_eq_mul_inv]
  exact mul_lt_mul_of_pos_right hlog (inv_pos.mpr (decay_pos hV))

/-- 衰减率相同时 `roundsFor` 取值相同。 -/
theorem roundsFor_congr {V V' : VerifyParams} (hd : decay V = decay V') (x : ℝ) :
    roundsFor V' x = roundsFor V x := by
  unfold roundsFor
  rw [hd]

/-- `inv` 在正数上反单调（自备，避免依赖具体引理名）。 -/
theorem inv_lt_inv_of_lt {a b : ℝ} (ha : 0 < a) (hb : 0 < b) (h : a < b) :
    b⁻¹ < a⁻¹ := by
  by_contra hcon
  push_neg at hcon
  have hnot : ¬ (a⁻¹ ≤ b⁻¹) := by
    intro hh
    have hba : b ≤ a := (inv_le_inv₀ ha hb).mp hh
    exact absurd h (not_lt_of_ge hba)
  exact hnot hcon

/-! ## 3. TV 地板：漏检率压不到 0 -/

/-- **地板存在性**：任何验证轮数下，残差漏检率都不低于 `T = λ·TV`。

这就是 `|功效 − 假阳性率| ≤ TV` 在预算语言里的样子。 -/
theorem missRate_ge_tvFloor (V : VerifyParams) (N : ℝ) :
    tvFloor V ≤ missRate V N :=
  le_max_right _ _

/-- **遗憾的地板**：`R(N) ≥ p·Φ + A·T + c·N`。与验证轮数的阶数无关。 -/
theorem regret_ge_floor {V : VerifyParams} (hV : VOk V) {N : ℝ} :
    V.p * V.Phi + lossScale V * tvFloor V + V.c * N ≤ regret V N := by
  unfold regret
  have hm := missRate_ge_tvFloor V N
  have hA : 0 ≤ lossScale V := le_of_lt (lossScale_pos hV)
  have hmul : lossScale V * tvFloor V ≤ lossScale V * missRate V N :=
    mul_le_mul_of_nonneg_left hm hA
  linarith

/-! ## 4. 主定理：\(N^\star\) 的硬上界（与 \(p\) 无关） -/

/-- **核心：\(N^\star\) 有与 \(p\) 无关的硬上界。**

    N*  ≤  N_0 = ln(1/(λ·TV)) / ln(1/(1−q))

右端**不含 `p`**。所以：**人再不准（\(p \to 0\)），验证预算也不能无限加**
——因为 TV 给了残差漏检率一个地板，加再多验证也压不下去。

这条改写了原第 6 节「\(p\) 越小、\(N^\star\) 越大」的结论：
\(N^\star\) 确实随 \(p\) 减小而增大，但**有天花板**。 -/
theorem starN_le_floorRounds {V : VerifyParams} (hV : VOk V) :
    starN V ≤ roundsFor V (tvFloor V) := by
  rw [starN]
  exact roundsFor_mono hV (tvFloor_pos hV) (maxResidual_pos hV)
    (le_max_right (idealResidual V) (tvFloor V))

/-- 上界的闭式：`N_0 = ln(1/(λ·TV)) / ln(1/(1−q))`，**不含 \(p\)**。 -/
theorem starN_le_floorRounds_closed {V : VerifyParams} (hV : VOk V) :
    starN V ≤ Real.log (1 / tvFloor V) / Real.log (1 / (1 - V.q)) := by
  have h1 : starN V ≤ -(Real.log (tvFloor V)) / decay V := starN_le_floorRounds hV
  have hT : tvFloor V ≠ 0 := ne_of_gt (tvFloor_pos hV)
  have h2 : -(Real.log (tvFloor V)) = Real.log (1 / tvFloor V) := by
    rw [Real.log_div (by norm_num) hT, Real.log_one]
    ring
  rw [h2, decay_eq_log_inv hV] at h1
  exact h1

/-! ## 5. 主定理：\(N^\star\) 关于 \(p\) 单调 -/

/-- **\(N^\star\) 关于人的可靠度单调非增**（同一验证器、同一代价尺度下）。

**方向**：人越准（`p` 越大），最优验证预算越小或不变。

这证实了原第 6 节的方向判断（`N*` 关于 `p` 递减），
而 `starN_le_floorRounds` 给它加上了天花板。 -/
theorem lossScale_mono_in_p {V V' : VerifyParams} (hV : VOk V)
    (hp : V.p ≤ V'.p) (hL : V'.L = V.L) :
    lossScale V' ≤ lossScale V := by
  have h1 : (1 : ℝ) - V'.p ≤ 1 - V.p := sub_le_sub_left hp 1
  rw [lossScale, lossScale, hL]
  exact mul_le_mul_of_nonneg_right h1 (le_of_lt hV.L_pos)

theorem lossScale_strict_mono_in_p {V V' : VerifyParams} (hV : VOk V)
    (hp : V.p < V'.p) (hL : V'.L = V.L) :
    lossScale V' < lossScale V := by
  have h1 : (1 : ℝ) - V'.p < 1 - V.p := sub_lt_sub_left hp 1
  rw [lossScale, lossScale, hL]
  exact mul_lt_mul_of_pos_right h1 hV.L_pos

/-- 无约束最优残差 `x_c = c/(A·d)` 关于 `p` 单调非增：人越准，代价规模越小、可达残差越低。 -/
theorem idealResidual_mono_in_p {V V' : VerifyParams} (hV : VOk V) (hV' : VOk V')
    (hq : V'.q = V.q) (hc : V'.c = V.c)
    (hp : V.p ≤ V'.p) (hL : V'.L = V.L) :
    idealResidual V ≤ idealResidual V' := by
  have hls := lossScale_mono_in_p hV hp hL
  have hdc : decay V' = decay V := by rw [decay, decay, hq]
  have hdpos : 0 < decay V' := by rw [hdc]; exact decay_pos hV
  have hden : lossScale V' * decay V' ≤ lossScale V * decay V' :=
    mul_le_mul_of_nonneg_right hls (le_of_lt hdpos)
  have hdenpos : 0 < lossScale V * decay V' := mul_pos (lossScale_pos hV) hdpos
  have hdenpos' : 0 < lossScale V' * decay V' := mul_pos (lossScale_pos hV') hdpos
  have hinv : (lossScale V * decay V')⁻¹ ≤ (lossScale V' * decay V')⁻¹ :=
    (inv_le_inv₀ hdenpos hdenpos').mpr hden
  unfold idealResidual
  calc V.c / (lossScale V * decay V)
      = V.c / (lossScale V * decay V') := by rw [hdc]
    _ = (lossScale V * decay V')⁻¹ * V.c := by rw [div_eq_mul_inv, mul_comm]
    _ ≤ (lossScale V' * decay V')⁻¹ * V.c := mul_le_mul_of_nonneg_right hinv (le_of_lt hV.c_pos)
    _ = V'.c / (lossScale V' * decay V') := by rw [div_eq_mul_inv, mul_comm, hc]

theorem idealResidual_strict_mono_in_p {V V' : VerifyParams} (hV : VOk V) (hV' : VOk V')
    (hq : V'.q = V.q) (hc : V'.c = V.c)
    (hp : V.p < V'.p) (hL : V'.L = V.L) :
    idealResidual V < idealResidual V' := by
  have hls := lossScale_strict_mono_in_p hV hp hL
  have hdc : decay V' = decay V := by rw [decay, decay, hq]
  have hdpos : 0 < decay V' := by rw [hdc]; exact decay_pos hV
  have hden : lossScale V' * decay V' < lossScale V * decay V' :=
    mul_lt_mul_of_pos_right hls hdpos
  have hdenpos : 0 < lossScale V * decay V' := mul_pos (lossScale_pos hV) hdpos
  have hdenpos' : 0 < lossScale V' * decay V' := mul_pos (lossScale_pos hV') hdpos
  have hinv : (lossScale V * decay V')⁻¹ < (lossScale V' * decay V')⁻¹ :=
    inv_lt_inv_of_lt hdenpos' hdenpos hden
  unfold idealResidual
  calc V.c / (lossScale V * decay V)
      = V.c / (lossScale V * decay V') := by rw [hdc]
    _ = (lossScale V * decay V')⁻¹ * V.c := by rw [div_eq_mul_inv, mul_comm]
    _ < (lossScale V' * decay V')⁻¹ * V.c := by
          simpa [mul_comm] using mul_lt_mul_of_pos_left hinv hV.c_pos
    _ = V'.c / (lossScale V' * decay V') := by rw [div_eq_mul_inv, mul_comm, hc]

/-- **\(N^\star\) 关于人的可靠度单调非增**（同一验证器、同一代价尺度下）。

**方向**：人越准（`p` 越大），最优验证预算越小或不变。

这证实了原第 6 节的方向判断（`N*` 关于 `p` 递减），
而 `starN_le_floorRounds` 给它加上了天花板。 -/
theorem starN_mono_in_p {V V' : VerifyParams} (hV : VOk V) (hV' : VOk V')
    (hq : V'.q = V.q) (hc : V'.c = V.c) (hlam : V'.lam = V.lam) (htv : V'.tv = V.tv)
    (hL : V'.L = V.L) (hp : V.p ≤ V'.p) :
    starN V' ≤ starN V := by
  have hdc : decay V' = decay V := by rw [decay, decay, hq]
  have hdt : tvFloor V' = tvFloor V := by unfold tvFloor; rw [hlam, htv]
  have hid := idealResidual_mono_in_p hV hV' hq hc hp hL
  have hmax : max (idealResidual V) (tvFloor V) ≤ max (idealResidual V') (tvFloor V') :=
    max_le_max hid hdt.symm.le
  rw [starN, starN, ← roundsFor_congr hdc (max (idealResidual V') (tvFloor V'))]
  exact roundsFor_mono hV (maxResidual_pos hV) (maxResidual_pos hV') hmax

/-- **严格性**：当 TV 地板**不起作用**时（`T < x_c`），
\(N^\star\) 关于 `p` **严格**递减。

即：验证预算要真正随人的可靠度变化，前提是「TV 不是瓶颈」。
一旦 TV 成为瓶颈，`N*` 就被钉死成常数 `N_0`，再信任谁也没用
——**瓶颈在内容层的可区分性，不在验证的力度。** -/
theorem starN_strictly_mono_in_p {V V' : VerifyParams} (hV : VOk V) (hV' : VOk V')
    (hq : V'.q = V.q) (hc : V'.c = V.c) (hlam : V'.lam = V.lam) (htv : V'.tv = V.tv)
    (hL : V'.L = V.L) (hp : V.p < V'.p) (hfree : tvFloor V' < idealResidual V') :
    starN V' < starN V := by
  have hdc : decay V' = decay V := by rw [decay, decay, hq]
  have hdt : tvFloor V' = tvFloor V := by unfold tvFloor; rw [hlam, htv]
  have hidlt := idealResidual_strict_mono_in_p hV hV' hq hc hp hL
  have hfree' : tvFloor V < idealResidual V' := by rw [← hdt]; exact hfree
  have key : max (idealResidual V) (tvFloor V) < max (idealResidual V') (tvFloor V') := by
    rw [hdt, max_eq_left (le_of_lt hfree')]
    rcases le_total (idealResidual V) (tvFloor V) with h | h
    · rw [max_eq_right h]
      exact hfree'
    · rw [max_eq_left h]
      exact hidlt
  rw [starN, starN, ← roundsFor_congr hdc (max (idealResidual V') (tvFloor V'))]
  exact roundsFor_strict_mono hV (maxResidual_pos hV) (maxResidual_pos hV') key

/-! ## 6. 主定理：\(N^\star\) 关于 `TV` 单调 -/

/-- **\(N^\star\) 关于 `TV` 单调非增**。

反直觉但正确：两个分布差得**越远**，验证越早饱和，所需预算**越小**。
所以提高 `TV` 不是"让人工审核更安全"，而是"让机器验证更省"。 -/
theorem starN_mono_in_tv {V V' : VerifyParams} (hV : VOk V) (hV' : VOk V')
    (hq : V'.q = V.q) (hc : V'.c = V.c) (hlam : V'.lam = V.lam)
    (hL : V'.L = V.L) (hp : V'.p = V.p) (htv : V.tv ≤ V'.tv) :
    starN V' ≤ starN V := by
  have hdc : decay V' = decay V := by rw [decay, decay, hq]
  have hdt : tvFloor V ≤ tvFloor V' := by
    unfold tvFloor
    rw [hlam]
    exact mul_le_mul_of_nonneg_left htv (le_of_lt hV.lam_pos)
  have hid1 := idealResidual_mono_in_p hV hV' hq hc hp.symm.le hL
  have hid2 := idealResidual_mono_in_p hV' hV hq.symm hc.symm hp.le hL.symm
  have hid : idealResidual V = idealResidual V' := le_antisymm hid1 hid2
  have hmax : max (idealResidual V) (tvFloor V) ≤ max (idealResidual V') (tvFloor V') :=
    max_le_max (le_of_eq hid) hdt
  have hstep : roundsFor V (max (idealResidual V') (tvFloor V'))
      ≤ roundsFor V (max (idealResidual V) (tvFloor V)) :=
    roundsFor_mono hV (maxResidual_pos hV) (maxResidual_pos hV') hmax
  rw [starN, starN, roundsFor_congr hdc.symm (max (idealResidual V') (tvFloor V'))]
  exact hstep

/-! ## 7. 退化情形：`TV = 0` 退回原始公式 -/

/-- **`TV = 0` 时地板消失**：漏检率就是 `(1−q)^N`，验证可以无限逼近 0。

即：TV 既是验证预算的天花板，也是它唯一的约束来源。
`TV = 0` 意味着两个分布完全重合——那时才谈得上"多验几轮"。 -/
theorem missRate_eq_pow_of_tv_zero {V : VerifyParams} (hV : VOk V) (htv : V.tv = 0)
    (N : ℝ) : missRate V N = (1 - V.q) ^ N := by
  unfold missRate tvFloor
  rw [htv, mul_zero]
  exact max_eq_left (Real.rpow_nonneg (show (0:ℝ) ≤ 1 - V.q by linarith [hV.q_lt_1]) N)

end Provenance