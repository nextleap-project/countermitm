SOURCES = $(shell ls ?_*.md)
TARGETS = complete.pdf gossip.pdf gossip.tex
HELPERS = build complete.md complete.tex

all: $(TARGETS)

complete.md: $(SOURCES)
	cat $^ >> $@

%.pdf: %.tex
	rm -rf build
	mkdir build
	pdflatex -halt-on-error -output-directory build $<
	cp build/$@ $@

%.tex: %.md
	pandoc -f markdown -t latex $< -o $@ -s

%.tex: ?_%.md
	pandoc -f markdown -t latex $< -o $@ -s

.PHONY: clean
clean:
	rm -rf $(TARGETS) $(HELPERS)
