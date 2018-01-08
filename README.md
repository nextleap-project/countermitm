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

In order to create the pdf you will need make, pandoc and pdflatex installed
on your system. On a debian based system you can achieve this with

```sh
sudo apt install pandoc texlive-latex-base texlive-fonts-recommended texlive-latex-extra
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
