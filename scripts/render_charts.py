#!/usr/bin/env python3
"""Render the README result charts as static SVGs — from receipts, like every
other number in this repo. Emits light + dark variants for GitHub's
<picture>-based theme switching.

Usage: scripts/render_charts.py          (writes docs/charts/*.svg)

Data sources: results/runs.jsonl (matrix; default-effort, non-clean-room),
experiments/live-site/runs.jsonl, experiments/{gen-vs-recognition,
cross-lab-review}/reviews.jsonl. No dependencies beyond the stdlib.
"""
import json, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "docs", "charts")
os.makedirs(OUT, exist_ok=True)

THEMES = {
    "light": dict(ink="#1A1E24", ink2="#4A5460", ink3="#8B95A1", line="#C9D0D7",
                  accent="#C96A32", cpass="#DCEFE4", cpartial="#F3E8CC", cfail="#F2DCD9",
                  tpass="#2F7D55", tpartial="#B98A2E", tfail="#B34A41", ghost="#C9D0D7",
                  panel="#FBFCFD"),
    "dark": dict(ink="#E6E9ED", ink2="#9AA5B1", ink3="#5F6B78", line="#39424D",
                 accent="#E07A3F", cpass="#16311F", cpartial="#33290F", cfail="#381B17",
                 tpass="#4CAF7D", tpartial="#D9A13B", tfail="#D0655A", ghost="#333B45",
                 panel="#151A21"),
}
MONO = "ui-monospace,'SF Mono','Cascadia Code',Menlo,Consolas,monospace"

VENDORS = [
    ("Anthropic", [("claude-fable-5", "fable-5"), ("claude-opus-4-8", "opus-4.8"),
                   ("claude-sonnet-5", "sonnet-5"), ("claude-haiku-4-5", "haiku-4.5")]),
    ("Google", [("gemini:gemini-3.1-pro-preview", "g3.1-pro"), ("gemini:gemini-3-flash", "g3-flash")]),
    ("OpenAI", [("openai:gpt-5.6-sol", "5.6-sol"), ("openai:gpt-5.6-luna", "5.6-luna")]),
    ("xAI", [("openrouter:x-ai/grok-4.5", "grok-4.5")]),
    ("Moonshot", [("openrouter:moonshotai/kimi-k3", "kimi-k3"),
                  ("openrouter:moonshotai/kimi-k2.7-code", "k2.7-code")]),
    ("Alibaba", [("openrouter:qwen/qwen3-coder-next", "qwen3-next")]),
    ("DeepSeek", [("openrouter:deepseek/deepseek-v3.2", "ds-v3.2")]),
]
MODELS = [(mid, label) for _, ms in VENDORS for mid, label in ms]
TASK_ORDER = ["e-01-decoder-roundtrip", "e-02-impossible-states", "e-06-unicode-length",
              "e-07-tagged-union-decode", "e-08-muac-classify", "b-01-write-e2e",
              "d10-02-cache-bug", "d10-04-cache-context-leak", "d10-05-query-access-leak",
              "d7-01-menu-endpoint", "d7-03-field-migration", "d7-05-save-trigger-queue",
              "d7-06-node-access-grants", "d7-07-batched-update", "d7-08-multilingual-field"]
SHORT = {t: t.replace("-menu-endpoint", " menu endpoint").replace("-decoder-roundtrip", " decoder round-trip")
         .replace("-impossible-states", " impossible states").replace("-unicode-length", " unicode length")
         .replace("-tagged-union-decode", " tagged-union decode").replace("-muac-classify", " MUAC classify")
         .replace("-write-e2e", " write-the-E2E").replace("-cache-bug", " cache invalidation")
         .replace("-cache-context-leak", " cache context").replace("-query-access-leak", " query access leak")
         .replace("-field-migration", " field migration").replace("-save-trigger-queue", " save-trigger queue")
         .replace("-node-access-grants", " node-access grants").replace("-batched-update", " batched update")
         .replace("-multilingual-field", " multilingual field") for t in TASK_ORDER}

def rows(path):
    with open(os.path.join(ROOT, path)) as f:
        for line in f:
            line = line.strip()
            if line:
                yield json.loads(line)

