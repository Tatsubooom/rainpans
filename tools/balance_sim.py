#!/usr/bin/env python3
"""Greedy-player economy simulation: prints when each milestone is reached.
Keep balance_cfg.json in sync with drum_defs.gd / game.gd when tuning."""
import sys
import json
import os
cfg = json.load(open(os.path.join(os.path.dirname(__file__), "balance_cfg.json")))
D = [tuple(x) for x in cfg["D"]]
DD = {d[0]: d for d in D}
UP = {k: tuple(v) for k, v in cfg["UP"].items()}
AREAS = cfg["AREAS"]  # name, cost, mult
CAP = int(sys.argv[1]) if len(sys.argv) > 1 else 24

owned = {"can": 1}   # bought copies (cost scaling)
placed = {"can": 1}  # copies in the world (income)
lv = {k: 0 for k in UP}
area_mult = 1.0
res, t = 0.0, 0.0


def mult():
    m = area_mult * cfg["RAINM"] ** lv["rain"] * (1 + 0.2 * lv["reverb"]) * (1.5 if lv["echo"] else 1) * (1 + 0.25 * lv["lamp"])
    m *= 1 + 0.1 * max(0, len([k for k in placed if placed[k] > 0]) - 1)
    return m


def income(pl=None):
    pl = pl or placed
    s = sum(n * DD[i][3] * DD[i][4] * 0.85 * 1.12 ** lv["rain"] for i, n in pl.items())
    return s * mult()


def dcost(i):
    _, c, g, y, h = DD[i]
    n = owned.get(i, 0)
    base = c if c > 0 else 8
    return base * g ** n if n > 0 else base


mil = {}
for it in range(100000):
    if t > 12 * 3600:
        break
    inc = income()
    best = None
    full = sum(placed.values()) >= CAP
    for i in DD:
        cost = dcost(i)
        pl = dict(placed)
        if full:
            weakest = min((j for j in pl if pl[j] > 0), key=lambda j: DD[j][3] * DD[j][4])
            pl[weakest] -= 1
            if pl[weakest] == 0:
                del pl[weakest]
        pl[i] = pl.get(i, 0) + 1
        gain = income(pl) - inc
        if gain <= 0:
            continue
        sc = cost / gain + cost / inc
        if best is None or sc < best[0]:
            best = (sc, "d", i, cost, pl)
    for k, (b, g, mx) in UP.items():
        if lv[k] >= mx or k == "drip":
            continue
        cost = b * g ** lv[k]
        lv[k] += 1
        gain = income() - inc
        lv[k] -= 1
        sc = cost / gain + cost / inc
        if best is None or sc < best[0]:
            best = (sc, "u", k, cost, None)
    for a, c, am in AREAS:
        if a in mil or am <= area_mult:
            continue
        gain = inc * (am / area_mult - 1)
        sc = c / gain + c / inc
        if best is None or sc < best[0]:
            best = (sc, "a", a, c, am)
        break
    if best is None:
        break
    _, kind, k, cost, pl = best
    wait = max(0.0, (cost - res) / inc)
    t += wait
    res += wait * inc - cost
    if kind == "a":
        area_mult = pl
        mil[k] = t
    elif kind == "d":
        owned[k] = owned.get(k, 0) + 1
        placed = pl
        mil.setdefault(k, t)
    else:
        lv[k] += 1
        mil.setdefault(k + str(lv[k]), t)
for k, v in sorted(mil.items(), key=lambda kv: kv[1]):
    if not k[-1].isdigit() or k.startswith("rain") and int(k[4:]) in (1, 5, 10):
        print(f"{k:16s} {v / 60:7.1f} min")
print("income/s at end %.3g" % income(), lv, placed)
