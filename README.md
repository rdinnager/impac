
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

Andy Wilson, Dmitry Bogdanov, Caleb M. Brown, Dean Schnabel, Jagged Fang
Designs, Ferran Sayol, Matt Crook, Christopher Laumer (vectorized by T.
Michael Keesey), Margot Michaud, Scott D. Sampson, Mark A. Loewen,
Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith,
Alan L. Titus, Chris huh, Markus A. Grohme, Zimices, Matt Dempsey,
CNZdenek, Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by
Maxime Dahirel), Campbell Fleming, Ghedoghedo (vectorized by T. Michael
Keesey), Francisco Gascó (modified by Michael P. Taylor), FunkMonk, T.
Michael Keesey (after Colin M. L. Burnett), Ghedo and T. Michael Keesey,
Ludwik Gąsiorowski, Obsidian Soul (vectorized by T. Michael Keesey),
Jessica Anne Miller, Mike Hanson, Steven Coombs, Christoph Schomburg,
Kamil S. Jaron, T. Michael Keesey (after Heinrich Harder), Christine
Axon, Birgit Lang, Becky Barnes, Gareth Monger, Scott Hartman, Michelle
Site, Ignacio Contreras, Nobu Tamura, vectorized by Zimices, Nobu Tamura
(vectorized by T. Michael Keesey), T. Michael Keesey (after Tillyard),
Vanessa Guerra, Milton Tan, Conty (vectorized by T. Michael Keesey),
Nobu Tamura (modified by T. Michael Keesey), Iain Reid, Dmitry Bogdanov
(vectorized by T. Michael Keesey), Verisimilus, Noah Schlottman, photo
by Casey Dunn, Jordan Mallon (vectorized by T. Michael Keesey),
Falconaumanni and T. Michael Keesey, Gabriela Palomo-Munoz, Alexander
Schmidt-Lebuhn, Tauana J. Cunha, Julio Garza, Matt Martyniuk,
Ghedoghedo, vectorized by Zimices, xgirouxb, Jose Carlos Arenas-Monroy,
Steven Traver, Shyamal, Tyler Greenfield, Sharon Wegner-Larsen, Melissa
Broussard, Felix Vaux, Timothy Knepp (vectorized by T. Michael Keesey),
M Kolmann, Apokryltaros (vectorized by T. Michael Keesey), Mali’o Kodis,
image from the Smithsonian Institution, Terpsichores, Rebecca Groom,
Kailah Thorn & Mark Hutchinson, Mason McNair, Michael Scroggie, from
original photograph by Gary M. Stolz, USFWS (original photograph in
public domain)., Tasman Dixon, André Karwath (vectorized by T. Michael
Keesey), Julia B McHugh, Marie-Aimée Allard, Cristian Osorio & Paula
Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org),
Nobu Tamura (vectorized by A. Verrière), David Liao, Chuanixn Yu, T.
Michael Keesey, Martin R. Smith, Samanta Orellana, Emily Willoughby,
Alex Slavenko, Anthony Caravaggi, L. Shyamal, Emil Schmidt (vectorized
by Maxime Dahirel), Erika Schumacher, Cathy, Smokeybjb, Tony Ayling,
Andrew A. Farke, Aadx, Jay Matternes (vectorized by T. Michael Keesey),
Michele M Tobias, Chris Jennings (Risiatto), Daniel Stadtmauer, Cesar
Julian, (after Spotila 2004), Jake Warner, Pranav Iyer (grey ideas),
Jaime Headden, C. Camilo Julián-Caballero, Mali’o Kodis, image by
Rebecca Ritger, James R. Spotila and Ray Chatterji, Arthur Weasley
(vectorized by T. Michael Keesey), Mattia Menchetti / Yan Wong, Brad
McFeeters (vectorized by T. Michael Keesey), Yan Wong, Chase Brownstein,
Matt Wilkins (photo by Patrick Kavanagh), Manabu Bessho-Uehara, Geoff
Shaw, Pete Buchholz, Ieuan Jones, Juan Carlos Jerí, Lauren
Sumner-Rooney, Mykle Hoban, Nobu Tamura, Jack Mayer Wood, Owen Jones,
Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey), Mette
Aumala, Yan Wong from SEM by Arnau Sebé-Pedrós (PD agreed by Iñaki
Ruiz-Trillo), Kimberly Haddrell, Michael Scroggie, Sarah Alewijnse,
Ville-Veikko Sinkkonen, Maxime Dahirel, Griensteidl and T. Michael
Keesey, Maxime Dahirel (digitisation), Kees van Achterberg et al (doi:
10.3897/BDJ.8.e49017)(original publication), Jimmy Bernot, Louis
Ranjard, Mathew Wedel, Collin Gross, Robbie N. Cada (vectorized by T.
Michael Keesey), TaraTaylorDesign, Jan A. Venter, Herbert H. T. Prins,
David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey),
Smokeybjb (vectorized by T. Michael Keesey), terngirl, Arthur S. Brum,
Diana Pomeroy, Ellen Edmonson and Hugh Chrisp (illustration) and Timothy
J. Bartley (silhouette), Carlos Cano-Barbacil, Stanton F. Fink
(vectorized by T. Michael Keesey), Dave Angelini, Darren Naish
(vectorize by T. Michael Keesey), Javier Luque, Scott Hartman (modified
by T. Michael Keesey), david maas / dave hone, Skye M, Sean McCann, Kai
R. Caspar, Taro Maeda, Hans Hillewaert (vectorized by T. Michael
Keesey), Bob Goldstein, Vectorization:Jake Warner, Xvazquez (vectorized
by William Gearty), Sarah Werning, Natasha Vitek, Stuart Humphries, Yan
Wong from wikipedia drawing (PD: Pearson Scott Foresman), Eduard Solà
Vázquez, vectorised by Yan Wong, Tim H. Heupink, Leon Huynen, and David
M. Lambert (vectorized by T. Michael Keesey), Francis de Laporte de
Castelnau (vectorized by T. Michael Keesey), Noah Schlottman, I. Sáček,
Sr. (vectorized by T. Michael Keesey), Lafage, Roberto Díaz Sibaja, T.
Michael Keesey (after Mivart), I. Geoffroy Saint-Hilaire (vectorized by
T. Michael Keesey), Jon Hill (Photo by DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), T.
Michael Keesey (after Joseph Wolf), Original drawing by Antonov,
vectorized by Roberto Díaz Sibaja, Almandine (vectorized by T. Michael
Keesey), Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Keith Murdock (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Javiera Constanzo, Xavier
Giroux-Bougard, Matt Martyniuk (modified by T. Michael Keesey), Dexter
R. Mardis, Maija Karala, S.Martini, John Conway, Michael P. Taylor,
Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe,
Florian Pfaff, NOAA Great Lakes Environmental Research Laboratory
(illustration) and Timothy J. Bartley (silhouette), Lukas Panzarin
(vectorized by T. Michael Keesey), Jessica Rick, Todd Marshall,
vectorized by Zimices

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                        |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------ |
|   1 |    646.466776 |    128.835203 | Andy Wilson                                                                                                                                                   |
|   2 |    734.039778 |    677.104261 | Dmitry Bogdanov                                                                                                                                               |
|   3 |    533.539785 |    557.943165 | Caleb M. Brown                                                                                                                                                |
|   4 |     71.154786 |    658.365146 | Dean Schnabel                                                                                                                                                 |
|   5 |    185.285385 |    514.702192 | Jagged Fang Designs                                                                                                                                           |
|   6 |    773.068527 |    399.845394 | Ferran Sayol                                                                                                                                                  |
|   7 |    497.779105 |    133.431261 | Matt Crook                                                                                                                                                    |
|   8 |    200.954090 |    741.170051 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                          |
|   9 |    972.204472 |    211.673399 | NA                                                                                                                                                            |
|  10 |    347.421737 |    379.642390 | Ferran Sayol                                                                                                                                                  |
|  11 |    410.041367 |    647.873803 | Margot Michaud                                                                                                                                                |
|  12 |    894.778297 |    376.627764 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                      |
|  13 |    200.448430 |    295.417824 | Matt Crook                                                                                                                                                    |
|  14 |    128.940456 |    392.356300 | Chris huh                                                                                                                                                     |
|  15 |    590.823565 |    314.919038 | Matt Crook                                                                                                                                                    |
|  16 |    797.487165 |    142.133188 | Markus A. Grohme                                                                                                                                              |
|  17 |    364.536150 |    561.818785 | NA                                                                                                                                                            |
|  18 |    248.527045 |    131.546372 | Zimices                                                                                                                                                       |
|  19 |    144.403054 |    226.616596 | Matt Dempsey                                                                                                                                                  |
|  20 |    828.111842 |    270.087809 | CNZdenek                                                                                                                                                      |
|  21 |    224.831818 |    596.007892 | Margot Michaud                                                                                                                                                |
|  22 |    988.101036 |    448.635944 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                 |
|  23 |    760.407446 |    549.447803 | Andy Wilson                                                                                                                                                   |
|  24 |    966.112977 |    690.058071 | Campbell Fleming                                                                                                                                              |
|  25 |    711.099886 |     19.124821 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                  |
|  26 |    291.792896 |    249.360816 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                               |
|  27 |    160.305556 |     38.856746 | FunkMonk                                                                                                                                                      |
|  28 |    391.994080 |    480.865556 | Andy Wilson                                                                                                                                                   |
|  29 |    295.230129 |    722.389941 | Zimices                                                                                                                                                       |
|  30 |     81.760953 |    156.611231 | T. Michael Keesey (after Colin M. L. Burnett)                                                                                                                 |
|  31 |     90.114077 |    555.225867 | Ghedo and T. Michael Keesey                                                                                                                                   |
|  32 |    581.831741 |    437.445691 | Matt Crook                                                                                                                                                    |
|  33 |    899.983848 |     96.856409 | Ludwik Gąsiorowski                                                                                                                                            |
|  34 |    590.251067 |     26.849450 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                               |
|  35 |    456.035159 |    290.210178 | Jessica Anne Miller                                                                                                                                           |
|  36 |    812.289269 |     79.288438 | Mike Hanson                                                                                                                                                   |
|  37 |    482.659158 |    419.369250 | Steven Coombs                                                                                                                                                 |
|  38 |    643.993573 |     72.738279 | Christoph Schomburg                                                                                                                                           |
|  39 |    367.705656 |    115.860186 | Kamil S. Jaron                                                                                                                                                |
|  40 |     66.185575 |    324.331727 | T. Michael Keesey (after Heinrich Harder)                                                                                                                     |
|  41 |    637.708593 |    577.090162 | NA                                                                                                                                                            |
|  42 |    660.175873 |    519.066774 | Christine Axon                                                                                                                                                |
|  43 |    709.550388 |    187.399439 | Margot Michaud                                                                                                                                                |
|  44 |    580.306695 |    193.615476 | Birgit Lang                                                                                                                                                   |
|  45 |     97.392961 |    448.394068 | Becky Barnes                                                                                                                                                  |
|  46 |    853.395411 |    701.529785 | Margot Michaud                                                                                                                                                |
|  47 |    523.143941 |    709.416505 | Gareth Monger                                                                                                                                                 |
|  48 |    843.930251 |    206.180057 | Ferran Sayol                                                                                                                                                  |
|  49 |    703.171637 |    262.555675 | Gareth Monger                                                                                                                                                 |
|  50 |     62.346536 |    742.832127 | NA                                                                                                                                                            |
|  51 |    179.436979 |    677.460189 | Scott Hartman                                                                                                                                                 |
|  52 |    919.575685 |    537.115789 | Markus A. Grohme                                                                                                                                              |
|  53 |    885.140513 |    638.121765 | Zimices                                                                                                                                                       |
|  54 |    253.021288 |    473.354581 | Michelle Site                                                                                                                                                 |
|  55 |    627.534382 |    655.828191 | Matt Crook                                                                                                                                                    |
|  56 |    560.282242 |    613.849767 | Ignacio Contreras                                                                                                                                             |
|  57 |     66.200745 |     71.494999 | Nobu Tamura, vectorized by Zimices                                                                                                                            |
|  58 |    562.609663 |    777.536667 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
|  59 |    849.466476 |    478.515874 | T. Michael Keesey (after Tillyard)                                                                                                                            |
|  60 |    853.758566 |    769.699076 | Vanessa Guerra                                                                                                                                                |
|  61 |    716.710617 |    760.826265 | Milton Tan                                                                                                                                                    |
|  62 |    729.276550 |    321.293389 | Conty (vectorized by T. Michael Keesey)                                                                                                                       |
|  63 |    543.003050 |    237.557133 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                   |
|  64 |    801.314372 |    337.034897 | Iain Reid                                                                                                                                                     |
|  65 |    458.233341 |    617.955094 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                             |
|  66 |    222.333523 |    347.258363 | Gareth Monger                                                                                                                                                 |
|  67 |    747.629882 |     64.352077 | Ferran Sayol                                                                                                                                                  |
|  68 |    171.320162 |    641.310268 | NA                                                                                                                                                            |
|  69 |    361.826475 |    768.631016 | Verisimilus                                                                                                                                                   |
|  70 |    662.378895 |    437.485300 | Gareth Monger                                                                                                                                                 |
|  71 |     73.215060 |    258.029385 | Jagged Fang Designs                                                                                                                                           |
|  72 |     69.322283 |    495.403112 | Christoph Schomburg                                                                                                                                           |
|  73 |    918.877394 |    322.586147 | Jagged Fang Designs                                                                                                                                           |
|  74 |    316.568479 |    641.198561 | Markus A. Grohme                                                                                                                                              |
|  75 |    171.234515 |    784.884421 | Markus A. Grohme                                                                                                                                              |
|  76 |    527.151611 |    512.486497 | Zimices                                                                                                                                                       |
|  77 |    737.914350 |    468.205558 | Ferran Sayol                                                                                                                                                  |
|  78 |    480.687118 |    373.299523 | Noah Schlottman, photo by Casey Dunn                                                                                                                          |
|  79 |    452.669790 |    523.159374 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                               |
|  80 |    459.236960 |     31.047973 | Falconaumanni and T. Michael Keesey                                                                                                                           |
|  81 |     47.299000 |    368.392849 | Gabriela Palomo-Munoz                                                                                                                                         |
|  82 |    972.628964 |    751.020413 | Alexander Schmidt-Lebuhn                                                                                                                                      |
|  83 |    628.531958 |    387.216333 | Markus A. Grohme                                                                                                                                              |
|  84 |    186.758000 |    169.117144 | Tauana J. Cunha                                                                                                                                               |
|  85 |    132.551735 |    605.971369 | Gabriela Palomo-Munoz                                                                                                                                         |
|  86 |    936.747705 |     13.831926 | Gabriela Palomo-Munoz                                                                                                                                         |
|  87 |    648.404834 |    223.223603 | Matt Crook                                                                                                                                                    |
|  88 |    259.938237 |    513.664365 | Margot Michaud                                                                                                                                                |
|  89 |    211.712045 |    477.678262 | NA                                                                                                                                                            |
|  90 |    167.561336 |    750.830777 | Julio Garza                                                                                                                                                   |
|  91 |    364.172755 |    216.166082 | Noah Schlottman, photo by Casey Dunn                                                                                                                          |
|  92 |     86.195786 |     99.132715 | Matt Dempsey                                                                                                                                                  |
|  93 |    751.853440 |    523.511300 | Jagged Fang Designs                                                                                                                                           |
|  94 |    262.046463 |    189.724047 | Matt Martyniuk                                                                                                                                                |
|  95 |    839.074176 |    168.344796 | Chris huh                                                                                                                                                     |
|  96 |    287.539367 |     73.132103 | Ghedoghedo, vectorized by Zimices                                                                                                                             |
|  97 |    955.785326 |    780.446669 | Becky Barnes                                                                                                                                                  |
|  98 |    816.146023 |    302.533229 | xgirouxb                                                                                                                                                      |
|  99 |     35.977540 |    672.760205 | Zimices                                                                                                                                                       |
| 100 |    883.778660 |    593.184950 | Gabriela Palomo-Munoz                                                                                                                                         |
| 101 |    596.917350 |     45.916481 | Caleb M. Brown                                                                                                                                                |
| 102 |    537.127249 |     60.870548 | Zimices                                                                                                                                                       |
| 103 |    826.249328 |    566.344656 | Chris huh                                                                                                                                                     |
| 104 |    490.085125 |    453.990534 | Jose Carlos Arenas-Monroy                                                                                                                                     |
| 105 |    243.254361 |    375.411565 | Gareth Monger                                                                                                                                                 |
| 106 |    444.807160 |    359.708188 | Matt Crook                                                                                                                                                    |
| 107 |     60.117503 |    230.285838 | Steven Traver                                                                                                                                                 |
| 108 |    427.171378 |    717.162088 | Shyamal                                                                                                                                                       |
| 109 |    386.878070 |    617.069877 | Tyler Greenfield                                                                                                                                              |
| 110 |     23.796278 |    297.346426 | Gabriela Palomo-Munoz                                                                                                                                         |
| 111 |    937.728715 |    725.285590 | Sharon Wegner-Larsen                                                                                                                                          |
| 112 |    179.539039 |     95.285600 | Zimices                                                                                                                                                       |
| 113 |    279.889270 |    554.270708 | Chris huh                                                                                                                                                     |
| 114 |    463.164649 |    767.120874 | Christoph Schomburg                                                                                                                                           |
| 115 |     26.604442 |    564.896960 | Melissa Broussard                                                                                                                                             |
| 116 |    936.734754 |    432.771714 | Felix Vaux                                                                                                                                                    |
| 117 |    319.856624 |    656.515810 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                               |
| 118 |    846.997642 |    548.381209 | Ferran Sayol                                                                                                                                                  |
| 119 |    478.958601 |     66.198326 | M Kolmann                                                                                                                                                     |
| 120 |    662.874468 |     46.526869 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                |
| 121 |    762.812699 |    497.109739 | Zimices                                                                                                                                                       |
| 122 |    789.563548 |    369.937055 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 123 |    995.471478 |    562.494741 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                          |
| 124 |    213.216487 |     75.265890 | Jagged Fang Designs                                                                                                                                           |
| 125 |    702.874096 |    491.902543 | NA                                                                                                                                                            |
| 126 |    512.739598 |     41.343624 | Terpsichores                                                                                                                                                  |
| 127 |    679.593335 |    249.801559 | Rebecca Groom                                                                                                                                                 |
| 128 |    357.075913 |    419.263340 | Campbell Fleming                                                                                                                                              |
| 129 |     92.001889 |    287.543970 | Ferran Sayol                                                                                                                                                  |
| 130 |    363.550658 |    680.320328 | Kailah Thorn & Mark Hutchinson                                                                                                                                |
| 131 |    249.840270 |     58.563139 | Mason McNair                                                                                                                                                  |
| 132 |    341.579978 |    789.937372 | Matt Crook                                                                                                                                                    |
| 133 |    637.812975 |    773.495841 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                    |
| 134 |    985.695839 |     54.751520 | Tasman Dixon                                                                                                                                                  |
| 135 |    447.586838 |     86.686260 | André Karwath (vectorized by T. Michael Keesey)                                                                                                               |
| 136 |    398.809593 |    257.073431 | Ferran Sayol                                                                                                                                                  |
| 137 |    111.157974 |    733.092578 | Steven Traver                                                                                                                                                 |
| 138 |    344.596623 |    263.453545 | Julia B McHugh                                                                                                                                                |
| 139 |    132.964913 |    277.631869 | Marie-Aimée Allard                                                                                                                                            |
| 140 |    669.347232 |    721.014425 | Steven Traver                                                                                                                                                 |
| 141 |    288.951755 |    222.703287 | Gareth Monger                                                                                                                                                 |
| 142 |    826.003614 |    741.184945 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                  |
| 143 |    293.943576 |    309.377039 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                       |
| 144 |    365.668375 |    243.476845 | David Liao                                                                                                                                                    |
| 145 |    542.044119 |    643.069806 | Chuanixn Yu                                                                                                                                                   |
| 146 |    919.229444 |    765.429167 | T. Michael Keesey                                                                                                                                             |
| 147 |    937.811174 |    509.327403 | Mason McNair                                                                                                                                                  |
| 148 |    261.035738 |     15.433742 | Zimices                                                                                                                                                       |
| 149 |    434.199499 |    689.439067 | Tauana J. Cunha                                                                                                                                               |
| 150 |    833.869248 |     30.857990 | Martin R. Smith                                                                                                                                               |
| 151 |    324.888553 |    160.289256 | Zimices                                                                                                                                                       |
| 152 |    430.160601 |    333.541142 | T. Michael Keesey                                                                                                                                             |
| 153 |     35.119981 |    439.897015 | Birgit Lang                                                                                                                                                   |
| 154 |    943.136339 |    585.359214 | Ferran Sayol                                                                                                                                                  |
| 155 |    893.375289 |    166.676472 | Samanta Orellana                                                                                                                                              |
| 156 |    296.445233 |    576.825854 | Emily Willoughby                                                                                                                                              |
| 157 |     96.166104 |    662.943805 | Zimices                                                                                                                                                       |
| 158 |   1014.550134 |    126.336396 | Gareth Monger                                                                                                                                                 |
| 159 |    683.558045 |    384.045024 | T. Michael Keesey                                                                                                                                             |
| 160 |    971.603238 |    351.891409 | Alex Slavenko                                                                                                                                                 |
| 161 |    286.460939 |    770.342350 | Anthony Caravaggi                                                                                                                                             |
| 162 |    153.616873 |    573.936856 | NA                                                                                                                                                            |
| 163 |    232.932169 |    173.605530 | Steven Traver                                                                                                                                                 |
| 164 |     26.004179 |    343.163821 | Margot Michaud                                                                                                                                                |
| 165 |    379.302695 |    744.215915 | NA                                                                                                                                                            |
| 166 |    795.612837 |    663.397869 | Markus A. Grohme                                                                                                                                              |
| 167 |    495.387079 |    292.440477 | L. Shyamal                                                                                                                                                    |
| 168 |    418.518997 |    165.165773 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                   |
| 169 |     50.728227 |     26.417990 | Erika Schumacher                                                                                                                                              |
| 170 |     15.791987 |    267.701084 | Steven Traver                                                                                                                                                 |
| 171 |    168.686387 |    550.622447 | Gareth Monger                                                                                                                                                 |
| 172 |    153.408878 |    102.117888 | Cathy                                                                                                                                                         |
| 173 |     63.146040 |    788.673873 | Smokeybjb                                                                                                                                                     |
| 174 |    758.121424 |    742.257066 | Tauana J. Cunha                                                                                                                                               |
| 175 |    885.674581 |     13.505155 | Tony Ayling                                                                                                                                                   |
| 176 |    618.710747 |    365.967675 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 177 |    392.906219 |    219.488921 | Zimices                                                                                                                                                       |
| 178 |     56.969365 |    308.895891 | Jagged Fang Designs                                                                                                                                           |
| 179 |    912.492362 |    276.015437 | Scott Hartman                                                                                                                                                 |
| 180 |    852.522223 |     25.029703 | Andrew A. Farke                                                                                                                                               |
| 181 |    484.133498 |    319.622661 | Birgit Lang                                                                                                                                                   |
| 182 |    488.912433 |    470.361174 | Anthony Caravaggi                                                                                                                                             |
| 183 |    217.335925 |    236.693121 | Matt Crook                                                                                                                                                    |
| 184 |    201.790619 |    558.775513 | Aadx                                                                                                                                                          |
| 185 |    276.346405 |     50.410974 | Chris huh                                                                                                                                                     |
| 186 |    616.969837 |    744.614582 | Ignacio Contreras                                                                                                                                             |
| 187 |    105.873443 |    691.450867 | Ferran Sayol                                                                                                                                                  |
| 188 |    282.600549 |    334.184730 | Matt Crook                                                                                                                                                    |
| 189 |    684.861224 |     57.830419 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                               |
| 190 |    572.017798 |     84.144967 | Scott Hartman                                                                                                                                                 |
| 191 |    571.347639 |    392.527637 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                             |
| 192 |    926.978432 |    415.565341 | Gareth Monger                                                                                                                                                 |
| 193 |      5.103756 |    599.701458 | Michele M Tobias                                                                                                                                              |
| 194 |    148.127076 |    136.650503 | Chris Jennings (Risiatto)                                                                                                                                     |
| 195 |    848.024119 |    225.628288 | Scott Hartman                                                                                                                                                 |
| 196 |    181.377151 |    241.930792 | Gareth Monger                                                                                                                                                 |
| 197 |    928.584215 |    562.137636 | Chris huh                                                                                                                                                     |
| 198 |     91.489009 |    771.035338 | Daniel Stadtmauer                                                                                                                                             |
| 199 |    969.660831 |    579.270133 | NA                                                                                                                                                            |
| 200 |    707.330995 |     92.876851 | Jagged Fang Designs                                                                                                                                           |
| 201 |    978.188134 |    693.902498 | Martin R. Smith                                                                                                                                               |
| 202 |     78.350896 |    591.501343 | Smokeybjb                                                                                                                                                     |
| 203 |   1006.124483 |    366.915566 | Jagged Fang Designs                                                                                                                                           |
| 204 |    198.752985 |    656.461166 | Cesar Julian                                                                                                                                                  |
| 205 |    999.630509 |     21.755019 | Margot Michaud                                                                                                                                                |
| 206 |    912.795485 |    497.941692 | Becky Barnes                                                                                                                                                  |
| 207 |    245.351932 |    550.223282 | (after Spotila 2004)                                                                                                                                          |
| 208 |    985.486970 |    325.893675 | Matt Crook                                                                                                                                                    |
| 209 |    603.551972 |    159.382624 | Scott Hartman                                                                                                                                                 |
| 210 |    318.097173 |    297.029126 | Jake Warner                                                                                                                                                   |
| 211 |    670.284094 |    351.975200 | Pranav Iyer (grey ideas)                                                                                                                                      |
| 212 |    719.555386 |    603.619948 | Jaime Headden                                                                                                                                                 |
| 213 |    276.909092 |    401.179703 | C. Camilo Julián-Caballero                                                                                                                                    |
| 214 |    231.171619 |    743.874009 | Tasman Dixon                                                                                                                                                  |
| 215 |    714.949180 |    645.740612 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                         |
| 216 |    593.075753 |    638.019092 | Matt Crook                                                                                                                                                    |
| 217 |    119.627700 |    353.424470 | Emily Willoughby                                                                                                                                              |
| 218 |    609.885632 |    790.355009 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                               |
| 219 |    471.919541 |    394.957418 | Smokeybjb                                                                                                                                                     |
| 220 |    991.090740 |    593.364412 | Matt Crook                                                                                                                                                    |
| 221 |    945.327283 |     47.017052 | NA                                                                                                                                                            |
| 222 |    457.302774 |    236.459483 | James R. Spotila and Ray Chatterji                                                                                                                            |
| 223 |    898.720461 |    426.671895 | Matt Crook                                                                                                                                                    |
| 224 |     14.889240 |    602.554138 | T. Michael Keesey                                                                                                                                             |
| 225 |    201.568273 |    143.495964 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                              |
| 226 |    900.529228 |    233.040487 | Steven Traver                                                                                                                                                 |
| 227 |    834.414115 |     54.511279 | Alex Slavenko                                                                                                                                                 |
| 228 |    496.873776 |    582.507383 | Mattia Menchetti / Yan Wong                                                                                                                                   |
| 229 |    357.141257 |    452.330187 | Dean Schnabel                                                                                                                                                 |
| 230 |    523.081754 |    589.462754 | M Kolmann                                                                                                                                                     |
| 231 |    726.667856 |    287.871755 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                              |
| 232 |    720.241779 |    398.041161 | Zimices                                                                                                                                                       |
| 233 |     35.369682 |    464.653717 | Zimices                                                                                                                                                       |
| 234 |    488.256412 |    204.151549 | Gareth Monger                                                                                                                                                 |
| 235 |   1003.551164 |    535.664532 | Yan Wong                                                                                                                                                      |
| 236 |    462.467350 |    204.432632 | Jagged Fang Designs                                                                                                                                           |
| 237 |    612.526844 |     55.969289 | Matt Crook                                                                                                                                                    |
| 238 |    188.568086 |    126.299026 | Chase Brownstein                                                                                                                                              |
| 239 |    127.861700 |    125.481374 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                      |
| 240 |    177.562782 |    444.657844 | Manabu Bessho-Uehara                                                                                                                                          |
| 241 |    214.885984 |    208.116163 | Geoff Shaw                                                                                                                                                    |
| 242 |    831.382780 |     74.750905 | Gareth Monger                                                                                                                                                 |
| 243 |   1000.341740 |     72.175013 | Chris huh                                                                                                                                                     |
| 244 |    109.994602 |     11.557911 | Pete Buchholz                                                                                                                                                 |
| 245 |    861.869409 |    737.351869 | Ieuan Jones                                                                                                                                                   |
| 246 |    676.480964 |    783.289564 | Juan Carlos Jerí                                                                                                                                              |
| 247 |    407.877700 |      5.353386 | Jagged Fang Designs                                                                                                                                           |
| 248 |    297.341802 |     23.059965 | Jagged Fang Designs                                                                                                                                           |
| 249 |    923.391732 |    465.781205 | Gabriela Palomo-Munoz                                                                                                                                         |
| 250 |    804.114728 |    595.822438 | Zimices                                                                                                                                                       |
| 251 |    776.931555 |     92.811245 | Lauren Sumner-Rooney                                                                                                                                          |
| 252 |    985.794692 |    378.399237 | Mykle Hoban                                                                                                                                                   |
| 253 |     12.550084 |    518.914523 | Gabriela Palomo-Munoz                                                                                                                                         |
| 254 |    951.032555 |    291.789041 | Nobu Tamura                                                                                                                                                   |
| 255 |    250.774009 |    454.044399 | Erika Schumacher                                                                                                                                              |
| 256 |    727.715165 |    226.085710 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 257 |    319.556317 |    670.034704 | Ferran Sayol                                                                                                                                                  |
| 258 |    768.845668 |    364.282927 | Jack Mayer Wood                                                                                                                                               |
| 259 |    473.355169 |    785.515080 | Ferran Sayol                                                                                                                                                  |
| 260 |    645.814961 |    433.156217 | Zimices                                                                                                                                                       |
| 261 |    411.222542 |    431.095579 | Matt Crook                                                                                                                                                    |
| 262 |    256.466495 |     95.199117 | Margot Michaud                                                                                                                                                |
| 263 |    813.293427 |    441.652971 | Owen Jones                                                                                                                                                    |
| 264 |    280.635202 |    661.002538 | Steven Traver                                                                                                                                                 |
| 265 |    999.456229 |    628.656402 | Gareth Monger                                                                                                                                                 |
| 266 |    287.101747 |    669.000242 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                              |
| 267 |    959.615356 |    311.048017 | Steven Traver                                                                                                                                                 |
| 268 |    885.830180 |     38.424602 | Margot Michaud                                                                                                                                                |
| 269 |    304.977436 |    202.112091 | Campbell Fleming                                                                                                                                              |
| 270 |    686.036767 |    289.782976 | Mette Aumala                                                                                                                                                  |
| 271 |    587.878906 |    763.348325 | Tasman Dixon                                                                                                                                                  |
| 272 |    823.726949 |    591.758740 | Birgit Lang                                                                                                                                                   |
| 273 |    128.019312 |    413.526228 | Yan Wong from SEM by Arnau Sebé-Pedrós (PD agreed by Iñaki Ruiz-Trillo)                                                                                       |
| 274 |    251.668506 |    314.688833 | Tasman Dixon                                                                                                                                                  |
| 275 |    271.457976 |    279.948908 | Iain Reid                                                                                                                                                     |
| 276 |    108.990396 |    518.174605 | Ferran Sayol                                                                                                                                                  |
| 277 |    606.741463 |     17.625538 | CNZdenek                                                                                                                                                      |
| 278 |    211.745748 |    774.713673 | Kimberly Haddrell                                                                                                                                             |
| 279 |    118.986874 |    704.195678 | Michael Scroggie                                                                                                                                              |
| 280 |    427.069933 |    212.331478 | Steven Traver                                                                                                                                                 |
| 281 |    637.345619 |    713.915761 | Ignacio Contreras                                                                                                                                             |
| 282 |    622.757188 |    253.511690 | Ignacio Contreras                                                                                                                                             |
| 283 |    203.711482 |    411.446338 | Sarah Alewijnse                                                                                                                                               |
| 284 |    239.795683 |    187.080413 | Ville-Veikko Sinkkonen                                                                                                                                        |
| 285 |    756.984928 |    340.811352 | Zimices                                                                                                                                                       |
| 286 |    403.382774 |    325.284975 | Maxime Dahirel                                                                                                                                                |
| 287 |    359.907467 |    609.998219 | Griensteidl and T. Michael Keesey                                                                                                                             |
| 288 |    610.458668 |    599.462051 | Caleb M. Brown                                                                                                                                                |
| 289 |     54.910769 |    586.012910 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                                    |
| 290 |    415.372773 |    738.438984 | Ignacio Contreras                                                                                                                                             |
| 291 |    857.256052 |    131.721951 | Jimmy Bernot                                                                                                                                                  |
| 292 |    858.671706 |    541.246989 | Jagged Fang Designs                                                                                                                                           |
| 293 |    389.353604 |    376.970201 | Louis Ranjard                                                                                                                                                 |
| 294 |    660.962549 |    290.511021 | Anthony Caravaggi                                                                                                                                             |
| 295 |    505.926219 |     10.606509 | NA                                                                                                                                                            |
| 296 |    517.730072 |    630.959680 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                             |
| 297 |    413.267223 |    702.329948 | Mathew Wedel                                                                                                                                                  |
| 298 |     65.968496 |    522.090885 | Jagged Fang Designs                                                                                                                                           |
| 299 |    538.089904 |    378.187255 | Gareth Monger                                                                                                                                                 |
| 300 |    378.624967 |    423.143124 | Gareth Monger                                                                                                                                                 |
| 301 |    261.956195 |    570.375420 | Andy Wilson                                                                                                                                                   |
| 302 |    673.855547 |    419.487495 | Mason McNair                                                                                                                                                  |
| 303 |     75.384002 |    346.231662 | Michelle Site                                                                                                                                                 |
| 304 |    911.260517 |    198.648326 | Collin Gross                                                                                                                                                  |
| 305 |    661.365521 |     91.122062 | Gareth Monger                                                                                                                                                 |
| 306 |    705.392957 |    585.130739 | Matt Crook                                                                                                                                                    |
| 307 |    499.169581 |    530.319752 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                  |
| 308 |    577.848717 |    562.466275 | Erika Schumacher                                                                                                                                              |
| 309 |    216.253312 |    196.339775 | Scott Hartman                                                                                                                                                 |
| 310 |    565.920659 |    169.920701 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                             |
| 311 |    803.496416 |    615.592445 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                              |
| 312 |    190.389253 |    260.593160 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 313 |     52.747314 |    289.734994 | Chris huh                                                                                                                                                     |
| 314 |   1007.206144 |    344.691528 | Jagged Fang Designs                                                                                                                                           |
| 315 |    403.058580 |    417.476279 | Margot Michaud                                                                                                                                                |
| 316 |    320.700387 |      8.407474 | Erika Schumacher                                                                                                                                              |
| 317 |     95.633642 |    262.206427 | Erika Schumacher                                                                                                                                              |
| 318 |    665.465492 |    321.423971 | Margot Michaud                                                                                                                                                |
| 319 |    816.234811 |    382.182099 | TaraTaylorDesign                                                                                                                                              |
| 320 |    161.232078 |    261.836946 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                           |
| 321 |    897.554707 |    510.985600 | Jose Carlos Arenas-Monroy                                                                                                                                     |
| 322 |    294.045329 |    785.363784 | Tasman Dixon                                                                                                                                                  |
| 323 |    450.550628 |     63.519401 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                   |
| 324 |     76.539822 |     45.458018 | Jagged Fang Designs                                                                                                                                           |
| 325 |    971.567586 |     38.019396 | T. Michael Keesey                                                                                                                                             |
| 326 |    496.783523 |    516.307767 | NA                                                                                                                                                            |
| 327 |     81.520407 |    567.326021 | terngirl                                                                                                                                                      |
| 328 |    405.675423 |    271.458932 | Birgit Lang                                                                                                                                                   |
| 329 |    976.662515 |    104.935791 | Anthony Caravaggi                                                                                                                                             |
| 330 |    734.629720 |    208.856242 | Zimices                                                                                                                                                       |
| 331 |    433.143943 |    617.243135 | Arthur S. Brum                                                                                                                                                |
| 332 |    681.780559 |    277.561489 | Ville-Veikko Sinkkonen                                                                                                                                        |
| 333 |    596.781522 |     92.829204 | Diana Pomeroy                                                                                                                                                 |
| 334 |    768.984828 |    225.720989 | Emily Willoughby                                                                                                                                              |
| 335 |    943.872210 |    479.274537 | T. Michael Keesey                                                                                                                                             |
| 336 |    115.865154 |    303.524922 | NA                                                                                                                                                            |
| 337 |    487.660742 |     24.647155 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                             |
| 338 |    945.362056 |    279.960230 | Zimices                                                                                                                                                       |
| 339 |    335.157448 |    687.910659 | Markus A. Grohme                                                                                                                                              |
| 340 |    106.905593 |    625.908488 | Tasman Dixon                                                                                                                                                  |
| 341 |     24.484243 |     87.822833 | Chris huh                                                                                                                                                     |
| 342 |    832.401748 |    179.587031 | Cesar Julian                                                                                                                                                  |
| 343 |    548.323793 |     11.555757 | Felix Vaux                                                                                                                                                    |
| 344 |    792.974319 |    761.847345 | Arthur S. Brum                                                                                                                                                |
| 345 |    143.308432 |    711.973773 | Andy Wilson                                                                                                                                                   |
| 346 |    398.553029 |    239.480295 | Carlos Cano-Barbacil                                                                                                                                          |
| 347 |    769.988520 |    242.554441 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 348 |    774.899747 |    616.622970 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                             |
| 349 |    663.070223 |    336.956505 | Dave Angelini                                                                                                                                                 |
| 350 |    564.307833 |    658.352395 | Erika Schumacher                                                                                                                                              |
| 351 |    463.084776 |    688.613167 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                 |
| 352 |    724.714412 |    249.043817 | Javier Luque                                                                                                                                                  |
| 353 |    720.131537 |     43.107014 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                 |
| 354 |    430.861822 |     18.832886 | Gareth Monger                                                                                                                                                 |
| 355 |    112.592677 |     90.657009 | Alex Slavenko                                                                                                                                                 |
| 356 |    734.151468 |    733.094819 | david maas / dave hone                                                                                                                                        |
| 357 |    907.887200 |    578.211245 | Skye M                                                                                                                                                        |
| 358 |    243.890021 |    395.243118 | Sean McCann                                                                                                                                                   |
| 359 |    582.948771 |    146.441491 | Kai R. Caspar                                                                                                                                                 |
| 360 |    756.087992 |    292.997871 | Taro Maeda                                                                                                                                                    |
| 361 |     75.310050 |    462.593322 | Jessica Anne Miller                                                                                                                                           |
| 362 |    746.353307 |    788.911993 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                             |
| 363 |    503.174631 |     66.113873 | Iain Reid                                                                                                                                                     |
| 364 |    902.073840 |    670.864332 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 365 |   1004.515766 |    106.431428 | Scott Hartman                                                                                                                                                 |
| 366 |    519.698439 |    389.841677 | Matt Crook                                                                                                                                                    |
| 367 |    632.780960 |    477.370527 | Bob Goldstein, Vectorization:Jake Warner                                                                                                                      |
| 368 |    233.070854 |     22.763407 | Xvazquez (vectorized by William Gearty)                                                                                                                       |
| 369 |     23.165312 |    582.449616 | Jagged Fang Designs                                                                                                                                           |
| 370 |    468.573058 |    655.936413 | Matt Crook                                                                                                                                                    |
| 371 |    832.552833 |    543.273386 | NA                                                                                                                                                            |
| 372 |    906.350702 |    650.395267 | Steven Coombs                                                                                                                                                 |
| 373 |    435.518293 |    192.912231 | Alex Slavenko                                                                                                                                                 |
| 374 |    915.581565 |     42.007399 | Birgit Lang                                                                                                                                                   |
| 375 |    747.419867 |     22.018168 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 376 |    501.352043 |    332.108430 | Sarah Werning                                                                                                                                                 |
| 377 |     33.745064 |    391.367500 | Dean Schnabel                                                                                                                                                 |
| 378 |    151.099062 |    203.350289 | Gareth Monger                                                                                                                                                 |
| 379 |    990.647337 |     85.627265 | Natasha Vitek                                                                                                                                                 |
| 380 |    278.356803 |    516.384979 | Stuart Humphries                                                                                                                                              |
| 381 |    930.911515 |    351.552442 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                  |
| 382 |    594.554289 |    492.429186 | Gareth Monger                                                                                                                                                 |
| 383 |     33.289156 |    616.450597 | Sarah Werning                                                                                                                                                 |
| 384 |    441.230437 |    500.191214 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 385 |     17.652055 |    467.426248 | Ferran Sayol                                                                                                                                                  |
| 386 |    557.596744 |    593.472322 | Eduard Solà Vázquez, vectorised by Yan Wong                                                                                                                   |
| 387 |    431.357053 |    153.952739 | NA                                                                                                                                                            |
| 388 |    432.735576 |    779.674815 | Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael Keesey)                                                                           |
| 389 |    516.450845 |    333.145759 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                             |
| 390 |     10.254862 |    410.629732 | Ferran Sayol                                                                                                                                                  |
| 391 |    518.297997 |    307.946413 | Ignacio Contreras                                                                                                                                             |
| 392 |    397.148380 |    627.500120 | Erika Schumacher                                                                                                                                              |
| 393 |    203.853145 |    707.851733 | Noah Schlottman                                                                                                                                               |
| 394 |    575.011363 |    575.544288 | Margot Michaud                                                                                                                                                |
| 395 |     47.073020 |    571.520955 | Iain Reid                                                                                                                                                     |
| 396 |    388.837099 |    360.268801 | Chris huh                                                                                                                                                     |
| 397 |    466.530391 |    216.849727 | Matt Crook                                                                                                                                                    |
| 398 |    137.933265 |    158.485213 | Andrew A. Farke                                                                                                                                               |
| 399 |     16.001232 |    226.420332 | I. Sáček, Sr. (vectorized by T. Michael Keesey)                                                                                                               |
| 400 |    699.909462 |    235.932047 | Gareth Monger                                                                                                                                                 |
| 401 |    175.805203 |    457.758454 | NA                                                                                                                                                            |
| 402 |    964.420021 |    675.739585 | Gabriela Palomo-Munoz                                                                                                                                         |
| 403 |    785.666762 |    154.211888 | Andrew A. Farke                                                                                                                                               |
| 404 |    183.181923 |     75.500538 | Margot Michaud                                                                                                                                                |
| 405 |     24.591868 |    777.316504 | Lafage                                                                                                                                                        |
| 406 |    134.601308 |    659.391684 | Chuanixn Yu                                                                                                                                                   |
| 407 |    452.666835 |    555.756442 | Roberto Díaz Sibaja                                                                                                                                           |
| 408 |    370.365614 |    268.376984 | Smokeybjb                                                                                                                                                     |
| 409 |    551.980378 |    407.492297 | Ferran Sayol                                                                                                                                                  |
| 410 |    147.078940 |    355.937496 | Jagged Fang Designs                                                                                                                                           |
| 411 |    696.993841 |    649.853076 | NA                                                                                                                                                            |
| 412 |    220.871635 |     90.211084 | NA                                                                                                                                                            |
| 413 |    286.073122 |    750.475804 | Andrew A. Farke                                                                                                                                               |
| 414 |    675.500281 |    564.413196 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                   |
| 415 |    400.908472 |    397.633637 | Gareth Monger                                                                                                                                                 |
| 416 |    512.103595 |    195.563113 | Jagged Fang Designs                                                                                                                                           |
| 417 |    516.173387 |    271.702511 | T. Michael Keesey (after Mivart)                                                                                                                              |
| 418 |    828.976045 |    524.150314 | Yan Wong                                                                                                                                                      |
| 419 |    783.144880 |    559.673126 | Caleb M. Brown                                                                                                                                                |
| 420 |    223.943194 |    310.910672 | Matt Crook                                                                                                                                                    |
| 421 |    839.333760 |    657.084536 | Zimices                                                                                                                                                       |
| 422 |    983.446183 |    408.498178 | Jagged Fang Designs                                                                                                                                           |
| 423 |    401.490996 |    674.860612 | Gareth Monger                                                                                                                                                 |
| 424 |    171.986491 |    693.142706 | Chris huh                                                                                                                                                     |
| 425 |     30.599398 |     42.598789 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                   |
| 426 |    722.218703 |    134.874857 | Matt Crook                                                                                                                                                    |
| 427 |    600.721760 |    511.270027 | Scott Hartman                                                                                                                                                 |
| 428 |    642.850535 |     57.856377 | Chris Jennings (Risiatto)                                                                                                                                     |
| 429 |    683.741706 |    236.456381 | Steven Traver                                                                                                                                                 |
| 430 |    572.362324 |    114.929055 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                |
| 431 |    245.179455 |    205.309207 | Iain Reid                                                                                                                                                     |
| 432 |    936.080959 |    393.739896 | FunkMonk                                                                                                                                                      |
| 433 |    262.276074 |    466.683277 | Margot Michaud                                                                                                                                                |
| 434 |    137.825473 |    294.309141 | Scott Hartman                                                                                                                                                 |
| 435 |    956.077699 |    378.285788 | T. Michael Keesey (after Joseph Wolf)                                                                                                                         |
| 436 |    617.187912 |    783.650456 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                             |
| 437 |    134.911809 |    533.614203 | CNZdenek                                                                                                                                                      |
| 438 |     45.423762 |    703.995607 | Sarah Werning                                                                                                                                                 |
| 439 |    507.578791 |    782.124974 | Caleb M. Brown                                                                                                                                                |
| 440 |    312.165878 |    180.323625 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 441 |   1015.330537 |    255.710030 | T. Michael Keesey                                                                                                                                             |
| 442 |    171.087940 |    282.780399 | Michelle Site                                                                                                                                                 |
| 443 |    794.520303 |    223.285465 | Almandine (vectorized by T. Michael Keesey)                                                                                                                   |
| 444 |     82.006175 |     26.134818 | Sarah Werning                                                                                                                                                 |
| 445 |    444.185223 |    745.846124 | Kamil S. Jaron                                                                                                                                                |
| 446 |    481.022111 |    754.521159 | Steven Traver                                                                                                                                                 |
| 447 |    787.142446 |    545.667987 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                               |
| 448 |    282.715100 |    207.730707 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 449 |    782.279515 |    390.985671 | Jagged Fang Designs                                                                                                                                           |
| 450 |    705.291516 |    419.532399 | Jagged Fang Designs                                                                                                                                           |
| 451 |    281.916600 |    305.466607 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                    |
| 452 |    650.865593 |     87.853658 | Jagged Fang Designs                                                                                                                                           |
| 453 |    545.840467 |    749.027782 | Jagged Fang Designs                                                                                                                                           |
| 454 |    422.243965 |    290.323754 | Gareth Monger                                                                                                                                                 |
| 455 |    446.835617 |    538.471733 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey       |
| 456 |    836.593296 |    294.996997 | Scott Hartman                                                                                                                                                 |
| 457 |    708.008297 |    409.783142 | Chris huh                                                                                                                                                     |
| 458 |     12.599308 |    120.411591 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 459 |    220.229897 |    633.687301 | Javiera Constanzo                                                                                                                                             |
| 460 |    157.474313 |    422.920365 | Xavier Giroux-Bougard                                                                                                                                         |
| 461 |     24.796396 |    175.871870 | T. Michael Keesey                                                                                                                                             |
| 462 |    633.057135 |    613.740179 | Steven Traver                                                                                                                                                 |
| 463 |    223.800338 |    448.148197 | Chris huh                                                                                                                                                     |
| 464 |    386.876138 |    448.032991 | Tasman Dixon                                                                                                                                                  |
| 465 |    304.681512 |    326.942389 | Maxime Dahirel                                                                                                                                                |
| 466 |    148.397542 |    649.142146 | M Kolmann                                                                                                                                                     |
| 467 |    355.659223 |    184.601584 | Chris huh                                                                                                                                                     |
| 468 |    876.222471 |    424.927075 | Gareth Monger                                                                                                                                                 |
| 469 |     28.636485 |    641.213336 | Arthur S. Brum                                                                                                                                                |
| 470 |    432.253678 |    228.079454 | Gareth Monger                                                                                                                                                 |
| 471 |    151.377575 |    794.784441 | Scott Hartman                                                                                                                                                 |
| 472 |    734.296934 |    624.559711 | Melissa Broussard                                                                                                                                             |
| 473 |    405.096911 |    294.362945 | Cathy                                                                                                                                                         |
| 474 |    868.320015 |    179.302990 | Gareth Monger                                                                                                                                                 |
| 475 |    612.115826 |    266.144664 | NA                                                                                                                                                            |
| 476 |     19.099690 |    210.490514 | Zimices                                                                                                                                                       |
| 477 |    278.198908 |    173.596483 | Jagged Fang Designs                                                                                                                                           |
| 478 |    997.364156 |    131.207873 | Ferran Sayol                                                                                                                                                  |
| 479 |   1001.400400 |    330.029894 | Margot Michaud                                                                                                                                                |
| 480 |    162.787568 |     81.587891 | Caleb M. Brown                                                                                                                                                |
| 481 |    288.141168 |    597.365030 | Jagged Fang Designs                                                                                                                                           |
| 482 |    171.409377 |    471.306821 | Margot Michaud                                                                                                                                                |
| 483 |    680.666434 |    673.367666 | Jagged Fang Designs                                                                                                                                           |
| 484 |    873.757560 |    212.619067 | Scott Hartman                                                                                                                                                 |
| 485 |    656.479665 |    741.068094 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                |
| 486 |    112.530477 |    796.216695 | Chris huh                                                                                                                                                     |
| 487 |   1012.897268 |    674.771312 | Andy Wilson                                                                                                                                                   |
| 488 |    139.592897 |    436.187547 | Shyamal                                                                                                                                                       |
| 489 |    332.430634 |    275.504906 | Zimices                                                                                                                                                       |
| 490 |    979.708087 |    512.537806 | Dexter R. Mardis                                                                                                                                              |
| 491 |    574.930051 |     58.149113 | NA                                                                                                                                                            |
| 492 |    726.402873 |    714.578883 | Chuanixn Yu                                                                                                                                                   |
| 493 |    447.933290 |    548.078597 | Maija Karala                                                                                                                                                  |
| 494 |    727.723589 |     32.368726 | Margot Michaud                                                                                                                                                |
| 495 |    912.978027 |    738.306025 | Dean Schnabel                                                                                                                                                 |
| 496 |    603.915219 |    527.957250 | Matt Crook                                                                                                                                                    |
| 497 |    728.579166 |    275.237285 | Jagged Fang Designs                                                                                                                                           |
| 498 |    129.537055 |     78.767800 | S.Martini                                                                                                                                                     |
| 499 |    785.278547 |    119.705238 | Jagged Fang Designs                                                                                                                                           |
| 500 |     79.819654 |    581.482649 | John Conway                                                                                                                                                   |
| 501 |    522.831473 |    470.515055 | Jagged Fang Designs                                                                                                                                           |
| 502 |    568.690316 |    757.391881 | C. Camilo Julián-Caballero                                                                                                                                    |
| 503 |    914.398395 |    523.254700 | Kamil S. Jaron                                                                                                                                                |
| 504 |    371.995645 |    786.799952 | Steven Traver                                                                                                                                                 |
| 505 |    817.457240 |    757.637640 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                 |
| 506 |    516.423901 |    756.788113 | Michael P. Taylor                                                                                                                                             |
| 507 |    800.963004 |    772.876891 | Roberto Díaz Sibaja                                                                                                                                           |
| 508 |    461.407129 |    670.506181 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                          |
| 509 |    554.155459 |    380.433209 | NA                                                                                                                                                            |
| 510 |    648.824540 |    171.292423 | Jack Mayer Wood                                                                                                                                               |
| 511 |    926.434147 |    150.239583 | Florian Pfaff                                                                                                                                                 |
| 512 |    580.135137 |    595.780441 | Chris huh                                                                                                                                                     |
| 513 |    646.605759 |    406.224491 | Emily Willoughby                                                                                                                                              |
| 514 |    176.845141 |    143.005493 | Chris huh                                                                                                                                                     |
| 515 |    941.764369 |    302.933747 | Ignacio Contreras                                                                                                                                             |
| 516 |    110.417133 |    651.495968 | Julio Garza                                                                                                                                                   |
| 517 |    115.053895 |    101.982489 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                         |
| 518 |    819.490747 |    794.143122 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                  |
| 519 |    171.433953 |    229.544537 | Markus A. Grohme                                                                                                                                              |
| 520 |    817.290062 |    675.891235 | Scott Hartman                                                                                                                                                 |
| 521 |    791.399189 |    653.218496 | Pranav Iyer (grey ideas)                                                                                                                                      |
| 522 |    877.930811 |    342.652655 | Jagged Fang Designs                                                                                                                                           |
| 523 |    960.219080 |    502.230458 | Alex Slavenko                                                                                                                                                 |
| 524 |    651.773919 |      7.081230 | Nobu Tamura                                                                                                                                                   |
| 525 |    795.079272 |     18.113432 | Zimices                                                                                                                                                       |
| 526 |    106.358432 |    109.086638 | Scott Hartman                                                                                                                                                 |
| 527 |    121.906411 |    768.689145 | Jagged Fang Designs                                                                                                                                           |
| 528 |    172.602677 |    192.350154 | Lukas Panzarin (vectorized by T. Michael Keesey)                                                                                                              |
| 529 |     16.069417 |    714.915223 | Gabriela Palomo-Munoz                                                                                                                                         |
| 530 |    695.269795 |     41.524348 | Gabriela Palomo-Munoz                                                                                                                                         |
| 531 |    629.715506 |    307.349305 | Jessica Rick                                                                                                                                                  |
| 532 |    577.399725 |    368.556396 | Xavier Giroux-Bougard                                                                                                                                         |
| 533 |    939.340966 |    455.029305 | Erika Schumacher                                                                                                                                              |
| 534 |    165.613939 |    483.210695 | Todd Marshall, vectorized by Zimices                                                                                                                          |
| 535 |    779.189802 |    784.209299 | Jagged Fang Designs                                                                                                                                           |
| 536 |    303.913814 |    625.445025 | Iain Reid                                                                                                                                                     |
| 537 |    913.724584 |    165.330612 | Sean McCann                                                                                                                                                   |

    #> Your tweet has been posted!
