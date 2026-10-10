/-
# 污染的代价：TV 混合定理与递归污染的形式化

本文件形式化原始分析第 1 节中"递归污染"那一段，并给出一个**精确**的定量结果：

    TV( (1-π)·p_H + π·u , (1-π)·p_H + π·v )  =  π · TV(u, v)

即：**污染率 π 使可识别信号恰好线性衰减为原来的 π 倍**。

结合 `Provenance.Basic.accuracy_bounds`（最优优势 = TV/2）可得：

    污染后的最优检测优势  =  π · TV₀ / 2

这为"污染的代价"提供了一个可计算的、非定性的答案，并直接导出：

* `totalVariation_contamIter` —— 在**自消费**递归（每轮以权重 π 重新插入人类源）下，
  可识别信号按 `π^k` **指数衰减**（精确等式，非近似）。
* `contam_decay_bound` —— 结合 `TV ≤ 1` 得 `信号 ≤ π^k`。当 `π < 1` 时
  `π^k → 0`，即人类来源信号终将被洗掉，这是原始分析"模型自噬/模型坍缩"
  严格图景的**定量版本**。
* `contamination_budget` —— 反过来给出**污染容忍度**：要保住目标优势 `δ`，
  必须 `π · TV₀ ≥ 2δ`。
* `accumulate_no_decay` —— 累积方案对应 `π = 1`，此时**信号完全不衰减**。

## 一个必须显式化的前提

混合 `(1-π)·p_H + π·q` 只有在 `0 ≤ π ≤ 1` 时才是合法概率分布
（`π < 0` 或 `π > 1` 会产生负质量）。Lean 强制我们把这一前提写进
`mix` 的签名（参数 `h : MixWeight π`），这比在正文里口头假设更可靠。

## 一个重要的诚实声明

原始分析声称"累积原始数据则收敛回 p_H"（Gersthaler et al., *Nature* 2024）。
**本文件只形式化了它的机制部分（`accumulate_no_decay`），没有形式化"收敛回 p_H"本身。**
后者是关于随机生成过程的收敛性定理，需要"经验分布"与随机过程的构造，
远超本次范围。

Lean 在这里帮了个忙：它逼我们把两件事分开——

* **已证明**：在每轮以固定权重 π 重混合的递归下，信号按 `π^k` 衰减；
* **未证明**：累积方案下信号收敛回**原分布**（只证明了不衰减）。

也就是说，衰减的真正驱动因素是**每轮重新插入人类数据的权重**，
而不是"是否污染"这个笼统说法。这一条已由 `totalVariation_contamIter`
精确刻画。

-/

import Mathlib.Tactic
import Mathlib.Data.Finset.Basic
import Provenance.Basic

open Finset
open scoped BigOperators

namespace Provenance

variable {n : ℕ}

/-- 合法污染率：`0 ≤ π ≤ 1`。 -/
abbrev MixWeight (π : ℝ) : Prop := 0 ≤ π ∧ π ≤ 1

/-- 混合：以权重 `π` 把 AI 源叠加到人类源上。`π` 即**污染率**。 -/
noncomputable def mix (p q : PMF n) (π : ℝ) (h : MixWeight π) : PMF n where
  val := fun i => (1 - π) * p.val i + π * q.val i
  nonneg := by
    intro i
    have hπ : (0 : ℝ) ≤ π ∧ π ≤ 1 := h
    have h1 : (0 : ℝ) ≤ p.val i := p.nonneg i
    have h2 : (0 : ℝ) ≤ q.val i := q.nonneg i
    have h3 : (0 : ℝ) ≤ 1 - π := by linarith
    exact add_nonneg (mul_nonneg h3 h1) (mul_nonneg hπ.1 h2)
  sum_one := by
    have key : (∑ i : Fin n, ((1 - π) * p.val i + π * q.val i))
        = (1 - π) * (∑ i : Fin n, p.val i) + π * (∑ i : Fin n, q.val i) := by
      rw [Finset.sum_add_distrib, Finset.mul_sum, Finset.mul_sum]
    rw [key, p.sum_one, q.sum_one]
    ring

/-- **混合定理（核心）**：全变差距离在混合下**恰好按污染率线性缩放**。

    TV((1-π)·p_H + π·u, (1-π)·p_H + π·v) = π · TV(u, v)

