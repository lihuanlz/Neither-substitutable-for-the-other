/-
# 碎片化：为什么人机协同下创新难以规模化

这是独立于主线的一个课题，主张是：

> **AI 不会让人的创新规模化，只会让它碎片化。**

机制有两截，本文各给一组定理：

1. **协作侧（内生）**：在同一层上，协作体达成的层移动等于其中最好那个人的层移动。
   多来一个人，最终压到的层一个数字都不变 —— `marginal_agent_pure_waste`。
   人数不是变量。
2. **时间侧（外生）**：把增量攒着不发，等的是一个会被盖掉的窗口。
   覆盖是吸收的，等待收益**单调不增** —— `holdValue_antitone`；
   一旦被盖掉，持有收益精确为 0 —— `publish_dominates_when_covered`。

两截合起来，`fragmentation_squeeze` 说明通往"大故事"的两条常规路径同时被堵死。
**唯一的出口是换一个新的层**，而那正是 `Refinement.human_gain_unbounded`
已经证过的无上界空间。

## 与主线的接口

本文件全程使用 `Provenance.Refinement` 的同一套货币：层是 \(\Phi > 0\)，
人类切层的收益是对数增益 \(\log(\Phi_{\text{old}}/\Phi_{\text{new}})\)。
`saturation_duality` 把两侧的饱和性并置：

* AI 侧：`Refinement.ai_total_gain_bounded` —— 上界 `log(e₀/Φ)`，**与步数无关**
* 人侧：本文 `marginal_agent_pure_waste` —— 上界由最好成员决定，**与人数无关**

两边同时饱和。这就是"不可替代性"在规模化问题上的投影：
**不是谁替代谁，而是谁都加不上去。**

## 本文的建模选择，以及它为什么可以被证伪

一个协作体被建模为"成员各自能独立达到的层的集合"，成果取其中最好者（`max` 型）。
这是比"合并打折"更强、也更容易被现实推翻的断言：本文说的是
**合并精确等于最优个体，其余成员贡献为零**。

如果现实中的协作确实存在互补性 —— 两人一起做能超过其中最好的一人 ——
那么 `add_member_same_reach` 立刻失效。所以本文给出的是**可证伪的立场**，
而不是把次模性换个说辞。

-/

import Mathlib.Tactic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Provenance.Refinement

namespace Provenance
namespace Fragmentation

noncomputable section
open Classical

/-
## 1. 协作体

一个协作体建模为**它的成员各自能独立达到的层的集合**。

这不是偷懒。`Provenance.Basic` 已经证明内容层在最优检验下不可识别，
两个成员"达到同一层"在观测上无法区分 —— 所以能观测的只有可达层的集合，
不是"谁做了什么"的对应关系。
-/

/-- 协作体 = 成员各自能独立达到的层的集合。 -/
abbrev Coalition := Finset ℝ

/-- 协作体最终压到的层：成员中最好的那个。 -/
def reach (D : Coalition) (hD : D.Nonempty) : ℝ := D.min' hD

/-- 协作体把起层 `Φ` 压低的幅度，用与 `Refinement` 相同的对数货币度量。 -/
def gain (Φ : ℝ) (D : Coalition) (hD : D.Nonempty) : ℝ :=
  Real.log (Φ / reach D hD)

/-- 各成员单独达到的层移动之和。 -/
def totalIndividual (Φ : ℝ) (D : Coalition) : ℝ :=
  D.sum fun a => Real.log (Φ / a)

/-- 协作的合法状态：每个成员达到的层都在 `(0, Φ]` 内。 -/
def Admissible (Φ : ℝ) (D : Coalition) : Prop := ∀ a ∈ D, 0 < a ∧ a ≤ Φ

theorem reach_mem (D : Coalition) (hD : D.Nonempty) : reach D hD ∈ D := by
  unfold reach; exact Finset.min'_mem D hD

