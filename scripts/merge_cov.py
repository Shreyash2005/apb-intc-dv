#!/usr/bin/env python3
# merge_cov.py <logs...> : merge coverage across runs.
# A bin is covered if ANY run hit it, so merged "missing" = bins missing in EVERY log.
import re
import sys

pat = re.compile(r"\[COV\] (C\d+) (.+?)\s+(\d+)\s*/\s*(\d+)\s+missing:(.*)$")
cov = {}   # "C1" -> [name, total_bins, set_of_missing]

for path in sys.argv[1:]:
    with open(path) as f:
        for line in f:
            m = pat.search(line)
            if not m:
                continue
            cp, name, _hit, total, miss = m.groups()
            missing = set(miss.split()) - {"none"}
            if cp in cov:
                cov[cp][2] &= missing          # still missing only if missing here too
            else:
                cov[cp] = [name.strip(), int(total), missing]

hit_all = bins_all = 0
print("MERGED COVERAGE (%d logs)" % len(sys.argv[1:]))
for cp in sorted(cov, key=lambda c: int(c[1:])):
    name, total, missing = cov[cp]
    hit = total - len(missing)
    hit_all += hit
    bins_all += total
    print("  %-4s %-20s %2d/%2d  missing: %s"
          % (cp, name, hit, total, " ".join(sorted(missing)) or "none"))
if bins_all:
    print("  TOTAL %d/%d bins = %.1f%%" % (hit_all, bins_all, 100.0 * hit_all / bins_all))
