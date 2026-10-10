/-
# 来源可识别性（source identifiability）的形式化

本文件把"人类数据 vs AI 数据可否区分"这一问题在 **有限概率空间** 上完全形式化，
并证明以下核心结论（对应原始分析的第 1 节）：

* 原始论断 `P_e = ½(1 − TV(p_H, p_A))`  —— 形式化为 `bayes_errRate` / `errRate_ge`，
  即 **最优检验的错误率恰为 (1−TV)/2，且任何检验都不可能更低**。
* 原始论断"当 p_A → p_H 则不可识别" —— 形式化为 `unidentifiable`：
  **TV = 0 时，任何检验的正确率都恰为 1/2**（不是"接近"，是精确等于）。
* 更强的刻画 —— 形式化为 `identifiable_iff`：
  **存在优于随机的检验 ⟺ TV > 0**，且优势大小恰为 **TV/2**（`accuracy_bounds`）。

## 记号约定

观测空间为 `Fin n`（有限）。`p` 表示人类分布 `p_H`，`q` 表示 AI 分布 `p_A`，
先验取 `π_H = π_A = 1/2`（与原文"两类先验相等"的设定一致）。

## 对原始分析的一处精确化

原文说"当 p_A→p_H 则不可识别"。准确的说法是**可识别性由 TV 连续控制**：
最优可达优势恰为 `TV/2`（`accuracy_bounds`），而"能否检出"还取决于样本量与噪声水平。
`accuracy_bounds` 写成不等式 `|acc − 1/2| ≤ TV/2`，使这个量化无法回避。

-/

import Mathlib.Tactic
import Mathlib.Data.Finset.Basic

open Finset
open scoped BigOperators

namespace Provenance

variable {n : ℕ}

/-- 有限空间上的概率分布（概率质量函数）。 -/
structure PMF (n : ℕ) where
  /-- 概率质量 -/
  val : Fin n → ℝ
  /-- 非负性 -/
  nonneg : ∀ i, 0 ≤ val i
  /-- 归一化 -/
  sum_one : ∑ i, val i = 1

/-- 全变差距离 `TV(p, q) = ½ Σᵢ |pᵢ − qᵢ|`。

`ℝ` 上的除法不可执行，故标 `noncomputable`。 -/
noncomputable def totalVariation (p q : PMF n) : ℝ :=
  (1/2) * ∑ i : Fin n, |p.val i - q.val i|

/-- 一个检验：把每个观测判为「人类」(true) 或「AI」(false)。 -/
abbrev Test (n : ℕ) := Fin n → Bool

/-- 先验 1/2 时的正确率 `acc(t) = ½ Σᵢ (tᵢ ? pᵢ : qᵢ)`。 -/
noncomputable def accuracy (t : Test n) (p q : PMF n) : ℝ :=
  (1/2) * ∑ i : Fin n, (if t i then p.val i else q.val i)

/-- 贝叶斯最优检验：先验似然比大于 1（即 `pᵢ ≥ qᵢ`）时判为人类。 -/
noncomputable def bayes (p q : PMF n) : Test n := fun i => decide (p.val i ≥ q.val i)

/-- 错误率 `= 1 − 正确率`。 -/
noncomputable def errRate (t : Test n) (p q : PMF n) : ℝ := 1 - accuracy t p q

/-! ## 基础性质 -/

theorem bayes_eq (p q : PMF n) (i : Fin n) :
    bayes p q i = if p.val i ≥ q.val i then true else false := by
  simp [bayes]

theorem totalVariation_nonneg (p q : PMF n) : 0 ≤ totalVariation p q := by
  unfold totalVariation
  exact mul_nonneg (by norm_num) (Finset.sum_nonneg fun _ _ => abs_nonneg _)

theorem totalVariation_self (p : PMF n) : totalVariation p p = 0 := by
  unfold totalVariation
  simp

theorem totalVariation_comm (p q : PMF n) : totalVariation p q = totalVariation q p := by
  unfold totalVariation
  congr 1
  apply Finset.sum_congr rfl
  intro i _
  have e : p.val i - q.val i = -(q.val i - p.val i) := by ring
  rw [e, abs_neg]

