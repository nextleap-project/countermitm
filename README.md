# countermitm (reversing the panopticon) 

Evolving research on new protocols and approaches to counter
mitm-attacks on Autocrypt E-Mail encryption.

The work on the initial 0.9 release has been contributed 
by NEXTLEAP researchers, an project on privacy and decentralized messaging,
funded through the EU Horizon 2020 programme. 

During the remainder of 2018 we'd like to incorporate 
feedback, comments and contributions,
before publishing a "1.0" version of this paper. 

If you want to do Pull Requests please note that we are using 
[Semantic Linefeeds](http://rhodesmill.org/brandon/2012/one-sentence-per-line/).
It means that the source code of this document should be 
broken down to a "one-line-per-phrase" format, 
as to make reviewing diffs easier. 

## The document uses RestructuredText

While this readme uses Markdown syntax, the actual document
uses the richer RestructuredText format and in particular
the "Sphinx Document Generators".  You can probably get
around by just mimicking the syntax and "tricks" 
of the existing text.  You may also look at this 
[reStructuredText Primer](http://www.sphinx-doc.org/en/master/usage/restructuredtext/basics.html) for some basic editing advise.  


## Building the pdf

For the images we use inkscape to convert them from svg to pdf.

In order to create the documents you will need make, sphinx and inkscape installed
on your system. On a debian based system you can achieve this with

```sh
sudo apt install python-sphinx inkscape
```

From there on creating the pdf should be a matter of running

```sh
make images
make latexpdf
```

## Build Results

Once the build is completed there will be a CounterMitm.pdf file in the
build/latex directory. This contains the different approaches.

## Modifying the Images

The sources for the images are stored in .seq files.
We used https://bramp.github.io/js-sequence-diagrams/ to turn them into
svgs that live in the images directory.

We have not found a good way to automate this yet.
