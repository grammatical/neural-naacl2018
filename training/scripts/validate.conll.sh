#!/bin/bash

MODEL="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$( realpath "$MODEL/../.." )"

cat $1 \
    | sed 's/@@ //g' 2>/dev/null \
    | perl $ROOT/tools/moses-scripts/scripts/recaser/detruecase.perl 2>/dev/null \
    | perl $ROOT/tools/moses-scripts/scripts/tokenizer/deescape-special-chars.perl 2>/dev/null \
    | perl $ROOT/tools/remove_repetitions.py \
    > $MODEL/valid.out.detok

timeout 3m python $ROOT/tools/m2scorer_fork $MODEL/valid.out.detok $ROOT/data/conll/test2013.m2 \
   | tee $MODEL/valid.out.eval \
   | perl -ne 'print "$1\n" if(/^F.*: (\d\.\d+)/)' 2>/dev/null