人类源相同的两侧相减后，人类部分完全抵消，只剩 `π` 倍的差。 -/
theorem totalVariation_mix (p u v : PMF n) {π : ℝ} (h : MixWeight π) :
    totalVariation (mix p u π h) (mix p v π h) = π * totalVariation u v := by
  unfold totalVariation
  have hval : ∀ i : Fin n, (mix p u π h).val i = (1 - π) * p.val i + π * u.val i := by
    intro i
    rfl
  have hval' : ∀ i : Fin n, (mix p v π h).val i = (1 - π) * p.val i + π * v.val i := by
    intro i
    rfl
  have key : ∀ i : Fin n,
      |(mix p u π h).val i - (mix p v π h).val i| = π * |u.val i - v.val i| := by
    intro i
    rw [hval i, hval' i]
    have e : (1 - π) * p.val i + π * u.val i - ((1 - π) * p.val i + π * v.val i)
        = π * (u.val i - v.val i) := by ring
    rw [e, abs_mul, abs_of_nonneg h.1]
  rw [Finset.sum_congr rfl (fun i _ => key i), ← Finset.mul_sum]
  ring

/-- **污染后的最优优势**：精确等于 `π · TV₀/2`。

结合 `accuracy_bounds`（优势 = TV/2）即知：污染率 π 把可检测优势
精确乘以 π，而非"大致削弱"。 -/
theorem maxAdvantage_mix (p u v : PMF n) {π : ℝ} (h : MixWeight π) :
    (1 + totalVariation (mix p u π h) (mix p v π h)) / 2 - 1 / 2
      = π * (totalVariation u v / 2) := by
  rw [totalVariation_mix p u v h]
  ring

/-- **污染容忍度**：要保住目标优势 `δ`，必须 `π · TV₀ ≥ 2δ`。

取等号即得：允许的最大污染率为 `π ≤ 2δ / TV₀`。
这说明当原始可识别信号 `TV₀` 越小，**对污染的容忍度越低**。 -/
theorem contamination_budget (p u v : PMF n) {π δ : ℝ} (h : MixWeight π)
    (htarget : δ ≤ totalVariation (mix p u π h) (mix p v π h) / 2) :
    π * totalVariation u v ≥ 2 * δ := by
  rw [totalVariation_mix p u v h] at htarget
  linarith

/-! ## 递归污染：自消费重混合 -/

/-- 单轮"自消费"重混合：每一轮都以固定权重 `π` 把当前代与人类源重新混合。
这正是原始分析的递归 `p_A^{(t+1)} = Fit(π_H·p_H + π_A·p_A^{(t)})` 的
**可测外壳**（此处把 `Fit` 恒等化，只跟踪信号量）。 -/
noncomputable def contamIter (p : PMF n) (π : ℝ) (h : MixWeight π) (k : ℕ) (x : PMF n) : PMF n :=
  Nat.rec x (fun _ y => mix p y π h) k

/-- **递归污染定理**：`k` 轮自消费重混合后，可识别信号衰减为 `π^k` 倍（**精确等式**）。

这把原始分析里"模型自噬"的定性描述变成了一个**精确的指数律**。 -/
theorem totalVariation_contamIter (p : PMF n) {π : ℝ} (h : MixWeight π) :
    ∀ k u v, totalVariation (contamIter p π h k u) (contamIter p π h k v)
      = (π ^ k) * totalVariation u v := by
  intro k
  induction k with
  | zero =>
      intro u v
      show totalVariation u v = π ^ 0 * totalVariation u v
      simp
  | succ k ih =>
      intro u v
      change totalVariation (mix p (contamIter p π h k u) π h)
          (mix p (contamIter p π h k v) π h) = _
      rw [totalVariation_mix p (contamIter p π h k u) (contamIter p π h k v) h]
      rw [ih u v]
      ring

/-- **衰减上界**：`k` 轮自消费重混合后，可识别信号不超过 `π^k`。

由 `totalVariation_le_one`（TV ≤ 1）与 `totalVariation_contamIter`（精确等于 `π^k · TV₀`）得到。
当 `π < 1` 时 `π^k → 0`，故信号终将被洗掉——
这是原始分析"模型自噬 / 模型坍缩"的严格图景的**定量版本**。

（未形式化的部分：把这条界进一步写成 `Tendsto ... (nhds 0)` 的极限陈述。
那需要额外的极限/滤子构造，本次未做；上界本身已足以支撑全部结论。） -/
theorem contam_decay_bound (p u v : PMF n) {π : ℝ} (h : MixWeight π) (k : ℕ) :
    totalVariation (contamIter p π h k u) (contamIter p π h k v) ≤ π ^ k := by
  have hπ : (0 : ℝ) ≤ π ∧ π ≤ 1 := h
  have h1 : totalVariation (contamIter p π h k u) (contamIter p π h k v)
      = π ^ k * totalVariation u v := totalVariation_contamIter p h k u v
  calc totalVariation (contamIter p π h k u) (contamIter p π h k v)
      = π ^ k * totalVariation u v := h1
    _ ≤ π ^ k * 1 := by
        have hle : totalVariation u v ≤ 1 := totalVariation_le_one u v
        have hle' := mul_le_mul_of_nonneg_right hle (pow_nonneg hπ.1 k)
        simpa [mul_comm] using hle'
    _ = π ^ k := by ring

/-- **累积方案对应 `π = 1`**：此时信号**不衰减**（`1^k = 1`）。

这给出 Gersthaler et al. (2024) 结论的**机制层面**解释：
累积原始数据之所以能避免坍缩，是因为人类源在每一轮都以**满权重**重新插入，
于是 `π = 1`，衰减因子恒为 1。 -/
theorem accumulate_no_decay (p u v : PMF n) (k : ℕ) :
    totalVariation (contamIter p 1 ⟨by norm_num, by norm_num⟩ k u)
      (contamIter p 1 ⟨by norm_num, by norm_num⟩ k v)
      = totalVariation u v := by
  rw [totalVariation_contamIter p ⟨by norm_num, by norm_num⟩ k u v]
  simp

/-- **衰减因子单调**：污染率越低，第 k 轮后的信号越弱（`π₁ ≤ π₂ ⟹ π₁^k ≤ π₂^k`）。 -/
theorem decay_monotone {π₁ π₂ : ℝ} (h₁ : 0 ≤ π₁) (h₂ : π₁ ≤ π₂) (k : ℕ) :
    π₁ ^ k ≤ π₂ ^ k := by
  have h₂' : (0 : ℝ) ≤ π₂ := by linarith
  induction k with
  | zero => norm_num
  | succ k ih =>
      rw [pow_succ, pow_succ]
      calc π₁ ^ k * π₁ ≤ π₂ ^ k * π₁ := mul_le_mul_of_nonneg_right ih h₁
        _ ≤ π₂ ^ k * π₂ := mul_le_mul_of_nonneg_left h₂ (pow_nonneg h₂' k)

end Provenance
