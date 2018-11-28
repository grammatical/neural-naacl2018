#!/bin/bash

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

perl $ROOT/tools/moses-scripts/scripts/tokenizer/escape-special-chars.perl \
    | perl $ROOT/tools/moses-scripts/scripts/recaser/truecase.perl --model $ROOT/data/helpers/tc.model \
    | python $ROOT/tools/subword-nmt/subword_nmt/apply_bpe.py -c $ROOT/data/helpers/gec.bpe
