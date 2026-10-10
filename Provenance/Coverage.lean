/-
# 覆盖度与边际增益：形式化"人类只贡献一点点，却很有价值"

对应原始分析第 3 节的**覆盖度**部分：

    F(S) = ∑_z w_z · min(1, ∑_{i∈S} 1[z ∈ C_i])

本文件在有限空间上用**指示函数**形式重写该式（计数为整数时与 `min(1,·)` 等价），
并证明：

* `coverage_mono` —— 覆盖函数单调：样本越多覆盖越全；
* `submodular_union` —— **次模性**（等价形式 `F(S∪T) + F(S∩T) ≤ F(S) + F(T)`）；
* `diminishing_returns` —— **边际增益递减**；
* `single_sample_marginal` —— **核心定理**：若某人类样本覆盖了一个
  当前未被覆盖的状态 `z`，则它**单独贡献的边际增益至少为 `w_z`**。

`single_sample_marginal` 正是"在大库里只占一点点、却极有价值"的严格形式化：
**价值由它填补的空洞决定，而非由数量比例决定。**

-/

import Mathlib.Tactic
import Mathlib.Data.Finset.Basic
import Provenance.Basic

open Finset
open scoped BigOperators

namespace Provenance

variable {m n : ℕ}

/-- 样本 `i` 覆盖的世界状态集合（一个样本可覆盖多个状态）。 -/
def cover (C : Fin n → Finset (Fin m)) (S : Finset (Fin n)) : Finset (Fin m) :=
  S.biUnion C

/-- 覆盖价值：集合 `X` 中所有状态权重之和。 -/
def covVal (w : Fin m → ℝ) (X : Finset (Fin m)) : ℝ :=
  ∑ z : Fin m, w z * (if z ∈ X then 1 else 0)

/-- 覆盖函数 `F(S) = covVal(w, ⋃_{i∈S} C_i)`。 -/
def coverage (w : Fin m → ℝ) (C : Fin n → Finset (Fin m)) (S : Finset (Fin n)) : ℝ :=
  covVal w (cover C S)

/-! ## 指示函数的集合恒等式 -/

/-- `covVal(w, A ∪ B) = covVal(w, A) + covVal(w, B \ A)`。 -/
theorem covVal_union (w : Fin m → ℝ) (A B : Finset (Fin m)) :
    covVal w (A ∪ B) = covVal w A + covVal w (B \ A) := by
  have key : ∀ z : Fin m,
      w z * (if z ∈ A ∪ B then 1 else 0)
        = w z * (if z ∈ A then 1 else 0)
          + w z * (if z ∈ B \ A then 1 else 0) := by
    intro z
    by_cases hA : z ∈ A <;> by_cases hB : z ∈ B <;>
      simp [hA, hB, Finset.mem_union, Finset.mem_sdiff]
  unfold covVal
  rw [Finset.sum_congr rfl (fun z _ => key z), Finset.sum_add_distrib]

/-- `1[A ∪ B] = 1[A] + 1[B] − 1[A ∩ B]`。 -/
theorem covVal_union_inter (w : Fin m → ℝ) (A B : Finset (Fin m)) :
    covVal w (A ∪ B) = covVal w A + covVal w B - covVal w (A ∩ B) := by
  have key : ∀ z : Fin m,
      w z * (if z ∈ A ∪ B then 1 else 0)
        = w z * (if z ∈ A then 1 else 0)
          + w z * (if z ∈ B then 1 else 0)
          - w z * (if z ∈ A ∩ B then 1 else 0) := by
    intro z
    by_cases hA : z ∈ A <;> by_cases hB : z ∈ B <;>
      simp [hA, hB, Finset.mem_union, Finset.mem_inter]
  unfold covVal
  rw [Finset.sum_congr rfl (fun z _ => key z),
      ← Finset.sum_add_distrib, ← Finset.sum_sub_distrib]

