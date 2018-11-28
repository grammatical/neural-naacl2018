#!/bin/bash -v

if [ $# -lt 1 ]; then
    echo "usage: $0 <gpus>"
    exit 1
fi

ROOT=.
TOOLS=$ROOT/tools
MARIAN=$TOOLS/marian-dev/build
DIR=outputs
mkdir -p $DIR

GPUS=$@


# As NMT models sometimes halucinate some words or punctuations, and M2Scorer
# is fragile on that, we heuristically remove repeated tokens (script
# tools/remove_repetitions.py) from the corrected outputs of the CoNLL 2013 and
# 2014 test sets.
#
# The CoNLL 2014 test set contains an illformed very long sentence, that can
# not be processed by NMT models correctly due to lack of RAM memory, so we
# first split the input into shorter chunks heuristically (scripts
# tools/split_long_sents.py and tools/merge_long_sents.py) and merge them
# afterwards.

echo "CoNLL Test 2013"
cat conll/test2013.m2 | perl $TOOLS/m2_to_txt.pl | cut -f1 \
    | bash preprocess.sh \
    | $MARIAN/marian-decoder -c model/config.yml -d $GPUS -w 4000 --quiet \
    | python $ROOT/tools/remove_repetitions.py \
    | bash postprocess.sh \
    > $DIR/test2013.out

$TOOLS/m2scorer/scripts/m2scorer.py $DIR/test2013.out conll/test2013.m2 \
    | tee $DIR/test2013.eval


echo "CoNLL Test 2014"
cat conll/test2014.m2 | perl $TOOLS/m2_to_txt.pl | cut -f1 \
    | bash preprocess.sh \
    | python $TOOLS/split_long_sents.py -f $DIR/test2014.merge.tmp \
    | $MARIAN/marian-decoder -c model/config.yml -d $GPUS -w 4000 --quiet \
    > $DIR/test2014.temp
cat $DIR/test2014.temp \
    | python $TOOLS/merge_long_sents.py -f $DIR/test2014.merge.tmp \
    | python $ROOT/tools/remove_repetitions.py \
    | bash postprocess.sh \
    > $DIR/test2014.out

$TOOLS/m2scorer/scripts/m2scorer.py $DIR/test2014.out conll/test2014.m2 \
    | tee $DIR/test2014.eval


# Following other works, we first run the Enchant spellchecker (script
# tools/spellcheck.py) on unprocessed source texts of JFLEG data sets and
# substitute each unrecognized alphanumeric tokens with the first suggestion
# from the spellchecker.

echo "JFLEG Dev"
cat $TOOLS/jfleg/dev/dev.src \
    | python $TOOLS/spellcheck.py \
    | bash preprocess.sh \
    | $MARIAN/marian-decoder -c model/config.yml -d $GPUS -w 4000 --quiet \
    | bash postprocess.sh \
    > $DIR/jflegdev.out

python $TOOLS/jfleg/eval/gleu.py --src $TOOLS/jfleg/dev/dev.src --ref $TOOLS/jfleg/dev/dev.ref? --hyp $DIR/jflegdev.out \
    | tee $DIR/jflegdev.eval


echo "JFLEG Test"
cat $TOOLS/jfleg/test/test.src \
    | python $TOOLS/spellcheck.py \
    | bash preprocess.sh \
    | $MARIAN/marian-decoder -c model/config.yml -d $GPUS -w 4000 --quiet \
    | bash postprocess.sh \
    > $DIR/jflegtest.out

python $TOOLS/jfleg/eval/gleu.py --src $TOOLS/jfleg/test/test.src --ref $TOOLS/jfleg/test/test.ref? --hyp $DIR/jflegtest.out \
    | tee $DIR/jflegtest.eval
