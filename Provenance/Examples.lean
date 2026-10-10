/-
# 数值验证：精确有理数实例（由 Lean 证明具体数值）

类型检查只能保证定理为真。本文件**在具体分布上证明具体数值**，
把原始分析里的公式与 Lean 定理逐条对拍。

注意：这些是**精确的相等式**（例如 `totalVariation pA pB = 1/3`），
不是 `#eval` 打印的近似值。`ℝ` 上的运算不可执行，故用证明代替求值——
这比打印数值更强：任何数值不符都会直接导致编译失败。

对照表：

| 实例                      | TV      | 贝叶斯正确率 | 理论 (1+TV)/2 | 贝叶斯错误率 | 理论 (1−TV)/2 |
|---------------------------|---------|--------------|---------------|--------------|---------------|
| 完全相同 (unidentifiable) | 0       | 1/2          | 1/2           | 1/2          | 1/2           |
| 弱可分                    | 1/6     | 7/12         | 7/12          | 5/12         | 5/12          |
| 中等可分                  | 1/3     | 2/3          | 2/3           | 1/3          | 1/3           |
| 完全可分                  | 1       | 1            | 1             | 0            | 0             |

-/

import Mathlib.Tactic
import Mathlib.Data.Finset.Basic
import Provenance.Basic
import Provenance.Contamination

namespace Provenance

open Finset
open scoped BigOperators

/-! ### `ℝ` 上绝对值的显式化简

`norm_num` 不会自动判定 `|q : ℝ|` 的符号，故把会用到的正有理数逐一化简。 -/

private theorem absHalf : |(1 / 2 : ℝ)| = 1 / 2 := abs_of_nonneg (by norm_num)
private theorem absThird : |(1 / 3 : ℝ)| = 1 / 3 := abs_of_nonneg (by norm_num)
private theorem absSixth : |(1 / 6 : ℝ)| = 1 / 6 := abs_of_nonneg (by norm_num)
private theorem absQuarter : |(1 / 4 : ℝ)| = 1 / 4 := abs_of_nonneg (by norm_num)
private theorem absEighth : |(1 / 8 : ℝ)| = 1 / 8 := abs_of_nonneg (by norm_num)
private theorem absTwelfth : |(1 / 12 : ℝ)| = 1 / 12 := abs_of_nonneg (by norm_num)



/-- 四点空间上由四个非负数构造 PMF。 -/
noncomputable def mkPMF4 (a b c d : ℝ) (h0 : 0 ≤ a) (h1 : 0 ≤ b) (h2 : 0 ≤ c) (h3 : 0 ≤ d)
    (hs : a + b + c + d = 1) : PMF 4 where
  val := fun i => match i.val with
    | 0 => a | 1 => b | 2 => c | 3 => d
    | _ => 0
  nonneg := by
    intro i
    fin_cases i <;> assumption
  sum_one := by
    simp_rw [Fin.sum_univ_succ]
    norm_num
    linarith

/-- `pA = (1/2, 1/3, 1/6, 0)`。 -/
noncomputable def pA : PMF 4 :=
  mkPMF4 (1/2) (1/3) (1/6) 0 (by norm_num) (by norm_num) (by norm_num) (by norm_num) (by norm_num)

/-- 与 `pA` 相差 `TV = 1/3` 的分布。 -/
noncomputable def pB : PMF 4 :=
  mkPMF4 (1/6) (1/3) (1/2) 0 (by norm_num) (by norm_num) (by norm_num) (by norm_num) (by norm_num)

/-- 与 `pA` 相差 `TV = 1/6` 的分布。 -/
noncomputable def pC : PMF 4 :=
  mkPMF4 (1/3) (1/3) (1/3) 0 (by norm_num) (by norm_num) (by norm_num) (by norm_num) (by norm_num)

/-- 与 `pA` 完全不相交的分布（`TV = 1`）。 -/
noncomputable def pD : PMF 4 :=
  mkPMF4 0 0 0 1 (by norm_num) (by norm_num) (by norm_num) (by norm_num) (by norm_num)

/-- 一个任意（非最优）的检验。 -/
noncomputable def t0 : Test 4 := fun i => decide (i.val = 0)

/-- 合法污染率 `π = 1/2`。 -/
noncomputable def hPi : MixWeight (1 / 2 : ℝ) := ⟨by norm_num, by norm_num⟩

/-- 合法污染率 `π = 1`（累积方案）。 -/
noncomputable def hOne : MixWeight 1 := ⟨by norm_num, by norm_num⟩

/-! ## 例 1：`TV = 0` 的不可识别情形 -/

example : totalVariation pA pA = 0 := totalVariation_self pA

example : accuracy t0 pA pA = 1 / 2 := unidentifiable pA pA (totalVariation_self pA) t0

/-- `TV = 0` 时连贝叶斯检验也只能得到 `1/2`。 -/
example : accuracy (bayes pA pA) pA pA = 1 / 2 :=
  unidentifiable pA pA (totalVariation_self pA) (bayes pA pA)

/-! ## 例 2：`TV = 1/3` 的中等可分情形 -/

example : totalVariation pA pB = 1 / 3 := by
  unfold totalVariation pA pB mkPMF4
  simp_rw [Fin.sum_univ_succ]
  norm_num [absHalf, absThird, absSixth, absQuarter, absEighth, absTwelfth]

