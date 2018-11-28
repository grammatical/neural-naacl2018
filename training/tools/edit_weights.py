#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import print_function

import sys
import difflib
import argparse


def main():
    args = parse_user_args()
    for i, line in enumerate(sys.stdin):
        err, cor = line.rstrip("\n").split("\t")
        weights = []
        matcher = difflib.SequenceMatcher(None, cor.split(), err.split())
        for tag, i1, i2, j1, j2 in matcher.get_opcodes():
            if tag == "equal":
                for x in range(i2, i1, -1):
                    weights.append("1")
            elif tag != "insert":
                for x in range(i2, i1, -1):
                    weights.append(args.weight)
        print(" ".join(weights))


def parse_user_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("-w", "--weight", default="3", help="weight for corrected words")
    return parser.parse_args()


if __name__ == "__main__":
    main()
