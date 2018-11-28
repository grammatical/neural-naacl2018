#!/usr/bin/python

import sys
import argparse
import nltk
import os
import multiprocessing

NLTK_DATA = "{}/.local/share/nltk_data".format(os.path.expanduser("~"))
SEGMENTER = None

THREADS = 16
CHUNKSIZE = 16


def main():
    args = parse_args()
    nltk.data.path.append(args.nltk_data)

    global NORMALIZE_QUOTES, SEGMENTER
    NORMALIZE_QUOTES = args.change_quotes

    if args.split_lines:
        SEGMENTER = nltk.data.load("tokenizers/punkt/{}.pickle".format(
            args.language))
        func = nltk_segmentize
    else:
        func = nltk_tokenize

    pool = multiprocessing.Pool(args.jobs)
    for result in pool.imap(nltk_tokenize, sys.stdin, chunksize=CHUNKSIZE):
        print result
    pool.close()
    pool.join()


def nltk_segmentize(line, change_quotes=False):
    sents = []
    for sent in segmenter.tokenize(line.lstrip()):
        sents.append(nltk_tokenize(sent, change_quotes))
    return "\n".join(sents)


def nltk_tokenize(line, change_quotes=False):
    toks = " ".join(nltk.word_tokenize(line.strip()))
    if not change_quotes:
        toks = toks.replace("``", '"').replace("''", '"')
    return toks


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-l",
        "--language",
        help="language, default: english",
        default="english")
    parser.add_argument(
        "-q",
        "--change-quotes",
        help="replace \"*\" with ``*''",
        action="store_true")
    parser.add_argument(
        "-s",
        "--split-lines",
        help="more than one sentence per line is possible",
        action="store_true")
    parser.add_argument(
        "--nltk-data", help="path to NLTK data", default=NLTK_DATA)
    parser.add_argument(
        "-j",
        "--jobs",
        help="number of parallel jobs, default: 16",
        type=int,
        default=THREADS)
    return parser.parse_args()


if __name__ == "__main__":
    main()
