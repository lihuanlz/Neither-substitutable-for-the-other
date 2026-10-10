"""Generate Nature-style vector figures for the identifiability manuscript.

All panels are computed from the same quantities that appear in the Lean
development, so figure and theorem cannot drift apart.
"""
import math
import os
import random

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, FancyArrowPatch, Circle
from matplotlib.lines import Line2D

# ---------------------------------------------------------------- style
plt.rcParams.update({
    "font.family": "sans-serif",
    "font.sans-serif": ["Arial", "Helvetica", "DejaVu Sans"],
    "font.size": 8,
    "axes.linewidth": 0.8,
    "axes.edgecolor": "#000000",
    "xtick.labelsize": 7,
    "ytick.labelsize": 7,
    "axes.labelsize": 8,
    "legend.fontsize": 7,
    "figure.dpi": 300,
    "savefig.dpi": 300,
})

K   = "#000000"
BLU = "#0072B2"
VER = "#D55E00"
GRN = "#009E73"
ORG = "#E69F00"
PUR = "#CC79A7"
GRY = "#8C8C8C"
LGR = "#C9C9C9"

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "figures")
os.makedirs(OUT, exist_ok=True)


def panel_tag(ax, letter, dx=-0.16, dy=1.06):
    ax.text(dx, dy, letter, transform=ax.transAxes, fontsize=11,
            fontweight="bold", va="top", ha="left")


def clean(ax, spines=("top", "right")):
    for s in spines:
        ax.spines[s].set_visible(False)


# ================================================================ FIG 1
def fig1():
    fig, axes = plt.subplots(1, 3, figsize=(7.2, 2.9),
                             gridspec_kw={"width_ratios": [1.05, 1.0, 1.15]})

    # ---- (a) two PMFs and the TV computation
    ax = axes[0]
    cats = ["$x_1$", "$x_2$", "$x_3$", "$x_4$"]
    p = [0.42, 0.28, 0.18, 0.12]
    q = [0.10, 0.20, 0.40, 0.30]
    x = range(4)
    w = 0.38
    b1 = ax.bar([i - w / 2 for i in x], p, w, color=BLU,
                edgecolor=K, linewidth=0.6, label="reference  p")
    b2 = ax.bar([i + w / 2 for i in x], q, w, color=VER,
                edgecolor=K, linewidth=0.6, label="alternative  q")
    ax.bar_label(b1, fmt="%.2f", fontsize=6, padding=1)
    ax.bar_label(b2, fmt="%.2f", fontsize=6, padding=1)
    tv = 0.5 * sum(abs(a - b) for a, b in zip(p, q))
    ax.set_xticks(list(x))
    ax.set_xticklabels(cats)
    ax.set_ylabel("probability mass")
    ax.set_xlabel("outcome")
    ax.set_ylim(0, 0.56)
    ax.legend(frameon=False, loc="upper center", ncol=1,
              bbox_to_anchor=(0.5, 1.02))
    ax.text(0.5, -0.34, r"$\mathrm{TV}(p,q)=\frac{1}{2}\sum_x|p_x-q_x|=0.40$",
            transform=ax.transAxes, ha="center", fontsize=8)
    clean(ax)
    panel_tag(ax, "a")

    # ---- (b) ROC family; every Youden vertex lands exactly on J = TV
    ax = axes[1]
    for tvc in [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]:
        xs = [0.0, 1.0 - tvc, 1.0]
        ys = [0.0, 1.0, 1.0]
        ax.plot(xs, ys, color=LGR, linewidth=0.8, zorder=1)
        ax.plot([1.0 - tvc], [1.0], marker="o", markersize=3.2,
                color=GRY, zorder=2)
    tvh = 0.55
    ax.plot([0, 1 - tvh, 1], [0, 1, 1], color=BLU, linewidth=1.6, zorder=3)
    ax.plot([1 - tvh], [1], marker="o", markersize=5, color=BLU, zorder=4)
    ax.plot([1 - tvh, 1 - tvh], [0, 1], linestyle=(0, (3, 2)),
            color=BLU, linewidth=0.8, zorder=3)
    ax.plot([1 - tvh, 1], [1, 1], linestyle=(0, (3, 2)),
            color=BLU, linewidth=0.8, zorder=3)
    ax.annotate("J = TV", xy=(1 - tvh, 1), xytext=(0.30, 0.66),
                fontsize=8, color=BLU,
                arrowprops=dict(arrowstyle="-", color=BLU, linewidth=0.8))
    ax.text(1 - tvh + 0.03, 0.955, "TPR = 1", fontsize=6.5, color=BLU)
    ax.text(0.62, 0.10, "FPR = 1 − TV", fontsize=6.5, color=BLU)
    ax.set_xlabel("false-positive rate")
    ax.set_ylabel("true-positive rate")
    ax.set_xlim(-0.03, 1.03)
    ax.set_ylim(-0.03, 1.03)
    ax.set_aspect("equal")
    clean(ax)
    panel_tag(ax, "b")

    # ---- (c) tightness: J and accuracy advantage are pinned to TV
    ax = axes[2]
    tvs = [i / 100 for i in range(1, 101)]
    ax.plot(tvs, tvs, color=BLU, linewidth=1.6,
            label=r"Youden  $J=\mathrm{TV}$")
    ax.plot(tvs, [(1 + t) / 2 for t in tvs], color=VER, linewidth=1.6,
            label=r"accuracy  $\frac{1+\mathrm{TV}}{2}$")
    ax.axhline(0.5, color=GRY, linewidth=0.7, linestyle=(0, (4, 3)))
    ax.axvline(0.0, color=GRY, linewidth=0.7)
    ax.annotate("chance", xy=(0.35, 0.5), xytext=(0.30, 0.545),
                fontsize=6.5, color=GRY)
    ax.annotate("TV = 0.05", xy=(0.05, 0.525), xytext=(0.30, 0.30),
                fontsize=7, color=VER,
                arrowprops=dict(arrowstyle="->", color=VER, linewidth=0.8))
    ax.text(0.30, 0.255, "max accuracy 52.5%", fontsize=6.5, color=VER)
    ax.text(0.62, 0.72, "bounds attained,\nnot approached",
            fontsize=6.5, color=K, ha="center")
    ax.set_xlabel(r"total variation  $\mathrm{TV}(p,q)$")
    ax.set_ylabel("attainable value")
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1.05)
    ax.legend(frameon=False, loc="lower right", handlelength=1.4)
    clean(ax)
    panel_tag(ax, "c")

    fig.tight_layout()
    fig.savefig(os.path.join(OUT, "fig1_ceiling.png"),
                bbox_inches="tight", facecolor="white")
    fig.savefig(os.path.join(OUT, "fig1_ceiling.pdf"),
                bbox_inches="tight", facecolor="white")
    plt.close(fig)
    print("fig1 done, TV =", round(tv, 4))


