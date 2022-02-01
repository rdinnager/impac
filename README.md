
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
#> Warning in register(): Can't find generic `scale_type` in package ggplot2 to
#> register S3 method.
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

Emily Willoughby, Noah Schlottman, photo from Casey Dunn, Gabriela
Palomo-Munoz, Jagged Fang Designs, Steven Haddock • Jellywatch.org,
Zimices, Gareth Monger, Dean Schnabel, Ferran Sayol, Becky Barnes, Kai
R. Caspar, Margot Michaud, Samanta Orellana, Conty, Christoph Schomburg,
Jose Carlos Arenas-Monroy, George Edward Lodge (vectorized by T. Michael
Keesey), Scott Hartman, Sharon Wegner-Larsen, Markus A. Grohme, Tasman
Dixon, Steven Coombs, Steven Traver, Joanna Wolfe, C. Camilo
Julián-Caballero, Lukasiniho, Ricardo N. Martinez & Oscar A. Alcober,
(after McCulloch 1908), Roberto Díaz Sibaja, Birgit Lang, Harold N
Eyster, Geoff Shaw, Matt Crook, Smokeybjb (modified by Mike Keesey),
Dmitry Bogdanov, Mali’o Kodis, photograph from Jersabek et al, 2003,
Obsidian Soul (vectorized by T. Michael Keesey), Maija Karala, NOAA
Great Lakes Environmental Research Laboratory (illustration) and Timothy
J. Bartley (silhouette), T. Michael Keesey, Julien Louys, Dmitry
Bogdanov (vectorized by T. Michael Keesey), Nobu Tamura, FunkMonk,
Michael P. Taylor, Chris huh, Ignacio Contreras, Carlos Cano-Barbacil,
Manabu Bessho-Uehara, Saguaro Pictures (source photo) and T. Michael
Keesey, Michelle Site, Liftarn, Inessa Voet, Andrew A. Farke, Alex
Slavenko, Chloé Schmidt, Walter Vladimir, Felix Vaux, SecretJellyMan -
from Mason McNair, Noah Schlottman, photo by Casey Dunn, Agnello
Picorelli, Noah Schlottman, Rafael Maia, Noah Schlottman, photo from
Moorea Biocode, Alexander Schmidt-Lebuhn, Renata F. Martins, Alexandra
van der Geer, Katie S. Collins, Scott Reid, Mo Hassan, Beth Reinke,
Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy, Sarah
Werning, Michael Scroggie, Frank Denota, Chuanixn Yu, Yan Wong, Taro
Maeda, Mathilde Cordellier, Sergio A. Muñoz-Gómez, C. W. Nash
(illustration) and Timothy J. Bartley (silhouette), Chris A. Hamilton,
Terpsichores, L. Shyamal, Rebecca Groom, S.Martini, Myriam\_Ramirez,
Matt Celeskey, Martin R. Smith, Nobu Tamura, vectorized by Zimices,
Ghedoghedo (vectorized by T. Michael Keesey), Fritz Geller-Grimm
(vectorized by T. Michael Keesey), Rene Martin, Robert Bruce Horsfall,
vectorized by Zimices, Philip Chalmers (vectorized by T. Michael
Keesey), J. J. Harrison (photo) & T. Michael Keesey, Nobu Tamura
(vectorized by T. Michael Keesey), James R. Spotila and Ray Chatterji,
Jessica Anne Miller, T. Michael Keesey (after Kukalová), Tony Ayling
(vectorized by T. Michael Keesey), Nobu Tamura (vectorized by A.
Verrière), Derek Bakken (photograph) and T. Michael Keesey
(vectorization), Pete Buchholz, Tony Ayling, Mathew Wedel, Ludwik
Gasiorowski, Tracy A. Heath, Martin R. Smith, after Skovsted et al 2015,
Robert Hering, Yusan Yang, Nobu Tamura (modified by T. Michael Keesey),
Jimmy Bernot, Ray Simpson (vectorized by T. Michael Keesey), Caleb M.
Brown, Kamil S. Jaron, Martin R. Smith, from photo by Jürgen Schoner,
www.studiospectre.com, Acrocynus (vectorized by T. Michael Keesey), Brad
McFeeters (vectorized by T. Michael Keesey), B. Duygu Özpolat, Jake
Warner, DW Bapst (Modified from photograph taken by Charles Mitchell),
T. Michael Keesey (after Walker & al.), Paul O. Lewis, Christine Axon,
Armin Reindl, Cathy, Milton Tan, Ernst Haeckel (vectorized by T. Michael
Keesey), Matt Dempsey, Christopher Watson (photo) and T. Michael Keesey
(vectorization), Ville Koistinen (vectorized by T. Michael Keesey),
Timothy Knepp (vectorized by T. Michael Keesey), Karina Garcia,
Falconaumanni and T. Michael Keesey, Zachary Quigley, Lauren Anderson,
Josefine Bohr Brask, LeonardoG (photography) and T. Michael Keesey
(vectorization), Lukas Panzarin, Ellen Edmonson (illustration) and
Timothy J. Bartley (silhouette), Cagri Cevrim, E. Lear, 1819
(vectorization by Yan Wong), Original drawing by Antonov, vectorized by
Roberto Díaz Sibaja, Darren Naish (vectorized by T. Michael Keesey),
Conty (vectorized by T. Michael Keesey), Kanchi Nanjo, Melissa
Broussard, Kevin Sánchez, Mattia Menchetti, Matus Valach, Didier
Descouens (vectorized by T. Michael Keesey), DW Bapst, modified from
Figure 1 of Belanger (2011, PALAIOS)., Moussa Direct Ltd. (photography)
and T. Michael Keesey (vectorization), CNZdenek, Mali’o Kodis,
photograph by Bruno Vellutini, Meyers Konversations-Lexikon 1897
(vectorized: Yan Wong), Louis Ranjard, Shyamal, Jaime Headden, Manabu
Sakamoto, Óscar San-Isidro (vectorized by T. Michael Keesey), David Orr,
Collin Gross, Smokeybjb, Frank Förster, James I. Kirkland, Luis Alcalá,
Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma
(vectorized by T. Michael Keesey), Dianne Bray / Museum Victoria
(vectorized by T. Michael Keesey), Matt Martyniuk, John Curtis
(vectorized by T. Michael Keesey), Diego Fontaneto, Elisabeth A.
Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia
Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey),
Matt Martyniuk (vectorized by T. Michael Keesey), Nancy Wyman (photo),
John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey,
Charles R. Knight (vectorized by T. Michael Keesey), I. Geoffroy
Saint-Hilaire (vectorized by T. Michael Keesey), Cesar Julian, C.
Abraczinskas, Gregor Bucher, Max Farnworth, Melissa Ingala, (unknown),
T. Michael Keesey (vectorization) and HuttyMcphoo (photography), Robbie
N. Cada (vectorized by T. Michael Keesey), Anthony Caravaggi, Rachel
Shoop

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    542.099989 |    503.528449 | Emily Willoughby                                                                                                                                                      |
|   2 |    606.327242 |    405.832857 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
|   3 |    922.371523 |    414.000658 | Gabriela Palomo-Munoz                                                                                                                                                 |
|   4 |     85.246295 |    680.455957 | Jagged Fang Designs                                                                                                                                                   |
|   5 |     65.579540 |    140.468902 | Steven Haddock • Jellywatch.org                                                                                                                                       |
|   6 |    792.464519 |    583.857316 | Zimices                                                                                                                                                               |
|   7 |    110.442293 |    284.986038 | Gareth Monger                                                                                                                                                         |
|   8 |    488.605207 |     81.945942 | Dean Schnabel                                                                                                                                                         |
|   9 |    155.786252 |    444.332972 | Ferran Sayol                                                                                                                                                          |
|  10 |    483.580887 |    648.816361 | NA                                                                                                                                                                    |
|  11 |    676.699247 |    561.567852 | Becky Barnes                                                                                                                                                          |
|  12 |    919.316593 |    193.229422 | Kai R. Caspar                                                                                                                                                         |
|  13 |    899.776780 |    658.222690 | Margot Michaud                                                                                                                                                        |
|  14 |     89.393117 |    583.197237 | Samanta Orellana                                                                                                                                                      |
|  15 |    192.320487 |    711.588538 | Conty                                                                                                                                                                 |
|  16 |    955.876588 |    597.141134 | Christoph Schomburg                                                                                                                                                   |
|  17 |    643.915700 |    202.308657 | Jose Carlos Arenas-Monroy                                                                                                                                             |
|  18 |    807.880603 |     19.653552 | Jagged Fang Designs                                                                                                                                                   |
|  19 |    594.144698 |    270.337440 | Margot Michaud                                                                                                                                                        |
|  20 |    676.560308 |     97.054341 | George Edward Lodge (vectorized by T. Michael Keesey)                                                                                                                 |
|  21 |    325.653656 |    313.472608 | Margot Michaud                                                                                                                                                        |
|  22 |    889.778286 |    305.962152 | Scott Hartman                                                                                                                                                         |
|  23 |    770.950269 |    401.040205 | Sharon Wegner-Larsen                                                                                                                                                  |
|  24 |    703.276006 |    315.246729 | Markus A. Grohme                                                                                                                                                      |
|  25 |    148.779739 |    370.685046 | Gareth Monger                                                                                                                                                         |
|  26 |    887.289994 |    495.668288 | Tasman Dixon                                                                                                                                                          |
|  27 |    471.324033 |    209.514689 | NA                                                                                                                                                                    |
|  28 |    713.352031 |    665.607078 | Steven Coombs                                                                                                                                                         |
|  29 |    220.939721 |    150.355712 | NA                                                                                                                                                                    |
|  30 |    463.337275 |    758.605581 | Steven Traver                                                                                                                                                         |
|  31 |    280.062841 |    538.303436 | Jagged Fang Designs                                                                                                                                                   |
|  32 |    681.992501 |    741.278997 | Joanna Wolfe                                                                                                                                                          |
|  33 |    193.921993 |    601.456308 | C. Camilo Julián-Caballero                                                                                                                                            |
|  34 |    912.180829 |    739.721041 | Christoph Schomburg                                                                                                                                                   |
|  35 |    370.044630 |    692.908885 | Steven Traver                                                                                                                                                         |
|  36 |    306.902116 |    734.798729 | Lukasiniho                                                                                                                                                            |
|  37 |    868.526405 |     35.598754 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                                |
|  38 |    293.198926 |    446.357608 | Zimices                                                                                                                                                               |
|  39 |    410.981333 |    342.795906 | Jose Carlos Arenas-Monroy                                                                                                                                             |
|  40 |    427.371900 |    532.088613 | (after McCulloch 1908)                                                                                                                                                |
|  41 |    288.964759 |    168.400125 | Roberto Díaz Sibaja                                                                                                                                                   |
|  42 |    802.967266 |    157.889363 | Birgit Lang                                                                                                                                                           |
|  43 |    758.765777 |    223.363530 | Harold N Eyster                                                                                                                                                       |
|  44 |    840.424735 |     91.472143 | Margot Michaud                                                                                                                                                        |
|  45 |    776.156967 |    474.791622 | Geoff Shaw                                                                                                                                                            |
|  46 |    444.755184 |    418.066217 | Matt Crook                                                                                                                                                            |
|  47 |    255.598977 |     45.788280 | Smokeybjb (modified by Mike Keesey)                                                                                                                                   |
|  48 |    140.129944 |    213.636576 | Zimices                                                                                                                                                               |
|  49 |    790.989044 |    743.723877 | Dmitry Bogdanov                                                                                                                                                       |
|  50 |    584.838974 |    670.912553 | NA                                                                                                                                                                    |
|  51 |    970.085516 |     76.879941 | Mali’o Kodis, photograph from Jersabek et al, 2003                                                                                                                    |
|  52 |    330.687237 |    637.287189 | Markus A. Grohme                                                                                                                                                      |
|  53 |    342.381306 |     78.703713 | Jagged Fang Designs                                                                                                                                                   |
|  54 |    462.771089 |    260.437426 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
|  55 |     41.404797 |    339.954210 | Maija Karala                                                                                                                                                          |
|  56 |    821.173217 |    337.768005 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
|  57 |    210.359464 |    313.366463 | Matt Crook                                                                                                                                                            |
|  58 |   1000.142438 |    264.854636 | T. Michael Keesey                                                                                                                                                     |
|  59 |    774.430864 |     58.229087 | Scott Hartman                                                                                                                                                         |
|  60 |    343.236095 |    239.721397 | T. Michael Keesey                                                                                                                                                     |
|  61 |    131.303816 |     62.083517 | Julien Louys                                                                                                                                                          |
|  62 |    657.944753 |    469.965335 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  63 |     88.775975 |    759.234116 | Nobu Tamura                                                                                                                                                           |
|  64 |    532.651904 |    592.209012 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
|  65 |    335.249835 |    595.789408 | FunkMonk                                                                                                                                                              |
|  66 |    805.611444 |    636.200378 | Michael P. Taylor                                                                                                                                                     |
|  67 |    532.548163 |    312.372278 | Jagged Fang Designs                                                                                                                                                   |
|  68 |    427.534597 |    180.823661 | Zimices                                                                                                                                                               |
|  69 |    692.977481 |     20.163968 | Scott Hartman                                                                                                                                                         |
|  70 |    192.564810 |    650.547732 | Chris huh                                                                                                                                                             |
|  71 |    794.895324 |    784.111375 | Chris huh                                                                                                                                                             |
|  72 |    389.865863 |    382.842406 | Ignacio Contreras                                                                                                                                                     |
|  73 |    948.905356 |    359.970821 | Carlos Cano-Barbacil                                                                                                                                                  |
|  74 |    201.695704 |    488.834616 | Manabu Bessho-Uehara                                                                                                                                                  |
|  75 |    909.940787 |    264.184193 | Scott Hartman                                                                                                                                                         |
|  76 |    676.305213 |    634.470146 | Jagged Fang Designs                                                                                                                                                   |
|  77 |    302.057120 |    361.589554 | Scott Hartman                                                                                                                                                         |
|  78 |     30.864412 |    538.432743 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                                 |
|  79 |    838.896933 |    689.259224 | NA                                                                                                                                                                    |
|  80 |    916.141013 |    535.173745 | Michelle Site                                                                                                                                                         |
|  81 |    396.387061 |    420.488759 | Liftarn                                                                                                                                                               |
|  82 |    876.848431 |    458.039518 | Chris huh                                                                                                                                                             |
|  83 |    693.000615 |    280.806168 | Scott Hartman                                                                                                                                                         |
|  84 |    904.431334 |     10.634178 | Inessa Voet                                                                                                                                                           |
|  85 |    146.316188 |    762.029488 | FunkMonk                                                                                                                                                              |
|  86 |    674.855523 |    427.855051 | Andrew A. Farke                                                                                                                                                       |
|  87 |    568.709750 |    763.809566 | Alex Slavenko                                                                                                                                                         |
|  88 |    925.102588 |    485.883220 | Chloé Schmidt                                                                                                                                                         |
|  89 |    791.484039 |    525.067265 | Becky Barnes                                                                                                                                                          |
|  90 |    845.494923 |    374.885370 | Jagged Fang Designs                                                                                                                                                   |
|  91 |    946.552610 |    691.647703 | Carlos Cano-Barbacil                                                                                                                                                  |
|  92 |    526.992494 |    160.632564 | Walter Vladimir                                                                                                                                                       |
|  93 |    129.416448 |    141.215852 | Margot Michaud                                                                                                                                                        |
|  94 |     65.897940 |    414.865959 | Felix Vaux                                                                                                                                                            |
|  95 |    213.596427 |    264.031045 | SecretJellyMan - from Mason McNair                                                                                                                                    |
|  96 |    674.127995 |    258.960598 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
|  97 |      7.448765 |    487.821417 | Agnello Picorelli                                                                                                                                                     |
|  98 |    206.729870 |     16.420130 | Chris huh                                                                                                                                                             |
|  99 |    893.622682 |     63.519934 | Noah Schlottman                                                                                                                                                       |
| 100 |     70.316859 |     55.127308 | Rafael Maia                                                                                                                                                           |
| 101 |     33.650072 |    642.371021 | Scott Hartman                                                                                                                                                         |
| 102 |    274.380957 |     15.321663 | Jagged Fang Designs                                                                                                                                                   |
| 103 |    619.535308 |     96.038636 | Gareth Monger                                                                                                                                                         |
| 104 |    227.460262 |    107.118109 | Zimices                                                                                                                                                               |
| 105 |    987.838175 |    529.797070 | Noah Schlottman, photo from Moorea Biocode                                                                                                                            |
| 106 |    593.228426 |     17.732190 | Felix Vaux                                                                                                                                                            |
| 107 |    532.490955 |    353.303475 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 108 |    139.041978 |    520.268714 | Margot Michaud                                                                                                                                                        |
| 109 |    518.498280 |    414.601238 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 110 |    970.135831 |    463.033619 | Steven Traver                                                                                                                                                         |
| 111 |    447.873590 |    684.558760 | Matt Crook                                                                                                                                                            |
| 112 |    255.462272 |    245.354807 | Renata F. Martins                                                                                                                                                     |
| 113 |    846.786119 |    212.231420 | Alexandra van der Geer                                                                                                                                                |
| 114 |     43.420198 |     32.396859 | Steven Traver                                                                                                                                                         |
| 115 |    440.866362 |    141.220481 | Chris huh                                                                                                                                                             |
| 116 |     68.829071 |    786.567009 | Katie S. Collins                                                                                                                                                      |
| 117 |    787.952188 |    285.594548 | Matt Crook                                                                                                                                                            |
| 118 |    583.134782 |    160.122468 | FunkMonk                                                                                                                                                              |
| 119 |    501.781372 |    470.780374 | Steven Traver                                                                                                                                                         |
| 120 |    608.629079 |    518.011506 | Zimices                                                                                                                                                               |
| 121 |    248.188529 |     79.971478 | Scott Reid                                                                                                                                                            |
| 122 |    852.380334 |    140.625393 | Mo Hassan                                                                                                                                                             |
| 123 |     75.930341 |     90.339727 | Beth Reinke                                                                                                                                                           |
| 124 |    524.862092 |    265.182123 | Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy                                                                                                        |
| 125 |    434.479456 |    241.748537 | Sarah Werning                                                                                                                                                         |
| 126 |    289.579690 |    126.854907 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 127 |    562.626664 |    189.765407 | Michael Scroggie                                                                                                                                                      |
| 128 |    810.465364 |    655.278892 | Frank Denota                                                                                                                                                          |
| 129 |    837.220969 |    529.625040 | Michelle Site                                                                                                                                                         |
| 130 |    119.124318 |    341.278784 | Chuanixn Yu                                                                                                                                                           |
| 131 |    973.604037 |    285.848668 | Yan Wong                                                                                                                                                              |
| 132 |    727.018444 |    344.119917 | NA                                                                                                                                                                    |
| 133 |    380.392137 |    155.646695 | Emily Willoughby                                                                                                                                                      |
| 134 |    920.461773 |    112.623675 | Margot Michaud                                                                                                                                                        |
| 135 |    880.965246 |    579.217939 | Matt Crook                                                                                                                                                            |
| 136 |    649.661315 |    596.546203 | C. Camilo Julián-Caballero                                                                                                                                            |
| 137 |    696.268491 |    160.639972 | Gareth Monger                                                                                                                                                         |
| 138 |    442.238911 |    610.889354 | NA                                                                                                                                                                    |
| 139 |     67.782785 |    309.601655 | Scott Hartman                                                                                                                                                         |
| 140 |    539.604519 |    554.204044 | Taro Maeda                                                                                                                                                            |
| 141 |     84.839265 |    443.617263 | Mathilde Cordellier                                                                                                                                                   |
| 142 |    763.731378 |    764.863643 | Scott Hartman                                                                                                                                                         |
| 143 |     23.605260 |     93.026367 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 144 |    957.859868 |    157.769477 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                         |
| 145 |    989.707123 |    162.069887 | Chris A. Hamilton                                                                                                                                                     |
| 146 |    285.709439 |    222.334854 | Terpsichores                                                                                                                                                          |
| 147 |    155.488357 |    323.369517 | Zimices                                                                                                                                                               |
| 148 |    613.357065 |     72.342536 | Margot Michaud                                                                                                                                                        |
| 149 |     23.094655 |    437.630824 | Ferran Sayol                                                                                                                                                          |
| 150 |    513.076569 |     13.085694 | Chris huh                                                                                                                                                             |
| 151 |    217.550370 |    778.892514 | Gareth Monger                                                                                                                                                         |
| 152 |     32.677546 |    182.885658 | L. Shyamal                                                                                                                                                            |
| 153 |     91.868588 |    409.566960 | Scott Hartman                                                                                                                                                         |
| 154 |     50.518131 |    208.416175 | Birgit Lang                                                                                                                                                           |
| 155 |    589.359021 |    335.988149 | Gareth Monger                                                                                                                                                         |
| 156 |    728.712779 |    121.596593 | Rebecca Groom                                                                                                                                                         |
| 157 |    838.542577 |    276.397279 | NA                                                                                                                                                                    |
| 158 |    758.215458 |     83.169098 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 159 |    272.963773 |     31.902405 | C. Camilo Julián-Caballero                                                                                                                                            |
| 160 |    734.624839 |    180.888410 | S.Martini                                                                                                                                                             |
| 161 |    971.691518 |    399.273990 | Zimices                                                                                                                                                               |
| 162 |    604.781365 |    788.175562 | S.Martini                                                                                                                                                             |
| 163 |   1001.568396 |    672.167798 | Margot Michaud                                                                                                                                                        |
| 164 |    420.786203 |     17.404523 | Myriam\_Ramirez                                                                                                                                                       |
| 165 |     44.981835 |    236.223845 | Margot Michaud                                                                                                                                                        |
| 166 |    639.016558 |    336.286189 | Matt Celeskey                                                                                                                                                         |
| 167 |    302.813951 |    493.250524 | Martin R. Smith                                                                                                                                                       |
| 168 |    649.995936 |    525.286064 | Steven Traver                                                                                                                                                         |
| 169 |    424.421467 |     52.264388 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 170 |    485.465728 |    698.099326 | Markus A. Grohme                                                                                                                                                      |
| 171 |    673.081615 |    372.785347 | Margot Michaud                                                                                                                                                        |
| 172 |    373.996876 |    457.587833 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 173 |     46.667492 |    729.887059 | Fritz Geller-Grimm (vectorized by T. Michael Keesey)                                                                                                                  |
| 174 |    199.331294 |    300.874471 | Rene Martin                                                                                                                                                           |
| 175 |    138.923732 |    578.964969 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 176 |   1008.889607 |    405.016418 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                     |
| 177 |    692.935606 |    347.423075 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                            |
| 178 |    439.089535 |    705.326643 | Scott Hartman                                                                                                                                                         |
| 179 |    334.749705 |    796.277868 | Markus A. Grohme                                                                                                                                                      |
| 180 |   1004.692057 |    186.841669 | Steven Traver                                                                                                                                                         |
| 181 |    735.797485 |    153.866217 | Carlos Cano-Barbacil                                                                                                                                                  |
| 182 |    636.214500 |    775.993819 | Jagged Fang Designs                                                                                                                                                   |
| 183 |    919.343364 |     85.594951 | Scott Hartman                                                                                                                                                         |
| 184 |    699.402248 |    691.676927 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 185 |    271.552938 |    266.328396 | Ignacio Contreras                                                                                                                                                     |
| 186 |    590.346345 |     46.355445 | Chloé Schmidt                                                                                                                                                         |
| 187 |    626.262467 |    730.829299 | Matt Crook                                                                                                                                                            |
| 188 |    556.414759 |    426.710995 | NA                                                                                                                                                                    |
| 189 |    726.685740 |    511.621532 | FunkMonk                                                                                                                                                              |
| 190 |    952.076196 |    239.320921 | Chris huh                                                                                                                                                             |
| 191 |    990.506608 |    712.004511 | Tasman Dixon                                                                                                                                                          |
| 192 |    689.760766 |    477.308433 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 193 |     18.971816 |    738.473503 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 194 |    989.717619 |    782.870331 | Jessica Anne Miller                                                                                                                                                   |
| 195 |    666.665266 |    784.495856 | Chris huh                                                                                                                                                             |
| 196 |    388.736756 |     30.624565 | NA                                                                                                                                                                    |
| 197 |     90.228923 |    527.609889 | Emily Willoughby                                                                                                                                                      |
| 198 |    781.656072 |    444.083555 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 199 |    840.026163 |    451.110895 | Margot Michaud                                                                                                                                                        |
| 200 |    598.182130 |    484.544435 | T. Michael Keesey (after Kukalová)                                                                                                                                    |
| 201 |    539.778734 |    734.230994 | Ignacio Contreras                                                                                                                                                     |
| 202 |    535.871132 |    749.367888 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 203 |    551.577644 |      7.804246 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                               |
| 204 |    914.420886 |    314.690722 | Zimices                                                                                                                                                               |
| 205 |    816.185979 |    255.738469 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
| 206 |    635.566548 |    754.652736 | Pete Buchholz                                                                                                                                                         |
| 207 |    145.417152 |    547.443018 | Chris huh                                                                                                                                                             |
| 208 |    692.122427 |     75.583944 | Tasman Dixon                                                                                                                                                          |
| 209 |    594.717966 |    600.083381 | Tony Ayling                                                                                                                                                           |
| 210 |    712.779292 |    753.708966 | Matt Crook                                                                                                                                                            |
| 211 |    623.546950 |    142.159490 | Ferran Sayol                                                                                                                                                          |
| 212 |    384.584979 |    778.232771 | T. Michael Keesey                                                                                                                                                     |
| 213 |    834.259825 |    231.004854 | Steven Traver                                                                                                                                                         |
| 214 |    673.680782 |    392.202901 | Mathew Wedel                                                                                                                                                          |
| 215 |    393.978729 |    726.327858 | Ludwik Gasiorowski                                                                                                                                                    |
| 216 |    363.987153 |    209.434097 | Tracy A. Heath                                                                                                                                                        |
| 217 |    246.159036 |    589.006395 | Beth Reinke                                                                                                                                                           |
| 218 |    687.115188 |     47.564215 | Margot Michaud                                                                                                                                                        |
| 219 |     22.951979 |    140.530601 | NA                                                                                                                                                                    |
| 220 |    342.248943 |    149.090318 | Jagged Fang Designs                                                                                                                                                   |
| 221 |    354.561367 |    172.870319 | L. Shyamal                                                                                                                                                            |
| 222 |    404.919883 |    314.220807 | Ferran Sayol                                                                                                                                                          |
| 223 |     49.363346 |    447.179986 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
| 224 |    270.494937 |    504.513892 | Jagged Fang Designs                                                                                                                                                   |
| 225 |    741.550091 |    432.642657 | Robert Hering                                                                                                                                                         |
| 226 |    368.630459 |    480.170656 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 227 |    995.427495 |    139.167746 | Scott Hartman                                                                                                                                                         |
| 228 |    345.513099 |    503.437404 | Gareth Monger                                                                                                                                                         |
| 229 |    994.682038 |    407.392229 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 230 |    209.122945 |    586.771906 | Yusan Yang                                                                                                                                                            |
| 231 |   1007.850061 |    121.398206 | Beth Reinke                                                                                                                                                           |
| 232 |    735.116215 |    373.392049 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 233 |    288.799776 |    785.141524 | Matt Crook                                                                                                                                                            |
| 234 |     47.534245 |    616.189731 | Beth Reinke                                                                                                                                                           |
| 235 |    982.595484 |    740.540815 | Michael Scroggie                                                                                                                                                      |
| 236 |    184.425689 |    163.629522 | Jimmy Bernot                                                                                                                                                          |
| 237 |    576.266132 |    740.505800 | C. Camilo Julián-Caballero                                                                                                                                            |
| 238 |   1004.159863 |     93.266149 | Emily Willoughby                                                                                                                                                      |
| 239 |    603.308313 |    549.933319 | Matt Crook                                                                                                                                                            |
| 240 |    565.067019 |    785.029697 | Michelle Site                                                                                                                                                         |
| 241 |    879.009145 |    556.951380 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
| 242 |    443.422441 |    125.818740 | Katie S. Collins                                                                                                                                                      |
| 243 |    357.778595 |    401.280452 | Scott Hartman                                                                                                                                                         |
| 244 |    161.537868 |    126.413432 | Scott Hartman                                                                                                                                                         |
| 245 |    116.309931 |    714.990691 | NA                                                                                                                                                                    |
| 246 |    275.842556 |    611.828436 | NA                                                                                                                                                                    |
| 247 |    207.530836 |     87.163284 | Felix Vaux                                                                                                                                                            |
| 248 |    414.257295 |    658.793984 | NA                                                                                                                                                                    |
| 249 |    933.511980 |    151.773851 | Chris huh                                                                                                                                                             |
| 250 |    349.007374 |    355.660157 | Caleb M. Brown                                                                                                                                                        |
| 251 |    776.425519 |    712.163347 | Gareth Monger                                                                                                                                                         |
| 252 |    448.277685 |    319.196925 | Chris huh                                                                                                                                                             |
| 253 |    502.525637 |    171.550373 | L. Shyamal                                                                                                                                                            |
| 254 |    287.238689 |    571.232152 | Steven Traver                                                                                                                                                         |
| 255 |    184.883729 |    557.127557 | Kamil S. Jaron                                                                                                                                                        |
| 256 |    239.208987 |    355.238447 | Walter Vladimir                                                                                                                                                       |
| 257 |     33.866827 |    472.836203 | Gareth Monger                                                                                                                                                         |
| 258 |    359.158328 |    562.617347 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 259 |   1003.097812 |     15.802585 | NA                                                                                                                                                                    |
| 260 |    513.733291 |    289.973593 | Martin R. Smith, from photo by Jürgen Schoner                                                                                                                         |
| 261 |    403.914489 |    623.394041 | www.studiospectre.com                                                                                                                                                 |
| 262 |    284.741721 |     66.362426 | Matt Crook                                                                                                                                                            |
| 263 |    564.888871 |    470.950105 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                           |
| 264 |    547.873965 |    210.489958 | Chris huh                                                                                                                                                             |
| 265 |    641.445927 |     30.005563 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 266 |    240.013113 |    206.444756 | Matt Crook                                                                                                                                                            |
| 267 |    958.132087 |    133.253603 | NA                                                                                                                                                                    |
| 268 |    728.868631 |    603.792714 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 269 |     29.211242 |    273.348456 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                         |
| 270 |    472.872069 |    443.288196 | Felix Vaux                                                                                                                                                            |
| 271 |    493.772031 |    553.655537 | Joanna Wolfe                                                                                                                                                          |
| 272 |    165.255191 |    248.165413 | Zimices                                                                                                                                                               |
| 273 |    390.116124 |    197.246487 | B. Duygu Özpolat                                                                                                                                                      |
| 274 |     80.844677 |    722.011977 | Jagged Fang Designs                                                                                                                                                   |
| 275 |    131.480836 |     13.119510 | Steven Traver                                                                                                                                                         |
| 276 |    968.462583 |    669.888989 | Gareth Monger                                                                                                                                                         |
| 277 |    570.352457 |    600.261734 | Yan Wong                                                                                                                                                              |
| 278 |    598.704702 |    141.475427 | Jake Warner                                                                                                                                                           |
| 279 |     16.614152 |    380.047139 | T. Michael Keesey                                                                                                                                                     |
| 280 |     74.063575 |    736.268428 | Steven Traver                                                                                                                                                         |
| 281 |    621.077282 |    764.270867 | C. Camilo Julián-Caballero                                                                                                                                            |
| 282 |    758.060083 |    555.810897 | Zimices                                                                                                                                                               |
| 283 |    400.839820 |    290.877756 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                         |
| 284 |     10.559627 |    299.332696 | T. Michael Keesey (after Walker & al.)                                                                                                                                |
| 285 |     17.398116 |    341.161607 | Zimices                                                                                                                                                               |
| 286 |    901.147374 |    576.108603 | Gareth Monger                                                                                                                                                         |
| 287 |    605.160482 |    747.738014 | Roberto Díaz Sibaja                                                                                                                                                   |
| 288 |    133.238998 |    180.806635 | Roberto Díaz Sibaja                                                                                                                                                   |
| 289 |    491.729455 |    719.052103 | Zimices                                                                                                                                                               |
| 290 |    255.579598 |    224.519082 | Gareth Monger                                                                                                                                                         |
| 291 |    487.313693 |    340.497491 | Paul O. Lewis                                                                                                                                                         |
| 292 |    604.059526 |    220.981522 | Christine Axon                                                                                                                                                        |
| 293 |    567.571564 |    223.244095 | Armin Reindl                                                                                                                                                          |
| 294 |     32.624030 |    418.034765 | Pete Buchholz                                                                                                                                                         |
| 295 |     67.947294 |    487.352251 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                               |
| 296 |    334.198068 |     21.100207 | NA                                                                                                                                                                    |
| 297 |    480.070411 |    787.931026 | Alex Slavenko                                                                                                                                                         |
| 298 |    666.131004 |    341.729848 | Zimices                                                                                                                                                               |
| 299 |    646.724357 |    131.365754 | Matt Crook                                                                                                                                                            |
| 300 |    543.296374 |    182.134572 | Tasman Dixon                                                                                                                                                          |
| 301 |    891.976310 |    332.126840 | Cathy                                                                                                                                                                 |
| 302 |    558.784544 |    164.847397 | Scott Hartman                                                                                                                                                         |
| 303 |    226.490509 |    141.807658 | Jagged Fang Designs                                                                                                                                                   |
| 304 |    414.586959 |    791.083613 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 305 |    124.428043 |    665.256456 | Ferran Sayol                                                                                                                                                          |
| 306 |    461.765952 |    471.021439 | Zimices                                                                                                                                                               |
| 307 |    874.112996 |    122.359003 | Manabu Bessho-Uehara                                                                                                                                                  |
| 308 |    394.693638 |     77.202929 | Terpsichores                                                                                                                                                          |
| 309 |    173.929193 |    783.363259 | Julien Louys                                                                                                                                                          |
| 310 |    885.890582 |    605.138256 | Birgit Lang                                                                                                                                                           |
| 311 |    447.612640 |    294.786490 | Milton Tan                                                                                                                                                            |
| 312 |    488.335743 |    580.195287 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 313 |    935.524259 |    790.766113 | Katie S. Collins                                                                                                                                                      |
| 314 |     65.350414 |    219.359022 | Matt Dempsey                                                                                                                                                          |
| 315 |    560.727552 |     26.457958 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                                      |
| 316 |    939.947280 |    138.242163 | Tracy A. Heath                                                                                                                                                        |
| 317 |    789.041237 |    317.603057 | Scott Hartman                                                                                                                                                         |
| 318 |    521.803908 |    224.411079 | Steven Traver                                                                                                                                                         |
| 319 |    220.356630 |    128.178014 | Pete Buchholz                                                                                                                                                         |
| 320 |    442.151589 |     41.322816 | Ville Koistinen (vectorized by T. Michael Keesey)                                                                                                                     |
| 321 |    813.173553 |    115.267226 | NA                                                                                                                                                                    |
| 322 |    271.446621 |    681.774412 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                       |
| 323 |     34.657767 |    116.126927 | Maija Karala                                                                                                                                                          |
| 324 |    916.370337 |     47.899628 | Michael Scroggie                                                                                                                                                      |
| 325 |    555.692136 |    403.571106 | Karina Garcia                                                                                                                                                         |
| 326 |    264.436189 |    659.341727 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 327 |    719.126527 |    484.726454 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 328 |    902.658484 |    284.099420 | Jagged Fang Designs                                                                                                                                                   |
| 329 |     18.446753 |    777.856687 | Michelle Site                                                                                                                                                         |
| 330 |    182.001133 |    230.918189 | Sarah Werning                                                                                                                                                         |
| 331 |    165.395164 |     12.792595 | Gareth Monger                                                                                                                                                         |
| 332 |    428.371731 |    154.011973 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 333 |    813.591359 |    479.773488 | Zachary Quigley                                                                                                                                                       |
| 334 |    464.860161 |    612.682168 | Michael Scroggie                                                                                                                                                      |
| 335 |    762.527691 |    687.079494 | Jagged Fang Designs                                                                                                                                                   |
| 336 |    168.006097 |    382.804629 | Margot Michaud                                                                                                                                                        |
| 337 |    994.741930 |    654.982892 | Kamil S. Jaron                                                                                                                                                        |
| 338 |     15.498800 |     54.458315 | Lauren Anderson                                                                                                                                                       |
| 339 |    831.348586 |    404.148924 | Zimices                                                                                                                                                               |
| 340 |    720.266352 |     71.900519 | Zimices                                                                                                                                                               |
| 341 |    577.580385 |    209.474855 | Josefine Bohr Brask                                                                                                                                                   |
| 342 |    855.270099 |    242.870982 | Markus A. Grohme                                                                                                                                                      |
| 343 |    171.789516 |    747.145943 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                                         |
| 344 |    349.756191 |    525.481467 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 345 |    288.024829 |    199.971200 | Margot Michaud                                                                                                                                                        |
| 346 |    123.857276 |    636.288029 | Zimices                                                                                                                                                               |
| 347 |    644.409892 |    457.129231 | Tasman Dixon                                                                                                                                                          |
| 348 |    395.313714 |    212.814920 | Margot Michaud                                                                                                                                                        |
| 349 |    830.154390 |    742.209084 | Lukas Panzarin                                                                                                                                                        |
| 350 |     77.663752 |    517.725769 | Chris huh                                                                                                                                                             |
| 351 |    253.766697 |    317.741146 | Matt Crook                                                                                                                                                            |
| 352 |    102.618023 |    784.051240 | Michelle Site                                                                                                                                                         |
| 353 |    883.220306 |    238.628566 | Margot Michaud                                                                                                                                                        |
| 354 |    838.518579 |    360.407981 | Zimices                                                                                                                                                               |
| 355 |     64.056314 |    371.341067 | Tracy A. Heath                                                                                                                                                        |
| 356 |    230.346934 |    456.161115 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
| 357 |    965.541238 |    557.114986 | S.Martini                                                                                                                                                             |
| 358 |    637.250075 |    683.577387 | Cagri Cevrim                                                                                                                                                          |
| 359 |    811.963603 |    459.039109 | Tracy A. Heath                                                                                                                                                        |
| 360 |    550.071004 |    658.146238 | Ferran Sayol                                                                                                                                                          |
| 361 |     56.868048 |    701.330097 | Markus A. Grohme                                                                                                                                                      |
| 362 |    956.528367 |    294.655313 | Zimices                                                                                                                                                               |
| 363 |     98.002385 |    720.383077 | Terpsichores                                                                                                                                                          |
| 364 |     47.355572 |    280.818876 | Margot Michaud                                                                                                                                                        |
| 365 |    716.822214 |    173.943760 | E. Lear, 1819 (vectorization by Yan Wong)                                                                                                                             |
| 366 |     11.439068 |    569.080422 | T. Michael Keesey                                                                                                                                                     |
| 367 |    664.094734 |    693.152348 | Matt Crook                                                                                                                                                            |
| 368 |     85.683387 |    475.055452 | Markus A. Grohme                                                                                                                                                      |
| 369 |    818.742246 |     69.584588 | Chris huh                                                                                                                                                             |
| 370 |    614.066292 |    505.875219 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                        |
| 371 |     46.031237 |    574.886133 | B. Duygu Özpolat                                                                                                                                                      |
| 372 |    196.756765 |    277.312801 | Zimices                                                                                                                                                               |
| 373 |    729.205628 |    289.114153 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 374 |    742.773792 |    107.830398 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 375 |    990.253556 |    322.383235 | Jagged Fang Designs                                                                                                                                                   |
| 376 |    759.013808 |    602.387311 | Kanchi Nanjo                                                                                                                                                          |
| 377 |     19.698964 |    714.682719 | Gareth Monger                                                                                                                                                         |
| 378 |    227.654056 |    502.111016 | Melissa Broussard                                                                                                                                                     |
| 379 |    316.550499 |    513.672436 | Margot Michaud                                                                                                                                                        |
| 380 |    272.752834 |    492.575735 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 381 |    958.181085 |    491.725305 | Matt Crook                                                                                                                                                            |
| 382 |    860.620300 |    757.541659 | Kevin Sánchez                                                                                                                                                         |
| 383 |    714.032912 |     37.149395 | Jagged Fang Designs                                                                                                                                                   |
| 384 |    577.182210 |    473.604135 | T. Michael Keesey                                                                                                                                                     |
| 385 |    885.613411 |    667.522483 | Andrew A. Farke                                                                                                                                                       |
| 386 |    323.218393 |    277.205119 | Margot Michaud                                                                                                                                                        |
| 387 |    624.014804 |    644.338614 | Tasman Dixon                                                                                                                                                          |
| 388 |    460.945511 |    718.029635 | Lukasiniho                                                                                                                                                            |
| 389 |    789.105334 |    683.589870 | Michelle Site                                                                                                                                                         |
| 390 |    356.659780 |    266.213949 | Harold N Eyster                                                                                                                                                       |
| 391 |    443.955459 |    147.397277 | Jagged Fang Designs                                                                                                                                                   |
| 392 |    215.167662 |    344.646060 | Mattia Menchetti                                                                                                                                                      |
| 393 |    137.491842 |    790.738932 | Matus Valach                                                                                                                                                          |
| 394 |    253.636846 |    334.181076 | Scott Hartman                                                                                                                                                         |
| 395 |    533.163174 |    694.992577 | T. Michael Keesey                                                                                                                                                     |
| 396 |     45.911704 |     54.080006 | Beth Reinke                                                                                                                                                           |
| 397 |    708.248099 |    258.532042 | Mathew Wedel                                                                                                                                                          |
| 398 |    236.110984 |    756.938172 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 399 |    412.600343 |    229.634456 | DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).                                                                                                         |
| 400 |    736.064686 |    613.079673 | Tasman Dixon                                                                                                                                                          |
| 401 |    608.551416 |    578.986183 | Matt Crook                                                                                                                                                            |
| 402 |     86.747926 |    129.807675 | Scott Hartman                                                                                                                                                         |
| 403 |      9.936715 |    205.931911 | Dean Schnabel                                                                                                                                                         |
| 404 |    303.675144 |    671.199795 | Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization)                                                                                                |
| 405 |    228.642195 |    568.548495 | Scott Hartman                                                                                                                                                         |
| 406 |    482.866898 |    491.244408 | Gareth Monger                                                                                                                                                         |
| 407 |     98.393945 |     84.281351 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 408 |    703.556468 |    401.178608 | CNZdenek                                                                                                                                                              |
| 409 |    758.730432 |    285.707876 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                           |
| 410 |    202.042026 |    605.950793 | Tasman Dixon                                                                                                                                                          |
| 411 |    345.046978 |    785.427885 | Ignacio Contreras                                                                                                                                                     |
| 412 |    777.462579 |    439.494831 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 413 |    425.161442 |    352.596085 | Chris huh                                                                                                                                                             |
| 414 |    901.455458 |     22.915329 | Armin Reindl                                                                                                                                                          |
| 415 |    290.731408 |     97.448079 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                              |
| 416 |    482.593327 |    672.085027 | Kai R. Caspar                                                                                                                                                         |
| 417 |    608.100683 |    317.796512 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 418 |    752.394661 |    636.502999 | Maija Karala                                                                                                                                                          |
| 419 |    930.607651 |    277.391529 | Steven Traver                                                                                                                                                         |
| 420 |    538.268302 |    524.723565 | Maija Karala                                                                                                                                                          |
| 421 |    813.361916 |    305.167923 | Louis Ranjard                                                                                                                                                         |
| 422 |    433.457731 |    308.428582 | Sarah Werning                                                                                                                                                         |
| 423 |    719.483638 |    782.560579 | Manabu Bessho-Uehara                                                                                                                                                  |
| 424 |    334.629292 |    655.318242 | Shyamal                                                                                                                                                               |
| 425 |    409.835129 |    603.055322 | Michelle Site                                                                                                                                                         |
| 426 |    321.292343 |    552.330116 | NA                                                                                                                                                                    |
| 427 |    253.363909 |    413.800175 | Christoph Schomburg                                                                                                                                                   |
| 428 |    696.613332 |    500.418443 | Jaime Headden                                                                                                                                                         |
| 429 |    827.063714 |    614.531571 | Jagged Fang Designs                                                                                                                                                   |
| 430 |    495.727584 |    279.238159 | Manabu Sakamoto                                                                                                                                                       |
| 431 |    199.370668 |    777.928291 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                            |
| 432 |    725.818147 |    688.264134 | Tasman Dixon                                                                                                                                                          |
| 433 |    863.016027 |    617.429804 | Óscar San-Isidro (vectorized by T. Michael Keesey)                                                                                                                    |
| 434 |    687.472449 |    614.359824 | Pete Buchholz                                                                                                                                                         |
| 435 |   1012.490100 |     46.001643 | David Orr                                                                                                                                                             |
| 436 |    129.425186 |    565.099317 | Margot Michaud                                                                                                                                                        |
| 437 |    300.062230 |    256.132949 | Collin Gross                                                                                                                                                          |
| 438 |   1007.245044 |    775.619216 | Smokeybjb                                                                                                                                                             |
| 439 |    261.483041 |    579.111018 | Jagged Fang Designs                                                                                                                                                   |
| 440 |     48.423930 |    637.394259 | Frank Förster                                                                                                                                                         |
| 441 |    953.636637 |    774.225335 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 442 |    580.789807 |    232.480353 | Jagged Fang Designs                                                                                                                                                   |
| 443 |    868.841247 |    784.260316 | Ferran Sayol                                                                                                                                                          |
| 444 |    636.870973 |    113.552907 | Jagged Fang Designs                                                                                                                                                   |
| 445 |     70.677065 |    327.085774 | Margot Michaud                                                                                                                                                        |
| 446 |    907.790430 |    551.546513 | Chris huh                                                                                                                                                             |
| 447 |    583.916542 |    125.723057 | Markus A. Grohme                                                                                                                                                      |
| 448 |    215.703248 |    229.805388 | Chuanixn Yu                                                                                                                                                           |
| 449 |    549.392675 |    229.708787 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 450 |    352.488569 |     18.592797 | Ferran Sayol                                                                                                                                                          |
| 451 |    653.849474 |    446.613959 | Steven Coombs                                                                                                                                                         |
| 452 |    756.635684 |    727.110471 | Scott Hartman                                                                                                                                                         |
| 453 |    328.258039 |    267.618168 | Gareth Monger                                                                                                                                                         |
| 454 |    288.538738 |     19.563048 | Tasman Dixon                                                                                                                                                          |
| 455 |   1001.148309 |    487.906154 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                       |
| 456 |    551.411525 |    792.018913 | Steven Traver                                                                                                                                                         |
| 457 |    103.768279 |    659.020946 | Zimices                                                                                                                                                               |
| 458 |    807.854969 |    665.478370 | Matt Martyniuk                                                                                                                                                        |
| 459 |    166.863641 |    584.002400 | Markus A. Grohme                                                                                                                                                      |
| 460 |    796.052342 |     66.920314 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                         |
| 461 |    856.035330 |    418.608915 | www.studiospectre.com                                                                                                                                                 |
| 462 |    986.760585 |    544.663964 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 463 |    825.237486 |     16.877129 | Markus A. Grohme                                                                                                                                                      |
| 464 |    808.408088 |    188.255342 | Matt Martyniuk                                                                                                                                                        |
| 465 |    228.322710 |    321.886247 | Jaime Headden                                                                                                                                                         |
| 466 |    954.122988 |    643.220075 | Markus A. Grohme                                                                                                                                                      |
| 467 |    183.424438 |    516.566768 | Steven Traver                                                                                                                                                         |
| 468 |    712.690948 |    728.683049 | Ferran Sayol                                                                                                                                                          |
| 469 |    913.814240 |    442.922867 | Birgit Lang                                                                                                                                                           |
| 470 |    108.425692 |    437.720667 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 471 |    922.314433 |    468.171048 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 472 |     17.249888 |    681.882559 | Scott Hartman                                                                                                                                                         |
| 473 |    561.029264 |    451.042537 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 474 |    690.606148 |    791.305053 | Zimices                                                                                                                                                               |
| 475 |    616.167463 |    767.716770 | Ignacio Contreras                                                                                                                                                     |
| 476 |    560.707715 |    140.208856 | Zimices                                                                                                                                                               |
| 477 |    208.896726 |     30.389238 | Mathew Wedel                                                                                                                                                          |
| 478 |     19.478093 |    165.954708 | Carlos Cano-Barbacil                                                                                                                                                  |
| 479 |    226.681963 |    468.948240 | Scott Hartman                                                                                                                                                         |
| 480 |    261.030806 |    447.879384 | Gareth Monger                                                                                                                                                         |
| 481 |    277.366708 |    688.743908 | Smokeybjb                                                                                                                                                             |
| 482 |    191.861468 |    312.374283 | T. Michael Keesey                                                                                                                                                     |
| 483 |    537.158263 |     17.972244 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 484 |    664.552777 |    602.500961 | Ignacio Contreras                                                                                                                                                     |
| 485 |    857.704019 |    430.145724 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                                   |
| 486 |    953.460532 |    307.707567 | NA                                                                                                                                                                    |
| 487 |    739.762891 |    279.915135 | Scott Hartman                                                                                                                                                         |
| 488 |    722.605111 |    639.901945 | Collin Gross                                                                                                                                                          |
| 489 |    627.864236 |    601.753614 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                           |
| 490 |    138.404811 |    492.483229 | Tasman Dixon                                                                                                                                                          |
| 491 |    245.708291 |    792.956476 | Emily Willoughby                                                                                                                                                      |
| 492 |    766.096161 |    358.022282 | Melissa Broussard                                                                                                                                                     |
| 493 |     51.436558 |     77.669098 | Gareth Monger                                                                                                                                                         |
| 494 |    788.438161 |    549.725748 | Chris huh                                                                                                                                                             |
| 495 |   1005.447646 |    757.007999 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 496 |    768.227712 |    177.437105 | Sarah Werning                                                                                                                                                         |
| 497 |    545.804682 |    722.983044 | Matus Valach                                                                                                                                                          |
| 498 |    616.101319 |    530.225613 | Gareth Monger                                                                                                                                                         |
| 499 |    927.814988 |     19.846784 | Ferran Sayol                                                                                                                                                          |
| 500 |    159.819949 |    170.146769 | Andrew A. Farke                                                                                                                                                       |
| 501 |    462.727746 |    240.123037 | Matt Crook                                                                                                                                                            |
| 502 |    924.385908 |    562.737507 | Cesar Julian                                                                                                                                                          |
| 503 |    823.715580 |    207.672501 | Rebecca Groom                                                                                                                                                         |
| 504 |    699.624610 |    409.994955 | C. Abraczinskas                                                                                                                                                       |
| 505 |    432.806181 |    404.511603 | Gregor Bucher, Max Farnworth                                                                                                                                          |
| 506 |    361.543479 |    546.865122 | Scott Hartman                                                                                                                                                         |
| 507 |    380.236534 |    657.015974 | Gareth Monger                                                                                                                                                         |
| 508 |    287.359623 |    280.050531 | Markus A. Grohme                                                                                                                                                      |
| 509 |    638.201982 |    609.592543 | NA                                                                                                                                                                    |
| 510 |    387.618268 |    119.069010 | Kai R. Caspar                                                                                                                                                         |
| 511 |    382.205401 |    556.067302 | Felix Vaux                                                                                                                                                            |
| 512 |    496.846214 |    439.714127 | Noah Schlottman, photo from Moorea Biocode                                                                                                                            |
| 513 |    316.207703 |    205.035640 | Melissa Ingala                                                                                                                                                        |
| 514 |    710.545220 |    445.864798 | Matt Crook                                                                                                                                                            |
| 515 |    673.998938 |     35.755350 | Christoph Schomburg                                                                                                                                                   |
| 516 |    533.414060 |    325.109836 | (unknown)                                                                                                                                                             |
| 517 |    195.085123 |    290.816628 | Margot Michaud                                                                                                                                                        |
| 518 |    995.385093 |    631.819847 | Ferran Sayol                                                                                                                                                          |
| 519 |    146.512259 |    105.071614 | NA                                                                                                                                                                    |
| 520 |    172.601058 |    138.728906 | FunkMonk                                                                                                                                                              |
| 521 |     57.024821 |    465.070956 | Matt Crook                                                                                                                                                            |
| 522 |     18.862738 |    614.325613 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                       |
| 523 |   1021.168752 |    612.518415 | T. Michael Keesey (after Walker & al.)                                                                                                                                |
| 524 |    799.993218 |    104.137224 | Roberto Díaz Sibaja                                                                                                                                                   |
| 525 |     20.870504 |    751.938807 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 526 |    404.055527 |    152.341193 | Matt Crook                                                                                                                                                            |
| 527 |    317.357633 |    760.216230 | C. Camilo Julián-Caballero                                                                                                                                            |
| 528 |    378.148873 |    445.261062 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 529 |    461.588633 |     19.228246 | Anthony Caravaggi                                                                                                                                                     |
| 530 |    412.520182 |    258.767677 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 531 |    873.579908 |    544.608293 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 532 |    644.552661 |    358.489170 | Rachel Shoop                                                                                                                                                          |

    #> Your tweet has been posted!
