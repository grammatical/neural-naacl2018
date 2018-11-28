#!/bin/bash

ROOT="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

sed 's/@@ //g' \
    | perl $ROOT/tools/moses-scripts/scripts/recaser/detruecase.perl \
    | perl $ROOT/tools/moses-scripts/scripts/tokenizer/deescape-special-chars.perl
