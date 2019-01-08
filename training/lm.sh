#!/bin/bash -v

if [ $# -lt 2 ]; then
    print "usage: $0 <dir> <gpus>"
    exit 1
fi

MODEL=$1
shift
GPUS=$1
shift

MARIAN=./tools/marian-dev/build

mkdir -p $MODEL/eval
cp $0 $MODEL/script.sh

$MARIAN/marian --type lm-transformer \
    -d $GPUS \
    --model $MODEL/model.npz \
    --train-sets ./data/mono.lc.bpe.gz \
    --vocabs ./data/helpers/vocab.yml --tied-embeddings-all \
    --max-length 120 --max-length-crop \
    --enc-depth 6 --dec-depth 6 --transformer-heads 8 \
    --transformer-dropout 0.1 \
    --exponential-smoothing --label-smoothing 0.1 \
    --mini-batch-fit -w 10000 --mini-batch 1000 --maxi-batch 1000 --sync-sgd \
    --learn-rate 0.0003 --lr-warmup 16000 --lr-decay-inv-sqrt 16000 --lr-report \
    --optimizer-params 0.9 0.98 1e-09 --clip-norm 5 \
    --cost-type perplexity \
    --valid-metrics perplexity ce-mean-words \
    --valid-sets ./data/devset.lm.lc.bpe.cor \
    --valid-mini-batch 16 \
    --early-stopping 5 --after-epochs 2 \
    --valid-freq 10000 --save-freq 10000 --disp-freq 1000 \
    --overwrite --keep-best \
    --log $MODEL/train.log --valid-log $MODEL/valid.log
