all:
	@echo read the Makefile!

lookup.dylib: lookup.c
	clang -framework CoreServices -shared -o $@ $?

anki:
	# https://github.com/dae/anki
	PYTHONPATH=$(HOME)/Downloads/经济学人词频/p/anki-master \
		   ./q.py
