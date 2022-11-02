
<!-- README.md is generated from README.Rmd. Please edit that file -->

# impac

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/rdinnager/impac/workflows/R-CMD-check/badge.svg)](https://github.com/rdinnager/impac/actions)
<!-- badges: end -->

The goal of `{impac}` is to create packed image mosaics. The main
function `impac`, takes a set of images, or a function that generates
images and packs them into a larger image as tightly as possible,
scaling as necessary, using a greedy algorithm (so don’t expect it to be
fast\!). It is inspired by [this python
script](https://github.com/qnzhou/Mosaic%5D). The main upgrade in this
package is the ability to feed the algorithm a generator function, which
generates an images, as opposed to just a list of pre-existing images
(though it can do this too).

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("rdinnager/impac")
```

## Example

This document and hence the images below are regenerated once a day
automatically. No two will ever be alike.

First we load the packages we need for these examples:

``` r
library(impac)
library(Rvcg)
library(rgl)
library(rphylopic)
```

Next we create an R function to generate an image. In this case, we use
the package `rgl` to plot a simple 3d shape, chosen randomly from a set
of possibilities:

``` r

generate_platonic <- function(i, swidth = 200, sheight = 200, cols = rainbow(100)) {
  
  shape <- sample(c("sphere",
                    "spherical_cap",
                    "tetrahedron",
                    "dodecahedron",
                    "octahedron",
                    "icosahedron",
                    "hexahedron",
                    "cube",
                    "cone"),
                  1)
  
  mesh <- switch (shape,
    sphere = Rvcg::vcgSphere(),
    spherical_cap = Rvcg::vcgSphericalCap(),
    tetrahedron = Rvcg::vcgTetrahedron(),
    dodecahedron = Rvcg::vcgDodecahedron(),
    octahedron = Rvcg::vcgOctahedron(),
    icosahedron = Rvcg::vcgIcosahedron(),
    hexahedron = Rvcg::vcgHexahedron(),
    cube = Rvcg::vcgBox(),
    cone = Rvcg::vcgCone(2, 0, 6)
  )
  
  scales <- c(1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 3, 4)
  mesh <- rgl::scale3d(mesh, 
                       sample(scales, 1),
                       sample(scales, 1),
                       sample(scales, 1))
  
  mesh <- rgl::rotate3d(mesh, runif(1, 0, 2 * pi), 0, 0, 1)
  mesh <- rgl::rotate3d(mesh, runif(1, 0, 2 * pi), 0, 1, 0)
  mesh <- rgl::rotate3d(mesh, runif(1, 0, 2 * pi), 1, 0, 0)
  
  rgl::shade3d(mesh, col = sample(cols, 1),
               specular = "grey")
  
  png_file <- tempfile(fileext = ".png")
  rgl::snapshot3d(filename = png_file, width = swidth, height = sheight,
                  webshot = FALSE)
  rgl::close3d()
  
  im2 <- imager::load.image(png_file)
  im <- imager::imfill(swidth, sheight, val = c(0, 0, 0, 1))
  im[ , , , 1:3] <- im2 
  im[imager::R(im) == 1 & imager::G(im) == 1 & imager::B(im) == 1] <- 0
  
  im  
 
}
```

Now we feed our function to the `impac()` function, which packs the
generated images onto a canvas:

``` r
shapes <- impac(generate_platonic, progress = FALSE, show_every = 0, bg = "white")
imager::save.image(shapes$image, "man/figures/R_gems.png")
```

![Pretty R gems - Packed images of 3d shapes drawn with
{rgl}](man/figures/R_gems.png)

Now let’s pack some Phylopic images\! These are silhouettes of organisms
from the [Phylopic](http://phylopic.org/) project. We will use the
`rphylopic` package to grab a random Phylopic image for packing:

``` r
all_images <- rphylopic::image_list(1, 10000)
all_images <- unlist(all_images)
get_phylopic <- function(i, max_size = 400, isize = 1024) {
  fail <- TRUE
  while(fail) {
    uuid <- sample(all_images, 1)
    pp <- try(rphylopic::image_data(uuid, isize), silent = TRUE)
    if(!inherits(pp, "try-error")) {
      fail <- FALSE
    }
  }
  rot <- aperm(pp$uid, c(2, 1, 3))
  dims <- dim(rot)
  im <- imager::as.cimg(as.vector(rot), dim = c(dims[1], dims[2], 1, dims[3]))
  max_dim <- which.max(dims[1:2])
  other_dim <- (max_size / dims[max_dim]) * dims[1:2][-max_dim]
  new_size <- c(0, 0)
  new_size[max_dim] <- max_size
  new_size[-max_dim] <- other_dim
  im <- imager::resize(im, new_size[1], new_size[2], interpolation_type = 6)
  im <- imager::imchange(im, ~ . < 0, ~ 0)
  im <- imager::imchange(im, ~ . > 1, ~ 1)
  ## this adds custom metadata
  list(im, uuid = uuid)
}
```

Now we run `impac` on our phylopic generating function:

``` r
phylopics <- impac(get_phylopic, progress = FALSE, show_every = 0, bg = "white", min_scale = 0.01)
imager::save.image(phylopics$image, "man/figures/phylopic_a_pack.png")
```

![Packed images of organism silhouettes from
Phylopic](man/figures/phylopic_a_pack.png)

Now we extract the artists who made the above images using the uid of
image.

``` r
image_dat <- lapply(phylopics$meta$uuid, 
                    function(x) {Sys.sleep(2); rphylopic::image_get(x, options = c("credit"))$credit})
```

## Artists whose work is showcased:

Alex Slavenko, Kai R. Caspar, Chris huh, Margot Michaud, S.Martini,
Collin Gross, Jon Hill, Riccardo Percudani, Obsidian Soul (vectorized by
T. Michael Keesey), Steven Traver, Gabriela Palomo-Munoz, Erika
Schumacher, Juan Carlos Jerí, Gareth Monger, Nobu Tamura (vectorized by
T. Michael Keesey), Jagged Fang Designs, Ferran Sayol, Carlos
Cano-Barbacil, V. Deepak, Dmitry Bogdanov (vectorized by T. Michael
Keesey), Yan Wong, T. Michael Keesey, Hans Hillewaert (vectorized by T.
Michael Keesey), Shyamal, TaraTaylorDesign, Anthony Caravaggi,
Apokryltaros (vectorized by T. Michael Keesey), Matt Crook, Roger
Witter, vectorized by Zimices, Nobu Tamura (modified by T. Michael
Keesey), Henry Fairfield Osborn, vectorized by Zimices, Scott Hartman,
Duane Raver (vectorized by T. Michael Keesey), Maija Karala, Ignacio
Contreras, Jan Sevcik (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Michelle Site, Markus A. Grohme, Beth
Reinke, NASA, Chloé Schmidt, Andy Wilson, Mathew Wedel, Dianne Bray /
Museum Victoria (vectorized by T. Michael Keesey), Mattia Menchetti /
Yan Wong, Darren Naish (vectorized by T. Michael Keesey), Hans
Hillewaert, Tasman Dixon, Marmelad, Haplochromis (vectorized by T.
Michael Keesey), Jakovche, Andrew A. Farke, Tony Ayling, Michael P.
Taylor, Jack Mayer Wood, Martin R. Smith, from photo by Jürgen Schoner,
Zimices, Emily Willoughby, Armin Reindl, Birgit Lang, Cesar Julian,
Julia B McHugh, Nobu Tamura, vectorized by Zimices, T. Michael Keesey
(after James & al.), Sarah Werning, Chuanixn Yu, Catherine Yasuda, Jose
Carlos Arenas-Monroy, M. A. Broussard, Mette Aumala, Jimmy Bernot,
Michael Scroggie, Rebecca Groom, Steven Coombs, Roberto Díaz Sibaja,
Terpsichores, Tracy A. Heath, Mali’o Kodis, photograph by Ching
(<http://www.flickr.com/photos/36302473@N03/>), Karla Martinez, Mathilde
Cordellier, Oscar Sanisidro, T. Michael Keesey (vector) and Stuart
Halliday (photograph), Philip Chalmers (vectorized by T. Michael
Keesey), Didier Descouens (vectorized by T. Michael Keesey), Ieuan
Jones, Jaime Chirinos (vectorized by T. Michael Keesey), Marie-Aimée
Allard, Peter Coxhead, Julien Louys, Scott Hartman (modified by T.
Michael Keesey), Jan A. Venter, Herbert H. T. Prins, David A. Balfour &
Rob Slotow (vectorized by T. Michael Keesey), Unknown (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Matt Martyniuk,
Ghedoghedo (vectorized by T. Michael Keesey), C. Camilo
Julián-Caballero, Kanchi Nanjo, Stanton F. Fink (vectorized by T.
Michael Keesey), Вальдимар (vectorized by T. Michael Keesey), CNZdenek,
Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja,
Amanda Katzer, Michael Day, T. Michael Keesey (vectorization) and
HuttyMcphoo (photography), Robbie N. Cada (vectorized by T. Michael
Keesey), FunkMonk, L. Shyamal, wsnaccad, Dean Schnabel, Dmitry Bogdanov
and FunkMonk (vectorized by T. Michael Keesey), Scarlet23 (vectorized by
T. Michael Keesey), Frank Denota, Alexander Schmidt-Lebuhn, Dmitry
Bogdanov, Andreas Preuss / marauder, Christoph Schomburg, Katie S.
Collins, Mali’o Kodis, photograph by Bruno Vellutini, Iain Reid, Mike
Keesey (vectorization) and Vaibhavcho (photography), Leann Biancani,
photo by Kenneth Clifton, Jessica Anne Miller, Kimberly Haddrell, Scott
D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine
A. Forster, Joshua A. Smith, Alan L. Titus, Scott Reid, Fernando Campos
De Domenico, Fernando Carezzano, Lisa M. “Pixxl” (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Renata F.
Martins, Chase Brownstein, Nick Schooler, xgirouxb, Ludwik Gąsiorowski,
Qiang Ou, Sherman F. Denton via rawpixel.com (illustration) and Timothy
J. Bartley (silhouette), A. H. Baldwin (vectorized by T. Michael
Keesey), Liftarn, Rene Martin, Rebecca Groom (Based on Photo by Andreas
Trepte), Mathew Stewart, Alan Manson (photo), John E. McCormack, Michael
G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn,
Robb T. Brumfield & T. Michael Keesey, Cristian Osorio & Paula Carrera,
Proyecto Carnivoros Australes (www.carnivorosaustrales.org), Milton Tan,
Joanna Wolfe, Pete Buchholz, Jordan Mallon (vectorized by T. Michael
Keesey), david maas / dave hone, Mike Hanson, Cyril Matthey-Doret,
adapted from Bernard Chaubet, Christine Axon, 于川云, Tyler McCraney,
Sergio A. Muñoz-Gómez, Maxwell Lefroy (vectorized by T. Michael Keesey),
Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall, Noah Schlottman,
photo by Carlos Sánchez-Ortiz, Henry Lydecker, Saguaro Pictures (source
photo) and T. Michael Keesey, Julio Garza, Noah Schlottman, photo by
Casey Dunn, Matt Dempsey, T. Michael Keesey (after A. Y. Ivantsov),
Jaime Headden, Jake Warner, Joris van der Ham (vectorized by T. Michael
Keesey), Gabriele Midolo, Kamil S. Jaron, Melissa Broussard, G. M.
Woodward, Andrew Farke and Joseph Sertich, Yan Wong from wikipedia
drawing (PD: Pearson Scott Foresman), Harold N Eyster, Original scheme
by ‘Haplochromis’, vectorized by Roberto Díaz Sibaja,
SauropodomorphMonarch, H. F. O. March (vectorized by T. Michael Keesey),
Audrey Ely, Tony Ayling (vectorized by T. Michael Keesey), Nobu Tamura
(vectorized by A. Verrière), Farelli (photo), John E. McCormack, Michael
G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn,
Robb T. Brumfield & T. Michael Keesey, Maxime Dahirel, Lukas Panzarin,
Mali’o Kodis, image from the “Proceedings of the Zoological Society of
London”, Walter Vladimir

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                          |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    192.638887 |    236.596428 | Alex Slavenko                                                                                                                                                   |
|   2 |    438.813402 |    362.989814 | Kai R. Caspar                                                                                                                                                   |
|   3 |    555.054706 |     75.230842 | Chris huh                                                                                                                                                       |
|   4 |    174.807896 |    677.335270 | Margot Michaud                                                                                                                                                  |
|   5 |    505.684062 |    695.927526 | S.Martini                                                                                                                                                       |
|   6 |    342.363860 |    148.022931 | Collin Gross                                                                                                                                                    |
|   7 |    696.412482 |    262.469701 | Jon Hill                                                                                                                                                        |
|   8 |    304.417383 |    618.411784 | Chris huh                                                                                                                                                       |
|   9 |    677.129400 |    676.739699 | Chris huh                                                                                                                                                       |
|  10 |    279.911103 |    420.289339 | Riccardo Percudani                                                                                                                                              |
|  11 |    155.215936 |    611.791411 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                 |
|  12 |    408.783054 |    539.641460 | Steven Traver                                                                                                                                                   |
|  13 |    765.573486 |    369.157475 | Gabriela Palomo-Munoz                                                                                                                                           |
|  14 |    707.097137 |     83.672886 | Erika Schumacher                                                                                                                                                |
|  15 |    793.833925 |    127.894504 | Juan Carlos Jerí                                                                                                                                                |
|  16 |    152.908476 |    345.361565 | Chris huh                                                                                                                                                       |
|  17 |    259.441208 |    760.581174 | Gareth Monger                                                                                                                                                   |
|  18 |    614.833847 |    574.293611 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
|  19 |    516.830155 |    533.091054 | NA                                                                                                                                                              |
|  20 |    194.922097 |    136.933100 | Jagged Fang Designs                                                                                                                                             |
|  21 |    223.566338 |    519.883363 | Ferran Sayol                                                                                                                                                    |
|  22 |    114.416717 |    422.001153 | Carlos Cano-Barbacil                                                                                                                                            |
|  23 |     98.633776 |    504.506688 | Gareth Monger                                                                                                                                                   |
|  24 |    379.696998 |    716.924804 | V. Deepak                                                                                                                                                       |
|  25 |    725.808417 |    595.861504 | NA                                                                                                                                                              |
|  26 |    135.467756 |    313.334077 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
|  27 |    950.972724 |    646.831765 | Margot Michaud                                                                                                                                                  |
|  28 |    799.666924 |    474.255175 | Yan Wong                                                                                                                                                        |
|  29 |    766.161043 |    702.409912 | T. Michael Keesey                                                                                                                                               |
|  30 |     89.480566 |    196.761397 | Margot Michaud                                                                                                                                                  |
|  31 |    884.964445 |    292.808221 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                               |
|  32 |    289.229509 |    292.982918 | Steven Traver                                                                                                                                                   |
|  33 |    614.954941 |    197.746498 | T. Michael Keesey                                                                                                                                               |
|  34 |    565.653296 |    408.090108 | Shyamal                                                                                                                                                         |
|  35 |    527.751640 |    244.437597 | NA                                                                                                                                                              |
|  36 |    627.428570 |    489.306123 | T. Michael Keesey                                                                                                                                               |
|  37 |    962.289474 |    250.287078 | TaraTaylorDesign                                                                                                                                                |
|  38 |     81.449871 |    125.053781 | Anthony Caravaggi                                                                                                                                               |
|  39 |    697.195918 |    508.890501 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                  |
|  40 |    461.193689 |    317.545880 | Erika Schumacher                                                                                                                                                |
|  41 |    948.402789 |    507.136677 | Matt Crook                                                                                                                                                      |
|  42 |    877.570948 |    430.216422 | Roger Witter, vectorized by Zimices                                                                                                                             |
|  43 |    918.279099 |     74.907628 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                     |
|  44 |    919.214396 |    746.804514 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                   |
|  45 |    148.056148 |    561.017644 | Scott Hartman                                                                                                                                                   |
|  46 |    215.427862 |     57.286033 | Margot Michaud                                                                                                                                                  |
|  47 |    587.838422 |    359.141371 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                   |
|  48 |    931.179444 |    156.289042 | Scott Hartman                                                                                                                                                   |
|  49 |    874.317642 |    574.334322 | Maija Karala                                                                                                                                                    |
|  50 |     61.782069 |    725.602826 | Ignacio Contreras                                                                                                                                               |
|  51 |    160.098851 |    745.896443 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey      |
|  52 |    417.984350 |    415.716682 | Jagged Fang Designs                                                                                                                                             |
|  53 |    444.070303 |     52.754555 | Michelle Site                                                                                                                                                   |
|  54 |    456.933307 |    267.426102 | Jagged Fang Designs                                                                                                                                             |
|  55 |    814.348754 |     29.985719 | Markus A. Grohme                                                                                                                                                |
|  56 |    111.560920 |    292.022451 | Beth Reinke                                                                                                                                                     |
|  57 |    942.027419 |    411.769662 | NASA                                                                                                                                                            |
|  58 |    533.750833 |     29.491884 | Jagged Fang Designs                                                                                                                                             |
|  59 |    188.950493 |    180.587670 | Chloé Schmidt                                                                                                                                                   |
|  60 |    641.108442 |    740.552902 | Andy Wilson                                                                                                                                                     |
|  61 |    487.153054 |    638.024803 | Markus A. Grohme                                                                                                                                                |
|  62 |    283.759044 |     31.696594 | Mathew Wedel                                                                                                                                                    |
|  63 |     79.750883 |    369.848257 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                 |
|  64 |    575.341258 |    290.519936 | Gareth Monger                                                                                                                                                   |
|  65 |    502.579893 |    117.172111 | Mattia Menchetti / Yan Wong                                                                                                                                     |
|  66 |    640.029614 |    634.144680 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                  |
|  67 |    122.283706 |     33.436510 | Hans Hillewaert                                                                                                                                                 |
|  68 |     61.760290 |    267.143874 | Tasman Dixon                                                                                                                                                    |
|  69 |    610.538836 |    148.281649 | Marmelad                                                                                                                                                        |
|  70 |    292.128666 |    666.194841 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
|  71 |    778.974880 |    276.916488 | Michelle Site                                                                                                                                                   |
|  72 |    884.992658 |    705.100275 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                  |
|  73 |    743.132373 |    554.655982 | Jagged Fang Designs                                                                                                                                             |
|  74 |    732.969234 |    462.496306 | Jakovche                                                                                                                                                        |
|  75 |    497.735873 |    166.388789 | Yan Wong                                                                                                                                                        |
|  76 |    299.472453 |    580.482571 | Scott Hartman                                                                                                                                                   |
|  77 |    613.917178 |     34.466789 | Tasman Dixon                                                                                                                                                    |
|  78 |    514.551784 |    768.418486 | Jagged Fang Designs                                                                                                                                             |
|  79 |    309.920672 |    226.820592 | Markus A. Grohme                                                                                                                                                |
|  80 |    538.687764 |    437.650307 | Andrew A. Farke                                                                                                                                                 |
|  81 |    643.915368 |    346.748624 | Yan Wong                                                                                                                                                        |
|  82 |    937.222972 |     23.827386 | Tony Ayling                                                                                                                                                     |
|  83 |    837.539844 |    777.017311 | Michael P. Taylor                                                                                                                                               |
|  84 |    322.288203 |    532.726737 | Jack Mayer Wood                                                                                                                                                 |
|  85 |     95.510994 |    694.333225 | Margot Michaud                                                                                                                                                  |
|  86 |    801.607883 |    305.214507 | Martin R. Smith, from photo by Jürgen Schoner                                                                                                                   |
|  87 |    949.861864 |    125.010795 | Jagged Fang Designs                                                                                                                                             |
|  88 |     38.822567 |     56.760949 | Zimices                                                                                                                                                         |
|  89 |    971.812115 |    553.206446 | Emily Willoughby                                                                                                                                                |
|  90 |    328.624387 |    389.954602 | Chris huh                                                                                                                                                       |
|  91 |    143.756470 |    394.561753 | NA                                                                                                                                                              |
|  92 |    669.605225 |    322.242382 | Armin Reindl                                                                                                                                                    |
|  93 |    274.102336 |    700.871570 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
|  94 |     32.669753 |    574.526144 | Birgit Lang                                                                                                                                                     |
|  95 |    615.964876 |    698.951939 | Cesar Julian                                                                                                                                                    |
|  96 |    377.098604 |      9.732970 | Julia B McHugh                                                                                                                                                  |
|  97 |     43.481286 |    783.295085 | Nobu Tamura, vectorized by Zimices                                                                                                                              |
|  98 |    368.865467 |    273.221356 | T. Michael Keesey (after James & al.)                                                                                                                           |
|  99 |    837.306338 |    653.995998 | Zimices                                                                                                                                                         |
| 100 |    655.820275 |    415.176002 | Gareth Monger                                                                                                                                                   |
| 101 |    221.991177 |    366.273540 | Sarah Werning                                                                                                                                                   |
| 102 |     55.135552 |    658.233071 | Scott Hartman                                                                                                                                                   |
| 103 |     66.700648 |    474.785667 | NA                                                                                                                                                              |
| 104 |    202.021139 |    278.599980 | Emily Willoughby                                                                                                                                                |
| 105 |    856.273550 |    194.075881 | Chuanixn Yu                                                                                                                                                     |
| 106 |    450.569787 |    778.565185 | Jagged Fang Designs                                                                                                                                             |
| 107 |    314.105430 |    722.255828 | Catherine Yasuda                                                                                                                                                |
| 108 |     19.270865 |    499.420361 | Jose Carlos Arenas-Monroy                                                                                                                                       |
| 109 |     81.892644 |    601.548876 | M. A. Broussard                                                                                                                                                 |
| 110 |    496.877116 |    476.244286 | Mette Aumala                                                                                                                                                    |
| 111 |    730.460738 |    428.252746 | Jimmy Bernot                                                                                                                                                    |
| 112 |    459.883937 |    595.271952 | Matt Crook                                                                                                                                                      |
| 113 |    423.095630 |    682.594338 | NA                                                                                                                                                              |
| 114 |    977.139936 |    183.356891 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 115 |    719.432968 |    648.879001 | T. Michael Keesey                                                                                                                                               |
| 116 |     31.604194 |    317.021082 | Ferran Sayol                                                                                                                                                    |
| 117 |    442.613142 |    539.506189 | Michael Scroggie                                                                                                                                                |
| 118 |    790.670831 |    511.956795 | Rebecca Groom                                                                                                                                                   |
| 119 |    383.272436 |    239.495327 | Ferran Sayol                                                                                                                                                    |
| 120 |    730.095883 |    123.020970 | Steven Coombs                                                                                                                                                   |
| 121 |    636.721342 |    535.416627 | Margot Michaud                                                                                                                                                  |
| 122 |   1007.955179 |     69.791170 | Roberto Díaz Sibaja                                                                                                                                             |
| 123 |    206.532913 |    328.321989 | Mette Aumala                                                                                                                                                    |
| 124 |    677.736314 |     18.784864 | Emily Willoughby                                                                                                                                                |
| 125 |     84.406911 |    340.347932 | Gareth Monger                                                                                                                                                   |
| 126 |    999.319519 |    110.468259 | Margot Michaud                                                                                                                                                  |
| 127 |    152.899385 |    107.162364 | Terpsichores                                                                                                                                                    |
| 128 |     33.453829 |    390.979530 | Zimices                                                                                                                                                         |
| 129 |    847.759051 |    755.892731 | Tracy A. Heath                                                                                                                                                  |
| 130 |    750.151686 |    655.443030 | Mali’o Kodis, photograph by Ching (<http://www.flickr.com/photos/36302473@N03/>)                                                                                |
| 131 |    344.905956 |    243.117781 | Nobu Tamura, vectorized by Zimices                                                                                                                              |
| 132 |    570.031793 |    609.358652 | Steven Traver                                                                                                                                                   |
| 133 |    592.480565 |    661.595172 | Karla Martinez                                                                                                                                                  |
| 134 |    819.162954 |    738.719006 | Scott Hartman                                                                                                                                                   |
| 135 |    319.558753 |    490.796742 | Ignacio Contreras                                                                                                                                               |
| 136 |    406.998278 |    261.178327 | Terpsichores                                                                                                                                                    |
| 137 |    448.560823 |     16.055696 | Steven Traver                                                                                                                                                   |
| 138 |    912.501903 |    791.171680 | Gareth Monger                                                                                                                                                   |
| 139 |    645.060663 |    194.249106 | Mathilde Cordellier                                                                                                                                             |
| 140 |    464.762715 |     32.849649 | Zimices                                                                                                                                                         |
| 141 |    329.898974 |    703.858344 | Oscar Sanisidro                                                                                                                                                 |
| 142 |    548.146663 |    328.820268 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 143 |    301.098420 |    346.829188 | Steven Traver                                                                                                                                                   |
| 144 |    345.149665 |     30.330102 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                     |
| 145 |    937.594847 |    279.077005 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                               |
| 146 |    479.357072 |    268.010632 | NA                                                                                                                                                              |
| 147 |    344.832822 |    552.619073 | NA                                                                                                                                                              |
| 148 |    990.985771 |    729.037067 | Margot Michaud                                                                                                                                                  |
| 149 |    991.722738 |    780.418234 | Matt Crook                                                                                                                                                      |
| 150 |    332.591732 |    333.327651 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                              |
| 151 |     16.350266 |    188.519921 | Shyamal                                                                                                                                                         |
| 152 |    820.326149 |    557.777174 | Sarah Werning                                                                                                                                                   |
| 153 |    746.214335 |    777.216056 | Steven Traver                                                                                                                                                   |
| 154 |    496.587464 |    205.660487 | Margot Michaud                                                                                                                                                  |
| 155 |     63.571463 |     92.084525 | Ieuan Jones                                                                                                                                                     |
| 156 |    211.911479 |    103.684487 | Zimices                                                                                                                                                         |
| 157 |     81.569263 |    635.181432 | Ferran Sayol                                                                                                                                                    |
| 158 |    993.978994 |    425.191263 | T. Michael Keesey                                                                                                                                               |
| 159 |     14.771710 |    227.238237 | Birgit Lang                                                                                                                                                     |
| 160 |    545.980066 |    795.852565 | NA                                                                                                                                                              |
| 161 |    529.071546 |    206.936092 | Andy Wilson                                                                                                                                                     |
| 162 |    569.528010 |    135.916765 | Matt Crook                                                                                                                                                      |
| 163 |    198.659491 |    390.932422 | Gareth Monger                                                                                                                                                   |
| 164 |    835.293078 |    229.213864 | Steven Traver                                                                                                                                                   |
| 165 |    211.737282 |    608.568834 | Gareth Monger                                                                                                                                                   |
| 166 |     44.982638 |    632.210562 | Margot Michaud                                                                                                                                                  |
| 167 |    956.506808 |    597.403881 | Margot Michaud                                                                                                                                                  |
| 168 |    707.455578 |    782.018736 | Jaime Chirinos (vectorized by T. Michael Keesey)                                                                                                                |
| 169 |    936.223961 |    326.253827 | Marie-Aimée Allard                                                                                                                                              |
| 170 |    622.457134 |    619.520447 | Chris huh                                                                                                                                                       |
| 171 |    359.389779 |    470.304837 | Tasman Dixon                                                                                                                                                    |
| 172 |    330.651362 |    374.999667 | Matt Crook                                                                                                                                                      |
| 173 |    721.310146 |    315.275643 | Anthony Caravaggi                                                                                                                                               |
| 174 |   1012.116108 |    310.201352 | Andy Wilson                                                                                                                                                     |
| 175 |    857.128015 |    737.976428 | Peter Coxhead                                                                                                                                                   |
| 176 |    484.665418 |     49.373312 | Erika Schumacher                                                                                                                                                |
| 177 |    249.082259 |    604.602867 | Julien Louys                                                                                                                                                    |
| 178 |    462.028384 |    748.374139 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                   |
| 179 |    999.293680 |    337.815416 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                             |
| 180 |     49.703968 |     24.494107 | NA                                                                                                                                                              |
| 181 |    297.877339 |    503.774616 | Steven Traver                                                                                                                                                   |
| 182 |    760.620961 |    634.551349 | Gareth Monger                                                                                                                                                   |
| 183 |    694.280901 |    304.173576 | Tasman Dixon                                                                                                                                                    |
| 184 |    822.690882 |    614.793448 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 185 |     72.386853 |    540.518721 | Margot Michaud                                                                                                                                                  |
| 186 |    939.938953 |    307.022433 | Jagged Fang Designs                                                                                                                                             |
| 187 |    691.043747 |    160.012491 | Matt Martyniuk                                                                                                                                                  |
| 188 |    279.011871 |    199.291608 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                    |
| 189 |    648.599905 |    791.735289 | C. Camilo Julián-Caballero                                                                                                                                      |
| 190 |    540.895716 |    615.787006 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 191 |    190.025572 |    256.416427 | Kanchi Nanjo                                                                                                                                                    |
| 192 |    799.376393 |    216.655228 | Jagged Fang Designs                                                                                                                                             |
| 193 |    182.459787 |    492.081822 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                               |
| 194 |    437.740065 |    746.469406 | Вальдимар (vectorized by T. Michael Keesey)                                                                                                                     |
| 195 |     22.220448 |    526.905355 | CNZdenek                                                                                                                                                        |
| 196 |    151.324128 |     63.025017 | Tasman Dixon                                                                                                                                                    |
| 197 |    518.480090 |     65.392964 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                          |
| 198 |    141.882319 |    128.668458 | Amanda Katzer                                                                                                                                                   |
| 199 |    439.371445 |    701.602225 | Michael Day                                                                                                                                                     |
| 200 |     55.984818 |    105.331705 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                 |
| 201 |    787.666234 |    325.243262 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                |
| 202 |    578.105634 |    691.606240 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                    |
| 203 |    836.667787 |    513.966928 | Collin Gross                                                                                                                                                    |
| 204 |    193.278744 |    545.425466 | FunkMonk                                                                                                                                                        |
| 205 |    703.213816 |    707.226145 | L. Shyamal                                                                                                                                                      |
| 206 |    130.646656 |    234.177582 | Zimices                                                                                                                                                         |
| 207 |    492.616854 |    604.569726 | wsnaccad                                                                                                                                                        |
| 208 |    637.277509 |    660.163485 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 209 |    208.303123 |    377.807485 | Dean Schnabel                                                                                                                                                   |
| 210 |    133.935723 |      6.563915 | Tasman Dixon                                                                                                                                                    |
| 211 |    460.567755 |    201.456043 | Matt Crook                                                                                                                                                      |
| 212 |    749.396831 |    220.367246 | T. Michael Keesey (after James & al.)                                                                                                                           |
| 213 |    596.012386 |    146.838771 | Yan Wong                                                                                                                                                        |
| 214 |    560.721081 |    472.386703 | Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey)                                                                                                  |
| 215 |    344.272560 |    486.770585 | Michelle Site                                                                                                                                                   |
| 216 |    406.277569 |    291.438035 | Birgit Lang                                                                                                                                                     |
| 217 |    271.170999 |     63.676581 | Jagged Fang Designs                                                                                                                                             |
| 218 |    678.643536 |    176.277634 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                     |
| 219 |   1000.449341 |    145.367367 | Zimices                                                                                                                                                         |
| 220 |    994.127026 |     11.976831 | Frank Denota                                                                                                                                                    |
| 221 |    956.117658 |      2.717950 | NA                                                                                                                                                              |
| 222 |    133.955895 |    481.559320 | Alexander Schmidt-Lebuhn                                                                                                                                        |
| 223 |    466.810208 |    458.048160 | Markus A. Grohme                                                                                                                                                |
| 224 |   1000.553335 |    380.618608 | Jose Carlos Arenas-Monroy                                                                                                                                       |
| 225 |     30.605569 |    116.289720 | Gabriela Palomo-Munoz                                                                                                                                           |
| 226 |     36.380724 |    670.967353 | Jagged Fang Designs                                                                                                                                             |
| 227 |    319.863552 |    715.156576 | Dmitry Bogdanov                                                                                                                                                 |
| 228 |    951.298582 |    623.201215 | CNZdenek                                                                                                                                                        |
| 229 |    892.589559 |    679.473621 | Dean Schnabel                                                                                                                                                   |
| 230 |    526.013473 |    469.638076 | NA                                                                                                                                                              |
| 231 |    759.037270 |    203.032310 | Tasman Dixon                                                                                                                                                    |
| 232 |     22.733407 |     91.173603 | Gabriela Palomo-Munoz                                                                                                                                           |
| 233 |    469.456949 |    552.615063 | Andreas Preuss / marauder                                                                                                                                       |
| 234 |    209.094363 |    298.511352 | Andy Wilson                                                                                                                                                     |
| 235 |    141.526631 |    787.332093 | Steven Traver                                                                                                                                                   |
| 236 |    687.077751 |    143.216300 | Christoph Schomburg                                                                                                                                             |
| 237 |    660.993162 |    391.258058 | Matt Crook                                                                                                                                                      |
| 238 |    166.570616 |    374.074877 | Margot Michaud                                                                                                                                                  |
| 239 |    921.690457 |    572.355631 | T. Michael Keesey                                                                                                                                               |
| 240 |    688.098296 |    192.444068 | NA                                                                                                                                                              |
| 241 |    768.783772 |    513.020356 | Dean Schnabel                                                                                                                                                   |
| 242 |    715.421542 |     26.726750 | Matt Crook                                                                                                                                                      |
| 243 |    435.323199 |    568.514255 | Katie S. Collins                                                                                                                                                |
| 244 |    777.542370 |     64.205748 | Michael Day                                                                                                                                                     |
| 245 |    878.472930 |    500.876448 | Ferran Sayol                                                                                                                                                    |
| 246 |     11.312883 |    615.635179 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                     |
| 247 |   1010.594507 |    643.062509 | NA                                                                                                                                                              |
| 248 |    617.221519 |    611.997902 | Iain Reid                                                                                                                                                       |
| 249 |    741.594884 |    197.291004 | Markus A. Grohme                                                                                                                                                |
| 250 |    440.255954 |    671.437999 | Mike Keesey (vectorization) and Vaibhavcho (photography)                                                                                                        |
| 251 |    694.448992 |    396.514341 | Gareth Monger                                                                                                                                                   |
| 252 |    368.062780 |    312.066102 | Leann Biancani, photo by Kenneth Clifton                                                                                                                        |
| 253 |    159.959945 |    229.350657 | Amanda Katzer                                                                                                                                                   |
| 254 |    882.408121 |    651.160933 | NA                                                                                                                                                              |
| 255 |     21.183426 |    467.229491 | NA                                                                                                                                                              |
| 256 |    708.504651 |    217.163277 | Matt Crook                                                                                                                                                      |
| 257 |    663.292787 |    574.912050 | Steven Traver                                                                                                                                                   |
| 258 |    767.092798 |    108.085543 | Jessica Anne Miller                                                                                                                                             |
| 259 |    434.514494 |    593.355639 | Andy Wilson                                                                                                                                                     |
| 260 |    179.593821 |    178.503486 | Tasman Dixon                                                                                                                                                    |
| 261 |    795.634581 |    549.411222 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 262 |    593.587410 |    503.888808 | Yan Wong                                                                                                                                                        |
| 263 |    620.153543 |    715.271504 | Chris huh                                                                                                                                                       |
| 264 |    804.761857 |    599.683377 | Zimices                                                                                                                                                         |
| 265 |    591.809173 |    162.899303 | Sarah Werning                                                                                                                                                   |
| 266 |    196.386134 |    460.123654 | T. Michael Keesey                                                                                                                                               |
| 267 |    969.635527 |    304.691132 | Kimberly Haddrell                                                                                                                                               |
| 268 |    503.944004 |    711.014823 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                        |
| 269 |    894.071818 |      5.668773 | Gareth Monger                                                                                                                                                   |
| 270 |    380.277452 |    295.137247 | Ferran Sayol                                                                                                                                                    |
| 271 |    822.559281 |    577.204364 | Sarah Werning                                                                                                                                                   |
| 272 |    553.840325 |    568.339644 | Markus A. Grohme                                                                                                                                                |
| 273 |    726.625089 |    109.101552 | Margot Michaud                                                                                                                                                  |
| 274 |    677.570136 |    782.034252 | Ferran Sayol                                                                                                                                                    |
| 275 |    287.653996 |    484.572820 | Chloé Schmidt                                                                                                                                                   |
| 276 |    203.903014 |     21.306060 | Scott Reid                                                                                                                                                      |
| 277 |    622.020485 |    102.448274 | Dean Schnabel                                                                                                                                                   |
| 278 |    606.588979 |    328.410827 | Steven Traver                                                                                                                                                   |
| 279 |    351.968875 |    650.374119 | Fernando Campos De Domenico                                                                                                                                     |
| 280 |    560.362810 |    484.391981 | Fernando Carezzano                                                                                                                                              |
| 281 |    528.494894 |    107.148542 | Margot Michaud                                                                                                                                                  |
| 282 |    311.070236 |    461.691766 | Erika Schumacher                                                                                                                                                |
| 283 |    115.958404 |    245.751098 | Carlos Cano-Barbacil                                                                                                                                            |
| 284 |    639.814854 |    271.568355 | Ignacio Contreras                                                                                                                                               |
| 285 |    267.134633 |    440.183456 | Zimices                                                                                                                                                         |
| 286 |    364.608309 |    701.944975 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 287 |    820.096594 |    531.495161 | Renata F. Martins                                                                                                                                               |
| 288 |    314.282589 |     66.962940 | Chase Brownstein                                                                                                                                                |
| 289 |    613.508505 |    388.554470 | Sarah Werning                                                                                                                                                   |
| 290 |    775.566437 |     10.636297 | Gabriela Palomo-Munoz                                                                                                                                           |
| 291 |    996.596809 |    166.806571 | Ferran Sayol                                                                                                                                                    |
| 292 |    571.165396 |    580.838382 | Michael Scroggie                                                                                                                                                |
| 293 |     15.330763 |     31.237814 | Nick Schooler                                                                                                                                                   |
| 294 |    989.170370 |    359.536772 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 295 |     89.072663 |    743.404966 | xgirouxb                                                                                                                                                        |
| 296 |    164.414533 |    477.365599 | Ludwik Gąsiorowski                                                                                                                                              |
| 297 |     33.105153 |    350.952860 | Margot Michaud                                                                                                                                                  |
| 298 |    972.984408 |    615.081330 | Maija Karala                                                                                                                                                    |
| 299 |     17.704339 |    765.405869 | Maija Karala                                                                                                                                                    |
| 300 |    178.667372 |     93.817188 | Michelle Site                                                                                                                                                   |
| 301 |    816.300630 |    187.099325 | Beth Reinke                                                                                                                                                     |
| 302 |    481.983048 |    572.000959 | Qiang Ou                                                                                                                                                        |
| 303 |    750.781356 |    534.179622 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                           |
| 304 |    340.678889 |    218.872355 | Michael P. Taylor                                                                                                                                               |
| 305 |    293.856372 |    211.528287 | NA                                                                                                                                                              |
| 306 |    972.263213 |    333.388760 | NA                                                                                                                                                              |
| 307 |    565.050530 |    721.587305 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                 |
| 308 |    613.503207 |    668.987577 | NA                                                                                                                                                              |
| 309 |    219.887627 |    561.838765 | Liftarn                                                                                                                                                         |
| 310 |    991.050580 |     32.766807 | Rene Martin                                                                                                                                                     |
| 311 |    233.183814 |    229.500622 | Scott Hartman                                                                                                                                                   |
| 312 |    281.050200 |    538.461559 | Tasman Dixon                                                                                                                                                    |
| 313 |    700.655940 |    734.853600 | Gareth Monger                                                                                                                                                   |
| 314 |    249.166271 |    553.338261 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 315 |    762.665160 |    424.308013 | Jose Carlos Arenas-Monroy                                                                                                                                       |
| 316 |    349.971496 |    453.641029 | Jose Carlos Arenas-Monroy                                                                                                                                       |
| 317 |    579.566964 |    762.659214 | Rebecca Groom (Based on Photo by Andreas Trepte)                                                                                                                |
| 318 |      6.540794 |    142.258979 | Dean Schnabel                                                                                                                                                   |
| 319 |    732.264919 |    622.213165 | Gareth Monger                                                                                                                                                   |
| 320 |    690.176727 |    478.073396 | Gareth Monger                                                                                                                                                   |
| 321 |    491.013014 |    182.917488 | Gareth Monger                                                                                                                                                   |
| 322 |    338.090417 |    671.069752 | Jagged Fang Designs                                                                                                                                             |
| 323 |    410.024442 |    786.661429 | Margot Michaud                                                                                                                                                  |
| 324 |    122.222988 |    522.862394 | Jack Mayer Wood                                                                                                                                                 |
| 325 |    548.279404 |    746.859070 | Chris huh                                                                                                                                                       |
| 326 |     81.744636 |    769.469302 | Jagged Fang Designs                                                                                                                                             |
| 327 |    135.115138 |    731.875468 | Birgit Lang                                                                                                                                                     |
| 328 |    830.656675 |      8.786432 | NA                                                                                                                                                              |
| 329 |    616.389944 |     15.668627 | Iain Reid                                                                                                                                                       |
| 330 |    361.295020 |     54.131486 | Mathew Stewart                                                                                                                                                  |
| 331 |    234.340553 |    263.675066 | Jagged Fang Designs                                                                                                                                             |
| 332 |     31.349659 |    296.357137 | Andrew A. Farke                                                                                                                                                 |
| 333 |     20.300057 |    638.876217 | Gareth Monger                                                                                                                                                   |
| 334 |    576.577095 |    734.601876 | Markus A. Grohme                                                                                                                                                |
| 335 |    114.602117 |    597.809783 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey     |
| 336 |    320.670729 |      9.848705 | Zimices                                                                                                                                                         |
| 337 |    321.921970 |    594.170824 | Jack Mayer Wood                                                                                                                                                 |
| 338 |    480.057618 |    416.142828 | Gareth Monger                                                                                                                                                   |
| 339 |    607.697752 |    303.984675 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                    |
| 340 |    887.177953 |    364.279389 | Markus A. Grohme                                                                                                                                                |
| 341 |    521.379007 |    135.222112 | Gareth Monger                                                                                                                                                   |
| 342 |    341.383336 |    690.695297 | Gareth Monger                                                                                                                                                   |
| 343 |    233.489880 |    583.573890 | Milton Tan                                                                                                                                                      |
| 344 |    965.557493 |     93.690222 | Alexander Schmidt-Lebuhn                                                                                                                                        |
| 345 |    213.620509 |    314.023939 | Margot Michaud                                                                                                                                                  |
| 346 |    851.724201 |    215.973917 | Margot Michaud                                                                                                                                                  |
| 347 |     26.552986 |    607.673539 | Margot Michaud                                                                                                                                                  |
| 348 |    625.490835 |     86.422896 | Margot Michaud                                                                                                                                                  |
| 349 |    951.841479 |    345.695869 | Markus A. Grohme                                                                                                                                                |
| 350 |    974.300598 |    387.741179 | Ferran Sayol                                                                                                                                                    |
| 351 |    969.824796 |    271.812468 | Joanna Wolfe                                                                                                                                                    |
| 352 |    973.928368 |    164.619902 | Jagged Fang Designs                                                                                                                                             |
| 353 |    576.679253 |      7.560258 | Tasman Dixon                                                                                                                                                    |
| 354 |    695.671180 |    330.345334 | Pete Buchholz                                                                                                                                                   |
| 355 |    626.441328 |    429.356566 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                 |
| 356 |    563.380627 |    456.689009 | Scott Hartman                                                                                                                                                   |
| 357 |    839.160248 |    495.341624 | Gareth Monger                                                                                                                                                   |
| 358 |    221.243416 |    642.927076 | Tasman Dixon                                                                                                                                                    |
| 359 |    457.227667 |    397.504184 | Carlos Cano-Barbacil                                                                                                                                            |
| 360 |     18.462436 |    168.986907 | Dean Schnabel                                                                                                                                                   |
| 361 |    358.711556 |    256.901726 | NA                                                                                                                                                              |
| 362 |    806.815213 |    637.213957 | david maas / dave hone                                                                                                                                          |
| 363 |     95.644493 |    787.563683 | Margot Michaud                                                                                                                                                  |
| 364 |    572.124628 |     39.905639 | NA                                                                                                                                                              |
| 365 |    313.200646 |    753.331825 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                  |
| 366 |    923.901353 |    453.149041 | Emily Willoughby                                                                                                                                                |
| 367 |     65.849435 |    573.604330 | Mike Hanson                                                                                                                                                     |
| 368 |    540.944573 |     45.708018 | Cyril Matthey-Doret, adapted from Bernard Chaubet                                                                                                               |
| 369 |    294.142780 |    366.418742 | Margot Michaud                                                                                                                                                  |
| 370 |    829.909870 |    333.530016 | Zimices                                                                                                                                                         |
| 371 |    719.393208 |    274.633968 | Christine Axon                                                                                                                                                  |
| 372 |    784.847935 |    616.716621 | NA                                                                                                                                                              |
| 373 |    998.473764 |    754.155908 | 于川云                                                                                                                                                             |
| 374 |    873.032655 |    132.142882 | Tyler McCraney                                                                                                                                                  |
| 375 |    859.942386 |    508.171356 | Andy Wilson                                                                                                                                                     |
| 376 |    867.028999 |    237.060856 | Rebecca Groom                                                                                                                                                   |
| 377 |    426.123488 |      9.707520 | Scott Hartman                                                                                                                                                   |
| 378 |    707.106909 |    411.709706 | Sergio A. Muñoz-Gómez                                                                                                                                           |
| 379 |    755.621825 |     88.557619 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                |
| 380 |    494.889828 |    791.918666 | Chris huh                                                                                                                                                       |
| 381 |    577.387061 |    530.785420 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                           |
| 382 |    128.202418 |    460.521443 | Andrew A. Farke                                                                                                                                                 |
| 383 |    667.155314 |    544.928724 | Christoph Schomburg                                                                                                                                             |
| 384 |    648.608420 |    592.527772 | Zimices                                                                                                                                                         |
| 385 |    641.665113 |    248.930339 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                                  |
| 386 |    798.590590 |    408.424164 | Henry Lydecker                                                                                                                                                  |
| 387 |    532.661651 |    304.454390 | Zimices                                                                                                                                                         |
| 388 |   1010.105974 |    576.531884 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                           |
| 389 |     64.563799 |    618.498467 | Steven Traver                                                                                                                                                   |
| 390 |    954.447573 |    780.419388 | Julio Garza                                                                                                                                                     |
| 391 |    821.485017 |     56.976280 | Gabriela Palomo-Munoz                                                                                                                                           |
| 392 |    514.111307 |    348.045497 | Noah Schlottman, photo by Casey Dunn                                                                                                                            |
| 393 |    766.813492 |    542.373585 | Matt Dempsey                                                                                                                                                    |
| 394 |    847.691227 |    357.531879 | Ignacio Contreras                                                                                                                                               |
| 395 |    359.413300 |    788.433758 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                        |
| 396 |   1006.423309 |     57.600195 | Julio Garza                                                                                                                                                     |
| 397 |    718.467701 |    137.264813 | Maija Karala                                                                                                                                                    |
| 398 |    469.032402 |    139.197814 | Jaime Headden                                                                                                                                                   |
| 399 |    267.291023 |    355.125234 | Collin Gross                                                                                                                                                    |
| 400 |    442.472119 |    469.945049 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                   |
| 401 |    434.368746 |    212.138506 | Jake Warner                                                                                                                                                     |
| 402 |    214.718242 |    475.094116 | NA                                                                                                                                                              |
| 403 |    580.383745 |    103.460501 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                             |
| 404 |    571.376013 |    329.166891 | Zimices                                                                                                                                                         |
| 405 |    280.882553 |      5.791910 | Scott Hartman                                                                                                                                                   |
| 406 |    235.255698 |    121.280480 | Markus A. Grohme                                                                                                                                                |
| 407 |   1013.997512 |     35.888294 | Gabriele Midolo                                                                                                                                                 |
| 408 |    464.619245 |      6.463607 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 409 |    754.137788 |    176.862900 | Kamil S. Jaron                                                                                                                                                  |
| 410 |    259.385459 |    179.402393 | Andy Wilson                                                                                                                                                     |
| 411 |    567.061504 |    385.002385 | Chris huh                                                                                                                                                       |
| 412 |    920.925425 |    405.080402 | Melissa Broussard                                                                                                                                               |
| 413 |    857.201111 |    681.382242 | Ferran Sayol                                                                                                                                                    |
| 414 |    903.604651 |    375.336523 | G. M. Woodward                                                                                                                                                  |
| 415 |    820.816155 |    723.640499 | Henry Lydecker                                                                                                                                                  |
| 416 |    365.840508 |    326.880084 | Jagged Fang Designs                                                                                                                                             |
| 417 |    963.381207 |    287.265729 | Chris huh                                                                                                                                                       |
| 418 |    290.593455 |    559.428763 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                     |
| 419 |     67.115878 |    300.691180 | Rebecca Groom                                                                                                                                                   |
| 420 |    399.610100 |    651.234889 | Jagged Fang Designs                                                                                                                                             |
| 421 |    738.307219 |    631.878576 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 422 |    288.089038 |     87.145983 | Matt Crook                                                                                                                                                      |
| 423 |    789.907025 |     98.146694 | T. Michael Keesey                                                                                                                                               |
| 424 |    567.275546 |    647.915829 | Zimices                                                                                                                                                         |
| 425 |    128.667124 |    747.423357 | xgirouxb                                                                                                                                                        |
| 426 |    890.861481 |    112.828824 | Scott Hartman                                                                                                                                                   |
| 427 |    373.927475 |    443.307226 | Andrew Farke and Joseph Sertich                                                                                                                                 |
| 428 |    544.009509 |    776.876372 | Noah Schlottman, photo by Casey Dunn                                                                                                                            |
| 429 |    598.161638 |    786.301665 | Melissa Broussard                                                                                                                                               |
| 430 |    701.418621 |    754.820813 | Steven Traver                                                                                                                                                   |
| 431 |    799.202157 |    779.683921 | Gabriela Palomo-Munoz                                                                                                                                           |
| 432 |    473.831540 |    658.502181 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                    |
| 433 |    485.458236 |    392.809153 | Chris huh                                                                                                                                                       |
| 434 |    183.678356 |    162.897741 | Christine Axon                                                                                                                                                  |
| 435 |    636.238271 |    577.867079 | Scott Hartman                                                                                                                                                   |
| 436 |    521.556464 |    361.351291 | Harold N Eyster                                                                                                                                                 |
| 437 |    816.502518 |    754.514660 | Michelle Site                                                                                                                                                   |
| 438 |    406.475846 |    700.807220 | Original scheme by ‘Haplochromis’, vectorized by Roberto Díaz Sibaja                                                                                            |
| 439 |    576.953409 |    792.557828 | Gabriela Palomo-Munoz                                                                                                                                           |
| 440 |    857.379150 |    788.255116 | Sarah Werning                                                                                                                                                   |
| 441 |    732.062016 |    270.291752 | SauropodomorphMonarch                                                                                                                                           |
| 442 |    103.818149 |    575.307577 | T. Michael Keesey                                                                                                                                               |
| 443 |    490.592082 |    617.366879 | Gareth Monger                                                                                                                                                   |
| 444 |    407.437115 |    633.891339 | NA                                                                                                                                                              |
| 445 |    879.815932 |    224.974871 | Tasman Dixon                                                                                                                                                    |
| 446 |    990.227762 |     45.206330 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                |
| 447 |    213.995690 |    764.249943 | Audrey Ely                                                                                                                                                      |
| 448 |    250.668871 |     44.556857 | Scott Hartman                                                                                                                                                   |
| 449 |      3.922075 |    402.682471 | Gareth Monger                                                                                                                                                   |
| 450 |    288.041603 |     11.775600 | Chris huh                                                                                                                                                       |
| 451 |    100.331874 |    340.882693 | Margot Michaud                                                                                                                                                  |
| 452 |    174.531720 |    120.301575 | Gabriela Palomo-Munoz                                                                                                                                           |
| 453 |     22.178025 |    455.006227 | NA                                                                                                                                                              |
| 454 |    247.834084 |    489.766228 | xgirouxb                                                                                                                                                        |
| 455 |    719.649919 |      5.797145 | NA                                                                                                                                                              |
| 456 |    377.670245 |    221.003875 | Jack Mayer Wood                                                                                                                                                 |
| 457 |    671.660440 |    152.621398 | Jagged Fang Designs                                                                                                                                             |
| 458 |   1013.664308 |    683.357127 | NA                                                                                                                                                              |
| 459 |    545.609741 |    754.028740 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                               |
| 460 |    631.131422 |     66.087043 | Gabriela Palomo-Munoz                                                                                                                                           |
| 461 |    746.409183 |    234.409949 | Cesar Julian                                                                                                                                                    |
| 462 |    798.369823 |    580.528458 | Christine Axon                                                                                                                                                  |
| 463 |    572.623620 |    168.310520 | Jagged Fang Designs                                                                                                                                             |
| 464 |    859.268362 |    764.191330 | Margot Michaud                                                                                                                                                  |
| 465 |    873.847636 |     43.798858 | Matt Crook                                                                                                                                                      |
| 466 |    685.365220 |    652.666899 | Chris huh                                                                                                                                                       |
| 467 |     93.737549 |     75.271930 | Andy Wilson                                                                                                                                                     |
| 468 |   1000.907570 |    697.319063 | NA                                                                                                                                                              |
| 469 |    144.005165 |    378.134929 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                   |
| 470 |   1002.880729 |    195.477194 | T. Michael Keesey                                                                                                                                               |
| 471 |    763.559092 |    575.832296 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                         |
| 472 |    508.163916 |    287.169064 | Chris huh                                                                                                                                                       |
| 473 |    353.876790 |    586.850535 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 474 |    344.747849 |    532.093507 | NA                                                                                                                                                              |
| 475 |     16.290108 |     15.234697 | Scott Hartman                                                                                                                                                   |
| 476 |     95.082777 |    654.605277 | Collin Gross                                                                                                                                                    |
| 477 |    702.655180 |    347.981582 | Matt Crook                                                                                                                                                      |
| 478 |    350.018603 |    405.868758 | Steven Traver                                                                                                                                                   |
| 479 |    741.601045 |     24.751509 | NA                                                                                                                                                              |
| 480 |    879.574713 |    622.195656 | Gareth Monger                                                                                                                                                   |
| 481 |   1013.418271 |    475.579459 | Gareth Monger                                                                                                                                                   |
| 482 |    204.168135 |    122.176296 | Chloé Schmidt                                                                                                                                                   |
| 483 |     70.580364 |    449.686812 | Jagged Fang Designs                                                                                                                                             |
| 484 |    944.807960 |    184.046652 | Jagged Fang Designs                                                                                                                                             |
| 485 |     20.144887 |    545.734373 | Maija Karala                                                                                                                                                    |
| 486 |    442.801009 |    517.338855 | T. Michael Keesey                                                                                                                                               |
| 487 |    792.936367 |    494.480586 | Maija Karala                                                                                                                                                    |
| 488 |    948.944548 |    570.713509 | Chris huh                                                                                                                                                       |
| 489 |    586.322697 |    269.197215 | Maxime Dahirel                                                                                                                                                  |
| 490 |    350.769174 |    208.172925 | Chris huh                                                                                                                                                       |
| 491 |    342.002673 |    507.231876 | Scott Hartman                                                                                                                                                   |
| 492 |    429.491054 |    302.495908 | Lukas Panzarin                                                                                                                                                  |
| 493 |    764.519280 |    303.144503 | Chris huh                                                                                                                                                       |
| 494 |    975.254494 |    470.251797 | Tracy A. Heath                                                                                                                                                  |
| 495 |     48.811472 |    531.295807 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                                  |
| 496 |    350.492984 |    289.308643 | NA                                                                                                                                                              |
| 497 |    605.864757 |     30.467033 | Walter Vladimir                                                                                                                                                 |
| 498 |    952.975151 |    156.497134 | Frank Denota                                                                                                                                                    |
| 499 |     92.835197 |      7.355429 | Chris huh                                                                                                                                                       |
| 500 |    221.809930 |     33.480992 | Iain Reid                                                                                                                                                       |
| 501 |    949.092367 |    714.245590 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                |
| 502 |     99.031603 |    753.009416 | Jagged Fang Designs                                                                                                                                             |
| 503 |     58.449782 |    241.736835 | FunkMonk                                                                                                                                                        |
| 504 |    265.512976 |    717.688044 | Carlos Cano-Barbacil                                                                                                                                            |
| 505 |    323.631440 |    638.303165 | Carlos Cano-Barbacil                                                                                                                                            |

    #> Your tweet has been posted!
