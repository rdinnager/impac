
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

ArtFavor & annaleeblysse, Birgit Lang, based on a photo by D. Sikes,
Gabriela Palomo-Munoz, Christoph Schomburg, Ferran Sayol, Matt Crook,
Margot Michaud, Chris huh, Jack Mayer Wood, Jennifer Trimble, T. Michael
Keesey, Zimices, Scott Hartman, Kanchi Nanjo, Mali’o Kodis, photograph
by Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>),
Martin R. Smith, after Skovsted et al 2015, Keith Murdock (photo), John
E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Andy
Wilson, Caleb M. Brown, Gareth Monger, Jagged Fang Designs, Nobu Tamura
(vectorized by T. Michael Keesey), Steven Traver, Hans Hillewaert,
Collin Gross, Cesar Julian, Stanton F. Fink (vectorized by T. Michael
Keesey), Kai R. Caspar, Bruno Maggia, Ignacio Contreras, George Edward
Lodge (modified by T. Michael Keesey), Carlos Cano-Barbacil, Sarah
Alewijnse, Yan Wong (vectorization) from 1873 illustration, Harold N
Eyster, Smokeybjb, Conty (vectorized by T. Michael Keesey), Yan Wong,
Markus A. Grohme, Robert Hering, David Sim (photograph) and T. Michael
Keesey (vectorization), Roberto Díaz Sibaja, Kimberly Haddrell, Kamil S.
Jaron, C. Camilo Julián-Caballero, Nobu Tamura (vectorized by A.
Verrière), Sergio A. Muñoz-Gómez, Dmitry Bogdanov, Dmitry Bogdanov
(vectorized by T. Michael Keesey), Tasman Dixon, Jimmy Bernot, Isaure
Scavezzoni, Joanna Wolfe, Ville-Veikko Sinkkonen, Nobu Tamura (modified
by T. Michael Keesey), Jose Carlos Arenas-Monroy, Felix Vaux, Emily Jane
McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Michelle Site, FunkMonk, Mathew Wedel, Manabu Bessho-Uehara, Birgit
Lang, Marie-Aimée Allard, Marie Russell, Alexander Schmidt-Lebuhn,
Saguaro Pictures (source photo) and T. Michael Keesey, Gopal Murali,
Lukasiniho, Thibaut Brunet, Emily Willoughby, Ieuan Jones, Lukas
Panzarin (vectorized by T. Michael Keesey), Juan Carlos Jerí, T. Michael
Keesey (after MPF), Maija Karala, Rainer Schoch, Sarah Werning, Chuanixn
Yu, Anthony Caravaggi, Becky Barnes, Nobu Tamura, vectorized by Zimices,
Abraão Leite, Milton Tan, Noah Schlottman, photo by Antonio Guillén,
Lukas Panzarin, Pete Buchholz, Noah Schlottman, kotik,
SauropodomorphMonarch, Eduard Solà (vectorized by T. Michael Keesey),
Andrew A. Farke, Johan Lindgren, Michael W. Caldwell, Takuya Konishi,
Luis M. Chiappe, Stuart Humphries, Original drawing by Dmitry Bogdanov,
vectorized by Roberto Díaz Sibaja, Yan Wong from illustration by Jules
Richard (1907), Lankester Edwin Ray (vectorized by T. Michael Keesey),
Jaime Headden, Tyler McCraney, Ellen Edmonson and Hugh Chrisp
(illustration) and Timothy J. Bartley (silhouette), Darius Nau, DW Bapst
(modified from Bates et al., 2005), Steven Coombs, Cristopher Silva,
Rene Martin, L. Shyamal, Julio Garza, Arthur S. Brum, Fernando Campos De
Domenico, Sam Droege (photography) and T. Michael Keesey
(vectorization), Xavier Giroux-Bougard, Maxime Dahirel, Darren Naish
(vectorized by T. Michael Keesey), T. Michael Keesey (after Masteraah),
John Curtis (vectorized by T. Michael Keesey), David Tana, Chris
Jennings (vectorized by A. Verrière), Joschua Knüppe, Lani Mohan, Joe
Schneid (vectorized by T. Michael Keesey), Zimices / Julián Bayona,
Dmitry Bogdanov (modified by T. Michael Keesey), Roderic Page and Lois
Page, C. W. Nash (illustration) and Timothy J. Bartley (silhouette),
U.S. National Park Service (vectorized by William Gearty), Ghedoghedo
(vectorized by T. Michael Keesey), Karla Martinez, Smokeybjb (modified
by Mike Keesey), Meliponicultor Itaymbere, Michael P. Taylor, Scott
Reid, Tracy A. Heath, Beth Reinke, Christine Axon, Tauana J. Cunha,
Henry Fairfield Osborn, vectorized by Zimices, Ellen Edmonson
(illustration) and Timothy J. Bartley (silhouette), Michele M Tobias,
Dean Schnabel, terngirl, Jaime A. Headden (vectorized by T. Michael
Keesey), Mariana Ruiz Villarreal (modified by T. Michael Keesey),
Smokeybjb (vectorized by T. Michael Keesey), Ludwik Gąsiorowski, Noah
Schlottman, photo by Carlos Sánchez-Ortiz, Roberto Diaz Sibaja, based on
Domser, Vijay Cavale (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, John Conway, Noah Schlottman, photo by
Martin V. Sørensen, Robbie N. Cada (vectorized by T. Michael Keesey),
Jonathan Wells, Chris A. Hamilton, Michael Scroggie, Derek Bakken
(photograph) and T. Michael Keesey (vectorization), Armin Reindl, Ingo
Braasch, Rebecca Groom, Mali’o Kodis, photograph by P. Funch and R.M.
Kristensen, Danny Cicchetti (vectorized by T. Michael Keesey), Jaime
Headden, modified by T. Michael Keesey, Jan A. Venter, Herbert H. T.
Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey),
Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant
C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield &
T. Michael Keesey, Michael “FunkMonk” B. H. (vectorized by T. Michael
Keesey), Tambja (vectorized by T. Michael Keesey), T. Michael Keesey
(from a photo by Maximilian Paradiz), Joris van der Ham (vectorized by
T. Michael Keesey), Chase Brownstein

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                             |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    622.409516 |    143.168629 | ArtFavor & annaleeblysse                                                                                                                                           |
|   2 |    775.023758 |    664.647807 | Birgit Lang, based on a photo by D. Sikes                                                                                                                          |
|   3 |    440.704304 |    447.271206 | Gabriela Palomo-Munoz                                                                                                                                              |
|   4 |    568.436303 |     71.187018 | Christoph Schomburg                                                                                                                                                |
|   5 |    455.840986 |    131.379018 | Ferran Sayol                                                                                                                                                       |
|   6 |    919.017880 |    311.755430 | NA                                                                                                                                                                 |
|   7 |     89.807934 |    412.241946 | Matt Crook                                                                                                                                                         |
|   8 |    517.238291 |    349.180813 | Margot Michaud                                                                                                                                                     |
|   9 |    363.176230 |    710.596167 | Chris huh                                                                                                                                                          |
|  10 |    921.590011 |     35.120162 | Gabriela Palomo-Munoz                                                                                                                                              |
|  11 |    883.786557 |    415.496715 | Margot Michaud                                                                                                                                                     |
|  12 |    677.718376 |    420.107511 | Jack Mayer Wood                                                                                                                                                    |
|  13 |     61.391015 |    176.471845 | NA                                                                                                                                                                 |
|  14 |    389.603539 |     37.669649 | Jennifer Trimble                                                                                                                                                   |
|  15 |    888.154763 |    142.347132 | NA                                                                                                                                                                 |
|  16 |    641.700688 |    689.491667 | T. Michael Keesey                                                                                                                                                  |
|  17 |    304.062050 |    371.998581 | Zimices                                                                                                                                                            |
|  18 |    277.403053 |    560.044871 | Scott Hartman                                                                                                                                                      |
|  19 |    583.736037 |    586.235839 | Ferran Sayol                                                                                                                                                       |
|  20 |    995.731531 |    720.389195 | Kanchi Nanjo                                                                                                                                                       |
|  21 |    178.210040 |    658.993171 | Mali’o Kodis, photograph by Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>)                                                                     |
|  22 |     73.262634 |    602.816900 | Martin R. Smith, after Skovsted et al 2015                                                                                                                         |
|  23 |    812.868670 |    516.288791 | Scott Hartman                                                                                                                                                      |
|  24 |    737.791663 |    692.262531 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey      |
|  25 |    424.161574 |    596.824498 | Andy Wilson                                                                                                                                                        |
|  26 |    280.761585 |    107.227749 | Margot Michaud                                                                                                                                                     |
|  27 |    637.327030 |    533.232040 | Matt Crook                                                                                                                                                         |
|  28 |    555.630724 |    489.269664 | Matt Crook                                                                                                                                                         |
|  29 |    773.908906 |    175.621095 | Caleb M. Brown                                                                                                                                                     |
|  30 |    226.711269 |    283.395585 | Gareth Monger                                                                                                                                                      |
|  31 |    248.171999 |    529.055619 | Christoph Schomburg                                                                                                                                                |
|  32 |    479.682671 |    213.382784 | Margot Michaud                                                                                                                                                     |
|  33 |    283.086013 |    175.815391 | Ferran Sayol                                                                                                                                                       |
|  34 |    188.811490 |    188.528428 | NA                                                                                                                                                                 |
|  35 |    711.700561 |    277.632013 | Jagged Fang Designs                                                                                                                                                |
|  36 |    909.490329 |    653.626927 | Ferran Sayol                                                                                                                                                       |
|  37 |    548.901381 |    713.489015 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
|  38 |     73.719932 |     74.424762 | Steven Traver                                                                                                                                                      |
|  39 |    778.192545 |    575.959936 | Hans Hillewaert                                                                                                                                                    |
|  40 |     98.193670 |    744.871531 | Matt Crook                                                                                                                                                         |
|  41 |    951.357248 |    511.325201 | Collin Gross                                                                                                                                                       |
|  42 |    281.432228 |    650.108856 | Cesar Julian                                                                                                                                                       |
|  43 |    909.371417 |    766.873800 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                  |
|  44 |     96.439094 |    288.126283 | Kai R. Caspar                                                                                                                                                      |
|  45 |    897.030223 |    571.811176 | Gareth Monger                                                                                                                                                      |
|  46 |    558.528304 |    259.581429 | Bruno Maggia                                                                                                                                                       |
|  47 |    718.937884 |    342.945012 | Ignacio Contreras                                                                                                                                                  |
|  48 |    204.603265 |    437.863960 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                                |
|  49 |    175.499795 |     92.663796 | Matt Crook                                                                                                                                                         |
|  50 |    350.301135 |    248.289157 | Andy Wilson                                                                                                                                                        |
|  51 |    162.038569 |    780.948332 | Carlos Cano-Barbacil                                                                                                                                               |
|  52 |    181.868582 |     21.088602 | Zimices                                                                                                                                                            |
|  53 |    777.440500 |    760.848573 | Chris huh                                                                                                                                                          |
|  54 |    235.682411 |    602.004939 | Steven Traver                                                                                                                                                      |
|  55 |    159.375189 |    504.861151 | Sarah Alewijnse                                                                                                                                                    |
|  56 |    650.880742 |     31.694661 | Jagged Fang Designs                                                                                                                                                |
|  57 |    443.048102 |    773.833279 | Zimices                                                                                                                                                            |
|  58 |    683.724685 |    645.712633 | Yan Wong (vectorization) from 1873 illustration                                                                                                                    |
|  59 |    507.046243 |     82.816386 | Andy Wilson                                                                                                                                                        |
|  60 |    748.395614 |    443.571753 | Harold N Eyster                                                                                                                                                    |
|  61 |    701.658127 |    232.023283 | T. Michael Keesey                                                                                                                                                  |
|  62 |    452.350371 |    677.909050 | Jagged Fang Designs                                                                                                                                                |
|  63 |    709.346710 |     53.837257 | NA                                                                                                                                                                 |
|  64 |    345.497760 |    487.267943 | NA                                                                                                                                                                 |
|  65 |    949.022240 |    133.319510 | Gareth Monger                                                                                                                                                      |
|  66 |    337.416807 |    134.350112 | Chris huh                                                                                                                                                          |
|  67 |    762.971768 |    482.421919 | Jagged Fang Designs                                                                                                                                                |
|  68 |    596.577293 |    754.927781 | Smokeybjb                                                                                                                                                          |
|  69 |    600.226942 |    782.628971 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
|  70 |    299.751005 |     43.203364 | Conty (vectorized by T. Michael Keesey)                                                                                                                            |
|  71 |    340.849770 |    770.709856 | Jagged Fang Designs                                                                                                                                                |
|  72 |    503.948383 |    414.291629 | Yan Wong                                                                                                                                                           |
|  73 |    881.500476 |    241.315071 | Gareth Monger                                                                                                                                                      |
|  74 |     72.822065 |    480.284694 | Markus A. Grohme                                                                                                                                                   |
|  75 |    567.550780 |    293.867107 | NA                                                                                                                                                                 |
|  76 |    507.476463 |     28.110587 | Robert Hering                                                                                                                                                      |
|  77 |    723.424135 |    127.861752 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
|  78 |    584.931297 |    662.675595 | Roberto Díaz Sibaja                                                                                                                                                |
|  79 |    598.081122 |    244.504413 | Margot Michaud                                                                                                                                                     |
|  80 |    811.074340 |    276.358254 | Kimberly Haddrell                                                                                                                                                  |
|  81 |    157.779991 |    223.688289 | Kamil S. Jaron                                                                                                                                                     |
|  82 |    730.201115 |    526.826978 | NA                                                                                                                                                                 |
|  83 |    437.562157 |    288.022143 | C. Camilo Julián-Caballero                                                                                                                                         |
|  84 |    244.052875 |    499.075255 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                            |
|  85 |     51.302520 |    353.980456 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
|  86 |    775.458268 |    303.154267 | Chris huh                                                                                                                                                          |
|  87 |    967.543016 |    588.688940 | Zimices                                                                                                                                                            |
|  88 |    331.960142 |    415.905706 | NA                                                                                                                                                                 |
|  89 |     32.106709 |    592.688755 | Sergio A. Muñoz-Gómez                                                                                                                                              |
|  90 |    372.640644 |     58.043196 | Christoph Schomburg                                                                                                                                                |
|  91 |     20.522035 |    707.262133 | Ferran Sayol                                                                                                                                                       |
|  92 |    273.317043 |    684.069376 | Scott Hartman                                                                                                                                                      |
|  93 |    698.108539 |    556.951032 | Roberto Díaz Sibaja                                                                                                                                                |
|  94 |    179.786893 |    365.538556 | Scott Hartman                                                                                                                                                      |
|  95 |    276.716001 |    320.577977 | Ferran Sayol                                                                                                                                                       |
|  96 |    789.179309 |    214.311223 | Dmitry Bogdanov                                                                                                                                                    |
|  97 |    696.366998 |    720.894846 | Zimices                                                                                                                                                            |
|  98 |    293.753672 |    454.018429 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
|  99 |    499.173195 |    554.950786 | Tasman Dixon                                                                                                                                                       |
| 100 |    225.948345 |    727.901913 | Carlos Cano-Barbacil                                                                                                                                               |
| 101 |    350.430925 |    301.421090 | Ferran Sayol                                                                                                                                                       |
| 102 |    848.475350 |     12.713166 | Scott Hartman                                                                                                                                                      |
| 103 |    794.911438 |    411.020411 | Jagged Fang Designs                                                                                                                                                |
| 104 |    388.293134 |    337.163868 | Steven Traver                                                                                                                                                      |
| 105 |    862.252527 |    579.686270 | Margot Michaud                                                                                                                                                     |
| 106 |    957.324099 |    458.149078 | Roberto Díaz Sibaja                                                                                                                                                |
| 107 |    574.924810 |    450.818285 | Christoph Schomburg                                                                                                                                                |
| 108 |    306.202816 |    108.472937 | Chris huh                                                                                                                                                          |
| 109 |    152.296124 |     48.668477 | Markus A. Grohme                                                                                                                                                   |
| 110 |    780.130906 |    552.043367 | Jimmy Bernot                                                                                                                                                       |
| 111 |    257.274877 |    693.027740 | Isaure Scavezzoni                                                                                                                                                  |
| 112 |    162.255208 |    452.088535 | Collin Gross                                                                                                                                                       |
| 113 |    696.072751 |    202.732114 | Joanna Wolfe                                                                                                                                                       |
| 114 |    987.056115 |    437.768189 | Scott Hartman                                                                                                                                                      |
| 115 |    465.286347 |    263.491944 | Scott Hartman                                                                                                                                                      |
| 116 |    472.628150 |    395.376035 | Carlos Cano-Barbacil                                                                                                                                               |
| 117 |     27.844355 |    770.199351 | Ville-Veikko Sinkkonen                                                                                                                                             |
| 118 |    461.076622 |    486.430591 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 119 |    851.826164 |    736.348217 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                        |
| 120 |    973.005892 |    409.433513 | Jack Mayer Wood                                                                                                                                                    |
| 121 |    685.625482 |     17.328126 | Jose Carlos Arenas-Monroy                                                                                                                                          |
| 122 |    958.507033 |    695.234823 | Margot Michaud                                                                                                                                                     |
| 123 |    975.447190 |    639.598246 | Felix Vaux                                                                                                                                                         |
| 124 |    911.076861 |    724.514977 | Zimices                                                                                                                                                            |
| 125 |    121.483364 |    579.607434 | Andy Wilson                                                                                                                                                        |
| 126 |    485.020424 |    373.855090 | Scott Hartman                                                                                                                                                      |
| 127 |    674.800435 |    167.399623 | Andy Wilson                                                                                                                                                        |
| 128 |    144.728654 |    569.585154 | Steven Traver                                                                                                                                                      |
| 129 |    838.376729 |    470.898418 | T. Michael Keesey                                                                                                                                                  |
| 130 |    136.028483 |    402.548525 | Chris huh                                                                                                                                                          |
| 131 |    229.460012 |    400.164741 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                        |
| 132 |    306.596660 |    614.779410 | Margot Michaud                                                                                                                                                     |
| 133 |    761.053429 |    117.397973 | Jagged Fang Designs                                                                                                                                                |
| 134 |    880.601927 |    538.248700 | Margot Michaud                                                                                                                                                     |
| 135 |    926.005050 |    624.556976 | Michelle Site                                                                                                                                                      |
| 136 |    325.435089 |    542.913969 | Margot Michaud                                                                                                                                                     |
| 137 |    123.434978 |    195.943045 | NA                                                                                                                                                                 |
| 138 |    903.561716 |    263.010775 | Markus A. Grohme                                                                                                                                                   |
| 139 |    388.838772 |    222.309945 | FunkMonk                                                                                                                                                           |
| 140 |    857.659623 |    484.696099 | Kamil S. Jaron                                                                                                                                                     |
| 141 |    298.421156 |     10.455598 | Mathew Wedel                                                                                                                                                       |
| 142 |    799.583326 |     18.633823 | Gareth Monger                                                                                                                                                      |
| 143 |    793.807690 |    386.389907 | Manabu Bessho-Uehara                                                                                                                                               |
| 144 |    770.063115 |    326.950743 | Jagged Fang Designs                                                                                                                                                |
| 145 |    821.376398 |    631.584708 | T. Michael Keesey                                                                                                                                                  |
| 146 |    386.416378 |    188.513273 | T. Michael Keesey                                                                                                                                                  |
| 147 |    363.367837 |     97.439414 | Collin Gross                                                                                                                                                       |
| 148 |     52.494537 |     21.397608 | Margot Michaud                                                                                                                                                     |
| 149 |    986.537500 |    120.512328 | Matt Crook                                                                                                                                                         |
| 150 |    846.767401 |    670.210376 | Matt Crook                                                                                                                                                         |
| 151 |    624.730712 |    308.038807 | Zimices                                                                                                                                                            |
| 152 |    243.741889 |    746.363021 | Birgit Lang                                                                                                                                                        |
| 153 |    870.762767 |    498.170222 | Matt Crook                                                                                                                                                         |
| 154 |    849.556203 |    600.964291 | NA                                                                                                                                                                 |
| 155 |    147.147841 |    478.888677 | Felix Vaux                                                                                                                                                         |
| 156 |    472.191520 |    738.058388 | Gareth Monger                                                                                                                                                      |
| 157 |     41.986971 |    723.754265 | Matt Crook                                                                                                                                                         |
| 158 |    895.338053 |    701.962827 | Zimices                                                                                                                                                            |
| 159 |    519.783625 |    755.720122 | Marie-Aimée Allard                                                                                                                                                 |
| 160 |     17.513007 |    202.907192 | Jagged Fang Designs                                                                                                                                                |
| 161 |    391.696387 |    530.272296 | Yan Wong                                                                                                                                                           |
| 162 |    385.485916 |     77.034959 | Marie Russell                                                                                                                                                      |
| 163 |    500.058169 |    281.349603 | Alexander Schmidt-Lebuhn                                                                                                                                           |
| 164 |    985.132025 |     82.975503 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                              |
| 165 |    297.719981 |    571.145770 | Gopal Murali                                                                                                                                                       |
| 166 |    660.922562 |     46.189399 | Lukasiniho                                                                                                                                                         |
| 167 |    719.234469 |    762.534333 | Zimices                                                                                                                                                            |
| 168 |    814.259465 |    306.721245 | Margot Michaud                                                                                                                                                     |
| 169 |    350.092938 |    321.877273 | Scott Hartman                                                                                                                                                      |
| 170 |    625.499474 |    468.491603 | Margot Michaud                                                                                                                                                     |
| 171 |    298.217827 |    222.241724 | NA                                                                                                                                                                 |
| 172 |     25.736621 |    507.481281 | Margot Michaud                                                                                                                                                     |
| 173 |    637.338280 |    187.650915 | C. Camilo Julián-Caballero                                                                                                                                         |
| 174 |    344.789310 |    457.183416 | Thibaut Brunet                                                                                                                                                     |
| 175 |    852.853969 |    695.120089 | Joanna Wolfe                                                                                                                                                       |
| 176 |    123.136083 |     28.764109 | Margot Michaud                                                                                                                                                     |
| 177 |    652.527168 |    299.365774 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 178 |    285.942767 |    699.360152 | Zimices                                                                                                                                                            |
| 179 |    446.450960 |    386.407254 | Markus A. Grohme                                                                                                                                                   |
| 180 |    229.238215 |    356.287974 | Markus A. Grohme                                                                                                                                                   |
| 181 |    641.572274 |    388.499692 | Margot Michaud                                                                                                                                                     |
| 182 |     31.682688 |    320.273622 | Margot Michaud                                                                                                                                                     |
| 183 |    339.540685 |    221.942276 | Zimices                                                                                                                                                            |
| 184 |    517.153676 |    372.440498 | Gabriela Palomo-Munoz                                                                                                                                              |
| 185 |    834.258469 |    438.603056 | T. Michael Keesey                                                                                                                                                  |
| 186 |    285.925830 |    271.002390 | Emily Willoughby                                                                                                                                                   |
| 187 |    436.620838 |    184.773881 | Dmitry Bogdanov                                                                                                                                                    |
| 188 |    745.668557 |    250.713749 | Ieuan Jones                                                                                                                                                        |
| 189 |   1000.387991 |    617.082122 | T. Michael Keesey                                                                                                                                                  |
| 190 |    493.258038 |    528.872540 | Jagged Fang Designs                                                                                                                                                |
| 191 |    113.186570 |    665.050182 | Matt Crook                                                                                                                                                         |
| 192 |    193.368105 |    249.762770 | Margot Michaud                                                                                                                                                     |
| 193 |    611.256689 |    704.433743 | Andy Wilson                                                                                                                                                        |
| 194 |    187.998478 |    344.065487 | Lukas Panzarin (vectorized by T. Michael Keesey)                                                                                                                   |
| 195 |    927.162383 |    395.416703 | Juan Carlos Jerí                                                                                                                                                   |
| 196 |     38.244939 |    680.337837 | Scott Hartman                                                                                                                                                      |
| 197 |    328.108777 |      8.328240 | Scott Hartman                                                                                                                                                      |
| 198 |    786.590036 |    680.978179 | Zimices                                                                                                                                                            |
| 199 |    649.398257 |    465.251218 | T. Michael Keesey (after MPF)                                                                                                                                      |
| 200 |    801.087066 |     56.369021 | Margot Michaud                                                                                                                                                     |
| 201 |    400.998298 |    169.648917 | Maija Karala                                                                                                                                                       |
| 202 |     31.958584 |    553.739946 | Matt Crook                                                                                                                                                         |
| 203 |     81.908917 |     12.607107 | Zimices                                                                                                                                                            |
| 204 |    304.880956 |     64.711133 | Zimices                                                                                                                                                            |
| 205 |    491.519205 |    133.840873 | Mathew Wedel                                                                                                                                                       |
| 206 |    807.238704 |    728.667628 | NA                                                                                                                                                                 |
| 207 |    762.381060 |    540.224513 | NA                                                                                                                                                                 |
| 208 |    703.584516 |    783.941168 | Ferran Sayol                                                                                                                                                       |
| 209 |    932.944220 |    416.493803 | T. Michael Keesey                                                                                                                                                  |
| 210 |    541.063373 |    543.100991 | Ignacio Contreras                                                                                                                                                  |
| 211 |    784.234632 |    715.670303 | Rainer Schoch                                                                                                                                                      |
| 212 |    195.719124 |    567.782135 | Sarah Werning                                                                                                                                                      |
| 213 |     20.125903 |    628.312984 | Steven Traver                                                                                                                                                      |
| 214 |    652.817909 |    353.924912 | Ferran Sayol                                                                                                                                                       |
| 215 |    655.059926 |    283.975985 | Steven Traver                                                                                                                                                      |
| 216 |    163.317337 |    535.981871 | Chuanixn Yu                                                                                                                                                        |
| 217 |    787.734826 |    358.110077 | Matt Crook                                                                                                                                                         |
| 218 |    478.112649 |    511.931068 | Matt Crook                                                                                                                                                         |
| 219 |    275.366258 |    297.092849 | Scott Hartman                                                                                                                                                      |
| 220 |    518.733002 |    657.346162 | Anthony Caravaggi                                                                                                                                                  |
| 221 |    646.831017 |    328.691671 | Becky Barnes                                                                                                                                                       |
| 222 |    997.719094 |     41.424914 | Gareth Monger                                                                                                                                                      |
| 223 |    794.839179 |    608.327594 | Kamil S. Jaron                                                                                                                                                     |
| 224 |    890.548568 |    735.738634 | Nobu Tamura, vectorized by Zimices                                                                                                                                 |
| 225 |   1008.644389 |    561.217141 | Christoph Schomburg                                                                                                                                                |
| 226 |    591.064213 |     94.902867 | Scott Hartman                                                                                                                                                      |
| 227 |    536.268646 |    106.607678 | Abraão Leite                                                                                                                                                       |
| 228 |     33.265540 |    237.803076 | Tasman Dixon                                                                                                                                                       |
| 229 |    760.761987 |    782.158153 | Milton Tan                                                                                                                                                         |
| 230 |    177.567831 |    283.422901 | Noah Schlottman, photo by Antonio Guillén                                                                                                                          |
| 231 |    409.808446 |    151.259997 | NA                                                                                                                                                                 |
| 232 |    835.543322 |     48.923678 | Zimices                                                                                                                                                            |
| 233 |    237.098401 |    710.318233 | Jagged Fang Designs                                                                                                                                                |
| 234 |    154.978692 |    343.842812 | NA                                                                                                                                                                 |
| 235 |    452.980024 |    645.409732 | Lukas Panzarin                                                                                                                                                     |
| 236 |    100.341306 |    551.491354 | Christoph Schomburg                                                                                                                                                |
| 237 |    789.326997 |     40.590820 | Pete Buchholz                                                                                                                                                      |
| 238 |     11.932619 |    225.624298 | Noah Schlottman                                                                                                                                                    |
| 239 |    273.098550 |    423.799571 | Matt Crook                                                                                                                                                         |
| 240 |    208.738957 |    383.156872 | Ferran Sayol                                                                                                                                                       |
| 241 |    456.858747 |     96.769821 | Yan Wong                                                                                                                                                           |
| 242 |    240.843166 |    634.666792 | Matt Crook                                                                                                                                                         |
| 243 |    227.318400 |    143.235346 | kotik                                                                                                                                                              |
| 244 |    507.386703 |    148.999236 | Gabriela Palomo-Munoz                                                                                                                                              |
| 245 |    237.209631 |    224.121252 | SauropodomorphMonarch                                                                                                                                              |
| 246 |    156.899378 |    581.901111 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                      |
| 247 |   1008.658391 |    142.978102 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 248 |    608.644269 |    288.023647 | T. Michael Keesey                                                                                                                                                  |
| 249 |    360.834622 |    532.627165 | Andrew A. Farke                                                                                                                                                    |
| 250 |    484.702627 |      5.071203 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                               |
| 251 |    141.204266 |    547.632590 | Steven Traver                                                                                                                                                      |
| 252 |    656.733314 |     86.615903 | Cesar Julian                                                                                                                                                       |
| 253 |   1005.427599 |    417.569250 | Andrew A. Farke                                                                                                                                                    |
| 254 |    969.212626 |    734.787808 | Maija Karala                                                                                                                                                       |
| 255 |    171.744618 |    754.791371 | Caleb M. Brown                                                                                                                                                     |
| 256 |    530.866127 |    179.480040 | Ignacio Contreras                                                                                                                                                  |
| 257 |    216.056548 |    747.384840 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 258 |     17.546428 |    280.790442 | Gabriela Palomo-Munoz                                                                                                                                              |
| 259 |    611.968120 |    159.930141 | Margot Michaud                                                                                                                                                     |
| 260 |    115.429820 |    379.644257 | Matt Crook                                                                                                                                                         |
| 261 |    615.541995 |    650.682521 | Yan Wong                                                                                                                                                           |
| 262 |    738.175847 |     20.571886 | Tasman Dixon                                                                                                                                                       |
| 263 |    595.529378 |    206.560729 | Stuart Humphries                                                                                                                                                   |
| 264 |    626.242926 |      9.058012 | Markus A. Grohme                                                                                                                                                   |
| 265 |    298.393944 |    538.963060 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                             |
| 266 |    207.262614 |    266.618154 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                 |
| 267 |    565.342784 |    386.939155 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                              |
| 268 |    425.582519 |    253.080892 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 269 |    607.573968 |    174.808431 | Jaime Headden                                                                                                                                                      |
| 270 |    316.796543 |    334.895648 | C. Camilo Julián-Caballero                                                                                                                                         |
| 271 |    998.069364 |    452.223008 | FunkMonk                                                                                                                                                           |
| 272 |    582.245797 |     30.120624 | Gabriela Palomo-Munoz                                                                                                                                              |
| 273 |    706.596072 |    166.513388 | Emily Willoughby                                                                                                                                                   |
| 274 |    417.005786 |    372.076429 | Christoph Schomburg                                                                                                                                                |
| 275 |    764.535171 |    108.857911 | Emily Willoughby                                                                                                                                                   |
| 276 |    118.165701 |    682.354539 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 277 |     55.117822 |    457.775487 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 278 |    298.190437 |     19.843857 | Markus A. Grohme                                                                                                                                                   |
| 279 |    752.244368 |    276.355069 | Tyler McCraney                                                                                                                                                     |
| 280 |    423.598621 |    740.825313 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                  |
| 281 |    871.437636 |    723.730189 | Margot Michaud                                                                                                                                                     |
| 282 |    974.998704 |    782.457782 | Darius Nau                                                                                                                                                         |
| 283 |    958.059774 |    717.870857 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 284 |    216.823303 |    250.441679 | Matt Crook                                                                                                                                                         |
| 285 |   1012.705951 |    734.259967 | DW Bapst (modified from Bates et al., 2005)                                                                                                                        |
| 286 |    670.985014 |    577.634760 | Steven Coombs                                                                                                                                                      |
| 287 |    108.736403 |    146.604380 | NA                                                                                                                                                                 |
| 288 |    530.788142 |    447.830336 | Margot Michaud                                                                                                                                                     |
| 289 |    842.370531 |    616.957624 | Cristopher Silva                                                                                                                                                   |
| 290 |    562.457080 |    781.696924 | Rene Martin                                                                                                                                                        |
| 291 |    644.619323 |    246.831675 | L. Shyamal                                                                                                                                                         |
| 292 |    288.455740 |    789.913616 | Tasman Dixon                                                                                                                                                       |
| 293 |   1006.886727 |    173.562653 | NA                                                                                                                                                                 |
| 294 |    361.591076 |     23.028190 | Scott Hartman                                                                                                                                                      |
| 295 |    124.983168 |    242.135717 | Gabriela Palomo-Munoz                                                                                                                                              |
| 296 |    906.613143 |     94.048874 | Julio Garza                                                                                                                                                        |
| 297 |    504.288002 |    443.003758 | Scott Hartman                                                                                                                                                      |
| 298 |    650.295997 |    767.596789 | Arthur S. Brum                                                                                                                                                     |
| 299 |    446.252462 |    501.972861 | Felix Vaux                                                                                                                                                         |
| 300 |    682.384324 |    771.059450 | Ferran Sayol                                                                                                                                                       |
| 301 |    162.971545 |    259.215909 | Fernando Campos De Domenico                                                                                                                                        |
| 302 |    132.692237 |    317.536656 | Markus A. Grohme                                                                                                                                                   |
| 303 |     24.560858 |     33.408677 | Matt Crook                                                                                                                                                         |
| 304 |    759.791181 |    183.003228 | Jaime Headden                                                                                                                                                      |
| 305 |    837.845406 |    724.200820 | Margot Michaud                                                                                                                                                     |
| 306 |    436.077670 |    515.809730 | C. Camilo Julián-Caballero                                                                                                                                         |
| 307 |    485.747662 |    480.124745 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                     |
| 308 |    786.816499 |    666.976921 | Markus A. Grohme                                                                                                                                                   |
| 309 |   1009.244697 |    349.085321 | NA                                                                                                                                                                 |
| 310 |    109.546496 |    618.220591 | Matt Crook                                                                                                                                                         |
| 311 |    901.838472 |     76.659794 | Xavier Giroux-Bougard                                                                                                                                              |
| 312 |    731.598361 |    223.896389 | Zimices                                                                                                                                                            |
| 313 |    287.837823 |    251.513749 | Maxime Dahirel                                                                                                                                                     |
| 314 |    198.935613 |    227.965116 | Caleb M. Brown                                                                                                                                                     |
| 315 |    760.345837 |    374.062935 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                     |
| 316 |    942.272697 |    633.580318 | T. Michael Keesey (after Masteraah)                                                                                                                                |
| 317 |    833.308694 |    758.483694 | Margot Michaud                                                                                                                                                     |
| 318 |    775.491532 |     79.382526 | Margot Michaud                                                                                                                                                     |
| 319 |    994.954164 |    664.679358 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                      |
| 320 |    340.454382 |    196.109486 | Yan Wong                                                                                                                                                           |
| 321 |    337.402102 |    438.336687 | Yan Wong                                                                                                                                                           |
| 322 |    629.305096 |    280.485944 | Felix Vaux                                                                                                                                                         |
| 323 |    463.993566 |    659.969164 | David Tana                                                                                                                                                         |
| 324 |    674.490815 |    790.106674 | Fernando Campos De Domenico                                                                                                                                        |
| 325 |    811.570110 |    224.162259 | Nobu Tamura, vectorized by Zimices                                                                                                                                 |
| 326 |    587.338877 |    492.627210 | Zimices                                                                                                                                                            |
| 327 |    760.724454 |    639.536923 | Chris Jennings (vectorized by A. Verrière)                                                                                                                         |
| 328 |    778.305747 |    106.583952 | NA                                                                                                                                                                 |
| 329 |    731.725469 |    108.240450 | Joschua Knüppe                                                                                                                                                     |
| 330 |    358.683278 |     71.792118 | Conty (vectorized by T. Michael Keesey)                                                                                                                            |
| 331 |     33.390640 |    391.916356 | Christoph Schomburg                                                                                                                                                |
| 332 |    963.346073 |    393.658319 | Markus A. Grohme                                                                                                                                                   |
| 333 |    768.431849 |    254.413906 | Chris huh                                                                                                                                                          |
| 334 |    556.617271 |    634.919757 | Lani Mohan                                                                                                                                                         |
| 335 |     20.510126 |    426.568635 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                      |
| 336 |     26.157959 |    261.267169 | T. Michael Keesey                                                                                                                                                  |
| 337 |    699.764368 |    516.454018 | Zimices / Julián Bayona                                                                                                                                            |
| 338 |     31.301412 |     90.625540 | Zimices                                                                                                                                                            |
| 339 |    188.335828 |    728.778468 | Kimberly Haddrell                                                                                                                                                  |
| 340 |    919.368917 |    600.765844 | Andy Wilson                                                                                                                                                        |
| 341 |    596.482833 |    634.802873 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                    |
| 342 |    291.286731 |    393.322619 | Ferran Sayol                                                                                                                                                       |
| 343 |    303.695771 |    745.910924 | Jagged Fang Designs                                                                                                                                                |
| 344 |   1005.141715 |     76.688742 | Roderic Page and Lois Page                                                                                                                                         |
| 345 |   1000.513525 |    595.051791 | Chris huh                                                                                                                                                          |
| 346 |    612.474232 |    220.486995 | Margot Michaud                                                                                                                                                     |
| 347 |     35.241855 |    664.358096 | Tasman Dixon                                                                                                                                                       |
| 348 |    487.110251 |    722.538708 | Scott Hartman                                                                                                                                                      |
| 349 |    753.842126 |    358.696105 | Chris huh                                                                                                                                                          |
| 350 |     34.512451 |     78.754320 | Scott Hartman                                                                                                                                                      |
| 351 |    260.276601 |     71.837251 | Markus A. Grohme                                                                                                                                                   |
| 352 |      8.630691 |    724.874740 | Alexander Schmidt-Lebuhn                                                                                                                                           |
| 353 |    244.134469 |    787.749818 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                      |
| 354 |    491.946248 |    258.662649 | Juan Carlos Jerí                                                                                                                                                   |
| 355 |    786.209872 |    696.016250 | Gabriela Palomo-Munoz                                                                                                                                              |
| 356 |    532.252766 |    791.808482 | Scott Hartman                                                                                                                                                      |
| 357 |    368.841288 |    746.395601 | Scott Hartman                                                                                                                                                      |
| 358 |    388.279047 |    296.269632 | Emily Willoughby                                                                                                                                                   |
| 359 |    138.861100 |    465.878328 | Scott Hartman                                                                                                                                                      |
| 360 |    336.791657 |    450.923756 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 361 |    698.795904 |    426.442451 | U.S. National Park Service (vectorized by William Gearty)                                                                                                          |
| 362 |    326.924660 |    683.048413 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                       |
| 363 |    855.554602 |     40.013322 | Karla Martinez                                                                                                                                                     |
| 364 |   1004.638186 |    201.960730 | Birgit Lang                                                                                                                                                        |
| 365 |     34.868982 |    520.658660 | NA                                                                                                                                                                 |
| 366 |     26.204163 |    106.405481 | Christoph Schomburg                                                                                                                                                |
| 367 |     49.103697 |    741.135960 | Smokeybjb (modified by Mike Keesey)                                                                                                                                |
| 368 |    379.788553 |    394.048605 | Zimices                                                                                                                                                            |
| 369 |    449.332564 |     20.580281 | Matt Crook                                                                                                                                                         |
| 370 |    913.947439 |    530.820513 | Ieuan Jones                                                                                                                                                        |
| 371 |    648.536542 |     75.645625 | T. Michael Keesey                                                                                                                                                  |
| 372 |    205.928462 |    131.257977 | Steven Traver                                                                                                                                                      |
| 373 |    617.084301 |    350.395760 | Andy Wilson                                                                                                                                                        |
| 374 |    739.398674 |    623.859382 | C. Camilo Julián-Caballero                                                                                                                                         |
| 375 |    205.731794 |    278.282087 | Tasman Dixon                                                                                                                                                       |
| 376 |    594.474294 |    685.226944 | Gareth Monger                                                                                                                                                      |
| 377 |     28.235135 |    535.405034 | Christoph Schomburg                                                                                                                                                |
| 378 |    678.779502 |    479.691324 | Chris huh                                                                                                                                                          |
| 379 |    311.492832 |    318.861197 | Meliponicultor Itaymbere                                                                                                                                           |
| 380 |    329.515740 |     18.004384 | Michael P. Taylor                                                                                                                                                  |
| 381 |   1017.256391 |    288.875055 | T. Michael Keesey                                                                                                                                                  |
| 382 |     16.019314 |    449.830133 | Gabriela Palomo-Munoz                                                                                                                                              |
| 383 |    993.623041 |     10.871027 | Zimices                                                                                                                                                            |
| 384 |    576.583369 |    426.978835 | Scott Reid                                                                                                                                                         |
| 385 |    297.408935 |    431.869287 | NA                                                                                                                                                                 |
| 386 |   1002.975130 |    100.192833 | Chris huh                                                                                                                                                          |
| 387 |    303.492340 |    288.820051 | Scott Hartman                                                                                                                                                      |
| 388 |    376.134326 |    371.366983 | Maxime Dahirel                                                                                                                                                     |
| 389 |    823.886431 |    657.749652 | Andy Wilson                                                                                                                                                        |
| 390 |    259.062051 |    419.402052 | Matt Crook                                                                                                                                                         |
| 391 |    578.561508 |     47.006628 | Alexander Schmidt-Lebuhn                                                                                                                                           |
| 392 |    606.072965 |    189.018964 | Scott Hartman                                                                                                                                                      |
| 393 |    226.771620 |    696.552786 | Cesar Julian                                                                                                                                                       |
| 394 |     92.015324 |    233.928593 | Anthony Caravaggi                                                                                                                                                  |
| 395 |    770.503742 |     21.998858 | Chris huh                                                                                                                                                          |
| 396 |    949.911699 |    794.068552 | Tracy A. Heath                                                                                                                                                     |
| 397 |    686.627641 |     39.728488 | Beth Reinke                                                                                                                                                        |
| 398 |    511.222553 |    548.679266 | Zimices                                                                                                                                                            |
| 399 |    883.724937 |     59.217239 | Christine Axon                                                                                                                                                     |
| 400 |    983.273946 |    151.379053 | Ferran Sayol                                                                                                                                                       |
| 401 |    998.175268 |    648.618235 | Tauana J. Cunha                                                                                                                                                    |
| 402 |    599.192874 |    740.905079 | Chris huh                                                                                                                                                          |
| 403 |    236.432186 |    766.481254 | Collin Gross                                                                                                                                                       |
| 404 |     53.998167 |    496.282051 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                      |
| 405 |    740.930463 |    472.255482 | Markus A. Grohme                                                                                                                                                   |
| 406 |    105.859885 |    734.878691 | Margot Michaud                                                                                                                                                     |
| 407 |    366.393610 |    668.900161 | Gopal Murali                                                                                                                                                       |
| 408 |   1012.507204 |    385.360702 | NA                                                                                                                                                                 |
| 409 |    108.410550 |    595.115566 | Jagged Fang Designs                                                                                                                                                |
| 410 |    690.154946 |    185.055077 | C. Camilo Julián-Caballero                                                                                                                                         |
| 411 |     64.908119 |    788.798823 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                  |
| 412 |    555.286846 |    673.204563 | Jagged Fang Designs                                                                                                                                                |
| 413 |    241.593413 |     61.708635 | Michele M Tobias                                                                                                                                                   |
| 414 |    552.453414 |     96.867870 | Dean Schnabel                                                                                                                                                      |
| 415 |    291.658776 |    206.311329 | Smokeybjb                                                                                                                                                          |
| 416 |    525.856172 |    776.768742 | NA                                                                                                                                                                 |
| 417 |    926.840395 |    437.960742 | Arthur S. Brum                                                                                                                                                     |
| 418 |    754.336467 |    288.877977 | terngirl                                                                                                                                                           |
| 419 |    949.066969 |    200.139913 | Jagged Fang Designs                                                                                                                                                |
| 420 |    868.236660 |    267.334585 | Scott Hartman                                                                                                                                                      |
| 421 |    932.381850 |    719.809895 | Zimices                                                                                                                                                            |
| 422 |    424.663492 |    267.189273 | Sergio A. Muñoz-Gómez                                                                                                                                              |
| 423 |    226.476616 |    624.099286 | Dean Schnabel                                                                                                                                                      |
| 424 |    258.130505 |    215.066768 | Steven Coombs                                                                                                                                                      |
| 425 |    625.134948 |    231.956067 | Jagged Fang Designs                                                                                                                                                |
| 426 |    795.320958 |    467.150869 | Zimices                                                                                                                                                            |
| 427 |    725.849482 |    290.986853 | Margot Michaud                                                                                                                                                     |
| 428 |    707.906190 |    592.230597 | Scott Hartman                                                                                                                                                      |
| 429 |    843.077342 |    645.519828 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                 |
| 430 |    252.483137 |    439.199748 | Mariana Ruiz Villarreal (modified by T. Michael Keesey)                                                                                                            |
| 431 |    177.120000 |    737.990221 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 432 |    510.336938 |    460.903450 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                        |
| 433 |    419.547715 |    198.134900 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                      |
| 434 |    160.720836 |    178.809358 | Ludwik Gąsiorowski                                                                                                                                                 |
| 435 |    410.876195 |    652.378647 | T. Michael Keesey                                                                                                                                                  |
| 436 |    460.291037 |     60.799891 | Ferran Sayol                                                                                                                                                       |
| 437 |    832.294866 |    417.852704 | Zimices                                                                                                                                                            |
| 438 |    551.061639 |    454.892339 | C. Camilo Julián-Caballero                                                                                                                                         |
| 439 |    989.255176 |    428.287811 | Markus A. Grohme                                                                                                                                                   |
| 440 |    218.746086 |    568.074179 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                                     |
| 441 |    335.791467 |    466.567065 | Roberto Diaz Sibaja, based on Domser                                                                                                                               |
| 442 |    155.311755 |    380.516170 | Jagged Fang Designs                                                                                                                                                |
| 443 |    876.058641 |     77.500949 | Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey       |
| 444 |    219.177545 |    162.061930 | John Conway                                                                                                                                                        |
| 445 |    323.844017 |    791.848861 | Gareth Monger                                                                                                                                                      |
| 446 |    348.481885 |    405.835433 | Markus A. Grohme                                                                                                                                                   |
| 447 |    213.178046 |    176.578006 | Margot Michaud                                                                                                                                                     |
| 448 |    131.147927 |    441.165589 | Scott Hartman                                                                                                                                                      |
| 449 |    546.175707 |     20.657186 | Matt Crook                                                                                                                                                         |
| 450 |     97.489013 |     29.070698 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                       |
| 451 |    465.052411 |    253.706476 | Michelle Site                                                                                                                                                      |
| 452 |    425.649215 |    353.357986 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                   |
| 453 |    277.496481 |    622.548764 | Zimices                                                                                                                                                            |
| 454 |    795.390459 |    395.474276 | Chris huh                                                                                                                                                          |
| 455 |    794.841007 |    792.098167 | Jonathan Wells                                                                                                                                                     |
| 456 |    395.571031 |    507.865140 | Chris A. Hamilton                                                                                                                                                  |
| 457 |    328.224421 |    568.932530 | Michael Scroggie                                                                                                                                                   |
| 458 |    268.047565 |    632.315573 | Markus A. Grohme                                                                                                                                                   |
| 459 |   1016.295264 |    321.233696 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                    |
| 460 |    440.371805 |    535.707052 | NA                                                                                                                                                                 |
| 461 |   1018.045008 |    511.806295 | Gareth Monger                                                                                                                                                      |
| 462 |    402.377025 |    316.553000 | Collin Gross                                                                                                                                                       |
| 463 |    495.989981 |    744.943506 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 464 |     22.025443 |    350.309392 | Chuanixn Yu                                                                                                                                                        |
| 465 |    301.931920 |    673.905056 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                  |
| 466 |    205.969281 |    752.336753 | Armin Reindl                                                                                                                                                       |
| 467 |    572.969766 |    641.375064 | Markus A. Grohme                                                                                                                                                   |
| 468 |    814.655250 |     22.654179 | T. Michael Keesey                                                                                                                                                  |
| 469 |   1000.660924 |    788.824031 | Margot Michaud                                                                                                                                                     |
| 470 |    232.511902 |    482.952266 | Markus A. Grohme                                                                                                                                                   |
| 471 |     10.897684 |    770.058672 | Gareth Monger                                                                                                                                                      |
| 472 |    830.957670 |    568.481951 | Gareth Monger                                                                                                                                                      |
| 473 |    257.292651 |    407.770319 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 474 |    814.694612 |    546.587913 | Jagged Fang Designs                                                                                                                                                |
| 475 |    395.608480 |    108.060860 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                       |
| 476 |     16.777790 |     13.054112 | T. Michael Keesey                                                                                                                                                  |
| 477 |    934.821445 |    153.898270 | Gareth Monger                                                                                                                                                      |
| 478 |    649.547075 |    590.219712 | Ingo Braasch                                                                                                                                                       |
| 479 |    376.788881 |    419.123797 | Margot Michaud                                                                                                                                                     |
| 480 |    404.474858 |    790.069295 | Zimices                                                                                                                                                            |
| 481 |    514.081357 |    618.811326 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 482 |     17.740382 |    462.987355 | Roberto Díaz Sibaja                                                                                                                                                |
| 483 |    574.541063 |    526.537462 | John Conway                                                                                                                                                        |
| 484 |    139.033965 |    453.782727 | Roberto Díaz Sibaja                                                                                                                                                |
| 485 |    732.354139 |      4.907162 | Scott Hartman                                                                                                                                                      |
| 486 |    687.120901 |    464.788699 | Rebecca Groom                                                                                                                                                      |
| 487 |    465.785436 |    537.482536 | FunkMonk                                                                                                                                                           |
| 488 |    116.190556 |    532.292653 | Margot Michaud                                                                                                                                                     |
| 489 |     42.270788 |      6.637370 | Gareth Monger                                                                                                                                                      |
| 490 |    272.024054 |    471.648414 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                           |
| 491 |    697.946652 |     46.595284 | Chris huh                                                                                                                                                          |
| 492 |    261.650109 |    777.886298 | Ferran Sayol                                                                                                                                                       |
| 493 |    676.746682 |    313.817243 | Matt Crook                                                                                                                                                         |
| 494 |    266.027768 |     12.779512 | Andy Wilson                                                                                                                                                        |
| 495 |    823.218414 |    453.304149 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                  |
| 496 |    696.091302 |    743.992022 | Jaime Headden, modified by T. Michael Keesey                                                                                                                       |
| 497 |    667.690484 |    556.796295 | Ferran Sayol                                                                                                                                                       |
| 498 |    807.159826 |    739.732254 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                |
| 499 |    232.628303 |    472.826688 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 500 |   1018.833231 |    653.838285 | Gareth Monger                                                                                                                                                      |
| 501 |    563.999043 |    225.038840 | Matt Crook                                                                                                                                                         |
| 502 |    705.101103 |    698.019689 | Dean Schnabel                                                                                                                                                      |
| 503 |    236.241448 |    266.634006 | Jagged Fang Designs                                                                                                                                                |
| 504 |   1008.034546 |     64.522697 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                         |
| 505 |    356.849671 |    515.799252 | Tambja (vectorized by T. Michael Keesey)                                                                                                                           |
| 506 |     13.571581 |    373.386846 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                             |
| 507 |     51.984298 |    709.189888 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                                |
| 508 |    202.749958 |    765.391833 | T. Michael Keesey                                                                                                                                                  |
| 509 |    142.649733 |    591.830997 | Jagged Fang Designs                                                                                                                                                |
| 510 |    271.822869 |    141.611972 | Sergio A. Muñoz-Gómez                                                                                                                                              |
| 511 |    480.329299 |    355.835880 | Collin Gross                                                                                                                                                       |
| 512 |     11.476264 |    647.217128 | Margot Michaud                                                                                                                                                     |
| 513 |     65.541051 |    121.491058 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 514 |    978.653975 |    562.729057 | Chase Brownstein                                                                                                                                                   |
| 515 |    470.003807 |    179.553015 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                     |
| 516 |    608.559637 |    427.788147 | Markus A. Grohme                                                                                                                                                   |
| 517 |    702.239003 |    147.399392 | Dmitry Bogdanov                                                                                                                                                    |
| 518 |    840.510423 |    536.666532 | Dean Schnabel                                                                                                                                                      |
| 519 |    562.965447 |    741.518954 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                       |
| 520 |     95.724940 |    424.684908 | Chris huh                                                                                                                                                          |
| 521 |    803.515880 |    287.776969 | Smokeybjb                                                                                                                                                          |

    #> Your tweet has been posted!
