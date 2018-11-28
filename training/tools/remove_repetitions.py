#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import print_function

import sys
import argparse
import collections
import re


def main():
    args = parse_user_args()
    for i, line in enumerate(sys.stdin):
        words = line.rstrip().split()
        ngrams = get_ngrams(words, args.max_size, args.min_freq)

        if len(ngrams) == 0:
            print(line, end='')
            continue

        text = line.rstrip()
        for ngram_toks, count in ngrams.most_common():
            ngram = " ".join(ngram_toks)
            regex_find = re.escape(" ".join([ngram] * args.min_freq))
            regex_sub = None
            if re.search(regex_find, text):
                regex_sub = "{}(:? {})*".format(regex_find, re.escape(ngram))
                text = re.sub(regex_sub, ngram, text)

            if args.debug:
                sys.stderr.write("  ngram '{}' ({})\n".format(ngram, count))
                sys.stderr.write("    find regex: {}\n".format(regex_find))
                if regex_sub:
                    sys.stderr.write("    sub. regex: {}\n".format(regex_sub))

        print(text)


def get_ngrams(segment, max_order, min_freq):
    counts = collections.Counter()
    for order in range(1, max_order + 1):
        for i in range(0, len(segment) - order + 1):
            ngram = tuple(segment[i:i + order])
            counts[ngram] += 1
    if min_freq > 1:
        for ngram in counts.keys():
            if counts[ngram] < min_freq:
                del counts[ngram]
    return counts


def parse_user_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("-f", "--min-freq", type=int, default=3)
    parser.add_argument("-s", "--max-size", type=int, default=12)
    parser.add_argument("-d", "--debug", action='store_true')
    return parser.parse_args()


if __name__ == "__main__":
    main()
