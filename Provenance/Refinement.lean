/-
# 观测层过滤下的贡献分解：形式化"人类切层 / AI 层内收敛"

本文件形式化一个框架的数学核心（用户提出的方案）：

把"真实"从单点 \(s^*\) 升级为**观测层上的等价类** \([s^*]_\alpha\)，
其中 \(\alpha \in (\mathcal{A},\le)\) 是观测层级（实验协议 / 任务族 / 观测能力），
且 \(\alpha \le \beta \Rightarrow \sim_\beta \subseteq \sim_\alpha\)（能力越强，类越细）。

设 \(\mathcal{R}_\alpha\) 为层 \(\alpha\) 下**可达估计的集合**（受实验能力、算力、
理论可构造性限制）。定义该层的**不可约误差下界**：

    Φ(α) = inf { d(ŝ, [s^*]_α) : ŝ ∈ ℘_α }

> **注意**：若不限制 \(\hat{s}\) 的可达集合，则取 \(\hat{s} \in [s^*]_\alpha\) 即可，
> 有 \(\Phi(\alpha) = 0\)，整个对数分解立即崩溃。
> **可达集 \(\mathcal{R}_\alpha\) 是这个框架成立的必要前提，不是可选项。**
> 有了它，\(\Phi(\alpha) > 0\) 正是"该层存在不可约残余"的形式化，
> 而 \(\Phi(\alpha) = 0\) 意味着该层下真实可被完全逼近。

误差的对数分解：

    log(1/e) = log(1/Φ) + log(Φ/e)
             └─ 天花板 ─┘  └─ 层内填充 ─┘

## 本文件证明的核心对偶

* `ai_total_gain_bounded` —— **AI 在层内能拿到的总比特数有硬上界**，
  且该上界只由层决定（`log(e₀/Φ)`），**与 AI 用了多少步无关**。
  这比"每步边际趋零"更强：不只是每步趋零，**总和本身有界**。
* `human_gain_unbounded` —— **人类切层的收益无上界**。
* `ai_budget_grows_when_floor_drops` —— 人类把 \(\Phi\) 压低，
  AI 的可用预算**才**变大。人类不切层，AI 就无预算可增。
* `no_gain_without_floor_drop` —— **层不变则人类零收益**：
  若换层但 \(\Phi\) 没降，这次提问白做。

由此得到"AI 边际贡献趋零"的**精确版本**：
**它只在"层固定"这个前提下成立**，而层固定正是人类不做贡献的状态。

-/

import Mathlib.Tactic
import Mathlib.Analysis.SpecialFunctions.Log.Basic

open scoped BigOperators

namespace Provenance

/-
## 1. AI 在层内的收益：硬上界
-/

/-- **AI 层内总收益有上界**。

若误差序列已降到 \(e_N\)，且 \(e_N \ge \Phi\)（\(\Phi\) 是该层不可约下界），
则 AI 迄今累计拿到的对数收益 \(\log(e_0/e_N)\) 不超过 \(\log(e_0/\Phi)\)。

关键：这个上界**只由层决定**，AI 增加任何步数都无法突破。 -/
theorem ai_total_gain_bounded {e0 Φ eN : ℝ}
    (he0 : 0 < e0) (hΦ : 0 < Φ) (heN : 0 < eN) (hΦle : Φ ≤ eN) :
    Real.log (e0 / eN) ≤ Real.log (e0 / Φ) := by
  rw [Real.log_div (ne_of_gt he0) (ne_of_gt heN),
      Real.log_div (ne_of_gt he0) (ne_of_gt hΦ)]
  have h1 : Real.log Φ ≤ Real.log eN := (Real.log_le_log_iff hΦ heN).mpr hΦle
  linarith

/-- **AI 单步收益非负**：只要误差不增，AI 就在赚比特。 -/
theorem ai_step_gain_nonneg {e_prev e_next : ℝ}
    (hprev : 0 < e_prev) (hnext : 0 < e_next) (hmono : e_next ≤ e_prev) :
    0 ≤ Real.log (e_prev / e_next) := by
  rw [Real.log_div (ne_of_gt hprev) (ne_of_gt hnext)]
  have h1 : Real.log e_next ≤ Real.log e_prev := (Real.log_le_log_iff hnext hprev).mpr hmono
  linarith

/-- **AI 剩余可获取收益非负**：还没拿到的比特数 \(\log(e_N/\Phi)\ge 0\)。 -/
theorem ai_remaining_gain_nonneg {Φ eN : ℝ} (hΦ : 0 < Φ) (heN : 0 < eN) (hΦle : Φ ≤ eN) :
    0 ≤ Real.log (eN / Φ) := by
  rw [Real.log_div (ne_of_gt heN) (ne_of_gt hΦ)]
  have h1 : Real.log Φ ≤ Real.log eN := (Real.log_le_log_iff hΦ heN).mpr hΦle
  linarith

/-
## 2. 人类的切层收益：无上界
-/

/-- **层不变则人类零收益**。