# ================================================================ FIG 2
def fig2():
    q = 0.5
    lam = 1.0
    TV = 0.09
    T = lam * TV
    d = -math.log(1 - q)
    N0 = -math.log(T) / d

    p_star, L, c = 0.8, 1.0, 0.01

    fig, axes = plt.subplots(1, 3, figsize=(7.2, 2.9))

    # ---- (a) miss rate: geometric decay clipped by the floor
    ax = axes[0]
    Ns = [i * 0.05 for i in range(0, 201)]
    geo = [(1 - q) ** n for n in Ns]
    miss = [max(g, T) for g in geo]
    ax.plot(Ns, geo, linestyle=(0, (3, 2)), color=GRY, linewidth=1.2,
            label=r"$(1-q)^N$")
    ax.axhline(T, color=VER, linewidth=1.2,
               label=r"floor  $T=\lambda\,\mathrm{TV}$")
    ax.plot(Ns, miss, color=BLU, linewidth=1.8,
            label=r"$\max\!\left[(1-q)^N,\,T\right]$")
    ax.axvline(N0, color=K, linewidth=0.9, linestyle=(0, (2, 2)))
    ax.plot([N0], [T], marker="o", markersize=5, color=K, zorder=5)
    ax.annotate(r"$N_0=\frac{\ln(1/\lambda\,\mathrm{TV})}{d}$",
                xy=(N0, T), xytext=(N0 + 0.9, 0.30),
                fontsize=7.5,
                arrowprops=dict(arrowstyle="->", color=K, linewidth=0.7))
    ax.set_xlabel("verification rounds  $N$")
    ax.set_ylabel("residual miss rate")
    ax.set_ylim(0, 1.02)
    ax.set_xlim(0, 10)
    ax.legend(frameon=False, loc="upper right", handlelength=1.3)
    clean(ax)
    panel_tag(ax, "a")

    # ---- (b) total cost and the two candidate optima
    ax = axes[1]
    A = (1 - p_star) * L
    xc = c / (A * d)
    Nc = -math.log(xc) / d
    Nstar = min(Nc, N0)
    Phistar = 0.7
    def R(n):
        return p_star * Phistar + A * max((1 - q) ** n, T) + c * n
    Ns2 = [i * 0.01 for i in range(0, 1201)]
    ax.plot(Ns2, [R(n) for n in Ns2], color=BLU, linewidth=1.8,
            label=r"$R(N)$")
    ax.axvline(Nc, color=GRY, linewidth=0.9, linestyle=(0, (2, 2)))
    ax.axvline(N0, color=VER, linewidth=0.9, linestyle=(0, (2, 2)))
    ax.axvline(Nstar, color=K, linewidth=1.2)
    ax.plot([Nstar], [R(Nstar)], marker="o", markersize=6, color=K, zorder=5)
    ax.text(Nc + 0.15, R(Nstar) + 0.004, r"$N_c$", fontsize=8, color=GRY)
    ax.text(N0 + 0.15, R(Nstar) + 0.014, r"$N_0$", fontsize=8, color=VER)
    ax.text(Nstar + 0.55, R(Nstar) + 0.026, r"$N^\star=\min(N_c,N_0)$",
            fontsize=8, color=K)
    ax.set_xlabel("verification rounds  $N$")
    ax.set_ylabel("total cost  $R(N)$")
    ax.set_xlim(0, 12)
    ax.set_ylim(R(Nstar) - 0.035, R(Nstar) + 0.050)
    clean(ax)
    panel_tag(ax, "b")

    # ---- (c) N* against reviewer reliability: flat once the floor binds
    ax = axes[2]
    ps = [i / 500 for i in range(5, 499)]
    Ns3 = []
    for p in ps:
        Aa = (1 - p) * L
        xcp = c / (Aa * d)
        Ns3.append(-math.log(max(xcp, T)) / d)
    ax.plot(ps, Ns3, color=BLU, linewidth=1.9)
    p_bind = 1 - c / (L * d * T)
    ax.axvline(p_bind, color=VER, linewidth=1.0, linestyle=(0, (3, 2)))
    ax.axhline(N0, color=VER, linewidth=0.9, linestyle=(0, (2, 2)))
    ax.plot([p_bind], [N0], marker="o", markersize=5, color=VER, zorder=5)
    ax.annotate("floor binds", xy=(p_bind, N0), xytext=(0.44, N0 + 0.55),
                fontsize=7, color=VER,
                arrowprops=dict(arrowstyle="->", color=VER, linewidth=0.7))
    ax.text(0.06, N0 - 0.30, r"$N^\star=N_0$  (no $p$)", fontsize=7, color=VER)
    ax.text(0.78, 0.9, "no dependence\non $p$", fontsize=7, color=BLU,
            ha="center")
    ax.set_xlabel("reviewer reliability  $p$")
    ax.set_ylabel(r"optimal rounds  $N^\star$")
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 5.2)
    clean(ax)
    panel_tag(ax, "c")

    fig.tight_layout()
    fig.savefig(os.path.join(OUT, "fig2_floor.png"),
                bbox_inches="tight", facecolor="white")
    fig.savefig(os.path.join(OUT, "fig2_floor.pdf"),
                bbox_inches="tight", facecolor="white")
    plt.close(fig)
    print(f"fig2 done  d={d:.4f} T={T} N_c={Nc:.3f} N_0={N0:.3f} "
          f"N*={Nstar:.3f} p_bind={p_bind:.4f}")


