SHELL = /bin/bash
THREADS = 8
PARALLEL = parallel --no-notice --pipe -k -j $(THREADS) --block 25M

.DELETE_ON_ERROR:
.SUFFIXES:
.PHONY: all conll jfleg lang8 test-data train-data


all: test-data train-data

test-data: \
	test2013.lc.bpe.err \
	test2014.lc.bpe.err \
	jflegdev.lc.bpe.err \
	jflegtest.lc.bpe.err

train-data: \
	trainset.lc.bpe.err.gz trainset.lc.bpe.cor.gz \
	trainset.lc.bpe.cor.w3 \
	test2013.lc.bpe.err test2013.lc.bpe.cor \
	devset.lm.lc.bpe.cor \
	mono.lc.bpe.gz


###############################################################################
### DATA SETS

# Prepare CoNLL data
conll: \
	nucle.lc.bpe.err nucle.lc.bpe.cor \
	nucle.mer.lc.bpe.err nucle.mer.lc.bpe.cor \
	test2013.lc.bpe.err test2013.lc.bpe.cor \
	test2014.lc.bpe.err test2014.lc.bpe.cor

%.txt: conll/%.m2
	cat $< | perl ../tools/m2_to_txt.pl > $@

%.mer.txt: conll/%.m2
	perl ../tools/error_rate.pl --mer 0.15 --m2in $< --errout $*.mer.tmp.err --corout $*.mer.tmp.cor --m2out $*.mer.m2
	paste $*.mer.tmp.err $*.mer.tmp.cor | python ../tools/remove_empty_lines.py > $@
	rm $*.mer.tmp.???

# Prepare JFLEG data
jfleg: \
	jflegdev.lc.bpe.err jflegdev.lc.bpe.ref0 jflegdev.lc.bpe.ref1 jflegdev.lc.bpe.ref2 jflegdev.lc.bpe.ref3 \
	jflegtest.lc.bpe.err jflegtest.lc.bpe.ref0 jflegtest.lc.bpe.ref1 jflegtest.lc.bpe.ref2 jflegtest.lc.bpe.ref3

jflegtest.err: ../tools/jfleg/test/test.src
	python ../tools/spellcheck.py < $^ > $@
jflegtest.ref%: ../tools/jfleg/test/test.ref%
	cp $^ $@
jflegdev.err: ../tools/jfleg/dev/dev.src
	python ../tools/spellcheck.py < $^ > $@
jflegdev.ref%: ../tools/jfleg/dev/dev.ref%
	cp $^ $@

# Download and prepare Lang-8
lang8: lang8.clean.lc.bpe.err lang8.clean.lc.bpe.cor

lang8.clean.txt.gz:
	wget -nc http://data.statmt.org/romang/gec-naacl18/$@


###############################################################################
### MONOLINGUAL

mono.lc.bpe.gz: sim.nltk.part.01.txt.xz
	xz -dc $< | head -n 100MB \
		| parallel --no-notice --pipe -j $(THREADS) --block 50M \
		' ../tools/moses-scripts/scripts/tokenizer/escape-special-chars.perl \
		| ../tools/subword-nmt/subword_nmt/apply_bpe.py -c helpers/gec.bpe' \
	| pigz -c > $@

sim.nltk.part.%.txt.xz:
	wget -nc http://data.statmt.org/romang/gec-emnlp16/sim/$@


###############################################################################
### TRAIN SETS

# Training set for NMT models consists of clean Lang-8 and NUCLE with increased error rate
# (oversampled 10 times)
trainset.lc.bpe.%: lang8.clean.lc.bpe.% nucle.mer.lc.bpe.%
	cp $< $@
	seq 10 | xargs -I{} cat $(word 2,$^) >> $@
trainset.lc.bpe.%.gz: trainset.lc.bpe.%
	pigz -c $< > $@

%.lc.bpe.cor.w3: %.lc.bpe.err %.lc.bpe.cor
	paste $^ | $(PARALLEL) python ../tools/edit_weights.py -w 3 > $@

# Development set for LM consists of the CoNLL 2013 Test Set (corrected sentences) and JFLEG Dev
# (first reference only)
devset.lm.lc.bpe.cor: test2013.lc.bpe.cor jflegdev.lc.bpe.ref0
	cat $^ > $@


###############################################################################
### PRERPOCESSING

%.lc.bpe.err: %.err | helpers
	cat $< | $(PARALLEL) bash ../scripts/preprocess.sh > $@
%.lc.bpe.cor: %.cor | helpers
	cat $< | $(PARALLEL) bash ../scripts/preprocess.sh > $@
jflegtest.lc.bpe.ref%: jflegtest.ref% | helpers
	cat $< | $(PARALLEL) bash ../scripts/preprocess.sh > $@
jflegdev.lc.bpe.ref%: jflegdev.ref% | helpers
	cat $< | $(PARALLEL) bash ../scripts/preprocess.sh > $@

%.err: %.txt.gz
	pigz -dc $< | cut -f1 > $@
%.cor: %.txt.gz
	pigz -dc $< | cut -f2 > $@

%.err: %.txt
	cut -f1 $< > $@
%.cor: %.txt
	cut -f2 $< > $@

helpers:
	mkdir -p $@
	cd $@ && wget -nc http://data.statmt.org/romang/gec-naacl18/$@.tgz
	cd $@ && tar zxvf $@.tgz


###############################################################################
### CLEAN

clean:
	rm -f trainset.* devset.* jfleg* test* nucle* lang8*