/-- 贝叶斯正确率 = `(1 + TV)/2 = 2/3`（原始分析公式的实例）。 -/
example : accuracy (bayes pA pB) pA pB = 2 / 3 := by
  rw [bayes_optimal]
  unfold totalVariation pA pB mkPMF4
  simp_rw [Fin.sum_univ_succ]
  norm_num [absHalf, absThird, absSixth, absQuarter, absEighth, absTwelfth]

/-- 贝叶斯错误率 = `(1 − TV)/2 = 1/3`（原始分析 `P_e = ½(1−TV)` 的实例）。 -/
example : errRate (bayes pA pB) pA pB = 1 / 3 := by
  rw [bayes_errRate]
  unfold totalVariation pA pB mkPMF4
  simp_rw [Fin.sum_univ_succ]
  norm_num [absHalf, absThird, absSixth, absQuarter, absEighth, absTwelfth]

/-- 优势幅度恰为 `TV/2 = 1/6`（`accuracy_bounds` 的实例）。 -/
example : accuracy (bayes pA pB) pA pB - 1 / 2 = totalVariation pA pB / 2 := by
  rw [bayes_optimal]
  unfold totalVariation pA pB mkPMF4
  simp_rw [Fin.sum_univ_succ]
  norm_num [absHalf, absThird, absSixth, absQuarter, absEighth, absTwelfth]

/-! ## 例 3：`TV = 1/6` 的弱可分情形

与例 2 对比：同样的检验下，优势从 `1/6` 降到 `1/12`。
这直接印证对原始分析的修正 #1——**可识别性由 TV 连续控制，而非二元开关**。 -/

example : totalVariation pA pC = 1 / 6 := by
  unfold totalVariation pA pC mkPMF4
  simp_rw [Fin.sum_univ_succ]
  norm_num [absHalf, absThird, absSixth, absQuarter, absEighth, absTwelfth]

example : accuracy (bayes pA pC) pA pC = 7 / 12 := by
  rw [bayes_optimal]
  unfold totalVariation pA pC mkPMF4
  simp_rw [Fin.sum_univ_succ]
  norm_num [absHalf, absThird, absSixth, absQuarter, absEighth, absTwelfth]

/-! ## 例 4：`TV = 1` 的完全可分情形 -/

example : totalVariation pA pD = 1 := by
  unfold totalVariation pA pD mkPMF4
  simp_rw [Fin.sum_univ_succ]
  norm_num [absHalf, absThird, absSixth, absQuarter, absEighth, absTwelfth]

/-- 完全可分时存在**零错误**的检验：可识别性的极端情形。 -/
example : errRate (bayes pA pD) pA pD = 0 := by
  rw [bayes_errRate]
  unfold totalVariation pA pD mkPMF4
  simp_rw [Fin.sum_univ_succ]
  norm_num [absHalf, absThird, absSixth, absQuarter, absEighth, absTwelfth]

/-! ## 例 5：污染的代价（`Contamination` 的数值对拍） -/

/-- 污染率 `π = 1/2` 时，信号恰为原来的一半：`½ · (1/3) = 1/6`。 -/
example : totalVariation (mix pA pA (1 / 2) hPi) (mix pA pB (1 / 2) hPi) = 1 / 6 := by
  rw [totalVariation_mix pA pA pB hPi]
  unfold totalVariation pA pB mkPMF4
  simp_rw [Fin.sum_univ_succ]
  norm_num [absHalf, absThird, absSixth, absQuarter, absEighth, absTwelfth]

/-- 污染后最优优势恰为 `π · TV₀/2 = 1/12`。 -/
example : accuracy (bayes (mix pA pA (1 / 2) hPi) (mix pA pB (1 / 2) hPi))
      (mix pA pA (1 / 2) hPi) (mix pA pB (1 / 2) hPi) - 1 / 2 = 1 / 12 := by
  rw [bayes_optimal, totalVariation_mix pA pA pB hPi]
  unfold totalVariation pA pB mkPMF4
  simp_rw [Fin.sum_univ_succ]
  norm_num [absHalf, absThird, absSixth, absQuarter, absEighth, absTwelfth]

/-- 三轮自消费重混合后，信号衰减为 `π³ = 1/8` 倍：`1/8 · (1/3) = 1/24`。

这是原始分析"递归污染 / 模型自噬"的**精确指数律**的数值实例。 -/
example : totalVariation (contamIter pA (1 / 2) hPi 3 pA) (contamIter pA (1 / 2) hPi 3 pB)
    = 1 / 24 := by
  rw [totalVariation_contamIter pA hPi 3 pA pB]
  unfold totalVariation pA pB mkPMF4
  simp_rw [Fin.sum_univ_succ]
  norm_num [absHalf, absThird, absSixth, absQuarter, absEighth, absTwelfth]

/-- 累积方案（人类源每轮以满权重 `π = 1` 重新插入）时信号**完全不衰减**。

这解释了 Gersthaler et al. (2024) 结论的机制：
累积之所以避免坍缩，是因为衰减因子为 `π = 1`。 -/
example : totalVariation (contamIter pA 1 hOne 5 pA) (contamIter pA 1 hOne 5 pB)
    = totalVariation pA pB := by
  rw [totalVariation_contamIter pA hOne 5 pA pB]
  simp

end Provenance
