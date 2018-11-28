THREADS = 8

.PHONY: all tools


all: tools marian-dev
tools: m2scorer subword-nmt moses-scripts jfleg

m2scorer:
	git clone https://github.com/nusnlp/m2scorer.git
subword-nmt:
	git clone https://github.com/rsennrich/subword-nmt.git
moses-scripts:
	git clone https://github.com/marian-nmt/moses-scripts.git
marian-dev:
	git clone https://github.com/marian-nmt/marian-dev.git
	cd $@ && mkdir build && cd build && cmake .. && make -j$(THREADS)
jfleg:
	git clone https://github.com/keisks/jfleg
