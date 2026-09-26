#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import shutil
import urllib.request
from pathlib import Path

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", default="references/hud/web_references.json")
    parser.add_argument("--output", default="build/hud-web-references")
    args = parser.parse_args()

    manifest = json.loads(Path(args.manifest).read_text(encoding="utf-8"))
    output = Path(args.output)
    output.mkdir(parents=True, exist_ok=True)

    for index, item in enumerate(manifest["references"], 1):
        destination = output / f"web_{index:02d}.jpg"
        request = urllib.request.Request(
            item["image_url"],
            headers={"User-Agent": "CollisionBattlestar-HUDAI/1.0"},
        )
        with urllib.request.urlopen(request, timeout=30) as response:
            data = response.read()
        destination.write_bytes(data)
        print(f"downloaded {item['id']} -> {destination}")

    print(f"references={len(manifest['references'])}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
