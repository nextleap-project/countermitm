# countermitm
thoughts, plans on countering mitm-attacks on autocrypt and other messaging systems

## Building the pdfs

The separate approaches are addressed in
* 1_dkim.md
* 2_key_history.md
* 3_gossip.md

These files use markdown with some tex formulars included.

We use pandoc to convert it to latex and then pdflatex to turn the latex
into a pdf document.
For the images we use rsvg2 to convert them from svg to pdf.

In order to create the documents you will need make, pandoc and pdflatex installed
on your system. On a debian based system you can achieve this with

```sh
sudo apt install pandoc texlive-latex-base texlive-fonts-recommended texlive-latex-extra librsvg2-bin
```

From there on creating the pdf should be a matter of running

```sh
make
```

## Build Results

Once the build is completed there will be a complete.pdf file in the
main directory. This contains the different approaches. It still lacks
and introduction and an overview though.

There's also a `gossip.pdf` which only contains the gossip
considerations. In order to compile more separate documents you can add
them to the TARGETS variable in the Makefile.

## Modifying the Images

The sources for the images are stored in .seq files.
I used https://bramp.github.io/js-sequence-diagrams/ to turn them into
svgs that live in the images directory.

I have not found a good way to automate this yet.
