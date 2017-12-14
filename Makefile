TARGETS = gossip.pdf
HELPERS = gossip.tex build

all: $(TARGETS)

%.pdf: %.tex
	rm -rf build
	mkdir build
	pdflatex -halt-on-error -output-directory build $<
	cp build/$@ $@

%.tex: %.md
	pandoc -f markdown -t latex $< -o $@ -s

.PHONY: clean
clean:
	rm -rf $(TARGETS) $(HELPERS)
