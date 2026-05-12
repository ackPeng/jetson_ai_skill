#!/usr/bin/env python3
import argparse
from pathlib import Path


def files_for_soc(sdk, soc):
    roots = []
    if soc in ("t234", "auto"):
        roots.append(sdk / "source" / "hardware" / "nvidia" / "t23x" / "nv-public")
    if soc in ("t264", "auto"):
        roots.append(sdk / "source" / "hardware" / "nvidia" / "t264" / "nv-public")
    roots.append(sdk / "source" / "hardware" / "nvidia" / "tegra" / "nv-public")
    for root in roots:
        if not root.is_dir():
            continue
        for pattern in ("*.dts", "*.dtsi"):
            yield from root.rglob(pattern)


def score(path, terms):
    text = str(path).lower()
    return sum(1 for term in terms if term.lower() in text)


def main():
    parser = argparse.ArgumentParser(description="Find likely Jetson DTS reference files.")
    parser.add_argument("--sdk", required=True, type=Path, help="Linux_for_Tegra SDK root.")
    parser.add_argument("--soc", default="auto", choices=["auto", "t234", "t264"])
    parser.add_argument("--terms", nargs="*", default=[], help="Search terms such as p3768 p3767 camera.")
    parser.add_argument("--limit", type=int, default=80)
    args = parser.parse_args()

    sdk = args.sdk.resolve()
    paths = list(files_for_soc(sdk, args.soc))
    if args.terms:
        ranked = sorted(
            ((score(path, args.terms), path) for path in paths),
            key=lambda item: (-item[0], str(item[1])),
        )
        paths = [path for value, path in ranked if value > 0]
    else:
        paths = sorted(paths)

    for path in paths[: args.limit]:
        print(path)


if __name__ == "__main__":
    main()