theorem reach_le_of_mem {D : Coalition} {hD : D.Nonempty} {a : ℝ} (ha : a ∈ D) :
    reach D hD ≤ a := by
  unfold reach; exact Finset.min'_le D a ha

theorem reach_pos {D : Coalition} {hD : D.Nonempty} (h : ∀ a ∈ D, 0 < a) :
    0 < reach D hD := h _ (reach_mem D hD)

/-
## 2. 主定理：加人不加收益
-/

/-- **加一个成员，最终压到的层一个数字都不变**。

只要新成员不优于现有最好者，协作体的成果就是原来的成果。

这条同时是本课题最强的**可证伪点**：若现实中两人协作能超过其中较好的一人，
这里立刻失败。 -/
theorem add_member_same_reach {D : Coalition} {hD : D.Nonempty} {a : ℝ}
    (ha : reach D hD ≤ a) :
    reach (insert a D) ⟨a, Finset.mem_insert_self a D⟩ = reach D hD := by
  unfold reach
  rw [Finset.min'_insert a D hD]
  exact min_eq_left ha

/-- **协作体的层移动 = 其中最好成员的层移动**。

其余所有成员对最终层的贡献精确为 0。 -/
theorem gain_eq_best_member {Φ : ℝ} {D : Coalition} {hD : D.Nonempty} {a : ℝ}
    (hΦ : 0 < Φ) (hpos : ∀ b ∈ D, 0 < b) (hmem : a ∈ D)
    (hbest : reach D hD = a) : gain Φ D hD = Real.log (Φ / a) := by
  have ha : 0 < a := hpos a hmem
  unfold gain
  rw [hbest, Real.log_div (ne_of_gt hΦ) (ne_of_gt ha)]

/-- **成员的个体收益不超过协作体收益**。 -/
theorem member_gain_le_gain {Φ : ℝ} {D : Coalition} {hD : D.Nonempty} {a : ℝ}
    (hΦ : 0 < Φ) (hpos : ∀ b ∈ D, 0 < b) (hmem : a ∈ D) :
    Real.log (Φ / a) ≤ gain Φ D hD := by
  have hr : 0 < reach D hD := reach_pos hpos
  have ha : 0 < a := hpos a hmem
  have hle : reach D hD ≤ a := reach_le_of_mem hmem
  have h1 : Real.log (reach D hD) ≤ Real.log a := (Real.log_le_log_iff hr ha).mpr hle
  unfold gain
  rw [Real.log_div (ne_of_gt hΦ) (ne_of_gt hr),
      Real.log_div (ne_of_gt hΦ) (ne_of_gt ha)]
  linarith

/-- **第 N+1 个人：收益精确为 0，成本精确为 `log(Φ/a)`**。

碎片化命题的全部内容就在这一行：左边不随人数变化，右边严格增加。 -/
theorem marginal_agent_pure_waste {Φ : ℝ} {D : Coalition} {hD : D.Nonempty} {a : ℝ}
    (hnew : a ∉ D) (hreach : reach D hD ≤ a) :
    gain Φ (insert a D) ⟨a, Finset.mem_insert_self a D⟩ = gain Φ D hD
      ∧ totalIndividual Φ (insert a D) = totalIndividual Φ D + Real.log (Φ / a) := by
  have hreach' : reach (insert a D) ⟨a, Finset.mem_insert_self a D⟩ = reach D hD :=
    add_member_same_reach hreach
  constructor
  · unfold gain
    rw [hreach']
  · have hsum : totalIndividual Φ (insert a D)
        = Real.log (Φ / a) + totalIndividual Φ D := by
      simp only [totalIndividual, Finset.sum_insert hnew]
    rw [hsum, add_comm]

/-
## 3. 浪费

`totalIndividual` 与 `gain` 的差额就是协作中被丢掉的部分。
-/

/-- 协作浪费 = 各成员层移动之和减去实际达成的层移动。 -/
def waste (Φ : ℝ) (D : Coalition) (hD : D.Nonempty) : ℝ :=
  totalIndividual Φ D - gain Φ D hD

theorem term_nonneg {Φ a : ℝ} (hΦ : 0 < Φ) (ha : 0 < a) (hle : a ≤ Φ) :
    0 ≤ Real.log (Φ / a) := by
  have h1 : Real.log a ≤ Real.log Φ := (Real.log_le_log_iff ha hΦ).mpr hle
  rw [Real.log_div (ne_of_gt hΦ) (ne_of_gt ha)]
  linarith

/-- 任何单个成员的收益都不超过总和（其余项非负）。 -/
theorem member_le_total {Φ : ℝ} {D : Coalition} {a : ℝ}
    (hΦ : 0 < Φ) (adm : Admissible Φ D) (hmem : a ∈ D) :
    Real.log (Φ / a) ≤ totalIndividual Φ D := by
  have hsplit : (D.erase a).sum (fun b : ℝ => Real.log (Φ / b)) + Real.log (Φ / a)
      = totalIndividual Φ D := Finset.sum_erase_add D _ hmem
  have hrest : 0 ≤ (D.erase a).sum fun b : ℝ => Real.log (Φ / b) := by
    refine Finset.sum_nonneg fun b hb => term_nonneg hΦ ?_ ?_
    · exact adm b (Finset.mem_of_mem_erase hb) |>.1
    · exact adm b (Finset.mem_of_mem_erase hb) |>.2
  linarith

/-- 协作体成果不超过成员收益之和：合并永不增产。 -/
theorem gain_le_total {Φ : ℝ} {D : Coalition} {hD : D.Nonempty}
    (hΦ : 0 < Φ) (adm : Admissible Φ D) :
    gain Φ D hD ≤ totalIndividual Φ D := by
  unfold gain
  exact member_le_total hΦ adm (reach_mem D hD)

/-- **浪费非负**：协作从不产生超过最优个体的额外层移动。 -/
theorem waste_nonneg {Φ : ℝ} {D : Coalition} {hD : D.Nonempty}
    (hΦ : 0 < Φ) (adm : Admissible Φ D) : 0 ≤ waste Φ D hD := by
  unfold waste
  linarith [gain_le_total (hD := hD) hΦ adm]

/-- **人数增加只增大浪费，不改变成果**。 -/
theorem headcount_adds_waste_only {Φ : ℝ} {D : Coalition} {hD : D.Nonempty} {a : ℝ}
    (hΦ : 0 < Φ) (adm : Admissible Φ D) (ha : 0 < a) (hle : a ≤ Φ) (hnew : a ∉ D)
    (hreach : reach D hD ≤ a) :
    gain Φ (insert a D) ⟨a, Finset.mem_insert_self a D⟩ = gain Φ D hD
      ∧ 0 ≤ waste Φ (insert a D) ⟨a, Finset.mem_insert_self a D⟩ := by
  refine ⟨(marginal_agent_pure_waste hnew hreach).1, ?_⟩
  refine waste_nonneg hΦ fun b hb => ?_
  rw [Finset.mem_insert] at hb
  rcases hb with rfl | hb
  · exact ⟨ha, hle⟩
  · exact adm b hb

/-
## 4. 与 AI 上界的对偶
-/

/-- **两侧同时饱和**。

* AI 侧：`Refinement.ai_total_gain_bounded`，上界 `log(e₀/Φ)`，**与步数无关**；
* 人侧：`marginal_agent_pure_waste`，上界由最好成员决定，**与人数无关**。

这是"不可替代性"在规模化问题上的投影：不是谁替代谁，而是谁都加不上去。 -/
theorem saturation_duality {M : ℝ} (hM : 0 ≤ M)
    {e0 Φ eN : ℝ} (he0 : 0 < e0) (hΦ : 0 < Φ) (heN : 0 < eN) (hΦle : Φ ≤ eN) :
    (Real.log (e0 / eN) ≤ Real.log (e0 / Φ))
      ∧ (∃ Φα Φβ : ℝ, 0 < Φβ ∧ Φβ ≤ Φα ∧ Real.log (Φα / Φβ) = M) :=
  ⟨ai_total_gain_bounded he0 hΦ heN hΦle, human_gain_unbounded hM⟩

/-
## 5. 时间侧：独占窗口
-/

/-- 攒着不发所能拿到的收益：到期若已被盖掉，精确为 0。 -/
def holdValue (vBig d : ℝ) (covered : ℝ → Prop) : ℝ :=
  if covered d then 0 else vBig

theorem holdValue_eq_zero_of_covered (vBig d : ℝ) {covered : ℝ → Prop} (h : covered d) :
    holdValue vBig d covered = 0 := by
  simp [holdValue, h]

theorem holdValue_eq_of_not_covered (vBig d : ℝ) {covered : ℝ → Prop} (h : ¬covered d) :
    holdValue vBig d covered = vBig := by
  simp [holdValue, h]

/-- **到期被盖住，则立刻发严格更优**。

这是碎片化的时间机制：大故事的收益是条件收益，条件一旦不成立就归零；
而小的立刻拿到手就是确定的。 -/
theorem publish_dominates_when_covered (vBig vSmall d : ℝ) {covered : ℝ → Prop}
    (h : covered d) (hsmall : 0 < vSmall) : vSmall > holdValue vBig d covered := by
  rw [holdValue_eq_zero_of_covered vBig d h]
  linarith

/-- **等待的收益单调不增**。

覆盖是吸收的 —— 一旦被盖掉就永远被盖掉。所以把增量压在手里不是一个期权：
越等越不划算，只有"没被盖住"和"已被盖掉"两种结局，不存在第三种。 -/
theorem holdValue_antitone (vBig : ℝ) (hbig : 0 ≤ vBig) {covered : ℝ → Prop}
    (hmono : ∀ d d', d ≤ d' → covered d → covered d') :
    ∀ d d', d ≤ d' → holdValue vBig d' covered ≤ holdValue vBig d covered := by
  intro d d' hle
  by_cases h2 : covered d'
  · rw [holdValue_eq_zero_of_covered vBig d' h2]
    by_cases h1 : covered d
    · rw [holdValue_eq_zero_of_covered vBig d h1]
    · rw [holdValue_eq_of_not_covered vBig d h1]
      exact hbig
  · rw [holdValue_eq_of_not_covered vBig d' h2]
    by_cases h1 : covered d
    · exact absurd (hmono d d' hle h1) h2
    · rw [holdValue_eq_of_not_covered vBig d h1]

/-
## 6. 双夹击

堆人零收益，攒着会被抢。于是通往大故事的两条常规路径同时关闭。
-/

/-- **碎片化均衡**。

两条路同时被堵死：
* 协作侧 —— 加人不改变最终层；
* 时间侧 —— 等待到期若被盖掉，收益归零。 -/
theorem fragmentation_squeeze {Φ : ℝ} {D : Coalition} {hD : D.Nonempty} {a : ℝ}
    (hnew : a ∉ D) (hreach : reach D hD ≤ a)
    {vBig d : ℝ} {covered : ℝ → Prop} (hcov : covered d) :
    gain Φ (insert a D) ⟨a, Finset.mem_insert_self a D⟩ = gain Φ D hD
      ∧ holdValue vBig d covered = 0 :=
  ⟨(marginal_agent_pure_waste hnew hreach).1,
    holdValue_eq_zero_of_covered vBig d hcov⟩

/-- **规模化只能靠换层，不能靠堆人**。

这是本课题的落点，也解释了为什么人的空间仍然无上界：
无上界不是因为人更多，而是因为**层可以换**。 -/
theorem scale_by_new_layers_not_by_headcount {M : ℝ} (hM : 0 ≤ M) :
    ∃ Φα Φβ : ℝ, 0 < Φβ ∧ Φβ ≤ Φα ∧ Real.log (Φα / Φβ) = M :=
  human_gain_unbounded hM

end
end Fragmentation
end Provenance
