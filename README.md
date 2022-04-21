
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

Markus A. Grohme, Trond R. Oskars, Jesús Gómez, vectorized by Zimices,
Michael Scroggie, from original photograph by John Bettaso, USFWS
(original photograph in public domain)., Ferran Sayol, Chris Jennings
(Risiatto), Gareth Monger, Smokeybjb, Richard Parker (vectorized by T.
Michael Keesey), Oscar Sanisidro, Iain Reid, Andy Wilson, Pete Buchholz,
Margot Michaud, Ignacio Contreras, Jagged Fang Designs, Felix Vaux, C.
Camilo Julián-Caballero, Pollyanna von Knorring and T. Michael Keesey,
Tasman Dixon, Matt Crook, Steven Coombs, Martin R. Smith, CNZdenek,
Armin Reindl, Milton Tan, Sarah Werning, Steven Traver, Kamil S. Jaron,
Dean Schnabel, Ernst Haeckel (vectorized by T. Michael Keesey), Giant
Blue Anteater (vectorized by T. Michael Keesey), Noah Schlottman, photo
from Casey Dunn, Kai R. Caspar, Crystal Maier, Dmitry Bogdanov (modified
by T. Michael Keesey), Nobu Tamura, vectorized by Zimices, Collin Gross,
Andrew A. Farke, Chris huh, Gabriela Palomo-Munoz, Conty (vectorized by
T. Michael Keesey), Cesar Julian, Christoph Schomburg, Michael Scroggie,
Dmitry Bogdanov (vectorized by T. Michael Keesey), Scott Hartman,
Zimices, Lukasiniho, Joanna Wolfe, Jack Mayer Wood, Óscar San-Isidro
(vectorized by T. Michael Keesey), Dexter R. Mardis, Tracy A. Heath,
Beth Reinke, T. Tischler, Jan A. Venter, Herbert H. T. Prins, David A.
Balfour & Rob Slotow (vectorized by T. Michael Keesey), Kanchi Nanjo,
John Curtis (vectorized by T. Michael Keesey), Courtney Rockenbach,
Birgit Lang, Lily Hughes, Alexandre Vong, Jiekun He, Alex Slavenko, Nobu
Tamura, Christian A. Masnaghetti, Carlos Cano-Barbacil, B. Duygu
Özpolat, Michelle Site, Jaime Headden, Apokryltaros (vectorized by T.
Michael Keesey), Dantheman9758 (vectorized by T. Michael Keesey), Sharon
Wegner-Larsen, Scarlet23 (vectorized by T. Michael Keesey), L. Shyamal,
Lisa Byrne, Jessica Rick, terngirl, Mercedes Yrayzoz (vectorized by T.
Michael Keesey), DW Bapst, modified from Figure 1 of Belanger (2011,
PALAIOS)., Emily Willoughby, Alexander Schmidt-Lebuhn, Steve
Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael
Keesey (vectorization), Myriam\_Ramirez, Martin R. Smith, after Skovsted
et al 2015, Pedro de Siracusa, Acrocynus (vectorized by T. Michael
Keesey), Nobu Tamura (modified by T. Michael Keesey), Tyler Greenfield,
T. Michael Keesey, Melissa Ingala, Caio Bernardes, vectorized by
Zimices, Mali’o Kodis, image from the Biodiversity Heritage Library,
Mali’o Kodis, photograph from Jersabek et al, 2003, Chase Brownstein,
Mariana Ruiz Villarreal, Matt Martyniuk, Dmitry Bogdanov, vectorized by
Zimices, Maija Karala, Matthew Hooge (vectorized by T. Michael Keesey),
Lani Mohan, Ryan Cupo, Daniel Jaron, Ellen Edmonson and Hugh Chrisp
(illustration) and Timothy J. Bartley (silhouette), Matthew E. Clapham,
Noah Schlottman, Mathew Wedel, Ghedoghedo (vectorized by T. Michael
Keesey), Agnello Picorelli, Berivan Temiz, Brian Gratwicke (photo) and
T. Michael Keesey (vectorization), Nobu Tamura (vectorized by T. Michael
Keesey), Mali’o Kodis, image by Rebecca Ritger, Benjamint444, Frederick
William Frohawk (vectorized by T. Michael Keesey), Felix Vaux and Steven
A. Trewick, G. M. Woodward, M Kolmann, Warren H (photography), T.
Michael Keesey (vectorization), SecretJellyMan, Andreas Trepte
(vectorized by T. Michael Keesey), Harold N Eyster, Maxime Dahirel
(digitisation), Kees van Achterberg et al (doi:
10.3897/BDJ.8.e49017)(original publication), Inessa Voet, Michael B. H.
(vectorized by T. Michael Keesey), Emil Schmidt (vectorized by Maxime
Dahirel), Maxime Dahirel, New York Zoological Society, Mali’o Kodis,
photograph by G. Giribet, Kenneth Lacovara (vectorized by T. Michael
Keesey), Michael Scroggie, from original photograph by Gary M. Stolz,
USFWS (original photograph in public domain)., Yan Wong, Becky Barnes,
Pranav Iyer (grey ideas), Smokeybjb (vectorized by T. Michael Keesey),
Francis de Laporte de Castelnau (vectorized by T. Michael Keesey), Ingo
Braasch, FunkMonk, Ghedo and T. Michael Keesey, Yan Wong from
illustration by Charles Orbigny, Pearson Scott Foresman (vectorized by
T. Michael Keesey), Anthony Caravaggi, Vijay Cavale (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Noah Schlottman,
photo by Antonio Guillén, Matt Dempsey, Diana Pomeroy, Cagri Cevrim,
Erika Schumacher, Scott Reid, Tambja (vectorized by T. Michael Keesey),
James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis
Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey), Jose
Carlos Arenas-Monroy, Charles R. Knight, vectorized by Zimices, FunkMonk
(Michael B.H.; vectorized by T. Michael Keesey), Noah Schlottman, photo
by Casey Dunn, Darius Nau, Robert Gay, Robert Bruce Horsfall (vectorized
by William Gearty), Noah Schlottman, photo by Martin V. Sørensen, Bruno
Maggia, Cristina Guijarro, Jessica Anne Miller, Duane Raver (vectorized
by T. Michael Keesey), Tony Ayling, T. K. Robinson, T. Michael Keesey
(vectorization) and Nadiatalent (photography), Ricardo N. Martinez &
Oscar A. Alcober, Renata F. Martins, Emily Jane McTavish,
\<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\>
(vectorized by T. Michael Keesey), Mali’o Kodis, photograph by Bruno
Vellutini, Michael P. Taylor, Smokeybjb (modified by Mike Keesey),
zoosnow, Robbie N. Cada (modified by T. Michael Keesey), Eduard Solà
(vectorized by T. Michael Keesey), Dmitry Bogdanov, Christine Axon,
Jonathan Wells, Sherman Foote Denton (illustration, 1897) and Timothy J.
Bartley (silhouette), Mathilde Cordellier, Alyssa Bell & Luis Chiappe
2015, dx.doi.org/10.1371/journal.pone.0141690, Smith609 and T. Michael
Keesey, Lafage, Ville Koistinen (vectorized by T. Michael Keesey), Geoff
Shaw, Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey),
\[unknown\]

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                       |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    311.358299 |    524.712429 | Markus A. Grohme                                                                                                                                             |
|   2 |    409.980566 |     80.983432 | Trond R. Oskars                                                                                                                                              |
|   3 |    305.838844 |    392.701652 | Jesús Gómez, vectorized by Zimices                                                                                                                           |
|   4 |    584.839336 |    196.319624 | Michael Scroggie, from original photograph by John Bettaso, USFWS (original photograph in public domain).                                                    |
|   5 |    850.851556 |    703.674657 | Ferran Sayol                                                                                                                                                 |
|   6 |    810.414782 |    430.830517 | Chris Jennings (Risiatto)                                                                                                                                    |
|   7 |    805.474201 |    510.568533 | Gareth Monger                                                                                                                                                |
|   8 |    158.136660 |    751.662225 | Smokeybjb                                                                                                                                                    |
|   9 |    227.725953 |    650.115150 | Richard Parker (vectorized by T. Michael Keesey)                                                                                                             |
|  10 |    816.807817 |     85.360670 | Oscar Sanisidro                                                                                                                                              |
|  11 |    121.451181 |    689.419366 | Iain Reid                                                                                                                                                    |
|  12 |    557.128419 |    648.653910 | Andy Wilson                                                                                                                                                  |
|  13 |    884.053135 |    207.621700 | Pete Buchholz                                                                                                                                                |
|  14 |    334.057379 |    644.614217 | Margot Michaud                                                                                                                                               |
|  15 |    467.616266 |    434.355022 | Ignacio Contreras                                                                                                                                            |
|  16 |    189.641477 |     34.511347 | Jagged Fang Designs                                                                                                                                          |
|  17 |    246.511809 |    288.348699 | Andy Wilson                                                                                                                                                  |
|  18 |    689.816890 |    230.120598 | Felix Vaux                                                                                                                                                   |
|  19 |    961.954841 |    454.954926 | C. Camilo Julián-Caballero                                                                                                                                   |
|  20 |    459.898132 |    279.677556 | C. Camilo Julián-Caballero                                                                                                                                   |
|  21 |    953.750136 |    574.159186 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                 |
|  22 |    405.934501 |    177.022212 | Tasman Dixon                                                                                                                                                 |
|  23 |    937.668142 |     49.715098 | NA                                                                                                                                                           |
|  24 |    832.168320 |    291.569328 | Matt Crook                                                                                                                                                   |
|  25 |    102.382038 |    114.983426 | Matt Crook                                                                                                                                                   |
|  26 |     66.725817 |    250.481000 | Steven Coombs                                                                                                                                                |
|  27 |    202.705355 |    463.149112 | Martin R. Smith                                                                                                                                              |
|  28 |    593.999488 |    503.092607 | Matt Crook                                                                                                                                                   |
|  29 |    223.912031 |    159.044351 | Margot Michaud                                                                                                                                               |
|  30 |    273.745051 |    739.030114 | NA                                                                                                                                                           |
|  31 |    788.024463 |    622.691434 | CNZdenek                                                                                                                                                     |
|  32 |    644.112424 |    334.295881 | Armin Reindl                                                                                                                                                 |
|  33 |    505.481462 |    359.733990 | Milton Tan                                                                                                                                                   |
|  34 |    444.830525 |    767.720989 | Gareth Monger                                                                                                                                                |
|  35 |    557.006366 |     48.434131 | Sarah Werning                                                                                                                                                |
|  36 |    711.780192 |    750.937176 | Steven Traver                                                                                                                                                |
|  37 |    953.555065 |    696.718328 | Kamil S. Jaron                                                                                                                                               |
|  38 |    369.238506 |    470.234065 | Margot Michaud                                                                                                                                               |
|  39 |    339.493972 |    558.168415 | Dean Schnabel                                                                                                                                                |
|  40 |     87.719759 |    588.954046 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                              |
|  41 |    953.751208 |    354.398124 | Steven Traver                                                                                                                                                |
|  42 |    957.449412 |    266.730811 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                        |
|  43 |     94.562839 |    422.612906 | Andy Wilson                                                                                                                                                  |
|  44 |    649.429172 |     60.546850 | Noah Schlottman, photo from Casey Dunn                                                                                                                       |
|  45 |    401.439381 |    247.862332 | Dean Schnabel                                                                                                                                                |
|  46 |    474.121872 |    523.681570 | Kai R. Caspar                                                                                                                                                |
|  47 |    751.523248 |    160.912112 | Crystal Maier                                                                                                                                                |
|  48 |    658.318269 |    434.499105 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                              |
|  49 |    247.963353 |     66.721330 | Nobu Tamura, vectorized by Zimices                                                                                                                           |
|  50 |     44.925694 |    722.457510 | NA                                                                                                                                                           |
|  51 |    935.023250 |    158.954846 | Collin Gross                                                                                                                                                 |
|  52 |    297.872939 |    163.902422 | Andrew A. Farke                                                                                                                                              |
|  53 |    560.373258 |    135.280340 | Chris huh                                                                                                                                                    |
|  54 |     96.644682 |    345.651300 | Ignacio Contreras                                                                                                                                            |
|  55 |    736.597924 |    700.724550 | Gabriela Palomo-Munoz                                                                                                                                        |
|  56 |    103.193696 |    304.489727 | Conty (vectorized by T. Michael Keesey)                                                                                                                      |
|  57 |    226.382547 |    557.418558 | NA                                                                                                                                                           |
|  58 |    859.253006 |    395.813905 | Chris huh                                                                                                                                                    |
|  59 |    406.644285 |    321.544377 | Cesar Julian                                                                                                                                                 |
|  60 |    344.538229 |    282.725921 | Ignacio Contreras                                                                                                                                            |
|  61 |    102.050628 |    215.323018 | Christoph Schomburg                                                                                                                                          |
|  62 |    869.131409 |    558.541399 | Michael Scroggie                                                                                                                                             |
|  63 |    387.264111 |    736.869968 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
|  64 |    757.533668 |    371.236154 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
|  65 |    559.961176 |    433.931779 | NA                                                                                                                                                           |
|  66 |    507.585429 |     74.669362 | Ferran Sayol                                                                                                                                                 |
|  67 |    745.078608 |    268.626368 | Gareth Monger                                                                                                                                                |
|  68 |    676.390450 |    142.962935 | Scott Hartman                                                                                                                                                |
|  69 |    590.166999 |    277.159683 | Zimices                                                                                                                                                      |
|  70 |    375.605068 |    405.219851 | Matt Crook                                                                                                                                                   |
|  71 |    987.796048 |    211.265364 | Gabriela Palomo-Munoz                                                                                                                                        |
|  72 |    944.090064 |    494.893056 | NA                                                                                                                                                           |
|  73 |    939.495270 |    100.364423 | Lukasiniho                                                                                                                                                   |
|  74 |     34.571999 |    474.023173 | Scott Hartman                                                                                                                                                |
|  75 |    178.734324 |    418.097583 | Joanna Wolfe                                                                                                                                                 |
|  76 |    201.747030 |    726.569792 | Jack Mayer Wood                                                                                                                                              |
|  77 |    433.868706 |    641.969572 | Zimices                                                                                                                                                      |
|  78 |    199.056477 |     98.729548 | Óscar San-Isidro (vectorized by T. Michael Keesey)                                                                                                           |
|  79 |    949.173247 |    772.238366 | Tasman Dixon                                                                                                                                                 |
|  80 |    105.053695 |    511.259458 | Dexter R. Mardis                                                                                                                                             |
|  81 |     72.817057 |    177.876703 | Tracy A. Heath                                                                                                                                               |
|  82 |    194.224160 |    370.855635 | Chris huh                                                                                                                                                    |
|  83 |    692.780252 |    716.593438 | Beth Reinke                                                                                                                                                  |
|  84 |    349.860659 |    143.917208 | T. Tischler                                                                                                                                                  |
|  85 |     73.326135 |    652.650814 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
|  86 |     37.575378 |     56.714234 | Ferran Sayol                                                                                                                                                 |
|  87 |    898.401423 |     37.653170 | Andy Wilson                                                                                                                                                  |
|  88 |    875.049517 |    605.030262 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                          |
|  89 |    796.766229 |    184.394561 | Kanchi Nanjo                                                                                                                                                 |
|  90 |    727.786503 |    488.744157 | Gareth Monger                                                                                                                                                |
|  91 |    339.766800 |     50.835817 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                |
|  92 |    348.683180 |     21.699332 | Courtney Rockenbach                                                                                                                                          |
|  93 |    979.076746 |    610.799915 | Birgit Lang                                                                                                                                                  |
|  94 |    367.882545 |    355.851340 | Margot Michaud                                                                                                                                               |
|  95 |    304.788472 |     91.537115 | Collin Gross                                                                                                                                                 |
|  96 |    153.323161 |    448.074314 | Lily Hughes                                                                                                                                                  |
|  97 |    489.151048 |    221.315890 | Alexandre Vong                                                                                                                                               |
|  98 |    899.566074 |    444.455781 | Ferran Sayol                                                                                                                                                 |
|  99 |    927.091873 |    228.126540 | Matt Crook                                                                                                                                                   |
| 100 |    781.997776 |    584.914124 | Milton Tan                                                                                                                                                   |
| 101 |     88.011791 |     44.227222 | Jiekun He                                                                                                                                                    |
| 102 |    246.689234 |    510.670692 | Scott Hartman                                                                                                                                                |
| 103 |    756.036441 |     63.207752 | Jagged Fang Designs                                                                                                                                          |
| 104 |    873.080959 |    493.216146 | NA                                                                                                                                                           |
| 105 |    768.424057 |    721.236899 | Alex Slavenko                                                                                                                                                |
| 106 |    230.399528 |     35.325683 | Nobu Tamura                                                                                                                                                  |
| 107 |    391.109604 |    507.584200 | Jagged Fang Designs                                                                                                                                          |
| 108 |     92.295945 |    755.762904 | Chris huh                                                                                                                                                    |
| 109 |    571.276018 |     24.609719 | Chris huh                                                                                                                                                    |
| 110 |    151.585238 |    173.049495 | Christian A. Masnaghetti                                                                                                                                     |
| 111 |    926.399352 |    188.055179 | Conty (vectorized by T. Michael Keesey)                                                                                                                      |
| 112 |    508.666433 |    757.642757 | Gareth Monger                                                                                                                                                |
| 113 |    512.349564 |    733.063206 | Carlos Cano-Barbacil                                                                                                                                         |
| 114 |    243.612451 |    491.589623 | Iain Reid                                                                                                                                                    |
| 115 |    518.678333 |     11.200973 | Zimices                                                                                                                                                      |
| 116 |   1006.240495 |    293.352375 | Margot Michaud                                                                                                                                               |
| 117 |    921.748678 |    132.555181 | Jagged Fang Designs                                                                                                                                          |
| 118 |    358.469941 |    510.659852 | B. Duygu Özpolat                                                                                                                                             |
| 119 |    156.788293 |    638.321760 | Michelle Site                                                                                                                                                |
| 120 |     52.374261 |    442.528641 | Sarah Werning                                                                                                                                                |
| 121 |    264.688472 |    562.840871 | Michelle Site                                                                                                                                                |
| 122 |    970.146060 |    307.762968 | Zimices                                                                                                                                                      |
| 123 |    769.922220 |    559.118596 | Jaime Headden                                                                                                                                                |
| 124 |    460.591683 |    465.837061 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                               |
| 125 |    302.072920 |     29.356983 | Matt Crook                                                                                                                                                   |
| 126 |   1007.673871 |    496.254540 | Dantheman9758 (vectorized by T. Michael Keesey)                                                                                                              |
| 127 |    151.972411 |    314.005097 | Sharon Wegner-Larsen                                                                                                                                         |
| 128 |     59.145391 |    494.180805 | Gareth Monger                                                                                                                                                |
| 129 |    240.508547 |    608.166654 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                  |
| 130 |    866.820622 |    158.827302 | Matt Crook                                                                                                                                                   |
| 131 |    630.703039 |     18.409355 | L. Shyamal                                                                                                                                                   |
| 132 |    982.893688 |    788.485382 | Lisa Byrne                                                                                                                                                   |
| 133 |    491.203750 |    457.761846 | Jessica Rick                                                                                                                                                 |
| 134 |    581.162811 |    357.007966 | terngirl                                                                                                                                                     |
| 135 |    483.934191 |    165.537845 | Jack Mayer Wood                                                                                                                                              |
| 136 |    274.582495 |    497.966856 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                           |
| 137 |    155.054193 |    257.043837 | Matt Crook                                                                                                                                                   |
| 138 |    905.299651 |    103.884771 | DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).                                                                                                |
| 139 |    316.175354 |    436.288469 | Emily Willoughby                                                                                                                                             |
| 140 |    242.172303 |    788.254162 | Cesar Julian                                                                                                                                                 |
| 141 |    727.342546 |    327.851772 | Zimices                                                                                                                                                      |
| 142 |    879.942767 |    361.925803 | Alexander Schmidt-Lebuhn                                                                                                                                     |
| 143 |    669.474651 |    481.133924 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                           |
| 144 |     21.267435 |    699.210076 | Andy Wilson                                                                                                                                                  |
| 145 |    750.530965 |    425.880046 | Myriam\_Ramirez                                                                                                                                              |
| 146 |    460.228865 |    557.003563 | NA                                                                                                                                                           |
| 147 |     36.269865 |    525.664461 | Gabriela Palomo-Munoz                                                                                                                                        |
| 148 |    802.636288 |    213.396044 | Tasman Dixon                                                                                                                                                 |
| 149 |    857.895118 |    457.844918 | Zimices                                                                                                                                                      |
| 150 |    885.658426 |    124.467656 | Martin R. Smith, after Skovsted et al 2015                                                                                                                   |
| 151 |    596.363478 |    422.295262 | Scott Hartman                                                                                                                                                |
| 152 |    464.012883 |    742.637768 | Pedro de Siracusa                                                                                                                                            |
| 153 |    788.355050 |    754.029328 | Steven Traver                                                                                                                                                |
| 154 |    311.477221 |    593.663333 | Zimices                                                                                                                                                      |
| 155 |   1003.700354 |    157.393705 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                  |
| 156 |    753.213967 |    778.139096 | Dean Schnabel                                                                                                                                                |
| 157 |    805.870159 |     19.089463 | Tracy A. Heath                                                                                                                                               |
| 158 |    877.176005 |     80.127300 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                  |
| 159 |     13.184184 |    400.521103 | Tyler Greenfield                                                                                                                                             |
| 160 |    797.706243 |    652.980225 | Michelle Site                                                                                                                                                |
| 161 |    828.511859 |    782.994738 | T. Michael Keesey                                                                                                                                            |
| 162 |    471.673677 |    195.439461 | Birgit Lang                                                                                                                                                  |
| 163 |    106.867091 |    719.756213 | Jagged Fang Designs                                                                                                                                          |
| 164 |    502.451804 |    169.805451 | Zimices                                                                                                                                                      |
| 165 |    978.921633 |     13.725266 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                          |
| 166 |    896.125838 |    500.841673 | Sarah Werning                                                                                                                                                |
| 167 |    295.967921 |    242.251765 | Jagged Fang Designs                                                                                                                                          |
| 168 |    740.333489 |    664.666657 | Gareth Monger                                                                                                                                                |
| 169 |    882.441994 |    236.194819 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 170 |    868.767802 |     60.466623 | Melissa Ingala                                                                                                                                               |
| 171 |   1008.702114 |    314.640672 | Jesús Gómez, vectorized by Zimices                                                                                                                           |
| 172 |    712.650704 |    388.590827 | Óscar San-Isidro (vectorized by T. Michael Keesey)                                                                                                           |
| 173 |    692.777110 |    310.888615 | Steven Traver                                                                                                                                                |
| 174 |    590.387286 |    756.784763 | Ferran Sayol                                                                                                                                                 |
| 175 |    423.016590 |    491.316771 | Cesar Julian                                                                                                                                                 |
| 176 |   1001.401650 |    713.153825 | Kamil S. Jaron                                                                                                                                               |
| 177 |    992.787875 |    416.957365 | Steven Traver                                                                                                                                                |
| 178 |    470.948552 |    408.498445 | Caio Bernardes, vectorized by Zimices                                                                                                                        |
| 179 |    179.970752 |    398.245396 | Dean Schnabel                                                                                                                                                |
| 180 |    302.122271 |    268.979611 | Tasman Dixon                                                                                                                                                 |
| 181 |     18.206120 |    543.622709 | Mali’o Kodis, image from the Biodiversity Heritage Library                                                                                                   |
| 182 |    295.211300 |    784.948219 | Mali’o Kodis, photograph from Jersabek et al, 2003                                                                                                           |
| 183 |    798.067244 |    146.977297 | Gareth Monger                                                                                                                                                |
| 184 |    271.713699 |    267.263708 | NA                                                                                                                                                           |
| 185 |    153.478815 |    789.296855 | NA                                                                                                                                                           |
| 186 |    209.816920 |    387.943051 | Chase Brownstein                                                                                                                                             |
| 187 |    111.243403 |    362.753058 | Mariana Ruiz Villarreal                                                                                                                                      |
| 188 |    908.673504 |    527.739812 | Beth Reinke                                                                                                                                                  |
| 189 |    157.538819 |    128.717489 | Matt Martyniuk                                                                                                                                               |
| 190 |    335.963914 |    696.048682 | Zimices                                                                                                                                                      |
| 191 |    627.716632 |    114.317824 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                       |
| 192 |    147.243633 |    546.735153 | Michelle Site                                                                                                                                                |
| 193 |    985.753264 |    534.722763 | Jaime Headden                                                                                                                                                |
| 194 |    450.645270 |      9.493981 | Margot Michaud                                                                                                                                               |
| 195 |    710.127772 |    646.304779 | Matt Crook                                                                                                                                                   |
| 196 |    170.780172 |    156.575734 | Maija Karala                                                                                                                                                 |
| 197 |    448.188721 |    308.232398 | Steven Traver                                                                                                                                                |
| 198 |     66.242414 |     78.325332 | Margot Michaud                                                                                                                                               |
| 199 |    318.852294 |    221.676387 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                              |
| 200 |    222.445009 |    435.966258 | Matt Crook                                                                                                                                                   |
| 201 |    134.812411 |    729.595108 | Gabriela Palomo-Munoz                                                                                                                                        |
| 202 |    175.745533 |    521.470622 | Lani Mohan                                                                                                                                                   |
| 203 |    567.095557 |    111.705443 | Ryan Cupo                                                                                                                                                    |
| 204 |    154.110122 |    351.925111 | Daniel Jaron                                                                                                                                                 |
| 205 |    934.949804 |    756.801676 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                            |
| 206 |     59.645208 |    774.802734 | Matthew E. Clapham                                                                                                                                           |
| 207 |    442.862218 |    694.400860 | Noah Schlottman                                                                                                                                              |
| 208 |    416.455815 |    555.619467 | Zimices                                                                                                                                                      |
| 209 |     33.708197 |    323.744758 | Mathew Wedel                                                                                                                                                 |
| 210 |    396.857611 |    751.591069 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                 |
| 211 |   1000.535150 |    651.323560 | Agnello Picorelli                                                                                                                                            |
| 212 |    520.308467 |    312.278115 | Berivan Temiz                                                                                                                                                |
| 213 |    190.918038 |    759.313677 | Andy Wilson                                                                                                                                                  |
| 214 |    342.557729 |    208.162093 | Brian Gratwicke (photo) and T. Michael Keesey (vectorization)                                                                                                |
| 215 |      8.211483 |    626.481397 | Felix Vaux                                                                                                                                                   |
| 216 |    218.341145 |    352.952591 | Zimices                                                                                                                                                      |
| 217 |    890.563494 |     14.509808 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 218 |    733.629713 |     81.543678 | Markus A. Grohme                                                                                                                                             |
| 219 |    236.552216 |    227.510925 | Gareth Monger                                                                                                                                                |
| 220 |     71.252739 |    323.367549 | Carlos Cano-Barbacil                                                                                                                                         |
| 221 |     23.166114 |    117.965760 | Matt Crook                                                                                                                                                   |
| 222 |    445.144604 |    663.689318 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                        |
| 223 |    675.239427 |    171.985836 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 224 |     12.872853 |    342.469971 | Benjamint444                                                                                                                                                 |
| 225 |    730.412507 |    305.883163 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                  |
| 226 |    429.697042 |    385.896954 | T. Michael Keesey                                                                                                                                            |
| 227 |    115.998038 |    469.643309 | NA                                                                                                                                                           |
| 228 |    896.918170 |    177.186565 | Matt Crook                                                                                                                                                   |
| 229 |    480.305180 |    707.407788 | Felix Vaux and Steven A. Trewick                                                                                                                             |
| 230 |    383.049593 |      6.888590 | G. M. Woodward                                                                                                                                               |
| 231 |    151.843770 |    367.084489 | Margot Michaud                                                                                                                                               |
| 232 |    765.249361 |    286.021542 | M Kolmann                                                                                                                                                    |
| 233 |    794.668498 |    115.779531 | Steven Traver                                                                                                                                                |
| 234 |    170.844840 |    588.786857 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                 |
| 235 |    978.118905 |    118.876139 | Birgit Lang                                                                                                                                                  |
| 236 |    797.299519 |    780.550466 | Zimices                                                                                                                                                      |
| 237 |    893.922064 |    642.779055 | Margot Michaud                                                                                                                                               |
| 238 |    605.032373 |     27.890625 | L. Shyamal                                                                                                                                                   |
| 239 |    738.474318 |     22.794212 | Michelle Site                                                                                                                                                |
| 240 |    136.258198 |    773.987415 | Chris huh                                                                                                                                                    |
| 241 |    296.153267 |    349.395580 | Zimices                                                                                                                                                      |
| 242 |    662.759798 |    247.696673 | Warren H (photography), T. Michael Keesey (vectorization)                                                                                                    |
| 243 |    681.379442 |     28.264411 | SecretJellyMan                                                                                                                                               |
| 244 |    241.674538 |    387.004055 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                             |
| 245 |    408.087929 |    218.034640 | Scott Hartman                                                                                                                                                |
| 246 |    699.357701 |    500.856174 | NA                                                                                                                                                           |
| 247 |    445.548233 |    152.664344 | Steven Traver                                                                                                                                                |
| 248 |    689.426975 |    293.703552 | Steven Traver                                                                                                                                                |
| 249 |    285.546208 |    622.674312 | Harold N Eyster                                                                                                                                              |
| 250 |    391.934075 |    529.190647 | Matt Crook                                                                                                                                                   |
| 251 |    858.540330 |      8.678795 | Gabriela Palomo-Munoz                                                                                                                                        |
| 252 |     24.948812 |    293.325295 | Kamil S. Jaron                                                                                                                                               |
| 253 |    180.101491 |    782.587491 | B. Duygu Özpolat                                                                                                                                             |
| 254 |    226.274715 |    405.714467 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                                   |
| 255 |    677.169905 |    120.892605 | Inessa Voet                                                                                                                                                  |
| 256 |    534.184389 |    553.106282 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                              |
| 257 |    871.693125 |    430.129930 | Matt Crook                                                                                                                                                   |
| 258 |    433.917322 |    354.382385 | Gareth Monger                                                                                                                                                |
| 259 |     24.369563 |    606.740465 | Zimices                                                                                                                                                      |
| 260 |     64.563132 |    368.099707 | Collin Gross                                                                                                                                                 |
| 261 |     97.756130 |    699.803463 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 262 |    655.051259 |    490.901420 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                  |
| 263 |    264.922166 |    674.382890 | Emily Willoughby                                                                                                                                             |
| 264 |    906.395354 |    773.150082 | T. Tischler                                                                                                                                                  |
| 265 |    744.325503 |     97.281915 | Zimices                                                                                                                                                      |
| 266 |    134.816273 |     65.180301 | Gareth Monger                                                                                                                                                |
| 267 |    992.401086 |    400.012905 | Carlos Cano-Barbacil                                                                                                                                         |
| 268 |    376.233020 |    606.801199 | Scott Hartman                                                                                                                                                |
| 269 |   1007.213829 |    752.918767 | Maxime Dahirel                                                                                                                                               |
| 270 |   1006.173884 |    102.296229 | Matt Crook                                                                                                                                                   |
| 271 |    522.403407 |    785.594019 | Collin Gross                                                                                                                                                 |
| 272 |    578.340374 |     72.979510 | Margot Michaud                                                                                                                                               |
| 273 |    701.667730 |    469.477109 | Scott Hartman                                                                                                                                                |
| 274 |    351.446469 |    580.926453 | New York Zoological Society                                                                                                                                  |
| 275 |   1008.654529 |    129.395533 | Mali’o Kodis, photograph by G. Giribet                                                                                                                       |
| 276 |    932.255091 |     15.594687 | Matt Crook                                                                                                                                                   |
| 277 |    482.210698 |    795.916139 | Gareth Monger                                                                                                                                                |
| 278 |    523.681517 |    250.679115 | CNZdenek                                                                                                                                                     |
| 279 |    564.134090 |     69.176449 | Mali’o Kodis, photograph by G. Giribet                                                                                                                       |
| 280 |    803.556414 |    465.377696 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                           |
| 281 |    583.625637 |    480.776703 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                   |
| 282 |    929.144434 |    789.271181 | Milton Tan                                                                                                                                                   |
| 283 |    705.590620 |    413.260890 | Yan Wong                                                                                                                                                     |
| 284 |    868.797991 |    578.205669 | Chris huh                                                                                                                                                    |
| 285 |     14.950209 |    486.103313 | NA                                                                                                                                                           |
| 286 |    419.968218 |    725.637273 | L. Shyamal                                                                                                                                                   |
| 287 |    710.136291 |     74.237922 | Emily Willoughby                                                                                                                                             |
| 288 |    771.476539 |    711.011217 | Tasman Dixon                                                                                                                                                 |
| 289 |    201.651202 |    511.569150 | Becky Barnes                                                                                                                                                 |
| 290 |    803.597023 |    388.053482 | Gabriela Palomo-Munoz                                                                                                                                        |
| 291 |    534.526061 |    103.719935 | Ferran Sayol                                                                                                                                                 |
| 292 |    523.534346 |    499.284595 | Pranav Iyer (grey ideas)                                                                                                                                     |
| 293 |    711.328538 |    673.464568 | Jagged Fang Designs                                                                                                                                          |
| 294 |    673.383146 |    400.975395 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                  |
| 295 |    251.586893 |     86.778206 | Matt Crook                                                                                                                                                   |
| 296 |    404.413507 |    142.634446 | Francis de Laporte de Castelnau (vectorized by T. Michael Keesey)                                                                                            |
| 297 |    307.881634 |     65.622718 | Steven Traver                                                                                                                                                |
| 298 |     18.409622 |    452.232850 | Gareth Monger                                                                                                                                                |
| 299 |    712.928933 |    780.911801 | Ingo Braasch                                                                                                                                                 |
| 300 |    382.683160 |    376.921046 | Scott Hartman                                                                                                                                                |
| 301 |     18.578490 |     78.254516 | Steven Traver                                                                                                                                                |
| 302 |    926.141043 |    291.865162 | FunkMonk                                                                                                                                                     |
| 303 |    289.361346 |      6.517543 | Gareth Monger                                                                                                                                                |
| 304 |     73.847706 |     18.459151 | Ferran Sayol                                                                                                                                                 |
| 305 |    517.203561 |    458.801854 | Dean Schnabel                                                                                                                                                |
| 306 |    734.677531 |    575.373057 | Markus A. Grohme                                                                                                                                             |
| 307 |    716.179462 |    659.634680 | Margot Michaud                                                                                                                                               |
| 308 |    916.540987 |    734.089170 | Steven Traver                                                                                                                                                |
| 309 |    330.094166 |    256.877116 | NA                                                                                                                                                           |
| 310 |    636.175498 |     39.871455 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 311 |    171.580255 |    495.250467 | Zimices                                                                                                                                                      |
| 312 |    393.901333 |    775.629076 | Ghedo and T. Michael Keesey                                                                                                                                  |
| 313 |    693.918249 |    339.206543 | Collin Gross                                                                                                                                                 |
| 314 |     32.017929 |    407.625876 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                 |
| 315 |    446.458071 |    526.569814 | Zimices                                                                                                                                                      |
| 316 |    338.562660 |    504.412720 | CNZdenek                                                                                                                                                     |
| 317 |    513.579742 |    419.841092 | Felix Vaux                                                                                                                                                   |
| 318 |    232.894558 |    108.943678 | NA                                                                                                                                                           |
| 319 |    300.233598 |    687.742801 | Maija Karala                                                                                                                                                 |
| 320 |    403.567314 |    675.380909 | Yan Wong from illustration by Charles Orbigny                                                                                                                |
| 321 |     21.068004 |    791.781921 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                     |
| 322 |    477.070611 |    784.633880 | Anthony Caravaggi                                                                                                                                            |
| 323 |    579.056569 |     40.633773 | Michelle Site                                                                                                                                                |
| 324 |    835.637241 |    367.110678 | Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 325 |    846.327067 |    418.143156 | Zimices                                                                                                                                                      |
| 326 |    830.059823 |     59.973201 | Zimices                                                                                                                                                      |
| 327 |    414.436001 |    409.091605 | Jagged Fang Designs                                                                                                                                          |
| 328 |    601.730979 |    322.107477 | Noah Schlottman, photo by Antonio Guillén                                                                                                                    |
| 329 |    359.781304 |    683.253959 | Ferran Sayol                                                                                                                                                 |
| 330 |    842.859933 |    770.865539 | Michelle Site                                                                                                                                                |
| 331 |    944.511710 |    176.546548 | T. Tischler                                                                                                                                                  |
| 332 |    765.729205 |    669.553347 | Scott Hartman                                                                                                                                                |
| 333 |    476.839364 |    583.302429 | Scott Hartman                                                                                                                                                |
| 334 |    178.588941 |    229.508814 | Matt Dempsey                                                                                                                                                 |
| 335 |    824.466140 |    601.970469 | Diana Pomeroy                                                                                                                                                |
| 336 |    927.530445 |    413.830344 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 337 |    257.829258 |    618.557976 | Gareth Monger                                                                                                                                                |
| 338 |    984.643573 |    517.570881 | Nobu Tamura                                                                                                                                                  |
| 339 |    123.324810 |    659.508565 | Pete Buchholz                                                                                                                                                |
| 340 |    737.320227 |    430.626714 | Cagri Cevrim                                                                                                                                                 |
| 341 |    326.324783 |    773.849191 | Matt Martyniuk                                                                                                                                               |
| 342 |    564.756404 |     90.870024 | NA                                                                                                                                                           |
| 343 |    903.006850 |    573.726825 | Collin Gross                                                                                                                                                 |
| 344 |    784.794864 |    605.085571 | Gareth Monger                                                                                                                                                |
| 345 |    573.956989 |    302.008343 | Michelle Site                                                                                                                                                |
| 346 |    398.104055 |     26.745652 | Zimices                                                                                                                                                      |
| 347 |    606.537546 |    439.387067 | NA                                                                                                                                                           |
| 348 |    810.928385 |    739.587115 | Jagged Fang Designs                                                                                                                                          |
| 349 |    945.351245 |    396.602272 | Erika Schumacher                                                                                                                                             |
| 350 |    858.942151 |    535.144542 | Felix Vaux                                                                                                                                                   |
| 351 |    153.323227 |    612.907201 | Scott Reid                                                                                                                                                   |
| 352 |    782.480343 |    228.468721 | Iain Reid                                                                                                                                                    |
| 353 |     71.079380 |    456.309156 | Tambja (vectorized by T. Michael Keesey)                                                                                                                     |
| 354 |    111.167412 |    772.903832 | Zimices                                                                                                                                                      |
| 355 |    734.295768 |     44.724529 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                          |
| 356 |    852.661982 |     39.704382 | Margot Michaud                                                                                                                                               |
| 357 |    331.126481 |    710.908029 | Jagged Fang Designs                                                                                                                                          |
| 358 |    447.542942 |    554.142371 | T. Michael Keesey                                                                                                                                            |
| 359 |     33.406477 |     14.341757 | Becky Barnes                                                                                                                                                 |
| 360 |    450.968561 |    171.206525 | Scott Hartman                                                                                                                                                |
| 361 |    139.508523 |    235.399441 | Zimices                                                                                                                                                      |
| 362 |    905.660833 |    317.746952 | Christian A. Masnaghetti                                                                                                                                     |
| 363 |    322.524152 |    305.838750 | Scott Hartman                                                                                                                                                |
| 364 |    784.680352 |    538.916370 | Markus A. Grohme                                                                                                                                             |
| 365 |    990.419036 |     87.576389 | Armin Reindl                                                                                                                                                 |
| 366 |    768.880513 |    793.250665 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                         |
| 367 |    766.019312 |     83.251041 | Markus A. Grohme                                                                                                                                             |
| 368 |    575.510165 |     10.178335 | Jose Carlos Arenas-Monroy                                                                                                                                    |
| 369 |   1001.349564 |    568.510301 | Andy Wilson                                                                                                                                                  |
| 370 |    864.485583 |    368.621031 | Ferran Sayol                                                                                                                                                 |
| 371 |    874.688250 |    786.561108 | Scott Hartman                                                                                                                                                |
| 372 |    991.551568 |    505.381657 | Scott Hartman                                                                                                                                                |
| 373 |    475.018954 |    140.361427 | Sharon Wegner-Larsen                                                                                                                                         |
| 374 |    598.756408 |     88.892594 | Markus A. Grohme                                                                                                                                             |
| 375 |    650.580258 |    455.398280 | Sarah Werning                                                                                                                                                |
| 376 |    970.269655 |    236.493492 | Charles R. Knight, vectorized by Zimices                                                                                                                     |
| 377 |    967.544992 |    284.022943 | Birgit Lang                                                                                                                                                  |
| 378 |     21.853135 |    142.973075 | Pranav Iyer (grey ideas)                                                                                                                                     |
| 379 |    552.133720 |    501.119945 | NA                                                                                                                                                           |
| 380 |   1013.062122 |    526.920512 | Gareth Monger                                                                                                                                                |
| 381 |    357.411229 |    562.944320 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                     |
| 382 |    589.061611 |    336.743190 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 383 |    562.529797 |    320.326970 | Margot Michaud                                                                                                                                               |
| 384 |    143.382114 |    564.960489 | Scott Hartman                                                                                                                                                |
| 385 |    133.794364 |    332.583314 | M Kolmann                                                                                                                                                    |
| 386 |     12.409955 |     26.717931 | Margot Michaud                                                                                                                                               |
| 387 |    286.843629 |    225.049583 | Chris huh                                                                                                                                                    |
| 388 |    709.043340 |     11.616227 | Margot Michaud                                                                                                                                               |
| 389 |    496.037438 |    184.041988 | Chris huh                                                                                                                                                    |
| 390 |    831.522839 |    160.340272 | Ferran Sayol                                                                                                                                                 |
| 391 |     25.522013 |    666.517839 | Matt Crook                                                                                                                                                   |
| 392 |    490.092139 |    308.242199 | Martin R. Smith                                                                                                                                              |
| 393 |    536.313184 |    477.745941 | Gabriela Palomo-Munoz                                                                                                                                        |
| 394 |     82.354290 |    783.271061 | Kai R. Caspar                                                                                                                                                |
| 395 |    124.493694 |    490.381446 | NA                                                                                                                                                           |
| 396 |    256.083812 |    773.386111 | Zimices                                                                                                                                                      |
| 397 |    677.805350 |    785.592317 | Yan Wong                                                                                                                                                     |
| 398 |    344.360087 |    311.058738 | Matt Crook                                                                                                                                                   |
| 399 |    129.740425 |    276.079370 | Noah Schlottman, photo by Casey Dunn                                                                                                                         |
| 400 |   1008.239398 |    250.048177 | Darius Nau                                                                                                                                                   |
| 401 |    495.822503 |    156.949314 | Gabriela Palomo-Munoz                                                                                                                                        |
| 402 |    107.496167 |    320.328574 | Robert Gay                                                                                                                                                   |
| 403 |    261.516265 |    103.386077 | T. Michael Keesey                                                                                                                                            |
| 404 |    377.184966 |    432.649258 | Robert Bruce Horsfall (vectorized by William Gearty)                                                                                                         |
| 405 |    508.617212 |     42.218864 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                 |
| 406 |    988.626108 |    641.663631 | Bruno Maggia                                                                                                                                                 |
| 407 |    196.309870 |    129.169791 | Chris huh                                                                                                                                                    |
| 408 |    410.522511 |    353.749809 | Dean Schnabel                                                                                                                                                |
| 409 |    429.636638 |    793.566794 | Andrew A. Farke                                                                                                                                              |
| 410 |    729.585316 |    339.360113 | NA                                                                                                                                                           |
| 411 |    743.319491 |    791.460998 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 412 |     41.577897 |     96.503899 | Gareth Monger                                                                                                                                                |
| 413 |    655.174407 |    760.221961 | Cristina Guijarro                                                                                                                                            |
| 414 |    205.137556 |     49.619676 | Dean Schnabel                                                                                                                                                |
| 415 |     19.156213 |    194.323133 | Steven Traver                                                                                                                                                |
| 416 |   1004.415554 |    661.257329 | Chris huh                                                                                                                                                    |
| 417 |    567.967378 |    780.732060 | Jessica Anne Miller                                                                                                                                          |
| 418 |    388.708773 |    783.847383 | Chris huh                                                                                                                                                    |
| 419 |    287.948237 |    424.459768 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                |
| 420 |    804.158496 |    555.498980 | Darius Nau                                                                                                                                                   |
| 421 |    981.235539 |     95.162807 | Tony Ayling                                                                                                                                                  |
| 422 |    772.322131 |     10.740646 | T. Michael Keesey                                                                                                                                            |
| 423 |    143.338939 |    524.139889 | T. K. Robinson                                                                                                                                               |
| 424 |     28.922178 |    430.450098 | Chris huh                                                                                                                                                    |
| 425 |    832.989103 |    221.025943 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                              |
| 426 |    520.255158 |    151.534672 | Iain Reid                                                                                                                                                    |
| 427 |    355.470560 |    193.387914 | Scott Hartman                                                                                                                                                |
| 428 |   1008.558977 |    397.017385 | Gareth Monger                                                                                                                                                |
| 429 |    246.103421 |    361.996243 | Gareth Monger                                                                                                                                                |
| 430 |    970.455424 |    245.479696 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                       |
| 431 |    458.188656 |    692.710054 | T. Michael Keesey                                                                                                                                            |
| 432 |    902.645627 |    208.602440 | Dean Schnabel                                                                                                                                                |
| 433 |    834.039173 |    581.899801 | Renata F. Martins                                                                                                                                            |
| 434 |    767.341460 |    467.053887 | Emily Jane McTavish                                                                                                                                          |
| 435 |    458.783470 |    387.814582 | \<U+0412\>\<U+0430\>\<U+043B\>\<U+044C\>\<U+0434\>\<U+0438\>\<U+043C\>\<U+0430\>\<U+0440\> (vectorized by T. Michael Keesey)                                 |
| 436 |    721.952014 |    612.036149 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                  |
| 437 |    657.571792 |    724.977576 | Michael P. Taylor                                                                                                                                            |
| 438 |    421.926910 |     17.752861 | Smokeybjb (modified by Mike Keesey)                                                                                                                          |
| 439 |    180.925569 |    343.849745 | Jagged Fang Designs                                                                                                                                          |
| 440 |    377.408258 |    298.230113 | Kamil S. Jaron                                                                                                                                               |
| 441 |    914.141246 |    645.174950 | zoosnow                                                                                                                                                      |
| 442 |    277.550254 |     44.549806 | Chris huh                                                                                                                                                    |
| 443 |    620.619154 |    402.533478 | Scott Hartman                                                                                                                                                |
| 444 |    388.146416 |    267.870617 | Joanna Wolfe                                                                                                                                                 |
| 445 |    249.590517 |    207.455123 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                               |
| 446 |    897.649291 |    484.861150 | Gareth Monger                                                                                                                                                |
| 447 |    730.405281 |    769.736941 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                |
| 448 |    991.594897 |    765.985545 | T. Michael Keesey                                                                                                                                            |
| 449 |    259.850470 |    222.524549 | Margot Michaud                                                                                                                                               |
| 450 |    360.420630 |    227.384449 | Steven Traver                                                                                                                                                |
| 451 |    845.920662 |    613.068805 | Smokeybjb                                                                                                                                                    |
| 452 |    519.270426 |    295.625583 | Margot Michaud                                                                                                                                               |
| 453 |    706.065050 |    347.918889 | Dmitry Bogdanov                                                                                                                                              |
| 454 |    362.744968 |    371.510579 | Jagged Fang Designs                                                                                                                                          |
| 455 |     76.536433 |    794.561361 | Noah Schlottman, photo from Casey Dunn                                                                                                                       |
| 456 |    613.284238 |    470.261230 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 457 |    127.915006 |    788.899222 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                  |
| 458 |    172.570583 |    191.793594 | Melissa Ingala                                                                                                                                               |
| 459 |    352.766144 |    115.276292 | Jagged Fang Designs                                                                                                                                          |
| 460 |     15.015491 |    272.745411 | Jagged Fang Designs                                                                                                                                          |
| 461 |    644.187263 |      7.931447 | Steven Traver                                                                                                                                                |
| 462 |    737.849294 |    567.733201 | Christine Axon                                                                                                                                               |
| 463 |   1003.344822 |    482.075651 | Steven Traver                                                                                                                                                |
| 464 |    716.196044 |    219.221577 | Ignacio Contreras                                                                                                                                            |
| 465 |    674.421767 |    406.595744 | T. Michael Keesey                                                                                                                                            |
| 466 |    908.996740 |    381.200346 | Jonathan Wells                                                                                                                                               |
| 467 |    384.906346 |    739.336184 | Markus A. Grohme                                                                                                                                             |
| 468 |    602.646832 |     77.094559 | Gareth Monger                                                                                                                                                |
| 469 |    694.973164 |    269.997116 | L. Shyamal                                                                                                                                                   |
| 470 |    852.873955 |    471.150465 | Jagged Fang Designs                                                                                                                                          |
| 471 |    722.195082 |    237.247242 | Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)                                                                                |
| 472 |    713.449555 |    192.917613 | NA                                                                                                                                                           |
| 473 |    981.255195 |    744.530662 | Cagri Cevrim                                                                                                                                                 |
| 474 |    601.442155 |    119.699013 | Mathilde Cordellier                                                                                                                                          |
| 475 |    669.913281 |    187.469355 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                     |
| 476 |     44.739889 |    125.557712 | Ferran Sayol                                                                                                                                                 |
| 477 |    216.186118 |    217.912632 | Smith609 and T. Michael Keesey                                                                                                                               |
| 478 |    917.880152 |    707.387367 | T. Michael Keesey                                                                                                                                            |
| 479 |    155.845369 |    715.066614 | Lafage                                                                                                                                                       |
| 480 |    720.509698 |    251.519989 | Steven Traver                                                                                                                                                |
| 481 |     18.307132 |    577.088835 | Dean Schnabel                                                                                                                                                |
| 482 |     67.776279 |    700.975259 | T. Michael Keesey                                                                                                                                            |
| 483 |    623.938471 |    782.389577 | Chris huh                                                                                                                                                    |
| 484 |    545.096040 |     20.998718 | Kamil S. Jaron                                                                                                                                               |
| 485 |    344.951569 |    128.334627 | Zimices                                                                                                                                                      |
| 486 |    773.513101 |    329.479972 | Ferran Sayol                                                                                                                                                 |
| 487 |    581.110332 |    247.356268 | Jagged Fang Designs                                                                                                                                          |
| 488 |    794.633567 |    664.920901 | Sarah Werning                                                                                                                                                |
| 489 |     92.525166 |    686.770332 | T. Michael Keesey                                                                                                                                            |
| 490 |    398.375502 |    421.560014 | Steven Traver                                                                                                                                                |
| 491 |   1010.825604 |     17.393563 | Ville Koistinen (vectorized by T. Michael Keesey)                                                                                                            |
| 492 |    388.890829 |    623.231479 | Margot Michaud                                                                                                                                               |
| 493 |    827.710935 |    182.650486 | Gabriela Palomo-Munoz                                                                                                                                        |
| 494 |     79.704625 |    279.472549 | Nobu Tamura                                                                                                                                                  |
| 495 |    236.430415 |      8.340710 | NA                                                                                                                                                           |
| 496 |     20.863191 |    646.222321 | Ferran Sayol                                                                                                                                                 |
| 497 |    763.645450 |     41.623885 | Geoff Shaw                                                                                                                                                   |
| 498 |    289.867475 |    572.069561 | Ignacio Contreras                                                                                                                                            |
| 499 |    905.202609 |    677.559270 | Tyler Greenfield                                                                                                                                             |
| 500 |    242.334699 |    594.081030 | Andrew A. Farke                                                                                                                                              |
| 501 |    175.023192 |    704.711354 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 502 |    716.035694 |    796.163706 | Markus A. Grohme                                                                                                                                             |
| 503 |    917.875410 |     75.986104 | Erika Schumacher                                                                                                                                             |
| 504 |    463.208144 |    295.214991 | Armin Reindl                                                                                                                                                 |
| 505 |    971.050182 |    409.085996 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                             |
| 506 |   1011.499855 |    600.268349 | Gareth Monger                                                                                                                                                |
| 507 |    530.708691 |    242.016337 | Andy Wilson                                                                                                                                                  |
| 508 |    276.592537 |    595.334827 | \[unknown\]                                                                                                                                                  |
| 509 |    437.119279 |    472.797767 | Gareth Monger                                                                                                                                                |
| 510 |    865.011799 |    125.703726 | Myriam\_Ramirez                                                                                                                                              |
| 511 |    139.393661 |    418.370212 | Michael Scroggie                                                                                                                                             |

    #> Your tweet has been posted!
