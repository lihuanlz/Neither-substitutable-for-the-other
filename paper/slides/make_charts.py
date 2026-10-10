# -*- coding: utf-8 -*-
"""Render the two data figures used in the deck, in the deck palette."""

import math
import os

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

import theme

os.makedirs(theme.ASSETS, exist_ok=True)

P = theme.PALETTE
plt.rcParams["font.sans-serif"] = ["Microsoft YaHei", "SimHei", "DejaVu Sans"]
plt.rcParams["axes.unicode_minus"] = False

BG = "#" + P["bg"]
PRI = "#" + P["primary"]
SEC = "#" + P["secondary"]
ACC = "#" + P["accent"]
LIGHT = "#" + P["light"]


def floor_figure(path):
    """Residual miss rate is clipped at the TV floor.

    Uses the model from the manuscript:  miss(N) = max[(1-q)^N, T],  T = lam*TV.
    Not an affine blend - the geometric decay is cut off once it reaches the
    floor, which is exactly what makes the budget cap p-independent.
    """
    N = list(range(0, 9))
    T = 0.09
    q = 0.5
    d = 1.0 / (1.0 - q)
    N0 = math.log(1.0 / T) / math.log(d)

    naive = [(1 - q) ** n for n in N]
    true = [max((1 - q) ** n, T) for n in N]

    fig, ax = plt.subplots(figsize=(8, 5), dpi=200)
    fig.patch.set_facecolor(BG)
    ax.set_facecolor(BG)

    ax.plot(N, true, "-o", color=PRI, lw=3, ms=7, label="真实残余漏检率（截断后）")
    ax.plot(N, naive, "--s", color=ACC, lw=2.2, ms=6, label="朴素估计（不截断）")
    ax.axhline(T, color=ACC, lw=1.2, ls=":", alpha=0.85)
    ax.axvline(N0, color=SEC, lw=1.6, ls="--")

    ax.annotate("地板 T = 0.09\n从第 4 轮起，再验证也没用",
                xy=(5.2, T), xytext=(3.6, 0.30), color=PRI, fontsize=11,
                arrowprops=dict(arrowstyle="->", color=PRI, lw=1.4))
    ax.text(N0 + 0.12, 0.52, "N* = 3.474", color=PRI, fontsize=11)
    ax.text(0.06, 0.045, "没有地板的话，验证越多漏检越少",
            color=ACC, fontsize=11)

    ax.set_xlabel("验证轮数 N", color=PRI, fontsize=12)
    ax.set_ylabel("残余漏检率", color=PRI, fontsize=12)
    ax.set_xticks(N)
    ax.set_ylim(0, 1.02)
    ax.tick_params(colors=PRI, labelsize=10)
    for sp in ("top", "right"):
        ax.spines[sp].set_visible(False)
    for sp in ("left", "bottom"):
        ax.spines[sp].set_color(SEC)
    ax.grid(axis="y", color=SEC, lw=0.6, alpha=0.45)
    leg = ax.legend(loc="upper right", frameon=False, fontsize=11)
    for t in leg.get_texts():
        t.set_color(PRI)

    fig.tight_layout()
    fig.savefig(path, facecolor=BG)
    plt.close(fig)
    print("wrote", path)


def signflip_figure(path):
    """One fixed output, two calibrations, opposite signs.

    The barred symbols go through mathtext: no CJK font on this machine
    carries the combining macron U+0304, so a literal "tau + bar" would
    render as a missing-glyph box.
    """
    TBAR = r"$\bar{\tau}$"
    SBAR = r"$\bar{s}$"
    labels = ["标定 A\nLlama-3\n%s = 0.5496" % TBAR,
              "标定 B\nMixtral\n%s = 0.4155" % TBAR]
    vals = [1 - 0.5496 / 0.50, 1 - 0.4155 / 0.50]

    fig, ax = plt.subplots(figsize=(8, 5), dpi=200)
    fig.patch.set_facecolor(BG)
    ax.set_facecolor(BG)

    colors = [PRI, ACC]
    bars = ax.bar([0, 1], vals, width=0.44, color=colors)
    ax.axhline(0, color=PRI, lw=1.6)

    for b, v in zip(bars, vals):
        off = 0.035 if v >= 0 else -0.10
        ax.text(b.get_x() + b.get_width() / 2, v + off, "%+.3f" % v,
                ha="center", color=PRI, fontsize=15, fontweight="bold")

    ax.text(0.5, 0.33, "同一个输出  %s = 0.50" % SBAR, ha="center",
            color=PRI, fontsize=13)
    ax.set_xticks([0, 1])
    ax.set_xticklabels(labels, fontsize=11, color=PRI)
    ax.set_ylim(-0.22, 0.42)
    ax.set_ylabel("报告值", color=PRI, fontsize=12)
    ax.tick_params(colors=PRI, labelsize=10)
    for sp in ("top", "right"):
        ax.spines[sp].set_visible(False)
    for sp in ("left", "bottom"):
        ax.spines[sp].set_color(SEC)
    ax.grid(axis="y", color=SEC, lw=0.6, alpha=0.4)

    fig.tight_layout()
    fig.savefig(path, facecolor=BG)
    plt.close(fig)
    print("wrote", path)


if __name__ == "__main__":
    floor_figure(theme.asset("chart_floor.png"))
    signflip_figure(theme.asset("chart_signflip.png"))
