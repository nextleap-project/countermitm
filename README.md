# countermitm
thoughts, plans on countering mitm-attacks on autocrypt and other messaging systems

## Building the pdf

The gossip.md file is written in markdown with some tex formulars
included. We use pandoc to convert it to latex and then pdflatex to turn
the latex into a pdf document.

In order to create the pdf you will need make, pandoc and pdflatex installed
on your system. On a debian based system you can achieve this with

```sh
sudo apt install pandoc texlive-latex-base texlive-fonts-recommended texlive-latex-extra
```

From there on creating the pdf should be a matter of running

```sh
make
```
