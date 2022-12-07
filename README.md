
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

Chris huh, Jaime Headden, modified by T. Michael Keesey, Scott Hartman,
Zimices, Michael Scroggie, Jagged Fang Designs, Yan Wong, Tauana J.
Cunha, Ludwik Gąsiorowski, C. Camilo Julián-Caballero, T. Michael Keesey
(after MPF), Emily Willoughby, wsnaccad, Melissa Broussard, T. Michael
Keesey, Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob
Slotow (vectorized by T. Michael Keesey), T. Michael Keesey
(vectorization) and Nadiatalent (photography), Kamil S. Jaron, Darius
Nau, Margot Michaud, T. Michael Keesey, from a photograph by Thea
Boodhoo, Christoph Schomburg, Katie S. Collins, Steven Traver, Ghedo
(vectorized by T. Michael Keesey), Mo Hassan, Ignacio Contreras, Jack
Mayer Wood, Ferran Sayol, Giant Blue Anteater (vectorized by T. Michael
Keesey), Mason McNair, Michelle Site, Gareth Monger, Dmitry Bogdanov
(vectorized by T. Michael Keesey), Prin Pattawaro (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Noah Schlottman,
photo by Casey Dunn, Ingo Braasch, Andrew A. Farke, Stacy Spensley
(Modified), Maija Karala, Smokeybjb, Alexandre Vong, Markus A. Grohme,
Matt Crook, Robert Gay, modified from FunkMonk (Michael B.H.) and T.
Michael Keesey., Erika Schumacher, Andy Wilson, Robbie N. Cada
(vectorized by T. Michael Keesey), Collin Gross, Vanessa Guerra,
Meliponicultor Itaymbere, Robert Gay, modifed from Olegivvit, DW Bapst
(Modified from photograph taken by Charles Mitchell), Alexander
Schmidt-Lebuhn, Pranav Iyer (grey ideas), Esme Ashe-Jepson, Tasman
Dixon, (unknown), Nobu Tamura (vectorized by T. Michael Keesey), (after
Spotila 2004), Carlos Cano-Barbacil, Milton Tan, Karla Martinez, Tony
Ayling, Beth Reinke, Kent Elson Sorgon, DW Bapst (Modified from Bulman,
1964), Joanna Wolfe, Emma Hughes, S.Martini, Dean Schnabel, Jakovche, B
Kimmel, Sharon Wegner-Larsen, Harold N Eyster, Peter Coxhead, Almandine
(vectorized by T. Michael Keesey), L. Shyamal, E. D. Cope (modified by
T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel), Lukasiniho,
Anna Willoughby, James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo
Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael
Keesey), DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).,
Tambja (vectorized by T. Michael Keesey), Ricardo Araújo, Cathy, Mark
Hofstetter (vectorized by T. Michael Keesey), Armin Reindl, Nobu Tamura,
vectorized by Zimices, Kanako Bessho-Uehara, John Conway, Robbie Cada
(vectorized by T. Michael Keesey), FunkMonk, Chase Brownstein, Cagri
Cevrim, Lafage, Burton Robert, USFWS, Matt Martyniuk, Martin Kevil,
Rebecca Groom, T. Michael Keesey (photo by Sean Mack), Matus Valach,
Sarah Werning, T. Michael Keesey (after Walker & al.), Chuanixn Yu,
Kailah Thorn & Mark Hutchinson, Sean McCann, Kristina Gagalova, Anthony
Caravaggi, Shyamal, Michael B. H. (vectorized by T. Michael Keesey),
kreidefossilien.de, FJDegrange, Birgit Lang, Campbell Fleming,
Metalhead64 (vectorized by T. Michael Keesey), Ian Burt (original) and
T. Michael Keesey (vectorization), Lip Kee Yap (vectorized by T. Michael
Keesey), Yan Wong from drawing in The Century Dictionary (1911), Jose
Carlos Arenas-Monroy, Gabriela Palomo-Munoz, Kelly, Nicolas Mongiardino
Koch, Yan Wong (vectorization) from 1873 illustration, Tony Ayling
(vectorized by T. Michael Keesey), Cesar Julian, Ernst Haeckel
(vectorized by T. Michael Keesey), CNZdenek, Rebecca Groom (Based on
Photo by Andreas Trepte), Felix Vaux, M Hutchinson, Emil Schmidt
(vectorized by Maxime Dahirel), Becky Barnes, Patrick Strutzenberger,
Jake Warner, annaleeblysse, Iain Reid, SecretJellyMan, Jon M Laurent,
Kai R. Caspar, Steve Hillebrand/U. S. Fish and Wildlife Service (source
photo), T. Michael Keesey (vectorization), Oscar Sanisidro, Tyler
Greenfield, T. Michael Keesey (from a photo by Maximilian Paradiz),
Aviceda (photo) & T. Michael Keesey, Josefine Bohr Brask, Noah
Schlottman, photo from Casey Dunn, Scott Reid, Michael Scroggie, from
original photograph by Gary M. Stolz, USFWS (original photograph in
public domain)., xgirouxb, Sergio A. Muñoz-Gómez, Original drawing by
Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja, Henry Fairfield
Osborn, vectorized by Zimices, Myriam\_Ramirez, Filip em, Obsidian Soul
(vectorized by T. Michael Keesey), Ricardo N. Martinez & Oscar A.
Alcober, Matt Dempsey, Dmitry Bogdanov, vectorized by Zimices, Steven
Coombs, Nobu Tamura, Mette Aumala, Abraão Leite, Jaime Headden, Mathew
Wedel, Ghedoghedo (vectorized by T. Michael Keesey), Sebastian
Stabinger, Oren Peles / vectorized by Yan Wong, Mattia Menchetti / Yan
Wong, Manabu Bessho-Uehara, Alex Slavenko, M Kolmann, Tim Bertelink
(modified by T. Michael Keesey), John Gould (vectorized by T. Michael
Keesey), Frank Denota, Chris Hay, Isaure Scavezzoni, Siobhon Egan, New
York Zoological Society, Yan Wong from illustration by Jules Richard
(1907), Timothy Knepp of the U.S. Fish and Wildlife Service
(illustration) and Timothy J. Bartley (silhouette), Darren Naish
(vectorize by T. Michael Keesey), SauropodomorphMonarch

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                         |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    142.175261 |    774.409591 | Chris huh                                                                                                                                                      |
|   2 |    811.106970 |    316.991312 | Jaime Headden, modified by T. Michael Keesey                                                                                                                   |
|   3 |    232.415156 |    197.634327 | Scott Hartman                                                                                                                                                  |
|   4 |     80.857067 |    541.686086 | NA                                                                                                                                                             |
|   5 |    256.961378 |     70.400462 | Zimices                                                                                                                                                        |
|   6 |    817.686215 |    582.349748 | Michael Scroggie                                                                                                                                               |
|   7 |    341.154043 |    384.822410 | Jagged Fang Designs                                                                                                                                            |
|   8 |    608.680716 |    360.418047 | Yan Wong                                                                                                                                                       |
|   9 |    599.471837 |    511.749533 | Tauana J. Cunha                                                                                                                                                |
|  10 |    741.820961 |    189.257211 | Ludwik Gąsiorowski                                                                                                                                             |
|  11 |    866.527877 |     85.303241 | C. Camilo Julián-Caballero                                                                                                                                     |
|  12 |     98.602125 |    415.219446 | NA                                                                                                                                                             |
|  13 |    396.958504 |    175.660273 | T. Michael Keesey (after MPF)                                                                                                                                  |
|  14 |    202.184039 |    360.813951 | Emily Willoughby                                                                                                                                               |
|  15 |    108.546231 |    733.682606 | wsnaccad                                                                                                                                                       |
|  16 |    848.347856 |    395.615954 | Melissa Broussard                                                                                                                                              |
|  17 |    554.753809 |    676.808252 | T. Michael Keesey                                                                                                                                              |
|  18 |    261.303327 |    563.498640 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                            |
|  19 |    441.395252 |     64.785451 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                |
|  20 |    480.508804 |    514.063959 | NA                                                                                                                                                             |
|  21 |    803.711758 |    744.960374 | Kamil S. Jaron                                                                                                                                                 |
|  22 |    706.545683 |    437.698050 | Darius Nau                                                                                                                                                     |
|  23 |     88.378866 |    627.108146 | Margot Michaud                                                                                                                                                 |
|  24 |    209.819400 |    646.096675 | Jagged Fang Designs                                                                                                                                            |
|  25 |    930.028945 |    531.355424 | T. Michael Keesey, from a photograph by Thea Boodhoo                                                                                                           |
|  26 |    400.199421 |    270.430926 | Christoph Schomburg                                                                                                                                            |
|  27 |    291.370079 |    722.528956 | Katie S. Collins                                                                                                                                               |
|  28 |    900.077190 |    255.332251 | Steven Traver                                                                                                                                                  |
|  29 |    612.565093 |    158.919480 | Melissa Broussard                                                                                                                                              |
|  30 |    496.146398 |    204.766056 | Steven Traver                                                                                                                                                  |
|  31 |    105.150988 |    157.206772 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                        |
|  32 |    562.869168 |    444.169509 | Mo Hassan                                                                                                                                                      |
|  33 |    416.441377 |    661.551255 | Jagged Fang Designs                                                                                                                                            |
|  34 |    856.405687 |    342.360872 | Ignacio Contreras                                                                                                                                              |
|  35 |    418.321143 |    439.876718 | Jack Mayer Wood                                                                                                                                                |
|  36 |    657.458219 |    232.865629 | Steven Traver                                                                                                                                                  |
|  37 |    558.703937 |     49.371838 | Ferran Sayol                                                                                                                                                   |
|  38 |    691.009935 |    628.111213 | Yan Wong                                                                                                                                                       |
|  39 |    720.733523 |    127.721809 | Jagged Fang Designs                                                                                                                                            |
|  40 |     61.000760 |    255.818869 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                          |
|  41 |    132.082766 |     60.416523 | Mason McNair                                                                                                                                                   |
|  42 |    530.714363 |    312.066189 | Michelle Site                                                                                                                                                  |
|  43 |    934.479757 |    647.517337 | Gareth Monger                                                                                                                                                  |
|  44 |    940.786858 |    444.031377 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
|  45 |    440.344584 |    611.259670 | NA                                                                                                                                                             |
|  46 |    898.116647 |    156.480945 | Prin Pattawaro (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
|  47 |    778.763933 |    391.963768 | Noah Schlottman, photo by Casey Dunn                                                                                                                           |
|  48 |    190.152640 |    454.139762 | Margot Michaud                                                                                                                                                 |
|  49 |    853.027758 |     36.460706 | Ingo Braasch                                                                                                                                                   |
|  50 |    733.338556 |     34.645666 | Zimices                                                                                                                                                        |
|  51 |    532.276009 |    137.656516 | Andrew A. Farke                                                                                                                                                |
|  52 |    379.751715 |    516.635004 | Stacy Spensley (Modified)                                                                                                                                      |
|  53 |    257.612709 |    311.156098 | Chris huh                                                                                                                                                      |
|  54 |    666.577516 |    734.233507 | NA                                                                                                                                                             |
|  55 |     43.707952 |    440.682305 | Maija Karala                                                                                                                                                   |
|  56 |    739.482952 |    706.812301 | Chris huh                                                                                                                                                      |
|  57 |    926.855667 |     60.871078 | Smokeybjb                                                                                                                                                      |
|  58 |    242.949166 |    276.553375 | Gareth Monger                                                                                                                                                  |
|  59 |     77.018266 |    316.500191 | Steven Traver                                                                                                                                                  |
|  60 |    954.331069 |    310.890135 | T. Michael Keesey                                                                                                                                              |
|  61 |    972.885780 |    566.051258 | Alexandre Vong                                                                                                                                                 |
|  62 |    952.693443 |    755.670455 | Zimices                                                                                                                                                        |
|  63 |    424.207679 |    768.485360 | Markus A. Grohme                                                                                                                                               |
|  64 |    817.245117 |    209.602228 | Matt Crook                                                                                                                                                     |
|  65 |    260.516321 |     13.368582 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                       |
|  66 |    313.062948 |     86.596250 | Margot Michaud                                                                                                                                                 |
|  67 |    678.488791 |     62.771034 | Erika Schumacher                                                                                                                                               |
|  68 |    472.248855 |    684.400816 | Zimices                                                                                                                                                        |
|  69 |    148.110057 |    240.654661 | NA                                                                                                                                                             |
|  70 |    354.499027 |    327.241584 | Jagged Fang Designs                                                                                                                                            |
|  71 |    715.144023 |    514.003994 | NA                                                                                                                                                             |
|  72 |    955.229171 |    374.028112 | Andy Wilson                                                                                                                                                    |
|  73 |    805.985711 |    463.761439 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                               |
|  74 |    965.792549 |    126.479726 | Collin Gross                                                                                                                                                   |
|  75 |    296.230134 |    654.963320 | Vanessa Guerra                                                                                                                                                 |
|  76 |    172.753458 |    556.395914 | Meliponicultor Itaymbere                                                                                                                                       |
|  77 |     57.039052 |     81.105209 | Robert Gay, modifed from Olegivvit                                                                                                                             |
|  78 |     27.754092 |    183.490329 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                  |
|  79 |    978.858834 |    694.266950 | Alexander Schmidt-Lebuhn                                                                                                                                       |
|  80 |    185.713043 |    689.925205 | Pranav Iyer (grey ideas)                                                                                                                                       |
|  81 |    944.165823 |     28.237305 | Andrew A. Farke                                                                                                                                                |
|  82 |    301.841937 |    448.638252 | Esme Ashe-Jepson                                                                                                                                               |
|  83 |    674.301654 |    756.811612 | Tasman Dixon                                                                                                                                                   |
|  84 |    977.727842 |    221.400708 | Margot Michaud                                                                                                                                                 |
|  85 |    588.754638 |    205.883974 | Maija Karala                                                                                                                                                   |
|  86 |    335.190925 |    180.506945 | Ferran Sayol                                                                                                                                                   |
|  87 |    403.774544 |    555.588987 | (unknown)                                                                                                                                                      |
|  88 |     73.347307 |    481.755537 | T. Michael Keesey                                                                                                                                              |
|  89 |    622.321300 |     91.848820 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
|  90 |    749.542135 |    363.323929 | Emily Willoughby                                                                                                                                               |
|  91 |    279.630579 |    517.115930 | (after Spotila 2004)                                                                                                                                           |
|  92 |    177.915068 |    132.107684 | NA                                                                                                                                                             |
|  93 |     52.701163 |    564.378448 | Smokeybjb                                                                                                                                                      |
|  94 |    678.437762 |    507.818027 | Matt Crook                                                                                                                                                     |
|  95 |    202.152078 |    749.762029 | Carlos Cano-Barbacil                                                                                                                                           |
|  96 |    765.024088 |    283.286311 | Milton Tan                                                                                                                                                     |
|  97 |    671.767055 |    574.444639 | Milton Tan                                                                                                                                                     |
|  98 |    140.065944 |    204.238766 | Scott Hartman                                                                                                                                                  |
|  99 |    994.076259 |     44.934052 | Karla Martinez                                                                                                                                                 |
| 100 |    489.468562 |    736.062836 | T. Michael Keesey                                                                                                                                              |
| 101 |    975.793902 |    651.787545 | Andy Wilson                                                                                                                                                    |
| 102 |    992.875167 |    259.264280 | Michelle Site                                                                                                                                                  |
| 103 |    493.380364 |    383.935080 | Zimices                                                                                                                                                        |
| 104 |    210.866298 |    391.938349 | Tony Ayling                                                                                                                                                    |
| 105 |    671.244927 |    277.422744 | NA                                                                                                                                                             |
| 106 |    172.005983 |    717.889017 | NA                                                                                                                                                             |
| 107 |    628.589931 |    300.888439 | Beth Reinke                                                                                                                                                    |
| 108 |    495.029994 |    412.533431 | Steven Traver                                                                                                                                                  |
| 109 |    124.931513 |    491.512995 | Kent Elson Sorgon                                                                                                                                              |
| 110 |    693.996718 |    594.412844 | DW Bapst (Modified from Bulman, 1964)                                                                                                                          |
| 111 |    385.372599 |     95.137826 | NA                                                                                                                                                             |
| 112 |     25.371805 |    716.994096 | Joanna Wolfe                                                                                                                                                   |
| 113 |    933.708428 |    195.090226 | Emma Hughes                                                                                                                                                    |
| 114 |    593.025927 |    116.241301 | Zimices                                                                                                                                                        |
| 115 |    346.822466 |    583.961800 | Steven Traver                                                                                                                                                  |
| 116 |     81.435314 |    637.781150 | S.Martini                                                                                                                                                      |
| 117 |    428.827237 |    311.881728 | Collin Gross                                                                                                                                                   |
| 118 |    900.939846 |    478.836841 | Zimices                                                                                                                                                        |
| 119 |    864.858048 |    765.901512 | Ferran Sayol                                                                                                                                                   |
| 120 |    843.878526 |    792.498024 | T. Michael Keesey                                                                                                                                              |
| 121 |    363.574786 |    782.238845 | Dean Schnabel                                                                                                                                                  |
| 122 |    861.705171 |    715.847653 | Jakovche                                                                                                                                                       |
| 123 |     84.740673 |     79.675081 | B Kimmel                                                                                                                                                       |
| 124 |    645.934677 |     27.760152 | Sharon Wegner-Larsen                                                                                                                                           |
| 125 |    504.877663 |     18.273908 | T. Michael Keesey                                                                                                                                              |
| 126 |   1002.496671 |    392.982230 | Andy Wilson                                                                                                                                                    |
| 127 |    201.464014 |    155.311891 | Dean Schnabel                                                                                                                                                  |
| 128 |    402.855075 |    737.791999 | Margot Michaud                                                                                                                                                 |
| 129 |    132.283747 |    386.105051 | NA                                                                                                                                                             |
| 130 |    793.330928 |    133.861480 | Gareth Monger                                                                                                                                                  |
| 131 |    796.667137 |    221.407498 | NA                                                                                                                                                             |
| 132 |    943.723619 |    143.707566 | Gareth Monger                                                                                                                                                  |
| 133 |    730.345475 |    656.894512 | Scott Hartman                                                                                                                                                  |
| 134 |    808.878647 |    422.058654 | Harold N Eyster                                                                                                                                                |
| 135 |    542.758735 |    255.718894 | Margot Michaud                                                                                                                                                 |
| 136 |     12.724533 |    501.162753 | Peter Coxhead                                                                                                                                                  |
| 137 |     76.590217 |    204.029073 | Almandine (vectorized by T. Michael Keesey)                                                                                                                    |
| 138 |    491.620645 |    352.439250 | Karla Martinez                                                                                                                                                 |
| 139 |    264.484046 |     28.707798 | Chris huh                                                                                                                                                      |
| 140 |     81.362862 |    103.278092 | L. Shyamal                                                                                                                                                     |
| 141 |    718.918839 |    763.617670 | Tasman Dixon                                                                                                                                                   |
| 142 |    650.272870 |      7.048555 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                               |
| 143 |    519.441078 |    592.008242 | Andy Wilson                                                                                                                                                    |
| 144 |    698.682136 |    735.247566 | Harold N Eyster                                                                                                                                                |
| 145 |    373.852005 |    679.028163 | Lukasiniho                                                                                                                                                     |
| 146 |     30.789161 |    103.176306 | Anna Willoughby                                                                                                                                                |
| 147 |    644.686602 |    479.663966 | (unknown)                                                                                                                                                      |
| 148 |    454.105008 |    483.280052 | Matt Crook                                                                                                                                                     |
| 149 |     25.514018 |    360.645040 | Steven Traver                                                                                                                                                  |
| 150 |    631.181359 |    695.351455 | Matt Crook                                                                                                                                                     |
| 151 |     10.437455 |    578.393140 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                           |
| 152 |    386.259261 |    688.853993 | Scott Hartman                                                                                                                                                  |
| 153 |     17.362668 |     56.416514 | DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).                                                                                                  |
| 154 |    317.020094 |    347.773525 | Tambja (vectorized by T. Michael Keesey)                                                                                                                       |
| 155 |    356.684010 |     20.341855 | Ricardo Araújo                                                                                                                                                 |
| 156 |    427.992280 |    794.733979 | Scott Hartman                                                                                                                                                  |
| 157 |     63.995117 |    573.674780 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 158 |     20.194223 |    764.159195 | Cathy                                                                                                                                                          |
| 159 |    733.032965 |    561.595895 | NA                                                                                                                                                             |
| 160 |    534.826449 |     72.175477 | Tasman Dixon                                                                                                                                                   |
| 161 |    464.178678 |    299.434273 | Mark Hofstetter (vectorized by T. Michael Keesey)                                                                                                              |
| 162 |    336.629021 |    430.906976 | Scott Hartman                                                                                                                                                  |
| 163 |    689.341621 |    669.495569 | Dean Schnabel                                                                                                                                                  |
| 164 |    360.070948 |     59.146445 | Joanna Wolfe                                                                                                                                                   |
| 165 |    261.391552 |    384.052894 | Armin Reindl                                                                                                                                                   |
| 166 |    362.486067 |    390.671521 | Zimices                                                                                                                                                        |
| 167 |    512.931112 |     83.083645 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 168 |    182.089249 |     68.210568 | Lukasiniho                                                                                                                                                     |
| 169 |    304.189836 |    239.794628 | Zimices                                                                                                                                                        |
| 170 |    497.222855 |    265.092000 | Kanako Bessho-Uehara                                                                                                                                           |
| 171 |    361.752759 |    414.793483 | Andrew A. Farke                                                                                                                                                |
| 172 |    701.625411 |    256.342792 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 173 |    180.840902 |     91.701821 | Scott Hartman                                                                                                                                                  |
| 174 |    355.867795 |    723.804490 | Alexandre Vong                                                                                                                                                 |
| 175 |    829.143416 |    305.001399 | Markus A. Grohme                                                                                                                                               |
| 176 |    149.239549 |    288.276242 | John Conway                                                                                                                                                    |
| 177 |     32.599430 |    694.180431 | Scott Hartman                                                                                                                                                  |
| 178 |    746.862825 |     69.381817 | Scott Hartman                                                                                                                                                  |
| 179 |    434.573020 |    331.346557 | Robbie Cada (vectorized by T. Michael Keesey)                                                                                                                  |
| 180 |    389.719221 |    312.978282 | Andy Wilson                                                                                                                                                    |
| 181 |    826.147676 |    695.762385 | FunkMonk                                                                                                                                                       |
| 182 |    330.828673 |    771.249643 | Margot Michaud                                                                                                                                                 |
| 183 |    639.495038 |    466.563869 | Chase Brownstein                                                                                                                                               |
| 184 |    605.083020 |    658.217657 | Zimices                                                                                                                                                        |
| 185 |    607.715724 |    617.990151 | NA                                                                                                                                                             |
| 186 |    505.585679 |    621.080236 | NA                                                                                                                                                             |
| 187 |    904.966582 |    663.375292 | Cagri Cevrim                                                                                                                                                   |
| 188 |    575.151991 |    316.038293 | Lafage                                                                                                                                                         |
| 189 |    784.223730 |     54.517994 | Burton Robert, USFWS                                                                                                                                           |
| 190 |    887.967488 |    330.430611 | C. Camilo Julián-Caballero                                                                                                                                     |
| 191 |    104.564003 |    110.822663 | Zimices                                                                                                                                                        |
| 192 |    331.086852 |    533.690777 | NA                                                                                                                                                             |
| 193 |    438.775456 |    356.871931 | Matt Martyniuk                                                                                                                                                 |
| 194 |    715.625558 |    323.246778 | T. Michael Keesey                                                                                                                                              |
| 195 |    518.276712 |    658.707762 | Martin Kevil                                                                                                                                                   |
| 196 |    444.608421 |    142.942997 | Gareth Monger                                                                                                                                                  |
| 197 |    270.582176 |    789.277062 | Ferran Sayol                                                                                                                                                   |
| 198 |     18.296208 |    628.376616 | Kent Elson Sorgon                                                                                                                                              |
| 199 |    490.621215 |    443.347399 | Rebecca Groom                                                                                                                                                  |
| 200 |    533.648943 |    559.940174 | T. Michael Keesey (photo by Sean Mack)                                                                                                                         |
| 201 |    701.919620 |    336.269295 | Matus Valach                                                                                                                                                   |
| 202 |    946.458644 |     95.319750 | NA                                                                                                                                                             |
| 203 |    125.863800 |    517.592833 | Smokeybjb                                                                                                                                                      |
| 204 |    557.585120 |    109.774090 | Sarah Werning                                                                                                                                                  |
| 205 |    377.527375 |    605.400669 | T. Michael Keesey (after Walker & al.)                                                                                                                         |
| 206 |    884.304161 |     10.063864 | Chuanixn Yu                                                                                                                                                    |
| 207 |    724.177703 |     10.413958 | Kailah Thorn & Mark Hutchinson                                                                                                                                 |
| 208 |    664.684118 |    309.070049 | Jagged Fang Designs                                                                                                                                            |
| 209 |     43.501608 |    733.089984 | Sean McCann                                                                                                                                                    |
| 210 |    663.998871 |    596.447869 | Zimices                                                                                                                                                        |
| 211 |    364.476528 |     75.367314 | Jaime Headden, modified by T. Michael Keesey                                                                                                                   |
| 212 |    866.818612 |    285.409201 | Gareth Monger                                                                                                                                                  |
| 213 |    293.027491 |    216.115518 | Kristina Gagalova                                                                                                                                              |
| 214 |    141.217856 |    466.836022 | NA                                                                                                                                                             |
| 215 |     67.289212 |    382.623357 | Steven Traver                                                                                                                                                  |
| 216 |     95.854879 |    135.345367 | Zimices                                                                                                                                                        |
| 217 |     67.109270 |    417.940941 | Anthony Caravaggi                                                                                                                                              |
| 218 |    615.518495 |    291.613211 | Shyamal                                                                                                                                                        |
| 219 |    834.191854 |    451.126681 | Jagged Fang Designs                                                                                                                                            |
| 220 |    841.793312 |    422.616415 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                |
| 221 |    665.818935 |    736.084232 | Scott Hartman                                                                                                                                                  |
| 222 |    222.209857 |    299.417993 | Tauana J. Cunha                                                                                                                                                |
| 223 |    520.815407 |    714.074142 | Jagged Fang Designs                                                                                                                                            |
| 224 |    901.787314 |    285.902328 | Carlos Cano-Barbacil                                                                                                                                           |
| 225 |    969.827859 |    509.900104 | kreidefossilien.de                                                                                                                                             |
| 226 |    217.439562 |    794.504499 | Tasman Dixon                                                                                                                                                   |
| 227 |    617.629015 |    433.549863 | FJDegrange                                                                                                                                                     |
| 228 |    806.078404 |    686.292696 | Smokeybjb                                                                                                                                                      |
| 229 |    394.660918 |    711.746132 | Zimices                                                                                                                                                        |
| 230 |    256.132366 |    479.704893 | Matt Crook                                                                                                                                                     |
| 231 |    921.076403 |    119.438914 | Sarah Werning                                                                                                                                                  |
| 232 |    641.616451 |    414.954501 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 233 |    170.679457 |    312.009777 | Matt Crook                                                                                                                                                     |
| 234 |    910.604298 |    503.610916 | Birgit Lang                                                                                                                                                    |
| 235 |    843.085767 |    436.116952 | Beth Reinke                                                                                                                                                    |
| 236 |     78.572452 |     19.474809 | Campbell Fleming                                                                                                                                               |
| 237 |    324.689680 |     25.459860 | Matt Crook                                                                                                                                                     |
| 238 |    118.810157 |    676.480810 | Metalhead64 (vectorized by T. Michael Keesey)                                                                                                                  |
| 239 |    219.201723 |     31.775752 | Erika Schumacher                                                                                                                                               |
| 240 |    393.469801 |    388.335263 | Andy Wilson                                                                                                                                                    |
| 241 |    489.593491 |     87.255105 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                      |
| 242 |    431.601484 |    634.537370 | Jagged Fang Designs                                                                                                                                            |
| 243 |    224.083056 |    594.753796 | FJDegrange                                                                                                                                                     |
| 244 |    810.529230 |    263.888605 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                  |
| 245 |    727.277493 |    257.793998 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 246 |    406.531332 |    470.350618 | Yan Wong from drawing in The Century Dictionary (1911)                                                                                                         |
| 247 |    530.460220 |    410.697545 | Jose Carlos Arenas-Monroy                                                                                                                                      |
| 248 |     41.504511 |    277.424440 | Zimices                                                                                                                                                        |
| 249 |    217.544147 |    127.100799 | Gabriela Palomo-Munoz                                                                                                                                          |
| 250 |     85.260544 |    460.688613 | Armin Reindl                                                                                                                                                   |
| 251 |    438.170061 |    735.030001 | Emily Willoughby                                                                                                                                               |
| 252 |    728.940300 |    748.605855 | Andrew A. Farke                                                                                                                                                |
| 253 |    843.898286 |    288.654265 | Milton Tan                                                                                                                                                     |
| 254 |    347.284801 |    458.964460 | Kelly                                                                                                                                                          |
| 255 |    548.744076 |    782.392311 | Matt Crook                                                                                                                                                     |
| 256 |    100.072886 |    503.811091 | Steven Traver                                                                                                                                                  |
| 257 |    289.633307 |    362.891423 | Dean Schnabel                                                                                                                                                  |
| 258 |    319.958959 |    251.874683 | Christoph Schomburg                                                                                                                                            |
| 259 |    191.943832 |    619.844973 | Chris huh                                                                                                                                                      |
| 260 |    906.751943 |    615.222244 | Matt Crook                                                                                                                                                     |
| 261 |     68.031710 |    680.652463 | Scott Hartman                                                                                                                                                  |
| 262 |    969.752412 |    169.948304 | Nicolas Mongiardino Koch                                                                                                                                       |
| 263 |    618.597212 |     25.371267 | NA                                                                                                                                                             |
| 264 |    874.424345 |    431.872548 | Yan Wong (vectorization) from 1873 illustration                                                                                                                |
| 265 |    737.017395 |    528.545443 | NA                                                                                                                                                             |
| 266 |    608.721138 |    639.072918 | T. Michael Keesey                                                                                                                                              |
| 267 |    731.843810 |    602.317655 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                  |
| 268 |    678.428920 |    466.783064 | Matt Crook                                                                                                                                                     |
| 269 |    977.774017 |    102.983441 | Cesar Julian                                                                                                                                                   |
| 270 |    346.309856 |    139.608061 | Joanna Wolfe                                                                                                                                                   |
| 271 |    609.863161 |    791.308759 | Steven Traver                                                                                                                                                  |
| 272 |    464.515018 |    149.799213 | Matt Crook                                                                                                                                                     |
| 273 |    815.696732 |    197.943309 | Scott Hartman                                                                                                                                                  |
| 274 |    285.538120 |    168.886546 | Zimices                                                                                                                                                        |
| 275 |     34.472606 |    687.491228 | FunkMonk                                                                                                                                                       |
| 276 |     24.525693 |    639.573878 | Beth Reinke                                                                                                                                                    |
| 277 |    164.339723 |     11.644963 | Tasman Dixon                                                                                                                                                   |
| 278 |    897.106370 |    767.130362 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                |
| 279 |    588.082533 |    247.072374 | CNZdenek                                                                                                                                                       |
| 280 |     73.054641 |    649.442437 | Maija Karala                                                                                                                                                   |
| 281 |    289.535404 |    193.336465 | Scott Hartman                                                                                                                                                  |
| 282 |    920.738932 |    404.892308 | Ferran Sayol                                                                                                                                                   |
| 283 |    325.615725 |    216.152950 | Rebecca Groom (Based on Photo by Andreas Trepte)                                                                                                               |
| 284 |    126.168082 |    698.572362 | Felix Vaux                                                                                                                                                     |
| 285 |    707.451180 |    396.534788 | Steven Traver                                                                                                                                                  |
| 286 |    674.897559 |    547.537063 | M Hutchinson                                                                                                                                                   |
| 287 |    198.355775 |     31.351901 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                    |
| 288 |     73.119510 |    283.490793 | Jagged Fang Designs                                                                                                                                            |
| 289 |    460.405329 |    582.220351 | Becky Barnes                                                                                                                                                   |
| 290 |    917.984655 |    328.997172 | Zimices                                                                                                                                                        |
| 291 |    523.429197 |    637.915186 | Patrick Strutzenberger                                                                                                                                         |
| 292 |    892.470317 |    540.646369 | Matt Crook                                                                                                                                                     |
| 293 |    159.385238 |    670.428207 | Ignacio Contreras                                                                                                                                              |
| 294 |    964.994958 |    195.588549 | Carlos Cano-Barbacil                                                                                                                                           |
| 295 |    412.781401 |    350.980490 | Smokeybjb                                                                                                                                                      |
| 296 |   1005.310316 |    433.481321 | Margot Michaud                                                                                                                                                 |
| 297 |    517.705519 |     97.220486 | Jake Warner                                                                                                                                                    |
| 298 |    269.126759 |    250.809915 | Jagged Fang Designs                                                                                                                                            |
| 299 |    603.943343 |     66.835950 | annaleeblysse                                                                                                                                                  |
| 300 |     20.763678 |    433.807547 | Iain Reid                                                                                                                                                      |
| 301 |    901.558659 |    720.906954 | Andy Wilson                                                                                                                                                    |
| 302 |    523.754415 |     12.743409 | Scott Hartman                                                                                                                                                  |
| 303 |    581.758100 |    589.256596 | Beth Reinke                                                                                                                                                    |
| 304 |     38.687785 |     13.529597 | Yan Wong                                                                                                                                                       |
| 305 |   1011.734998 |    630.687118 | SecretJellyMan                                                                                                                                                 |
| 306 |    618.565383 |    241.536451 | Markus A. Grohme                                                                                                                                               |
| 307 |    159.677302 |    181.346826 | Gareth Monger                                                                                                                                                  |
| 308 |    271.377067 |    612.509190 | Jon M Laurent                                                                                                                                                  |
| 309 |    837.076161 |    277.496763 | Gabriela Palomo-Munoz                                                                                                                                          |
| 310 |    294.684572 |    775.281139 | Sharon Wegner-Larsen                                                                                                                                           |
| 311 |    151.461847 |    791.946577 | Chris huh                                                                                                                                                      |
| 312 |    437.146919 |    447.255942 | Kai R. Caspar                                                                                                                                                  |
| 313 |   1005.504190 |    790.132446 | Zimices                                                                                                                                                        |
| 314 |    515.026190 |    334.869045 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                             |
| 315 |    217.848298 |    560.896970 | Oscar Sanisidro                                                                                                                                                |
| 316 |    241.049303 |    775.137801 | Gabriela Palomo-Munoz                                                                                                                                          |
| 317 |    922.735489 |    573.718374 | Dean Schnabel                                                                                                                                                  |
| 318 |    607.829315 |    696.779890 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                            |
| 319 |    518.303824 |    487.503611 | Ingo Braasch                                                                                                                                                   |
| 320 |    424.186331 |    503.667401 | Andy Wilson                                                                                                                                                    |
| 321 |    878.014922 |    694.382099 | Zimices                                                                                                                                                        |
| 322 |    269.419769 |    209.971590 | Maija Karala                                                                                                                                                   |
| 323 |    323.875845 |      6.900188 | Tyler Greenfield                                                                                                                                               |
| 324 |    312.050800 |    158.381115 | Smokeybjb                                                                                                                                                      |
| 325 |    701.264157 |    313.857985 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 326 |    420.067739 |    719.694490 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 327 |    147.515658 |    345.542993 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                         |
| 328 |    245.047766 |    510.223281 | Aviceda (photo) & T. Michael Keesey                                                                                                                            |
| 329 |    221.891975 |    673.264131 | Tauana J. Cunha                                                                                                                                                |
| 330 |    634.216763 |    602.936100 | Josefine Bohr Brask                                                                                                                                            |
| 331 |     13.226043 |    392.385648 | Noah Schlottman, photo from Casey Dunn                                                                                                                         |
| 332 |     61.816890 |    797.514740 | Markus A. Grohme                                                                                                                                               |
| 333 |    239.282792 |    685.767090 | Scott Reid                                                                                                                                                     |
| 334 |    223.572986 |    699.694477 | C. Camilo Julián-Caballero                                                                                                                                     |
| 335 |    376.312141 |     25.720620 | Margot Michaud                                                                                                                                                 |
| 336 |    431.162721 |    463.997861 | Margot Michaud                                                                                                                                                 |
| 337 |    169.645534 |    632.900503 | Matt Crook                                                                                                                                                     |
| 338 |    615.996624 |    120.756215 | Yan Wong                                                                                                                                                       |
| 339 |    359.310447 |    192.152925 | Gareth Monger                                                                                                                                                  |
| 340 |    432.236899 |    386.527260 | Shyamal                                                                                                                                                        |
| 341 |    740.748089 |    474.973226 | Gabriela Palomo-Munoz                                                                                                                                          |
| 342 |    975.026561 |    781.398654 | Andy Wilson                                                                                                                                                    |
| 343 |     58.680566 |    665.554099 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                     |
| 344 |    836.372688 |     18.078540 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 345 |     59.027724 |    714.888594 | Markus A. Grohme                                                                                                                                               |
| 346 |    798.176066 |     11.267041 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 347 |    895.782298 |    596.256433 | xgirouxb                                                                                                                                                       |
| 348 |   1003.341526 |      7.757037 | Zimices                                                                                                                                                        |
| 349 |    631.400916 |    194.136998 | NA                                                                                                                                                             |
| 350 |    276.809305 |    341.847498 | Tasman Dixon                                                                                                                                                   |
| 351 |    562.527339 |    753.340852 | Sergio A. Muñoz-Gómez                                                                                                                                          |
| 352 |    676.421921 |    297.633657 | Anthony Caravaggi                                                                                                                                              |
| 353 |    233.507778 |    654.168249 | Harold N Eyster                                                                                                                                                |
| 354 |    154.723097 |    746.671850 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 355 |    792.687095 |     79.962321 | NA                                                                                                                                                             |
| 356 |    600.458306 |    102.866659 | NA                                                                                                                                                             |
| 357 |    626.752116 |    677.985141 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                         |
| 358 |    290.880101 |    494.869679 | Andy Wilson                                                                                                                                                    |
| 359 |    743.839825 |    131.265689 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                  |
| 360 |     52.293178 |    782.080371 | Myriam\_Ramirez                                                                                                                                                |
| 361 |    319.092892 |    510.449559 | Ferran Sayol                                                                                                                                                   |
| 362 |    432.252997 |    138.203173 | Dean Schnabel                                                                                                                                                  |
| 363 |    471.065393 |    359.268122 | Gareth Monger                                                                                                                                                  |
| 364 |    600.704722 |    577.226508 | Erika Schumacher                                                                                                                                               |
| 365 |    762.181230 |     85.756779 | Gareth Monger                                                                                                                                                  |
| 366 |    458.646079 |    124.024812 | Birgit Lang                                                                                                                                                    |
| 367 |    734.458044 |    583.864331 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 368 |    132.429123 |    476.908786 | Jagged Fang Designs                                                                                                                                            |
| 369 |    202.327218 |    723.864279 | Filip em                                                                                                                                                       |
| 370 |   1017.739582 |    698.078288 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 371 |    103.630885 |    278.718508 | Margot Michaud                                                                                                                                                 |
| 372 |    907.713601 |    711.611870 | Chris huh                                                                                                                                                      |
| 373 |     56.115173 |    174.066693 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                |
| 374 |    882.462032 |    782.815094 | Gareth Monger                                                                                                                                                  |
| 375 |    780.454366 |    240.663392 | Markus A. Grohme                                                                                                                                               |
| 376 |    449.088631 |    643.821054 | Jagged Fang Designs                                                                                                                                            |
| 377 |    721.260237 |    789.022072 | Gabriela Palomo-Munoz                                                                                                                                          |
| 378 |    370.267827 |     83.951974 | NA                                                                                                                                                             |
| 379 |    571.781785 |     88.156596 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                         |
| 380 |    551.610222 |    391.355873 | Jagged Fang Designs                                                                                                                                            |
| 381 |     67.241465 |    693.421973 | Collin Gross                                                                                                                                                   |
| 382 |    782.652013 |    410.113172 | Matt Dempsey                                                                                                                                                   |
| 383 |    798.730084 |    794.398113 | Markus A. Grohme                                                                                                                                               |
| 384 |    478.446841 |    789.078931 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                         |
| 385 |    516.671616 |    240.083796 | Rebecca Groom                                                                                                                                                  |
| 386 |    918.851829 |    209.635843 | NA                                                                                                                                                             |
| 387 |    649.665052 |    772.013316 | Chuanixn Yu                                                                                                                                                    |
| 388 |     68.535753 |    447.297850 | Steven Coombs                                                                                                                                                  |
| 389 |    740.100587 |    491.274278 | Armin Reindl                                                                                                                                                   |
| 390 |    907.524696 |    516.598867 | Nobu Tamura                                                                                                                                                    |
| 391 |    482.785415 |    426.395915 | Scott Hartman                                                                                                                                                  |
| 392 |    331.343272 |    295.204210 | Beth Reinke                                                                                                                                                    |
| 393 |    301.879808 |    628.922950 | T. Michael Keesey                                                                                                                                              |
| 394 |    773.379989 |    793.415998 | Mette Aumala                                                                                                                                                   |
| 395 |    388.368338 |      9.184045 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 396 |    386.090067 |    632.547413 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                  |
| 397 |    144.104219 |    129.753548 | Zimices                                                                                                                                                        |
| 398 |    373.977358 |    348.489655 | Maija Karala                                                                                                                                                   |
| 399 |    529.074260 |    317.057377 | xgirouxb                                                                                                                                                       |
| 400 |    543.906834 |    474.316107 | Steven Traver                                                                                                                                                  |
| 401 |     95.045109 |    580.628575 | Abraão Leite                                                                                                                                                   |
| 402 |    373.860915 |     38.987402 | Kent Elson Sorgon                                                                                                                                              |
| 403 |    628.486486 |     42.439051 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                               |
| 404 |    343.657439 |    703.703762 | Jaime Headden                                                                                                                                                  |
| 405 |    886.156473 |    736.930655 | Mathew Wedel                                                                                                                                                   |
| 406 |      5.284187 |    175.127730 | Gareth Monger                                                                                                                                                  |
| 407 |    118.526197 |    448.055505 | Margot Michaud                                                                                                                                                 |
| 408 |    298.289028 |    148.592193 | Jagged Fang Designs                                                                                                                                            |
| 409 |    467.030218 |    257.402325 | Markus A. Grohme                                                                                                                                               |
| 410 |    880.700930 |    361.293861 | Margot Michaud                                                                                                                                                 |
| 411 |     56.456435 |    397.035368 | T. Michael Keesey                                                                                                                                              |
| 412 |    575.198830 |      9.044667 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
| 413 |    805.046815 |    283.912797 | Ferran Sayol                                                                                                                                                   |
| 414 |    631.056830 |    582.958823 | Margot Michaud                                                                                                                                                 |
| 415 |     11.562442 |    468.471545 | Michael Scroggie                                                                                                                                               |
| 416 |    728.850279 |    728.871522 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
| 417 |   1009.649266 |     68.452272 | T. Michael Keesey                                                                                                                                              |
| 418 |    245.756543 |    109.552994 | Ferran Sayol                                                                                                                                                   |
| 419 |    483.291305 |    582.017584 | Birgit Lang                                                                                                                                                    |
| 420 |    359.048835 |    622.526970 | Sebastian Stabinger                                                                                                                                            |
| 421 |    490.289054 |    481.559755 | NA                                                                                                                                                             |
| 422 |    813.418362 |    778.012526 | Jack Mayer Wood                                                                                                                                                |
| 423 |    374.780226 |    741.364283 | Chris huh                                                                                                                                                      |
| 424 |    731.773110 |    547.411282 | NA                                                                                                                                                             |
| 425 |    492.911325 |    280.119585 | Ferran Sayol                                                                                                                                                   |
| 426 |     56.308272 |    582.422339 | NA                                                                                                                                                             |
| 427 |    564.470632 |    291.843529 | Jagged Fang Designs                                                                                                                                            |
| 428 |    370.953945 |    573.367787 | Oren Peles / vectorized by Yan Wong                                                                                                                            |
| 429 |    407.671380 |    282.459260 | Jaime Headden                                                                                                                                                  |
| 430 |    579.044809 |    142.741624 | Andy Wilson                                                                                                                                                    |
| 431 |    733.938582 |    453.290715 | Collin Gross                                                                                                                                                   |
| 432 |    374.420635 |    375.852114 | Andy Wilson                                                                                                                                                    |
| 433 |   1007.357505 |    490.513756 | Matt Crook                                                                                                                                                     |
| 434 |    318.559021 |    418.749431 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 435 |    542.791696 |    307.394095 | Steven Traver                                                                                                                                                  |
| 436 |    156.937685 |    392.768285 | Rebecca Groom                                                                                                                                                  |
| 437 |    107.278346 |    188.704637 | Zimices                                                                                                                                                        |
| 438 |    364.997109 |    103.723964 | Sarah Werning                                                                                                                                                  |
| 439 |   1006.815970 |    694.231923 | Michelle Site                                                                                                                                                  |
| 440 |    836.082562 |    141.587754 | Yan Wong                                                                                                                                                       |
| 441 |    976.422509 |    135.356147 | Zimices                                                                                                                                                        |
| 442 |    522.144252 |    220.430540 | Chris huh                                                                                                                                                      |
| 443 |    783.427321 |    201.538662 | Matt Crook                                                                                                                                                     |
| 444 |    548.808285 |    377.082777 | Mattia Menchetti / Yan Wong                                                                                                                                    |
| 445 |    305.194331 |    783.255720 | Gabriela Palomo-Munoz                                                                                                                                          |
| 446 |    272.638050 |    587.343352 | Maija Karala                                                                                                                                                   |
| 447 |    378.802172 |    466.557733 | Zimices                                                                                                                                                        |
| 448 |    497.820099 |    456.841015 | NA                                                                                                                                                             |
| 449 |    348.865884 |    612.377656 | Joanna Wolfe                                                                                                                                                   |
| 450 |    323.495227 |    547.136717 | Manabu Bessho-Uehara                                                                                                                                           |
| 451 |    998.104619 |    203.680973 | Maija Karala                                                                                                                                                   |
| 452 |     89.618997 |    217.223327 | Zimices                                                                                                                                                        |
| 453 |    347.807428 |    698.846556 | Alex Slavenko                                                                                                                                                  |
| 454 |    460.003509 |    221.201263 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 455 |    583.688451 |    299.619072 | M Kolmann                                                                                                                                                      |
| 456 |    576.375415 |    782.378592 | NA                                                                                                                                                             |
| 457 |    509.499295 |    705.098733 | Scott Hartman                                                                                                                                                  |
| 458 |    678.276996 |    745.279413 | Chris huh                                                                                                                                                      |
| 459 |    185.684783 |    399.668370 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                  |
| 460 |    470.559661 |    388.839668 | Jagged Fang Designs                                                                                                                                            |
| 461 |    820.692514 |     59.299291 | John Gould (vectorized by T. Michael Keesey)                                                                                                                   |
| 462 |    928.071521 |    787.593204 | Gareth Monger                                                                                                                                                  |
| 463 |    262.409766 |    644.459118 | Margot Michaud                                                                                                                                                 |
| 464 |    257.581894 |    435.940098 | Zimices                                                                                                                                                        |
| 465 |    362.935738 |    755.782185 | Zimices                                                                                                                                                        |
| 466 |    998.944155 |    413.479173 | Andrew A. Farke                                                                                                                                                |
| 467 |    207.331565 |    626.811405 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
| 468 |    112.633443 |    124.235345 | Scott Hartman                                                                                                                                                  |
| 469 |    203.648802 |    307.886711 | Frank Denota                                                                                                                                                   |
| 470 |    675.744032 |     87.641475 | Markus A. Grohme                                                                                                                                               |
| 471 |    693.088374 |    404.255625 | Alex Slavenko                                                                                                                                                  |
| 472 |    370.202839 |    405.335273 | Scott Hartman                                                                                                                                                  |
| 473 |    800.644021 |     23.034070 | Steven Coombs                                                                                                                                                  |
| 474 |    539.733165 |     86.371871 | Gabriela Palomo-Munoz                                                                                                                                          |
| 475 |    481.626821 |    443.136776 | NA                                                                                                                                                             |
| 476 |    102.355592 |     91.226979 | Scott Hartman                                                                                                                                                  |
| 477 |    666.835514 |    726.668956 | Chris huh                                                                                                                                                      |
| 478 |    780.927771 |    151.996012 | Chris Hay                                                                                                                                                      |
| 479 |    316.199565 |    356.658743 | Scott Hartman                                                                                                                                                  |
| 480 |    534.933209 |    507.538051 | Markus A. Grohme                                                                                                                                               |
| 481 |    930.485454 |    712.527020 | Sergio A. Muñoz-Gómez                                                                                                                                          |
| 482 |    993.587934 |    609.287042 | Isaure Scavezzoni                                                                                                                                              |
| 483 |     37.566215 |    341.006487 | Tasman Dixon                                                                                                                                                   |
| 484 |     87.961595 |    556.932420 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 485 |    545.779884 |      5.971234 | Matt Martyniuk                                                                                                                                                 |
| 486 |     14.698464 |    194.727109 | T. Michael Keesey                                                                                                                                              |
| 487 |   1007.352577 |    446.981984 | Markus A. Grohme                                                                                                                                               |
| 488 |     88.840506 |    349.422201 | Margot Michaud                                                                                                                                                 |
| 489 |    839.197985 |    260.153926 | Scott Hartman                                                                                                                                                  |
| 490 |    290.086602 |    184.435241 | Jagged Fang Designs                                                                                                                                            |
| 491 |    698.364842 |    235.857241 | Siobhon Egan                                                                                                                                                   |
| 492 |    744.857515 |    678.879126 | New York Zoological Society                                                                                                                                    |
| 493 |    342.548547 |    307.456934 | Manabu Bessho-Uehara                                                                                                                                           |
| 494 |    639.668962 |    659.057200 | CNZdenek                                                                                                                                                       |
| 495 |    977.450243 |    112.723679 | Markus A. Grohme                                                                                                                                               |
| 496 |    469.577996 |    595.837525 | Yan Wong from illustration by Jules Richard (1907)                                                                                                             |
| 497 |    310.097706 |    683.716937 | Zimices                                                                                                                                                        |
| 498 |    622.989303 |    669.565667 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                         |
| 499 |     42.429186 |    289.720237 | NA                                                                                                                                                             |
| 500 |    532.680164 |    617.005118 | Jagged Fang Designs                                                                                                                                            |
| 501 |    959.932849 |     15.772287 | NA                                                                                                                                                             |
| 502 |   1001.738803 |    264.226483 | Matt Crook                                                                                                                                                     |
| 503 |    510.607435 |    785.086642 | Margot Michaud                                                                                                                                                 |
| 504 |    870.163214 |    197.468672 | Steven Coombs                                                                                                                                                  |
| 505 |    886.810721 |    614.204070 | Abraão Leite                                                                                                                                                   |
| 506 |    679.359927 |    787.509577 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                  |
| 507 |     73.448367 |    371.185691 | SauropodomorphMonarch                                                                                                                                          |
| 508 |    298.679794 |    140.596033 | Chris huh                                                                                                                                                      |

    #> Your tweet has been posted!
