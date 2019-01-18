#!/bin/bash -v

if [ $# -lt 2 ]; then
    print "usage: $0 <dir> <gpus>"
    exit 1
fi

MODEL=$1
shift
GPUS=$@

MARIAN=./tools/marian-dev/build

mkdir -p $MODEL
cp ./scripts/validate.conll.sh $MODEL/validate.sh
cp $0 $MODEL/script.sh

$MARIAN/marian --type transformer \
    --model $MODEL/model.npz \
    -d $GPUS \
    --pretrained-model models/lm.1/model.npz.best-perplexity.npz \
    --train-sets ./data/trainset.lc.bpe.{err,cor}.gz \
    --vocabs ./data/helpers/vocab.{yml,yml} --tied-embeddings-all \
    --data-weighting-type word --data-weighting ./data/trainset.lc.bpe.cor.w3 \
    --max-length 120 \
    --enc-depth 6 --dec-depth 6 --transformer-heads 8 --enc-type alternating \
    --layer-normalization --skip \
    --dropout-rnn 0.3 --dropout-src 0.2 --dropout-trg 0.1 --transformer-dropout 0.3 \
    --exponential-smoothing --label-smoothing 0.1 \
    --mini-batch-fit -w 9500 --mini-batch 1000 --maxi-batch 1000 --sync-sgd --optimizer-delay 2 \
    --learn-rate 0.0003 --lr-warmup 16000 --lr-decay-inv-sqrt 16000 --lr-report \
    --optimizer-params 0.9 0.98 1e-09 --clip-norm 5 \
    --valid-metrics cross-entropy ce-mean-words translation perplexity \
    --valid-sets ./data/test2013.lc.bpe.{err,cor} \
    --valid-translation-output $MODEL/valid.out --quiet-translation \
    --valid-script-path $MODEL/validate.sh \
    --valid-mini-batch 16 --beam-size 12 --normalize 1.0 \
    --early-stopping 10 \
    --valid-freq 5000 --save-freq 5000 --disp-freq 500 \
    --overwrite --keep-best \
    --log $MODEL/train.log --valid-log $MODEL/valid.log