# ---- data -------------------------------------------------------------------
cells = {}   # (task, model) -> [pass, n]
for r in rows("results/runs.jsonl"):
    a = r.get("agent", {})
    if a.get("effort", "default") != "default" or a.get("clean_room"):
        continue
    k = (r["task"], r["model"])
    p, n = cells.get(k, [0, 0])
    cells[k] = [p + (1 if r["pass"] else 0), n + 1]

effort = {}  # model -> [p, n] on d7-01 at raised effort
for r in rows("results/runs.jsonl"):
    a = r.get("agent", {})
    if r["task"] == "d7-01-menu-endpoint" and a.get("effort", "default") != "default":
        p, n = effort.get(r["model"], [0, 0])
        effort[r["model"]] = [p + (1 if r["pass"] else 0), n + 1]

live = {}    # model -> [p, n]
for r in rows("experiments/live-site/runs.jsonl"):
    p, n = live.get(r["model"], [0, 0])
    live[r["model"]] = [p + (1 if r["pass"] else 0), n + 1]

quad = {}    # reviewer -> {ref: [ok, n], flaw: [ok, n]}  (e-06, parse errors excluded)
for path in ("experiments/gen-vs-recognition/reviews.jsonl",
             "experiments/cross-lab-review/reviews.jsonl"):
    for r in rows(path):
        if r.get("task") != "e-06" or r.get("verdict") == "parse_error":
            continue
        d = quad.setdefault(r["reviewer"], {"ref": [0, 0], "flaw": [0, 0]})
        if r["solution"] == "reference":
            d["ref"][1] += 1; d["ref"][0] += (r["verdict"] == "approve")
        else:
            d["flaw"][1] += 1; d["flaw"][0] += (r["verdict"] == "reject")

def esc(s): return s.replace("&", "&amp;").replace("<", "&lt;")

def svg_open(w, h, t):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" '
            f'viewBox="0 0 {w} {h}" font-family="{MONO}">'
            f'<rect width="{w}" height="{h}" fill="{t["panel"]}"/>')

def text(x, y, s, size, fill, anchor="start", weight="normal"):
    return (f'<text x="{x}" y="{y}" font-size="{size}" fill="{fill}" '
            f'text-anchor="{anchor}" font-weight="{weight}">{esc(s)}</text>')

# ---- chart 1: heatmap -------------------------------------------------------
def heatmap(t):
    cw, ch, left, top = 62, 26, 205, 74
    w = left + len(MODELS) * cw + 16
    h = top + len(TASK_ORDER) * ch + 46
    s = svg_open(w, h, t)
    x = left
    for vendor, ms in VENDORS:
        s += text(x + len(ms) * cw / 2, 20, vendor.upper(), 10, t["ink3"], "middle")
        s += f'<line x1="{x+3}" y1="26" x2="{x+len(ms)*cw-3}" y2="26" stroke="{t["line"]}"/>'
        for mid, label in ms:
            s += text(x + cw / 2, 46, label, 10, t["ink2"], "middle")
            x += cw
    for i, task in enumerate(TASK_ORDER):
        y = top + i * ch
        trap = task == "d7-01-menu-endpoint"
        s += text(left - 10, y + 17, SHORT[task], 11, t["accent"] if trap else t["ink"],
                  "end", "bold" if trap else "normal")
        for j, (mid, _) in enumerate(MODELS):
            c = cells.get((task, mid))
            cx = left + j * cw
            if not c:
                s += f'<circle cx="{cx+cw/2}" cy="{y+13}" r="2" fill="{t["ghost"]}"/>'
                continue
            p, n = c
            bg, fg = ((t["cpass"], t["tpass"]) if p == n else
                      (t["cfail"], t["tfail"]) if p == 0 else (t["cpartial"], t["tpartial"]))
            s += f'<rect x="{cx+2}" y="{y+2}" width="{cw-4}" height="{ch-4}" fill="{bg}"/>'
            s += text(cx + cw / 2, y + 18, f"{p}/{n}", 10.5, fg, "middle",
                      "bold" if p == 0 else "normal")
        if trap:
            s += (f'<rect x="{left-200}" y="{y}" width="{200+len(MODELS)*cw+8}" height="{ch}" '
                  f'fill="none" stroke="{t["accent"]}" stroke-width="1.5"/>')
    s += text(left - 200, h - 16, "cell = passes/trials · dot = not run · "
              "orange row = the corpus-trap task (see below)", 10.5, t["ink3"])
    return s + "</svg>"

