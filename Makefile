all: help

EXTERNALS=externals

PYTHON ?= `env which -a python2 python2.7 | head -n1`
PYTHONPATH=$$PYTHONPATH:$(EXTERNALS)/pypy


COMMON_BUILD_OPTS?=--thread --gcrootfinder=shadowstack --continuation
JIT_OPTS?=--opt=jit
TARGET_OPTS?=target.py

help:
	@echo "make help                   - display this message"
	@echo "make run                    - run the compiled interpreter"
	@echo "make run_interactive        - run without compiling (slow)"
	@echo "make build_with_jit         - build with jit enabled"
	@echo "make build_no_jit           - build without jit"
	@echo "make fetch_externals	   - download and unpack external deps"

build_with_jit: fetch_externals re2_cre2
	@if [ ! -d /usr/local/include/boost -a ! -d /usr/include/boost ] ; then echo "Boost C++ Library not found" && false; fi && \
	$(PYTHON) $(EXTERNALS)/pypy/rpython/bin/rpython $(COMMON_BUILD_OPTS) --opt=jit target.py && \
	make compile_basics

build_no_jit: fetch_externals re2_cre2
	@if [ ! -d /usr/local/include/boost -a ! -d /usr/include/boost ] ; then echo "Boost C++ Library not found" && false; fi && \
	$(PYTHON) $(EXTERNALS)/pypy/rpython/bin/rpython $(COMMON_BUILD_OPTS) target.py && \
	make compile_basics

build_no_jit_shared: fetch_externals re2_cre2
	@if [ ! -d /usr/local/include/boost -a ! -d /usr/include/boost ] ; then echo "Boost C++ Library not found" && false; fi && \
	$(PYTHON) $(EXTERNALS)/pypy/rpython/bin/rpython $(COMMON_BUILD_OPTS) --shared target.py && \
	make compile_basics


compile_basics:
	@echo -e "\n\n\n\nWARNING: Compiling core libs. If you want to modify one of these files delete the .pxic files first\n\n\n\n"
	./pixie-vm -c pixie/uv.pxi -c pixie/io.pxi -c pixie/stacklets.pxi -c pixie/stdlib.pxi -c pixie/repl.pxi -c pixie/re.pxi

build: fetch_externals re2_cre2
	$(PYTHON) $(EXTERNALS)/pypy/rpython/bin/rpython $(COMMON_BUILD_OPTS) $(JIT_OPTS) $(TARGET_OPTS)

fetch_externals: $(EXTERNALS)/pypy externals.fetched

externals.fetched:
	echo https://github.com/pixie-lang/external-deps/releases/download/1.0/`uname -s`-`uname -m`.tar.bz2
	curl -L https://github.com/pixie-lang/external-deps/releases/download/1.0/`uname -s`-`uname -m`.tar.bz2 > /tmp/externals.tar.bz2
	tar -jxf /tmp/externals.tar.bz2 --strip-components=2
	touch externals.fetched

$(EXTERNALS):
	mkdir $(EXTERNALS)

$(EXTERNALS)/pypy: $(EXTERNALS)
	cd $(EXTERNALS); \
	curl https://bitbucket.org/pypy/pypy/get/81254.tar.bz2 >  pypy.tar.bz2; \
	mkdir pypy; \
	cd pypy; \
	tar -jxf ../pypy.tar.bz2 --strip-components=1

$(EXTERNALS)/re2: $(EXTERNALS)
	cd $(EXTERNALS) && \
	curl -sL https://github.com/google/re2/archive/2016-02-01.tar.gz > re2.tar.gz && \
	shasum -a 256 re2.tar.gz | grep -q f246c43897ac341568a7460622138ec0dd8de9b6f5459686376fa23e9d8c1bb8 && \
  mkdir -p re2 && \
  cd re2 && \
	tar -zxf ../re2.tar.gz --strip-components=1 && \
	make CPPFLAGS="-fPIC"

$(EXTERNALS)/cre2: $(EXTERNALS)
	cd $(EXTERNALS) && \
	curl -sL https://bitbucket.org/marcomaggi/cre2/downloads/cre2-0.2.0.tar.xz > cre2.tar.xz && \
  shasum -a 256 cre2.tar.xz | grep -q d31118dbc9d2b1cf95c1b763ca92ae2ec4e262b1f8d8e995c1ffdc8eb40a82fc && \
  mkdir -p cre2 && \
  cd cre2 && \
	tar -Jxf ../cre2.tar.xz --strip-components=1 && \
	mkdir -p build && \
	cd build && \
	../configure LDFLAGS="-L`pwd`/../../re2/obj" CPPFLAGS="-I`pwd`/../../re2" && \
	chmod +x ../meta/autotools/install-sh && \
	make

re2: $(EXTERNALS)/re2

cre2: $(EXTERNALS)/cre2
	mkdir -p lib/ include/ && \
	ln -sf ../$(EXTERNALS)/cre2/src/cre2.h include/ && \
  cd lib && \
	ln -sf ../$(EXTERNALS)/cre2/build/.libs/* ./

re2_cre2: re2 cre2

run:
	./pixie-vm

run_interactive:
	@PYTHONPATH=$(PYTHONPATH) $(PYTHON) target.py

run_interactive_stacklets:
	@PYTHONPATH=$(PYTHONPATH) $(PYTHON) target.py pixie/stacklets.pxi


run_built_tests: pixie-vm
	./pixie-vm run-tests.pxi

run_interpreted_tests: target.py
	PYTHONPATH=$(PYTHONPATH) $(PYTHON) target.py run-tests.pxi

compile_tests:
	find "tests" -name "*.pxi" | xargs -L1 ./pixie-vm -l "tests" -c

compile_src:
	find * -name "*.pxi" | grep "^pixie/" | xargs -L1 ./pixie-vm $(EXTERNALS_FLAGS) -c

clean_pxic:
	find * -name "*.pxic" -delete

clean: clean_pxic
	rm -rf ./lib
	rm -rf ./include
	rm -rf ./externals*
	rm -f ./pixie-vm
	rm -f ./*.pyc
