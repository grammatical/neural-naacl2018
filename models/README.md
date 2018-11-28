# Approaching Neural GEC as a Low-Resource MT Task

This repository contains neural models and instructions on how to reproduce our
results for our neural grammatical error correction systems from M.
Junczys-Dowmunt, R. Grundkiewicz, S. Guha, K. Heafield: [_Approaching Neural
Grammatical Error Correction as a Low-Resource Machine Translation
Task_](http://www.aclweb.org/anthology/N18-1055), NAACL 2018.


## Prepared models

We prepared the top neural GEC system described in the paper that is an
ensemble of four transformer models and a neural language model. Each
translation model is pretrained with a language model and trained using
edit-weighted MLE objective on NUCLE and Lang-8 data.

Training settings are described in README in `../training` directory.


## Requirements

The scripts use the official test sets from CoNLL 2013 and 2014 shared tasks
that need to be downloaded separately.

You need to have CUDA 8.0+ and Boost 1.61+ installed for Marian ([see the
official documentation](https://marian-nmt.github.io/docs/)).


## Instructions

1. Install requirements:
    - Python, Perl, Makefile
    - Python Enchant (`sudo apt-get install python-enchant` on Ubuntu)

1. Put the official test sets from CoNLL 2013 and 2014 shared tasks into
   this directory and name them `test2013.m2` and `test2014.m2`.

1. Download required tools, including Marian:

        cd tools
        make all
        cd ..

    If Marian compilation fails, install it manually in `tools/marian-dev`
    following instructions from [the official
    documentation](https://marian-nmt.github.io/docs/).

1. Download the model and helper files:

        ./download.sh

1. Run the system:

        echo "Alice have a cats ." | ./preprocess.sh | /path/to/marian-decoder -c model/config.yml | ./postprocess.sh
        # Alice has a cat .

    The preprocessing script assumes that input is already tokenized using the
    NLTK tokenizer.  If it's not, you may use `tools/nltk_tok.py` to tokenize
    it. The script requires NLTK.

1. Evaluate on CoNLL and JFLEG data sets using a single GPU with ID 0:

        bash evaluate.sh 0

This should produce the following results:

- CoNLL 2013: 44.56 M2
- CoNLL 2014: 57.53 M2
- JFLEG Dev: 54.1276 GLEU
- JFLEG Test: 59.7967 GLEU

