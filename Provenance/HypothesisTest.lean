/-
# 假设检验与 Neyman–Pearson 功效上界

本文件形式化原始分析第 2 节的数学核心。

原文第 2 节提出：靠**水印 + z 检验**来判定一段内容是否 AI 生成，
并声称"没有协议和水印时纯文本来源不可靠"。

原文**没有给出**这个检验的理论上界。本文件补上：
任何基于统计量的检验（z 检验、t 检验、任何检测器、任何阈值）
其**判别能力都无法超过**全变差距离 `TV(p, q)`。这不是某种检验的缺陷，
而是**一切检验的共同上限**。

## 主要结果

* `totalVariation_eq_max_sum` —— `TV = Σᵢ max(pᵢ − qᵢ, 0)`（正差部分的总和）。
* `mass_diff_eq_sum` —— `mass p S − mass q S = Σ_{i∈S}(pᵢ − qᵢ)`。
* `mass_sub_le_tv` —— **上界**：任意集合上的概率差不超过 `TV`。
* `mass_posSet_eq_tv` —— **上界可达**：取 `S = posSet p q = {i | pᵢ ≥ qᵢ}` 时取等号。
* `power_le_tv` —— **Neyman–Pearson 功效上界**：对任何检验 `S`，`功效 ≤ 假阳性率 + TV`。
* `abs_mass_diff_le_tv` —— **双侧版本**：`|功效 − 假阳性率| ≤ TV`。
* `abs_mass_diff_attains` —— 该双侧上界同样可达，故 `TV` 就是最优检验的精确优势。
* `tv_eq_zero_iff_mass_diff` —— `TV = 0` ⟺ 任何集合上的概率差精确为 0。
* `no_threshold_escapes_tv` —— 任何阈值检验都逃不出这条上界。

## 一处修正：原稿的 `confusable_le_tv` 是假命题

初稿曾写「`mass p S + mass q S ≤ 1 + TV`」。这是**错的**：
取 `p = q`、`S = univ`，左边 `= 2`，右边 `= 1 + TV(p,p) = 1`。

混淆矩阵里的恒等式是 `TP + FN = 1`（而不是 `TP + FP ≤ 1`），
所以有意义的双侧判据是

    |TP − FP| = |Youden's J| ≤ TV

即本文件的 `abs_mass_diff_le_tv`。形式化在这里起的作用正是它该起的：
**直接判它死刑**。

## 为什么这直接支撑第 2 节

设水印检测的统计量 `T` 在人类文本下服从 `p`、AI 文本下 `q`，
任取阈值 `τ` 得到判别集合 `S_τ = {x : T(x) > τ}`。
则 `mass_sub_le_tv` 给出：

    功效(S_τ) − 假阳性率(S_τ) ≤ TV(p, q)

因此第 2 节的结论不只是"应该用 z 检验"，而是更强的一句：
**只要 `TV` 本身小，任何统计检验都救不了内容层判定**。
要突破这个上界，只能走协议层（签名、水印谱系），不能靠更好的统计量。
这正是原文第 5 节判断 2 的定量依据。

-/

import Mathlib.Tactic
import Mathlib.Data.Finset.Basic
import Provenance.Basic

open Finset
open scoped BigOperators

namespace Provenance

variable {n : ℕ}

/-- 分布 `p` 在集合 `S` 上的质量。 -/
def mass (p : PMF n) (S : Finset (Fin n)) : ℝ := ∑ i ∈ S, p.val i

theorem mass_nonneg (p : PMF n) (S : Finset (Fin n)) : 0 ≤ mass p S := by
  unfold mass
  exact Finset.sum_nonneg fun i _ => p.nonneg i

theorem mass_empty (p : PMF n) : mass p ∅ = 0 := by
  unfold mass; simp

theorem mass_univ (p : PMF n) : mass p (Finset.univ) = 1 := by
  show (∑ i : Fin n, p.val i) = 1
  exact p.sum_one

