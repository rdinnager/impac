
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

Yan Wong, Andy Wilson, Steven Haddock • Jellywatch.org, M Kolmann,
Zimices, Mike Hanson, Iain Reid, Ferran Sayol, Beth Reinke, DW Bapst
(Modified from Bulman, 1964), Neil Kelley, Cathy, Sharon Wegner-Larsen,
U.S. National Park Service (vectorized by William Gearty), Gareth
Monger, Berivan Temiz, David Liao, Kamil S. Jaron, Ernst Haeckel
(vectorized by T. Michael Keesey), Markus A. Grohme, Adam Stuart Smith
(vectorized by T. Michael Keesey), Smokeybjb, T. Michael Keesey, Nobu
Tamura, vectorized by Zimices, Vanessa Guerra, Griensteidl and T.
Michael Keesey, Milton Tan, Jiekun He, Tomas Willems (vectorized by T.
Michael Keesey), Juan Carlos Jerí, Armin Reindl, Chris huh, Ray Simpson
(vectorized by T. Michael Keesey), Steven Traver, Nobu Tamura
(vectorized by T. Michael Keesey), Jagged Fang Designs, Owen Jones
(derived from a CC-BY 2.0 photograph by Paulo B. Chaves), Dmitry
Bogdanov (vectorized by T. Michael Keesey), Kai R. Caspar, Andrew A.
Farke, Haplochromis (vectorized by T. Michael Keesey), Scott Hartman,
Stuart Humphries, Mathew Wedel, Martin R. Smith, from photo by Jürgen
Schoner, Matt Crook, Diego Fontaneto, Elisabeth A. Herniou, Chiara
Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy
G. Barraclough (vectorized by T. Michael Keesey), Matt Celeskey, Emily
Willoughby, NOAA Great Lakes Environmental Research Laboratory
(illustration) and Timothy J. Bartley (silhouette), Michael Scroggie,
Inessa Voet, Margot Michaud, FunkMonk, Scott Reid, L. Shyamal, Lisa
Byrne, Daniel Jaron, Katie S. Collins, Diana Pomeroy, Tasman Dixon,
Erika Schumacher, Chris Jennings (Risiatto), Christoph Schomburg, Tim H.
Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael
Keesey), Felix Vaux, Frank Denota, Carlos Cano-Barbacil, Ludwik
Gąsiorowski, Jordan Mallon (vectorized by T. Michael Keesey),
www.studiospectre.com, Francisco Gascó (modified by Michael P. Taylor),
Gabriela Palomo-Munoz, Mathieu Pélissié, Jakovche, kreidefossilien.de,
Ingo Braasch, Harold N Eyster, Ellen Edmonson and Hugh Chrisp
(illustration) and Timothy J. Bartley (silhouette), Chase Brownstein, C.
Camilo Julián-Caballero, Ben Liebeskind, Ghedoghedo (vectorized by T.
Michael Keesey), Original drawing by Antonov, vectorized by Roberto Díaz
Sibaja, Robert Hering, Allison Pease, Noah Schlottman, photo by Casey
Dunn, Michelle Site, Sarah Werning, Birgit Szabo, Sergio A. Muñoz-Gómez,
Jerry Oldenettel (vectorized by T. Michael Keesey), Jose Carlos
Arenas-Monroy, Ignacio Contreras, Isaure Scavezzoni, David Orr, T.
Michael Keesey (photo by Bc999 \[Black crow\]), Verdilak, Birgit Lang,
Manabu Sakamoto, Meyers Konversations-Lexikon 1897 (vectorized: Yan
Wong), Saguaro Pictures (source photo) and T. Michael Keesey, Lauren
Anderson, Tauana J. Cunha, Collin Gross, Joshua Fowler, Becky Barnes,
Christine Axon, Rebecca Groom (Based on Photo by Andreas Trepte),
Christopher Watson (photo) and T. Michael Keesey (vectorization), Ville
Koistinen and T. Michael Keesey, T. Tischler, B. Duygu Özpolat, Mariana
Ruiz (vectorized by T. Michael Keesey), , CNZdenek, Matt Martyniuk
(vectorized by T. Michael Keesey), Javier Luque, Nobu Tamura, modified
by Andrew A. Farke, Lauren Sumner-Rooney, xgirouxb, Arthur S. Brum,
Andrew A. Farke, modified from original by H. Milne Edwards, H. F. O.
March (vectorized by T. Michael Keesey), Sherman Foote Denton
(illustration, 1897) and Timothy J. Bartley (silhouette), Julie
Blommaert based on photo by Sofdrakou, Joanna Wolfe, Matt Dempsey, Emily
Jane McTavish, Dean Schnabel, David Sim (photograph) and T. Michael
Keesey (vectorization), Martin R. Smith, Dmitry Bogdanov, Jessica Anne
Miller, Mattia Menchetti, Timothy Knepp of the U.S. Fish and Wildlife
Service (illustration) and Timothy J. Bartley (silhouette), Maija
Karala, Scott Hartman, modified by T. Michael Keesey, Alexander
Schmidt-Lebuhn, Johan Lindgren, Michael W. Caldwell, Takuya Konishi,
Luis M. Chiappe, terngirl, Mercedes Yrayzoz (vectorized by T. Michael
Keesey), Pete Buchholz, JJ Harrison (vectorized by T. Michael Keesey),
Robert Gay, T. Michael Keesey (after Marek Velechovský), Michael
“FunkMonk” B. H. (vectorized by T. Michael Keesey), Maxime Dahirel,
Cesar Julian, Didier Descouens (vectorized by T. Michael Keesey), Yan
Wong from illustration by Jules Richard (1907), Shyamal, Jessica Rick,
Louis Ranjard, Matt Martyniuk, Jaime Headden, Mali’o Kodis, photograph
property of National Museums of Northern Ireland, Noah Schlottman, photo
by Carol Cummings, Hans Hillewaert (vectorized by T. Michael Keesey),
Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey), Tony
Ayling (vectorized by T. Michael Keesey), Jay Matternes (vectorized by
T. Michael Keesey), Henry Lydecker, S.Martini, Kailah Thorn & Mark
Hutchinson, James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo
Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael
Keesey), Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael
Keesey), Melissa Broussard, Xvazquez (vectorized by William Gearty),
Baheerathan Murugavel, Tony Ayling, Noah Schlottman, Konsta Happonen,
from a CC-BY-NC image by sokolkov2002 on iNaturalist, Lankester Edwin
Ray (vectorized by T. Michael Keesey), Martin R. Smith, after Skovsted
et al 2015, Trond R. Oskars, Danielle Alba, Mathilde Cordellier, Tyler
McCraney

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    618.158025 |    392.778127 | Yan Wong                                                                                                                                                              |
|   2 |    425.714482 |    484.356074 | Andy Wilson                                                                                                                                                           |
|   3 |    138.908487 |    344.940595 | Steven Haddock • Jellywatch.org                                                                                                                                       |
|   4 |     46.944840 |    285.268604 | M Kolmann                                                                                                                                                             |
|   5 |    622.478515 |    770.739344 | Zimices                                                                                                                                                               |
|   6 |    444.522617 |    205.077407 | Zimices                                                                                                                                                               |
|   7 |    341.574614 |    263.681318 | Mike Hanson                                                                                                                                                           |
|   8 |    626.805800 |    130.851344 | Iain Reid                                                                                                                                                             |
|   9 |    469.913025 |    335.252320 | Ferran Sayol                                                                                                                                                          |
|  10 |    192.877982 |    503.486580 | Zimices                                                                                                                                                               |
|  11 |    360.240882 |     77.840957 | Beth Reinke                                                                                                                                                           |
|  12 |    305.638412 |    606.845053 | DW Bapst (Modified from Bulman, 1964)                                                                                                                                 |
|  13 |    532.486599 |    499.094085 | Neil Kelley                                                                                                                                                           |
|  14 |    451.023775 |    708.695885 | Zimices                                                                                                                                                               |
|  15 |    846.292130 |    205.715349 | Cathy                                                                                                                                                                 |
|  16 |    618.600020 |    642.616754 | Sharon Wegner-Larsen                                                                                                                                                  |
|  17 |    761.566847 |    189.679026 | U.S. National Park Service (vectorized by William Gearty)                                                                                                             |
|  18 |    277.557265 |    382.156261 | Zimices                                                                                                                                                               |
|  19 |    820.970932 |    591.109181 | Gareth Monger                                                                                                                                                         |
|  20 |    599.126694 |    301.553922 | Berivan Temiz                                                                                                                                                         |
|  21 |    186.093484 |    146.668159 | David Liao                                                                                                                                                            |
|  22 |    948.092499 |    133.275446 | Kamil S. Jaron                                                                                                                                                        |
|  23 |    943.877315 |    487.469196 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
|  24 |    299.406618 |    687.859478 | Zimices                                                                                                                                                               |
|  25 |     63.889782 |    103.694446 | Markus A. Grohme                                                                                                                                                      |
|  26 |    766.013808 |     98.084438 | Adam Stuart Smith (vectorized by T. Michael Keesey)                                                                                                                   |
|  27 |    274.583653 |    457.354140 | Smokeybjb                                                                                                                                                             |
|  28 |    988.551500 |    456.842674 | T. Michael Keesey                                                                                                                                                     |
|  29 |    491.056287 |     44.057437 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  30 |     68.074506 |    536.996293 | Gareth Monger                                                                                                                                                         |
|  31 |    946.429357 |    595.212235 | Vanessa Guerra                                                                                                                                                        |
|  32 |    780.521368 |    369.532334 | Griensteidl and T. Michael Keesey                                                                                                                                     |
|  33 |    115.569239 |    694.278706 | Milton Tan                                                                                                                                                            |
|  34 |    874.143175 |    324.125935 | Jiekun He                                                                                                                                                             |
|  35 |    652.457551 |     31.391168 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  36 |    708.977526 |    604.299396 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                                       |
|  37 |    742.581742 |    259.974908 | Juan Carlos Jerí                                                                                                                                                      |
|  38 |    356.504973 |    183.774678 | T. Michael Keesey                                                                                                                                                     |
|  39 |    374.684998 |    768.676179 | NA                                                                                                                                                                    |
|  40 |    425.597195 |    126.594946 | Armin Reindl                                                                                                                                                          |
|  41 |    138.977008 |     59.838404 | Chris huh                                                                                                                                                             |
|  42 |    677.867193 |    529.958514 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
|  43 |    939.287394 |    733.672732 | Zimices                                                                                                                                                               |
|  44 |     74.833487 |    749.705020 | Steven Traver                                                                                                                                                         |
|  45 |    952.816072 |    348.337340 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  46 |    188.154014 |    259.561259 | Jagged Fang Designs                                                                                                                                                   |
|  47 |    698.030134 |    455.608239 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                                   |
|  48 |    465.254521 |    559.691854 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  49 |    175.728111 |    643.215157 | Steven Traver                                                                                                                                                         |
|  50 |    278.283047 |    107.697465 | Ferran Sayol                                                                                                                                                          |
|  51 |    226.887472 |    751.786726 | Kai R. Caspar                                                                                                                                                         |
|  52 |    483.616023 |    279.954246 | Andrew A. Farke                                                                                                                                                       |
|  53 |    188.514252 |    431.662970 | Kamil S. Jaron                                                                                                                                                        |
|  54 |    600.808777 |    201.477019 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
|  55 |    637.999869 |     93.859223 | Scott Hartman                                                                                                                                                         |
|  56 |    168.789925 |    222.977696 | Stuart Humphries                                                                                                                                                      |
|  57 |    723.290321 |    312.356918 | Mathew Wedel                                                                                                                                                          |
|  58 |    252.766773 |    288.770018 | Chris huh                                                                                                                                                             |
|  59 |     69.197947 |    476.012284 | Martin R. Smith, from photo by Jürgen Schoner                                                                                                                         |
|  60 |    525.281399 |    375.825364 | Matt Crook                                                                                                                                                            |
|  61 |     27.827869 |    404.336686 | Gareth Monger                                                                                                                                                         |
|  62 |    921.508289 |    450.671418 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
|  63 |    496.361230 |    647.018480 | Scott Hartman                                                                                                                                                         |
|  64 |    784.453461 |     30.181743 | NA                                                                                                                                                                    |
|  65 |     93.602081 |    608.664347 | Matt Celeskey                                                                                                                                                         |
|  66 |    681.471287 |    730.733710 | Emily Willoughby                                                                                                                                                      |
|  67 |   1001.241379 |    218.603759 | Gareth Monger                                                                                                                                                         |
|  68 |    444.878587 |    383.929385 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  69 |    387.021085 |     30.131970 | Jagged Fang Designs                                                                                                                                                   |
|  70 |    352.935595 |    294.743450 | NA                                                                                                                                                                    |
|  71 |    284.641909 |    524.400566 | Matt Crook                                                                                                                                                            |
|  72 |     78.490231 |     31.384206 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
|  73 |    709.779472 |    684.625246 | Michael Scroggie                                                                                                                                                      |
|  74 |     68.809657 |    183.089773 | Zimices                                                                                                                                                               |
|  75 |    613.485178 |    234.229056 | Inessa Voet                                                                                                                                                           |
|  76 |    263.609938 |    193.815176 | Zimices                                                                                                                                                               |
|  77 |    527.977402 |    776.388316 | Margot Michaud                                                                                                                                                        |
|  78 |    938.732023 |    236.227960 | Markus A. Grohme                                                                                                                                                      |
|  79 |    930.372951 |    652.873439 | Zimices                                                                                                                                                               |
|  80 |    570.793349 |    590.983876 | Chris huh                                                                                                                                                             |
|  81 |    911.528917 |    553.976023 | FunkMonk                                                                                                                                                              |
|  82 |     73.515057 |    433.438407 | Scott Reid                                                                                                                                                            |
|  83 |    594.833808 |    721.909354 | L. Shyamal                                                                                                                                                            |
|  84 |    775.524401 |    746.250341 | Gareth Monger                                                                                                                                                         |
|  85 |    273.852398 |    638.362833 | Lisa Byrne                                                                                                                                                            |
|  86 |    693.169419 |    341.235726 | Scott Hartman                                                                                                                                                         |
|  87 |    658.188345 |    443.640211 | Daniel Jaron                                                                                                                                                          |
|  88 |    326.956491 |    569.709716 | Katie S. Collins                                                                                                                                                      |
|  89 |    507.023635 |    152.533907 | Diana Pomeroy                                                                                                                                                         |
|  90 |    837.565045 |     98.664478 | Steven Traver                                                                                                                                                         |
|  91 |     77.137710 |    366.431079 | Tasman Dixon                                                                                                                                                          |
|  92 |    557.176934 |    386.262801 | Erika Schumacher                                                                                                                                                      |
|  93 |     94.726250 |    330.163035 | Chris Jennings (Risiatto)                                                                                                                                             |
|  94 |     96.168970 |    644.758232 | Christoph Schomburg                                                                                                                                                   |
|  95 |    263.283014 |     28.850048 | Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael Keesey)                                                                                   |
|  96 |    963.658208 |    285.533221 | Steven Traver                                                                                                                                                         |
|  97 |    522.056256 |    726.197474 | Felix Vaux                                                                                                                                                            |
|  98 |    201.807227 |     29.506139 | Christoph Schomburg                                                                                                                                                   |
|  99 |     84.946734 |    393.368941 | Jagged Fang Designs                                                                                                                                                   |
| 100 |    320.479070 |    742.820496 | FunkMonk                                                                                                                                                              |
| 101 |    743.126228 |    760.683488 | Emily Willoughby                                                                                                                                                      |
| 102 |    992.194629 |    650.488785 | NA                                                                                                                                                                    |
| 103 |    567.195450 |    264.764471 | Frank Denota                                                                                                                                                          |
| 104 |    622.583230 |     66.776259 | Tasman Dixon                                                                                                                                                          |
| 105 |    406.197870 |    673.411790 | Markus A. Grohme                                                                                                                                                      |
| 106 |    537.535026 |     97.316948 | Carlos Cano-Barbacil                                                                                                                                                  |
| 107 |    267.887900 |    136.603870 | Ludwik Gąsiorowski                                                                                                                                                    |
| 108 |    875.615995 |    401.301612 | Andrew A. Farke                                                                                                                                                       |
| 109 |    639.814171 |    351.403040 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                       |
| 110 |    677.547925 |    165.142053 | T. Michael Keesey                                                                                                                                                     |
| 111 |    513.272823 |    175.685330 | Yan Wong                                                                                                                                                              |
| 112 |    647.147454 |    250.385997 | Ferran Sayol                                                                                                                                                          |
| 113 |    714.964914 |    781.512664 | Armin Reindl                                                                                                                                                          |
| 114 |    776.180780 |    246.297298 | Steven Traver                                                                                                                                                         |
| 115 |    156.989329 |    732.426067 | www.studiospectre.com                                                                                                                                                 |
| 116 |    962.450559 |    418.068815 | Margot Michaud                                                                                                                                                        |
| 117 |    861.848707 |     28.669245 | NA                                                                                                                                                                    |
| 118 |    237.073019 |    577.004559 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                       |
| 119 |    753.671030 |    460.739510 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 120 |     59.538950 |    217.801749 | Scott Hartman                                                                                                                                                         |
| 121 |     41.385391 |    643.207900 | Ferran Sayol                                                                                                                                                          |
| 122 |    860.101840 |     74.583062 | Mathieu Pélissié                                                                                                                                                      |
| 123 |    609.327820 |    155.625867 | Steven Traver                                                                                                                                                         |
| 124 |    876.048006 |    153.168496 | Andrew A. Farke                                                                                                                                                       |
| 125 |    522.383866 |    214.863290 | Jakovche                                                                                                                                                              |
| 126 |    908.084067 |     19.693373 | kreidefossilien.de                                                                                                                                                    |
| 127 |    231.269510 |     78.515722 | Chris huh                                                                                                                                                             |
| 128 |    705.880930 |    417.934456 | Ferran Sayol                                                                                                                                                          |
| 129 |    575.430385 |    179.317453 | Scott Hartman                                                                                                                                                         |
| 130 |    402.284291 |    275.592562 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 131 |    600.467439 |    453.947659 | Yan Wong                                                                                                                                                              |
| 132 |    176.590087 |    333.921142 | Ingo Braasch                                                                                                                                                          |
| 133 |    125.143614 |    417.932416 | Harold N Eyster                                                                                                                                                       |
| 134 |    505.499098 |    609.820011 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 135 |    603.689535 |    502.089522 | Zimices                                                                                                                                                               |
| 136 |    702.186545 |    708.741988 | Scott Hartman                                                                                                                                                         |
| 137 |    866.779543 |    308.044282 | Chase Brownstein                                                                                                                                                      |
| 138 |     20.023826 |    600.745538 | FunkMonk                                                                                                                                                              |
| 139 |    635.897809 |    681.020773 | C. Camilo Julián-Caballero                                                                                                                                            |
| 140 |    494.226816 |    122.275441 | Zimices                                                                                                                                                               |
| 141 |    105.562540 |    287.004970 | Andy Wilson                                                                                                                                                           |
| 142 |     40.852958 |    141.486948 | NA                                                                                                                                                                    |
| 143 |    821.968939 |    291.333260 | Stuart Humphries                                                                                                                                                      |
| 144 |    915.014666 |    771.889462 | Zimices                                                                                                                                                               |
| 145 |    764.090397 |    711.017625 | Ben Liebeskind                                                                                                                                                        |
| 146 |    739.744683 |    382.917026 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 147 |    981.402611 |     15.959977 | NA                                                                                                                                                                    |
| 148 |    668.474780 |    397.370760 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 149 |    594.037736 |    352.508910 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                        |
| 150 |    112.382759 |    207.763078 | Scott Hartman                                                                                                                                                         |
| 151 |    784.054543 |    434.889918 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 152 |    291.923079 |    492.339333 | Zimices                                                                                                                                                               |
| 153 |    982.880031 |    552.566007 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 154 |    658.727681 |    273.439987 | Robert Hering                                                                                                                                                         |
| 155 |    146.332878 |     99.986394 | Allison Pease                                                                                                                                                         |
| 156 |    515.786466 |    307.953898 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 157 |    498.263020 |    443.920414 | Yan Wong                                                                                                                                                              |
| 158 |    410.554459 |    431.152237 | Matt Crook                                                                                                                                                            |
| 159 |    825.888319 |    264.672220 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 160 |    531.177286 |    593.919292 | Matt Crook                                                                                                                                                            |
| 161 |    115.433435 |    322.009367 | Michelle Site                                                                                                                                                         |
| 162 |    260.114476 |    439.896797 | Allison Pease                                                                                                                                                         |
| 163 |    624.664045 |    478.232014 | Zimices                                                                                                                                                               |
| 164 |     78.297635 |     59.829229 | Sarah Werning                                                                                                                                                         |
| 165 |    355.496454 |    468.575623 | Steven Traver                                                                                                                                                         |
| 166 |     27.685194 |    779.293776 | Zimices                                                                                                                                                               |
| 167 |    848.017429 |    286.193570 | Birgit Szabo                                                                                                                                                          |
| 168 |    190.666281 |    558.371321 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 169 |   1006.474037 |     20.862061 | Matt Crook                                                                                                                                                            |
| 170 |    452.000697 |     21.610039 | Milton Tan                                                                                                                                                            |
| 171 |    535.891624 |    697.691676 | Ferran Sayol                                                                                                                                                          |
| 172 |    473.349754 |     79.287375 | NA                                                                                                                                                                    |
| 173 |     93.232431 |    777.868327 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 174 |     16.455285 |    554.372322 | Jagged Fang Designs                                                                                                                                                   |
| 175 |     84.314495 |    139.870805 | Ferran Sayol                                                                                                                                                          |
| 176 |    929.645464 |    258.976918 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                    |
| 177 |    757.794168 |    441.070156 | Chris huh                                                                                                                                                             |
| 178 |    488.051861 |    583.999983 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 179 |    544.845907 |    553.791302 | Zimices                                                                                                                                                               |
| 180 |    645.207806 |    212.916813 | Kai R. Caspar                                                                                                                                                         |
| 181 |    907.485246 |    579.103175 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 182 |    917.830925 |    328.345794 | Ignacio Contreras                                                                                                                                                     |
| 183 |    637.914964 |    169.673669 | Isaure Scavezzoni                                                                                                                                                     |
| 184 |    671.393534 |     58.654702 | Matt Crook                                                                                                                                                            |
| 185 |     89.860965 |    660.863323 | David Orr                                                                                                                                                             |
| 186 |    741.893665 |    355.556755 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 187 |     35.860987 |    667.917769 | T. Michael Keesey (photo by Bc999 \[Black crow\])                                                                                                                     |
| 188 |    524.049502 |    244.762503 | Tasman Dixon                                                                                                                                                          |
| 189 |    693.978537 |    221.717979 | Matt Crook                                                                                                                                                            |
| 190 |    603.547141 |    376.885965 | Zimices                                                                                                                                                               |
| 191 |    146.493595 |     15.524078 | Verdilak                                                                                                                                                              |
| 192 |    689.861690 |     72.299516 | Kamil S. Jaron                                                                                                                                                        |
| 193 |    265.558662 |    235.864496 | Matt Crook                                                                                                                                                            |
| 194 |    384.996430 |    469.842921 | Birgit Lang                                                                                                                                                           |
| 195 |    337.573803 |     95.103403 | Manabu Sakamoto                                                                                                                                                       |
| 196 |    307.682567 |    433.316771 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                              |
| 197 |    397.896580 |    353.879288 | Margot Michaud                                                                                                                                                        |
| 198 |    694.388552 |    505.183400 | Birgit Lang                                                                                                                                                           |
| 199 |    907.889564 |    183.332217 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                                 |
| 200 |    376.530445 |    327.021321 | Sarah Werning                                                                                                                                                         |
| 201 |    452.382951 |     96.827577 | Kamil S. Jaron                                                                                                                                                        |
| 202 |    637.755183 |    503.836228 | Lauren Anderson                                                                                                                                                       |
| 203 |    402.827787 |    170.566072 | Tauana J. Cunha                                                                                                                                                       |
| 204 |    121.938452 |    129.103294 | Andy Wilson                                                                                                                                                           |
| 205 |    957.766805 |    628.673691 | Jagged Fang Designs                                                                                                                                                   |
| 206 |    540.357976 |    457.605081 | Gareth Monger                                                                                                                                                         |
| 207 |    935.870947 |    218.121189 | Scott Hartman                                                                                                                                                         |
| 208 |    924.296478 |    299.395526 | Collin Gross                                                                                                                                                          |
| 209 |    529.519193 |    654.312343 | Joshua Fowler                                                                                                                                                         |
| 210 |    201.822562 |     77.065423 | Birgit Lang                                                                                                                                                           |
| 211 |    140.881867 |    544.244530 | Scott Reid                                                                                                                                                            |
| 212 |    141.863100 |     78.197095 | Zimices                                                                                                                                                               |
| 213 |    317.466867 |    724.228694 | Becky Barnes                                                                                                                                                          |
| 214 |    359.173652 |    545.264629 | Matt Crook                                                                                                                                                            |
| 215 |    313.817445 |      9.274000 | Andrew A. Farke                                                                                                                                                       |
| 216 |    693.922282 |    393.048383 | Christine Axon                                                                                                                                                        |
| 217 |    407.560891 |    249.795861 | Zimices                                                                                                                                                               |
| 218 |    823.893377 |    383.035212 | Rebecca Groom (Based on Photo by Andreas Trepte)                                                                                                                      |
| 219 |    704.005553 |    653.983743 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                                      |
| 220 |    593.178427 |    106.920774 | Gareth Monger                                                                                                                                                         |
| 221 |    727.318606 |    551.176142 | Chris huh                                                                                                                                                             |
| 222 |    599.693229 |    549.522866 | Armin Reindl                                                                                                                                                          |
| 223 |    997.707782 |    316.742006 | Chase Brownstein                                                                                                                                                      |
| 224 |    447.613169 |    588.357055 | Ville Koistinen and T. Michael Keesey                                                                                                                                 |
| 225 |    239.179418 |     95.943037 | Chris huh                                                                                                                                                             |
| 226 |     16.328598 |     76.036380 | T. Tischler                                                                                                                                                           |
| 227 |    882.496298 |    441.485561 | Matt Crook                                                                                                                                                            |
| 228 |    294.322935 |    470.449038 | Zimices                                                                                                                                                               |
| 229 |    636.323770 |    626.623214 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 230 |    644.366456 |     70.500568 | Margot Michaud                                                                                                                                                        |
| 231 |    892.498789 |    247.701152 | B. Duygu Özpolat                                                                                                                                                      |
| 232 |    762.176676 |    643.580352 | Mariana Ruiz (vectorized by T. Michael Keesey)                                                                                                                        |
| 233 |    695.465763 |    277.926674 | Jagged Fang Designs                                                                                                                                                   |
| 234 |    171.746089 |    785.626595 |                                                                                                                                                                       |
| 235 |    743.011883 |    322.620185 | T. Michael Keesey                                                                                                                                                     |
| 236 |    803.885097 |    788.670798 | Andrew A. Farke                                                                                                                                                       |
| 237 |    897.539966 |    656.357256 | Tasman Dixon                                                                                                                                                          |
| 238 |     90.142240 |    574.947583 | Birgit Lang                                                                                                                                                           |
| 239 |    541.217269 |    744.049433 | CNZdenek                                                                                                                                                              |
| 240 |    403.146514 |    564.159360 | Tasman Dixon                                                                                                                                                          |
| 241 |    107.579968 |    453.494769 | Zimices                                                                                                                                                               |
| 242 |    428.345583 |    406.569711 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 243 |    679.745579 |    194.223683 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 244 |    358.621691 |    508.176735 | Javier Luque                                                                                                                                                          |
| 245 |    221.207017 |     38.889362 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                              |
| 246 |    644.241913 |    696.626252 | Tasman Dixon                                                                                                                                                          |
| 247 |    805.196245 |    768.173412 | Lauren Sumner-Rooney                                                                                                                                                  |
| 248 |    195.777214 |    272.862974 | Lauren Sumner-Rooney                                                                                                                                                  |
| 249 |    878.506227 |    778.135437 | Matt Celeskey                                                                                                                                                         |
| 250 |   1004.099278 |    368.064172 | xgirouxb                                                                                                                                                              |
| 251 |    706.169916 |    445.376522 | Zimices                                                                                                                                                               |
| 252 |    582.610189 |    459.345590 | Arthur S. Brum                                                                                                                                                        |
| 253 |    353.048520 |    107.197561 | Ferran Sayol                                                                                                                                                          |
| 254 |    579.952176 |     47.070974 | Jagged Fang Designs                                                                                                                                                   |
| 255 |     25.077442 |    327.240620 | Beth Reinke                                                                                                                                                           |
| 256 |    795.672945 |    296.536886 | Andrew A. Farke, modified from original by H. Milne Edwards                                                                                                           |
| 257 |    551.907327 |    614.327784 | Matt Crook                                                                                                                                                            |
| 258 |    963.713554 |    256.179352 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                      |
| 259 |    701.583600 |    749.143696 | Zimices                                                                                                                                                               |
| 260 |     96.526530 |    251.780454 | Markus A. Grohme                                                                                                                                                      |
| 261 |    912.596253 |     50.248731 | Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)                                                                                         |
| 262 |    170.070146 |    298.437992 | Sharon Wegner-Larsen                                                                                                                                                  |
| 263 |     26.463010 |    573.372070 | Birgit Lang                                                                                                                                                           |
| 264 |     57.386430 |    514.677150 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 265 |    929.487853 |    792.648387 | Markus A. Grohme                                                                                                                                                      |
| 266 |    295.558991 |    766.720401 | Julie Blommaert based on photo by Sofdrakou                                                                                                                           |
| 267 |     44.582146 |    692.989636 | Tasman Dixon                                                                                                                                                          |
| 268 |   1007.025396 |    512.734931 | Andy Wilson                                                                                                                                                           |
| 269 |    803.007696 |    124.406848 | Joanna Wolfe                                                                                                                                                          |
| 270 |    961.575372 |    397.774317 | NA                                                                                                                                                                    |
| 271 |     76.180505 |    419.617126 | Matt Dempsey                                                                                                                                                          |
| 272 |     12.579166 |    759.216146 | Emily Jane McTavish                                                                                                                                                   |
| 273 |    876.308673 |    500.009052 | Dean Schnabel                                                                                                                                                         |
| 274 |    399.360943 |    646.120205 | Matt Crook                                                                                                                                                            |
| 275 |    511.588602 |    407.926279 | Erika Schumacher                                                                                                                                                      |
| 276 |    979.302722 |    528.233085 | Jagged Fang Designs                                                                                                                                                   |
| 277 |    881.162618 |    466.637967 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                          |
| 278 |    876.355580 |    426.603640 | Zimices                                                                                                                                                               |
| 279 |     50.637842 |     64.378377 | Tasman Dixon                                                                                                                                                          |
| 280 |    940.178019 |    201.940345 | Chris huh                                                                                                                                                             |
| 281 |    668.377830 |    426.058282 | Margot Michaud                                                                                                                                                        |
| 282 |     54.169277 |    681.667433 | Martin R. Smith                                                                                                                                                       |
| 283 |    909.767977 |    526.108957 | Steven Traver                                                                                                                                                         |
| 284 |   1008.471822 |    151.334046 | Dmitry Bogdanov                                                                                                                                                       |
| 285 |    198.314157 |    331.391092 | Beth Reinke                                                                                                                                                           |
| 286 |    429.880696 |     74.136849 | Dmitry Bogdanov                                                                                                                                                       |
| 287 |    161.447786 |    744.573589 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 288 |    771.063813 |    466.094053 | Gareth Monger                                                                                                                                                         |
| 289 |    260.404144 |    305.625299 | Scott Hartman                                                                                                                                                         |
| 290 |    760.029479 |    151.974974 | Scott Hartman                                                                                                                                                         |
| 291 |    482.760536 |    169.243762 | Steven Traver                                                                                                                                                         |
| 292 |    704.875254 |    185.162088 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 293 |    256.356052 |    382.620751 | Jessica Anne Miller                                                                                                                                                   |
| 294 |    442.749652 |    660.490306 | NA                                                                                                                                                                    |
| 295 |    593.650444 |     15.184608 | Iain Reid                                                                                                                                                             |
| 296 |    146.414265 |    658.215855 | Matt Crook                                                                                                                                                            |
| 297 |   1012.741566 |    784.990390 | Steven Traver                                                                                                                                                         |
| 298 |    752.717395 |    513.298887 | Erika Schumacher                                                                                                                                                      |
| 299 |    787.597904 |    422.989927 | Mattia Menchetti                                                                                                                                                      |
| 300 |    238.016480 |    515.958698 | Tasman Dixon                                                                                                                                                          |
| 301 |    672.275332 |    146.079572 | Steven Traver                                                                                                                                                         |
| 302 |    499.356784 |     80.462353 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
| 303 |    371.306771 |    574.381083 | Andy Wilson                                                                                                                                                           |
| 304 |    643.392988 |    186.279611 | Collin Gross                                                                                                                                                          |
| 305 |     76.487011 |    307.129698 | Sarah Werning                                                                                                                                                         |
| 306 |    337.896414 |    526.082851 | Stuart Humphries                                                                                                                                                      |
| 307 |    680.526225 |      8.450303 | Dmitry Bogdanov                                                                                                                                                       |
| 308 |    257.218778 |    480.200052 | Maija Karala                                                                                                                                                          |
| 309 |    147.808586 |    121.169234 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 310 |    664.553250 |    484.140533 | Armin Reindl                                                                                                                                                          |
| 311 |    961.397122 |    372.302140 | Sarah Werning                                                                                                                                                         |
| 312 |     29.570207 |    438.127128 | Scott Hartman, modified by T. Michael Keesey                                                                                                                          |
| 313 |    558.002315 |    679.953826 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 314 |    235.502365 |    789.071272 | Markus A. Grohme                                                                                                                                                      |
| 315 |    261.632218 |    221.519080 | Matt Crook                                                                                                                                                            |
| 316 |   1006.078612 |    701.091804 | Ferran Sayol                                                                                                                                                          |
| 317 |    443.783031 |    761.771581 | Andy Wilson                                                                                                                                                           |
| 318 |    889.862659 |    512.416024 | NA                                                                                                                                                                    |
| 319 |    314.427397 |    646.887324 | Maija Karala                                                                                                                                                          |
| 320 |    504.958341 |    790.090840 | Chris huh                                                                                                                                                             |
| 321 |    706.230289 |    764.533455 | Chris huh                                                                                                                                                             |
| 322 |    683.471085 |     92.295252 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 323 |    658.280995 |    577.693700 | Chris huh                                                                                                                                                             |
| 324 |    607.669234 |      3.237849 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                  |
| 325 |    508.889273 |    673.261091 | Scott Hartman                                                                                                                                                         |
| 326 |   1008.214937 |    728.406587 | terngirl                                                                                                                                                              |
| 327 |    428.164503 |    396.038314 | Markus A. Grohme                                                                                                                                                      |
| 328 |   1007.082540 |    385.365623 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 329 |    407.174002 |    148.997350 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                                    |
| 330 |    608.433213 |    435.788155 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                  |
| 331 |    153.660277 |    763.968163 | Markus A. Grohme                                                                                                                                                      |
| 332 |    378.467984 |    722.822287 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 333 |     46.507187 |     84.026104 | Pete Buchholz                                                                                                                                                         |
| 334 |    385.289390 |    411.227478 | Inessa Voet                                                                                                                                                           |
| 335 |    800.750298 |    371.586275 | NA                                                                                                                                                                    |
| 336 |    110.261032 |    559.096089 | JJ Harrison (vectorized by T. Michael Keesey)                                                                                                                         |
| 337 |    513.397589 |    526.815589 | Margot Michaud                                                                                                                                                        |
| 338 |     19.498446 |    632.861898 | Robert Gay                                                                                                                                                            |
| 339 |    401.593227 |    448.783850 | Ferran Sayol                                                                                                                                                          |
| 340 |     59.898716 |    572.508834 | T. Michael Keesey (after Marek Velechovský)                                                                                                                           |
| 341 |    890.749851 |    755.011492 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                            |
| 342 |    500.633787 |    463.049023 | Maxime Dahirel                                                                                                                                                        |
| 343 |    672.473536 |    709.620830 | Milton Tan                                                                                                                                                            |
| 344 |    601.425235 |    481.878552 | Steven Traver                                                                                                                                                         |
| 345 |    266.280832 |    512.878064 | Cesar Julian                                                                                                                                                          |
| 346 |    543.995021 |    432.046436 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 347 |     37.877572 |     12.370388 | Carlos Cano-Barbacil                                                                                                                                                  |
| 348 |    340.649103 |    122.808465 | Dean Schnabel                                                                                                                                                         |
| 349 |    751.815774 |    568.203227 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 350 |    540.384960 |      6.144830 | Erika Schumacher                                                                                                                                                      |
| 351 |    611.036256 |    392.412992 | T. Michael Keesey                                                                                                                                                     |
| 352 |    450.152590 |    615.451821 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                    |
| 353 |    325.351552 |    793.456072 | Shyamal                                                                                                                                                               |
| 354 |    187.145388 |     10.523464 | Jessica Rick                                                                                                                                                          |
| 355 |    110.645251 |    190.301903 | Zimices                                                                                                                                                               |
| 356 |    413.196073 |     22.419104 | Christine Axon                                                                                                                                                        |
| 357 |     92.874960 |    405.330408 | Markus A. Grohme                                                                                                                                                      |
| 358 |    221.199136 |     14.664622 | Erika Schumacher                                                                                                                                                      |
| 359 |    296.146919 |    236.178495 | Ferran Sayol                                                                                                                                                          |
| 360 |    401.964072 |    316.935509 | Steven Traver                                                                                                                                                         |
| 361 |     69.672989 |    142.376615 | Gareth Monger                                                                                                                                                         |
| 362 |    214.173197 |    710.871579 | Kamil S. Jaron                                                                                                                                                        |
| 363 |    467.799432 |     58.944333 | Zimices                                                                                                                                                               |
| 364 |    392.832492 |    552.872381 | Margot Michaud                                                                                                                                                        |
| 365 |    541.128874 |    170.675505 | Chris huh                                                                                                                                                             |
| 366 |    727.911647 |     49.631848 | Louis Ranjard                                                                                                                                                         |
| 367 |    592.844446 |     43.379961 | Beth Reinke                                                                                                                                                           |
| 368 |    612.460943 |     61.065049 | Scott Hartman                                                                                                                                                         |
| 369 |    742.269913 |    715.980543 | NA                                                                                                                                                                    |
| 370 |    417.545836 |    587.315889 | Matt Crook                                                                                                                                                            |
| 371 |    580.291008 |     61.989340 | Matt Martyniuk                                                                                                                                                        |
| 372 |    882.749227 |     87.550539 | Dean Schnabel                                                                                                                                                         |
| 373 |    548.785822 |    156.955346 | Jaime Headden                                                                                                                                                         |
| 374 |     16.003182 |    307.340160 | Jessica Rick                                                                                                                                                          |
| 375 |    244.890120 |    706.673173 | Matt Martyniuk                                                                                                                                                        |
| 376 |    789.252294 |    233.008777 | NA                                                                                                                                                                    |
| 377 |    909.496040 |    589.565186 | Scott Hartman                                                                                                                                                         |
| 378 |    914.320237 |    389.844655 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 379 |    560.547474 |    722.865149 | T. Michael Keesey                                                                                                                                                     |
| 380 |    373.156297 |      4.400109 | C. Camilo Julián-Caballero                                                                                                                                            |
| 381 |    720.398690 |    231.499454 | T. Michael Keesey                                                                                                                                                     |
| 382 |    546.878399 |     80.705709 | Margot Michaud                                                                                                                                                        |
| 383 |    848.140559 |    151.076453 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 384 |    670.419286 |    105.687990 | Zimices                                                                                                                                                               |
| 385 |    184.702177 |    543.139997 | Chris huh                                                                                                                                                             |
| 386 |    427.057630 |    297.656779 | Sarah Werning                                                                                                                                                         |
| 387 |     13.005307 |    348.971090 | Kai R. Caspar                                                                                                                                                         |
| 388 |    838.640250 |    309.885745 | Steven Traver                                                                                                                                                         |
| 389 |    717.174701 |     18.376993 | Mali’o Kodis, photograph property of National Museums of Northern Ireland                                                                                             |
| 390 |    163.617238 |    284.620867 | Noah Schlottman, photo by Carol Cummings                                                                                                                              |
| 391 |    463.518734 |    784.654553 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 392 |     68.377246 |    353.262522 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 393 |    366.573418 |    457.666723 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 394 |    193.544712 |    577.328625 | Tasman Dixon                                                                                                                                                          |
| 395 |    628.021039 |    666.684827 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 396 |     15.337392 |    587.679751 | T. Michael Keesey                                                                                                                                                     |
| 397 |     16.036104 |    742.997022 | Scott Hartman                                                                                                                                                         |
| 398 |    104.448412 |    237.484306 | Zimices                                                                                                                                                               |
| 399 |    686.350367 |    136.794571 | Zimices                                                                                                                                                               |
| 400 |    385.694902 |    702.066819 | Noah Schlottman, photo by Carol Cummings                                                                                                                              |
| 401 |    199.958096 |    312.638301 | Matt Crook                                                                                                                                                            |
| 402 |    170.411863 |    382.701187 | Sarah Werning                                                                                                                                                         |
| 403 |    623.278277 |    264.752127 | Chris huh                                                                                                                                                             |
| 404 |    564.783834 |    561.612762 | DW Bapst (Modified from Bulman, 1964)                                                                                                                                 |
| 405 |    216.847255 |     68.030633 | Sarah Werning                                                                                                                                                         |
| 406 |    893.587471 |    201.605624 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 407 |    593.370640 |     95.416820 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                       |
| 408 |   1009.720223 |    553.353394 | Martin R. Smith                                                                                                                                                       |
| 409 |    601.814964 |    362.692659 | Gareth Monger                                                                                                                                                         |
| 410 |     33.556859 |    541.980625 | xgirouxb                                                                                                                                                              |
| 411 |    350.934219 |    532.072316 | L. Shyamal                                                                                                                                                            |
| 412 |    510.643105 |    749.220480 | Kai R. Caspar                                                                                                                                                         |
| 413 |    101.899016 |    386.170153 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 414 |    310.678217 |     24.490715 | NA                                                                                                                                                                    |
| 415 |    234.234161 |    308.081417 | Andy Wilson                                                                                                                                                           |
| 416 |    579.876289 |    163.135931 | Dmitry Bogdanov                                                                                                                                                       |
| 417 |    295.304785 |    790.992751 | Zimices                                                                                                                                                               |
| 418 |   1007.481513 |    294.672389 | Matt Crook                                                                                                                                                            |
| 419 |    573.332791 |    443.159912 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                                       |
| 420 |   1011.090855 |     89.434899 | NA                                                                                                                                                                    |
| 421 |    842.365195 |     61.067008 | Zimices                                                                                                                                                               |
| 422 |    640.743360 |      5.678838 | Jagged Fang Designs                                                                                                                                                   |
| 423 |    890.708856 |    481.046193 | Henry Lydecker                                                                                                                                                        |
| 424 |    940.866136 |     21.815020 | Margot Michaud                                                                                                                                                        |
| 425 |    150.977379 |    622.823720 | Jagged Fang Designs                                                                                                                                                   |
| 426 |    160.501165 |    553.613753 | Erika Schumacher                                                                                                                                                      |
| 427 |    880.364594 |     15.506560 | NA                                                                                                                                                                    |
| 428 |    961.447921 |    218.315627 | Scott Hartman                                                                                                                                                         |
| 429 |    653.239757 |    155.292416 | Margot Michaud                                                                                                                                                        |
| 430 |     14.335144 |    666.241876 | Andy Wilson                                                                                                                                                           |
| 431 |    914.275505 |    455.305022 | Armin Reindl                                                                                                                                                          |
| 432 |    484.031117 |    250.433913 | Markus A. Grohme                                                                                                                                                      |
| 433 |    179.246768 |    660.638268 | C. Camilo Julián-Caballero                                                                                                                                            |
| 434 |    712.188823 |     87.102613 | Felix Vaux                                                                                                                                                            |
| 435 |    495.533257 |      9.280014 | S.Martini                                                                                                                                                             |
| 436 |    215.850207 |    570.362515 | Michelle Site                                                                                                                                                         |
| 437 |    179.945134 |    720.094708 | FunkMonk                                                                                                                                                              |
| 438 |    715.067095 |    242.825204 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 439 |    799.043662 |    751.429363 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 440 |    553.582079 |    699.718437 | Felix Vaux                                                                                                                                                            |
| 441 |    345.397295 |    323.284063 | Markus A. Grohme                                                                                                                                                      |
| 442 |     98.025136 |    130.859047 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 443 |    854.946703 |    243.109184 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 444 |    665.708435 |    677.418280 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 445 |    923.851349 |    618.688897 | Margot Michaud                                                                                                                                                        |
| 446 |     46.536124 |    790.130652 | Melissa Broussard                                                                                                                                                     |
| 447 |    200.245162 |    465.818159 | Gareth Monger                                                                                                                                                         |
| 448 |    769.430588 |    116.154725 | Gareth Monger                                                                                                                                                         |
| 449 |    809.669838 |     15.465818 | Tauana J. Cunha                                                                                                                                                       |
| 450 |    234.785418 |    107.240334 | Xvazquez (vectorized by William Gearty)                                                                                                                               |
| 451 |    671.791539 |    170.236840 | Scott Hartman                                                                                                                                                         |
| 452 |     33.448392 |     51.245642 | Shyamal                                                                                                                                                               |
| 453 |    621.733931 |    702.124971 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 454 |    419.255761 |    371.012959 | Markus A. Grohme                                                                                                                                                      |
| 455 |    404.610090 |    788.788613 | Andy Wilson                                                                                                                                                           |
| 456 |     84.255323 |    228.153518 | Dmitry Bogdanov                                                                                                                                                       |
| 457 |    432.443654 |    104.631247 | Birgit Lang                                                                                                                                                           |
| 458 |    857.724646 |    172.334436 | Steven Traver                                                                                                                                                         |
| 459 |    745.456933 |    391.508012 | Chris huh                                                                                                                                                             |
| 460 |    526.127212 |     66.689229 | Chris huh                                                                                                                                                             |
| 461 |    948.163576 |    244.121474 | Cesar Julian                                                                                                                                                          |
| 462 |    236.242576 |    237.087786 | Baheerathan Murugavel                                                                                                                                                 |
| 463 |    203.075334 |    243.005526 | Birgit Lang                                                                                                                                                           |
| 464 |    181.652899 |    728.364138 | Tony Ayling                                                                                                                                                           |
| 465 |    572.321580 |    367.491983 | Gareth Monger                                                                                                                                                         |
| 466 |    262.740944 |    253.168230 | CNZdenek                                                                                                                                                              |
| 467 |    381.515620 |    490.951457 | Chris huh                                                                                                                                                             |
| 468 |    528.647351 |     15.286968 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 469 |    547.356989 |    333.185196 | Noah Schlottman                                                                                                                                                       |
| 470 |    487.921316 |    479.387065 | Gareth Monger                                                                                                                                                         |
| 471 |    816.846916 |    357.902070 | Zimices                                                                                                                                                               |
| 472 |    946.262108 |    193.074105 | Markus A. Grohme                                                                                                                                                      |
| 473 |     12.689177 |    698.842721 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                                 |
| 474 |   1015.121843 |    250.661565 | Gareth Monger                                                                                                                                                         |
| 475 |    714.363716 |    370.343189 | Chris huh                                                                                                                                                             |
| 476 |    763.155699 |    485.474921 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
| 477 |    757.065651 |    531.566038 | Matt Crook                                                                                                                                                            |
| 478 |    527.079411 |    136.573217 | Chris huh                                                                                                                                                             |
| 479 |    412.400701 |    602.588256 | NA                                                                                                                                                                    |
| 480 |    287.018679 |    735.965684 | Matt Crook                                                                                                                                                            |
| 481 |    967.189288 |    464.362395 | T. Michael Keesey                                                                                                                                                     |
| 482 |    234.450673 |    525.039594 | NA                                                                                                                                                                    |
| 483 |    438.458404 |    152.724705 | Martin R. Smith                                                                                                                                                       |
| 484 |    424.387199 |    520.575936 | Markus A. Grohme                                                                                                                                                      |
| 485 |    415.451156 |    657.336757 | Chris huh                                                                                                                                                             |
| 486 |    497.109446 |    422.922723 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
| 487 |    318.002036 |    475.452618 | Trond R. Oskars                                                                                                                                                       |
| 488 |    420.547321 |      5.742118 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                  |
| 489 |    529.288675 |    630.596265 | Scott Hartman                                                                                                                                                         |
| 490 |     19.785825 |     91.902492 | Danielle Alba                                                                                                                                                         |
| 491 |    329.304016 |    166.024766 | Steven Traver                                                                                                                                                         |
| 492 |    701.312330 |    732.157960 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 493 |    715.138854 |    643.761233 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 494 |    256.519525 |    653.384890 | Ferran Sayol                                                                                                                                                          |
| 495 |      7.253353 |    143.630268 | T. Michael Keesey                                                                                                                                                     |
| 496 |    450.954877 |    118.278024 | Steven Traver                                                                                                                                                         |
| 497 |    633.478179 |     86.499473 | Iain Reid                                                                                                                                                             |
| 498 |    332.457026 |     31.435434 | Mathilde Cordellier                                                                                                                                                   |
| 499 |    901.077229 |    263.219831 | Tyler McCraney                                                                                                                                                        |
| 500 |    999.341646 |    687.842106 | Zimices                                                                                                                                                               |
| 501 |    738.493771 |    791.053172 | Gareth Monger                                                                                                                                                         |
| 502 |    375.149327 |    563.122445 | Smokeybjb                                                                                                                                                             |
| 503 |    366.788438 |    662.357603 | Steven Traver                                                                                                                                                         |
| 504 |    995.736295 |    209.719741 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                              |
| 505 |    910.719029 |    628.929149 | Scott Hartman                                                                                                                                                         |
| 506 |    958.143954 |    564.699489 | Zimices                                                                                                                                                               |
| 507 |    660.561107 |    584.248982 | NA                                                                                                                                                                    |
| 508 |    293.671957 |    315.047632 | Chris huh                                                                                                                                                             |
| 509 |    257.961906 |    157.846320 | T. Michael Keesey                                                                                                                                                     |
| 510 |    141.077494 |    773.971105 | Kamil S. Jaron                                                                                                                                                        |
| 511 |    698.453852 |    380.810969 | Jagged Fang Designs                                                                                                                                                   |

    #> Your tweet has been posted!
