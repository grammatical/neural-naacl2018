#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import argparse
import re

SPLIT_REGEX = re.compile(r'(\s|\b)\.(@@ )?[A-Z]')


def main():
    args = parse_user_args()
    info = open(args.file, 'w+')

    for sid, line in enumerate(sys.stdin):
        sent = line.strip()
        toks = sent.split()
        if len(toks) <= args.max_length:
            print line.strip()
            info.write("0\n")
            continue

        start = 0
        frags = 0
        for match in SPLIT_REGEX.finditer(sent):
            # print "{}\t|{}|\t{}".format(match.start(), match.group(), match.span())
            frags += 1

            # keep everything before a dot at the end of the previous sentence
            idx = match.group().index(".") + 1
            tail = match.group()[:idx]
            print sent[start:match.start()] + tail
            info.write("1\n")

            start = match.start() + len(tail)
            # remove leading BPE codes
            if ".@@ " in match.group():
                start += 3

        if start < len(sent):
            print sent[start:]
            info.write("0\n")

    info.close()

def parse_user_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', '--file', required=True, help="helper file")
    parser.add_argument(
        '-m', '--max-length', default=80, help="max sentence length in words")
    return parser.parse_args()


if __name__ == '__main__':
    main()