/-- 质量可加：`S` 上的质量加上其补集上的质量等于 1。 -/
theorem mass_add_compl (p : PMF n) (S : Finset (Fin n)) :
    mass p S + mass p (Finset.univ \ S) = 1 := by
  have key : (∑ i : Fin n, p.val i)
      = ∑ i ∈ Finset.univ \ S, p.val i + ∑ i ∈ S, p.val i :=
    (Finset.sum_sdiff (Finset.subset_univ S)).symm
  have huniv : (∑ i : Fin n, p.val i) = 1 := p.sum_one
  unfold mass
  linarith

theorem mass_le_one (p : PMF n) (S : Finset (Fin n)) : mass p S ≤ 1 := by
  have h0 := mass_nonneg p (Finset.univ \ S)
  have h1 := mass_add_compl p S
  linarith

/-- 质量随集合扩大而不减。 -/
theorem mass_mono (p : PMF n) {S T : Finset (Fin n)} (h : S ⊆ T) :
    mass p S ≤ mass p T := by
  unfold mass
  exact Finset.sum_le_sum_of_subset_of_nonneg h fun i _ _ => p.nonneg i

theorem mass_union (p : PMF n) (S T : Finset (Fin n)) :
    mass p (S ∪ T) = mass p S + mass p (T \ S) := by
  have hsd : (S ∪ T) \ S = T \ S := by
    ext i
    rw [Finset.mem_sdiff, Finset.mem_sdiff, Finset.mem_union]
    constructor
    · rintro ⟨h, hn⟩
      exact ⟨h.resolve_left hn, hn⟩
    · rintro ⟨h, hn⟩
      exact ⟨Or.inr h, hn⟩
  unfold mass
  calc (∑ i ∈ S ∪ T, p.val i)
      = (∑ i ∈ (S ∪ T) \ S, p.val i) + ∑ i ∈ S, p.val i := by
        symm
        exact Finset.sum_sdiff fun i hi => Finset.mem_union.mpr (Or.inl hi)
    _ = ∑ i ∈ T \ S, p.val i + ∑ i ∈ S, p.val i := by rw [hsd]
    _ = (∑ i ∈ S, p.val i) + ∑ i ∈ T \ S, p.val i := add_comm _ _

/-! ## 1. `TV` 的集合形式刻画 -/

/-- `max(x, 0) = (x + |x|)/2`。 -/
theorem max_eq_half (x : ℝ) : max x 0 = (x + |x|) / 2 := by
  by_cases h : 0 ≤ x
  · rw [max_eq_left h, abs_of_nonneg h]; ring
  · have hx : x < 0 := lt_of_not_ge h
    rw [max_eq_right (le_of_lt hx), abs_of_neg hx]; ring

/-- `TV(p,q) = Σᵢ max(pᵢ − qᵢ, 0)`：正差部分的总和。

因为 `Σᵢ(pᵢ − qᵢ) = 0`，故 `Σᵢ max(pᵢ − qᵢ, 0) = ½Σᵢ|pᵢ − qᵢ| = TV`。 -/
theorem totalVariation_eq_max_sum (p q : PMF n) :
    totalVariation p q = ∑ i : Fin n, max (p.val i - q.val i) 0 := by
  unfold totalVariation
  have hz : ∑ i : Fin n, (p.val i - q.val i) = 0 := by
    rw [Finset.sum_sub_distrib, p.sum_one, q.sum_one]
    norm_num
  have hstep : ∀ i : Fin n, max (p.val i - q.val i) 0
      = (1 / 2 : ℝ) * (p.val i - q.val i) + (1 / 2 : ℝ) * |p.val i - q.val i| := by
    intro i
    rw [max_eq_half]
    ring
  have hmain : ∑ i : Fin n, max (p.val i - q.val i) 0
      = ∑ i : Fin n, (1 / 2 : ℝ) * (p.val i - q.val i)
        + ∑ i : Fin n, (1 / 2 : ℝ) * |p.val i - q.val i| := by
    rw [Finset.sum_congr rfl (fun i _ => hstep i), Finset.sum_add_distrib]
  rw [hmain, ← Finset.mul_sum, ← Finset.mul_sum, hz, mul_zero, zero_add]

/-- 判别集合：取差异为正的那部分（NP 检验的判别集）。