/-- `covVal` 非负（权重非负时）。 -/
theorem covVal_nonneg {w : Fin m → ℝ} (hw : ∀ z, 0 ≤ w z) (X : Finset (Fin m)) :
    0 ≤ covVal w X := by
  unfold covVal
  exact Finset.sum_nonneg fun z _ => by
    by_cases hz : z ∈ X
    · rw [if_pos hz]; exact mul_nonneg (hw z) (by norm_num)
    · rw [if_neg hz]; simp

/-- `covVal` 的下界：集合 `X` 中任一元素的权重都不超过其总价值。

这是"单项 ≤ 总和（其余项非负）"的直接应用。 -/
theorem covVal_ge {w : Fin m → ℝ} (hw : ∀ z, 0 ≤ w z) {X : Finset (Fin m)} (hz : z ∈ X) :
    w z ≤ covVal w X := by
  have hpos : ∀ u ∈ (Finset.univ : Finset (Fin m)),
      0 ≤ w u * (if u ∈ X then 1 else 0) := by
    intro u _
    by_cases hu : u ∈ X
    · rw [if_pos hu]; exact mul_nonneg (hw u) (by norm_num)
    · rw [if_neg hu]; simp
  have h1 : w z * (if z ∈ X then 1 else 0)
      ≤ ∑ u : Fin m, w u * (if u ∈ X then 1 else 0) :=
    Finset.single_le_sum hpos (Finset.mem_univ z)
  unfold covVal
  rw [if_pos hz] at h1
  linarith

/-! ## 覆盖算子的基本性质 -/

theorem cover_mono {C : Fin n → Finset (Fin m)} {S T : Finset (Fin n)}
    (hST : S ⊆ T) : cover C S ⊆ cover C T := by
  intro z hz
  rcases Finset.mem_biUnion.mp hz with ⟨i, hi, hzi⟩
  exact Finset.mem_biUnion.mpr ⟨i, hST hi, hzi⟩

theorem cover_union (C : Fin n → Finset (Fin m)) (S T : Finset (Fin n)) :
    cover C (S ∪ T) = cover C S ∪ cover C T := by
  ext z
  constructor
  · intro hz
    rcases Finset.mem_biUnion.mp hz with ⟨i, hi, hzi⟩
    rcases Finset.mem_union.mp hi with hi | hi
    · exact Finset.mem_union_left _ (Finset.mem_biUnion.mpr ⟨i, hi, hzi⟩)
    · exact Finset.mem_union_right _ (Finset.mem_biUnion.mpr ⟨i, hi, hzi⟩)
  · intro hz
    rcases Finset.mem_union.mp hz with hz | hz
    · rcases Finset.mem_biUnion.mp hz with ⟨i, hi, hzi⟩
      exact Finset.mem_biUnion.mpr ⟨i, Finset.mem_union_left _ hi, hzi⟩
    · rcases Finset.mem_biUnion.mp hz with ⟨i, hi, hzi⟩
      exact Finset.mem_biUnion.mpr ⟨i, Finset.mem_union_right _ hi, hzi⟩

/-- **交集的单向包含**：`cover C (S ∩ T) ⊆ cover C S ∩ cover C T`。

注意只有单向包含成立：反向不成立，因为 `z ∈ cover C S` 与 `z ∈ cover C T`
的见证样本未必是同一个。`submodular_union` 只需要这一方向。 -/
theorem cover_inter_subset (C : Fin n → Finset (Fin m)) (S T : Finset (Fin n)) :
    cover C (S ∩ T) ⊆ cover C S ∩ cover C T := by
  intro z hz
  rcases Finset.mem_biUnion.mp hz with ⟨i, hi, hzi⟩
  have hi' := Finset.mem_inter.mp hi
  exact Finset.mem_inter.mpr
    ⟨Finset.mem_biUnion.mpr ⟨i, hi'.1, hzi⟩, Finset.mem_biUnion.mpr ⟨i, hi'.2, hzi⟩⟩