theorem totalVariation_le_one (p q : PMF n) : totalVariation p q ≤ 1 := by
  have hsum : ∑ i : Fin n, |p.val i - q.val i| ≤ ∑ i : Fin n, (p.val i + q.val i) := by
    refine Finset.sum_le_sum fun i _ => ?_
    rw [abs_le]
    constructor <;> linarith [p.nonneg i, q.nonneg i]
  have h2 : ∑ i : Fin n, (p.val i + q.val i) = 2 := by
    rw [Finset.sum_add_distrib, p.sum_one, q.sum_one]; norm_num
  unfold totalVariation
  linarith

theorem totalVariation_triangle (p q r : PMF n) :
    totalVariation p r ≤ totalVariation p q + totalVariation q r := by
  have hpt : ∀ i : Fin n, |p.val i - r.val i| ≤ |p.val i - q.val i| + |q.val i - r.val i| := by
    intro i
    have e : p.val i - r.val i = (p.val i - q.val i) + (q.val i - r.val i) := by ring
    rw [e]
    exact abs_add _ _
  have hsplit : (∑ i : Fin n, (|p.val i - q.val i| + |q.val i - r.val i|))
      = (∑ i : Fin n, |p.val i - q.val i|) + ∑ i : Fin n, |q.val i - r.val i| :=
    Finset.sum_add_distrib
  unfold totalVariation
  calc (1 / 2) * ∑ i : Fin n, |p.val i - r.val i|
      ≤ (1 / 2) * ∑ i : Fin n, (|p.val i - q.val i| + |q.val i - r.val i|) :=
        mul_le_mul_of_nonneg_left (Finset.sum_le_sum fun i _ => hpt i) (by norm_num)
    _ = (1 / 2) * ∑ i : Fin n, |p.val i - q.val i|
        + (1 / 2) * ∑ i : Fin n, |q.val i - r.val i| := by rw [hsplit]; ring
    _ = _ := rfl

/-- `TV = 0` 当且仅当两个分布逐点相同。（有限空间上无"几乎处处"的微妙性。） -/
theorem totalVariation_eq_zero_iff (p q : PMF n) :
    totalVariation p q = 0 ↔ ∀ i : Fin n, p.val i = q.val i := by
  constructor
  · intro h i
    unfold totalVariation at h
    have key : ∑ j : Fin n, |p.val j - q.val j| = 0 := by linarith
    have hn : ∀ j ∈ (Finset.univ : Finset (Fin n)), 0 ≤ |p.val j - q.val j| :=
      fun j _ => abs_nonneg _
    have hz : |p.val i - q.val i| = 0 :=
      (Finset.sum_eq_zero_iff_of_nonneg hn).mp key i (Finset.mem_univ i)
    exact sub_eq_zero.mp (abs_eq_zero.mp hz)
  · intro h
    unfold totalVariation
    rw [Finset.sum_congr rfl (fun i _ => by rw [h i])]
    simp

/-! ## 核心定理：正确率的精确刻画

关键代数恒等式：任何检验的正确率都等于 `1/2 + (1/4)·T`，
其中 `T` 是一个"带符号求和"，且 `|T| ≤ Σᵢ|pᵢ − qᵢ| = 2·TV`。
于是最优检验的优势恰为 `TV/2`。

-/

theorem accuracy_eq (t : Test n) (p q : PMF n) :
    accuracy t p q
      = (1 / 2) + (1 / 4) * ∑ i : Fin n,
          (if t i then p.val i - q.val i else q.val i - p.val i) := by
  unfold accuracy
  have key : ∀ i : Fin n,
      (if t i then p.val i else q.val i)
        = (1 / 2) * (p.val i + q.val i)
          + (1 / 2) * (if t i then p.val i - q.val i else q.val i - p.val i) := by
    intro i; split <;> ring
  have h2 : ∑ i : Fin n, (p.val i + q.val i) = 2 := by
    rw [Finset.sum_add_distrib, p.sum_one, q.sum_one]; norm_num
  calc (1 / 2) * ∑ i : Fin n, (if t i then p.val i else q.val i)
      = (1 / 2) * ∑ i : Fin n,
          ((1 / 2) * (p.val i + q.val i)
            + (1 / 2) * (if t i then p.val i - q.val i else q.val i - p.val i)) := by
        rw [Finset.sum_congr rfl (fun i _ => key i)]
    _ = (1 / 2) * ((1 / 2) * ∑ i : Fin n, (p.val i + q.val i)
          + (1 / 2) * ∑ i : Fin n,
            (if t i then p.val i - q.val i else q.val i - p.val i)) := by
        rw [Finset.sum_add_distrib, ← Finset.mul_sum, ← Finset.mul_sum]
    _ = _ := by rw [h2]; ring