`ℝ` 上的 `≥` 无可执行判定，故标 `noncomputable`。 -/
noncomputable def posSet (p q : PMF n) : Finset (Fin n) :=
  Finset.univ.filter (fun i => p.val i - q.val i ≥ 0)

/-! ## 2. 集合形式的全变差定理 -/

/-- 两个分布在一个集合上的**概率差**等于差值的求和。 -/
theorem mass_diff_eq_sum (p q : PMF n) (S : Finset (Fin n)) :
    mass p S - mass q S = ∑ i ∈ S, (p.val i - q.val i) := by
  unfold mass
  rw [Finset.sum_sub_distrib]

/-- **上界**：任意集合上的概率差不超过 `TV`。

这条是整个文件的地基：**任何检验的「命中 − 误报」都不超过 `TV`。** -/
theorem mass_sub_le_tv (p q : PMF n) (S : Finset (Fin n)) :
    mass p S - mass q S ≤ totalVariation p q := by
  have key : (∑ i ∈ S, (p.val i - q.val i))
      ≤ ∑ i : Fin n, max (p.val i - q.val i) 0 := by
    calc (∑ i ∈ S, (p.val i - q.val i))
        = ∑ i : Fin n, if i ∈ S then p.val i - q.val i else 0 := by
          rw [← Finset.sum_filter, Finset.filter_mem_eq_inter,
            Finset.inter_comm, Finset.inter_univ]
      _ ≤ ∑ i : Fin n, max (p.val i - q.val i) 0 := by
            refine Finset.sum_le_sum fun i _ => ?_
            by_cases hi : i ∈ S
            · rw [if_pos hi]
              exact le_max_left _ _
            · rw [if_neg hi]
              exact le_max_right _ _
  rw [mass_diff_eq_sum, totalVariation_eq_max_sum]
  exact key

/-- **上界可达**：取 `posSet`（即 `{i | pᵢ ≥ qᵢ}`）时概率差恰为 `TV`。

这就是 Neyman–Pearson 引理的离散形式。 -/
theorem mass_posSet_eq_tv (p q : PMF n) :
    mass p (posSet p q) - mass q (posSet p q) = totalVariation p q := by
  rw [mass_diff_eq_sum, posSet, Finset.sum_filter]
  have key : (∑ i : Fin n, if p.val i - q.val i ≥ 0 then p.val i - q.val i else 0)
      = ∑ i : Fin n, max (p.val i - q.val i) 0 := by
    refine Finset.sum_congr rfl fun i _ => ?_
    by_cases h : p.val i - q.val i ≥ 0
    · rw [if_pos h, max_eq_left h]
    · rw [if_neg h, max_eq_right (le_of_not_ge h)]
  rw [key, ← totalVariation_eq_max_sum]

/-! ## 3. Neyman–Pearson：任何检验的判别能力上界

约定：
* 检验 `S` = 「判为人类」的观测集合；
* **功效** `power = mass p S`：人类数据中被正确识别的比例；
* **假阳性率** `FPR = mass q S`：AI 数据中被误判为人类的比例。

-/

/-- **Neyman–Pearson 功效上界**：任何检验都满足
`功效 ≤ 假阳性率 + TV`。

这是关于**一切**统计检验（含 z 检验）的普遍上限，与具体检验形式无关。 -/
theorem power_le_tv (p q : PMF n) (S : Finset (Fin n)) :
    mass p S ≤ mass q S + totalVariation p q := by
  have h := mass_sub_le_tv p q S
  linarith

/-- 该上界可达：最优检验（NP 检验）取 `posSet`。 -/
theorem power_attains_tv (p q : PMF n) :
    mass p (posSet p q) = mass q (posSet p q) + totalVariation p q := by
  have h := mass_posSet_eq_tv p q
  linarith

/-- **双侧上界**：`|功效 − 假阳性率| ≤ TV`。