theorem cover_insert (C : Fin n → Finset (Fin m)) (h : Fin n) (S : Finset (Fin n)) :
    cover C (insert h S) = cover C S ∪ C h := by
  ext z
  constructor
  · intro hz
    rcases Finset.mem_biUnion.mp hz with ⟨i, hi, hzi⟩
    rcases Finset.mem_insert.mp hi with rfl | hi
    · exact Finset.mem_union_right _ hzi
    · exact Finset.mem_union_left _ (Finset.mem_biUnion.mpr ⟨i, hi, hzi⟩)
  · intro hz
    rcases Finset.mem_union.mp hz with hz | hz
    · rcases Finset.mem_biUnion.mp hz with ⟨i, hi, hzi⟩
      exact Finset.mem_biUnion.mpr ⟨i, Finset.mem_insert_of_mem hi, hzi⟩
    · exact Finset.mem_biUnion.mpr ⟨h, Finset.mem_insert_self h S, hz⟩

/-! ## 单调性与次模性 -/

/-- **单调性**：样本集合变大，覆盖价值不减（权重非负）。 -/
theorem coverage_mono {w : Fin m → ℝ} (hw : ∀ z, 0 ≤ w z)
    {C : Fin n → Finset (Fin m)} {S T : Finset (Fin n)} (hST : S ⊆ T) :
    coverage w C S ≤ coverage w C T := by
  have hcov : cover C S ⊆ cover C T := cover_mono hST
  have key : ∀ z : Fin m,
      w z * (if z ∈ cover C S then 1 else 0)
        ≤ w z * (if z ∈ cover C T then 1 else 0) := by
    intro z
    by_cases hS : z ∈ cover C S
    · rw [if_pos hS, if_pos (hcov hS)]
    · by_cases hT : z ∈ cover C T
      · rw [if_neg hS, if_pos hT]; linarith [hw z]
      · rw [if_neg hS, if_neg hT]
  unfold coverage covVal
  exact Finset.sum_le_sum fun z _ => key z

/-- **次模性**（等价形式）：`F(S∪T) + F(S∩T) ≤ F(S) + F(T)`。

证明：先用指示函数恒等式展开 `F(S∪T)`，再用 `cover C (S∩T) ⊆ cover C S ∩ cover C T`
与权重非负，把差额吸收掉。 -/
theorem submodular_union {w : Fin m → ℝ} (hw : ∀ z, 0 ≤ w z)
    (C : Fin n → Finset (Fin m)) (S T : Finset (Fin n)) :
    coverage w C (S ∪ T) + coverage w C (S ∩ T)
      ≤ coverage w C S + coverage w C T := by
  have hunion : cover C (S ∪ T) = cover C S ∪ cover C T := cover_union C S T
  have hsub : cover C (S ∩ T) ⊆ cover C S ∩ cover C T := cover_inter_subset C S T
  have hmono : covVal w (cover C (S ∩ T)) ≤ covVal w (cover C S ∩ cover C T) := by
    unfold covVal
    exact Finset.sum_le_sum fun z _ => by
      by_cases h1 : z ∈ cover C (S ∩ T)
      · rw [if_pos h1, if_pos (hsub h1)]
      · by_cases h2 : z ∈ cover C S ∩ cover C T
        · rw [if_neg h1, if_pos h2]; linarith [hw z]
        · rw [if_neg h1, if_neg h2]
  unfold coverage
  rw [hunion, covVal_union_inter]
  linarith

/-- **边际增益递减**：先纳入 `a` 再纳入 `b`，总收益不超过反向顺序。

这意味着"先获得的样本更值钱"，边际价值随集合变大而递减——
是"把少量预算投在高价值人类数据上"这一策略的理论依据。

