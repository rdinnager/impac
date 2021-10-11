
<!-- README.md is generated from README.Rmd. Please edit that file -->

# immosaic

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/rdinnager/immosaic/workflows/R-CMD-check/badge.svg)](https://github.com/rdinnager/immosaic/actions)
<!-- badges: end -->

The goal of `{immosaic}` is to create packed image mosaics. The main
function `immosaic`, takes a set of images, or a function that generates
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
devtools::install_github("rdinnager/immosaic")
```

## Example

This document and hence the images below are regenerated once a day
automatically. No two will ever be alike.

First we load the packages we need for these examples:

``` r
library(immosaic)
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

Now we feed our function to the `immosaic()` function, which packs the
generated images onto a canvas:

``` r
shapes <- immosaic(generate_platonic, progress = FALSE, show_every = 0, bg = "white")
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

Now we run `immosaic` on our phylopic generating function:

``` r
phylopics <- immosaic(get_phylopic, progress = FALSE, show_every = 0, bg = "white", min_scale = 0.01)
imager::save.image(phylopics$image, "man/figures/phylopic_a_pack.png")
```

![Packed images of organism silhouettes from
Phylopic](man/figures/phylopic_a_pack.png)

Now we extract the artists who made the above images using the uid of
image.

``` r
image_dat <- lapply(phylopics$meta$uuid, 
                    function(x) {Sys.sleep(0.5); rphylopic::image_get(x, options = c("credit"))$credit})
```

## Artists whose work is showcased:

Margot Michaud, Steven Traver, Christoph Schomburg, Alexandre Vong, Yan
Wong from drawing by T. F. Zimmermann, Gabriel Lio, vectorized by
Zimices, Tracy A. Heath, Martin R. Smith, Owen Jones (derived from a
CC-BY 2.0 photograph by Paulo B. Chaves), Michele M Tobias, T. Michael
Keesey, Dmitry Bogdanov (vectorized by T. Michael Keesey), Birgit Lang,
Gabriela Palomo-Munoz, Martin Kevil, Scott Reid, Dmitry Bogdanov,
vectorized by Zimices, C. Camilo Julián-Caballero, Matthew E. Clapham,
Gareth Monger, Mo Hassan, FunkMonk, Kai R. Caspar, Ghedoghedo
(vectorized by T. Michael Keesey), Joanna Wolfe, Konsta Happonen, from a
CC-BY-NC image by pelhonen on iNaturalist, Matt Crook, Zimices, Scott
Hartman, Rachel Shoop, M Hutchinson, Mathew Wedel, Diego Fontaneto,
Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone,
Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael
Keesey), Chris huh, Arthur S. Brum, Smokeybjb, Tasman Dixon, Alex
Slavenko, T. Michael Keesey (after Walker & al.), Alexander
Schmidt-Lebuhn, Eric Moody, Frank Förster, Taenadoman, T. Michael Keesey
(from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel
Vences), Iain Reid, Steven Coombs (vectorized by T. Michael Keesey),
Obsidian Soul (vectorized by T. Michael Keesey), Nobu Tamura (vectorized
by T. Michael Keesey), Steven Coombs, Óscar San-Isidro (vectorized by T.
Michael Keesey), Yan Wong, B. Duygu Özpolat, Sergio A. Muñoz-Gómez,
Matthew Hooge (vectorized by T. Michael Keesey), Matt Dempsey,
Falconaumanni and T. Michael Keesey, S.Martini, Didier Descouens
(vectorized by T. Michael Keesey), Frank Förster (based on a picture by
Hans Hillewaert), Katie S. Collins, Apokryltaros (vectorized by T.
Michael Keesey), Kamil S. Jaron, Collin Gross, Jaime Headden, Craig
Dylke, Isaure Scavezzoni, Dmitry Bogdanov, Andrew A. Farke, Zachary
Quigley, CNZdenek, \[unknown\], Jagged Fang Designs, Nobu Tamura,
modified by Andrew A. Farke, Jan A. Venter, Herbert H. T. Prins, David
A. Balfour & Rob Slotow (vectorized by T. Michael Keesey), FJDegrange,
T. Michael Keesey (photo by Bc999 \[Black crow\]), Xavier
Giroux-Bougard, Chloé Schmidt, Martin R. Smith, from photo by Jürgen
Schoner, George Edward Lodge (modified by T. Michael Keesey), Trond R.
Oskars, Sarah Werning, Sidney Frederic Harmer, Arthur Everett Shipley
(vectorized by Maxime Dahirel), New York Zoological Society, Ferran
Sayol, Mali’o Kodis, image from Brockhaus and Efron Encyclopedic
Dictionary, Juan Carlos Jerí, Luc Viatour (source photo) and Andreas
Plank, Allison Pease, Maija Karala, Anilocra (vectorization by Yan
Wong), Manabu Bessho-Uehara, Dori <dori@merr.info> (source photo) and
Nevit Dilmen, terngirl, Nobu Tamura, vectorized by Zimices, Conty
(vectorized by T. Michael Keesey), Mattia Menchetti, Roberto Díaz
Sibaja, Cesar Julian, Lukas Panzarin, Scott Hartman, modified by T.
Michael Keesey, Christine Axon, Maxwell Lefroy (vectorized by T. Michael
Keesey), Gordon E. Robertson, Stephen O’Connor (vectorized by T. Michael
Keesey), Caleb M. Brown, Felix Vaux, L. Shyamal, M Kolmann, Becky
Barnes, E. Lear, 1819 (vectorization by Yan Wong), David Orr, Vijay
Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Kenneth Lacovara (vectorized by T. Michael Keesey), Beth
Reinke, Baheerathan Murugavel, xgirouxb, Crystal Maier, Campbell
Fleming, Nobu Tamura, Jakovche, Dinah Challen, Sharon Wegner-Larsen,
Jimmy Bernot, Pranav Iyer (grey ideas), Chase Brownstein, Lukasiniho,
Melissa Broussard, Jonathan Wells, Caio Bernardes, vectorized by
Zimices, Tony Ayling (vectorized by T. Michael Keesey), Meliponicultor
Itaymbere, Michael P. Taylor, Jose Carlos Arenas-Monroy, Jessica Anne
Miller, T. Michael Keesey (after Ponomarenko), Neil Kelley, Emily Jane
McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Steven Haddock • Jellywatch.org, Martin R. Smith, after Skovsted et al
2015, Nick Schooler, John Curtis (vectorized by T. Michael Keesey),
Geoff Shaw, Nobu Tamura (vectorized by A. Verrière), Francesco
“Architetto” Rollandin, Joe Schneid (vectorized by T. Michael Keesey),
Noah Schlottman, photo by Casey Dunn, Jack Mayer Wood, Dean Schnabel,
U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley
(silhouette), Rene Martin, Mariana Ruiz Villarreal (modified by T.
Michael Keesey), (unknown), Jay Matternes (vectorized by T. Michael
Keesey), B Kimmel, Tim Bertelink (modified by T. Michael Keesey),
Rebecca Groom, Steven Blackwood, Ricardo N. Martinez & Oscar A. Alcober,
Bennet McComish, photo by Avenue, Emily Willoughby, Julia B McHugh,
Blanco et al., 2014, vectorized by Zimices, Mykle Hoban, Bennet
McComish, photo by Hans Hillewaert, Julio Garza, Johan Lindgren, Michael
W. Caldwell, Takuya Konishi, Luis M. Chiappe, Carlos Cano-Barbacil, Noah
Schlottman, photo by Carol Cummings, Ghedoghedo, vectorized by Zimices,
Javier Luque, Félix Landry Yuan, Maxime Dahirel, E. J. Van Nieukerken,
A. Laštuvka, and Z. Laštuvka (vectorized by T. Michael Keesey), Scott D.
Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A.
Forster, Joshua A. Smith, Alan L. Titus, Robert Gay, modified from
FunkMonk (Michael B.H.) and T. Michael Keesey., , Martien Brand
(original photo), Renato Santos (vector silhouette), NASA, Kimberly
Haddrell, Ian Burt (original) and T. Michael Keesey (vectorization),
Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Michelle Site, Christopher Watson (photo) and T. Michael
Keesey (vectorization), Jay Matternes, vectorized by Zimices, Michael
Scroggie, Michael B. H. (vectorized by T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    690.256089 |    705.716856 | NA                                                                                                                                                                    |
|   2 |    509.689587 |    738.824298 | Margot Michaud                                                                                                                                                        |
|   3 |    558.933053 |    186.328287 | Steven Traver                                                                                                                                                         |
|   4 |    177.388033 |    670.768768 | Christoph Schomburg                                                                                                                                                   |
|   5 |    741.251535 |    556.452438 | Alexandre Vong                                                                                                                                                        |
|   6 |    561.648225 |    336.842742 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                             |
|   7 |    413.293725 |    623.323862 | Gabriel Lio, vectorized by Zimices                                                                                                                                    |
|   8 |    266.800723 |    172.500069 | Tracy A. Heath                                                                                                                                                        |
|   9 |    890.291736 |    231.287873 | Martin R. Smith                                                                                                                                                       |
|  10 |    780.459145 |    277.695571 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                                   |
|  11 |    684.149690 |    226.602669 | Michele M Tobias                                                                                                                                                      |
|  12 |    285.657122 |    379.479017 | T. Michael Keesey                                                                                                                                                     |
|  13 |    878.007935 |    695.184955 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  14 |    933.606153 |    555.305580 | Birgit Lang                                                                                                                                                           |
|  15 |    574.429966 |    528.375616 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  16 |    815.490361 |    764.999132 | Martin Kevil                                                                                                                                                          |
|  17 |    417.745113 |    383.001856 | Scott Reid                                                                                                                                                            |
|  18 |     76.283092 |    305.531834 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                                |
|  19 |    183.084277 |    548.989003 | C. Camilo Julián-Caballero                                                                                                                                            |
|  20 |    196.765910 |    389.124529 | Matthew E. Clapham                                                                                                                                                    |
|  21 |     52.479376 |    653.155377 | Gareth Monger                                                                                                                                                         |
|  22 |    788.442433 |    395.192831 | Mo Hassan                                                                                                                                                             |
|  23 |    395.240887 |    333.793519 | FunkMonk                                                                                                                                                              |
|  24 |    343.988912 |    506.710142 | Kai R. Caspar                                                                                                                                                         |
|  25 |    843.235927 |    476.065251 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
|  26 |    591.702291 |    410.268570 | Joanna Wolfe                                                                                                                                                          |
|  27 |    257.620799 |     70.144222 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                                     |
|  28 |    790.457377 |    185.598958 | Matt Crook                                                                                                                                                            |
|  29 |    584.847393 |     87.481577 | Margot Michaud                                                                                                                                                        |
|  30 |    902.319159 |     35.929583 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  31 |    305.708345 |    737.651022 | Zimices                                                                                                                                                               |
|  32 |    471.656062 |    438.681271 | Kai R. Caspar                                                                                                                                                         |
|  33 |    942.496780 |    451.093989 | Scott Hartman                                                                                                                                                         |
|  34 |    839.791001 |    541.735892 | Rachel Shoop                                                                                                                                                          |
|  35 |    488.248524 |     48.903691 | M Hutchinson                                                                                                                                                          |
|  36 |    606.389215 |    648.125372 | Mathew Wedel                                                                                                                                                          |
|  37 |    259.107857 |    333.401135 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
|  38 |    370.246720 |     31.868983 | Scott Hartman                                                                                                                                                         |
|  39 |     79.694577 |    457.970339 | Margot Michaud                                                                                                                                                        |
|  40 |    909.194491 |    362.923242 | Chris huh                                                                                                                                                             |
|  41 |    612.720336 |    473.338379 | Arthur S. Brum                                                                                                                                                        |
|  42 |    309.314886 |    672.857106 | Smokeybjb                                                                                                                                                             |
|  43 |    769.354496 |     66.591811 | Tasman Dixon                                                                                                                                                          |
|  44 |    458.450193 |    296.074140 | Zimices                                                                                                                                                               |
|  45 |     69.997600 |    563.471751 | Zimices                                                                                                                                                               |
|  46 |     74.831888 |    370.421456 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  47 |     91.791327 |    769.698360 | Alex Slavenko                                                                                                                                                         |
|  48 |    999.384000 |    157.422489 | T. Michael Keesey (after Walker & al.)                                                                                                                                |
|  49 |     16.871805 |     97.996112 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|  50 |    923.628590 |     84.935865 | Eric Moody                                                                                                                                                            |
|  51 |    709.597301 |    485.416148 | Chris huh                                                                                                                                                             |
|  52 |    211.763142 |    490.624540 | Frank Förster                                                                                                                                                         |
|  53 |    944.292841 |    644.239241 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  54 |    449.994725 |    233.014101 | Tasman Dixon                                                                                                                                                          |
|  55 |    751.804929 |    449.852645 | Taenadoman                                                                                                                                                            |
|  56 |    602.411090 |      9.158189 | Zimices                                                                                                                                                               |
|  57 |    310.347387 |    459.119824 | NA                                                                                                                                                                    |
|  58 |    397.268550 |     73.510366 | Chris huh                                                                                                                                                             |
|  59 |    389.887073 |    758.839162 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                                     |
|  60 |    699.919597 |    647.890207 | Iain Reid                                                                                                                                                             |
|  61 |    574.551311 |    593.166508 | Steven Traver                                                                                                                                                         |
|  62 |    955.188088 |    764.909535 | Margot Michaud                                                                                                                                                        |
|  63 |     70.021490 |     18.681173 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                                       |
|  64 |    777.802151 |    137.996549 | T. Michael Keesey                                                                                                                                                     |
|  65 |    949.178867 |    365.515792 | Matt Crook                                                                                                                                                            |
|  66 |    641.391319 |    674.240325 | Iain Reid                                                                                                                                                             |
|  67 |    211.905898 |     41.331403 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
|  68 |     36.037165 |    726.826666 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  69 |    802.408788 |     23.586622 | Steven Coombs                                                                                                                                                         |
|  70 |    846.386685 |    103.331267 | Óscar San-Isidro (vectorized by T. Michael Keesey)                                                                                                                    |
|  71 |    974.802531 |    237.386337 | Yan Wong                                                                                                                                                              |
|  72 |    304.356198 |    104.011220 | B. Duygu Özpolat                                                                                                                                                      |
|  73 |    635.111922 |    615.945015 | Chris huh                                                                                                                                                             |
|  74 |    217.228795 |    456.438373 | Chris huh                                                                                                                                                             |
|  75 |    161.388539 |    328.109271 | Scott Hartman                                                                                                                                                         |
|  76 |    214.060192 |    273.667828 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
|  77 |    429.913172 |    489.280250 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                                       |
|  78 |     50.743687 |    260.551620 | Matt Dempsey                                                                                                                                                          |
|  79 |    981.065761 |    420.897665 | Scott Hartman                                                                                                                                                         |
|  80 |    281.144837 |    602.848250 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  81 |    629.490053 |    166.683523 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
|  82 |    773.099881 |    516.557331 | Scott Hartman                                                                                                                                                         |
|  83 |     38.320706 |    175.844153 | S.Martini                                                                                                                                                             |
|  84 |     89.587679 |    689.503358 | Birgit Lang                                                                                                                                                           |
|  85 |    706.341624 |    572.703854 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  86 |    287.922481 |    624.403627 | Iain Reid                                                                                                                                                             |
|  87 |    939.577809 |    408.182897 | Scott Hartman                                                                                                                                                         |
|  88 |    276.577159 |    550.831865 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
|  89 |     64.224245 |    119.107573 | NA                                                                                                                                                                    |
|  90 |     39.546357 |    225.084329 | Frank Förster (based on a picture by Hans Hillewaert)                                                                                                                 |
|  91 |    878.359755 |    157.135586 | Katie S. Collins                                                                                                                                                      |
|  92 |      8.634285 |    636.216106 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
|  93 |    785.257120 |    226.794287 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
|  94 |    768.283719 |    596.313141 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
|  95 |    345.683785 |    400.445946 | Kamil S. Jaron                                                                                                                                                        |
|  96 |     68.692543 |    517.747537 | Collin Gross                                                                                                                                                          |
|  97 |    293.878992 |    150.832108 | Jaime Headden                                                                                                                                                         |
|  98 |    631.635407 |    317.735635 | Scott Reid                                                                                                                                                            |
|  99 |    991.088234 |    481.389007 | NA                                                                                                                                                                    |
| 100 |    778.404711 |    793.269095 | Craig Dylke                                                                                                                                                           |
| 101 |    955.085454 |    308.812728 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 102 |    758.244167 |    172.472788 | Scott Hartman                                                                                                                                                         |
| 103 |    990.411751 |     17.952271 | Isaure Scavezzoni                                                                                                                                                     |
| 104 |    182.970840 |    782.387574 | Margot Michaud                                                                                                                                                        |
| 105 |    910.209971 |    120.243640 | Christoph Schomburg                                                                                                                                                   |
| 106 |    531.163795 |    659.425975 | Dmitry Bogdanov                                                                                                                                                       |
| 107 |    844.672987 |    598.843946 | Matt Crook                                                                                                                                                            |
| 108 |     26.294349 |    513.260793 | Andrew A. Farke                                                                                                                                                       |
| 109 |    971.982475 |    132.757568 | Zachary Quigley                                                                                                                                                       |
| 110 |    681.442958 |      6.188491 | Steven Coombs                                                                                                                                                         |
| 111 |    201.610002 |    521.601846 | Steven Coombs                                                                                                                                                         |
| 112 |    482.073240 |    401.499760 | CNZdenek                                                                                                                                                              |
| 113 |     76.030974 |     55.647898 | Andrew A. Farke                                                                                                                                                       |
| 114 |    488.097210 |     92.148738 | \[unknown\]                                                                                                                                                           |
| 115 |    524.790897 |    292.541255 | Steven Traver                                                                                                                                                         |
| 116 |    546.500842 |    251.355352 | Margot Michaud                                                                                                                                                        |
| 117 |   1009.477541 |    574.362096 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 118 |    571.167009 |    359.713819 | Scott Hartman                                                                                                                                                         |
| 119 |   1011.527837 |     63.325952 | NA                                                                                                                                                                    |
| 120 |    107.056428 |    635.617007 | Jagged Fang Designs                                                                                                                                                   |
| 121 |    646.650217 |    598.636630 | Dmitry Bogdanov                                                                                                                                                       |
| 122 |    657.186450 |    629.402294 | T. Michael Keesey                                                                                                                                                     |
| 123 |     19.633639 |    764.024357 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                              |
| 124 |    464.131539 |    519.736748 | Jagged Fang Designs                                                                                                                                                   |
| 125 |    417.347058 |    732.877486 | B. Duygu Özpolat                                                                                                                                                      |
| 126 |     86.448957 |    187.451268 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 127 |    274.600150 |    259.640659 | FJDegrange                                                                                                                                                            |
| 128 |     23.283572 |    420.417365 | T. Michael Keesey (photo by Bc999 \[Black crow\])                                                                                                                     |
| 129 |    642.236594 |     51.369393 | Xavier Giroux-Bougard                                                                                                                                                 |
| 130 |    995.850081 |    513.821694 | Chloé Schmidt                                                                                                                                                         |
| 131 |    874.318408 |    343.678257 | Chris huh                                                                                                                                                             |
| 132 |    392.127003 |    426.775508 | Christoph Schomburg                                                                                                                                                   |
| 133 |    334.238469 |    358.045234 | Martin R. Smith, from photo by Jürgen Schoner                                                                                                                         |
| 134 |    522.333878 |    610.808999 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                                   |
| 135 |    398.596293 |     97.878065 | NA                                                                                                                                                                    |
| 136 |    176.818556 |    247.046564 | Margot Michaud                                                                                                                                                        |
| 137 |    999.081960 |    312.029469 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 138 |    780.461335 |    732.569051 | Margot Michaud                                                                                                                                                        |
| 139 |    865.027546 |    622.985222 | Trond R. Oskars                                                                                                                                                       |
| 140 |    970.944553 |     44.760351 | Margot Michaud                                                                                                                                                        |
| 141 |    708.819062 |    389.970896 | T. Michael Keesey                                                                                                                                                     |
| 142 |    139.075031 |    503.029907 | Sarah Werning                                                                                                                                                         |
| 143 |    291.358525 |     30.706520 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                         |
| 144 |    869.009151 |    442.525690 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 145 |    247.088545 |    247.392523 | Zimices                                                                                                                                                               |
| 146 |     45.875656 |    623.607737 | Jagged Fang Designs                                                                                                                                                   |
| 147 |    370.635901 |    433.928991 | Matt Crook                                                                                                                                                            |
| 148 |   1007.164125 |    683.548627 | Tasman Dixon                                                                                                                                                          |
| 149 |     29.612873 |    321.741300 | Gareth Monger                                                                                                                                                         |
| 150 |     52.845337 |    499.764601 | New York Zoological Society                                                                                                                                           |
| 151 |    479.374036 |    344.661679 | Matt Crook                                                                                                                                                            |
| 152 |    865.938689 |    405.826518 | T. Michael Keesey                                                                                                                                                     |
| 153 |    131.011103 |    663.898910 | Ferran Sayol                                                                                                                                                          |
| 154 |    512.198425 |    688.410185 | Matt Dempsey                                                                                                                                                          |
| 155 |     56.000828 |    608.485039 | Ferran Sayol                                                                                                                                                          |
| 156 |    877.071602 |    535.236116 | NA                                                                                                                                                                    |
| 157 |     42.544378 |     99.870959 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                                  |
| 158 |    963.873432 |    495.092295 | Gareth Monger                                                                                                                                                         |
| 159 |    487.963258 |    125.868318 | Chris huh                                                                                                                                                             |
| 160 |    309.503041 |    698.675638 | Juan Carlos Jerí                                                                                                                                                      |
| 161 |    201.886174 |     18.957358 | Luc Viatour (source photo) and Andreas Plank                                                                                                                          |
| 162 |    534.885112 |    629.733181 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 163 |    737.586295 |    255.453864 | C. Camilo Julián-Caballero                                                                                                                                            |
| 164 |    269.200760 |    650.807436 | Allison Pease                                                                                                                                                         |
| 165 |    923.926522 |    792.599731 | Maija Karala                                                                                                                                                          |
| 166 |    410.921215 |    439.315629 | Ferran Sayol                                                                                                                                                          |
| 167 |    550.526624 |    770.694842 | Steven Traver                                                                                                                                                         |
| 168 |    717.085349 |     20.429266 | NA                                                                                                                                                                    |
| 169 |    725.464256 |    612.358057 | Zimices                                                                                                                                                               |
| 170 |    781.187571 |    107.212614 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 171 |    162.708289 |    519.978466 | Zimices                                                                                                                                                               |
| 172 |    777.186271 |    271.476932 | Anilocra (vectorization by Yan Wong)                                                                                                                                  |
| 173 |    998.971368 |      5.760269 | Scott Hartman                                                                                                                                                         |
| 174 |     37.571225 |    216.230337 | FunkMonk                                                                                                                                                              |
| 175 |    162.158109 |    464.181281 | Andrew A. Farke                                                                                                                                                       |
| 176 |    334.162090 |    550.061416 | Matt Crook                                                                                                                                                            |
| 177 |    284.503391 |     59.928325 | Ferran Sayol                                                                                                                                                          |
| 178 |    769.589112 |    706.358649 | Jagged Fang Designs                                                                                                                                                   |
| 179 |     72.010726 |    640.608685 | Tasman Dixon                                                                                                                                                          |
| 180 |    120.010603 |    556.833934 | Scott Hartman                                                                                                                                                         |
| 181 |    990.184028 |    677.118856 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 182 |    385.370436 |     39.508032 | Manabu Bessho-Uehara                                                                                                                                                  |
| 183 |    198.782926 |    264.428285 | T. Michael Keesey                                                                                                                                                     |
| 184 |    363.335740 |    725.496961 | Ferran Sayol                                                                                                                                                          |
| 185 |    618.296591 |    274.870459 | Dori <dori@merr.info> (source photo) and Nevit Dilmen                                                                                                                 |
| 186 |    530.380583 |    137.009817 | Margot Michaud                                                                                                                                                        |
| 187 |    619.089323 |    236.107941 | terngirl                                                                                                                                                              |
| 188 |    629.168090 |    756.989914 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                                   |
| 189 |    847.533487 |     71.559116 | NA                                                                                                                                                                    |
| 190 |    554.245861 |    693.105840 | Zimices                                                                                                                                                               |
| 191 |     28.933068 |    448.066448 | T. Michael Keesey                                                                                                                                                     |
| 192 |    736.795214 |    326.662949 | Zimices                                                                                                                                                               |
| 193 |    685.501412 |    451.514066 | Matt Crook                                                                                                                                                            |
| 194 |    654.807132 |    386.277276 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                                  |
| 195 |    810.056324 |    498.950076 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 196 |    975.684542 |    181.392978 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 197 |    310.568270 |    315.826744 | Mattia Menchetti                                                                                                                                                      |
| 198 |    894.852088 |    780.066751 | Margot Michaud                                                                                                                                                        |
| 199 |    960.592980 |    124.645225 | Gareth Monger                                                                                                                                                         |
| 200 |    302.441600 |      7.107234 | Roberto Díaz Sibaja                                                                                                                                                   |
| 201 |    420.332746 |     88.278489 | Cesar Julian                                                                                                                                                          |
| 202 |     76.489332 |    727.039042 | Gareth Monger                                                                                                                                                         |
| 203 |    826.748990 |    208.503440 | Lukas Panzarin                                                                                                                                                        |
| 204 |    632.454570 |    566.403161 | Ferran Sayol                                                                                                                                                          |
| 205 |    483.933044 |    476.403405 | Ferran Sayol                                                                                                                                                          |
| 206 |    424.961626 |      5.155051 | Scott Hartman, modified by T. Michael Keesey                                                                                                                          |
| 207 |    810.852048 |    549.374726 | Gabriel Lio, vectorized by Zimices                                                                                                                                    |
| 208 |    839.516797 |    192.159761 | Kai R. Caspar                                                                                                                                                         |
| 209 |     95.016177 |    614.531467 | Zimices                                                                                                                                                               |
| 210 |    697.746803 |    613.328950 | Christine Axon                                                                                                                                                        |
| 211 |    666.015780 |    350.481731 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 212 |     19.381356 |    376.528680 | T. Michael Keesey                                                                                                                                                     |
| 213 |    359.012714 |    788.471750 | Collin Gross                                                                                                                                                          |
| 214 |    787.622767 |    717.517721 | NA                                                                                                                                                                    |
| 215 |    497.239807 |    356.200031 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 216 |    338.960245 |    312.315155 | Maija Karala                                                                                                                                                          |
| 217 |    978.045777 |    696.809514 | NA                                                                                                                                                                    |
| 218 |    629.495170 |    361.562343 | Gordon E. Robertson                                                                                                                                                   |
| 219 |    478.721208 |      5.325239 | NA                                                                                                                                                                    |
| 220 |    740.271482 |    285.639979 | NA                                                                                                                                                                    |
| 221 |    861.328440 |    201.447588 | Gareth Monger                                                                                                                                                         |
| 222 |    548.281919 |    273.223243 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 223 |    485.856063 |    573.004921 | Steven Traver                                                                                                                                                         |
| 224 |    144.529313 |      5.645328 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                                    |
| 225 |    896.443006 |    653.146127 | Caleb M. Brown                                                                                                                                                        |
| 226 |    726.696637 |    771.601834 | Matt Crook                                                                                                                                                            |
| 227 |    339.292560 |     52.177868 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 228 |    422.412608 |    509.939593 | Tasman Dixon                                                                                                                                                          |
| 229 |    764.986774 |    500.926494 | Cesar Julian                                                                                                                                                          |
| 230 |    724.521781 |     61.522032 | Felix Vaux                                                                                                                                                            |
| 231 |    978.521083 |    312.337868 | L. Shyamal                                                                                                                                                            |
| 232 |    316.781447 |    336.023144 | M Kolmann                                                                                                                                                             |
| 233 |    974.206015 |    581.236733 | Kai R. Caspar                                                                                                                                                         |
| 234 |    779.058995 |    691.607831 | Gareth Monger                                                                                                                                                         |
| 235 |     52.330799 |     71.844167 | Becky Barnes                                                                                                                                                          |
| 236 |    367.171557 |    287.313474 | E. Lear, 1819 (vectorization by Yan Wong)                                                                                                                             |
| 237 |    798.816029 |    334.739046 | Ferran Sayol                                                                                                                                                          |
| 238 |     59.620255 |    746.257624 | Kai R. Caspar                                                                                                                                                         |
| 239 |    327.976970 |    178.058528 | David Orr                                                                                                                                                             |
| 240 |    510.331637 |    265.260753 | Sarah Werning                                                                                                                                                         |
| 241 |    633.693820 |    259.522654 | Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey          |
| 242 |     34.477483 |    603.251739 | Zimices                                                                                                                                                               |
| 243 |    500.042079 |    518.838895 | NA                                                                                                                                                                    |
| 244 |    842.976791 |    649.802358 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                    |
| 245 |    234.343894 |    649.935287 | Ferran Sayol                                                                                                                                                          |
| 246 |    564.318576 |    119.205108 | Joanna Wolfe                                                                                                                                                          |
| 247 |    732.651249 |    662.607637 | Beth Reinke                                                                                                                                                           |
| 248 |    121.279759 |    644.067867 | Smokeybjb                                                                                                                                                             |
| 249 |    265.372351 |    482.929687 | Baheerathan Murugavel                                                                                                                                                 |
| 250 |    928.713575 |    775.770704 | xgirouxb                                                                                                                                                              |
| 251 |    387.031515 |    460.672214 | Zimices                                                                                                                                                               |
| 252 |    265.466195 |    233.266568 | Margot Michaud                                                                                                                                                        |
| 253 |    964.313183 |    156.723451 | Crystal Maier                                                                                                                                                         |
| 254 |    429.212763 |     43.232060 | Zimices                                                                                                                                                               |
| 255 |    266.211198 |     95.811900 | T. Michael Keesey                                                                                                                                                     |
| 256 |    129.864211 |    196.825157 | Campbell Fleming                                                                                                                                                      |
| 257 |    907.768519 |    213.145581 | Steven Traver                                                                                                                                                         |
| 258 |    796.749963 |    576.490800 | Margot Michaud                                                                                                                                                        |
| 259 |    299.795700 |    563.143370 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 260 |     52.958647 |    421.158667 | Nobu Tamura                                                                                                                                                           |
| 261 |    267.971111 |    638.888617 | Nobu Tamura                                                                                                                                                           |
| 262 |    782.008399 |    248.460083 | Jakovche                                                                                                                                                              |
| 263 |    284.616396 |    473.641681 | NA                                                                                                                                                                    |
| 264 |    655.590473 |    584.160104 | C. Camilo Julián-Caballero                                                                                                                                            |
| 265 |    153.659103 |     31.632963 | Scott Reid                                                                                                                                                            |
| 266 |    171.365508 |      8.374244 | Roberto Díaz Sibaja                                                                                                                                                   |
| 267 |    653.568663 |    281.143694 | Dinah Challen                                                                                                                                                         |
| 268 |    449.647242 |    735.106792 | Margot Michaud                                                                                                                                                        |
| 269 |    212.744410 |    319.642127 | T. Michael Keesey                                                                                                                                                     |
| 270 |    999.650091 |    279.887350 | Sharon Wegner-Larsen                                                                                                                                                  |
| 271 |    487.474411 |    156.259358 | Jimmy Bernot                                                                                                                                                          |
| 272 |    237.526493 |    524.385200 | Zimices                                                                                                                                                               |
| 273 |    766.989559 |    445.076626 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 274 |    601.634033 |    246.677984 | Steven Traver                                                                                                                                                         |
| 275 |    686.910042 |    520.273428 | Jagged Fang Designs                                                                                                                                                   |
| 276 |    217.148287 |    193.412022 | Chase Brownstein                                                                                                                                                      |
| 277 |    261.163440 |    791.065915 | Lukasiniho                                                                                                                                                            |
| 278 |    113.501536 |    531.694421 | Melissa Broussard                                                                                                                                                     |
| 279 |     91.215610 |    241.280273 | NA                                                                                                                                                                    |
| 280 |    869.680245 |    511.331776 | Jonathan Wells                                                                                                                                                        |
| 281 |    999.138874 |    713.093276 | Zimices                                                                                                                                                               |
| 282 |    249.472182 |    182.766245 | Steven Traver                                                                                                                                                         |
| 283 |    100.291224 |    260.430484 | Margot Michaud                                                                                                                                                        |
| 284 |    934.437167 |    597.064293 | Zimices                                                                                                                                                               |
| 285 |    825.259322 |     50.417421 | Christoph Schomburg                                                                                                                                                   |
| 286 |    775.978717 |    343.156645 | Caio Bernardes, vectorized by Zimices                                                                                                                                 |
| 287 |    585.573435 |    263.903935 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 288 |    831.960255 |    578.745709 | Matt Crook                                                                                                                                                            |
| 289 |    186.422386 |    312.068716 | Gareth Monger                                                                                                                                                         |
| 290 |    818.098165 |     89.060648 | Tasman Dixon                                                                                                                                                          |
| 291 |    497.762154 |    591.902419 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 292 |    111.707690 |    349.029967 | Katie S. Collins                                                                                                                                                      |
| 293 |    394.877466 |    385.205414 | Dmitry Bogdanov                                                                                                                                                       |
| 294 |    785.787208 |    617.606015 | C. Camilo Julián-Caballero                                                                                                                                            |
| 295 |   1016.403167 |    264.336571 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 296 |    899.770788 |    195.415436 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 297 |    747.549785 |      8.170123 | M Kolmann                                                                                                                                                             |
| 298 |    507.606275 |    139.649197 | Zimices                                                                                                                                                               |
| 299 |    496.802409 |    178.003359 | Meliponicultor Itaymbere                                                                                                                                              |
| 300 |    783.968172 |     46.510707 | Roberto Díaz Sibaja                                                                                                                                                   |
| 301 |     40.988644 |    122.413397 | Michael P. Taylor                                                                                                                                                     |
| 302 |    710.005683 |    310.449571 | Scott Hartman                                                                                                                                                         |
| 303 |    598.978147 |    349.215572 | Margot Michaud                                                                                                                                                        |
| 304 |    350.671875 |     13.955694 | NA                                                                                                                                                                    |
| 305 |    242.488242 |    719.372753 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 306 |    225.766347 |    782.730049 | C. Camilo Julián-Caballero                                                                                                                                            |
| 307 |    853.048017 |    338.615001 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 308 |    656.721697 |    660.771556 | Scott Hartman                                                                                                                                                         |
| 309 |    395.024015 |    236.919368 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 310 |    126.869416 |    369.055870 | Scott Hartman                                                                                                                                                         |
| 311 |    584.235055 |    785.721052 | Margot Michaud                                                                                                                                                        |
| 312 |    894.023678 |    578.595465 | Sharon Wegner-Larsen                                                                                                                                                  |
| 313 |    902.279852 |    503.021134 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 314 |    437.220639 |    350.611635 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 315 |    234.966218 |    579.234022 | Jessica Anne Miller                                                                                                                                                   |
| 316 |    964.705465 |    728.524956 | Zimices                                                                                                                                                               |
| 317 |    459.971739 |    198.539301 | Katie S. Collins                                                                                                                                                      |
| 318 |    997.872494 |    587.969499 | T. Michael Keesey (after Ponomarenko)                                                                                                                                 |
| 319 |    982.402497 |    560.786590 | Neil Kelley                                                                                                                                                           |
| 320 |    267.064998 |    687.446751 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                           |
| 321 |    295.485727 |    484.627824 | Margot Michaud                                                                                                                                                        |
| 322 |    893.419980 |    381.955265 | Steven Traver                                                                                                                                                         |
| 323 |    939.179302 |    348.430529 | Scott Hartman                                                                                                                                                         |
| 324 |    918.686101 |    487.220091 | Matt Crook                                                                                                                                                            |
| 325 |    180.095398 |     15.033682 | Scott Hartman                                                                                                                                                         |
| 326 |    986.703756 |    109.414542 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 327 |    246.631620 |    627.267754 | Zimices                                                                                                                                                               |
| 328 |     80.118102 |     89.128123 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
| 329 |     82.098118 |     41.043997 | Sarah Werning                                                                                                                                                         |
| 330 |   1017.102743 |    199.378621 | Gareth Monger                                                                                                                                                         |
| 331 |    524.231769 |    244.340171 | Scott Hartman                                                                                                                                                         |
| 332 |    468.784414 |    545.676178 | Jagged Fang Designs                                                                                                                                                   |
| 333 |    635.358239 |     84.284267 | Christoph Schomburg                                                                                                                                                   |
| 334 |    745.285403 |     44.973114 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 335 |    240.665835 |    273.197634 | Matt Crook                                                                                                                                                            |
| 336 |    572.120728 |    233.266036 | Nick Schooler                                                                                                                                                         |
| 337 |    257.212428 |    437.690853 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                         |
| 338 |    914.853074 |    144.365353 | Geoff Shaw                                                                                                                                                            |
| 339 |    218.611257 |    597.604597 | Scott Hartman                                                                                                                                                         |
| 340 |    997.863952 |    619.801770 | NA                                                                                                                                                                    |
| 341 |    448.447107 |    535.697404 | Margot Michaud                                                                                                                                                        |
| 342 |   1000.219502 |    405.685145 | Margot Michaud                                                                                                                                                        |
| 343 |    642.153117 |    489.307460 | Yan Wong                                                                                                                                                              |
| 344 |     15.227475 |    273.599423 | Margot Michaud                                                                                                                                                        |
| 345 |     57.259354 |    400.071828 | T. Michael Keesey                                                                                                                                                     |
| 346 |   1003.122899 |    730.585921 | Maija Karala                                                                                                                                                          |
| 347 |    434.742062 |    411.571955 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                               |
| 348 |    571.796591 |    616.749704 | Scott Hartman                                                                                                                                                         |
| 349 |    488.204966 |     19.905763 | Francesco “Architetto” Rollandin                                                                                                                                      |
| 350 |    747.308379 |    697.931245 | Matt Crook                                                                                                                                                            |
| 351 |    330.423177 |      4.675502 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 352 |    578.216094 |    132.947034 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 353 |     42.030395 |    740.138829 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 354 |    442.659362 |     82.070482 | Jaime Headden                                                                                                                                                         |
| 355 |    681.350532 |    606.644042 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
| 356 |    401.194537 |    715.158743 | Jagged Fang Designs                                                                                                                                                   |
| 357 |    630.257890 |     37.547206 | Mattia Menchetti                                                                                                                                                      |
| 358 |   1008.953999 |    439.326210 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 359 |    312.674436 |    794.308605 | Jack Mayer Wood                                                                                                                                                       |
| 360 |    399.103740 |    265.478471 | Dean Schnabel                                                                                                                                                         |
| 361 |    997.555291 |    746.602774 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 362 |     61.546006 |    158.974865 | Rene Martin                                                                                                                                                           |
| 363 |     98.192919 |    721.689114 | Tracy A. Heath                                                                                                                                                        |
| 364 |    502.906453 |    383.605768 | Gareth Monger                                                                                                                                                         |
| 365 |    150.493753 |    447.110336 | Christoph Schomburg                                                                                                                                                   |
| 366 |     41.421301 |    138.546019 | Tracy A. Heath                                                                                                                                                        |
| 367 |    363.653659 |    425.923969 | Matt Crook                                                                                                                                                            |
| 368 |    714.665853 |    788.528663 | Mariana Ruiz Villarreal (modified by T. Michael Keesey)                                                                                                               |
| 369 |    152.183407 |    302.255574 | Matt Dempsey                                                                                                                                                          |
| 370 |     24.234165 |    470.486627 | (unknown)                                                                                                                                                             |
| 371 |    319.263987 |     54.702280 | T. Michael Keesey                                                                                                                                                     |
| 372 |    222.379995 |    328.781304 | Roberto Díaz Sibaja                                                                                                                                                   |
| 373 |    332.019944 |    431.723033 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                                       |
| 374 |      9.425114 |    442.185472 | Crystal Maier                                                                                                                                                         |
| 375 |    388.859747 |    282.275656 | Chris huh                                                                                                                                                             |
| 376 |    463.271677 |    789.452477 | C. Camilo Julián-Caballero                                                                                                                                            |
| 377 |    374.106429 |    718.239021 | Steven Traver                                                                                                                                                         |
| 378 |    966.881789 |    199.089722 | B Kimmel                                                                                                                                                              |
| 379 |    146.869152 |    605.232684 | Gareth Monger                                                                                                                                                         |
| 380 |    846.149408 |    132.493110 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                         |
| 381 |    219.961266 |    756.537261 | Rebecca Groom                                                                                                                                                         |
| 382 |    205.193426 |    241.720261 | Maija Karala                                                                                                                                                          |
| 383 |    419.366664 |    406.851673 | Chris huh                                                                                                                                                             |
| 384 |    910.534522 |    555.157601 | Andrew A. Farke                                                                                                                                                       |
| 385 |    312.618190 |    367.903528 | Gareth Monger                                                                                                                                                         |
| 386 |   1003.301434 |    701.626837 | Jagged Fang Designs                                                                                                                                                   |
| 387 |    775.294208 |    529.226241 | Birgit Lang                                                                                                                                                           |
| 388 |    871.282616 |    602.092607 | Chris huh                                                                                                                                                             |
| 389 |    631.954574 |    656.067399 | Steven Blackwood                                                                                                                                                      |
| 390 |    992.052491 |     37.686918 | Steven Traver                                                                                                                                                         |
| 391 |    538.006768 |    447.743706 | FunkMonk                                                                                                                                                              |
| 392 |    446.252434 |    723.230992 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                                |
| 393 |    712.333689 |    557.788678 | Bennet McComish, photo by Avenue                                                                                                                                      |
| 394 |    680.704806 |    508.617831 | Emily Willoughby                                                                                                                                                      |
| 395 |    961.263437 |    115.751854 | Jagged Fang Designs                                                                                                                                                   |
| 396 |    705.145687 |     37.445572 | Margot Michaud                                                                                                                                                        |
| 397 |    876.699105 |      6.116291 | xgirouxb                                                                                                                                                              |
| 398 |    643.409948 |    776.995672 | Tasman Dixon                                                                                                                                                          |
| 399 |     19.784909 |    655.084328 | Gareth Monger                                                                                                                                                         |
| 400 |    759.834022 |    630.572392 | Julia B McHugh                                                                                                                                                        |
| 401 |    973.637895 |    542.737024 | Beth Reinke                                                                                                                                                           |
| 402 |   1007.536521 |    610.342139 | T. Michael Keesey                                                                                                                                                     |
| 403 |    304.595347 |    580.308719 | Maija Karala                                                                                                                                                          |
| 404 |    842.531229 |    634.639795 | C. Camilo Julián-Caballero                                                                                                                                            |
| 405 |    668.503152 |    795.073030 | Blanco et al., 2014, vectorized by Zimices                                                                                                                            |
| 406 |    897.148817 |    418.389523 | Sarah Werning                                                                                                                                                         |
| 407 |    629.269831 |    698.518415 | Felix Vaux                                                                                                                                                            |
| 408 |    740.622281 |    776.810794 | Mattia Menchetti                                                                                                                                                      |
| 409 |    479.605961 |    535.059178 | Kai R. Caspar                                                                                                                                                         |
| 410 |     47.367568 |     50.662877 | S.Martini                                                                                                                                                             |
| 411 |    628.885601 |    453.485346 | Mykle Hoban                                                                                                                                                           |
| 412 |    323.490914 |    344.664407 | Gareth Monger                                                                                                                                                         |
| 413 |   1019.704450 |    530.385911 | Yan Wong                                                                                                                                                              |
| 414 |    243.443959 |      9.456213 | Bennet McComish, photo by Hans Hillewaert                                                                                                                             |
| 415 |    705.067695 |    345.747628 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 416 |    750.765194 |    188.547902 | Tasman Dixon                                                                                                                                                          |
| 417 |    969.900818 |    268.107538 | Julio Garza                                                                                                                                                           |
| 418 |    738.768447 |    113.755887 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                  |
| 419 |    241.339427 |    661.661159 | NA                                                                                                                                                                    |
| 420 |    826.273942 |    453.429816 | Lukas Panzarin                                                                                                                                                        |
| 421 |    208.369024 |    512.401923 | CNZdenek                                                                                                                                                              |
| 422 |    877.375329 |    396.463792 | Zimices                                                                                                                                                               |
| 423 |    914.332710 |    161.481777 | Gareth Monger                                                                                                                                                         |
| 424 |    180.370761 |    573.983220 | Carlos Cano-Barbacil                                                                                                                                                  |
| 425 |    616.019260 |    355.505158 | Noah Schlottman, photo by Carol Cummings                                                                                                                              |
| 426 |    110.922224 |    626.201522 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 427 |     18.638775 |    693.384534 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 428 |    685.934975 |    682.065418 | NA                                                                                                                                                                    |
| 429 |    235.891061 |    303.673731 | Felix Vaux                                                                                                                                                            |
| 430 |     60.307013 |    192.865357 | Gareth Monger                                                                                                                                                         |
| 431 |    910.347575 |    130.589884 | Chris huh                                                                                                                                                             |
| 432 |    758.289212 |    716.142733 | Ghedoghedo, vectorized by Zimices                                                                                                                                     |
| 433 |    187.501925 |     61.649856 | Javier Luque                                                                                                                                                          |
| 434 |    809.138845 |    621.141651 | T. Michael Keesey                                                                                                                                                     |
| 435 |    269.024431 |    352.063848 | S.Martini                                                                                                                                                             |
| 436 |    995.584898 |    231.040944 | Rebecca Groom                                                                                                                                                         |
| 437 |     57.047677 |    491.081198 | Christoph Schomburg                                                                                                                                                   |
| 438 |    339.224470 |    778.677872 | Zimices                                                                                                                                                               |
| 439 |    375.327808 |      4.915578 | Zimices                                                                                                                                                               |
| 440 |    964.096220 |    340.250386 | Margot Michaud                                                                                                                                                        |
| 441 |    260.514546 |    409.864983 | Félix Landry Yuan                                                                                                                                                     |
| 442 |    694.423616 |     13.353043 | Rebecca Groom                                                                                                                                                         |
| 443 |    263.049974 |    578.185814 | Maxime Dahirel                                                                                                                                                        |
| 444 |    591.222350 |     23.670545 | Chris huh                                                                                                                                                             |
| 445 |    957.968966 |    685.502340 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 446 |    658.872239 |    689.202603 | Zimices                                                                                                                                                               |
| 447 |    975.502692 |    436.057073 | E. J. Van Nieukerken, A. Laštuvka, and Z. Laštuvka (vectorized by T. Michael Keesey)                                                                                  |
| 448 |    816.125568 |      4.483531 | T. Michael Keesey                                                                                                                                                     |
| 449 |    253.530266 |    706.501862 | Tasman Dixon                                                                                                                                                          |
| 450 |    319.360168 |    163.386371 | Tracy A. Heath                                                                                                                                                        |
| 451 |    467.765903 |     99.686576 | Zimices                                                                                                                                                               |
| 452 |    477.629161 |    495.974421 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 453 |    521.911521 |    118.087047 | Margot Michaud                                                                                                                                                        |
| 454 |    702.219518 |    372.850100 | Gareth Monger                                                                                                                                                         |
| 455 |    382.630463 |    393.616787 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
| 456 |     11.655873 |    246.986077 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 457 |    686.009854 |    537.459794 | Christoph Schomburg                                                                                                                                                   |
| 458 |    767.462953 |    120.642475 | Smokeybjb                                                                                                                                                             |
| 459 |    122.165122 |    708.749811 | Gareth Monger                                                                                                                                                         |
| 460 |   1005.063768 |    468.325233 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                              |
| 461 |   1007.685274 |    112.007224 | Ferran Sayol                                                                                                                                                          |
| 462 |    989.269726 |    531.791258 | Cesar Julian                                                                                                                                                          |
| 463 |    846.870534 |    791.764223 |                                                                                                                                                                       |
| 464 |    554.093515 |    660.955066 | Zimices                                                                                                                                                               |
| 465 |    397.649447 |     10.650385 | Zimices                                                                                                                                                               |
| 466 |    710.869806 |    505.285679 | Zimices                                                                                                                                                               |
| 467 |    504.914851 |    790.110358 | Birgit Lang                                                                                                                                                           |
| 468 |    482.191956 |    375.062222 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                     |
| 469 |    876.351696 |    649.260215 | NASA                                                                                                                                                                  |
| 470 |    289.441622 |    129.363356 | Kimberly Haddrell                                                                                                                                                     |
| 471 |    242.861665 |    622.938092 | Christoph Schomburg                                                                                                                                                   |
| 472 |   1012.499052 |    158.573307 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                             |
| 473 |     12.437529 |    781.525822 | Steven Traver                                                                                                                                                         |
| 474 |    339.585547 |    101.197546 | Tasman Dixon                                                                                                                                                          |
| 475 |    715.123036 |    761.259325 | Matt Crook                                                                                                                                                            |
| 476 |    620.090938 |    579.782707 | Scott Hartman                                                                                                                                                         |
| 477 |    229.451543 |    338.485827 | Christoph Schomburg                                                                                                                                                   |
| 478 |    434.936498 |    214.109510 | Jonathan Wells                                                                                                                                                        |
| 479 |    533.022229 |    398.808387 | Gareth Monger                                                                                                                                                         |
| 480 |    437.568319 |    523.504596 | Scott Hartman                                                                                                                                                         |
| 481 |    242.966018 |    468.351920 | NA                                                                                                                                                                    |
| 482 |    473.457777 |    187.057611 | David Orr                                                                                                                                                             |
| 483 |    620.504403 |    622.316914 | Margot Michaud                                                                                                                                                        |
| 484 |    463.892278 |    389.685907 | Matt Crook                                                                                                                                                            |
| 485 |   1015.501158 |     11.112823 | Matt Crook                                                                                                                                                            |
| 486 |    711.679441 |    423.240524 | Chris huh                                                                                                                                                             |
| 487 |    430.375442 |    710.378967 | T. Michael Keesey                                                                                                                                                     |
| 488 |    175.637062 |    284.375312 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 489 |    291.752977 |    607.773599 | Margot Michaud                                                                                                                                                        |
| 490 |    717.530966 |    672.775807 | Margot Michaud                                                                                                                                                        |
| 491 |    801.793284 |    119.776821 | T. Michael Keesey                                                                                                                                                     |
| 492 |    648.402822 |    350.721265 | Michelle Site                                                                                                                                                         |
| 493 |    817.858010 |    795.016103 | NA                                                                                                                                                                    |
| 494 |    473.636901 |    485.273079 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                                      |
| 495 |    846.945073 |     48.909970 | Jay Matternes, vectorized by Zimices                                                                                                                                  |
| 496 |    859.491383 |    500.486216 | Steven Traver                                                                                                                                                         |
| 497 |    503.610113 |    250.149281 | NA                                                                                                                                                                    |
| 498 |    140.898814 |    638.647280 | Sarah Werning                                                                                                                                                         |
| 499 |    819.832642 |    198.032138 | Michael Scroggie                                                                                                                                                      |
| 500 |    415.534672 |     79.328107 | NA                                                                                                                                                                    |
| 501 |    396.671472 |    528.088450 | T. Michael Keesey                                                                                                                                                     |
| 502 |    144.311109 |    527.806536 | Scott Hartman                                                                                                                                                         |
| 503 |    332.430393 |    119.583962 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 504 |      4.440530 |    751.190213 | NA                                                                                                                                                                    |
| 505 |    470.379307 |    712.831225 | Zimices                                                                                                                                                               |
| 506 |    784.122101 |    161.330327 | Zimices                                                                                                                                                               |
| 507 |    456.129317 |    408.550285 | Margot Michaud                                                                                                                                                        |
| 508 |    324.445026 |    394.552293 | Matt Crook                                                                                                                                                            |
| 509 |    770.687955 |    474.465393 | Caleb M. Brown                                                                                                                                                        |
| 510 |    320.411346 |    442.181165 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                       |
| 511 |    958.063116 |     65.573466 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 512 |    701.657170 |    322.201619 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 513 |    310.732980 |     73.267748 | Dean Schnabel                                                                                                                                                         |
| 514 |    315.448326 |    780.466475 | Kamil S. Jaron                                                                                                                                                        |
| 515 |    623.735255 |     87.940455 | Ferran Sayol                                                                                                                                                          |
| 516 |     90.512047 |     88.119429 | NA                                                                                                                                                                    |

    #> Your tweet has been posted!
