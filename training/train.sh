#!/bin/bash -v

# Exit on error
set -e

MARIAN=./tools/marian-dev/build
GPUS=$1
shift
OPTIONS=$@

# Check some requirements
test -e $MARIAN/marian
test -e data/test2013.lc.bpe.err
test -e data/trainset.lc.bpe.err.gz
test -e data/mono.lc.bpe.gz

mkdir -p models

# Train language model to be used for initialization of decoder parameters
bash ./lm.sh models/lm.1 "$GPUS" $OPTIONS

# Train and evaluate four transformer models
for i in 1 2 3 4; do
    bash ./transformer.sh models/transformer.$i "$GPUS" $OPTIONS
    bash ./evaluate.sh models/transformer.$i/eval "$GPUS" models/transformer.$i/model.npz.best-translation.npz
done

# Evaluate ensemble without LM
bash ./evaluate.sh models/ensemble/eval "$GPUS" models/transformer.?/model.npz.best-translation.npz

# Train language model to be used in an ensemble
bash ./lm.sh models/lm.2 "$GPUS" $OPTIONS

# Evaluate ensemble with LM setting the weight for LM to 0.4
# Note: the weight may need to be tuned on test2013 for each training run
bash ./evaluate.sh models/ensemble.lm/eval "$GPUS" models/transformer.?/model.npz.best-translation.npz models/lm.2/model.npz.best-perplexity.npz \
    --weights 1. 1. 1. 1. .4

# Print evaluation results
tail models/ensemble.lm/eval/*.eval
