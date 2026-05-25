#!/usr/bin/env python2
# -*- coding: utf-8 -*-

import os
import re
import sys

FILES = [
    "./scratch/IvyTopo.cc",
    "./scratch/IvyrrTopo.cc",
    "./scratch/IvyspTopo.cc",
    "./scratch/SimpleTopo.cc",
    "./scratch/myTopo.cc",
    "./scratch/lmTopo.cc"
]


def update_file(filepath, suffix):
    if not os.path.exists(filepath):
        print("File not found: %s" % filepath)
        return

    with open(filepath, 'r') as f:
        content = f.read()

    # 替换 traffic_ws_xxx.txt
    content = re.sub(
        r'scratch/traffic_ws_[^"]+\.txt',
        'scratch/traffic_ws_%s.txt' % suffix,
        content
    )

    # 替换 traffic_hd_xxx.txt
    content = re.sub(
        r'scratch/traffic_hd_[^"]+\.txt',
        'scratch/traffic_hd_%s.txt' % suffix,
        content
    )

    with open(filepath, 'w') as f:
        f.write(content)

    print("Updated: %s" % filepath)


def main():
    if len(sys.argv) != 2:
        print("Usage: python update_suffix.py <suffix>")
        print("Example: python update_suffix.py 013")
        sys.exit(1)

    suffix = sys.argv[1]

    for filepath in FILES:
        update_file(filepath, suffix)

    print("Done. Updated suffix to: %s" % suffix)


if __name__ == "__main__":
    main()