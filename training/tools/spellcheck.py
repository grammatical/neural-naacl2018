#!/usr/bin/env python
# -*- coding: utf-8 -*-

from __future__ import print_function

import sys
import argparse
import enchant


def main():
    args = parse_user_args()
    d = enchant.Dict(args.dict)
    for line in sys.stdin:
        for w in line.strip().split():
            if d.check(w) or not w.isalpha():
                print(w, end=" ")
            else:
                print(d.suggest(w)[0], end=" ")
        print()


def parse_user_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("-d", "--dict", default="en_US", help="dictionary")
    return parser.parse_args()


if __name__ == '__main__':
    main()
