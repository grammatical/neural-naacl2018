# Approaching Neural GEC as a Low-Resource MT Task

This repository contains neural models and instructions on how to reproduce our
results for our neural grammatical error correction systems from M.
Junczys-Dowmunt, R. Grundkiewicz, S. Guha, K. Heafield: [_Approaching Neural
Grammatical Error Correction as a Low-Resource Machine Translation
Task_](http://www.aclweb.org/anthology/N18-1055), NAACL 2018.


## Training scripts

The scripts reproduce the top neural GEC system described in the paper that is
an ensemble of four transformer models and a neural language model. Each
translation model is pretrained with a language model and trained using
edit-weighted MLE objective on NUCLE and Lang-8 data.


## Requirements

The scripts use the NUCLE corpus and official test sets from CoNLL 2013 and
2014 shared tasks that need to be downloaded separately.

You need to have CUDA 8.0+ and Boost 1.61+ installed for Marian ([see the
official documentation](https://marian-nmt.github.io/docs/)).

The scripts are prepared for training on 4 GPUs with 12GB RAM memory.  They
**will produce suboptimal results** on fewer or low-end devices if used
out-of-the-box.  See instructions below if you do not have such resources
available.



## Instructions

1. Install requirements:
    - Python, Perl, Makefile
    - GNU parallel (`sudo apt-get install parallel` on Ubuntu)
    - Python Enchant (`sudo apt-get install python-enchant` on Ubuntu)

1. Put the NUCLE corpus and official test sets from CoNLL 2013 and 2014 shared
   tasks into `data/conll` directory and name them `nucle.m2`, `test2013.m2`
   and `test2014.m2`.
1. Download required tools and compile Marian:

        cd tools
        make tools
        make marian-dev
        cd ..

    If Marian compilation fails, install it manually in `tools/marian-dev`
    following instructions from [the official
    documentation](https://marian-nmt.github.io/docs/).

1. Download and prepare parallel and monolingual data:

        cd data
        make all
        cd ..

1. Start training on 4 GPUs:

        ./train.sh '0 1 2 3'

1. This should eventually produce a system equivalent to the system described
   in the folder `../models`.  A single model needs 1-2 days for training,
   depending on your GPU performance and CUDA settings.


### GPUs

The scripts are prepared for training on 4 GPUs with 12GB RAM memory.
Transformer models are hungry of large mini-batches.  These can be obtained in
Marian either by having a lot of RAM available or by gradients accumulation.
Hence, if you have 4 GPUs with 8GB RAM only, I suggest adding
`--optimizer-delay 3` to training commands (and you need to reduce the
workspace, e.g. `-w 6500`).  I successfully trained some of the models on 2
GPUs with 12GB RAM with `--optimizer-delay` set to 2 or 3.  To make these
changes you need to manually modify `transformer.sh` and `lm.sh`.
