
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

Christoph Schomburg, Zimices, Margot Michaud, Matt Crook, Cagri Cevrim,
Katie S. Collins, L. Shyamal, Mathew Wedel, Didier Descouens (vectorized
by T. Michael Keesey), Jagged Fang Designs, Warren H (photography), T.
Michael Keesey (vectorization), Chris huh, Samanta Orellana, Markus A.
Grohme, Ignacio Contreras, Steven Traver, Joanna Wolfe, Sarah Werning,
Dmitry Bogdanov (vectorized by T. Michael Keesey), Ferran Sayol, Collin
Gross, Emily Willoughby, Birgit Lang, Ieuan Jones, CNZdenek, Evan-Amos
(vectorized by T. Michael Keesey), Smokeybjb, Tess Linden, Mali’o Kodis,
photograph from Jersabek et al, 2003, Tasman Dixon, Scott Hartman, Sean
McCann, S.Martini, Gareth Monger, Jack Mayer Wood, Lukasiniho, Xavier
Giroux-Bougard, Alexander Schmidt-Lebuhn, Mark Witton, Nicolas Huet le
Jeune and Jean-Gabriel Prêtre (vectorized by T. Michael Keesey), Nobu
Tamura (vectorized by T. Michael Keesey), Nobu Tamura (modified by T.
Michael Keesey), Jaime Headden, Enoch Joseph Wetsy (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Daniel
Stadtmauer, Andrew Farke and Joseph Sertich, Renato de Carvalho
Ferreira, David Tana, Craig Dylke, Kanako Bessho-Uehara, Obsidian Soul
(vectorized by T. Michael Keesey), FunkMonk, Anna Willoughby, Mattia
Menchetti, Brian Swartz (vectorized by T. Michael Keesey), Konsta
Happonen, Steven Coombs, Dexter R. Mardis, Gabriela Palomo-Munoz, Becky
Barnes, Chris A. Hamilton, Sharon Wegner-Larsen, Beth Reinke, Kamil S.
Jaron, Maija Karala, Hans Hillewaert (vectorized by T. Michael Keesey),
Alexandre Vong, Matus Valach, Robbie N. Cada (vectorized by T. Michael
Keesey), Terpsichores, Kai R. Caspar, Milton Tan, Mathilde Cordellier,
Jonathan Wells, T. Michael Keesey, U.S. Fish and Wildlife Service
(illustration) and Timothy J. Bartley (silhouette), Dean Schnabel, Matt
Celeskey, Dmitry Bogdanov, Mali’o Kodis, photograph by Jim Vargo,
Smith609 and T. Michael Keesey, Julio Garza, T. Michael Keesey and
Tanetahi, Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob
Slotow (vectorized by T. Michael Keesey), Philip Chalmers (vectorized by
T. Michael Keesey), T. Michael Keesey (vectorization) and HuttyMcphoo
(photography), E. Lear, 1819 (vectorization by Yan Wong), Felix Vaux,
Matt Martyniuk, Joedison Rocha, Alex Slavenko, Tracy A. Heath, C. Camilo
Julián-Caballero, Michelle Site, Ron Holmes/U. S. Fish and Wildlife
Service (source photo), T. Michael Keesey (vectorization), C.
Abraczinskas, Pete Buchholz, Y. de Hoev. (vectorized by T. Michael
Keesey), Nobu Tamura, vectorized by Zimices, Iain Reid, Melissa
Broussard, Agnello Picorelli, Myriam\_Ramirez, Jiekun He, Yan Wong from
wikipedia drawing (PD: Pearson Scott Foresman), Cesar Julian, Todd
Marshall, vectorized by Zimices, Martien Brand (original photo), Renato
Santos (vector silhouette), Zachary Quigley, Darren Naish (vectorize by
T. Michael Keesey), Matt Dempsey, Caleb M. Brown, Mattia Menchetti / Yan
Wong, Noah Schlottman, Manabu Bessho-Uehara, (unknown), Kent Sorgon,
Chase Brownstein, Oliver Griffith, Noah Schlottman, photo by Museum of
Geology, University of Tartu, Jose Carlos Arenas-Monroy, Carlos
Cano-Barbacil, Ellen Edmonson and Hugh Chrisp (illustration) and Timothy
J. Bartley (silhouette), Michael Scroggie, Nobu Tamura, Verisimilus, Yan
Wong from illustration by Charles Orbigny, Jakovche, Andreas Hejnol,
Abraão Leite, Óscar San-Isidro (vectorized by T. Michael Keesey), Darren
Naish (vectorized by T. Michael Keesey), Nicholas J. Czaplewski,
vectorized by Zimices, Conty (vectorized by T. Michael Keesey), DW Bapst
(Modified from Bulman, 1964), Original drawing by Nobu Tamura,
vectorized by Roberto Díaz Sibaja, Tyler Greenfield, Ben Liebeskind,
Roberto Díaz Sibaja, Eduard Solà (vectorized by T. Michael Keesey),
Martin R. Smith, after Skovsted et al 2015, Cathy, Lisa Byrne, Matt
Wilkins, Jake Warner, Scott Reid, Lukas Panzarin, Armin Reindl, I.
Sácek, Sr. (vectorized by T. Michael Keesey), Dianne Bray / Museum
Victoria (vectorized by T. Michael Keesey), Charles R. Knight
(vectorized by T. Michael Keesey), Oscar Sanisidro, Darius Nau, Lily
Hughes, Rebecca Groom, Caleb M. Gordon, Nobu Tamura, modified by Andrew
A. Farke, Ludwik Gasiorowski, Jaime A. Headden (vectorized by T. Michael
Keesey), Sherman Foote Denton (illustration, 1897) and Timothy J.
Bartley (silhouette), Noah Schlottman, photo by Antonio Guillén, Siobhon
Egan, Andrew A. Farke, FunkMonk (Michael B.H.; vectorized by T. Michael
Keesey), James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo
Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael
Keesey), Birgit Lang, based on a photo by D. Sikes, Kanchi Nanjo,
Fernando Carezzano

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                             |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    565.075246 |    381.157699 | Christoph Schomburg                                                                                                                                                |
|   2 |    334.736597 |    250.015916 | Zimices                                                                                                                                                            |
|   3 |    248.181567 |    671.981700 | Margot Michaud                                                                                                                                                     |
|   4 |    400.967967 |    645.896358 | Matt Crook                                                                                                                                                         |
|   5 |    429.222756 |    331.710285 | Zimices                                                                                                                                                            |
|   6 |    631.355518 |     84.071935 | Margot Michaud                                                                                                                                                     |
|   7 |    573.812443 |    623.668433 | Cagri Cevrim                                                                                                                                                       |
|   8 |    866.312797 |    578.226278 | Katie S. Collins                                                                                                                                                   |
|   9 |    144.738841 |    180.064167 | L. Shyamal                                                                                                                                                         |
|  10 |    159.877555 |    508.349433 | Mathew Wedel                                                                                                                                                       |
|  11 |    395.080049 |    388.849902 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                 |
|  12 |    136.705403 |    302.663372 | Jagged Fang Designs                                                                                                                                                |
|  13 |    776.900826 |     54.811004 | Katie S. Collins                                                                                                                                                   |
|  14 |    763.129958 |    688.441985 | Warren H (photography), T. Michael Keesey (vectorization)                                                                                                          |
|  15 |    644.273869 |    203.805641 | Chris huh                                                                                                                                                          |
|  16 |    476.020972 |     48.305406 | NA                                                                                                                                                                 |
|  17 |    671.979758 |    393.919355 | Samanta Orellana                                                                                                                                                   |
|  18 |    635.762090 |    772.561374 | Markus A. Grohme                                                                                                                                                   |
|  19 |    391.015754 |    131.942411 | Zimices                                                                                                                                                            |
|  20 |    662.453114 |    296.611100 | Zimices                                                                                                                                                            |
|  21 |    171.210805 |    377.829600 | Ignacio Contreras                                                                                                                                                  |
|  22 |    884.910532 |    122.188756 | NA                                                                                                                                                                 |
|  23 |    192.026544 |    471.082498 | Markus A. Grohme                                                                                                                                                   |
|  24 |    225.690297 |    738.203637 | Steven Traver                                                                                                                                                      |
|  25 |    404.153480 |    514.909472 | Joanna Wolfe                                                                                                                                                       |
|  26 |    307.259163 |     63.491165 | Sarah Werning                                                                                                                                                      |
|  27 |    861.264417 |    392.064444 | NA                                                                                                                                                                 |
|  28 |    848.045261 |    220.037069 | Margot Michaud                                                                                                                                                     |
|  29 |    783.957514 |    464.336454 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
|  30 |    919.810798 |    717.730748 | Zimices                                                                                                                                                            |
|  31 |    453.108016 |    713.121215 | Chris huh                                                                                                                                                          |
|  32 |    651.628477 |    653.847612 | Zimices                                                                                                                                                            |
|  33 |    129.886734 |    613.437762 | Markus A. Grohme                                                                                                                                                   |
|  34 |     94.736908 |     70.791379 | Ferran Sayol                                                                                                                                                       |
|  35 |    237.509747 |    106.886355 | NA                                                                                                                                                                 |
|  36 |    314.298261 |    433.789760 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
|  37 |    800.192054 |    313.707446 | Collin Gross                                                                                                                                                       |
|  38 |     47.632132 |    353.432230 | Cagri Cevrim                                                                                                                                                       |
|  39 |    714.764865 |    568.528012 | Zimices                                                                                                                                                            |
|  40 |    527.199535 |    267.323589 | Emily Willoughby                                                                                                                                                   |
|  41 |    957.165177 |    216.025234 | Birgit Lang                                                                                                                                                        |
|  42 |    294.558716 |    567.046838 | Ieuan Jones                                                                                                                                                        |
|  43 |    108.477599 |    726.424897 | Matt Crook                                                                                                                                                         |
|  44 |    595.323705 |    727.792747 | CNZdenek                                                                                                                                                           |
|  45 |    960.939697 |    298.683295 | Evan-Amos (vectorized by T. Michael Keesey)                                                                                                                        |
|  46 |    693.553847 |    260.831644 | Smokeybjb                                                                                                                                                          |
|  47 |    620.918619 |    489.344472 | Tess Linden                                                                                                                                                        |
|  48 |    172.012108 |     28.283649 | Zimices                                                                                                                                                            |
|  49 |    988.201056 |    588.360580 | Mali’o Kodis, photograph from Jersabek et al, 2003                                                                                                                 |
|  50 |    323.818818 |    629.813928 | Tasman Dixon                                                                                                                                                       |
|  51 |    908.204005 |     27.915577 | Scott Hartman                                                                                                                                                      |
|  52 |    546.839645 |    165.385016 | Sean McCann                                                                                                                                                        |
|  53 |    959.054541 |    516.820026 | Matt Crook                                                                                                                                                         |
|  54 |     76.008553 |    394.613921 | S.Martini                                                                                                                                                          |
|  55 |     48.868516 |    490.093218 | Gareth Monger                                                                                                                                                      |
|  56 |    952.860658 |     70.762179 | Jack Mayer Wood                                                                                                                                                    |
|  57 |     91.462853 |    531.027070 | Lukasiniho                                                                                                                                                         |
|  58 |    540.224478 |    545.875713 | Jagged Fang Designs                                                                                                                                                |
|  59 |     57.564358 |    205.606107 | Xavier Giroux-Bougard                                                                                                                                              |
|  60 |    250.747337 |    218.820599 | Alexander Schmidt-Lebuhn                                                                                                                                           |
|  61 |    308.506541 |    342.794941 | Mark Witton                                                                                                                                                        |
|  62 |    485.159671 |    444.451064 | Birgit Lang                                                                                                                                                        |
|  63 |    360.161741 |    778.444472 | Jagged Fang Designs                                                                                                                                                |
|  64 |    781.031370 |    373.797627 | Nicolas Huet le Jeune and Jean-Gabriel Prêtre (vectorized by T. Michael Keesey)                                                                                    |
|  65 |    752.901921 |    762.755925 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
|  66 |    124.383409 |    266.210608 | Christoph Schomburg                                                                                                                                                |
|  67 |    758.511028 |    247.930936 | Steven Traver                                                                                                                                                      |
|  68 |     69.050396 |    129.847671 | Markus A. Grohme                                                                                                                                                   |
|  69 |    978.856573 |    418.481124 | L. Shyamal                                                                                                                                                         |
|  70 |    797.175556 |    785.324221 | Smokeybjb                                                                                                                                                          |
|  71 |    498.819262 |    774.851524 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                        |
|  72 |    633.043761 |    243.034934 | Jaime Headden                                                                                                                                                      |
|  73 |     70.215773 |    686.927357 | Margot Michaud                                                                                                                                                     |
|  74 |    866.637112 |    655.519019 | Matt Crook                                                                                                                                                         |
|  75 |    127.128208 |    437.926931 | Scott Hartman                                                                                                                                                      |
|  76 |    497.394228 |    220.402572 | Katie S. Collins                                                                                                                                                   |
|  77 |    728.497305 |     26.191060 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
|  78 |    544.937376 |    520.147607 | NA                                                                                                                                                                 |
|  79 |    771.076521 |    612.519874 | Joanna Wolfe                                                                                                                                                       |
|  80 |    914.776135 |    273.758455 | Daniel Stadtmauer                                                                                                                                                  |
|  81 |    700.842036 |    511.749932 | Andrew Farke and Joseph Sertich                                                                                                                                    |
|  82 |    531.674304 |    604.669277 | Renato de Carvalho Ferreira                                                                                                                                        |
|  83 |    957.339405 |    160.949429 | David Tana                                                                                                                                                         |
|  84 |    488.526634 |    667.125578 | Craig Dylke                                                                                                                                                        |
|  85 |    586.681090 |     39.074497 | Chris huh                                                                                                                                                          |
|  86 |    736.625840 |    121.759208 | Chris huh                                                                                                                                                          |
|  87 |    438.631764 |    207.369702 | Kanako Bessho-Uehara                                                                                                                                               |
|  88 |    159.053082 |    773.367522 | Margot Michaud                                                                                                                                                     |
|  89 |     32.081561 |    246.086510 | Jagged Fang Designs                                                                                                                                                |
|  90 |    580.428998 |    449.235994 | Zimices                                                                                                                                                            |
|  91 |     36.264007 |    666.640603 | Chris huh                                                                                                                                                          |
|  92 |    518.245776 |    685.196004 | Steven Traver                                                                                                                                                      |
|  93 |    115.807333 |    405.696025 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                    |
|  94 |    822.624296 |    272.382512 | Zimices                                                                                                                                                            |
|  95 |    857.906831 |    463.576453 | Matt Crook                                                                                                                                                         |
|  96 |    128.901076 |    665.366292 | Gareth Monger                                                                                                                                                      |
|  97 |    196.554374 |    551.800597 | FunkMonk                                                                                                                                                           |
|  98 |    163.756531 |    744.504381 | Anna Willoughby                                                                                                                                                    |
|  99 |    528.802360 |    485.018230 | Zimices                                                                                                                                                            |
| 100 |    325.408614 |    612.898160 | Scott Hartman                                                                                                                                                      |
| 101 |    736.270214 |    384.840713 | Mattia Menchetti                                                                                                                                                   |
| 102 |    179.170548 |    319.501467 | Zimices                                                                                                                                                            |
| 103 |    592.415907 |    328.999934 | Markus A. Grohme                                                                                                                                                   |
| 104 |    968.024724 |    785.582645 | Chris huh                                                                                                                                                          |
| 105 |    690.425317 |    713.431886 | Steven Traver                                                                                                                                                      |
| 106 |    236.793626 |    530.849310 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                                     |
| 107 |    406.309797 |     35.116628 | Margot Michaud                                                                                                                                                     |
| 108 |    751.194318 |    160.795140 | Konsta Happonen                                                                                                                                                    |
| 109 |    683.219355 |    737.030695 | Steven Coombs                                                                                                                                                      |
| 110 |    904.855861 |    294.783819 | Dexter R. Mardis                                                                                                                                                   |
| 111 |    970.650980 |    626.863597 | Gabriela Palomo-Munoz                                                                                                                                              |
| 112 |    635.264392 |    582.124761 | Zimices                                                                                                                                                            |
| 113 |    957.048688 |     36.686199 | Becky Barnes                                                                                                                                                       |
| 114 |    849.117335 |    519.537370 | Matt Crook                                                                                                                                                         |
| 115 |     79.263079 |    354.681029 | Margot Michaud                                                                                                                                                     |
| 116 |     87.644731 |    220.036198 | Chris A. Hamilton                                                                                                                                                  |
| 117 |    702.572417 |    330.265581 | Christoph Schomburg                                                                                                                                                |
| 118 |    403.095575 |    452.523351 | Gareth Monger                                                                                                                                                      |
| 119 |    831.272973 |    157.100875 | Margot Michaud                                                                                                                                                     |
| 120 |     14.476405 |     57.052357 | Sharon Wegner-Larsen                                                                                                                                               |
| 121 |    932.789838 |    658.389158 | Zimices                                                                                                                                                            |
| 122 |    590.266965 |    265.621370 | Matt Crook                                                                                                                                                         |
| 123 |    882.649290 |    484.556458 | Beth Reinke                                                                                                                                                        |
| 124 |     16.741835 |    595.613492 | Kamil S. Jaron                                                                                                                                                     |
| 125 |    219.087636 |    159.750221 | Maija Karala                                                                                                                                                       |
| 126 |    704.451904 |    473.882262 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                  |
| 127 |    779.540580 |    639.141575 | Alexandre Vong                                                                                                                                                     |
| 128 |    435.216945 |    282.446557 | Gabriela Palomo-Munoz                                                                                                                                              |
| 129 |    265.048088 |    596.359531 | Matus Valach                                                                                                                                                       |
| 130 |    826.418266 |    723.950206 | Beth Reinke                                                                                                                                                        |
| 131 |    393.459843 |    275.256136 | Zimices                                                                                                                                                            |
| 132 |    466.593837 |    689.944361 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                   |
| 133 |    547.658120 |    306.824532 | Terpsichores                                                                                                                                                       |
| 134 |     34.421540 |    725.026371 | NA                                                                                                                                                                 |
| 135 |    576.265240 |     17.301900 | Maija Karala                                                                                                                                                       |
| 136 |    237.378450 |    443.518012 | Gabriela Palomo-Munoz                                                                                                                                              |
| 137 |    424.180299 |    744.307689 | Ferran Sayol                                                                                                                                                       |
| 138 |    141.085622 |    574.234501 | Chris huh                                                                                                                                                          |
| 139 |    332.503002 |    165.657718 | Kai R. Caspar                                                                                                                                                      |
| 140 |    783.620920 |    110.764826 | Zimices                                                                                                                                                            |
| 141 |    789.397876 |    579.946529 | Zimices                                                                                                                                                            |
| 142 |    973.052271 |    180.963813 | Milton Tan                                                                                                                                                         |
| 143 |    414.367466 |      5.347856 | Jagged Fang Designs                                                                                                                                                |
| 144 |    101.785438 |    148.273854 | Jaime Headden                                                                                                                                                      |
| 145 |   1002.674233 |    456.973129 | NA                                                                                                                                                                 |
| 146 |    284.576917 |    792.882746 | Scott Hartman                                                                                                                                                      |
| 147 |    203.817738 |     80.716770 | Matt Crook                                                                                                                                                         |
| 148 |    731.057849 |    359.295739 | Scott Hartman                                                                                                                                                      |
| 149 |    638.436478 |    553.334697 | Mathilde Cordellier                                                                                                                                                |
| 150 |    592.206563 |    518.151827 | Zimices                                                                                                                                                            |
| 151 |    485.363764 |    156.395873 | Jonathan Wells                                                                                                                                                     |
| 152 |    266.663566 |    499.423968 | S.Martini                                                                                                                                                          |
| 153 |    434.763368 |     74.688532 | Matt Crook                                                                                                                                                         |
| 154 |    722.793042 |    614.832011 | Matt Crook                                                                                                                                                         |
| 155 |    487.791807 |     92.562253 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 156 |     17.875296 |    421.140409 | Jagged Fang Designs                                                                                                                                                |
| 157 |    235.238571 |    620.263276 | Ferran Sayol                                                                                                                                                       |
| 158 |     79.605102 |    660.802757 | T. Michael Keesey                                                                                                                                                  |
| 159 |     90.909395 |    704.996768 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                                  |
| 160 |    707.853483 |    440.890593 | Dean Schnabel                                                                                                                                                      |
| 161 |    714.607180 |    272.021893 | Matt Celeskey                                                                                                                                                      |
| 162 |    469.298978 |    737.733846 | Jack Mayer Wood                                                                                                                                                    |
| 163 |    467.817540 |    377.334342 | Dmitry Bogdanov                                                                                                                                                    |
| 164 |    611.372076 |    613.942377 | Mali’o Kodis, photograph by Jim Vargo                                                                                                                              |
| 165 |    321.772687 |    123.956412 | L. Shyamal                                                                                                                                                         |
| 166 |     80.184382 |    773.355032 | Smith609 and T. Michael Keesey                                                                                                                                     |
| 167 |    380.189839 |    429.323556 | Chris huh                                                                                                                                                          |
| 168 |    990.548047 |    122.631554 | Birgit Lang                                                                                                                                                        |
| 169 |    196.486021 |    244.062125 | Julio Garza                                                                                                                                                        |
| 170 |    164.262433 |     83.243115 | Alexander Schmidt-Lebuhn                                                                                                                                           |
| 171 |    983.575138 |     15.706414 | T. Michael Keesey and Tanetahi                                                                                                                                     |
| 172 |    109.857498 |    757.694849 | NA                                                                                                                                                                 |
| 173 |    113.770905 |    777.216393 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                |
| 174 |    938.947944 |    517.299797 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                  |
| 175 |    452.504810 |    267.378535 | Jagged Fang Designs                                                                                                                                                |
| 176 |    166.125339 |    446.633616 | Dean Schnabel                                                                                                                                                      |
| 177 |    378.116720 |    749.989572 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                    |
| 178 |    765.616919 |    421.759031 | Ignacio Contreras                                                                                                                                                  |
| 179 |    564.462996 |    137.381698 | Ferran Sayol                                                                                                                                                       |
| 180 |    239.172837 |    346.887732 | E. Lear, 1819 (vectorization by Yan Wong)                                                                                                                          |
| 181 |    704.574203 |     79.974748 | Jagged Fang Designs                                                                                                                                                |
| 182 |    228.275311 |     16.295017 | Felix Vaux                                                                                                                                                         |
| 183 |    699.271732 |    166.955627 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 184 |    604.416621 |    673.489851 | Scott Hartman                                                                                                                                                      |
| 185 |    373.466524 |    568.117278 | Matt Crook                                                                                                                                                         |
| 186 |    807.413520 |    539.155857 | NA                                                                                                                                                                 |
| 187 |    658.487779 |    701.219728 | Margot Michaud                                                                                                                                                     |
| 188 |    142.417812 |    543.689019 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                   |
| 189 |    767.350689 |    200.744683 | Beth Reinke                                                                                                                                                        |
| 190 |    519.336605 |    126.886622 | NA                                                                                                                                                                 |
| 191 |     92.304576 |     20.943071 | Mathilde Cordellier                                                                                                                                                |
| 192 |   1009.681492 |     85.383213 | Matt Crook                                                                                                                                                         |
| 193 |   1006.291408 |    664.794167 | Margot Michaud                                                                                                                                                     |
| 194 |    592.821657 |    700.998019 | Markus A. Grohme                                                                                                                                                   |
| 195 |    346.460012 |    593.372294 | Matt Martyniuk                                                                                                                                                     |
| 196 |    436.402248 |    378.834699 | Ferran Sayol                                                                                                                                                       |
| 197 |     17.500680 |    541.233322 | Steven Traver                                                                                                                                                      |
| 198 |    563.025664 |    316.523920 | Kai R. Caspar                                                                                                                                                      |
| 199 |    934.005571 |    415.111789 | Jagged Fang Designs                                                                                                                                                |
| 200 |    943.956410 |    600.885269 | Joedison Rocha                                                                                                                                                     |
| 201 |    233.109884 |    417.379570 | Joanna Wolfe                                                                                                                                                       |
| 202 |    305.007164 |    667.305751 | Alex Slavenko                                                                                                                                                      |
| 203 |     68.350716 |    580.404947 | Kai R. Caspar                                                                                                                                                      |
| 204 |    968.421157 |     86.956539 | Matt Crook                                                                                                                                                         |
| 205 |    185.492466 |     61.627541 | Birgit Lang                                                                                                                                                        |
| 206 |    301.850895 |      9.115287 | Tracy A. Heath                                                                                                                                                     |
| 207 |    109.978253 |    339.484025 | Alexandre Vong                                                                                                                                                     |
| 208 |    550.527946 |     70.596398 | Matt Crook                                                                                                                                                         |
| 209 |    575.656647 |    486.177231 | Kamil S. Jaron                                                                                                                                                     |
| 210 |    790.777771 |     98.284501 | C. Camilo Julián-Caballero                                                                                                                                         |
| 211 |    305.550609 |    130.415361 | Michelle Site                                                                                                                                                      |
| 212 |    178.453144 |    202.849176 | Ron Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                       |
| 213 |     46.663770 |    745.285458 | Matt Crook                                                                                                                                                         |
| 214 |    729.506765 |    151.335599 | Sarah Werning                                                                                                                                                      |
| 215 |    511.582358 |     10.680509 | Scott Hartman                                                                                                                                                      |
| 216 |    711.890084 |    103.967000 | Ferran Sayol                                                                                                                                                       |
| 217 |    472.941367 |    361.380066 | C. Abraczinskas                                                                                                                                                    |
| 218 |    273.253165 |    122.967216 | T. Michael Keesey                                                                                                                                                  |
| 219 |    180.634129 |    124.566676 | Ferran Sayol                                                                                                                                                       |
| 220 |     39.096764 |    712.881978 | Pete Buchholz                                                                                                                                                      |
| 221 |    469.690738 |     17.583148 | Scott Hartman                                                                                                                                                      |
| 222 |    751.672391 |    570.866733 | Jaime Headden                                                                                                                                                      |
| 223 |    800.940846 |    692.359219 | Chris huh                                                                                                                                                          |
| 224 |    970.773981 |    479.620655 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 225 |    879.973583 |    530.570358 | Zimices                                                                                                                                                            |
| 226 |    508.231008 |    727.549320 | Y. de Hoev. (vectorized by T. Michael Keesey)                                                                                                                      |
| 227 |     18.701306 |    762.195319 | Steven Traver                                                                                                                                                      |
| 228 |     91.556500 |    203.825322 | Maija Karala                                                                                                                                                       |
| 229 |    271.559705 |     16.096770 | Evan-Amos (vectorized by T. Michael Keesey)                                                                                                                        |
| 230 |     45.300272 |    795.477715 | Jack Mayer Wood                                                                                                                                                    |
| 231 |    860.965304 |    751.083541 | Nobu Tamura, vectorized by Zimices                                                                                                                                 |
| 232 |    638.246190 |    433.661988 | NA                                                                                                                                                                 |
| 233 |    204.450132 |    634.851422 | Iain Reid                                                                                                                                                          |
| 234 |     50.353048 |    157.507480 | Tracy A. Heath                                                                                                                                                     |
| 235 |    490.141655 |    189.544569 | NA                                                                                                                                                                 |
| 236 |    623.160868 |    344.645088 | Zimices                                                                                                                                                            |
| 237 |     20.305256 |    205.062122 | L. Shyamal                                                                                                                                                         |
| 238 |    579.537092 |    422.510959 | Jaime Headden                                                                                                                                                      |
| 239 |     98.199701 |    246.371810 | Zimices                                                                                                                                                            |
| 240 |    506.731040 |    646.626430 | Melissa Broussard                                                                                                                                                  |
| 241 |    231.076996 |    515.951393 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 242 |    490.522410 |    635.624757 | Agnello Picorelli                                                                                                                                                  |
| 243 |    171.805413 |    660.278306 | Felix Vaux                                                                                                                                                         |
| 244 |    134.633184 |    331.427111 | Matt Crook                                                                                                                                                         |
| 245 |    776.612704 |    524.103036 | Myriam\_Ramirez                                                                                                                                                    |
| 246 |    293.578199 |    524.337912 | Matt Crook                                                                                                                                                         |
| 247 |    870.641303 |     60.083441 | Jiekun He                                                                                                                                                          |
| 248 |    123.690896 |    453.163150 | Jagged Fang Designs                                                                                                                                                |
| 249 |    727.344812 |    490.970837 | Scott Hartman                                                                                                                                                      |
| 250 |    985.526177 |    654.040765 | Tasman Dixon                                                                                                                                                       |
| 251 |     57.281939 |    561.851322 | Chris huh                                                                                                                                                          |
| 252 |    589.502106 |     69.301790 | Myriam\_Ramirez                                                                                                                                                    |
| 253 |    540.878355 |    776.588687 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 254 |    148.551937 |    302.775384 | Chris huh                                                                                                                                                          |
| 255 |    945.004030 |    305.223876 | NA                                                                                                                                                                 |
| 256 |    920.707315 |    454.419041 | Zimices                                                                                                                                                            |
| 257 |     23.249115 |    282.324085 | Zimices                                                                                                                                                            |
| 258 |     27.547301 |    648.982398 | Alex Slavenko                                                                                                                                                      |
| 259 |     89.060003 |    171.791070 | NA                                                                                                                                                                 |
| 260 |    147.212811 |    726.436172 | Zimices                                                                                                                                                            |
| 261 |    974.536651 |    253.095709 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                       |
| 262 |    406.102269 |     75.639480 | Steven Traver                                                                                                                                                      |
| 263 |     50.527498 |     10.940060 | Scott Hartman                                                                                                                                                      |
| 264 |     64.673432 |    726.969451 | Cesar Julian                                                                                                                                                       |
| 265 |    417.985477 |    766.474358 | Alexander Schmidt-Lebuhn                                                                                                                                           |
| 266 |    527.143292 |     93.033752 | Gabriela Palomo-Munoz                                                                                                                                              |
| 267 |    974.769891 |    754.903913 | Margot Michaud                                                                                                                                                     |
| 268 |    649.685890 |    750.577888 | Todd Marshall, vectorized by Zimices                                                                                                                               |
| 269 |    549.293340 |    428.362068 | Michelle Site                                                                                                                                                      |
| 270 |    744.407482 |    218.178269 | Smokeybjb                                                                                                                                                          |
| 271 |    168.757968 |    231.270579 | Kanako Bessho-Uehara                                                                                                                                               |
| 272 |    547.701067 |     35.456471 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                  |
| 273 |    675.669792 |    787.043552 | Zachary Quigley                                                                                                                                                    |
| 274 |    683.000338 |    618.198081 | Katie S. Collins                                                                                                                                                   |
| 275 |    471.907577 |    653.851787 | Chris huh                                                                                                                                                          |
| 276 |    610.702101 |    168.644503 | Matt Crook                                                                                                                                                         |
| 277 |    633.346730 |    369.623213 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                      |
| 278 |    144.872050 |    559.114288 | Kai R. Caspar                                                                                                                                                      |
| 279 |    324.600494 |    750.461723 | Matt Dempsey                                                                                                                                                       |
| 280 |     15.880155 |    739.824712 | Caleb M. Brown                                                                                                                                                     |
| 281 |    655.410553 |    159.716200 | Mattia Menchetti / Yan Wong                                                                                                                                        |
| 282 |     22.600721 |    261.722928 | Noah Schlottman                                                                                                                                                    |
| 283 |    825.828851 |    634.884115 | Manabu Bessho-Uehara                                                                                                                                               |
| 284 |    491.869205 |    351.849096 | Felix Vaux                                                                                                                                                         |
| 285 |    205.716446 |    344.298703 | Jagged Fang Designs                                                                                                                                                |
| 286 |    528.682295 |    705.593425 | Caleb M. Brown                                                                                                                                                     |
| 287 |    153.321646 |    457.856360 | (unknown)                                                                                                                                                          |
| 288 |    234.121975 |    499.987929 | CNZdenek                                                                                                                                                           |
| 289 |    555.319625 |    502.600800 | Noah Schlottman                                                                                                                                                    |
| 290 |    301.544047 |    779.101671 | Gabriela Palomo-Munoz                                                                                                                                              |
| 291 |    472.247605 |    483.437800 | Kent Sorgon                                                                                                                                                        |
| 292 |    902.196181 |    515.663839 | Christoph Schomburg                                                                                                                                                |
| 293 |    666.075654 |    461.062320 | Gabriela Palomo-Munoz                                                                                                                                              |
| 294 |    777.467267 |    304.076190 | Tasman Dixon                                                                                                                                                       |
| 295 |    100.754736 |    788.103849 | Chase Brownstein                                                                                                                                                   |
| 296 |    447.785148 |    238.677712 | Oliver Griffith                                                                                                                                                    |
| 297 |    349.854635 |    337.664538 | NA                                                                                                                                                                 |
| 298 |    723.668907 |    316.710297 | Dean Schnabel                                                                                                                                                      |
| 299 |    537.123048 |    630.076532 | NA                                                                                                                                                                 |
| 300 |     18.010533 |     26.504701 | Markus A. Grohme                                                                                                                                                   |
| 301 |    847.926241 |    763.316134 | Steven Traver                                                                                                                                                      |
| 302 |    531.114324 |    574.369334 | Pete Buchholz                                                                                                                                                      |
| 303 |    607.951278 |     17.525325 | Noah Schlottman, photo by Museum of Geology, University of Tartu                                                                                                   |
| 304 |     33.011890 |    301.528881 | Beth Reinke                                                                                                                                                        |
| 305 |     15.345348 |    508.088483 | Tasman Dixon                                                                                                                                                       |
| 306 |    876.587279 |    311.969569 | Gabriela Palomo-Munoz                                                                                                                                              |
| 307 |    502.340379 |    505.557636 | Tracy A. Heath                                                                                                                                                     |
| 308 |    929.540538 |    361.617231 | Jose Carlos Arenas-Monroy                                                                                                                                          |
| 309 |    455.605209 |     83.339022 | NA                                                                                                                                                                 |
| 310 |    452.198767 |    782.599430 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                 |
| 311 |     87.497227 |    471.716783 | Scott Hartman                                                                                                                                                      |
| 312 |     83.398703 |    447.801786 | Zimices                                                                                                                                                            |
| 313 |    205.356480 |    424.321160 | Gareth Monger                                                                                                                                                      |
| 314 |    771.020224 |    147.298363 | T. Michael Keesey                                                                                                                                                  |
| 315 |    873.399421 |    781.904282 | Zimices                                                                                                                                                            |
| 316 |    749.452039 |    514.425565 | Carlos Cano-Barbacil                                                                                                                                               |
| 317 |    285.157899 |    148.271349 | Ferran Sayol                                                                                                                                                       |
| 318 |    999.238884 |    479.142300 | Nobu Tamura, vectorized by Zimices                                                                                                                                 |
| 319 |    633.688589 |    685.641014 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                  |
| 320 |    403.611283 |    568.197546 | Michael Scroggie                                                                                                                                                   |
| 321 |    886.467083 |    423.460744 | Nobu Tamura                                                                                                                                                        |
| 322 |     30.309708 |    112.088718 | Lukasiniho                                                                                                                                                         |
| 323 |    830.072073 |      6.077744 | NA                                                                                                                                                                 |
| 324 |    704.661427 |    526.531165 | Zimices                                                                                                                                                            |
| 325 |     38.515205 |    173.603215 | Birgit Lang                                                                                                                                                        |
| 326 |    548.982677 |    244.590455 | Verisimilus                                                                                                                                                        |
| 327 |    899.183709 |    182.769956 | Nobu Tamura, vectorized by Zimices                                                                                                                                 |
| 328 |     18.884694 |    490.050809 | Melissa Broussard                                                                                                                                                  |
| 329 |    227.327632 |    245.757742 | Gareth Monger                                                                                                                                                      |
| 330 |    541.457411 |    139.148266 | Chris huh                                                                                                                                                          |
| 331 |    339.980595 |    173.806836 | Scott Hartman                                                                                                                                                      |
| 332 |   1008.408901 |     58.342261 | Margot Michaud                                                                                                                                                     |
| 333 |    534.035554 |    204.924511 | Zimices                                                                                                                                                            |
| 334 |    728.735210 |     94.437192 | Zimices                                                                                                                                                            |
| 335 |    883.639603 |    197.419553 | Collin Gross                                                                                                                                                       |
| 336 |    970.542112 |    362.781364 | Yan Wong from illustration by Charles Orbigny                                                                                                                      |
| 337 |    936.959776 |    431.114145 | Jakovche                                                                                                                                                           |
| 338 |    569.794800 |    256.433892 | Andreas Hejnol                                                                                                                                                     |
| 339 |    167.222775 |     67.798334 | Iain Reid                                                                                                                                                          |
| 340 |    735.270428 |    734.593954 | Abraão Leite                                                                                                                                                       |
| 341 |     79.476418 |    340.543804 | Óscar San-Isidro (vectorized by T. Michael Keesey)                                                                                                                 |
| 342 |    417.536342 |    791.271222 | NA                                                                                                                                                                 |
| 343 |    586.183516 |    305.864002 | NA                                                                                                                                                                 |
| 344 |    366.495036 |    443.680460 | Emily Willoughby                                                                                                                                                   |
| 345 |    355.316577 |    294.494316 | Zimices                                                                                                                                                            |
| 346 |    121.097691 |    583.349171 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                     |
| 347 |     49.333056 |    583.366103 | Gabriela Palomo-Munoz                                                                                                                                              |
| 348 |    611.043651 |    753.655531 | Emily Willoughby                                                                                                                                                   |
| 349 |    796.778308 |    737.781674 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                |
| 350 |    868.429732 |     41.134488 | Chris huh                                                                                                                                                          |
| 351 |    254.871621 |    657.748095 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                      |
| 352 |    652.084703 |      4.563880 | Collin Gross                                                                                                                                                       |
| 353 |    577.974360 |    545.625773 | Chris huh                                                                                                                                                          |
| 354 |     37.331393 |     55.382622 | Gabriela Palomo-Munoz                                                                                                                                              |
| 355 |    595.594407 |    556.978088 | NA                                                                                                                                                                 |
| 356 |    171.148025 |    730.545241 | NA                                                                                                                                                                 |
| 357 |    673.272737 |    752.713249 | Conty (vectorized by T. Michael Keesey)                                                                                                                            |
| 358 |    539.648689 |    338.570524 | Matt Crook                                                                                                                                                         |
| 359 |    738.174326 |    590.390324 | Michael Scroggie                                                                                                                                                   |
| 360 |    352.884524 |    471.347935 | DW Bapst (Modified from Bulman, 1964)                                                                                                                              |
| 361 |    723.361559 |    414.721896 | Margot Michaud                                                                                                                                                     |
| 362 |    430.413069 |    248.628595 | Gareth Monger                                                                                                                                                      |
| 363 |      9.832615 |    175.766773 | Dean Schnabel                                                                                                                                                      |
| 364 |    941.027425 |    399.837144 | Gareth Monger                                                                                                                                                      |
| 365 |    910.595681 |    783.631029 | Chris huh                                                                                                                                                          |
| 366 |    239.474469 |    783.113059 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                                 |
| 367 |    181.671893 |    519.432015 | NA                                                                                                                                                                 |
| 368 |    664.361738 |    676.176939 | Margot Michaud                                                                                                                                                     |
| 369 |    563.820648 |    556.330192 | Gareth Monger                                                                                                                                                      |
| 370 |    716.248661 |    788.877764 | Collin Gross                                                                                                                                                       |
| 371 |    552.114828 |      5.698311 | Tyler Greenfield                                                                                                                                                   |
| 372 |    952.405271 |    117.095799 | Ben Liebeskind                                                                                                                                                     |
| 373 |    925.663198 |    536.827579 | Roberto Díaz Sibaja                                                                                                                                                |
| 374 |    135.738407 |    137.606913 | Chris huh                                                                                                                                                          |
| 375 |    802.787797 |     20.839482 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 376 |    148.243102 |    489.324543 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                      |
| 377 |    286.325315 |    463.235622 | Terpsichores                                                                                                                                                       |
| 378 |      9.514355 |    365.283007 | Martin R. Smith, after Skovsted et al 2015                                                                                                                         |
| 379 |    837.556462 |     42.673078 | Cathy                                                                                                                                                              |
| 380 |   1012.142025 |    371.525439 | Ferran Sayol                                                                                                                                                       |
| 381 |    386.986263 |    477.997794 | Alex Slavenko                                                                                                                                                      |
| 382 |     15.638237 |     15.140063 | Scott Hartman                                                                                                                                                      |
| 383 |    711.527708 |    243.572924 | Lisa Byrne                                                                                                                                                         |
| 384 |    782.312322 |    439.367329 | Jaime Headden                                                                                                                                                      |
| 385 |     56.716899 |    406.023107 | Matt Wilkins                                                                                                                                                       |
| 386 |    185.897989 |    169.403842 | Gabriela Palomo-Munoz                                                                                                                                              |
| 387 |    107.577583 |     50.457261 | Gabriela Palomo-Munoz                                                                                                                                              |
| 388 |    928.069600 |    557.655089 | Christoph Schomburg                                                                                                                                                |
| 389 |    284.301718 |    378.405453 | Chris huh                                                                                                                                                          |
| 390 |    584.178425 |    692.994000 | Steven Traver                                                                                                                                                      |
| 391 |    557.754915 |    790.266804 | Margot Michaud                                                                                                                                                     |
| 392 |     15.920301 |    577.582541 | Scott Hartman                                                                                                                                                      |
| 393 |    205.709531 |      7.737771 | Smokeybjb                                                                                                                                                          |
| 394 |     15.049300 |    152.261429 | Zimices                                                                                                                                                            |
| 395 |    212.641642 |    402.075436 | Jake Warner                                                                                                                                                        |
| 396 |    195.272077 |    495.813721 | Tasman Dixon                                                                                                                                                       |
| 397 |    214.259603 |    289.551936 | Sarah Werning                                                                                                                                                      |
| 398 |    375.660385 |    786.197410 | Maija Karala                                                                                                                                                       |
| 399 |    486.694882 |    301.790373 | Scott Hartman                                                                                                                                                      |
| 400 |     19.508383 |     79.906744 | Scott Reid                                                                                                                                                         |
| 401 |    194.302386 |    775.174109 | Tasman Dixon                                                                                                                                                       |
| 402 |    102.407407 |    476.466758 | Markus A. Grohme                                                                                                                                                   |
| 403 |    857.441361 |    273.159431 | Lukas Panzarin                                                                                                                                                     |
| 404 |    263.344012 |     86.990770 | Ferran Sayol                                                                                                                                                       |
| 405 |    679.367823 |    145.370482 | Jagged Fang Designs                                                                                                                                                |
| 406 |    465.820635 |    259.113394 | Conty (vectorized by T. Michael Keesey)                                                                                                                            |
| 407 |    297.441052 |    359.532908 | Armin Reindl                                                                                                                                                       |
| 408 |    898.395737 |    770.800805 | Jaime Headden                                                                                                                                                      |
| 409 |    738.431169 |    109.298503 | Markus A. Grohme                                                                                                                                                   |
| 410 |    394.114248 |     12.158806 | I. Sácek, Sr. (vectorized by T. Michael Keesey)                                                                                                                    |
| 411 |    907.802613 |    796.582988 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                    |
| 412 |    726.162683 |    168.739530 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                                |
| 413 |    828.302674 |    334.252030 | Oscar Sanisidro                                                                                                                                                    |
| 414 |     62.363234 |    427.859208 | Gareth Monger                                                                                                                                                      |
| 415 |    739.528044 |    296.703814 | Tyler Greenfield                                                                                                                                                   |
| 416 |    486.568827 |     11.589338 | Darius Nau                                                                                                                                                         |
| 417 |    885.823519 |    433.042189 | Lily Hughes                                                                                                                                                        |
| 418 |    129.833073 |     68.813561 | Matt Dempsey                                                                                                                                                       |
| 419 |    645.220530 |    230.220714 | NA                                                                                                                                                                 |
| 420 |    288.258929 |    619.701718 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 421 |    785.096435 |    773.412947 | Jagged Fang Designs                                                                                                                                                |
| 422 |    564.651579 |    751.724656 | Maija Karala                                                                                                                                                       |
| 423 |    694.050066 |    687.026231 | Zimices                                                                                                                                                            |
| 424 |    419.252336 |    464.138796 | Margot Michaud                                                                                                                                                     |
| 425 |    947.493427 |    379.796529 | Becky Barnes                                                                                                                                                       |
| 426 |    171.456078 |    569.785831 | NA                                                                                                                                                                 |
| 427 |    300.519638 |    591.204517 | Scott Hartman                                                                                                                                                      |
| 428 |    795.613812 |    134.526904 | Matt Crook                                                                                                                                                         |
| 429 |    727.270876 |    342.277720 | Rebecca Groom                                                                                                                                                      |
| 430 |    475.273545 |    394.438008 | Jagged Fang Designs                                                                                                                                                |
| 431 |    870.026884 |    506.648106 | Scott Hartman                                                                                                                                                      |
| 432 |    940.845581 |    642.166408 | NA                                                                                                                                                                 |
| 433 |    830.901272 |    461.156752 | NA                                                                                                                                                                 |
| 434 |    363.610946 |    627.765935 | Chris huh                                                                                                                                                          |
| 435 |    859.494069 |    702.875991 | Beth Reinke                                                                                                                                                        |
| 436 |     88.774527 |    329.149445 | Gareth Monger                                                                                                                                                      |
| 437 |   1009.745170 |     17.750577 | Ferran Sayol                                                                                                                                                       |
| 438 |    736.674053 |    352.744092 | Jagged Fang Designs                                                                                                                                                |
| 439 |    674.527724 |    245.908895 | Beth Reinke                                                                                                                                                        |
| 440 |    802.361104 |    620.275962 | Gareth Monger                                                                                                                                                      |
| 441 |    771.134528 |    167.067800 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                      |
| 442 |    315.311563 |    530.768401 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 443 |     46.809680 |    546.689306 | Margot Michaud                                                                                                                                                     |
| 444 |    347.828945 |     14.732582 | Chris huh                                                                                                                                                          |
| 445 |    934.609912 |    570.968214 | Caleb M. Gordon                                                                                                                                                    |
| 446 |    495.073791 |    742.677951 | Gabriela Palomo-Munoz                                                                                                                                              |
| 447 |     58.967653 |    285.618343 | Matt Celeskey                                                                                                                                                      |
| 448 |    218.590742 |    547.997661 | Gareth Monger                                                                                                                                                      |
| 449 |    236.081179 |    281.187537 | Jagged Fang Designs                                                                                                                                                |
| 450 |    298.397107 |    482.069639 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                           |
| 451 |    248.001013 |    406.999412 | NA                                                                                                                                                                 |
| 452 |    514.956601 |     73.518288 | Chris huh                                                                                                                                                          |
| 453 |     48.958323 |    778.325349 | Steven Traver                                                                                                                                                      |
| 454 |    822.188756 |    108.224290 | Steven Traver                                                                                                                                                      |
| 455 |    695.850810 |     56.798103 | Zimices                                                                                                                                                            |
| 456 |    829.323837 |     13.880893 | Smokeybjb                                                                                                                                                          |
| 457 |    603.668500 |    683.294043 | Christoph Schomburg                                                                                                                                                |
| 458 |    709.025644 |    597.667317 | Jiekun He                                                                                                                                                          |
| 459 |    564.339131 |    574.714943 | Gareth Monger                                                                                                                                                      |
| 460 |    642.921701 |    390.223856 | NA                                                                                                                                                                 |
| 461 |    468.970439 |     25.546956 | NA                                                                                                                                                                 |
| 462 |     73.268451 |    712.392715 | Cesar Julian                                                                                                                                                       |
| 463 |    360.275265 |      5.213012 | Jagged Fang Designs                                                                                                                                                |
| 464 |     73.292866 |    238.985116 | Ludwik Gasiorowski                                                                                                                                                 |
| 465 |     21.679797 |    729.224502 | Roberto Díaz Sibaja                                                                                                                                                |
| 466 |    144.062248 |    246.528276 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                 |
| 467 |     98.868104 |    420.616091 | Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)                                                                                      |
| 468 |    283.149996 |    367.494934 | Noah Schlottman, photo by Antonio Guillén                                                                                                                          |
| 469 |    112.870979 |    361.172026 | Matt Crook                                                                                                                                                         |
| 470 |    792.358806 |    558.599111 | NA                                                                                                                                                                 |
| 471 |    665.234149 |    496.365830 | Scott Hartman                                                                                                                                                      |
| 472 |    653.967523 |    619.812236 | Chris huh                                                                                                                                                          |
| 473 |    613.347279 |    794.135025 | Siobhon Egan                                                                                                                                                       |
| 474 |     16.992534 |    322.671097 | Andrew A. Farke                                                                                                                                                    |
| 475 |    841.632123 |     87.956607 | Ferran Sayol                                                                                                                                                       |
| 476 |    997.065784 |    161.375956 | Noah Schlottman                                                                                                                                                    |
| 477 |    280.599974 |    757.548166 | T. Michael Keesey                                                                                                                                                  |
| 478 |    227.180097 |    140.744943 | NA                                                                                                                                                                 |
| 479 |    584.445760 |    661.448060 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                           |
| 480 |    470.113057 |    292.275209 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                               |
| 481 |    321.476653 |    488.013333 | Ignacio Contreras                                                                                                                                                  |
| 482 |    618.984029 |     61.223471 | Gareth Monger                                                                                                                                                      |
| 483 |    229.116750 |    711.596281 | Nobu Tamura, vectorized by Zimices                                                                                                                                 |
| 484 |    194.392778 |    675.334503 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                |
| 485 |    277.343492 |    658.652634 | Birgit Lang, based on a photo by D. Sikes                                                                                                                          |
| 486 |    262.849100 |    261.498308 | Kanchi Nanjo                                                                                                                                                       |
| 487 |    593.047208 |    131.571422 | Jaime Headden                                                                                                                                                      |
| 488 |    244.158464 |    766.772585 | Markus A. Grohme                                                                                                                                                   |
| 489 |    965.188054 |    294.220124 | Fernando Carezzano                                                                                                                                                 |
| 490 |    541.629439 |    608.744555 | Chris huh                                                                                                                                                          |
| 491 |     76.434707 |    458.876788 | Ignacio Contreras                                                                                                                                                  |
| 492 |    288.986951 |    715.538599 | Margot Michaud                                                                                                                                                     |
| 493 |    867.412645 |    350.289483 | Gareth Monger                                                                                                                                                      |
| 494 |    369.258463 |    777.947381 | Sarah Werning                                                                                                                                                      |
| 495 |    490.129339 |    366.759997 | Jagged Fang Designs                                                                                                                                                |
| 496 |    523.792454 |    796.657522 | Christoph Schomburg                                                                                                                                                |
| 497 |    252.965271 |     11.955289 | Jagged Fang Designs                                                                                                                                                |
| 498 |    211.812379 |    793.208897 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                  |
| 499 |    777.365841 |    194.329426 | NA                                                                                                                                                                 |
| 500 |    355.287855 |    749.666345 | Jagged Fang Designs                                                                                                                                                |
| 501 |    819.488536 |    705.024999 | T. Michael Keesey                                                                                                                                                  |
| 502 |    910.641556 |     87.703604 | Matt Dempsey                                                                                                                                                       |
| 503 |    514.821456 |    781.868731 | Michael Scroggie                                                                                                                                                   |
| 504 |    651.245652 |    530.983776 | NA                                                                                                                                                                 |
| 505 |    609.551067 |    536.488217 | Kai R. Caspar                                                                                                                                                      |
| 506 |    559.634304 |    779.643350 | Jagged Fang Designs                                                                                                                                                |
| 507 |    733.920036 |    531.882513 | Iain Reid                                                                                                                                                          |
| 508 |    277.493900 |    238.944133 | Kanchi Nanjo                                                                                                                                                       |
| 509 |    877.708551 |    211.726043 | Gareth Monger                                                                                                                                                      |
| 510 |    633.182440 |    594.139804 | Christoph Schomburg                                                                                                                                                |

    #> Your tweet has been posted!
