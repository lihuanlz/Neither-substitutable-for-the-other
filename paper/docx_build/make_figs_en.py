# -*- coding: utf-8 -*-
"""
English versions of the two figures that previously only existed as Chinese
PPT assets, so the formal paper has no mixed-language figures.

Style and palette match paper/make_figures.py (Okabe-Ito, colorblind-safe):
  BLU #0072B2, VER #D55E00, GRY #8C8C8C, LGR #C9C9C9, K #000000

Bars/labels use matplotlib mathtext for the barred symbols because no font on
this machine carries the combining macron U+0304.
"""
import io
import math
import os
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

OUT = os.path.normpath(os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "..", "figures"))

K, BLU, VER, GRN = "#000000", "#0072B2", "#D55E00", "#009E73"
GRY, LGR = "#8C8C8C", "#C9C9C9"

plt.rcParams.update({
    "font.family": "sans-serif",
    "font.sans-serif": ["Arial", "Helvetica", "DejaVu Sans"],
    "font.size": 8,
    "axes.linewidth": 0.8,
    "axes.edgecolor": K,
    "xtick.labelsize": 7,
    "ytick.labelsize": 7,
    "axes.labelsize": 8,
    "legend.fontsize": 7,
    "figure.dpi": 300,
    "savefig.dpi": 300,
})


# ---------------------------------------------------------------- figure 5
def fig5_floor():
    """Residual miss rate vs verification rounds, clipped at the TV floor."""
    TV, q, lam = 0.09, 0.5, 1.0
    floor = lam * TV
    N = np.arange(0, 9, 0.02)
    geometric = (1 - q) ** N
    true = np.maximum(geometric, floor)

    # N* = min(N_c, N_0); N_0 is the p-independent cap where the two cross.
    N0 = math.log(1.0 / floor) / math.log(1.0 / (1 - q))

    fig, ax = plt.subplots(figsize=(7.2, 2.75))
    ax.plot(N, geometric, color=VER, linewidth=1.4, linestyle=(0, (4, 2)),
            label=r"naive estimate $(1-q)^{N}$ (no floor)")
    ax.plot(N, true, color=BLU, linewidth=1.8, marker="o", markersize=2.6,
            markevery=25, label=r"true residual  $\max[(1-q)^{N},\,\lambda\mathrm{TV}]$")
    ax.axhline(floor, color=LGR, linewidth=1.0, linestyle=(0, (1, 2.5)))
    ax.axvline(N0, color=BLU, linewidth=0.9, linestyle=(0, (3, 2)))

    ax.annotate(r"$N^{*}=3.474$", xy=(N0, 0.55), xytext=(N0 - 0.05, 0.72),
                fontsize=8, color=BLU)
    ax.annotate(r"floor  $T=\lambda\cdot\mathrm{TV}=0.09$" "\n"
                "from round 4 on, more\nverification buys nothing",
                xy=(4.0, floor), xytext=(4.30, 0.50),
                fontsize=7, color=BLU,
                arrowprops=dict(arrowstyle="->", color=BLU, linewidth=0.8))
    ax.annotate("without the floor,\nverification would\nkeep reducing",
                xy=(7.6, 0.004), xytext=(5.55, 0.135),
                fontsize=7, color=VER)

    ax.set_xlim(0, 8)
    ax.set_ylim(0, 1.05)
    ax.set_xlabel("verification rounds  $N$")
    ax.set_ylabel("residual miss rate")
    ax.legend(loc="upper right", frameon=False)
    fig.tight_layout()
    p = os.path.join(OUT, "fig5_verification_floor.png")
    fig.savefig(p, bbox_inches="tight")
    plt.close(fig)
    print("wrote", p, "| N0 =", round(N0, 3))


# ---------------------------------------------------------------- figure 6
def fig6_sign():
    """Same output, two calibrations, opposite reported sign."""
    sbar = 0.50
    calib = [
        ("A\nLlama-3\n" r"$\bar{\tau}=0.5496$", 1 - 0.5496 / sbar),
        ("B\nMixtral\n" r"$\bar{\tau}=0.4155$", 1 - 0.4155 / sbar),
    ]
    vals = [v for _, v in calib]
    labels = [l for l, _ in calib]

    fig, ax = plt.subplots(figsize=(7.2, 2.75))
    for i, (v, lab) in enumerate(zip(vals, labels)):
        ax.bar(i, v, width=0.34, color=VER if v < 0 else BLU,
               edgecolor=K, linewidth=0.6)
        off = 0.028 if v >= 0 else -0.028
        va = "bottom" if v >= 0 else "top"
        ax.text(i, v + off, f"{v:+.3f}".replace("+0.169", "+0.169").replace("-0.099", "−0.099"),
                ha="center", va=va, fontsize=9,
                color=VER if v < 0 else BLU, fontweight="bold")

    ax.axhline(0, color=GRY, linewidth=0.9)
    ax.set_xticks(range(len(vals)))
    ax.set_xticklabels(labels, fontsize=7.5)
    ax.set_xlim(-0.6, len(vals) - 0.4)
    ax.set_ylim(-0.30, 0.34)
    ax.set_ylabel(r"reported $\hat{\varphi}$")
    ax.text(0.5, 0.265, r"one output,  $\bar{s}=0.50$, and the data never change",
            ha="center", fontsize=8.5, color=K)
    ax.annotate("sign set by the calibration,\nnot by the collaboration",
                xy=(0.5, -0.24), ha="center", fontsize=7, color=GRY)
    fig.tight_layout()
    p = os.path.join(OUT, "fig6_sign_not_identified.png")
    fig.savefig(p, bbox_inches="tight")
    plt.close(fig)
    print("wrote", p, "| vals =", [round(v, 3) for v in vals])


if __name__ == "__main__":
    fig5_floor()
    fig6_sign()
