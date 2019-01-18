#!/bin/bash -v

if [ $# -lt 3 ]; then
    print "usage: $0 <dir> <gpus> <models>"
    exit 1
fi

ROOT=.
TOOLS=$ROOT/tools
SCRIPTS=$ROOT/scripts
DATA=$ROOT/data
MARIAN=$TOOLS/marian-dev/build

DIR=$1
shift
GPUS=$1
shift

OPTIONS="-m $@ -v $DATA/helpers/vocab.yml $DATA/helpers/vocab.yml --mini-batch 32 --beam-size 6 --normalize 1.0 --max-length 120 --max-length-crop --quiet-translation"

mkdir -p $DIR


# CoNLL Test 2013
test -s $DIR/test2013.out || cat $DATA/test2013.lc.bpe.err \
    | $MARIAN/marian-decoder $OPTIONS -d $GPUS 2> $DIR/test2013.stderr \
    | bash $SCRIPTS/postprocess_safe.sh \
    > $DIR/test2013.out

timeout 3m $TOOLS/m2scorer_fork $DIR/test2013.out $DATA/conll/test2013.m2 \
    > $DIR/test2013.eval


# CoNLL Test 2014
test -s $DIR/test2014.temp || cat $DATA/test2014.lc.bpe.err \
    | python $TOOLS/split_long_sents.py -f $DIR/merge.txt \
    | $MARIAN/marian-decoder $OPTIONS -d $GPUS 2> $DIR/test2014.stderr \
    > $DIR/test2014.temp
test -s $DIR/test2014.out || cat $DIR/test2014.temp \
    | python $TOOLS/merge_long_sents.py -f $DIR/merge.txt \
    | bash $SCRIPTS/postprocess_safe.sh \
    > $DIR/test2014.out

timeout 3m $TOOLS/m2scorer_fork $DIR/test2014.out $DATA/conll/test2014.m2 \
    > $DIR/test2014.eval


# JFLEG Dev
test -s $DIR/jflegdev.out || cat $DATA/jflegdev.lc.bpe.err \
    | $MARIAN/marian-decoder $OPTIONS -d $GPUS 2> $DIR/jflegdev.stderr \
    | bash $SCRIPTS/postprocess.sh \
    > $DIR/jflegdev.out

python $TOOLS/jfleg/eval/gleu.py --src $TOOLS/jfleg/dev/dev.src --ref $TOOLS/jfleg/dev/dev.ref? --hyp $DIR/jflegdev.out \
    > $DIR/jflegdev.eval


# JFLEG Test
test -s $DIR/jflegtest.out || cat $DATA/jflegtest.lc.bpe.err \
    | $MARIAN/marian-decoder $OPTIONS -d $GPUS 2> $DIR/jflegtest.stderr \
    | bash $SCRIPTS/postprocess.sh \
    > $DIR/jflegtest.out

python $TOOLS/jfleg/eval/gleu.py --src $TOOLS/jfleg/test/test.src --ref $TOOLS/jfleg/test/test.ref? --hyp $DIR/jflegtest.out \
    > $DIR/jflegtest.eval


echo "Models: $@"
tail $DIR/*.eval
