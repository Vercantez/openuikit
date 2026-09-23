#!/usr/bin/env python3
"""Derive the live-data masks for NetNewsWire's Feeds screen from the GOLDEN's
measured layout (a LayoutDump view tree, Tools/oracle2/layoutdump).

    nnw_feed_masks.py <golden.layout.json> > <variant>.masks.json

Only regions whose content comes from the network are masked:
  * each feed cell's unread-count label (the count comes from fetched
    articles; the port, network fail-closed, has none);
  * each feed cell's icon in the account section (a downloaded favicon, or a
    generated globe that stands in until one downloads).
Smart-feed icons are bundled images and stay graded, as do every title, the
navigation bar, section headers, separators, cell backgrounds and the toolbar.
Each mask is the view's window frame in points, as measured in the golden.
"""
import json, sys

CELL = "NetNewsWire.MainFeedCollectionViewCell"


def masks(dump):
    views = [v for v in dump["views"] if not v.get("hidden")]
    by_path = {v["path"]: v for v in views}
    out = []
    # Account-section cells follow the "On My iPhone" header; smart-feed cells
    # precede it (window y order).
    header = next((v for v in views if v.get("text") == "On My iPhone"), None)
    account_top = header["window_frame"][1] if header else float("inf")
    for cell in (v for v in views if v["class"] == CELL):
        p = cell["path"]
        name = by_path.get(p + ".1.0", {}).get("text", "?")
        count = by_path.get(p + ".1.1")
        if count is not None and count["class"] == "UILabel":
            out.append({"rect": [round(x, 3) for x in count["window_frame"]],
                        "reason": f"unread count of '{name}' (fetched articles, live data)"})
        icon = by_path.get(p + ".1.2")
        if icon is not None and cell["window_frame"][1] > account_top:
            out.append({"rect": [round(x, 3) for x in icon["window_frame"]],
                        "reason": f"favicon of '{name}' (downloaded, or a placeholder until it is)"})
    return out


if __name__ == "__main__":
    dump = json.load(open(sys.argv[1]))
    json.dump({"source": "golden layout dump; Tools/compare/nnw_feed_masks.py",
               "masks": masks(dump)}, sys.stdout, indent=1)
    print()
