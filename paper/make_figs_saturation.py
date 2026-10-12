# -*- coding: utf-8 -*-
"""
Figures for the saturation sections: coalition headcount and corpus growth.

These cover the two sections added when the paper was re-centred on the two
saturating operators. Section 5 (headcount) and section 6 (corpus) had no
figure, and both claims are about a quantity staying flat while a second
quantity grows without bound, which is exactly what a plot is for.

Style and palette match paper/make_figures.py and paper/docx_build/make_figs_en.py
(Okabe-Ito, colourblind-safe):
  BLU #0072B2, VER #D55E00, GRN #009E73, GRY #8C8C8C, LGR #C9C9C9, K #000000
"""

import os

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

OUT = os.path.normpath(os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "figures"))

K, BLU, VER, GRN = "#000000", "#0072B2", "#D55E00", "#009E73"
GRY, LGR = "#8C8C8C", "#C9C9C9"


def fig_headcount():
    """Section 5. Coalition gain is flat; summed individual cost is not."""
    fig, axes = plt.subplots(1, 3, figsize=(11.0, 3.15))

    phi = 1.0                      # starting floor
    members = np.array([0.20, 0.30, 0.35, 0.40, 0.60, 0.75, 0.90])
    reach = np.min(members)        # max-type coalition takes the best member
    n = np.arange(1, members.size + 1)
    gain = np.full_like(n, np.log(phi / reach), dtype=float)
    cost = np.cumsum(np.log(phi / members))

    ax = axes[0]
    ax.plot(n, gain, "-o", color=BLU, lw=2.0, ms=5, label="coalition gain")
    ax.plot(n, cost, "-s", color=VER, lw=2.0, ms=5, label="summed member gain")
    ax.fill_between(n, gain, cost, color=LGR, alpha=0.55,
                    label="waste = pure loss")
    ax.axhline(gain[0], color=GRY, ls="--", lw=1.0)
    ax.set_xlabel("coalition size $n$")
    ax.set_ylabel("log gain")
    ax.set_title("Gain flat, cost linear", fontsize=9)
    ax.legend(loc="upper left", frameon=False, fontsize=7)

    ax = axes[1]
    marg = np.concatenate([[gain[0]], np.diff(gain)])
    ax.plot(n, marg, "-o", color=BLU, lw=2.0, ms=5)
    ax.axhline(0, color=K, lw=0.8)
    ax.set_xlabel("coalition size $n$")
    ax.set_ylabel("marginal gain of member $n$")
    ax.set_title("Every later member earns 0", fontsize=9)
    ax.set_ylim(-0.15, 0.75)

    ax = axes[2]
    phi = 1.0
    cands = np.linspace(0.05, 0.95, 60)
    ax.plot(cands, np.log(phi / cands), "-", color=BLU, lw=2.0,
            label="per-member gain")
    ax.axvline(0.20, color=VER, ls="--", lw=1.4)
    ax.axhline(np.log(phi / 0.20), color=VER, ls=":", lw=1.2)
    ax.annotate("best member\nsets the coalition",
                xy=(0.20, np.log(phi / 0.20)), xytext=(0.40, 1.15),
                fontsize=7, color=VER,
                arrowprops=dict(arrowstyle="->", color=VER, lw=1.0))
    ax.set_xlabel("candidate floor $a$")
    ax.set_ylabel("log gain")
    ax.set_title("max-type coalition", fontsize=9)
    ax.legend(loc="upper right", frameon=False, fontsize=7)

    fig.tight_layout()
    p = os.path.join(OUT, "fig5_headcount_saturates.png")
    fig.savefig(p, bbox_inches="tight", dpi=200)
    plt.close(fig)
    print("wrote", p)


def fig_corpus():
    """Section 6. Dilution invariance and the selection cap."""
    fig, axes = plt.subplots(1, 3, figsize=(11.0, 3.15))
    m = np.arange(1, 61)

    ax = axes[0]
    floor_1 = np.full_like(m, 0.40, dtype=float)
    floor_5 = np.concatenate([
        np.full(4, 1.00), np.full(56, 0.40)])
    floor_best_first = np.concatenate([
        np.full(4, 0.20), np.full(56, 0.20)])
    ax.plot(m, floor_1, "-", color=GRY, lw=2.0, label="all items at floor $c$")
    ax.plot(m, floor_5, "-", color=BLU, lw=2.0,
            label="one good item arrives at $n=4$")
    ax.plot(m, floor_best_first, "-", color=VER, lw=2.0,
            label="best item arrives at $n=1$")
    ax.axhline(0.30, color=GRN, ls="--", lw=1.4, label="selection threshold $c$")
    ax.set_xlabel("items absorbed")
    ax.set_ylabel("certified floor")
    ax.set_title("Floor depends on one item", fontsize=9)
    ax.legend(loc="center right", frameon=False, fontsize=7)

    ax = axes[1]
    e0, phi_true = 1.0, 0.20
    ax.plot(m, np.full(60, np.log(e0 / 0.30)), "-", color=GRY, lw=2.0,
            label="bound set by selection filter $c$")
    ax.plot(m, np.full(60, np.log(e0 / phi_true)), "-", color=VER, lw=2.0,
            label="bound if a good item exists")
    ax.fill_between(m, np.log(e0 / phi_true), np.log(e0 / 0.30),
                    color=LGR, alpha=0.55, label="corpus growth buys nothing")
    ax.set_xlabel("items absorbed")
    ax.set_ylabel(r"attainable log gain $\log(e_0/\Phi)$")
    ax.set_title("Dilution invariance", fontsize=9)
    ax.legend(loc="center right", frameon=False, fontsize=7)

    ax = axes[2]
    labels = ["100 noise", "99 noise\n+ 1 signal", "50 noise\n+ 50 signal",
              "100 signal"]
    floors = [0.40, 0.20, 0.20, 0.20]
    cols = [GRY, BLU, BLU, BLU]
    bars = ax.bar(range(len(labels)), floors, color=cols, width=0.62)
    ax.axhline(0.30, color=GRN, ls="--", lw=1.4)
    ax.text(3.45, 0.315, "selection floor $c$", color=GRN, fontsize=7,
            ha="right", va="bottom")
    for b, v in zip(bars, floors):
        ax.text(b.get_x() + b.get_width() / 2, v + 0.012, f"{v:.2f}",
                ha="center", fontsize=7, color=K)
    ax.set_xticks(range(len(labels)))
    ax.set_xticklabels(labels, fontsize=7)
    ax.set_ylim(0, 0.5)
    ax.set_ylabel("certified floor")
    ax.set_title("Counts do not matter", fontsize=9)

    fig.tight_layout()
    p = os.path.join(OUT, "fig6_corpus_saturates.png")
    fig.savefig(p, bbox_inches="tight", dpi=200)
    plt.close(fig)
    print("wrote", p)


if __name__ == "__main__":
    fig_headcount()
    fig_corpus()