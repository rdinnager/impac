
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

Gabriela Palomo-Munoz, Ignacio Contreras, B. Duygu Özpolat, Matt Crook,
Steven Traver, Chloé Schmidt, Ferran Sayol, Scott Hartman, Erika
Schumacher, Nobu Tamura (vectorized by T. Michael Keesey), Margot
Michaud, Michael P. Taylor, Tasman Dixon, Gopal Murali, Andrew A. Farke,
Collin Gross, Mark Hannaford (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, T. Michael Keesey (vector) and Stuart
Halliday (photograph), Sam Fraser-Smith (vectorized by T. Michael
Keesey), Shyamal, Smokeybjb (modified by Mike Keesey), Jan A. Venter,
Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T.
Michael Keesey), FunkMonk, Milton Tan, Kamil S. Jaron, Thea Boodhoo
(photograph) and T. Michael Keesey (vectorization), Katie S. Collins,
Smokeybjb, vectorized by Zimices, Chris huh, T. Michael Keesey, Markus
A. Grohme, Matt Celeskey, Zimices, Jose Carlos Arenas-Monroy, Emily
Willoughby, Gareth Monger, Noah Schlottman, photo by Casey Dunn, C.
Camilo Julián-Caballero, Noah Schlottman, photo from Casey Dunn, Emily
Jane McTavish, from Haeckel, E. H. P. A. (1904).Kunstformen der Natur.
Bibliographisches, White Wolf, Maxime Dahirel, Sarah Alewijnse, Espen
Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell),
Christoph Schomburg, Yan Wong from illustration by Jules Richard (1907),
Michelle Site, Apokryltaros (vectorized by T. Michael Keesey),
Ghedoghedo (vectorized by T. Michael Keesey), Kai R. Caspar, Nobu
Tamura, Tess Linden, Sean McCann, Cesar Julian, Mathew Wedel, Martin
Kevil, Dexter R. Mardis, Thibaut Brunet, Beth Reinke, David Orr,
Lankester Edwin Ray (vectorized by T. Michael Keesey), Scott Hartman
(vectorized by William Gearty), Maija Karala, Birgit Lang, Konsta
Happonen, from a CC-BY-NC image by pelhonen on iNaturalist, Yan Wong,
Ghedo (vectorized by T. Michael Keesey), Tauana J. Cunha, Mason McNair,
Scott Reid, Roberto Díaz Sibaja, Jagged Fang Designs, Ray Simpson
(vectorized by T. Michael Keesey), Verdilak, Jaime Headden, T. Michael
Keesey (vectorization) and Tony Hisgett (photography), Pearson Scott
Foresman (vectorized by T. Michael Keesey), Yan Wong from wikipedia
drawing (PD: Pearson Scott Foresman), Rachel Shoop, Caleb M. Brown, Matt
Dempsey, Smith609 and T. Michael Keesey, Yan Wong from photo by Denes
Emoke, Andy Wilson, Mercedes Yrayzoz (vectorized by T. Michael Keesey),
Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael
Keesey., Noah Schlottman, photo by Reinhard Jahn, Andrew R. Gehrke,
Meliponicultor Itaymbere, Scarlet23 (vectorized by T. Michael Keesey),
T. Michael Keesey (photo by Bc999 \[Black crow\]), Nobu Tamura,
vectorized by Zimices, Chuanixn Yu, Rebecca Groom, Sharon Wegner-Larsen,
Emma Hughes, Juan Carlos Jerí, M. Antonio Todaro, Tobias Kånneby, Matteo
Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey), T.
Tischler, Armin Reindl, Ingo Braasch, Catherine Yasuda, Brockhaus and
Efron, DW Bapst (modified from Bulman, 1970), Patrick Fisher (vectorized
by T. Michael Keesey), Gustav Mützel, Manabu Sakamoto, Crystal Maier,
Acrocynus (vectorized by T. Michael Keesey), Xavier Giroux-Bougard,
Dmitry Bogdanov, Gordon E. Robertson, Alexander Schmidt-Lebuhn,
Smokeybjb, Dmitry Bogdanov (vectorized by T. Michael Keesey), S.Martini,
Maxwell Lefroy (vectorized by T. Michael Keesey), Jay Matternes,
vectorized by Zimices, Kanchi Nanjo, Walter Vladimir, Lily Hughes,
Francisco Gascó (modified by Michael P. Taylor), Aline M. Ghilardi,
Christina N. Hodson, Jessica Rick, Danny Cicchetti (vectorized by T.
Michael Keesey), Kristina Gagalova, 于川云, Roberto Diaz Sibaja, based on
Domser, SauropodomorphMonarch, CNZdenek, Zsoldos Márton (vectorized by
T. Michael Keesey), Abraão B. Leite, Geoff Shaw, Pranav Iyer (grey
ideas), Steven Coombs, Jiekun He, Sebastian Stabinger, Robert Gay, Chris
Jennings (Risiatto), Anthony Caravaggi, Mette Aumala, Carlos
Cano-Barbacil, Lafage, Noah Schlottman, photo by Martin V. Sørensen,
Skye McDavid, Luc Viatour (source photo) and Andreas Plank, Original
drawing by Antonov, vectorized by Roberto Díaz Sibaja, Mark Hofstetter
(vectorized by T. Michael Keesey), Harold N Eyster, David Tana, Chase
Brownstein, Amanda Katzer, Zachary Quigley, Robert Bruce Horsfall,
vectorized by Zimices, NOAA Great Lakes Environmental Research
Laboratory (illustration) and Timothy J. Bartley (silhouette), Manabu
Bessho-Uehara, Xavier A. Jenkins, Gabriel Ugueto, Julio Garza, Samanta
Orellana, Michael Scroggie, from original photograph by Gary M. Stolz,
USFWS (original photograph in public domain)., Jaime A. Headden
(vectorized by T. Michael Keesey), terngirl, Maxime Dahirel
(digitisation), Kees van Achterberg et al (doi:
10.3897/BDJ.8.e49017)(original publication), Julia B McHugh, Auckland
Museum and T. Michael Keesey, FunkMonk (Michael B. H.), Sarah Werning,
Andrés Sánchez, Mario Quevedo, Emily Jane McTavish, Nobu Tamura
(vectorized by A. Verrière), Abraão Leite, Joanna Wolfe, Kelly, Young
and Zhao (1972:figure 4), modified by Michael P. Taylor, M Hutchinson,
Trond R. Oskars, T. Michael Keesey (after A. Y. Ivantsov), Iain Reid, DW
Bapst (Modified from Bulman, 1964), Michael “FunkMonk” B. H. (vectorized
by T. Michael Keesey), Вальдимар (vectorized by T. Michael Keesey), Alex
Slavenko, Renata F. Martins, Matthew Hooge (vectorized by T. Michael
Keesey), Ghedo and T. Michael Keesey, Michele M Tobias, Jaime Headden,
modified by T. Michael Keesey, Jon Hill, Michael Scroggie

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                         |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    921.947667 |     21.084929 | Gabriela Palomo-Munoz                                                                                                                                          |
|   2 |    371.802973 |    316.803375 | Ignacio Contreras                                                                                                                                              |
|   3 |    778.409102 |    467.183141 | B. Duygu Özpolat                                                                                                                                               |
|   4 |    643.788810 |    217.381654 | Matt Crook                                                                                                                                                     |
|   5 |    120.366769 |    263.580916 | Steven Traver                                                                                                                                                  |
|   6 |    406.182041 |    685.374444 | Matt Crook                                                                                                                                                     |
|   7 |    931.925121 |    686.918761 | Chloé Schmidt                                                                                                                                                  |
|   8 |    687.905787 |    366.409002 | Ferran Sayol                                                                                                                                                   |
|   9 |    105.760629 |    729.967854 | Matt Crook                                                                                                                                                     |
|  10 |    195.528404 |    542.788154 | Steven Traver                                                                                                                                                  |
|  11 |    564.994467 |    304.130826 | Scott Hartman                                                                                                                                                  |
|  12 |    745.268730 |     56.533261 | Erika Schumacher                                                                                                                                               |
|  13 |    621.528880 |    527.923226 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
|  14 |    884.964951 |    150.376463 | Margot Michaud                                                                                                                                                 |
|  15 |    773.038788 |    112.299912 | Steven Traver                                                                                                                                                  |
|  16 |     90.446323 |    414.862614 | Michael P. Taylor                                                                                                                                              |
|  17 |     70.209360 |    640.869087 | Tasman Dixon                                                                                                                                                   |
|  18 |    544.990102 |    179.134024 | Gopal Murali                                                                                                                                                   |
|  19 |    250.509043 |    175.237175 | Andrew A. Farke                                                                                                                                                |
|  20 |    569.501135 |     59.022578 | Steven Traver                                                                                                                                                  |
|  21 |     64.005584 |    509.055915 | Collin Gross                                                                                                                                                   |
|  22 |    849.549512 |    335.521304 | Mark Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
|  23 |    744.116725 |    324.172195 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                    |
|  24 |    625.128070 |    671.332100 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                             |
|  25 |    750.305492 |    753.009411 | Shyamal                                                                                                                                                        |
|  26 |    427.373541 |     32.446348 | Smokeybjb (modified by Mike Keesey)                                                                                                                            |
|  27 |    862.736350 |    583.616297 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                            |
|  28 |    921.423863 |    224.114059 | FunkMonk                                                                                                                                                       |
|  29 |     98.896633 |    578.987799 | Milton Tan                                                                                                                                                     |
|  30 |     61.600412 |     84.776708 | Margot Michaud                                                                                                                                                 |
|  31 |    520.777478 |    388.766665 | Kamil S. Jaron                                                                                                                                                 |
|  32 |    420.698268 |    115.527534 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                |
|  33 |    924.648329 |    404.367966 | Katie S. Collins                                                                                                                                               |
|  34 |    275.959550 |     38.362562 | Smokeybjb, vectorized by Zimices                                                                                                                               |
|  35 |    385.635531 |    481.489312 | NA                                                                                                                                                             |
|  36 |    764.415722 |    655.155448 | Chris huh                                                                                                                                                      |
|  37 |    546.203508 |    652.110147 | Steven Traver                                                                                                                                                  |
|  38 |    591.563358 |    443.911244 | T. Michael Keesey                                                                                                                                              |
|  39 |    255.764805 |    404.344008 | Markus A. Grohme                                                                                                                                               |
|  40 |    789.536881 |    210.356889 | Matt Celeskey                                                                                                                                                  |
|  41 |    415.148649 |    563.522312 | Zimices                                                                                                                                                        |
|  42 |    210.080479 |    744.623073 | NA                                                                                                                                                             |
|  43 |    169.250678 |    367.286892 | Mark Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
|  44 |    176.786095 |     79.083036 | Jose Carlos Arenas-Monroy                                                                                                                                      |
|  45 |    873.716412 |    505.471096 | Emily Willoughby                                                                                                                                               |
|  46 |    851.885253 |    713.924467 | Gareth Monger                                                                                                                                                  |
|  47 |    231.437716 |    686.367824 | Markus A. Grohme                                                                                                                                               |
|  48 |    195.549198 |    448.957796 | Noah Schlottman, photo by Casey Dunn                                                                                                                           |
|  49 |    585.170848 |    777.532238 | C. Camilo Julián-Caballero                                                                                                                                     |
|  50 |    759.149081 |    610.924061 | Noah Schlottman, photo from Casey Dunn                                                                                                                         |
|  51 |    299.101130 |    619.757959 | Emily Jane McTavish, from Haeckel, E. H. P. A. (1904).Kunstformen der Natur. Bibliographisches                                                                 |
|  52 |    720.153510 |    558.399366 | Margot Michaud                                                                                                                                                 |
|  53 |    121.558886 |    146.163334 | NA                                                                                                                                                             |
|  54 |    425.313369 |    204.799406 | C. Camilo Julián-Caballero                                                                                                                                     |
|  55 |    893.437300 |    778.487817 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
|  56 |    966.991955 |    313.257443 | Noah Schlottman, photo from Casey Dunn                                                                                                                         |
|  57 |    954.367193 |    122.289949 | White Wolf                                                                                                                                                     |
|  58 |     55.432161 |    323.336156 | Maxime Dahirel                                                                                                                                                 |
|  59 |    507.380132 |    507.947862 | Sarah Alewijnse                                                                                                                                                |
|  60 |    515.255137 |    734.413663 | Scott Hartman                                                                                                                                                  |
|  61 |    593.245562 |    554.962675 | Scott Hartman                                                                                                                                                  |
|  62 |    618.569755 |    596.402529 | Markus A. Grohme                                                                                                                                               |
|  63 |    319.349659 |     88.766559 | Tasman Dixon                                                                                                                                                   |
|  64 |    716.899942 |    202.422068 | NA                                                                                                                                                             |
|  65 |    783.896587 |    511.903023 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                    |
|  66 |    156.077500 |     17.661258 | C. Camilo Julián-Caballero                                                                                                                                     |
|  67 |    322.745984 |    442.354675 | Matt Crook                                                                                                                                                     |
|  68 |    703.587525 |     15.160284 | Christoph Schomburg                                                                                                                                            |
|  69 |    722.687878 |    280.841744 | Yan Wong from illustration by Jules Richard (1907)                                                                                                             |
|  70 |    951.816270 |    745.383462 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
|  71 |    281.038091 |    505.793764 | Michelle Site                                                                                                                                                  |
|  72 |    964.095936 |    478.322864 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                 |
|  73 |    436.099882 |    391.408165 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
|  74 |    498.009741 |     99.618456 | Gabriela Palomo-Munoz                                                                                                                                          |
|  75 |    642.985309 |    130.063331 | Kai R. Caspar                                                                                                                                                  |
|  76 |   1003.500397 |    620.023966 | Gareth Monger                                                                                                                                                  |
|  77 |    899.218370 |     52.319863 | NA                                                                                                                                                             |
|  78 |    731.916233 |    694.862492 | Markus A. Grohme                                                                                                                                               |
|  79 |    737.289599 |    457.052320 | Noah Schlottman, photo by Casey Dunn                                                                                                                           |
|  80 |    454.153781 |    769.645227 | Scott Hartman                                                                                                                                                  |
|  81 |     85.681287 |    680.070087 | Nobu Tamura                                                                                                                                                    |
|  82 |    839.185597 |    240.826137 | NA                                                                                                                                                             |
|  83 |    472.494362 |    267.073081 | Chris huh                                                                                                                                                      |
|  84 |    194.305944 |    643.133005 | Scott Hartman                                                                                                                                                  |
|  85 |    810.709725 |    382.282363 | Zimices                                                                                                                                                        |
|  86 |    347.842495 |    232.990209 | Scott Hartman                                                                                                                                                  |
|  87 |    964.887988 |    629.705330 | Tess Linden                                                                                                                                                    |
|  88 |    341.391783 |    154.469547 | Sean McCann                                                                                                                                                    |
|  89 |    599.131299 |    733.817879 | Zimices                                                                                                                                                        |
|  90 |    181.204438 |    619.017354 | Cesar Julian                                                                                                                                                   |
|  91 |    924.653029 |     90.397747 | Chris huh                                                                                                                                                      |
|  92 |    699.121291 |    440.257433 | Mathew Wedel                                                                                                                                                   |
|  93 |     85.918535 |    448.013425 | Martin Kevil                                                                                                                                                   |
|  94 |    288.688525 |    779.113262 | Chris huh                                                                                                                                                      |
|  95 |    518.549283 |     26.339872 | Dexter R. Mardis                                                                                                                                               |
|  96 |    268.702709 |    230.454121 | Margot Michaud                                                                                                                                                 |
|  97 |    990.383513 |    541.144299 | Margot Michaud                                                                                                                                                 |
|  98 |    855.450465 |     82.580941 | Scott Hartman                                                                                                                                                  |
|  99 |    513.970927 |    268.581902 | Margot Michaud                                                                                                                                                 |
| 100 |    493.646239 |    140.789910 | Matt Crook                                                                                                                                                     |
| 101 |    314.771531 |    539.051293 | Thibaut Brunet                                                                                                                                                 |
| 102 |    250.476768 |    111.223663 | Katie S. Collins                                                                                                                                               |
| 103 |    883.236079 |    276.670410 | NA                                                                                                                                                             |
| 104 |    661.894253 |     69.353474 | Margot Michaud                                                                                                                                                 |
| 105 |     21.480488 |    771.653422 | Beth Reinke                                                                                                                                                    |
| 106 |    562.994079 |    621.937589 | David Orr                                                                                                                                                      |
| 107 |    482.609083 |     66.693963 | NA                                                                                                                                                             |
| 108 |    130.649484 |    648.208273 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                          |
| 109 |     22.510601 |    442.289127 | T. Michael Keesey                                                                                                                                              |
| 110 |    628.703299 |    377.481982 | Scott Hartman (vectorized by William Gearty)                                                                                                                   |
| 111 |     36.333124 |    149.711398 | NA                                                                                                                                                             |
| 112 |    574.585219 |    270.672522 | Markus A. Grohme                                                                                                                                               |
| 113 |    477.798054 |    736.494333 | Scott Hartman                                                                                                                                                  |
| 114 |    175.648772 |    716.881723 | Margot Michaud                                                                                                                                                 |
| 115 |    625.135553 |    288.188413 | Maija Karala                                                                                                                                                   |
| 116 |    728.125317 |    638.756823 | Markus A. Grohme                                                                                                                                               |
| 117 |    979.275985 |    586.723290 | Birgit Lang                                                                                                                                                    |
| 118 |     79.866265 |    175.260884 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                              |
| 119 |    494.923847 |    582.321086 | Matt Crook                                                                                                                                                     |
| 120 |    612.825264 |    495.328134 | Yan Wong                                                                                                                                                       |
| 121 |     35.055008 |    700.513451 | Gareth Monger                                                                                                                                                  |
| 122 |    128.935989 |    785.698028 | Matt Crook                                                                                                                                                     |
| 123 |    580.017842 |    691.049817 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                        |
| 124 |    665.784361 |    624.948118 | Chris huh                                                                                                                                                      |
| 125 |    164.247265 |    323.239334 | Tauana J. Cunha                                                                                                                                                |
| 126 |     54.894772 |     33.732739 | Zimices                                                                                                                                                        |
| 127 |    246.894698 |    361.739101 | Mason McNair                                                                                                                                                   |
| 128 |    287.004632 |    379.790821 | Scott Reid                                                                                                                                                     |
| 129 |     71.387821 |    722.631628 | Gareth Monger                                                                                                                                                  |
| 130 |    234.192990 |    655.434863 | Shyamal                                                                                                                                                        |
| 131 |    880.634623 |    187.403124 | Gareth Monger                                                                                                                                                  |
| 132 |    828.693003 |    730.329463 | Roberto Díaz Sibaja                                                                                                                                            |
| 133 |    610.046896 |    351.931685 | Jagged Fang Designs                                                                                                                                            |
| 134 |    832.504080 |    621.920979 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                  |
| 135 |    997.637568 |    489.948714 | Cesar Julian                                                                                                                                                   |
| 136 |     98.684709 |    352.156952 | Verdilak                                                                                                                                                       |
| 137 |    309.994521 |    679.415442 | Zimices                                                                                                                                                        |
| 138 |    968.790792 |      5.312379 | Jaime Headden                                                                                                                                                  |
| 139 |    996.209990 |     22.246637 | Kamil S. Jaron                                                                                                                                                 |
| 140 |    366.099535 |    106.400440 | Gabriela Palomo-Munoz                                                                                                                                          |
| 141 |    700.644234 |    758.238823 | Jagged Fang Designs                                                                                                                                            |
| 142 |     98.738615 |    388.409293 | Steven Traver                                                                                                                                                  |
| 143 |    200.326128 |    130.315753 | T. Michael Keesey (vectorization) and Tony Hisgett (photography)                                                                                               |
| 144 |    253.059265 |    301.988451 | NA                                                                                                                                                             |
| 145 |    369.928871 |    535.112769 | Steven Traver                                                                                                                                                  |
| 146 |    322.767441 |    555.760629 | Ferran Sayol                                                                                                                                                   |
| 147 |     63.393642 |    533.744269 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                       |
| 148 |    625.112354 |    398.725880 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                   |
| 149 |    111.041862 |    427.084420 | NA                                                                                                                                                             |
| 150 |    863.249549 |    102.780898 | Zimices                                                                                                                                                        |
| 151 |    392.555699 |    227.170379 | Rachel Shoop                                                                                                                                                   |
| 152 |    677.673608 |    538.698964 | Caleb M. Brown                                                                                                                                                 |
| 153 |    417.737505 |    530.840707 | Matt Dempsey                                                                                                                                                   |
| 154 |    819.745557 |    417.642173 | David Orr                                                                                                                                                      |
| 155 |   1009.298840 |     33.670996 | Smith609 and T. Michael Keesey                                                                                                                                 |
| 156 |    327.003908 |    215.684816 | Yan Wong from photo by Denes Emoke                                                                                                                             |
| 157 |    998.920047 |    371.998389 | Kamil S. Jaron                                                                                                                                                 |
| 158 |    380.607713 |    772.488562 | Andy Wilson                                                                                                                                                    |
| 159 |    430.154535 |    163.887359 | Birgit Lang                                                                                                                                                    |
| 160 |     24.322042 |    594.836189 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                             |
| 161 |    281.393225 |    699.515279 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                       |
| 162 |    315.617616 |    194.245999 | T. Michael Keesey                                                                                                                                              |
| 163 |    423.585502 |    357.029399 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                        |
| 164 |    524.324536 |    720.964191 | Markus A. Grohme                                                                                                                                               |
| 165 |    854.421806 |    427.189875 | Andrew R. Gehrke                                                                                                                                               |
| 166 |   1001.594926 |     91.506049 | Smokeybjb, vectorized by Zimices                                                                                                                               |
| 167 |    116.332962 |    188.255581 | Zimices                                                                                                                                                        |
| 168 |    897.468419 |    199.194183 | Matt Crook                                                                                                                                                     |
| 169 |    839.870079 |    681.801513 | Gabriela Palomo-Munoz                                                                                                                                          |
| 170 |    133.900775 |    759.724345 | Matt Crook                                                                                                                                                     |
| 171 |    747.165512 |    360.523376 | Tasman Dixon                                                                                                                                                   |
| 172 |    609.094479 |    194.229060 | Maija Karala                                                                                                                                                   |
| 173 |    212.340751 |    509.694474 | Meliponicultor Itaymbere                                                                                                                                       |
| 174 |    662.706401 |    787.765608 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                    |
| 175 |    643.638407 |     36.945010 | T. Michael Keesey (photo by Bc999 \[Black crow\])                                                                                                              |
| 176 |    267.013926 |    545.303752 | Beth Reinke                                                                                                                                                    |
| 177 |    158.870894 |    601.933041 | Margot Michaud                                                                                                                                                 |
| 178 |    788.607200 |    768.620229 | Zimices                                                                                                                                                        |
| 179 |    959.480773 |    160.125397 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                            |
| 180 |    787.633381 |    567.690038 | T. Michael Keesey                                                                                                                                              |
| 181 |    383.159321 |     61.795957 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 182 |    342.870705 |    193.821155 | Gareth Monger                                                                                                                                                  |
| 183 |    819.758919 |    262.134610 | Chuanixn Yu                                                                                                                                                    |
| 184 |    404.122835 |     51.604000 | NA                                                                                                                                                             |
| 185 |    359.211507 |    395.750840 | Zimices                                                                                                                                                        |
| 186 |    516.802267 |    457.720492 | Rebecca Groom                                                                                                                                                  |
| 187 |    597.644798 |     20.565207 | Zimices                                                                                                                                                        |
| 188 |    630.029742 |    179.885448 | Markus A. Grohme                                                                                                                                               |
| 189 |    517.674284 |    693.306581 | Jagged Fang Designs                                                                                                                                            |
| 190 |    682.573630 |    644.309217 | Sharon Wegner-Larsen                                                                                                                                           |
| 191 |    759.345609 |    247.111369 | Emma Hughes                                                                                                                                                    |
| 192 |    978.620432 |    782.834474 | Markus A. Grohme                                                                                                                                               |
| 193 |    807.473730 |    684.699045 | Margot Michaud                                                                                                                                                 |
| 194 |    363.367326 |    598.855428 | Gareth Monger                                                                                                                                                  |
| 195 |    829.262228 |    184.313856 | Andrew A. Farke                                                                                                                                                |
| 196 |    998.728158 |    717.685153 | Juan Carlos Jerí                                                                                                                                               |
| 197 |     37.923278 |    743.340088 | Zimices                                                                                                                                                        |
| 198 |    140.031016 |    550.960384 | Michelle Site                                                                                                                                                  |
| 199 |    788.610783 |    543.757224 | Kai R. Caspar                                                                                                                                                  |
| 200 |    120.810091 |    167.372198 | Markus A. Grohme                                                                                                                                               |
| 201 |    946.249966 |     63.492967 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                 |
| 202 |    788.536482 |    173.176758 | Andy Wilson                                                                                                                                                    |
| 203 |   1008.935063 |    345.669621 | Gabriela Palomo-Munoz                                                                                                                                          |
| 204 |     51.023836 |    422.734017 | Michelle Site                                                                                                                                                  |
| 205 |    563.130513 |    106.936052 | Steven Traver                                                                                                                                                  |
| 206 |    968.828112 |    179.277150 | FunkMonk                                                                                                                                                       |
| 207 |    113.909945 |    488.027605 | Gareth Monger                                                                                                                                                  |
| 208 |    780.980459 |    413.429577 | Matt Crook                                                                                                                                                     |
| 209 |    221.686847 |    461.897723 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                       |
| 210 |    117.343788 |    560.885072 | NA                                                                                                                                                             |
| 211 |    715.847677 |     41.454607 | Andy Wilson                                                                                                                                                    |
| 212 |    447.095714 |    604.934107 | T. Tischler                                                                                                                                                    |
| 213 |    827.359903 |    477.468818 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
| 214 |     34.867284 |    617.177158 | Tasman Dixon                                                                                                                                                   |
| 215 |    787.178497 |    268.558753 | Jagged Fang Designs                                                                                                                                            |
| 216 |    965.594792 |     75.394915 | Jagged Fang Designs                                                                                                                                            |
| 217 |    749.408477 |    163.268025 | Andy Wilson                                                                                                                                                    |
| 218 |    418.281855 |    607.694946 | Armin Reindl                                                                                                                                                   |
| 219 |    702.502224 |    588.809051 | Scott Hartman                                                                                                                                                  |
| 220 |     19.590912 |    316.919692 | NA                                                                                                                                                             |
| 221 |     66.226629 |    785.544149 | Zimices                                                                                                                                                        |
| 222 |    307.860022 |    393.018716 | Ingo Braasch                                                                                                                                                   |
| 223 |    726.039179 |    295.846515 | Catherine Yasuda                                                                                                                                               |
| 224 |     28.516178 |    569.678234 | Gabriela Palomo-Munoz                                                                                                                                          |
| 225 |    290.921416 |    721.187257 | Matt Crook                                                                                                                                                     |
| 226 |    493.488413 |    702.847261 | Brockhaus and Efron                                                                                                                                            |
| 227 |     76.175542 |    599.386960 | Steven Traver                                                                                                                                                  |
| 228 |    417.200188 |    262.851912 | Steven Traver                                                                                                                                                  |
| 229 |    148.490994 |    398.175024 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                       |
| 230 |    999.608726 |    406.837984 | Matt Crook                                                                                                                                                     |
| 231 |    507.961345 |    320.035269 | DW Bapst (modified from Bulman, 1970)                                                                                                                          |
| 232 |    688.672555 |    725.212604 | Rebecca Groom                                                                                                                                                  |
| 233 |     18.822306 |    380.868092 | Patrick Fisher (vectorized by T. Michael Keesey)                                                                                                               |
| 234 |    239.191365 |    483.797613 | Gustav Mützel                                                                                                                                                  |
| 235 |    452.941505 |    339.747181 | T. Michael Keesey                                                                                                                                              |
| 236 |    686.344744 |     40.354567 | Manabu Sakamoto                                                                                                                                                |
| 237 |    422.321253 |    415.795280 | Tasman Dixon                                                                                                                                                   |
| 238 |    406.930610 |    751.117780 | Margot Michaud                                                                                                                                                 |
| 239 |     20.737375 |    427.858746 | Gabriela Palomo-Munoz                                                                                                                                          |
| 240 |    474.754550 |    359.759769 | Margot Michaud                                                                                                                                                 |
| 241 |     62.937402 |     12.031205 | B. Duygu Özpolat                                                                                                                                               |
| 242 |    578.962494 |    493.385660 | Crystal Maier                                                                                                                                                  |
| 243 |    917.830246 |    457.663927 | Katie S. Collins                                                                                                                                               |
| 244 |    174.654537 |    179.665629 | Steven Traver                                                                                                                                                  |
| 245 |    346.048786 |    123.179315 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                    |
| 246 |    491.148865 |     42.938605 | Markus A. Grohme                                                                                                                                               |
| 247 |   1008.691718 |    123.007729 | Gareth Monger                                                                                                                                                  |
| 248 |    576.630276 |    381.205063 | Xavier Giroux-Bougard                                                                                                                                          |
| 249 |    311.784288 |    246.754278 | Dmitry Bogdanov                                                                                                                                                |
| 250 |    786.087074 |     11.537125 | Zimices                                                                                                                                                        |
| 251 |    710.826426 |    714.707786 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 252 |    646.899874 |    303.920777 | Gareth Monger                                                                                                                                                  |
| 253 |    633.661646 |    607.609932 | Chris huh                                                                                                                                                      |
| 254 |    349.482076 |     14.139372 | Gordon E. Robertson                                                                                                                                            |
| 255 |     18.622076 |    350.335436 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 256 |    558.605946 |    580.931202 | Scott Hartman                                                                                                                                                  |
| 257 |    924.991215 |    332.793641 | Matt Crook                                                                                                                                                     |
| 258 |    863.238483 |    741.472750 | Christoph Schomburg                                                                                                                                            |
| 259 |    985.652948 |    222.753577 | Smokeybjb                                                                                                                                                      |
| 260 |    755.310356 |    378.835273 | Jagged Fang Designs                                                                                                                                            |
| 261 |    445.536410 |    408.955590 | Scott Reid                                                                                                                                                     |
| 262 |    847.201442 |    740.428837 | Gareth Monger                                                                                                                                                  |
| 263 |    241.939656 |    207.471575 | Matt Crook                                                                                                                                                     |
| 264 |    231.132357 |    611.426733 | Zimices                                                                                                                                                        |
| 265 |    295.182981 |    424.816985 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 266 |    439.166377 |     71.892666 | Michelle Site                                                                                                                                                  |
| 267 |    689.711231 |    426.819438 | Margot Michaud                                                                                                                                                 |
| 268 |    999.786728 |    164.818910 | Armin Reindl                                                                                                                                                   |
| 269 |    144.834400 |    189.839092 | Gareth Monger                                                                                                                                                  |
| 270 |     44.469928 |    190.369034 | Margot Michaud                                                                                                                                                 |
| 271 |    245.440183 |    449.415227 | Zimices                                                                                                                                                        |
| 272 |    130.049812 |    604.553787 | S.Martini                                                                                                                                                      |
| 273 |    732.086536 |    788.714932 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                               |
| 274 |    875.455406 |    622.456762 | Andy Wilson                                                                                                                                                    |
| 275 |    758.876364 |    407.431721 | Katie S. Collins                                                                                                                                               |
| 276 |    982.119939 |    763.175655 | Jay Matternes, vectorized by Zimices                                                                                                                           |
| 277 |    270.639123 |    755.015256 | Chris huh                                                                                                                                                      |
| 278 |   1006.684946 |    248.723449 | Margot Michaud                                                                                                                                                 |
| 279 |    132.308145 |    107.878164 | Kanchi Nanjo                                                                                                                                                   |
| 280 |    850.276454 |    208.717689 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 281 |     48.415600 |    389.711522 | Walter Vladimir                                                                                                                                                |
| 282 |    667.649529 |    506.550905 | Lily Hughes                                                                                                                                                    |
| 283 |    132.121656 |    459.761756 | Yan Wong                                                                                                                                                       |
| 284 |     20.275193 |    282.324465 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                |
| 285 |    508.390437 |    546.782520 | Aline M. Ghilardi                                                                                                                                              |
| 286 |    914.833230 |    483.136866 | Matt Crook                                                                                                                                                     |
| 287 |    784.584032 |    787.384772 | Cesar Julian                                                                                                                                                   |
| 288 |    197.215567 |    785.642840 | Gabriela Palomo-Munoz                                                                                                                                          |
| 289 |    820.391187 |     66.283260 | Matt Crook                                                                                                                                                     |
| 290 |    976.448040 |    105.003461 | Zimices                                                                                                                                                        |
| 291 |    938.117865 |    568.685110 | Christina N. Hodson                                                                                                                                            |
| 292 |    241.231668 |    321.531669 | Jessica Rick                                                                                                                                                   |
| 293 |    845.240885 |     30.159181 | Margot Michaud                                                                                                                                                 |
| 294 |    147.734594 |    430.848207 | Margot Michaud                                                                                                                                                 |
| 295 |    148.324777 |    295.845337 | Chuanixn Yu                                                                                                                                                    |
| 296 |    457.699697 |    429.776160 | Zimices                                                                                                                                                        |
| 297 |    216.956540 |    716.007024 | Gabriela Palomo-Munoz                                                                                                                                          |
| 298 |    592.437677 |    711.946561 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                              |
| 299 |    535.580980 |    487.457631 | T. Michael Keesey                                                                                                                                              |
| 300 |    465.281690 |    395.588713 | Markus A. Grohme                                                                                                                                               |
| 301 |    268.013322 |    568.940974 | Chloé Schmidt                                                                                                                                                  |
| 302 |    868.258431 |    690.671970 | Kristina Gagalova                                                                                                                                              |
| 303 |    846.170762 |    291.070398 | Sean McCann                                                                                                                                                    |
| 304 |    590.676528 |    654.561470 | Kai R. Caspar                                                                                                                                                  |
| 305 |    709.142043 |    499.322563 | Mason McNair                                                                                                                                                   |
| 306 |    885.175743 |    253.926401 | Markus A. Grohme                                                                                                                                               |
| 307 |    876.397323 |    561.944480 | Gareth Monger                                                                                                                                                  |
| 308 |    788.162883 |    303.627265 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                       |
| 309 |    591.520982 |    565.462772 | Jagged Fang Designs                                                                                                                                            |
| 310 |    448.923911 |    166.476409 | Maxime Dahirel                                                                                                                                                 |
| 311 |    272.734452 |    665.013190 | NA                                                                                                                                                             |
| 312 |    728.113401 |    628.205624 | Jagged Fang Designs                                                                                                                                            |
| 313 |    694.367655 |    787.764144 | Gabriela Palomo-Munoz                                                                                                                                          |
| 314 |    158.923005 |    789.688628 | Birgit Lang                                                                                                                                                    |
| 315 |    692.344349 |    311.295874 | 于川云                                                                                                                                                            |
| 316 |    933.525632 |    189.600084 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 317 |    224.465069 |    338.466919 | Zimices                                                                                                                                                        |
| 318 |    643.946733 |    225.809581 | Roberto Diaz Sibaja, based on Domser                                                                                                                           |
| 319 |     18.118955 |    405.307110 | SauropodomorphMonarch                                                                                                                                          |
| 320 |    321.463122 |    413.119415 | Sean McCann                                                                                                                                                    |
| 321 |    881.096814 |    543.342536 | Matt Crook                                                                                                                                                     |
| 322 |    164.107238 |    667.919210 | Margot Michaud                                                                                                                                                 |
| 323 |    196.355310 |    491.253284 | Steven Traver                                                                                                                                                  |
| 324 |    250.529647 |    389.908496 | Margot Michaud                                                                                                                                                 |
| 325 |    549.736197 |    153.657646 | CNZdenek                                                                                                                                                       |
| 326 |    853.805286 |    649.734882 | Steven Traver                                                                                                                                                  |
| 327 |    592.686944 |    247.277166 | Jagged Fang Designs                                                                                                                                            |
| 328 |    701.461198 |    520.774980 | Steven Traver                                                                                                                                                  |
| 329 |    821.070875 |    101.706544 | Margot Michaud                                                                                                                                                 |
| 330 |    494.708067 |    249.966144 | C. Camilo Julián-Caballero                                                                                                                                     |
| 331 |    542.400562 |     12.074652 | Ingo Braasch                                                                                                                                                   |
| 332 |    994.943505 |    687.111260 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                               |
| 333 |    285.252168 |    252.629536 | Abraão B. Leite                                                                                                                                                |
| 334 |    928.146345 |    656.676361 | Margot Michaud                                                                                                                                                 |
| 335 |    380.785570 |    624.046713 | Geoff Shaw                                                                                                                                                     |
| 336 |    819.735176 |    647.754078 | Pranav Iyer (grey ideas)                                                                                                                                       |
| 337 |    827.939350 |    744.976272 | Steven Coombs                                                                                                                                                  |
| 338 |    510.803655 |      6.699846 | Chris huh                                                                                                                                                      |
| 339 |    259.522550 |    264.862630 | Jiekun He                                                                                                                                                      |
| 340 |    465.365922 |     57.482397 | NA                                                                                                                                                             |
| 341 |    879.187960 |     69.331947 | Sebastian Stabinger                                                                                                                                            |
| 342 |     59.151723 |    128.779282 | Scott Hartman                                                                                                                                                  |
| 343 |    830.597150 |    785.076361 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 344 |     93.352341 |    773.234429 | Andrew A. Farke                                                                                                                                                |
| 345 |   1000.238762 |    384.049491 | Robert Gay                                                                                                                                                     |
| 346 |    934.721645 |    276.049690 | T. Michael Keesey                                                                                                                                              |
| 347 |    742.846062 |    391.794097 | Shyamal                                                                                                                                                        |
| 348 |    920.088377 |     70.296250 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 349 |     27.115351 |    263.456073 | Andy Wilson                                                                                                                                                    |
| 350 |    464.386605 |     16.044933 | Chris Jennings (Risiatto)                                                                                                                                      |
| 351 |    485.744066 |    315.874342 | Emily Willoughby                                                                                                                                               |
| 352 |     85.544648 |    546.903547 | Anthony Caravaggi                                                                                                                                              |
| 353 |    284.487338 |    733.794974 | Tasman Dixon                                                                                                                                                   |
| 354 |    909.631201 |    282.236683 | Chris huh                                                                                                                                                      |
| 355 |     36.491595 |    455.098832 | Jagged Fang Designs                                                                                                                                            |
| 356 |    672.277751 |    739.091496 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 357 |     87.859273 |    568.439078 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 358 |    816.117434 |     87.452396 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                       |
| 359 |    395.802145 |    420.361796 | Maija Karala                                                                                                                                                   |
| 360 |    789.997770 |    630.248988 | Beth Reinke                                                                                                                                                    |
| 361 |    549.511248 |    747.267750 | Scott Hartman                                                                                                                                                  |
| 362 |    936.103332 |    622.621517 | Ferran Sayol                                                                                                                                                   |
| 363 |     24.620840 |    635.351951 | Mette Aumala                                                                                                                                                   |
| 364 |    380.223702 |    246.966372 | Andy Wilson                                                                                                                                                    |
| 365 |    619.544645 |    274.213888 | Margot Michaud                                                                                                                                                 |
| 366 |    667.756173 |    466.198295 | Carlos Cano-Barbacil                                                                                                                                           |
| 367 |    172.775026 |    484.931011 | Gareth Monger                                                                                                                                                  |
| 368 |    251.887337 |    470.715409 | Lafage                                                                                                                                                         |
| 369 |    683.348315 |    717.782061 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 370 |    125.519897 |    356.188161 | T. Michael Keesey                                                                                                                                              |
| 371 |   1005.608101 |    201.886895 | Steven Traver                                                                                                                                                  |
| 372 |    987.481293 |     52.564337 | Robert Gay                                                                                                                                                     |
| 373 |    756.797102 |    675.301626 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                   |
| 374 |    260.527839 |    351.259993 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 375 |    851.610732 |    794.578854 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 376 |    766.710558 |    714.220702 | Chris huh                                                                                                                                                      |
| 377 |    640.032333 |    716.963331 | Anthony Caravaggi                                                                                                                                              |
| 378 |    514.466980 |    632.572575 | Andrew R. Gehrke                                                                                                                                               |
| 379 |    877.532991 |    120.556355 | Scott Hartman                                                                                                                                                  |
| 380 |    755.325789 |    424.913167 | Skye McDavid                                                                                                                                                   |
| 381 |    931.015090 |    140.641668 | Ferran Sayol                                                                                                                                                   |
| 382 |    380.307170 |    174.656634 | Luc Viatour (source photo) and Andreas Plank                                                                                                                   |
| 383 |    310.601974 |     67.686359 | Matt Crook                                                                                                                                                     |
| 384 |    849.588666 |    251.466768 | Zimices                                                                                                                                                        |
| 385 |    451.219964 |    138.263544 | Ignacio Contreras                                                                                                                                              |
| 386 |    671.015516 |    758.325048 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                 |
| 387 |   1003.858747 |    309.543564 | Mark Hofstetter (vectorized by T. Michael Keesey)                                                                                                              |
| 388 |    329.273467 |     47.873180 | Tasman Dixon                                                                                                                                                   |
| 389 |    516.950456 |    148.310068 | Ferran Sayol                                                                                                                                                   |
| 390 |    916.773279 |    303.283155 | Anthony Caravaggi                                                                                                                                              |
| 391 |    327.650531 |    667.831323 | Zimices                                                                                                                                                        |
| 392 |    740.873328 |    122.232373 | Zimices                                                                                                                                                        |
| 393 |     80.671618 |    377.117697 | Harold N Eyster                                                                                                                                                |
| 394 |    645.208947 |    490.985892 | NA                                                                                                                                                             |
| 395 |    199.628252 |    659.432915 | Steven Coombs                                                                                                                                                  |
| 396 |    721.161302 |    349.312181 | Markus A. Grohme                                                                                                                                               |
| 397 |    509.718921 |    530.778069 | David Tana                                                                                                                                                     |
| 398 |    771.265710 |     34.504520 | Gabriela Palomo-Munoz                                                                                                                                          |
| 399 |    821.651008 |      8.020392 | Zimices                                                                                                                                                        |
| 400 |    281.686397 |    138.900572 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 401 |    410.854085 |    623.552955 | Chase Brownstein                                                                                                                                               |
| 402 |    473.242979 |    703.752706 | Chris huh                                                                                                                                                      |
| 403 |    500.981570 |     37.830505 | Scott Hartman                                                                                                                                                  |
| 404 |    672.545530 |    415.511166 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 405 |    626.679087 |    359.146245 | Amanda Katzer                                                                                                                                                  |
| 406 |    689.730492 |    777.582103 | Zachary Quigley                                                                                                                                                |
| 407 |    961.601290 |    598.057841 | Scott Hartman                                                                                                                                                  |
| 408 |    796.823478 |    590.067128 | Steven Traver                                                                                                                                                  |
| 409 |    554.500047 |    253.085573 | Margot Michaud                                                                                                                                                 |
| 410 |    439.642934 |    731.221840 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                   |
| 411 |    406.286087 |      8.646143 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                          |
| 412 |    668.623290 |    447.547899 | Scott Reid                                                                                                                                                     |
| 413 |    233.719306 |    636.404510 | Andy Wilson                                                                                                                                                    |
| 414 |    418.825252 |    231.901836 | Manabu Bessho-Uehara                                                                                                                                           |
| 415 |    629.152761 |    621.175699 | Chris huh                                                                                                                                                      |
| 416 |     72.369808 |    615.842338 | Walter Vladimir                                                                                                                                                |
| 417 |     42.113093 |    653.845100 | Xavier A. Jenkins, Gabriel Ugueto                                                                                                                              |
| 418 |    370.432215 |    643.565003 | NA                                                                                                                                                             |
| 419 |    539.840146 |    570.034078 | Julio Garza                                                                                                                                                    |
| 420 |    608.754539 |    320.706284 | Jaime Headden                                                                                                                                                  |
| 421 |     95.782206 |    197.434371 | Kai R. Caspar                                                                                                                                                  |
| 422 |    627.960396 |    627.281290 | Ignacio Contreras                                                                                                                                              |
| 423 |    500.587930 |    478.122281 | Caleb M. Brown                                                                                                                                                 |
| 424 |    342.866530 |    478.005454 | Samanta Orellana                                                                                                                                               |
| 425 |    693.746880 |    453.373626 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                     |
| 426 |      8.091831 |    206.982586 | Kanchi Nanjo                                                                                                                                                   |
| 427 |     35.446009 |     15.911780 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                             |
| 428 |    543.597819 |    557.500863 | Markus A. Grohme                                                                                                                                               |
| 429 |     96.631800 |    607.089011 | Andrew R. Gehrke                                                                                                                                               |
| 430 |    279.143419 |    201.771991 | NA                                                                                                                                                             |
| 431 |    241.490984 |    267.925321 | terngirl                                                                                                                                                       |
| 432 |    342.633988 |    575.523002 | T. Michael Keesey                                                                                                                                              |
| 433 |    103.254632 |     34.754455 | Gabriela Palomo-Munoz                                                                                                                                          |
| 434 |    921.237695 |    352.846397 | Steven Coombs                                                                                                                                                  |
| 435 |    452.185681 |    245.731528 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                                     |
| 436 |    162.234082 |    133.715058 | Geoff Shaw                                                                                                                                                     |
| 437 |   1008.690312 |    553.539485 | Kai R. Caspar                                                                                                                                                  |
| 438 |    596.240204 |    240.409397 | Margot Michaud                                                                                                                                                 |
| 439 |     56.239320 |    566.823548 | David Tana                                                                                                                                                     |
| 440 |    521.670876 |    759.212739 | C. Camilo Julián-Caballero                                                                                                                                     |
| 441 |   1014.579631 |    458.332239 | Gareth Monger                                                                                                                                                  |
| 442 |    413.845033 |    596.627733 | Julia B McHugh                                                                                                                                                 |
| 443 |    834.926242 |    699.332692 | Margot Michaud                                                                                                                                                 |
| 444 |    160.021717 |    556.408028 | David Orr                                                                                                                                                      |
| 445 |    798.822260 |    346.006724 | Collin Gross                                                                                                                                                   |
| 446 |    633.793000 |    480.587441 | Tasman Dixon                                                                                                                                                   |
| 447 |    488.621781 |     18.274599 | Auckland Museum and T. Michael Keesey                                                                                                                          |
| 448 |     59.985282 |    694.614049 | FunkMonk (Michael B. H.)                                                                                                                                       |
| 449 |    602.945356 |    489.005179 | NA                                                                                                                                                             |
| 450 |    221.382010 |    354.521974 | T. Michael Keesey                                                                                                                                              |
| 451 |    315.570075 |    383.732299 | T. Michael Keesey                                                                                                                                              |
| 452 |    208.476736 |    598.078747 | Margot Michaud                                                                                                                                                 |
| 453 |    207.662943 |    768.459736 | Sarah Werning                                                                                                                                                  |
| 454 |    109.708055 |    125.923119 | Ignacio Contreras                                                                                                                                              |
| 455 |    603.388251 |    579.755763 | Margot Michaud                                                                                                                                                 |
| 456 |    646.934641 |    754.920715 | Andrés Sánchez                                                                                                                                                 |
| 457 |    689.204749 |    671.675742 | Aline M. Ghilardi                                                                                                                                              |
| 458 |     91.630780 |     14.017166 | Sarah Werning                                                                                                                                                  |
| 459 |    973.821190 |     16.539358 | Gareth Monger                                                                                                                                                  |
| 460 |    813.081137 |    765.084193 | Mario Quevedo                                                                                                                                                  |
| 461 |     97.060586 |    465.996210 | Scott Hartman                                                                                                                                                  |
| 462 |   1012.079760 |    280.676107 | Michelle Site                                                                                                                                                  |
| 463 |    925.818283 |    683.078223 | Emily Jane McTavish                                                                                                                                            |
| 464 |    162.828192 |    198.035598 | Margot Michaud                                                                                                                                                 |
| 465 |    810.811117 |    429.780242 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                        |
| 466 |    624.720744 |     14.443451 | Margot Michaud                                                                                                                                                 |
| 467 |    940.822328 |    455.404288 | Abraão Leite                                                                                                                                                   |
| 468 |    656.518532 |    479.290051 | Jagged Fang Designs                                                                                                                                            |
| 469 |    396.995301 |    795.581689 | Jagged Fang Designs                                                                                                                                            |
| 470 |    872.277414 |    195.072369 | Yan Wong                                                                                                                                                       |
| 471 |    586.157181 |    196.997536 | NA                                                                                                                                                             |
| 472 |    146.254175 |    504.646716 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                     |
| 473 |   1006.701190 |    503.201222 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 474 |    515.351241 |    702.485945 | Joanna Wolfe                                                                                                                                                   |
| 475 |    492.285450 |    339.958488 | Julia B McHugh                                                                                                                                                 |
| 476 |    472.112099 |    179.684251 | Andrew A. Farke                                                                                                                                                |
| 477 |    664.331472 |    290.512541 | Xavier A. Jenkins, Gabriel Ugueto                                                                                                                              |
| 478 |    847.219237 |    665.564309 | T. Michael Keesey                                                                                                                                              |
| 479 |    385.228161 |    117.502330 | Andrew A. Farke                                                                                                                                                |
| 480 |    891.272448 |    474.333498 | Kelly                                                                                                                                                          |
| 481 |    796.408531 |    247.431974 | Jaime Headden                                                                                                                                                  |
| 482 |    736.457465 |    527.132170 | Scott Hartman                                                                                                                                                  |
| 483 |    509.443439 |    494.240833 | FunkMonk                                                                                                                                                       |
| 484 |    953.706759 |    765.177819 | Carlos Cano-Barbacil                                                                                                                                           |
| 485 |    467.449429 |      4.920303 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                  |
| 486 |    975.921703 |     94.173672 | Markus A. Grohme                                                                                                                                               |
| 487 |    659.804065 |     35.641019 | M Hutchinson                                                                                                                                                   |
| 488 |    642.700682 |    410.805638 | Emily Willoughby                                                                                                                                               |
| 489 |    237.801913 |     41.401438 | Jagged Fang Designs                                                                                                                                            |
| 490 |    380.516845 |     74.991169 | Caleb M. Brown                                                                                                                                                 |
| 491 |    699.443072 |     78.337528 | Trond R. Oskars                                                                                                                                                |
| 492 |    725.422694 |    774.217300 | Zimices                                                                                                                                                        |
| 493 |    352.977611 |    550.294992 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                       |
| 494 |     15.403022 |     53.888634 | Markus A. Grohme                                                                                                                                               |
| 495 |    798.208388 |    157.083161 | Iain Reid                                                                                                                                                      |
| 496 |     16.415460 |    791.342011 | Markus A. Grohme                                                                                                                                               |
| 497 |    111.022946 |    540.245848 | DW Bapst (Modified from Bulman, 1964)                                                                                                                          |
| 498 |    109.002597 |    659.441352 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 499 |     69.162003 |    194.388774 | Emily Jane McTavish                                                                                                                                            |
| 500 |    325.398320 |    109.300365 | Margot Michaud                                                                                                                                                 |
| 501 |   1015.141000 |    616.385654 | Gopal Murali                                                                                                                                                   |
| 502 |    583.478702 |    334.833970 | Gabriela Palomo-Munoz                                                                                                                                          |
| 503 |    404.600669 |    182.409954 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 504 |    717.569524 |    420.415276 | Jagged Fang Designs                                                                                                                                            |
| 505 |    576.729009 |    223.196793 | Mark Hofstetter (vectorized by T. Michael Keesey)                                                                                                              |
| 506 |    897.520093 |    751.544367 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                     |
| 507 |    812.956003 |     45.874218 | Вальдимар (vectorized by T. Michael Keesey)                                                                                                                    |
| 508 |     15.071115 |    125.283543 | Margot Michaud                                                                                                                                                 |
| 509 |   1003.277374 |     67.016197 | Alex Slavenko                                                                                                                                                  |
| 510 |    288.627160 |    709.837324 | Caleb M. Brown                                                                                                                                                 |
| 511 |    536.556713 |    533.682632 | Matt Crook                                                                                                                                                     |
| 512 |    257.371114 |    420.782898 | Renata F. Martins                                                                                                                                              |
| 513 |    685.778836 |    268.178874 | Iain Reid                                                                                                                                                      |
| 514 |    898.604712 |    328.409226 | Matt Crook                                                                                                                                                     |
| 515 |     53.791263 |    678.432718 | Zachary Quigley                                                                                                                                                |
| 516 |    382.762517 |    154.009948 | Iain Reid                                                                                                                                                      |
| 517 |    682.630164 |    488.951356 | Steven Traver                                                                                                                                                  |
| 518 |    265.302942 |    495.884683 | Matt Crook                                                                                                                                                     |
| 519 |    836.889107 |    402.575664 | Mathew Wedel                                                                                                                                                   |
| 520 |    119.468432 |    398.616270 | Julia B McHugh                                                                                                                                                 |
| 521 |    483.602726 |    757.827092 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                                |
| 522 |    931.541649 |    785.896828 | Ghedo and T. Michael Keesey                                                                                                                                    |
| 523 |    920.726637 |    764.415455 | NA                                                                                                                                                             |
| 524 |   1017.219991 |    740.879060 | Michele M Tobias                                                                                                                                               |
| 525 |    878.545209 |    298.664410 | Christoph Schomburg                                                                                                                                            |
| 526 |    847.230727 |     97.172091 | Jaime Headden, modified by T. Michael Keesey                                                                                                                   |
| 527 |    340.559106 |    792.326670 | Jagged Fang Designs                                                                                                                                            |
| 528 |    809.795746 |    626.875107 | Alex Slavenko                                                                                                                                                  |
| 529 |    899.003944 |    728.046385 | Jon Hill                                                                                                                                                       |
| 530 |    593.821137 |     11.269197 | Jagged Fang Designs                                                                                                                                            |
| 531 |    465.826991 |    143.391656 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 532 |    361.518186 |    215.211108 | C. Camilo Julián-Caballero                                                                                                                                     |
| 533 |    960.482456 |    450.118373 | Chris huh                                                                                                                                                      |
| 534 |    292.740721 |    488.171081 | Jagged Fang Designs                                                                                                                                            |
| 535 |    580.624991 |    700.638772 | Michael Scroggie                                                                                                                                               |
| 536 |    434.967113 |     13.094113 | Beth Reinke                                                                                                                                                    |
| 537 |    881.491867 |     84.385941 | Smokeybjb                                                                                                                                                      |
| 538 |    745.902564 |    263.939268 | Gareth Monger                                                                                                                                                  |
| 539 |    565.183785 |    403.548400 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                    |
| 540 |    112.212357 |    552.663713 | Chris huh                                                                                                                                                      |

    #> Your tweet has been posted!