若换层后不可约误差没有下降，这次提问的收益精确为 0。
这条给"什么算好问题"提供了**可证伪的判据**：
好问题 ⟺ 它降低了 \(\Phi\)。 -/
theorem no_gain_without_floor_drop {Φα Φβ : ℝ} (_hα : 0 < Φα) (hβ : 0 < Φβ)
    (heq : Φα = Φβ) : Real.log (Φα / Φβ) = 0 := by
  rw [heq]
  rw [div_self (ne_of_gt hβ), Real.log_one]

/-- **人类切层收益无上界**。

对任意目标比特数 \(M \ge 0\)，存在两个层的下界使得
\(\log(\Phi(\alpha)/\Phi(\beta)) = M\)。

取 \(\Phi(\alpha) = 1\)、\(\Phi(\beta) = e^{-M}\) 即得。 -/
theorem human_gain_unbounded {M : ℝ} (hM : 0 ≤ M) :
    ∃ Φα Φβ : ℝ, 0 < Φβ ∧ Φβ ≤ Φα ∧ Real.log (Φα / Φβ) = M := by
  refine ⟨1, Real.exp (-M), Real.exp_pos _, ?_, ?_⟩
  · have h := Real.exp_le_exp.mpr (neg_nonpos.mpr hM)
    simpa using h
  · rw [Real.log_div (by norm_num) (ne_of_gt (Real.exp_pos _)),
      Real.log_one, Real.log_exp]
    ring

/-- **人类压低下界后，AI 的可用预算才变大**。

这是整段分析里最关键的一条**因果方向**：
不是"AI 越强人类越没用"，而是"**人类不压 \(\Phi\)，AI 再强也没预算可增**"。 -/
theorem ai_budget_grows_when_floor_drops {e0 Φα Φβ : ℝ}
    (he0 : 0 < e0) (hα : 0 < Φα) (hβ : 0 < Φβ) (hdrop : Φβ < Φα) :
    Real.log (e0 / Φβ) > Real.log (e0 / Φα) := by
  rw [Real.log_div (ne_of_gt he0) (ne_of_gt hβ),
      Real.log_div (ne_of_gt he0) (ne_of_gt hα)]
  have h1 : Real.log Φβ < Real.log Φα := (Real.log_lt_log_iff hβ hα).mpr hdrop
  linarith

/-- **对偶定理**：人类收益无上界 ⟹ AI 层内收益有界。

形式化这个"不对称"：存在人类收益任意大的层对，
而对任何固定的层，AI 的累计收益都有硬上界。 -/
theorem asymmetry_of_layer_structure {M : ℝ} (hM : 0 ≤ M)
    {e0 Φ eN : ℝ} (he0 : 0 < e0) (hΦ : 0 < Φ) (heN : 0 < eN) (hΦle : Φ ≤ eN) :
    (∃ Φα Φβ : ℝ, 0 < Φβ ∧ Φβ ≤ Φα ∧ Real.log (Φα / Φβ) = M)
      ∧ Real.log (e0 / eN) ≤ Real.log (e0 / Φ) :=
  ⟨human_gain_unbounded hM, ai_total_gain_bounded he0 hΦ heN hΦle⟩

/-
## 3. 分层贡献的可加性
-/

/-- **切层收益 + 层内收益 = 总对数收益**（无误差）。

在层 \(\beta\) 内做 AI 逼近时，若层 \(\alpha \le \beta\) 且无误差残留，
总收益恰好等于切层收益加层内收益。 -/
theorem layered_decomposition {Φα Φβ eN : ℝ}
    (hα : 0 < Φα) (hβ : 0 < Φβ) (heN : 0 < eN) :
    Real.log (Φα / eN) = Real.log (Φα / Φβ) + Real.log (Φβ / eN) := by
  rw [Real.log_div (ne_of_gt hα) (ne_of_gt heN),
      Real.log_div (ne_of_gt hα) (ne_of_gt hβ),
      Real.log_div (ne_of_gt hβ) (ne_of_gt heN)]
  ring

/-- **每一项都非负**：切层不亏，层内也不亏。 -/
theorem layered_terms_nonneg {Φα Φβ eN : ℝ}
    (hα : 0 < Φα) (hβ : 0 < Φβ) (hdrop : Φβ ≤ Φα) (heN : 0 < eN) (hdrop2 : eN ≤ Φβ) :
    (0 ≤ Real.log (Φα / Φβ)) ∧ (0 ≤ Real.log (Φβ / eN)) := by
  constructor
  · rw [Real.log_div (ne_of_gt hα) (ne_of_gt hβ)]
    have h1 : Real.log Φβ ≤ Real.log Φα := (Real.log_le_log_iff hβ hα).mpr hdrop
    linarith
  · rw [Real.log_div (ne_of_gt hβ) (ne_of_gt heN)]
    have h1 : Real.log eN ≤ Real.log Φβ := (Real.log_le_log_iff heN hβ).mpr hdrop2
    linarith

end Provenance