# ---- chart 2: d7-01 staircase ----------------------------------------------
def staircase(t):
    data = []
    for mid, label in MODELS:
        c = cells.get(("d7-01-menu-endpoint", mid))
        if c:
            data.append((label, c[0], c[1], c[0] / c[1]))
    data.sort(key=lambda d: -d[3])
    bw, gap, x0, y0, bh = 62, 12, 46, 24, 190
    w = x0 + len(data) * (bw + gap) + 20
    s = svg_open(w, y0 + bh + 72, t)
    for i, (label, p, n, frac) in enumerate(data):
        x = x0 + i * (bw + gap)
        col = t["tpass"] if frac == 1 else (t["tfail"] if frac == 0 else t["tpartial"])
        hh = max(3, frac * bh)
        s += f'<rect x="{x}" y="{y0+bh-hh}" width="{bw}" height="{hh}" fill="{col}" opacity="0.9"/>'
        s += text(x + bw / 2, y0 + bh - hh - 7, f"{p}/{n}", 12, col, "middle", "bold")
        s += text(x + bw / 2, y0 + bh + 18, label, 10.5, t["ink2"], "middle")
    s += f'<line x1="{x0-8}" y1="{y0+bh}" x2="{w-12}" y2="{y0+bh}" stroke="{t["line"]}"/>'
    s += text(x0 - 8, y0 + bh + 44, "d7-01 blind pass rate. Every API-engaging failure, "
              "all 7 vendors: the same two wrong patterns. Raised effort rescued only Opus (2/3); other blind-failers 0/24.", 11.5, t["ink2"])
    return s + "</svg>"

# ---- chart 3: levers --------------------------------------------------------
def levers(t):
    order = [("claude-sonnet-5", "sonnet-5"), ("claude-haiku-4-5", "haiku-4.5"),
             ("openai:gpt-5.6-sol", "5.6-sol"), ("openrouter:x-ai/grok-4.5", "grok-4.5"),
             ("openrouter:moonshotai/kimi-k3", "kimi-k3"),
             ("openrouter:moonshotai/kimi-k2.7-code", "k2.7-code"),
             ("openrouter:qwen/qwen3-coder-next", "qwen3-next"),
             ("openrouter:deepseek/deepseek-v3.2", "ds-v3.2")]
    lw, lg, x0, y0, lh = 26, 5, 52, 18, 180
    gw = 3 * (lw + lg) + 26
    w = x0 + len(order) * gw + 8
    s = svg_open(w, y0 + lh + 70, t)
    colors = [t["ghost"], t["tpartial"], t["tpass"]]
    for i, (mid, label) in enumerate(order):
        gx = x0 + i * gw
        blind = cells.get(("d7-01-menu-endpoint", mid))
        for j, v in enumerate([blind, effort.get(mid), live.get(mid)]):
            x = gx + j * (lw + lg)
            if not v:
                s += text(x + lw / 2, y0 + lh - 4, "–", 10, t["ink3"], "middle")
                continue
            frac = v[0] / v[1]
            hh = max(3, frac * lh)
            s += f'<rect x="{x}" y="{y0+lh-hh}" width="{lw}" height="{hh}" fill="{colors[j]}" opacity="0.92"/>'
            s += text(x + lw / 2, y0 + lh - hh - 5, f"{v[0]}/{v[1]}", 9.5, t["ink2"], "middle")
        s += text(gx + gw / 2 - 13, y0 + lh + 18, label, 10.5, t["ink2"], "middle")
    s += f'<line x1="{x0-8}" y1="{y0+lh}" x2="{w-8}" y2="{y0+lh}" stroke="{t["line"]}"/>'
    s += text(x0 - 8, y0 + lh + 42, "grey = blind · amber = high reasoning effort · "
              "green = live site + behavior probe. Effort rescued one model partially; observation "
              "does — bounded by the probe's own blind spot (author-catch #9).", 10.5, t["ink2"])
    return s + "</svg>"

