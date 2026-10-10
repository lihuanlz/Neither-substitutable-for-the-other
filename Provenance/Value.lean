/-
# 影响力与价值的可分离性

本文件形式化对原始框架的一个**方向性反驳**：

> `D_KL( p(θ|D_A,h) ‖ p(θ|D_A) )` 衡量的是数据 `h` 的**影响力**，
> 不是它的**价值**。因此不能用它来给人类输出定价。

反驳的形式是一条可证的定理：存在两条人类输出，
它们对不可约下界 \(\Phi\) 的**影响力大小完全相同**，
但价值**符号相反**——一条有益 \(+M\) 比特，另一条有害 \(-M\) 比特，
且 \(M\) 可以任意大。

推论：任何**只依赖影响大小**的价值度量或排序，必然把有益输出与有害输出等同。
故价值函数必须带符号，或必须额外引入效用/方向信息。

## 主结果

* `influence_value_separable` —— 影响力绝对值相同、价值符号相反，且量级任意大。
* `separation_grows_without_bound` —— "影响很小"不是借口。
* `positive_layer_gain_iff_strict_drop` —— **人类输出有正层间价值
  ⟺ 它严格降低了不可约下界**。这是"好问题"的可证伪判据。
* `zero_gain_iff_equal` —— **价值为零 ⟺ 层未改变**。
* `layered_bits_decomposition` —— 总对数收益 = 层间 + 层内（统一到比特）。
* `cover_value_is_a_layer_gain` —— 覆盖新模态的价值**就是**层间收益的特例，
  不是并列的第三项。
* `influence_and_value_are_distinct` —— 打包陈述。

-/

import Mathlib.Tactic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Provenance.Refinement

open scoped BigOperators

namespace Provenance

/-! ## 1. 影响力与价值可分离（核心反驳） -/

/-- **影响力—价值可分离定理**。

对任意量级 \(M>0\)，存在两层下界 \(p,q\) 与 \(r,s\)，使得

* 影响力大小完全相同：\(\big|\log(p/q)\big| = \big|\log(r/s)\big|\)；
* 价值符号相反：\(\log(p/q) > 0\) 而 \(\log(r/s) < 0\)。

构造：取 \(p=e^M,\ q=1,\ r=1,\ s=e^M\)。前者价值 \(+M\) 比特，
后者价值 \(-M\) 比特，影响力绝对值都是 \(M\)。

**这直接否掉「用影响力（KL / 任何信息增益）代理价值」的方案。** -/
theorem influence_value_separable {M : ℝ} (hM : 0 < M) :
    ∃ p q r s : ℝ,
      (0 < p ∧ 0 < q ∧ 0 < r ∧ 0 < s) ∧
      |Real.log (p / q)| = |Real.log (r / s)| ∧
      (0 < Real.log (p / q)) ∧ (Real.log (r / s) < 0) := by
  have hpos : 0 < Real.exp M := Real.exp_pos M
  have h₁ : |Real.log (Real.exp M / 1)| = M := by
    rw [Real.log_div (ne_of_gt hpos) one_ne_zero,
        Real.log_one, Real.log_exp, sub_zero, abs_of_pos hM]
  have h₂ : |Real.log (1 / Real.exp M)| = M := by
    rw [Real.log_div one_ne_zero (ne_of_gt hpos),
        Real.log_one, Real.log_exp, abs_of_neg (by linarith : (0 - M : ℝ) < 0)]
    ring
  refine ⟨Real.exp M, 1, 1, Real.exp M,
    ⟨hpos, (by norm_num : (0:ℝ) < 1), (by norm_num : (0:ℝ) < 1), hpos⟩,
    h₁.trans h₂.symm, ?_, ?_⟩
  · rw [Real.log_div (ne_of_gt hpos) one_ne_zero, Real.log_one, Real.log_exp]
    linarith
  · rw [Real.log_div one_ne_zero (ne_of_gt hpos), Real.log_one, Real.log_exp]
    linarith

/-- **可分离性无法靠"影响很小"来回避**：分离量级 \(M\) 可以任意大。

所以问题不在于"筛选掉影响小的样本"——**影响大恰恰是最危险的情形**。 -/
theorem separation_grows_without_bound {M : ℝ} (hM : 0 < M) :
    ∃ p q r s : ℝ,
      0 < p ∧ 0 < q ∧ 0 < r ∧ 0 < s ∧
      M ≤ |Real.log (p / q)| ∧ (0 < Real.log (p / q)) ∧ (Real.log (r / s) < 0) := by
  have hpos : 0 < Real.exp M := Real.exp_pos M
  refine ⟨Real.exp M, 1, 1, Real.exp M, hpos,
    (by norm_num : (0:ℝ) < 1), (by norm_num : (0:ℝ) < 1), hpos, ?_, ?_, ?_⟩
  · rw [Real.log_div (ne_of_gt hpos) one_ne_zero,
        Real.log_one, Real.log_exp, sub_zero, abs_of_pos hM]
  · rw [Real.log_div (ne_of_gt hpos) one_ne_zero, Real.log_one, Real.log_exp, sub_zero]
    linarith
  · rw [Real.log_div one_ne_zero (ne_of_gt hpos), Real.log_one, Real.log_exp]
    linarith

/-! ## 2. 好问题的可证伪判据 -/

