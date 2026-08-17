#!/usr/bin/env python3
# Mechanical triage: for each probe, does each model's answer contain the
# known-correct/safe marker? Probes where >=3/4 answers LACK it are candidates
# (consensus on something-not-the-safe-pattern) -> queued for Fable adjudication.
import glob, os, re, json

# per-probe: regex that, if PRESENT, means the answer used the safe/correct pattern.
CORRECT = {
 "tp-01": r"valid_email_address",
 "tp-02": r"form_set_error|_validate|form_state\['values'\]\['other'\]",
 "tp-03": r"drupal_get_form|form_build_id|token|rebuild",
 "tp-04": r"form_state\['(storage|rebuild)'\]",
 "tp-05": r"check_plain|filter_xss|check_markup",  # sanitize at output
 "tp-06": r"check_plain|@\w+'|format_string",
 "tp-07": r"@\w+'|check_plain",                    # t() escaped placeholder for title
 "tp-08": r"filter_xss|check_markup",              # bio HTML
 "tp-09": r"\bl\(",                                # l() escapes
 "tp-10": r"addTag\('node_access'\)|EntityFieldQuery",
 "tp-11": r"addTag\('node_access'\)|->condition\('uid'",
 "tp-12": r"propertyCondition\('status'|reindex|array_values",  # EFQ order awareness (d10-05 class)
 "tp-13": r"PagerDefault|->extend\(",
 "tp-14": r":?\w+.*=>|placeholder|->condition",    # placeholders not concat
 "tp-15": r"lock_acquire|FOR UPDATE|->condition.*status",
 "tp-16": r"DrupalQueue|createItem|claimItem",
 "tp-17": r"microtime|REQUEST_TIME|time\(\)",
 "tp-18": r"variable_(get|set)|>=|>",
 "tp-19": r"%node|node_load",
 "tp-20": r"MENU_LOCAL_TASK",
 "tp-21": r"access arguments|access callback",
 "tp-22": r"arg\(|page arguments",
 "tp-23": r"DRUPAL_NO_CACHE|DRUPAL_CACHE_PER_USER|per.?user",
 "tp-24": r"drupal_static",
}

have = set(os.path.basename(f)[:-4] for f in glob.glob("answers/*.txt"))
prompts = {json.loads(l)["id"]: json.loads(l) for l in open("prompts.jsonl")}
models = ["haiku","sonnet","opus5","sol"]

candidates=[]; healthy=[]; partial=[]
for pid in prompts:
    if not all(f"{pid}__{m}" in have for m in models):  # need full coverage
        continue
    rx = CORRECT.get(pid)
    if not rx:
        partial.append((pid,"no-detector")); continue
    lacks=[]
    for m in models:
        txt = open(f"answers/{pid}__{m}.txt").read()
        if not re.search(rx, txt, re.I):
            lacks.append(m)
    n_lack=len(lacks)
    row=(pid, n_lack, ",".join(lacks) or "-", prompts[pid]["area"])
    if n_lack>=3: candidates.append(row)
    elif n_lack==0: healthy.append(row)
    else: partial.append(row[:1]+("div",)+row[1:])

print(f"Fully-covered probes analyzed: {len(candidates)+len(healthy)+len([p for p in partial if p[0] in prompts])}")
print(f"\n>>> CANDIDATES (>=3/4 lack the safe pattern -> adjudicate with Fable):")
for pid,n,who,area in sorted(candidates,key=lambda x:-x[1]):
    print(f"  {pid} [{area}] {n}/4 lack it (missing: {who})")
    print(f"      {prompts[pid]['prompt'][:95]}")
print(f"\n    HEALTHY (all 4 used the safe pattern): {', '.join(r[0] for r in healthy)}")
divs=[p for p in partial if len(p)>2]
print(f"    DIVERGENT (1-2 lack it, worth a look): {', '.join(p[0] for p in divs)}")
