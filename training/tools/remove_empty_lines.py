#!/usr/bin/python

import sys

for line in sys.stdin:
    if len(line.strip().split("\t")) < 2:
        continue
    print line.strip()
