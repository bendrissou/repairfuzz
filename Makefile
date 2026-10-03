# RepairFuzz -- convenience wrapper around scripts/.
# Every target here is a thin alias; the scripts are the real interface.

SHELL      := /bin/bash
LANGS      := lua ruby js php
GRAMMAR    ?= corpus
LANG       ?= lua
DURATION   ?= 120

.PHONY: help setup mutators mutator repair-cli quickstart docker clean distclean

help:
	@echo "RepairFuzz"
	@echo
	@echo "  make setup                      fetch + patch + build AFL++ and grmtools"
	@echo "  make mutators [GRAMMAR=corpus]  build repair mutators for all languages"
	@echo "  make mutator LANG=php GRAMMAR=custom"
	@echo "                                  build one mutator"
	@echo "  make repair-cli LANG=lua GRAMMAR=corpus"
	@echo "                                  build the standalone repair/corpus-check CLI"
	@echo "  make quickstart [DURATION=120]  full end-to-end demo on LuaJIT"
	@echo "  make docker                     build the Docker image"
	@echo "  make clean                      remove build outputs (keeps third_party)"
	@echo "  make distclean                  also remove third_party checkouts"
	@echo
	@echo "Languages: $(LANGS)    Grammars: standard, custom, corpus"

setup:
	./scripts/setup.sh

mutators:
	@for l in $(LANGS); do ./scripts/build-mutator.sh $$l $(GRAMMAR); done

mutator:
	./scripts/build-mutator.sh $(LANG) $(GRAMMAR)

repair-cli:
	./scripts/build-repair-cli.sh $(LANG) $(GRAMMAR)

quickstart:
	./examples/quickstart/run.sh $(DURATION)

docker:
	docker build -t repairfuzz .

clean:
	rm -rf build
	rm -rf mutator/*/target tools/repair-cli/target
	rm -f  mutator/*/src/*.l mutator/*/src/*.y
	rm -f  tools/repair-cli/src/grammar.l tools/repair-cli/src/grammar.y

distclean: clean
	rm -rf third_party
