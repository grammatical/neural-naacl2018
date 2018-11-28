#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import argparse


def main():
    args = parse_user_args()
    info = open(args.file, 'rb')

    for line in sys.stdin:
        merge = int(info.next().strip())
        if merge:
            print line.strip(),
        else:
            print line.strip()


def parse_user_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', '--file', required=True, help="helper file")
    return parser.parse_args()


if __name__ == '__main__':
    main()