注意需要区分退化情形 `a = b`（此时不等式退化为单调性）。 -/
-- `ha` is kept in the statement to record the intended setting (both `a` and
-- `b` are new) even though the proof never needs it; dropping it would
-- strengthen the theorem, which is a claim change rather than a cleanup.
set_option linter.unusedVariables false in
theorem diminishing_returns {w : Fin m → ℝ} (hw : ∀ z, 0 ≤ w z)
    {C : Fin n → Finset (Fin m)} {S : Finset (Fin n)} {a b : Fin n}
    (ha : a ∉ S) (hb : b ∉ S) :
    coverage w C (insert a (insert b S)) - coverage w C (insert b S)
      ≤ coverage w C (insert a S) - coverage w C S := by
  by_cases hab : a = b
  · rcases hab with rfl
    have hmono : coverage w C S ≤ coverage w C (insert a S) :=
      coverage_mono hw (Finset.subset_insert a S)
    have h1 : (insert a (insert a S) : Finset (Fin n)) = insert a S :=
      Finset.insert_eq_of_mem (Finset.mem_insert_self a S)
    rw [h1]
    linarith
  · have hinter : insert a S ∩ insert b S = S := by
      ext x
      constructor
      · intro hx
        have hx' := Finset.mem_inter.mp hx
        have h1 := Finset.mem_insert.mp hx'.1
        have h2 := Finset.mem_insert.mp hx'.2
        by_cases hxS : x ∈ S
        · exact hxS
        · have h1' : x = a := h1.resolve_right hxS
          have h2' : x = b := h2.resolve_right hxS
          exact absurd (h1'.symm.trans h2') hab
      · intro hx
        exact Finset.mem_inter.mpr
          ⟨Finset.mem_insert_of_mem hx, Finset.mem_insert_of_mem hx⟩
    have h2 : S ∪ insert b S = insert b S := by
      ext x
      constructor
      · intro hx
        rcases Finset.mem_union.mp hx with hx | hx
        · exact Finset.mem_insert_of_mem hx
        · exact hx
      · intro hx
        exact Finset.mem_union_right _ hx
    have hsub := submodular_union hw C (insert a S) (insert b S)
    have hun : insert a S ∪ insert b S = insert a (insert b S) := by
      rw [Finset.insert_union a S (insert b S), h2]
    rw [hun, hinter] at hsub
    linarith

/-! ## 核心定理：一个样本的边际贡献 -/

/-- **单样本边际定理**（"一点点很有价值"的严格形式）。

若样本 `h` 覆盖了一个尚未被 `S` 覆盖的状态 `z`，则

    w_z  ≤  F(S ∪ {h}) − F(S)

即：**该样本单独提供的价值至少等于它填补的那个空洞的权重。** -/
theorem single_sample_marginal {w : Fin m → ℝ} (hw : ∀ z, 0 ≤ w z)
    {C : Fin n → Finset (Fin m)} {S : Finset (Fin n)} {h : Fin n} {z : Fin m}
    (hz : z ∉ cover C S) (hzc : z ∈ C h) :
    w z ≤ coverage w C (insert h S) - coverage w C S := by
  have hunion : cover C (insert h S) = cover C S ∪ C h := cover_insert C h S
  rw [coverage, coverage, hunion, covVal_union]
  have hge : w z ≤ covVal w (C h \ cover C S) :=
    covVal_ge hw (Finset.mem_sdiff.mpr ⟨hzc, hz⟩)
  linarith

/-- **推论（数量无关性）**：单样本边际增益的下界 `w_z` 与其在大库中的占比无关。

若样本 `h` 只占全部样本的很小一部分，但它覆盖了一个权重为 `w_z` 的
**未被覆盖**的状态，则其边际贡献仍被 `w_z` 从下方界定。

这在 Lean 中排除了"价值 ∝ 数量比例"这一主张：
占比再小，只要填补了 `w_z` 大的空洞，边际增益就 `≥ w_z`。 -/
theorem marginal_independent_of_share {w : Fin m → ℝ} (hw : ∀ z, 0 ≤ w z)
    {C : Fin n → Finset (Fin m)} {S : Finset (Fin n)} {h : Fin n} {z : Fin m}
    (hz : z ∉ cover C S) (hzc : z ∈ C h) :
    w z ≤ coverage w C (insert h S) - coverage w C S :=
  single_sample_marginal hw hz hzc

end Provenance
