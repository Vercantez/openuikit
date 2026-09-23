"""Merge a fresh symbolinkprobe harvest into the committed ink tables:
add entries for names not yet stored, in the stored configurations only, and
check the committed aliases (default == 17|regular|unspecified,
body|medium|large == 17|medium|large) still hold byte-for-byte for every new
name; also require every already-stored entry to be re-harvested identically.
usage: merge_symbols.py <committed.json> <harvest.json> <names.txt>"""
import json, sys

committed_path, harvest_path, names_path = sys.argv[1:4]
old = json.load(open(committed_path))
new = json.load(open(harvest_path))
configs = sorted({"|".join(k.split("|")[1:]) for k in old["entries"]})
for k, v in old["entries"].items():
    assert new["entries"].get(k) == v, f"re-harvest differs for {k}"
names = [n for n in open(names_path).read().split() if n]
added = 0
for name in names:
    if name in old["names"]:
        continue
    for c in configs:
        key = f"{name}|{c}"
        assert key in new["entries"], f"missing {key}"
        old["entries"][key] = new["entries"][key]
        added += 1
    phases = sorted({c.split("|")[-1] for c in configs})
    for ph in phases:
        assert new["entries"][f"{name}|default|{ph}"] == new["entries"][f"{name}|17|regular|unspecified|{ph}"], name
        assert new["entries"][f"{name}|body|medium|large|{ph}"] == new["entries"][f"{name}|17|medium|large|{ph}"], name
    old["names"].append(name)
json.dump(old, open(committed_path, "w"), separators=(",", ":"), sort_keys=False)
print(f"{committed_path}: +{added} entries, {len(old['names'])} names")