# ================================================================ FIG 3
def fig3():
    random.seed(7)
    fig, axes = plt.subplots(1, 3, figsize=(7.2, 2.9))

    # ---- (a) observation induces equivalence classes
    ax = axes[0]
    groups = [
        ([(0.12, 0.86), (0.25, 0.63), (0.08, 0.41)], 0.14, BLU, r"\alpha_1"),
        ([(0.42, 0.79), (0.53, 0.51), (0.37, 0.29)], 0.45, VER, r"\alpha_2"),
        ([(0.70, 0.87), (0.83, 0.61), (0.67, 0.41),
          (0.90, 0.23), (0.76, 0.70)], 0.78, GRN, r"\alpha_3"),
    ]
    for pts, ox, col, lab in groups:
        for (lx, ly) in pts:
            ax.plot([lx, ox], [ly, 0.11], color=col, linewidth=0.7,
                    alpha=0.55, zorder=1)
            ax.plot(lx, ly, marker="o", markersize=6, color=col,
                    markeredgecolor=K, markeredgewidth=0.5, zorder=3)
        ax.plot(ox, 0.08, marker="s", markersize=9, color=col,
                markeredgecolor=K, markeredgewidth=0.6, zorder=4)
        ax.text(ox, 0.005, r"$[s^\star]_{" + lab + r"}$", fontsize=8,
                ha="center", va="bottom", color=col)
    ax.text(0.5, 1.02, r"observation protocol  $\Pi$", fontsize=8,
            ha="center", va="bottom", transform=ax.transAxes)
    ax.text(0.01, 0.98, "latent states", fontsize=6.5, color=GRY,
            transform=ax.transAxes, va="top")
    ax.text(0.01, 0.27, "observed\nclasses", fontsize=6.5, color=GRY,
            transform=ax.transAxes, va="top")
    ax.set_xlim(0, 1)
    ax.set_ylim(-0.06, 1.05)
    ax.set_axis_off()
    panel_tag(ax, "a", dx=0.0, dy=1.12)

    # ---- (b) refinement vs within-layer compression
    ax = axes[1]
    layers = ["$\\alpha_1$", "$\\alpha_2$", "$\\alpha_3$", "$\\alpha_4$"]
    Phi = [0.22, 0.41, 0.63, 0.86]
    ax.plot(range(4), Phi, marker="o", markersize=5, color=VER,
            linewidth=1.8, label=r"certified coverage  $\Phi(\alpha)$")
    e0 = 1.0
    for i, (ph,) in enumerate(zip(Phi)):
        es = [e0 * (1 - ph) ** (t + 1) for t in range(4)]
        ax.plot([i + 0.13 * t for t in range(4)], es, marker="s",
                markersize=3.6, color=BLU, linewidth=1.1,
                alpha=0.35 + 0.2 * i)
    ax.plot([], [], marker="s", color=BLU, linewidth=1.1, label="residual  $e_t$")
    ax.axhline(0, color=GRY, linewidth=0.7)
    ax.set_xticks(range(4))
    ax.set_xticklabels(layers)
    ax.set_ylabel("magnitude")
    ax.set_xlabel("resolution layer")
    ax.set_ylim(0, 1.05)
    ax.legend(frameon=False, loc="lower left", bbox_to_anchor=(0.0, 1.005),
              ncol=2, handlelength=1.3, columnspacing=1.2)
    ax.annotate("refinement:  moves $\\Phi$", xy=(0.02, 0.86),
                fontsize=7.5, color=VER)
    ax.annotate("compression:  moves $e_t \\to \\Phi$", xy=(0.02, 0.78),
                fontsize=7.5, color=BLU)
    clean(ax)
    panel_tag(ax, "b")

    # ---- (c) return profiles: unbounded vs capped
    ax = axes[2]
    xs = [i / 100 for i in range(1, 501)]
    cap = math.log(1 / 0.30)
    ax.plot(xs, [x * 9 for x in xs], color=VER, linewidth=1.9, zorder=2,
            label="human, cross-layer\nunbounded")
    ax.plot(xs, [min(x * 9, cap) for x in xs], color=BLU, linewidth=1.9,
            zorder=3, solid_capstyle="butt",
            label="machine, within-layer\n"
                  r"$\leq \log(e_0/\Phi)$")
    ax.axhline(cap, color=BLU, linewidth=0.8, linestyle=(0, (3, 2)),
               zorder=1)
    ax.text(0.62, cap + 0.18, r"$\log(e_0/\Phi)$", fontsize=7.5, color=BLU)
    ax.set_xlabel("effort invested")
    ax.set_ylabel("signed value gained")
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 5.0)
    ax.legend(frameon=False, loc="upper left", handlelength=1.3)
    clean(ax)
    panel_tag(ax, "c")

    fig.tight_layout()
    fig.savefig(os.path.join(OUT, "fig3_layers.png"),
                bbox_inches="tight", facecolor="white")
    fig.savefig(os.path.join(OUT, "fig3_layers.pdf"),
                bbox_inches="tight", facecolor="white")
    plt.close(fig)
    print("fig3 done, cap =", round(cap, 4))


