# countermitm
thoughts, plans on countering mitm-attacks on Autocrypt and other messaging systems

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
I used https://bramp.github.io/js-sequence-diagrams/ to turn them into
svgs that live in the images directory.

I have not found a good way to automate this yet.