theorem signed_sum_bound (t : Test n) (p q : PMF n) :
    |∑ i : Fin n, (if t i then p.val i - q.val i else q.val i - p.val i)|
      ≤ ∑ i : Fin n, |p.val i - q.val i| := by
  calc
    |∑ i : Fin n, (if t i then p.val i - q.val i else q.val i - p.val i)|
        ≤ ∑ i : Fin n, |(if t i then p.val i - q.val i else q.val i - p.val i)| :=
          Finset.abs_sum_le_sum_abs _ _
    _ = ∑ i : Fin n, |p.val i - q.val i| := by
        refine Finset.sum_congr rfl fun i _ => ?_
        by_cases h : t i = true <;> simp [h, abs_sub_comm]

/-- **可识别性上界**：任意检验的正确率不超过 `(1 + TV)/2`。 -/
theorem accuracy_le (t : Test n) (p q : PMF n) :
    accuracy t p q ≤ (1 + totalVariation p q) / 2 := by
  have hb := signed_sum_bound t p q
  have hS : (∑ i : Fin n, (if t i then p.val i - q.val i else q.val i - p.val i))
      ≤ ∑ i : Fin n, |p.val i - q.val i| :=
    (le_abs_self _).trans hb
  rw [accuracy_eq t p q]
  unfold totalVariation
  linarith

/-- **下界（对偶形式）**：任意检验的正确率不低于 `(1 − TV)/2`。 -/
theorem accuracy_ge (t : Test n) (p q : PMF n) :
    (1 - totalVariation p q) / 2 ≤ accuracy t p q := by
  have hb := signed_sum_bound t p q
  have hS : -(∑ i : Fin n, (if t i then p.val i - q.val i else q.val i - p.val i))
      ≤ ∑ i : Fin n, |p.val i - q.val i| :=
    (neg_le_abs _).trans hb
  rw [accuracy_eq t p q]
  unfold totalVariation
  linarith

/-- **精确刻画**：最优可达优势恰为 `TV/2`。

这是对原始分析最重要的精确化：可识别性不是"能/不能"的二元开关，
而是由 `TV` 连续控制的实数。`TV/2` 就是**任何检验相对随机猜测所能拿到的全部优势**。 -/
theorem accuracy_bounds (t : Test n) (p q : PMF n) :
    |accuracy t p q - 1 / 2| ≤ totalVariation p q / 2 := by
  rw [abs_le]
  constructor
  · linarith [accuracy_ge t p q]
  · linarith [accuracy_le t p q]

/-- **贝叶斯最优性**：贝叶斯检验达到上界，正确率恰为 `(1 + TV)/2`。 -/
theorem bayes_optimal (p q : PMF n) :
    accuracy (bayes p q) p q = (1 + totalVariation p q) / 2 := by
  have key : ∀ i : Fin n,
      (if bayes p q i then p.val i - q.val i else q.val i - p.val i)
        = |p.val i - q.val i| := by
    intro i
    by_cases h : p.val i ≥ q.val i
    · have h1 : (if bayes p q i then p.val i - q.val i else q.val i - p.val i)
          = p.val i - q.val i := by simp [bayes_eq, h]
      rw [h1, abs_of_nonneg (sub_nonneg.mpr h)]
    · have h1 : (if bayes p q i then p.val i - q.val i else q.val i - p.val i)
          = q.val i - p.val i := by simp [bayes_eq, h]
      rw [h1, abs_of_neg (sub_lt_zero.mpr (lt_of_not_ge h))]
      ring
  rw [accuracy_eq (bayes p q) p q]
  unfold totalVariation
  rw [Finset.sum_congr rfl (fun i _ => key i)]
  ring