# ================================================================ FIG 4
def fig4():
    fig, axes = plt.subplots(1, 2, figsize=(7.2, 2.7),
                             gridspec_kw={"width_ratios": [1.25, 1.0]})

    M = 2.0
    m = 0.55

    # ---- (a) identical |influence|, opposite signed value
    ax = axes[0]
    rng = random.Random(3)
    for sgn, col, lab, tx in [(1, VER, "+M", m + 0.12),
                          (-1, BLU, "−M", m - 0.16)]:
        for k in range(3):
            amp = m * (1 + 0.06 * k)
            ax.plot([amp], [sgn * M * (1 - 0.07 * k)], marker="o",
                    markersize=7 - 1.2 * k, color=col, markeredgecolor=K,
                    markeredgewidth=0.5, zorder=4)
        ax.plot([m], [sgn * M], marker="o", markersize=9, color=col,
                markeredgecolor=K, markeredgewidth=0.7, zorder=5)
        ax.annotate(lab, xy=(m, sgn * M),
                    xytext=(tx, sgn * M + sgn * 0.45),
                    fontsize=9, color=col, ha="center",
                    arrowprops=dict(arrowstyle="-", color=col, linewidth=0.7))
    ax.axvline(m, color=GRY, linewidth=0.9, linestyle=(0, (3, 2)))
    ax.axhline(0, color=GRY, linewidth=0.9)
    ax.set_xlim(0.26, 0.98)
    ax.set_ylim(-3.2, 3.2)
    ax.set_xlabel(r"influence  $|\Delta|$  (unsigned)")
    ax.set_ylabel("signed value")
    ax.text(0.275, 2.95, "every point here has\nthe same $|\\Delta|$",
            fontsize=7, color=GRY, va="top")
    clean(ax)
    panel_tag(ax, "a")

    # ---- (b) unsigned divergences collapse all cases to one number
    ax = axes[1]
    names = ["refine\ntoward truth", "blur\naway from truth",
             "refine\n(weaker)", "blur\n(weaker)"]
    vals = [M, M, 0.86 * M, 0.86 * M]
    ax.bar(range(4), vals, 0.62, color=LGR, edgecolor=K, linewidth=0.6)
    ax.bar([0, 2], vals[0:1] + vals[2:3], 0.62, color=VER,
           edgecolor=K, linewidth=0.6, label="signed (distinguishes)")
    ax.bar([1, 3], [vals[1], vals[3]], 0.62, color=BLU,
           edgecolor=K, linewidth=0.6, label="signed (distinguishes)")
    for i, v in enumerate(vals):
        ax.text(i, v + 0.05, f"{v:.2f}", ha="center", fontsize=7)
    ax.axhline(0, color=GRY, linewidth=0.9)
    ax.annotate("", xy=(0.06, 2.62), xytext=(0.94, 2.62),
                arrowprops=dict(arrowstyle="<->", color=K, linewidth=0.8))
    ax.text(0.5, 2.70, r"$I(x;y)$ / KL / TV:  both cases $\to$ same scalar",
            fontsize=7, ha="center", va="bottom")
    ax.set_xticks(range(4))
    ax.set_xticklabels(names, fontsize=6.5)
    ax.set_ylabel("reported by the measure", fontsize=7.5)
    ax.set_ylim(0, 3.05)
    clean(ax)
    panel_tag(ax, "b")

    fig.tight_layout()
    fig.savefig(os.path.join(OUT, "fig4_separable.png"),
                bbox_inches="tight", facecolor="white")
    fig.savefig(os.path.join(OUT, "fig4_separable.pdf"),
                bbox_inches="tight", facecolor="white")
    plt.close(fig)
    print("fig4 done")


if __name__ == "__main__":
    fig1()
    fig2()
    fig3()
    fig4()
    print("all figures written to", OUT)