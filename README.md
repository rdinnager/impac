
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

Matt Crook, Markus A. Grohme, Zimices, Manabu Sakamoto, Tyler Greenfield
and Dean Schnabel, Xavier Giroux-Bougard, L. Shyamal, Joanna Wolfe,
Zsoldos Márton (vectorized by T. Michael Keesey), Elisabeth Östman,
S.Martini, Gareth Monger, Dexter R. Mardis, Gabriela Palomo-Munoz,
Smokeybjb, Steven Traver, T. Michael Keesey (after Tillyard), Andy
Wilson, Margot Michaud, Ferran Sayol, Birgit Lang, Julio Garza, Mattia
Menchetti, Chris huh, Louis Ranjard, Auckland Museum, Jaime Headden,
Mark Miller, Tasman Dixon, Anthony Caravaggi, Jagged Fang Designs,
Michael Scroggie, Daniel Jaron, Nicholas J. Czaplewski, vectorized by
Zimices, Pete Buchholz, Scott Hartman, Beth Reinke, James Neenan,
Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja,
Steven Blackwood, Josefine Bohr Brask, Zachary Quigley, Yan Wong, M
Kolmann, Diana Pomeroy, Alexandra van der Geer, Taro Maeda, Qiang Ou,
Jakovche, Carlos Cano-Barbacil, Ignacio Contreras, Matt Martyniuk, Jerry
Oldenettel (vectorized by T. Michael Keesey), Nobu Tamura, vectorized by
Zimices, Stuart Humphries, Agnello Picorelli, Sarah Werning, terngirl,
Sergio A. Muñoz-Gómez, Becky Barnes, Jake Warner, Sharon Wegner-Larsen,
T. Michael Keesey, Collin Gross, Dmitry Bogdanov (vectorized by T.
Michael Keesey), Maxime Dahirel, Jack Mayer Wood, Maija Karala, Jan A.
Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized
by T. Michael Keesey), Mali’o Kodis, photograph by Jim Vargo, E. Lear,
1819 (vectorization by Yan Wong), Noah Schlottman, Caleb M. Gordon,
Steven Coombs, SecretJellyMan - from Mason McNair, George Edward Lodge
(modified by T. Michael Keesey), T. Michael Keesey (vectorization) and
Nadiatalent (photography), Tim H. Heupink, Leon Huynen, and David M.
Lambert (vectorized by T. Michael Keesey), Alexandre Vong, Griensteidl
and T. Michael Keesey, Michelle Site, wsnaccad, Nobu Tamura (vectorized
by T. Michael Keesey), Kai R. Caspar, Erika Schumacher, Christoph
Schomburg, Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua
Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey, Roger
Witter, vectorized by Zimices, T. Michael Keesey (photo by J. M. Garg),
Ghedoghedo (vectorized by T. Michael Keesey), Jesús Gómez, vectorized by
Zimices, C. Camilo Julián-Caballero, Ghedoghedo, Andrew A. Farke, Yusan
Yang, Terpsichores, Rachel Shoop, Sherman F. Denton via rawpixel.com
(illustration) and Timothy J. Bartley (silhouette), Armin Reindl,
Michael Scroggie, from original photograph by John Bettaso, USFWS
(original photograph in public domain)., Duane Raver (vectorized by T.
Michael Keesey), Chloé Schmidt, Diego Fontaneto, Elisabeth A. Herniou,
Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and
Timothy G. Barraclough (vectorized by T. Michael Keesey), Lafage,
Roberto Diaz Sibaja, based on Domser, Tracy A. Heath, Dmitry Bogdanov,
Konsta Happonen, JCGiron, Cesar Julian, Mathieu Basille, Noah
Schlottman, photo by Casey Dunn, Christine Axon, T. Michael Keesey
(vectorization); Yves Bousquet (photography), Melissa Broussard, Caleb
M. Brown, Crystal Maier, Kristina Gagalova, Lukasiniho, Ray Simpson
(vectorized by T. Michael Keesey), Neil Kelley, Unknown (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Rebecca Groom,
Jose Carlos Arenas-Monroy, Original scheme by ‘Haplochromis’, vectorized
by Roberto Díaz Sibaja, Evan Swigart (photography) and T. Michael Keesey
(vectorization), Christopher Watson (photo) and T. Michael Keesey
(vectorization), E. J. Van Nieukerken, A. Laštůvka, and Z. Laštůvka
(vectorized by T. Michael Keesey), Dann Pigdon, Roberto Díaz Sibaja,
Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes
(www.carnivorosaustrales.org), Florian Pfaff, Alex Slavenko,
Haplochromis (vectorized by T. Michael Keesey), Ekaterina Kopeykina
(vectorized by T. Michael Keesey), Robert Gay, Felix Vaux, Farelli
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Tony Ayling, Cathy, Noah Schlottman, photo from Casey Dunn, T.
Michael Keesey (after C. De Muizon), Matt Dempsey, Nobu Tamura (modified
by T. Michael Keesey), Mykle Hoban, Tod Robbins, Ellen Edmonson and Hugh
Chrisp (vectorized by T. Michael Keesey), Paul Baker (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Melissa Ingala,
Burton Robert, USFWS, Sean McCann, Mali’o Kodis, photograph by John
Slapcinsky, Michael P. Taylor, Acrocynus (vectorized by T. Michael
Keesey), Duane Raver/USFWS, Dean Schnabel, Fernando Carezzano, CNZdenek,
T. Michael Keesey (vectorization) and HuttyMcphoo (photography), Trond
R. Oskars, B. Duygu Özpolat, Joseph Wolf, 1863 (vectorization by Dinah
Challen), T. Michael Keesey (photo by Sean Mack), Iain Reid, Pearson
Scott Foresman (vectorized by T. Michael Keesey), Emily Willoughby,
James R. Spotila and Ray Chatterji, Shyamal, Dmitry Bogdanov and
FunkMonk (vectorized by T. Michael Keesey), Mathieu Pélissié, Matt
Wilkins (photo by Patrick Kavanagh), T. K. Robinson, Alexander
Schmidt-Lebuhn, John Curtis (vectorized by T. Michael Keesey), E. R.
Waite & H. M. Hale (vectorized by T. Michael Keesey), Inessa Voet,
Gregor Bucher, Max Farnworth, Conty (vectorized by T. Michael Keesey),
Mette Aumala, Tim Bertelink (modified by T. Michael Keesey), Douglas
Brown (modified by T. Michael Keesey), Joseph J. W. Sertich, Mark A.
Loewen

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    393.192136 |    223.623571 | Matt Crook                                                                                                                                                            |
|   2 |    655.431913 |     72.803785 | Markus A. Grohme                                                                                                                                                      |
|   3 |    472.263024 |    336.920608 | Matt Crook                                                                                                                                                            |
|   4 |    672.574965 |    246.557502 | Zimices                                                                                                                                                               |
|   5 |    457.399372 |    128.346651 | Manabu Sakamoto                                                                                                                                                       |
|   6 |    317.996551 |    561.053518 | Tyler Greenfield and Dean Schnabel                                                                                                                                    |
|   7 |    742.486187 |    386.970291 | Xavier Giroux-Bougard                                                                                                                                                 |
|   8 |    848.057637 |    603.078168 | L. Shyamal                                                                                                                                                            |
|   9 |    489.022328 |    747.468369 | Joanna Wolfe                                                                                                                                                          |
|  10 |    706.584430 |    490.260826 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                                      |
|  11 |    121.906983 |    533.372777 | Elisabeth Östman                                                                                                                                                      |
|  12 |    498.200536 |    660.092803 | S.Martini                                                                                                                                                             |
|  13 |     70.633182 |     69.636296 | Gareth Monger                                                                                                                                                         |
|  14 |     61.491038 |    777.123655 | Dexter R. Mardis                                                                                                                                                      |
|  15 |    178.646555 |    443.283939 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  16 |    969.756959 |     99.485384 | Matt Crook                                                                                                                                                            |
|  17 |    930.470028 |    561.363444 | Smokeybjb                                                                                                                                                             |
|  18 |    300.624254 |    758.335910 | Gareth Monger                                                                                                                                                         |
|  19 |    241.157649 |    256.464872 | Matt Crook                                                                                                                                                            |
|  20 |    560.191381 |    575.773032 | Steven Traver                                                                                                                                                         |
|  21 |    286.203582 |    391.185546 | T. Michael Keesey (after Tillyard)                                                                                                                                    |
|  22 |    528.704730 |    484.770633 | Steven Traver                                                                                                                                                         |
|  23 |    898.713566 |    336.130915 | Andy Wilson                                                                                                                                                           |
|  24 |    236.440554 |     58.946001 | Margot Michaud                                                                                                                                                        |
|  25 |    765.654701 |    680.924621 | Ferran Sayol                                                                                                                                                          |
|  26 |    823.367302 |     74.740823 | Margot Michaud                                                                                                                                                        |
|  27 |     95.314508 |    215.827898 | Margot Michaud                                                                                                                                                        |
|  28 |    505.599881 |    200.363103 | Birgit Lang                                                                                                                                                           |
|  29 |    936.710573 |    487.943490 | Gareth Monger                                                                                                                                                         |
|  30 |    864.862958 |    440.713485 | NA                                                                                                                                                                    |
|  31 |    908.527623 |    718.700553 | Julio Garza                                                                                                                                                           |
|  32 |    359.484274 |     54.534503 | Margot Michaud                                                                                                                                                        |
|  33 |    255.172661 |    159.768772 | Mattia Menchetti                                                                                                                                                      |
|  34 |    808.400607 |    756.673072 | Chris huh                                                                                                                                                             |
|  35 |    636.888467 |     28.304318 | Chris huh                                                                                                                                                             |
|  36 |    146.209831 |    678.079332 | Louis Ranjard                                                                                                                                                         |
|  37 |    401.059626 |    651.626677 | Markus A. Grohme                                                                                                                                                      |
|  38 |    504.855642 |     58.310873 | Chris huh                                                                                                                                                             |
|  39 |    619.116800 |    663.284387 | NA                                                                                                                                                                    |
|  40 |    804.726151 |    201.206780 | Auckland Museum                                                                                                                                                       |
|  41 |    620.993942 |    120.474608 | Jaime Headden                                                                                                                                                         |
|  42 |    972.820187 |    650.271743 | Mark Miller                                                                                                                                                           |
|  43 |    793.069634 |    310.109792 | Tasman Dixon                                                                                                                                                          |
|  44 |     54.697253 |    321.938176 | Gareth Monger                                                                                                                                                         |
|  45 |    611.567306 |    401.552146 | Gareth Monger                                                                                                                                                         |
|  46 |     58.817975 |    672.522030 | Anthony Caravaggi                                                                                                                                                     |
|  47 |    731.440082 |    556.716117 | Jagged Fang Designs                                                                                                                                                   |
|  48 |    214.037867 |    559.857493 | Michael Scroggie                                                                                                                                                      |
|  49 |    909.841834 |    184.357910 | Michael Scroggie                                                                                                                                                      |
|  50 |    404.420320 |    466.862497 | Jagged Fang Designs                                                                                                                                                   |
|  51 |    425.504971 |    539.151757 | Daniel Jaron                                                                                                                                                          |
|  52 |    637.422113 |    291.719372 | Ferran Sayol                                                                                                                                                          |
|  53 |    154.895782 |    171.391724 | Zimices                                                                                                                                                               |
|  54 |    304.321790 |    694.359359 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                         |
|  55 |    639.735253 |    752.527601 | NA                                                                                                                                                                    |
|  56 |    363.975595 |    298.414943 | Pete Buchholz                                                                                                                                                         |
|  57 |    661.343712 |    169.463255 | Scott Hartman                                                                                                                                                         |
|  58 |    936.328809 |    268.555812 | Beth Reinke                                                                                                                                                           |
|  59 |    766.611713 |    621.698476 | James Neenan                                                                                                                                                          |
|  60 |    157.684570 |    316.169319 | Ferran Sayol                                                                                                                                                          |
|  61 |    929.217261 |     34.496202 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
|  62 |    910.797813 |    671.146591 | Mattia Menchetti                                                                                                                                                      |
|  63 |    695.314142 |    596.480234 | Scott Hartman                                                                                                                                                         |
|  64 |    455.568800 |    711.570352 | Steven Blackwood                                                                                                                                                      |
|  65 |    890.117458 |    129.152114 | Josefine Bohr Brask                                                                                                                                                   |
|  66 |    176.835316 |    766.448335 | Jagged Fang Designs                                                                                                                                                   |
|  67 |    791.827982 |    360.511554 | NA                                                                                                                                                                    |
|  68 |    293.876795 |    113.383405 | Zachary Quigley                                                                                                                                                       |
|  69 |    499.249755 |     21.479200 | Markus A. Grohme                                                                                                                                                      |
|  70 |    447.845882 |    616.606211 | NA                                                                                                                                                                    |
|  71 |    136.468685 |    737.537354 | Scott Hartman                                                                                                                                                         |
|  72 |    785.479360 |     23.820003 | Markus A. Grohme                                                                                                                                                      |
|  73 |    250.133838 |    520.071367 | Yan Wong                                                                                                                                                              |
|  74 |    920.644539 |    242.824217 | M Kolmann                                                                                                                                                             |
|  75 |     79.633147 |    449.004315 | Gareth Monger                                                                                                                                                         |
|  76 |    957.171605 |    393.982997 | NA                                                                                                                                                                    |
|  77 |    550.184449 |    781.378196 | Diana Pomeroy                                                                                                                                                         |
|  78 |    815.568229 |    266.660361 | Alexandra van der Geer                                                                                                                                                |
|  79 |    107.232493 |     94.496708 | Taro Maeda                                                                                                                                                            |
|  80 |    716.183482 |    117.530900 | Qiang Ou                                                                                                                                                              |
|  81 |     72.858187 |    380.722605 | Ferran Sayol                                                                                                                                                          |
|  82 |    581.186644 |    212.905289 | Jakovche                                                                                                                                                              |
|  83 |    355.681824 |    143.834574 | Scott Hartman                                                                                                                                                         |
|  84 |    712.314664 |    361.605697 | Steven Traver                                                                                                                                                         |
|  85 |    696.960549 |    730.326903 | Scott Hartman                                                                                                                                                         |
|  86 |    762.440323 |    444.037704 | Ferran Sayol                                                                                                                                                          |
|  87 |    275.410791 |    304.572777 | Carlos Cano-Barbacil                                                                                                                                                  |
|  88 |    944.201109 |     88.306265 | Margot Michaud                                                                                                                                                        |
|  89 |    378.173768 |     20.714810 | Ignacio Contreras                                                                                                                                                     |
|  90 |    986.377580 |    350.959531 | Matt Martyniuk                                                                                                                                                        |
|  91 |    532.052788 |     98.457517 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                    |
|  92 |    528.725283 |    600.280305 | NA                                                                                                                                                                    |
|  93 |    950.845210 |    767.256963 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  94 |    549.891908 |    265.237344 | Chris huh                                                                                                                                                             |
|  95 |     30.487026 |     22.568282 | Zimices                                                                                                                                                               |
|  96 |    801.147528 |    538.159675 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  97 |     37.341466 |    575.442289 | Stuart Humphries                                                                                                                                                      |
|  98 |    819.659115 |    346.692676 | Chris huh                                                                                                                                                             |
|  99 |    951.630801 |    534.454021 | Jagged Fang Designs                                                                                                                                                   |
| 100 |    372.133564 |    615.838121 | Agnello Picorelli                                                                                                                                                     |
| 101 |    558.325105 |    696.155836 | Sarah Werning                                                                                                                                                         |
| 102 |    882.283383 |    224.414455 | Andy Wilson                                                                                                                                                           |
| 103 |    520.336178 |    304.320474 | Zimices                                                                                                                                                               |
| 104 |    407.519731 |    499.804345 | Smokeybjb                                                                                                                                                             |
| 105 |    536.488520 |    121.502175 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 106 |    678.629695 |    708.217484 | Steven Traver                                                                                                                                                         |
| 107 |    527.696013 |    439.515377 | Zimices                                                                                                                                                               |
| 108 |     18.861934 |    323.818716 | Matt Crook                                                                                                                                                            |
| 109 |    368.311348 |    744.686634 | Ferran Sayol                                                                                                                                                          |
| 110 |     30.649603 |    148.417695 | terngirl                                                                                                                                                              |
| 111 |    690.641571 |    627.243078 | Margot Michaud                                                                                                                                                        |
| 112 |    801.161634 |    703.028044 | NA                                                                                                                                                                    |
| 113 |    711.825171 |    793.541982 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 114 |    215.842831 |    340.487973 | Steven Traver                                                                                                                                                         |
| 115 |    341.125255 |    342.196398 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 116 |    447.020150 |    492.019392 | Zimices                                                                                                                                                               |
| 117 |    484.166455 |    380.919410 | Chris huh                                                                                                                                                             |
| 118 |    206.294767 |    731.743444 | Beth Reinke                                                                                                                                                           |
| 119 |    738.732983 |    726.144760 | Becky Barnes                                                                                                                                                          |
| 120 |    768.070711 |    230.450641 | Jake Warner                                                                                                                                                           |
| 121 |    320.908470 |    237.024933 | Tasman Dixon                                                                                                                                                          |
| 122 |    903.346291 |    781.223398 | Jagged Fang Designs                                                                                                                                                   |
| 123 |    696.065704 |    409.249342 | Margot Michaud                                                                                                                                                        |
| 124 |    867.875704 |    794.970507 | Jaime Headden                                                                                                                                                         |
| 125 |    226.817827 |     17.846413 | Agnello Picorelli                                                                                                                                                     |
| 126 |    670.884522 |    353.983427 | Michael Scroggie                                                                                                                                                      |
| 127 |    414.613558 |    769.013764 | Scott Hartman                                                                                                                                                         |
| 128 |    907.321437 |    630.234440 | Sharon Wegner-Larsen                                                                                                                                                  |
| 129 |    146.074484 |    605.507916 | T. Michael Keesey                                                                                                                                                     |
| 130 |    636.669462 |    528.175463 | Zimices                                                                                                                                                               |
| 131 |    416.498651 |    343.739815 | Collin Gross                                                                                                                                                          |
| 132 |    210.391496 |    314.234591 | Scott Hartman                                                                                                                                                         |
| 133 |    392.533772 |    429.463471 | Steven Traver                                                                                                                                                         |
| 134 |    168.701282 |    400.141038 | Ignacio Contreras                                                                                                                                                     |
| 135 |    937.884370 |    595.224129 | Margot Michaud                                                                                                                                                        |
| 136 |     30.238974 |    190.159876 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 137 |    964.739887 |    596.640569 | Maxime Dahirel                                                                                                                                                        |
| 138 |    816.001770 |    514.305272 | Jack Mayer Wood                                                                                                                                                       |
| 139 |    244.106273 |    769.593756 | Maija Karala                                                                                                                                                          |
| 140 |    308.007602 |    784.137814 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 141 |    795.620628 |    118.340148 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 142 |    435.119290 |    262.852675 | NA                                                                                                                                                                    |
| 143 |    127.609129 |     46.348062 | Mali’o Kodis, photograph by Jim Vargo                                                                                                                                 |
| 144 |    848.219340 |    539.202049 | E. Lear, 1819 (vectorization by Yan Wong)                                                                                                                             |
| 145 |    107.507574 |    394.606968 | Andy Wilson                                                                                                                                                           |
| 146 |    948.373380 |     15.701685 | Noah Schlottman                                                                                                                                                       |
| 147 |    175.840822 |    119.378980 | Caleb M. Gordon                                                                                                                                                       |
| 148 |    156.796402 |    239.473419 | Margot Michaud                                                                                                                                                        |
| 149 |    792.594113 |    139.140926 | Steven Coombs                                                                                                                                                         |
| 150 |    966.087548 |    511.839831 | NA                                                                                                                                                                    |
| 151 |    306.149436 |    202.299555 | SecretJellyMan - from Mason McNair                                                                                                                                    |
| 152 |    877.524136 |    645.145963 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                                   |
| 153 |    586.917273 |    179.720900 | Jaime Headden                                                                                                                                                         |
| 154 |    244.575521 |    630.644968 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                       |
| 155 |    108.269875 |    484.432351 | Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael Keesey)                                                                                   |
| 156 |     18.180865 |    502.366124 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 157 |     64.706468 |    108.630733 | Joanna Wolfe                                                                                                                                                          |
| 158 |    328.327736 |     69.555250 | Ferran Sayol                                                                                                                                                          |
| 159 |    136.710811 |    628.011306 | Julio Garza                                                                                                                                                           |
| 160 |    462.416211 |    579.218713 | Zimices                                                                                                                                                               |
| 161 |    931.381837 |    341.650766 | Alexandre Vong                                                                                                                                                        |
| 162 |    982.042807 |     54.698209 | T. Michael Keesey                                                                                                                                                     |
| 163 |    564.050788 |    750.316893 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 164 |    106.926286 |    334.983505 | Matt Crook                                                                                                                                                            |
| 165 |    522.984134 |    532.477913 | Michelle Site                                                                                                                                                         |
| 166 |    492.570895 |    433.783051 | Jagged Fang Designs                                                                                                                                                   |
| 167 |    708.615650 |    665.870590 | Matt Crook                                                                                                                                                            |
| 168 |     17.811202 |    257.173280 | Matt Crook                                                                                                                                                            |
| 169 |    332.636293 |    432.490391 | Margot Michaud                                                                                                                                                        |
| 170 |    864.757688 |    166.171958 | Birgit Lang                                                                                                                                                           |
| 171 |    737.406379 |    327.013736 | Chris huh                                                                                                                                                             |
| 172 |    117.661704 |    712.371904 | Sarah Werning                                                                                                                                                         |
| 173 |    760.124274 |     69.574670 | Michelle Site                                                                                                                                                         |
| 174 |    847.016392 |    324.116597 | Margot Michaud                                                                                                                                                        |
| 175 |     19.337860 |    452.201753 | wsnaccad                                                                                                                                                              |
| 176 |    394.270722 |    581.226646 | Carlos Cano-Barbacil                                                                                                                                                  |
| 177 |    912.939506 |     70.087067 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 178 |    543.005211 |    162.388278 | Tasman Dixon                                                                                                                                                          |
| 179 |     22.356987 |    531.199129 | Steven Traver                                                                                                                                                         |
| 180 |    133.399276 |    783.666473 | T. Michael Keesey                                                                                                                                                     |
| 181 |     80.014573 |    713.396616 | Kai R. Caspar                                                                                                                                                         |
| 182 |    347.876046 |    412.947709 | Erika Schumacher                                                                                                                                                      |
| 183 |     66.805620 |    586.332112 | Christoph Schomburg                                                                                                                                                   |
| 184 |    992.772824 |    729.281065 | NA                                                                                                                                                                    |
| 185 |    865.950103 |    105.346812 | Scott Hartman                                                                                                                                                         |
| 186 |   1004.368909 |    194.766393 | Steven Traver                                                                                                                                                         |
| 187 |    312.812339 |     81.359339 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                           |
| 188 |   1003.638693 |    172.245528 | Roger Witter, vectorized by Zimices                                                                                                                                   |
| 189 |    996.029822 |    431.512417 | T. Michael Keesey (photo by J. M. Garg)                                                                                                                               |
| 190 |   1001.976006 |    326.550471 | Gareth Monger                                                                                                                                                         |
| 191 |    440.351066 |     57.676310 | NA                                                                                                                                                                    |
| 192 |    232.078957 |     26.373722 | Chris huh                                                                                                                                                             |
| 193 |    777.523636 |    345.724673 | Yan Wong                                                                                                                                                              |
| 194 |    990.923311 |    298.573271 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 195 |   1007.408041 |    241.900471 | Zimices                                                                                                                                                               |
| 196 |    566.715995 |    145.702716 | Jesús Gómez, vectorized by Zimices                                                                                                                                    |
| 197 |    352.395732 |     95.523018 | C. Camilo Julián-Caballero                                                                                                                                            |
| 198 |    690.576874 |    788.132823 | Ghedoghedo                                                                                                                                                            |
| 199 |    668.629954 |      5.425689 | Tasman Dixon                                                                                                                                                          |
| 200 |    360.659752 |    255.233563 | Matt Crook                                                                                                                                                            |
| 201 |    131.868529 |    494.448347 | Ferran Sayol                                                                                                                                                          |
| 202 |    651.495341 |    456.776947 | Jagged Fang Designs                                                                                                                                                   |
| 203 |    862.846901 |    513.376617 | Andrew A. Farke                                                                                                                                                       |
| 204 |     73.868052 |    618.902855 | Gareth Monger                                                                                                                                                         |
| 205 |    847.384245 |    370.048865 | Yusan Yang                                                                                                                                                            |
| 206 |    479.703795 |    781.209341 | Jagged Fang Designs                                                                                                                                                   |
| 207 |     87.323944 |    418.459915 | Scott Hartman                                                                                                                                                         |
| 208 |    998.588216 |     17.938832 | Terpsichores                                                                                                                                                          |
| 209 |    826.442462 |    689.825336 | Rachel Shoop                                                                                                                                                          |
| 210 |    374.699518 |    783.743586 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                                 |
| 211 |    392.303568 |      9.876598 | Gareth Monger                                                                                                                                                         |
| 212 |    792.589431 |    264.685975 | Armin Reindl                                                                                                                                                          |
| 213 |    597.361281 |    532.138843 | Michael Scroggie, from original photograph by John Bettaso, USFWS (original photograph in public domain).                                                             |
| 214 |    427.083413 |      7.249515 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                         |
| 215 |    415.221214 |    204.969303 | Ferran Sayol                                                                                                                                                          |
| 216 |    452.717105 |    390.145348 | Chloé Schmidt                                                                                                                                                         |
| 217 |    211.540942 |    488.251191 | Matt Crook                                                                                                                                                            |
| 218 |    157.991655 |    523.775184 | Scott Hartman                                                                                                                                                         |
| 219 |    743.550950 |    275.908114 | T. Michael Keesey                                                                                                                                                     |
| 220 |    337.227490 |    318.694352 | Maija Karala                                                                                                                                                          |
| 221 |    706.341154 |    763.338867 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 222 |     98.253035 |    161.615210 | Lafage                                                                                                                                                                |
| 223 |    781.908526 |    599.214431 | Margot Michaud                                                                                                                                                        |
| 224 |    919.524621 |    613.960152 | T. Michael Keesey                                                                                                                                                     |
| 225 |    294.336066 |    262.540296 | Armin Reindl                                                                                                                                                          |
| 226 |    181.193370 |     68.565822 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 227 |     38.311497 |    173.282873 | Roberto Diaz Sibaja, based on Domser                                                                                                                                  |
| 228 |    506.865218 |    359.413476 | Matt Crook                                                                                                                                                            |
| 229 |    175.484580 |    624.212307 | Anthony Caravaggi                                                                                                                                                     |
| 230 |    284.424942 |     12.178873 | Michelle Site                                                                                                                                                         |
| 231 |    479.918829 |     77.731498 | Tracy A. Heath                                                                                                                                                        |
| 232 |    370.203467 |    115.162052 | Collin Gross                                                                                                                                                          |
| 233 |    333.098321 |    262.740679 | Matt Crook                                                                                                                                                            |
| 234 |    363.759101 |     10.806357 | Tasman Dixon                                                                                                                                                          |
| 235 |    237.322729 |    698.131316 | Dmitry Bogdanov                                                                                                                                                       |
| 236 |    795.915760 |    790.980661 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 237 |    681.541014 |    674.540752 | Konsta Happonen                                                                                                                                                       |
| 238 |    952.879805 |    221.122731 | Jaime Headden                                                                                                                                                         |
| 239 |    728.273172 |    749.443031 | Margot Michaud                                                                                                                                                        |
| 240 |    700.338242 |    177.546235 | Margot Michaud                                                                                                                                                        |
| 241 |     25.466662 |    275.653967 | Pete Buchholz                                                                                                                                                         |
| 242 |    816.760498 |    403.280441 | JCGiron                                                                                                                                                               |
| 243 |    705.628746 |     31.795790 | Matt Crook                                                                                                                                                            |
| 244 |    999.173688 |    691.542847 | Zimices                                                                                                                                                               |
| 245 |    393.612287 |    383.943604 | L. Shyamal                                                                                                                                                            |
| 246 |    743.811591 |     43.865777 | Cesar Julian                                                                                                                                                          |
| 247 |     23.421023 |    375.654079 | NA                                                                                                                                                                    |
| 248 |    409.395574 |    144.773226 | Tasman Dixon                                                                                                                                                          |
| 249 |    711.516330 |    317.253960 | Mathieu Basille                                                                                                                                                       |
| 250 |    494.083056 |     93.751502 | Jagged Fang Designs                                                                                                                                                   |
| 251 |    401.879730 |    746.134674 | Matt Crook                                                                                                                                                            |
| 252 |    704.274191 |    435.393352 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 253 |     70.175077 |    141.562917 | T. Michael Keesey                                                                                                                                                     |
| 254 |    729.594081 |     49.247565 | Christine Axon                                                                                                                                                        |
| 255 |    238.656663 |    787.479166 | Ferran Sayol                                                                                                                                                          |
| 256 |     30.475959 |    216.956293 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                                        |
| 257 |     22.270775 |    485.880346 | Melissa Broussard                                                                                                                                                     |
| 258 |    762.887097 |    585.403527 | Michael Scroggie                                                                                                                                                      |
| 259 |    881.403811 |     17.420594 | Jagged Fang Designs                                                                                                                                                   |
| 260 |    703.046520 |      6.046004 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 261 |    448.500262 |    787.035682 | Caleb M. Brown                                                                                                                                                        |
| 262 |    185.580737 |    779.669484 | Crystal Maier                                                                                                                                                         |
| 263 |    822.306843 |    492.067169 | T. Michael Keesey                                                                                                                                                     |
| 264 |    512.850369 |    253.444364 | Matt Crook                                                                                                                                                            |
| 265 |    827.311867 |    379.030204 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 266 |    292.157848 |    450.089386 | Kristina Gagalova                                                                                                                                                     |
| 267 |    649.879194 |    553.872064 | Julio Garza                                                                                                                                                           |
| 268 |    939.572884 |    309.811877 | Lukasiniho                                                                                                                                                            |
| 269 |    835.718717 |    642.465690 | NA                                                                                                                                                                    |
| 270 |   1005.496799 |    520.095142 | Zimices                                                                                                                                                               |
| 271 |    832.222615 |    115.030128 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
| 272 |    782.878143 |    413.205982 | Gareth Monger                                                                                                                                                         |
| 273 |    338.903339 |    163.876583 | Anthony Caravaggi                                                                                                                                                     |
| 274 |    744.554209 |    529.886703 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 275 |   1002.488339 |    540.213596 | Zimices                                                                                                                                                               |
| 276 |    852.929886 |    681.755001 | Andy Wilson                                                                                                                                                           |
| 277 |    750.140245 |    410.116375 | NA                                                                                                                                                                    |
| 278 |      8.983827 |    403.441230 | Andy Wilson                                                                                                                                                           |
| 279 |    594.421910 |     20.053509 | Jagged Fang Designs                                                                                                                                                   |
| 280 |    156.402995 |     34.512535 | Margot Michaud                                                                                                                                                        |
| 281 |    263.980634 |    284.702912 | Neil Kelley                                                                                                                                                           |
| 282 |    994.109465 |    220.640683 | Matt Crook                                                                                                                                                            |
| 283 |    768.669336 |    523.642186 | Andy Wilson                                                                                                                                                           |
| 284 |    770.293395 |    723.092406 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 285 |    813.891501 |    162.504184 | Gareth Monger                                                                                                                                                         |
| 286 |    913.494759 |    774.441075 | Rebecca Groom                                                                                                                                                         |
| 287 |    399.867838 |    299.719237 | Ferran Sayol                                                                                                                                                          |
| 288 |    187.742825 |    261.745555 | NA                                                                                                                                                                    |
| 289 |    996.779497 |    757.239272 | Matt Crook                                                                                                                                                            |
| 290 |    541.837740 |    239.487920 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 291 |    376.911829 |    679.089881 | NA                                                                                                                                                                    |
| 292 |    983.099845 |    702.339666 | Margot Michaud                                                                                                                                                        |
| 293 |    587.907309 |    326.444278 | NA                                                                                                                                                                    |
| 294 |    452.391862 |     40.503710 | Markus A. Grohme                                                                                                                                                      |
| 295 |     97.614086 |    627.689032 | Original scheme by ‘Haplochromis’, vectorized by Roberto Díaz Sibaja                                                                                                  |
| 296 |    320.918688 |    346.651583 | Evan Swigart (photography) and T. Michael Keesey (vectorization)                                                                                                      |
| 297 |    973.622784 |    329.146777 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 298 |    399.720183 |     70.453406 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                                      |
| 299 |    191.104421 |    548.176301 | Gareth Monger                                                                                                                                                         |
| 300 |    381.010209 |    409.524232 | Matt Crook                                                                                                                                                            |
| 301 |    403.296302 |    359.480198 | Jagged Fang Designs                                                                                                                                                   |
| 302 |    138.630971 |    382.652503 | E. J. Van Nieukerken, A. Laštůvka, and Z. Laštůvka (vectorized by T. Michael Keesey)                                                                                  |
| 303 |    100.441235 |    758.324237 | Dann Pigdon                                                                                                                                                           |
| 304 |    556.738577 |    526.820364 | Scott Hartman                                                                                                                                                         |
| 305 |    291.195846 |    325.463625 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 306 |    282.292397 |    703.085086 | Steven Traver                                                                                                                                                         |
| 307 |    638.123942 |    467.009385 | Roberto Díaz Sibaja                                                                                                                                                   |
| 308 |    248.561714 |    425.040956 | Anthony Caravaggi                                                                                                                                                     |
| 309 |    219.528657 |    203.357437 | Zimices                                                                                                                                                               |
| 310 |    909.689009 |    290.967594 | Birgit Lang                                                                                                                                                           |
| 311 |    871.213687 |    315.006618 | Steven Traver                                                                                                                                                         |
| 312 |    213.599261 |    236.167692 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                          |
| 313 |    200.900229 |      5.248826 | Markus A. Grohme                                                                                                                                                      |
| 314 |    562.613968 |    715.827791 | Tasman Dixon                                                                                                                                                          |
| 315 |     31.192505 |    403.113940 | Margot Michaud                                                                                                                                                        |
| 316 |    580.417129 |     59.216365 | Florian Pfaff                                                                                                                                                         |
| 317 |    483.834594 |    316.476339 | Jagged Fang Designs                                                                                                                                                   |
| 318 |    837.380350 |    707.245155 | Christoph Schomburg                                                                                                                                                   |
| 319 |    426.588591 |    792.835281 | Alex Slavenko                                                                                                                                                         |
| 320 |    204.300537 |    570.128285 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 321 |    239.694648 |    211.578188 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 322 |    498.696902 |    541.732566 | NA                                                                                                                                                                    |
| 323 |    729.615082 |    190.438192 | Matt Crook                                                                                                                                                            |
| 324 |    250.937666 |    716.448842 | NA                                                                                                                                                                    |
| 325 |    586.045375 |    455.235934 | Markus A. Grohme                                                                                                                                                      |
| 326 |    247.835649 |    335.698900 | Beth Reinke                                                                                                                                                           |
| 327 |     15.410980 |    737.839888 | Ekaterina Kopeykina (vectorized by T. Michael Keesey)                                                                                                                 |
| 328 |    449.699611 |    470.650303 | Margot Michaud                                                                                                                                                        |
| 329 |    559.430533 |    275.862794 | T. Michael Keesey                                                                                                                                                     |
| 330 |     17.439590 |    347.960036 | Xavier Giroux-Bougard                                                                                                                                                 |
| 331 |    582.061367 |    755.167532 | Robert Gay                                                                                                                                                            |
| 332 |   1015.795600 |    766.844755 | Melissa Broussard                                                                                                                                                     |
| 333 |    622.061170 |    100.109152 | Gareth Monger                                                                                                                                                         |
| 334 |    176.381648 |    224.570309 | Chris huh                                                                                                                                                             |
| 335 |    392.263708 |    637.622331 | Felix Vaux                                                                                                                                                            |
| 336 |    735.706748 |    163.535956 | NA                                                                                                                                                                    |
| 337 |    744.347025 |     95.168595 | Farelli (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 338 |    437.801131 |    208.850366 | Dexter R. Mardis                                                                                                                                                      |
| 339 |    154.774461 |     76.251223 | Scott Hartman                                                                                                                                                         |
| 340 |    906.735726 |    259.145457 | Tony Ayling                                                                                                                                                           |
| 341 |      3.262837 |    293.593268 | T. Michael Keesey                                                                                                                                                     |
| 342 |    965.484867 |    314.489284 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 343 |     30.485978 |    428.356520 | Jaime Headden                                                                                                                                                         |
| 344 |    458.037111 |    277.171985 | Sarah Werning                                                                                                                                                         |
| 345 |    764.494763 |    319.871171 | Andy Wilson                                                                                                                                                           |
| 346 |    261.589179 |    650.668195 | Cathy                                                                                                                                                                 |
| 347 |    904.143846 |     98.211842 | Rachel Shoop                                                                                                                                                          |
| 348 |    598.373678 |    779.269081 | Steven Coombs                                                                                                                                                         |
| 349 |    998.652750 |    494.786128 | Zimices                                                                                                                                                               |
| 350 |    426.148433 |    678.527677 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 351 |    667.738676 |    680.910798 | Sarah Werning                                                                                                                                                         |
| 352 |    643.663554 |    342.494332 | Steven Traver                                                                                                                                                         |
| 353 |    943.208731 |    436.196149 | Chris huh                                                                                                                                                             |
| 354 |    557.731761 |     76.741979 | Scott Hartman                                                                                                                                                         |
| 355 |    223.669656 |     95.781170 | Felix Vaux                                                                                                                                                            |
| 356 |    267.645752 |    618.412423 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 357 |    687.481201 |    746.249269 | T. Michael Keesey (after C. De Muizon)                                                                                                                                |
| 358 |   1000.902478 |    146.190927 | Andy Wilson                                                                                                                                                           |
| 359 |    816.884334 |    652.639573 | Scott Hartman                                                                                                                                                         |
| 360 |     94.284753 |    284.646546 | Zimices                                                                                                                                                               |
| 361 |    735.194304 |    259.118384 | Joanna Wolfe                                                                                                                                                          |
| 362 |    673.734002 |    102.728101 | NA                                                                                                                                                                    |
| 363 |    534.061841 |    426.057916 | Gareth Monger                                                                                                                                                         |
| 364 |    456.575516 |    441.087022 | Zimices                                                                                                                                                               |
| 365 |    258.298988 |    457.952447 | Gareth Monger                                                                                                                                                         |
| 366 |    606.966101 |     91.438239 | Matt Dempsey                                                                                                                                                          |
| 367 |    717.152849 |    579.784251 | Steven Traver                                                                                                                                                         |
| 368 |    962.176845 |    201.985771 | Ferran Sayol                                                                                                                                                          |
| 369 |    216.606666 |    645.979541 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 370 |    968.664008 |    174.261865 | Agnello Picorelli                                                                                                                                                     |
| 371 |    909.474097 |     10.627747 | Markus A. Grohme                                                                                                                                                      |
| 372 |    866.851543 |    537.980857 | Mykle Hoban                                                                                                                                                           |
| 373 |    612.421678 |    479.702639 | Jagged Fang Designs                                                                                                                                                   |
| 374 |    516.649115 |    694.835286 | Zimices                                                                                                                                                               |
| 375 |    433.639644 |    507.903098 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 376 |    149.884322 |    635.117623 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 377 |   1004.189930 |    791.648245 | Steven Traver                                                                                                                                                         |
| 378 |    164.253558 |     98.697738 | Tasman Dixon                                                                                                                                                          |
| 379 |    148.988226 |      9.920307 | NA                                                                                                                                                                    |
| 380 |    435.219897 |    438.034785 | Yan Wong                                                                                                                                                              |
| 381 |    678.906791 |    576.924405 | Steven Traver                                                                                                                                                         |
| 382 |    526.379761 |    794.811248 | Tod Robbins                                                                                                                                                           |
| 383 |    671.209225 |    781.469207 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 384 |    169.721990 |    479.914931 | Matt Crook                                                                                                                                                            |
| 385 |    402.767943 |    523.787021 | T. Michael Keesey                                                                                                                                                     |
| 386 |    925.285864 |    108.353086 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 387 |    269.406603 |    592.599339 | Paul Baker (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 388 |     30.084891 |    758.576922 | Chris huh                                                                                                                                                             |
| 389 |    478.492660 |    297.001319 | Melissa Broussard                                                                                                                                                     |
| 390 |    609.574839 |    191.356736 | Melissa Ingala                                                                                                                                                        |
| 391 |    647.944245 |     52.442624 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 392 |    380.885950 |    525.333882 | Michael Scroggie                                                                                                                                                      |
| 393 |    587.774094 |    787.403046 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 394 |    448.037561 |    658.915153 | Birgit Lang                                                                                                                                                           |
| 395 |    423.405093 |    281.482563 | T. Michael Keesey                                                                                                                                                     |
| 396 |    114.985476 |    286.381776 | T. Michael Keesey                                                                                                                                                     |
| 397 |    229.400851 |    654.818617 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 398 |    533.746570 |    144.071361 | Andy Wilson                                                                                                                                                           |
| 399 |    744.412945 |    336.993002 | Sarah Werning                                                                                                                                                         |
| 400 |    890.309357 |    160.089364 | Margot Michaud                                                                                                                                                        |
| 401 |     14.734744 |    700.996871 | Birgit Lang                                                                                                                                                           |
| 402 |    763.893409 |    265.098227 | Burton Robert, USFWS                                                                                                                                                  |
| 403 |    808.353844 |    638.910241 | Matt Crook                                                                                                                                                            |
| 404 |    837.316825 |    496.768422 | Sean McCann                                                                                                                                                           |
| 405 |    318.144565 |     95.852314 | Zimices                                                                                                                                                               |
| 406 |    710.005989 |    714.171545 | NA                                                                                                                                                                    |
| 407 |    259.883344 |     17.188366 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 408 |    279.997130 |     33.842575 | Jaime Headden                                                                                                                                                         |
| 409 |    671.938468 |    428.654064 | Gareth Monger                                                                                                                                                         |
| 410 |    653.000889 |    689.630244 | Ferran Sayol                                                                                                                                                          |
| 411 |    519.859821 |    217.172499 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                           |
| 412 |     16.741913 |    752.974334 | Tasman Dixon                                                                                                                                                          |
| 413 |    828.594273 |    241.211929 | Jesús Gómez, vectorized by Zimices                                                                                                                                    |
| 414 |    644.714758 |    541.736388 | Michael P. Taylor                                                                                                                                                     |
| 415 |    265.403803 |    572.362034 | Stuart Humphries                                                                                                                                                      |
| 416 |    554.607629 |    325.898000 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                           |
| 417 |    429.521148 |    312.870245 | Steven Traver                                                                                                                                                         |
| 418 |    497.193689 |    327.479611 | Duane Raver/USFWS                                                                                                                                                     |
| 419 |    333.235032 |     10.177661 | NA                                                                                                                                                                    |
| 420 |   1015.276385 |    421.902730 | Dean Schnabel                                                                                                                                                         |
| 421 |    409.993572 |    414.461530 | NA                                                                                                                                                                    |
| 422 |    536.098145 |    727.893081 | Fernando Carezzano                                                                                                                                                    |
| 423 |    249.105582 |    780.141455 | Steven Coombs                                                                                                                                                         |
| 424 |    726.321356 |     81.335344 | CNZdenek                                                                                                                                                              |
| 425 |    258.976451 |    321.370065 | Gareth Monger                                                                                                                                                         |
| 426 |    828.308383 |    793.766691 | C. Camilo Julián-Caballero                                                                                                                                            |
| 427 |    486.299215 |    110.333445 | Dexter R. Mardis                                                                                                                                                      |
| 428 |    522.065243 |    524.859383 | Zimices                                                                                                                                                               |
| 429 |    490.018385 |    588.112609 | Markus A. Grohme                                                                                                                                                      |
| 430 |    529.904527 |     35.577666 | Ignacio Contreras                                                                                                                                                     |
| 431 |    954.230352 |    624.647088 | Scott Hartman                                                                                                                                                         |
| 432 |    177.140919 |    459.187129 | Zimices                                                                                                                                                               |
| 433 |    894.178741 |    787.503123 | NA                                                                                                                                                                    |
| 434 |    354.154540 |    617.427046 | NA                                                                                                                                                                    |
| 435 |    487.079494 |    446.714525 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 436 |    670.220369 |    288.908007 | C. Camilo Julián-Caballero                                                                                                                                            |
| 437 |     54.595539 |    742.816811 | T. Michael Keesey (vectorization) and HuttyMcphoo (photography)                                                                                                       |
| 438 |    432.478213 |    518.956341 | Markus A. Grohme                                                                                                                                                      |
| 439 |   1016.190784 |    219.356603 | T. Michael Keesey                                                                                                                                                     |
| 440 |      9.554836 |    213.647920 | Trond R. Oskars                                                                                                                                                       |
| 441 |    582.595083 |    159.572181 | B. Duygu Özpolat                                                                                                                                                      |
| 442 |    814.395153 |    296.328467 | Ignacio Contreras                                                                                                                                                     |
| 443 |    758.345112 |    791.390142 | Zimices                                                                                                                                                               |
| 444 |    211.721766 |    778.235854 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                                    |
| 445 |   1008.424342 |    278.902916 | T. Michael Keesey                                                                                                                                                     |
| 446 |    182.038569 |    384.324690 | Margot Michaud                                                                                                                                                        |
| 447 |    762.680052 |    135.448801 | Markus A. Grohme                                                                                                                                                      |
| 448 |    205.488939 |    109.427070 | T. Michael Keesey (photo by Sean Mack)                                                                                                                                |
| 449 |    678.838012 |    145.289105 | Steven Traver                                                                                                                                                         |
| 450 |    769.535008 |    122.452397 | Iain Reid                                                                                                                                                             |
| 451 |    473.688093 |    178.928839 | Chris huh                                                                                                                                                             |
| 452 |    966.237801 |    427.449506 | Christoph Schomburg                                                                                                                                                   |
| 453 |    745.547659 |    216.048052 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 454 |    417.386722 |     51.191226 | Margot Michaud                                                                                                                                                        |
| 455 |     23.850963 |    288.824102 | Emily Willoughby                                                                                                                                                      |
| 456 |    484.186952 |    487.286124 | Chris huh                                                                                                                                                             |
| 457 |    751.044708 |     52.774950 | Gareth Monger                                                                                                                                                         |
| 458 |     53.915365 |    574.374087 | Gareth Monger                                                                                                                                                         |
| 459 |    533.874929 |    633.472882 | Rebecca Groom                                                                                                                                                         |
| 460 |    803.980979 |    714.753553 | Iain Reid                                                                                                                                                             |
| 461 |    563.863666 |    249.619392 | NA                                                                                                                                                                    |
| 462 |    772.190210 |    733.181715 | Tasman Dixon                                                                                                                                                          |
| 463 |   1007.649211 |    253.719433 | Steven Coombs                                                                                                                                                         |
| 464 |    157.622375 |     56.666087 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 465 |    523.112030 |    340.508326 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 466 |    593.988767 |    513.452378 | Shyamal                                                                                                                                                               |
| 467 |    521.455847 |    380.811648 | Xavier Giroux-Bougard                                                                                                                                                 |
| 468 |    476.928401 |    557.165730 | Scott Hartman                                                                                                                                                         |
| 469 |    283.265889 |    614.873594 | Matt Martyniuk                                                                                                                                                        |
| 470 |    986.777274 |    583.517625 | Tracy A. Heath                                                                                                                                                        |
| 471 |    157.961410 |    504.311636 | Collin Gross                                                                                                                                                          |
| 472 |    566.296855 |    127.556466 | Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey)                                                                                                        |
| 473 |    326.879700 |    194.917645 | Mathieu Pélissié                                                                                                                                                      |
| 474 |    493.703285 |      3.710443 | Scott Hartman                                                                                                                                                         |
| 475 |    251.272508 |    121.603305 | Markus A. Grohme                                                                                                                                                      |
| 476 |    959.953333 |     61.381981 | Shyamal                                                                                                                                                               |
| 477 |     25.490511 |     48.192391 | Jagged Fang Designs                                                                                                                                                   |
| 478 |    866.640981 |    283.421169 | Zimices                                                                                                                                                               |
| 479 |    792.614439 |    632.037472 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                              |
| 480 |    344.678015 |    228.380365 | T. Michael Keesey                                                                                                                                                     |
| 481 |    907.592567 |    792.177058 | Markus A. Grohme                                                                                                                                                      |
| 482 |     98.676715 |    138.535902 | Christoph Schomburg                                                                                                                                                   |
| 483 |    508.191723 |     73.800055 | T. K. Robinson                                                                                                                                                        |
| 484 |     87.729751 |    492.225722 | Scott Hartman                                                                                                                                                         |
| 485 |    415.213992 |    162.746149 | Melissa Broussard                                                                                                                                                     |
| 486 |    141.778332 |    718.810713 | Steven Coombs                                                                                                                                                         |
| 487 |    557.372078 |     42.629149 | Jagged Fang Designs                                                                                                                                                   |
| 488 |    720.348162 |    302.405811 | Ignacio Contreras                                                                                                                                                     |
| 489 |    898.513865 |    372.925451 | Matt Crook                                                                                                                                                            |
| 490 |    424.112575 |    481.356332 | NA                                                                                                                                                                    |
| 491 |    264.076361 |    199.862603 | Jagged Fang Designs                                                                                                                                                   |
| 492 |    336.951499 |    132.807425 | Matt Martyniuk                                                                                                                                                        |
| 493 |    360.066894 |    425.810733 | Armin Reindl                                                                                                                                                          |
| 494 |    879.402295 |    705.377651 | Roberto Díaz Sibaja                                                                                                                                                   |
| 495 |    243.657875 |    294.534515 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 496 |    355.086840 |    673.697509 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                         |
| 497 |    964.913620 |    231.572224 | Chris huh                                                                                                                                                             |
| 498 |    230.249980 |    352.571933 | Scott Hartman                                                                                                                                                         |
| 499 |    623.228926 |    205.614188 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 500 |    524.352044 |    282.028200 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 501 |    964.112377 |    743.017144 | Margot Michaud                                                                                                                                                        |
| 502 |    273.610405 |     97.647271 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                            |
| 503 |    565.169083 |    781.014460 | Inessa Voet                                                                                                                                                           |
| 504 |   1012.305130 |    722.885091 | Matt Martyniuk                                                                                                                                                        |
| 505 |    476.983933 |     99.668701 | Andy Wilson                                                                                                                                                           |
| 506 |    290.089968 |     49.867964 | Jagged Fang Designs                                                                                                                                                   |
| 507 |    374.328567 |     32.508140 | Markus A. Grohme                                                                                                                                                      |
| 508 |    720.938341 |    638.626089 | Gregor Bucher, Max Farnworth                                                                                                                                          |
| 509 |    391.235979 |    690.647502 | Gareth Monger                                                                                                                                                         |
| 510 |    480.048719 |    388.689753 | Matt Dempsey                                                                                                                                                          |
| 511 |    423.223353 |    274.384789 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 512 |     41.848188 |    413.792106 | Markus A. Grohme                                                                                                                                                      |
| 513 |    213.757590 |    220.271763 | Tasman Dixon                                                                                                                                                          |
| 514 |     93.355778 |    467.852580 | Matt Crook                                                                                                                                                            |
| 515 |    546.605113 |    107.347213 | Matt Crook                                                                                                                                                            |
| 516 |    785.548772 |    433.646602 | Gareth Monger                                                                                                                                                         |
| 517 |   1017.811826 |     30.516904 | Robert Gay                                                                                                                                                            |
| 518 |    650.634403 |     64.552809 | Tasman Dixon                                                                                                                                                          |
| 519 |    846.252373 |      8.198723 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 520 |    742.425430 |    703.537212 | Emily Willoughby                                                                                                                                                      |
| 521 |    383.315676 |    566.175789 | NA                                                                                                                                                                    |
| 522 |    802.683683 |    524.259102 | Steven Traver                                                                                                                                                         |
| 523 |    500.152930 |     37.859793 | Chris huh                                                                                                                                                             |
| 524 |    426.568726 |    294.839176 | Mette Aumala                                                                                                                                                          |
| 525 |    465.394461 |    345.152971 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                         |
| 526 |    637.239244 |    606.102320 | Steven Traver                                                                                                                                                         |
| 527 |    509.916865 |    590.784034 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                           |
| 528 |   1013.929451 |    616.040893 | Gareth Monger                                                                                                                                                         |
| 529 |    179.047308 |     14.831439 | Maija Karala                                                                                                                                                          |
| 530 |    477.923200 |    239.085904 | Douglas Brown (modified by T. Michael Keesey)                                                                                                                         |
| 531 |    219.741912 |    618.305354 | Margot Michaud                                                                                                                                                        |
| 532 |    777.841268 |    554.426097 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                  |

    #> Your tweet has been posted!