/-- **正层间价值 ⟺ 严格降低不可约下界**。

这条把"什么算好问题"从修辞变成可判定的条件：

    人类输出有正价值  ⟺  它使 Φ(β) < Φ(α)  ⟺  它让"真实"更可识别

换言之：**不降低 \(\Phi\) 的提问，价值精确为 0**。 -/
theorem positive_layer_gain_iff_strict_drop {Φα Φβ : ℝ}
    (hα : 0 < Φα) (hβ : 0 < Φβ) :
    0 < Real.log (Φα / Φβ) ↔ Φβ < Φα := by
  rw [Real.log_div (ne_of_gt hα) (ne_of_gt hβ)]
  constructor
  · intro h
    have h1 : Real.log Φβ < Real.log Φα := by linarith
    by_contra hcon
    have hge : Φα ≤ Φβ := le_of_not_gt hcon
    have h2 : Real.log Φα ≤ Real.log Φβ := (Real.log_le_log_iff hα hβ).mpr hge
    exact h1.ne (le_antisymm h1.le h2)
  · intro h
    have h1 : Real.log Φβ < Real.log Φα := (Real.log_lt_log_iff hβ hα).mpr h
    linarith

/-- **价值为零 ⟺ 层未改变**（无变化即无价值）。 -/
theorem zero_gain_iff_equal {Φα Φβ : ℝ} (hα : 0 < Φα) (hβ : 0 < Φβ) :
    Real.log (Φα / Φβ) = 0 ↔ Φα = Φβ := by
  rw [Real.log_div (ne_of_gt hα) (ne_of_gt hβ)]
  constructor
  · intro h
    have h1 : Real.log Φα = Real.log Φβ := by linarith
    exact (Real.strictMonoOn_log.eq_iff_eq hα hβ).mp h1
  · intro h
    rw [h]
    ring

/-! ## 3. 统一到比特的两项分解 -/

/-- **比特单位的两项分解**。

这是修正 `V(h) = ΔΦ + Δe^α + ΔCover` 的正确形式：
三项量纲不同（误差 / 误差 / 权重），必须先转成比特；
而"覆盖新模态"本身就是切层的特例，故并入第一项，不再单列。

    总对数收益  =  层间收益  +  层内收益

两个残差相乘恰为原残差，所以**不存在重复计数**。

（数学内容即 `Provenance.layered_decomposition`；此处按"比特账"重述，
  以便与"影响力 / 价值"两条线并列引用。） -/
theorem layered_bits_decomposition {Φα Φβ eN : ℝ}
    (hα : 0 < Φα) (hβ : 0 < Φβ) (heN : 0 < eN) :
    Real.log (Φα / eN) = Real.log (Φα / Φβ) + Real.log (Φβ / eN) :=
  layered_decomposition hα hβ heN

/-- **覆盖带来的价值就是层间收益**，不是并列的第三项。

取 \(\Phi(\alpha)=1\)、\(\Phi(\beta)=e^{-M}\)，则覆盖一个新模态换来的
价值恰为 \(M\) 比特——落在层间收益的取值范围内，无上界。

（这把 `ΔCover` 从分解式中移除，消除重复计数。） -/
theorem cover_value_is_a_layer_gain {M : ℝ} (hM : 0 ≤ M) :
    ∃ Φα Φβ : ℝ, 0 < Φβ ∧ Φβ ≤ Φα ∧ Real.log (Φα / Φβ) = M :=
  human_gain_unbounded hM

/-! ## 4. 符号不可省 -/

/-- **价值必须带符号**。

本文件全部结果合起来给出：`human_gain_unbounded`（层间收益无上界）
与 `ai_total_gain_bounded`（层内收益有硬上界）构成严格的不对称，
而 `influence_value_separable` 说明这个不对称**不能**用"影响大小"来代理。

故完整的贡献账必须记两个量：
**影响力（大小，无符号）** 与 **价值（比特，有符号）**。 -/
theorem influence_and_value_are_distinct {M : ℝ} (hM : 0 < M) :
    (∃ p q r s : ℝ, 0 < p ∧ 0 < q ∧ 0 < r ∧ 0 < s ∧
      |Real.log (p / q)| = |Real.log (r / s)| ∧
      (0 < Real.log (p / q)) ∧ (Real.log (r / s) < 0))
      ∧ (∀ M' : ℝ, 0 ≤ M' → ∃ Φα Φβ : ℝ,
          0 < Φβ ∧ Φβ ≤ Φα ∧ Real.log (Φα / Φβ) = M')
      ∧ (∀ e0 Φ eN : ℝ, 0 < e0 → 0 < Φ → 0 < eN → Φ ≤ eN →
          Real.log (e0 / eN) ≤ Real.log (e0 / Φ)) := by
  refine ⟨?_, ?_, ?_⟩
  · obtain ⟨p, q, r, s, hp, hlt, hpos, hneg⟩ := influence_value_separable hM
    exact ⟨p, q, r, s, hp.1, hp.2.1, hp.2.2.1, hp.2.2.2, hlt, hpos, hneg⟩
  · exact fun _ h => human_gain_unbounded h
  · exact fun e0 Φ eN he0 hΦ heN hle => ai_total_gain_bounded he0 hΦ heN hle

end Provenance