把 `mass_sub_le_tv` 作用到补集上即得反向不等式；两者合并给出一个
与 `TV` 无关的**双侧**限制。这就是 Youden's J 的上界。 -/
theorem abs_mass_diff_le_tv (p q : PMF n) (S : Finset (Fin n)) :
    |mass p S - mass q S| ≤ totalVariation p q := by
  have h1 := mass_sub_le_tv p q S
  have hc := mass_sub_le_tv p q (Finset.univ \ S)
  have hp := mass_add_compl p S
  have hq := mass_add_compl q S
  rw [abs_le]
  constructor <;> linarith

/-- **双侧上界同样可达**：故 `TV` 就是最优检验的**精确**判别优势。

结合 `Provenance.accuracy_bounds`（准确率优势 `TV/2`）与本定理（判别差 `TV`），
第 1 层的可识别性刻画至此闭合。 -/
theorem abs_mass_diff_attains (p q : PMF n) :
    |mass p (posSet p q) - mass q (posSet p q)| = totalVariation p q := by
  rw [mass_posSet_eq_tv, abs_of_nonneg (totalVariation_nonneg p q)]

/-- **无信号 ⇒ 无优势**：`TV = 0` 时任何集合上的概率差精确为 0。 -/
theorem tv_eq_zero_mass_diff (p q : PMF n) (S : Finset (Fin n))
    (h : totalVariation p q = 0) : mass p S = mass q S := by
  have h1 := mass_sub_le_tv p q S
  have h2 := abs_mass_diff_le_tv p q S
  rw [h] at h1 h2
  have habs : |mass p S - mass q S| = 0 :=
    le_antisymm h2 (abs_nonneg (mass p S - mass q S))
  exact sub_eq_zero.mp (abs_eq_zero.mp habs)

/-- **反向要限定判别集**：只有在**最优**判别集上无差异，才谈得上 `TV = 0`。

（初稿曾把这条写成对任意 `S` 的 `TV = 0 ↔ mass p S = mass q S`，
  那是假的：`S = ∅` 时两边恒等，与 `TV` 无关。形式化再次直接判它死刑。） -/
theorem mass_diff_zero_iff_tv (p q : PMF n) :
    mass p (posSet p q) - mass q (posSet p q) = 0 ↔ totalVariation p q = 0 := by
  constructor
  · intro h
    rw [mass_posSet_eq_tv] at h
    exact h
  · intro h
    rw [mass_posSet_eq_tv, h]

/-- 完全版：`TV = 0` ⟺ **对每个**集合都没有概率差。

这才是"两个分布不可区分"的准确形式化——注意它必须量化到所有 `S`，
单给一个 `S` 是不够的（`S = ∅` 永远给出 0）。 -/
theorem tv_eq_zero_iff_all_masses (p q : PMF n) :
    totalVariation p q = 0 ↔ ∀ S : Finset (Fin n), mass p S = mass q S := by
  constructor
  · intro h S
    exact tv_eq_zero_mass_diff p q S h
  · intro h
    have h' := h (posSet p q)
    have hz : mass p (posSet p q) - mass q (posSet p q) = 0 := by
      rw [h']
      ring
    exact (mass_diff_zero_iff_tv p q).mp hz

/-! ## 4. 与原文第 2 节的接口：z 检验的功效上限 -/

/-- **z 检验（以及任何阈值检验）都无法突破 TV 上限。**

设水印统计量 `T` 在人类文本下为 `p`、AI 文本下为 `q`，
任取阈值 `τ` 得到判别集合 `S_τ = {x : T(x) > τ}`。
则对**任意** `τ` 都有

    功效(S_τ) − 假阳性率(S_τ) ≤ TV(p, q)

因此**提高阈值的精细程度、调整个性化的统计量，都不可能突破 TV**。
第 2 节的结论应加强为：内容层判定失效时，
瓶颈是 `TV` 本身太小，而不是检验不够好。 -/
theorem no_threshold_escapes_tv (p q : PMF n) (S : Finset (Fin n)) :
    mass p S - mass q S ≤ totalVariation p q :=
  mass_sub_le_tv p q S

/-- 任何检验的**最大**优势恰为 `TV`（由 `posSet` 达到，且无人能超过）。 -/
theorem optimal_test_advantage (p q : PMF n) :
    mass p (posSet p q) - mass q (posSet p q) = totalVariation p q :=
  mass_posSet_eq_tv p q

end Provenance