# ---- chart 4: review errors, by direction --------------------------------
def review_errors(t):
    label_map = {"claude-fable-5": "fable-5", "claude-opus-4-8": "opus-4.8",
                 "claude-sonnet-5": "sonnet-5", "claude-haiku-4-5": "haiku-4.5",
                 "openai:gpt-5.6-sol": "5.6-sol", "x-ai/grok-4.5": "grok-4.5",
                 "moonshotai/kimi-k2.7-code": "kimi-k2.7", "deepseek/deepseek-v3.2": "ds-v3.2",
                 "qwen/qwen3-coder-next": "qwen3-next"}
    data = []
    for rid, d in quad.items():
        if d["ref"][1] == 0 or d["flaw"][1] == 0:
            continue
        fa_n = d["ref"][1] - d["ref"][0]          # rejected the correct file
        miss_n = d["flaw"][1] - d["flaw"][0]      # approved the buggy file
        data.append((label_map.get(rid, rid),
                     fa_n, d["ref"][1], miss_n, d["flaw"][1]))
    data.sort(key=lambda d: (d[1] / d[2], d[3] / d[4]))
    cx, half, rh, top = 470, 300, 34, 64
    w, h = cx + half + 170, top + len(data) * rh + 56
    s = svg_open(w, h, t)
    s += text(cx - 14, 22, "hallucinated a bug in the CORRECT file", 11.5, t["tfail"], "end", "bold")
    s += text(cx - 14, 37, "(rejected code that works)", 10, t["ink3"], "end")
    s += text(cx + 14, 22, "missed the REAL bug", 11.5, t["tpartial"], "start", "bold")
    s += text(cx + 14, 37, "(approved broken code)", 10, t["ink3"])
    s += f'<line x1="{cx}" y1="{top-14}" x2="{cx}" y2="{h-40}" stroke="{t["line"]}"/>'
    for tick in (0.5, 1.0):
        for sign in (-1, 1):
            x = cx + sign * tick * half
            s += f'<line x1="{x}" y1="{top-8}" x2="{x}" y2="{h-40}" stroke="{t["line"]}" stroke-dasharray="2 4"/>'
            s += text(x, h - 24, f"{int(tick*100)}%", 9.5, t["ink3"], "middle")
    for i, (label, fa, fan, ms, msn) in enumerate(data):
        y = top + i * rh
        s += text(cx - half - 14, y + 17, label, 11.5, t["ink"], "end", "bold")
        if fa == 0 and ms == 0:
            s += text(cx, y + 17, "no errors", 10, t["tpass"], "middle")
            s += f'<rect x="{cx-half}" y="{y+4}" width="{2*half}" height="{rh-12}" fill="{t["cpass"]}" opacity="0.35"/>'
            continue
        if fa:
            bw = fa / fan * half
            s += f'<rect x="{cx-bw}" y="{y+4}" width="{bw}" height="{rh-12}" fill="{t["tfail"]}" opacity="0.85"/>'
            s += text(cx - bw - 7, y + 19, f"{fa}/{fan}", 10.5, t["tfail"], "end")
        if ms:
            bw = ms / msn * half
            s += f'<rect x="{cx}" y="{y+4}" width="{bw}" height="{rh-12}" fill="{t["tpartial"]}" opacity="0.9"/>'
            s += text(cx + bw + 7, y + 19, f"{ms}/{msn}", 10.5, t["tpartial"])
    return s + "</svg>"

for name, fn in [("heatmap", heatmap), ("staircase", staircase),
                 ("levers", levers), ("review-errors", review_errors)]:
    for theme, tokens in THEMES.items():
        path = os.path.join(OUT, f"{name}-{theme}.svg")
        with open(path, "w") as f:
            f.write(fn(tokens))
        print(f"wrote {os.path.relpath(path, ROOT)}")
