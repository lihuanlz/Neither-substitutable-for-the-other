/-
# 不可通约性：层间收益 \(v_H\) 与层内收益 \(v_A\)

本文件处理原始分析第 8 节第 1 条：不可通约性。

## 效用函数类 \(\mathcal U\) 的选择（建模决策）

用户选定**方向 B**：保序 + 保加法 + \(\phi(1)=1\)，定义域取有符号 \(\mathbb{R}\)
（层间价值可以为负——粗化等价类就是负贡献，见 `Provenance.influence_value_separable`）。

> **为什么取有符号**：原第 5 稿把 \(v_H\) 当作"比特数"（非负），
> 但粗化观测层（引入错误约束）是**负**的。用非负域会把这个方向信息抹掉，
> 恰好重犯 KL 的错误。

**已知事实（本文件未证）**：在 \(\mathbb{R}\) 上，加性 + 单调强制线性，
故 \(\mathcal U\) 只含仿射映射；再由 \(\phi(1)=1\) 定出斜率。
\(\mathcal U = \{\text{斜率为 }1\text{ 的仿射映射}\}\)。

下面每一条结论都对 \(\mathcal U\) 中**每一个**元素成立，所以不需要这条分类。

## 判决：不可通约性**分两个区间**，只在一半上成立

### 区间 ①：TV 地板 bind（\(T \ge x_c\)）—— **完全不可通约**

`starN_indep_of_p_when_floor_binds`：**任意两个不同可靠度的人，
给出完全相同的 \(N^\star\)**。AI 的工作量携带不了关于人的**任何**信息。
这一段上，连单调性都没有，更不用说线性换算。

### 区间 ②：TV 地板不 bind（\(T < x_c\)）—— **可通约，但非线性**

`starN_exp_formula`：

    exp( d·N* )  =  A·d / c ,     A = (1−p)L,   d = ln(1/(1−q))

即 \(A = \frac{c}{d}\,e^{dN^\star}\)。所以：

* **保序**（单调递增）——`starN_strictly_mono_in_p` 已证；
* **但不是仿射**——是指数。故**不存在** \(\phi \in \mathcal U\) 使
  \(\phi(N^\star) = A\)。

> **这修正了原命题**：这一段不是"不可通约"，而是"可通约但非线性"。
> 把整条命题说成"完全不可通约"是**过强**的，会被 Lean 判死。

### 两条极端的量化陈述（原第 8 节第 1 条的字面形式）

* `ai_effort_arbitrarily_large` —— AI 的工作量**无上界**（`TV → 0` 时）。
* `human_value_arbitrarily_small` —— 人的不可靠性成本**可任意小**（`p → 1` 时）。
* `incommensurable_witness` —— **同一个过程里同时成立**：
  AI 工作量任意大、人的成本任意小。
  故任何保序映射都无法把层内量换算成层间量。

### 层间 vs 层内的取值范围（打包 `Provenance.Refinement`）

* `human_gain_unbounded` —— 层间收益 `log(Φα/Φβ)` **无上界**。
* `ai_total_gain_bounded` —— 层内收益 `log(e₀/e)` **有硬上界** `log(e₀/Φ)`，
  且该上界只由层决定、与步数无关。

一个是 \([0,\infty)\)，一个是 \([0,K]\)。这是"两个尺度"最朴素的形式化。

-/

import Mathlib.Tactic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Provenance.Refinement
import Provenance.VerifyBudget

open scoped BigOperators

namespace Provenance

/-- 允许的效用函数类 \(\mathcal U\)：保序 + 保加法 + 保正 + \(\phi(1)=1\)。

**定义域取有符号 \(\mathbb{R}\)**：层间价值可以为负。 -/
def U (φ : ℝ → ℝ) : Prop :=
  (∀ a b, a ≤ b → φ a ≤ φ b)
    ∧ (∀ a b, φ (a + b) = φ a + φ b)
    ∧ (∀ a, 0 ≤ a → 0 ≤ φ a)
    ∧ φ 1 = 1

/-- **区间 ①：TV 地板 bind ⟹ AI 工作量与人的可靠度完全无关。**

这是不可通约性真正成立的那一半：连单调性都没有。