/-- **最优错误率**：`= (1 − TV)/2`。这是原始分析 `P_e = ½(1 − TV)` 的形式化。 -/
theorem bayes_errRate (p q : PMF n) :
    errRate (bayes p q) p q = (1 - totalVariation p q) / 2 := by
  rw [errRate, bayes_optimal]; ring

/-- **错误率下界**：任何检验的错误率都不低于 `(1 − TV)/2`。 -/
theorem errRate_ge (t : Test n) (p q : PMF n) :
    (1 - totalVariation p q) / 2 ≤ errRate t p q := by
  rw [errRate]
  linarith [accuracy_le t p q]

/-! ## 不可识别性（原始分析第 1 节的判决） -/

/-- **不可识别性定理**：`TV = 0` 时，**任何**检验的正确率**恰为** `1/2`。

注意这是精确等于，而非"接近随机"。形式化系统不接受近似表述。 -/
theorem unidentifiable (p q : PMF n) (h : totalVariation p q = 0) (t : Test n) :
    accuracy t p q = 1 / 2 := by
  have hle := accuracy_le t p q
  have hge := accuracy_ge t p q
  rw [h] at hle hge
  linarith

/-- **可识别性的充要条件**：`∃` 优于随机的检验 `⟺ TV > 0`。

这把原始分析的核心断言"来源可识别性 = TV(p_H, p_A)"精确化了：
不仅可识别性等价于 `TV > 0`，而且优势大小被 `TV/2` 完全决定。 -/
theorem identifiable_iff (p q : PMF n) :
    (∃ t : Test n, accuracy t p q > 1 / 2) ↔ 0 < totalVariation p q := by
  constructor
  · rintro ⟨t, ht⟩
    have hle := accuracy_le t p q
    have : (1 / 2 : ℝ) < (1 + totalVariation p q) / 2 := lt_of_lt_of_le ht hle
    linarith
  · intro h
    refine ⟨bayes p q, ?_⟩
    have hbo := bayes_optimal p q
    linarith

/-- **贝叶斯错误率随 TV 严格下降**：TV 越大越可分，最优错误率越小。

（注意：`(1 − TV)/2` 关于 TV 是**递减**函数——TV 越大，错误率越小。
初稿曾把不等号方向写反，Lean 直接拒绝，这正是形式化校验的价值。） -/
theorem errRate_strictly_decreasing {p q p' q' : PMF n}
    (h : totalVariation p' q' < totalVariation p q) :
    errRate (bayes p q) p q < errRate (bayes p' q') p' q' := by
  rw [bayes_errRate, bayes_errRate]
  have hlt : (1 : ℝ) - totalVariation p q < 1 - totalVariation p' q' := sub_lt_sub_left h 1
  rw [div_eq_mul_inv, div_eq_mul_inv]
  exact mul_lt_mul_of_pos_right hlt (inv_pos.mpr (by norm_num : (0:ℝ) < 2))

/-! ## 检验类的表达力（对原始分析的修正 #2）

`accuracy_le` 对**任意**检验成立，因此对任意检验类也成立——
这说明"分布有差异"与"实际能检出"之间隔着**检验类的表达力**这一层。
下式说明：只有当检验类包含贝叶斯检验时，上界才可达。

-/

theorem testClass_upperBound (p q : PMF n) (𝒯 : Set (Test n))
    (t : Test n) (_ht : t ∈ 𝒯) :
    accuracy t p q ≤ (1 + totalVariation p q) / 2 :=
  accuracy_le t p q

theorem testClass_attainsBound (p q : PMF n) (𝒯 : Set (Test n))
    (hb : bayes p q ∈ 𝒯) :
    ∃ t ∈ 𝒯, accuracy t p q = (1 + totalVariation p q) / 2 :=
  ⟨bayes p q, hb, bayes_optimal p q⟩

end Provenance
