SOURCES = $(shell ls ?_*.md)
IMAGES = $(shell ls images/*.svg | sed -e 's/svg/pdf/')
TARGETS = complete.pdf gossip.pdf
HELPERS = build complete.md complete.tex gossip.tex

all: $(TARGETS)

complete.md: $(SOURCES)
	cat $^ > $@

%.pdf: %.tex $(IMAGES)
	rm -rf build
	mkdir build
	pdflatex -halt-on-error -output-directory build $<
	cp build/$@ $@

images/%.pdf: images/%.svg
	inkscape -D -z --file=$< --export-pdf=$@

%.tex: %.md
	pandoc -f markdown -t latex $< -o $@ -s

%.tex: ?_%.md
	pandoc -f markdown -t latex $< -o $@ -s

.PHONY: clean
clean:
	rm -rf $(TARGETS) $(HELPERS)