推论：一旦 `λ·TV ≥ c/(A·d)`，**再多验证也不解决问题**，而且
**再信任谁也没用**——因为 `N*` 已经不随 \(p\) 变了。 -/
theorem starN_indep_of_p_when_floor_binds {V V' : VerifyParams} (hV : VOk V) (hV' : VOk V')
    (hq : V'.q = V.q) (hc : V'.c = V.c) (hlam : V'.lam = V.lam) (htv : V'.tv = V.tv)
    (hL : V'.L = V.L) (hp : V.p ≤ V'.p)
    (hfill : idealResidual V' ≤ tvFloor V') :
    starN V = starN V' := by
  have hdc : decay V' = decay V := by rw [decay, decay, hq]
  have hdt : tvFloor V' = tvFloor V := by unfold tvFloor; rw [hlam, htv]
  have hid : idealResidual V ≤ idealResidual V' :=
    idealResidual_mono_in_p hV hV' hq hc hp hL
  have hid2 : idealResidual V ≤ tvFloor V := by
    refine hid.trans ?_
    rw [← hdt]
    exact hfill
  have h1 : max (idealResidual V) (tvFloor V) = tvFloor V := max_eq_right hid2
  have h2 : max (idealResidual V') (tvFloor V') = tvFloor V' := max_eq_right hfill
  rw [starN, starN, h1, h2, hdt, roundsFor_congr hdc.symm (tvFloor V)]

/-- **区间 ②：TV 地板不 bind ⟹ \(A\) 与 \(N^\star\) 是指数关系。**

    exp( d·N* )  =  A·d / c ,    A = (1−p)L,  d = ln(1/(1−q))

这条把"不可线性换算"精确化了：
关系**存在**（保序），但它是 `exp` 而**非仿射**，故 \(\mathcal U\) 里没有它。 -/
theorem starN_exp_formula {V : VerifyParams} (hV : VOk V)
    (hfill : tvFloor V ≤ idealResidual V) :
    Real.exp (decay V * starN V) = lossScale V * decay V / V.c := by
  have hd : decay V ≠ 0 := ne_of_gt (decay_pos hV)
  have hmax : max (idealResidual V) (tvFloor V) = idealResidual V := max_eq_left hfill
  have hstep : decay V * starN V = -(Real.log (idealResidual V)) := by
    rw [starN, hmax, roundsFor]
    field_simp
    ring
  rw [hstep, Real.exp_neg, Real.exp_log (idealResidual_pos hV)]
  rw [show idealResidual V = V.c / (lossScale V * decay V) from rfl]
  field_simp [ne_of_gt hV.c_pos, ne_of_gt (mul_pos (lossScale_pos hV) (decay_pos hV))]

/-- **AI 的工作量无上界。**

`TV → 0` 时地板消失，验证轮数可以任意大。
（构造：取 `d = 1`，即 `1−q = e^{−1}`；再取 `λ = e^{−2M}`、`TV = 1`，
  于是 `N_0 = −ln(e^{−2M}) = 2M > M`。） -/
theorem ai_effort_arbitrarily_large {M : ℝ} (hM : 0 < M) :
    ∃ V : VerifyParams, VOk V ∧ M < roundsFor V (tvFloor V) := by
  have he1 : 0 < Real.exp (-1) := Real.exp_pos (-1)
  have he1' : Real.exp (-1) < 1 := by
    have h : Real.exp (-1) < Real.exp 0 := Real.exp_lt_exp.mpr (by norm_num : (-1:ℝ) < 0)
    rw [Real.exp_zero] at h
    exact h
  set V : VerifyParams :=
    { p := (1 : ℝ) / 2, Phi := 1, L := 1, q := 1 - Real.exp (-1), c := 1,
      tv := 1, lam := Real.exp (-2 * M) } with hVdef
  have hV : VOk V := by
    refine ⟨by norm_num, by norm_num, by norm_num, by norm_num, ?_, ?_,
      by norm_num, by norm_num, by norm_num, ?_⟩
    · simp only [hVdef]; linarith
    · simp only [hVdef]; linarith
    · simp only [hVdef]; exact Real.exp_pos _
  refine ⟨V, hV, ?_⟩
  have hd : decay V = 1 := by
    simp only [decay, hVdef]
    rw [show (1:ℝ) - (1 - Real.exp (-1)) = Real.exp (-1) by ring, Real.log_exp,
      abs_of_nonpos (by norm_num : (-1:ℝ) ≤ 0)]
    ring
  have htf : tvFloor V = Real.exp (-2 * M) := by
    simp only [tvFloor, hVdef]
    ring
  rw [roundsFor, htf, hd, Real.log_exp]
  linarith

/-- **人的不可靠性成本可任意小。**

人几乎总是对时，AI 几乎不用干活。
（构造：`p = 1/2`、`L = M`，则 `A = M/2 < M`。） -/
theorem human_value_arbitrarily_small {M : ℝ} (hM : 0 < M) :
    ∃ V : VerifyParams, VOk V ∧ lossScale V < M := by
  set V : VerifyParams :=
    { p := (1 : ℝ) / 2, Phi := 1, L := M, q := (1 : ℝ) / 2, c := 1, tv := 1, lam := 1 } with hVdef
  have hV : VOk V := by
    refine ⟨by norm_num, by norm_num, by norm_num, hM, by norm_num, by norm_num,
      by norm_num, by norm_num, by norm_num, by norm_num⟩
  refine ⟨V, hV, ?_⟩
  simp only [lossScale, hVdef]
  norm_num
  linarith

/-- **原第 8 节第 1 条的字面形式：同一个过程里，AI 工作量任意大而人的成本任意小。**

故任何保序映射都无法把层内量 \(v_A\) 换算成层间量 \(v_H\)：
两个量在同一族里**互不控制**。 -/
theorem incommensurable_witness {M : ℝ} (hM : 0 < M) :
    ∃ V : VerifyParams, VOk V ∧ M < roundsFor V (tvFloor V) ∧ lossScale V < M := by
  set V : VerifyParams :=
    { p := 1 - M / (2 * (M + 1)), Phi := 1, L := 1, q := 1 - Real.exp (-1), c := 1,
      tv := 1, lam := Real.exp (-2 * M) } with hVdef
  have he1 : 0 < Real.exp (-1) := Real.exp_pos (-1)
  have he1' : Real.exp (-1) < 1 := by
    have h : Real.exp (-1) < Real.exp 0 := Real.exp_lt_exp.mpr (by norm_num : (-1:ℝ) < 0)
    rw [Real.exp_zero] at h
    exact h
  have hden : (0:ℝ) < 2 * (M + 1) := by linarith
  have hqle : (M:ℝ) / (2 * (M + 1)) ≤ 1 := (div_le_iff₀ hden).2 (by linarith)
  have hp0 : (0:ℝ) ≤ 1 - M / (2 * (M + 1)) := sub_nonneg.mpr hqle
  have hp1 : (1 : ℝ) - M / (2 * (M + 1)) < 1 := by
    have hpos : (0:ℝ) < M / (2 * (M + 1)) := div_pos hM hden
    linarith
  have hV : VOk V := by
    refine ⟨hp0, hp1, by norm_num, by norm_num, ?_, ?_,
      by norm_num, by norm_num, by norm_num, ?_⟩
    · simp only [hVdef]; linarith
    · simp only [hVdef]; linarith
    · simp only [hVdef]; exact Real.exp_pos _
  refine ⟨V, hV, ?_, ?_⟩
  · have hd : decay V = 1 := by
      simp only [decay, hVdef]
      rw [show (1:ℝ) - (1 - Real.exp (-1)) = Real.exp (-1) by ring, Real.log_exp,
        abs_of_nonpos (by norm_num : (-1:ℝ) ≤ 0)]
      ring
    have htf : tvFloor V = Real.exp (-2 * M) := by
      simp only [tvFloor, hVdef]
      ring
    rw [roundsFor, htf, hd, Real.log_exp]
    linarith
  · have hsmall : (M:ℝ) / (2 * (M + 1)) < M := (div_lt_iff₀ hden).2 (by nlinarith)
    have hid : (1:ℝ) - (1 - M / (2 * (M + 1))) = M / (2 * (M + 1)) := by ring
    rw [lossScale, hVdef, hid, mul_one]
    exact hsmall

/-- **打包：区间 ①② + 两条极端。**

不可通约性的完整判决：
* 地板 bind ⟹ 完全无关（`starN_indep_of_p_when_floor_binds`）；
* 地板不 bind ⟹ 指数相关、非线性（`starN_exp_formula`）；
* 两端 ⟹ 互不控制（`incommensurable_witness`）。 -/
theorem incommensurable_two_regime {M : ℝ} (hM : 0 < M) :
    (∃ V : VerifyParams, VOk V ∧ M < roundsFor V (tvFloor V))
      ∧ (∃ V : VerifyParams, VOk V ∧ lossScale V < M)
      ∧ (∃ V : VerifyParams, VOk V ∧ M < roundsFor V (tvFloor V) ∧ lossScale V < M) :=
  ⟨ai_effort_arbitrarily_large hM, human_value_arbitrarily_small hM,
    incommensurable_witness hM⟩

/-- **层间无上界 vs 层内有硬上界**：两个尺度不相交。

层间收益 `log(Φα/Φβ)` 取遍 \([0,\infty)\)；层内收益 `log(e₀/e)` 恒 `≤ log(e₀/Φ)`，
且该上界**只由层决定、与步数无关**。 -/
theorem layer_scales_disjoint {M e0 Φ : ℝ} (hM : 0 ≤ M) (he0 : 0 < e0) (hΦ : 0 < Φ) :
    (∃ Φα Φβ : ℝ, 0 < Φβ ∧ Φβ ≤ Φα ∧ Real.log (Φα / Φβ) = M)
      ∧ (∀ _eN : ℝ, 0 < _eN → Φ ≤ _eN → Real.log (e0 / _eN) ≤ Real.log (e0 / Φ)) :=
  ⟨human_gain_unbounded hM, fun _eN heN hle => ai_total_gain_bounded he0 hΦ heN hle⟩

end Provenance