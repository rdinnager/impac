
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

Gareth Monger, Dean Schnabel, Chris huh, Birgit Lang, Danielle Alba,
Ville Koistinen (vectorized by T. Michael Keesey), Zimices, Nobu Tamura
(vectorized by T. Michael Keesey), Rebecca Groom, Andrew A. Farke,
Steven Traver, Nobu Tamura, Matt Wilkins, Robert Bruce Horsfall,
vectorized by Zimices, Jebulon (vectorized by T. Michael Keesey), Sharon
Wegner-Larsen, Tasman Dixon, Trond R. Oskars, Gustav Mützel, Yan Wong,
Alexander Schmidt-Lebuhn, Matt Crook, Gabriela Palomo-Munoz, Jay
Matternes (vectorized by T. Michael Keesey), Chloé Schmidt, Mathilde
Cordellier, Nobu Tamura, vectorized by Zimices, Dave Angelini, Auckland
Museum and T. Michael Keesey, Margot Michaud, Jack Mayer Wood, Noah
Schlottman, photo by Casey Dunn, Jaime Headden, Smokeybjb, Yan Wong from
photo by Denes Emoke, Brian Gratwicke (photo) and T. Michael Keesey
(vectorization), Maija Karala, Chase Brownstein, T. Michael Keesey,
Tommaso Cancellario, C. Camilo Julián-Caballero, Jagged Fang Designs,
Dmitry Bogdanov (vectorized by T. Michael Keesey), Felix Vaux, Scott
Hartman, Julia B McHugh, Sarah Werning, Roberto Diaz Sibaja, based on
Domser, Richard Ruggiero, vectorized by Zimices, Claus Rebler, Armin
Reindl, E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor &
Matthew J. Wedel), Jan A. Venter, Herbert H. T. Prins, David A. Balfour
& Rob Slotow (vectorized by T. Michael Keesey), Ferran Sayol, Carlos
Cano-Barbacil, Isaure Scavezzoni, Maxime Dahirel (digitisation), Kees
van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication),
Crystal Maier, Sherman F. Denton via rawpixel.com (illustration) and
Timothy J. Bartley (silhouette), H. F. O. March (vectorized by T.
Michael Keesey), terngirl, Maxime Dahirel, Dave Souza (vectorized by T.
Michael Keesey), Noah Schlottman, photo from Casey Dunn, Liftarn, Mathew
Callaghan, Jose Carlos Arenas-Monroy, T. Michael Keesey (after Monika
Betley), FJDegrange, Christoph Schomburg, Bill Bouton (source photo) &
T. Michael Keesey (vectorization), Iain Reid, Xavier Giroux-Bougard,
Tyler McCraney, Javier Luque & Sarah Gerken, Lily Hughes, Beth Reinke,
Michelle Site, Alex Slavenko, Andrew A. Farke, modified from original by
Robert Bruce Horsfall, from Scott 1912, Manabu Bessho-Uehara,
Christopher Watson (photo) and T. Michael Keesey (vectorization), Diego
Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli,
Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by
T. Michael Keesey), Matt Martyniuk, L. Shyamal, Josefine Bohr Brask, T.
Michael Keesey (after Marek Velechovský), Stanton F. Fink (vectorized by
T. Michael Keesey), FunkMonk (Michael B.H.; vectorized by T. Michael
Keesey), Christine Axon, Emily Jane McTavish, from Haeckel, E. H. P. A.
(1904).Kunstformen der Natur. Bibliographisches, Frank Förster,
Ghedoghedo, vectorized by Zimices, Steven Coombs, Collin Gross, Roberto
Díaz Sibaja, Kent Elson Sorgon, T. Michael Keesey (photo by Bc999
\[Black crow\]), Melissa Broussard, Henry Lydecker, Lukasiniho,
Smokeybjb (vectorized by T. Michael Keesey), Mathieu Basille, Philippe
Janvier (vectorized by T. Michael Keesey), T. Michael Keesey (after
Joseph Wolf), Shyamal, Ewald Rübsamen, Julio Garza, Jim Bendon
(photography) and T. Michael Keesey (vectorization), Hanyong Pu,
Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming
Zhang, Songhai Jia & T. Michael Keesey, Kenneth Lacovara (vectorized by
T. Michael Keesey), Fritz Geller-Grimm (vectorized by T. Michael
Keesey), SecretJellyMan - from Mason McNair, Darren Naish (vectorized by
T. Michael Keesey), Brad McFeeters (vectorized by T. Michael Keesey),
Kimberly Haddrell, wsnaccad, Emily Willoughby, Blanco et al., 2014,
vectorized by Zimices, Eduard Solà Vázquez, vectorised by Yan Wong,
Nicholas J. Czaplewski, vectorized by Zimices, Tony Ayling (vectorized
by T. Michael Keesey), Pollyanna von Knorring and T. Michael Keesey,
Dmitry Bogdanov, James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo
Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael
Keesey), Oscar Sanisidro, Matt Martyniuk (modified by T. Michael
Keesey), Harold N Eyster, David Orr, Milton Tan, Michael Scroggie,
Xavier A. Jenkins, Gabriel Ugueto, Jaime Headden (vectorized by T.
Michael Keesey), Nobu Tamura, modified by Andrew A. Farke, Darren Naish
(vectorize by T. Michael Keesey), Lisa M. “Pixxl” (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Peter Coxhead,
T. Michael Keesey (after A. Y. Ivantsov), FunkMonk \[Michael B.H.\]
(modified by T. Michael Keesey), Katie S. Collins, Jessica Anne Miller,
Caleb M. Brown, Warren H (photography), T. Michael Keesey
(vectorization), Timothy Knepp of the U.S. Fish and Wildlife Service
(illustration) and Timothy J. Bartley (silhouette), T. Michael Keesey
(after Tillyard), Pranav Iyer (grey ideas), Dmitry Bogdanov (modified by
T. Michael Keesey), A. H. Baldwin (vectorized by T. Michael Keesey),
Obsidian Soul (vectorized by T. Michael Keesey), Rene Martin, Mathew
Wedel, M Kolmann, Anthony Caravaggi, Danny Cicchetti (vectorized by T.
Michael Keesey), Jesús Gómez, vectorized by Zimices, Lip Kee Yap
(vectorized by T. Michael Keesey), Tyler Greenfield, Heinrich Harder
(vectorized by T. Michael Keesey), AnAgnosticGod (vectorized by T.
Michael Keesey), Timothy Knepp (vectorized by T. Michael Keesey),
Jonathan Wells, Scott Hartman (modified by T. Michael Keesey), Siobhon
Egan, Ghedo and T. Michael Keesey, Kamil S. Jaron, Acrocynus (vectorized
by T. Michael Keesey), Natasha Vitek, Gopal Murali, Arthur S. Brum, Ralf
Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T.
Michael Keesey), Matt Martyniuk (vectorized by T. Michael Keesey),
Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization),
Nicolas Huet le Jeune and Jean-Gabriel Prêtre (vectorized by T. Michael
Keesey), Tony Ayling, Nancy Wyman (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Joanna Wolfe, DW Bapst (modified from
Bates et al., 2005), Ellen Edmonson and Hugh Chrisp (illustration) and
Timothy J. Bartley (silhouette), Charles R. Knight, vectorized by
Zimices, Mark Hofstetter (vectorized by T. Michael Keesey), Noah
Schlottman, C. Abraczinskas, Darius Nau, Tauana J. Cunha, Nobu Tamura
(modified by T. Michael Keesey), Mali’o Kodis, image from the
Smithsonian Institution, Pete Buchholz, Remes K, Ortega F, Fierro I,
Joger U, Kosma R, et al., nicubunu, DW Bapst (Modified from photograph
taken by Charles Mitchell), Cesar Julian, Lauren Sumner-Rooney, B. Duygu
Özpolat, Francisco Gascó (modified by Michael P. Taylor)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     811.60021 |    700.601221 | Gareth Monger                                                                                                                                                         |
|   2 |      89.57077 |    346.799935 | Dean Schnabel                                                                                                                                                         |
|   3 |     266.39639 |     58.638620 | Chris huh                                                                                                                                                             |
|   4 |      97.14863 |    691.862315 | Birgit Lang                                                                                                                                                           |
|   5 |     291.36576 |    669.844894 | Danielle Alba                                                                                                                                                         |
|   6 |     168.37090 |    415.086321 | Ville Koistinen (vectorized by T. Michael Keesey)                                                                                                                     |
|   7 |     794.02726 |    607.855558 | Zimices                                                                                                                                                               |
|   8 |     207.18554 |    570.928988 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|   9 |     278.92748 |    429.673203 | Rebecca Groom                                                                                                                                                         |
|  10 |     338.00870 |    174.563575 | Andrew A. Farke                                                                                                                                                       |
|  11 |     901.72607 |     89.141286 | Steven Traver                                                                                                                                                         |
|  12 |     534.17751 |    635.765572 | Zimices                                                                                                                                                               |
|  13 |     245.80007 |    288.345430 | Nobu Tamura                                                                                                                                                           |
|  14 |     465.00580 |    371.686566 | Matt Wilkins                                                                                                                                                          |
|  15 |     688.34039 |     65.507030 | NA                                                                                                                                                                    |
|  16 |     771.59128 |    521.345422 | Zimices                                                                                                                                                               |
|  17 |     543.78303 |    527.026069 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
|  18 |     760.34852 |    258.709723 | Gareth Monger                                                                                                                                                         |
|  19 |     135.47132 |     85.955247 | Jebulon (vectorized by T. Michael Keesey)                                                                                                                             |
|  20 |     901.05690 |    214.720643 | Sharon Wegner-Larsen                                                                                                                                                  |
|  21 |     220.52820 |    343.220385 | Tasman Dixon                                                                                                                                                          |
|  22 |     107.16593 |    184.926702 | Andrew A. Farke                                                                                                                                                       |
|  23 |     467.31006 |    137.900925 | Trond R. Oskars                                                                                                                                                       |
|  24 |     624.92048 |    144.752236 | Gustav Mützel                                                                                                                                                         |
|  25 |     885.39478 |    444.806891 | Yan Wong                                                                                                                                                              |
|  26 |     585.26246 |    727.744262 | Tasman Dixon                                                                                                                                                          |
|  27 |     255.42724 |    207.865108 | Dean Schnabel                                                                                                                                                         |
|  28 |     577.38094 |    355.785989 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|  29 |     807.63144 |    389.041118 | Matt Crook                                                                                                                                                            |
|  30 |     574.52262 |     59.348770 | Tasman Dixon                                                                                                                                                          |
|  31 |     924.40348 |    579.055370 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  32 |     655.19705 |    276.299178 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                                       |
|  33 |     403.99068 |    447.705991 | Chloé Schmidt                                                                                                                                                         |
|  34 |      90.93754 |    529.791124 | Mathilde Cordellier                                                                                                                                                   |
|  35 |     601.10290 |    439.371482 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  36 |     674.50352 |    608.379057 | Dave Angelini                                                                                                                                                         |
|  37 |     380.99383 |    565.288712 | Auckland Museum and T. Michael Keesey                                                                                                                                 |
|  38 |     438.30816 |    743.021036 | Tasman Dixon                                                                                                                                                          |
|  39 |     518.70976 |    285.558451 | Margot Michaud                                                                                                                                                        |
|  40 |     719.02155 |    383.037101 | Jack Mayer Wood                                                                                                                                                       |
|  41 |     975.91253 |    704.706650 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
|  42 |     954.80318 |    313.670393 | Margot Michaud                                                                                                                                                        |
|  43 |     318.25106 |    761.205887 | Jaime Headden                                                                                                                                                         |
|  44 |     708.35255 |    182.419656 | Matt Crook                                                                                                                                                            |
|  45 |     263.46845 |    479.064440 | Jack Mayer Wood                                                                                                                                                       |
|  46 |     429.19602 |     27.690299 | Smokeybjb                                                                                                                                                             |
|  47 |     202.23502 |    763.232203 | Yan Wong from photo by Denes Emoke                                                                                                                                    |
|  48 |     426.58180 |    661.232671 | Brian Gratwicke (photo) and T. Michael Keesey (vectorization)                                                                                                         |
|  49 |     922.53600 |    366.048449 | Margot Michaud                                                                                                                                                        |
|  50 |     269.22967 |    607.713282 | Maija Karala                                                                                                                                                          |
|  51 |     702.38472 |    445.459067 | Tasman Dixon                                                                                                                                                          |
|  52 |     387.47605 |    266.663906 | Chase Brownstein                                                                                                                                                      |
|  53 |     344.22650 |     92.887290 | Matt Crook                                                                                                                                                            |
|  54 |     348.23943 |    336.617468 | Tasman Dixon                                                                                                                                                          |
|  55 |     574.07985 |    223.749685 | Maija Karala                                                                                                                                                          |
|  56 |     880.87997 |    783.166384 | T. Michael Keesey                                                                                                                                                     |
|  57 |      97.19886 |    284.860781 | NA                                                                                                                                                                    |
|  58 |     959.76244 |    514.530428 | Tommaso Cancellario                                                                                                                                                   |
|  59 |      95.83788 |    456.168145 | C. Camilo Julián-Caballero                                                                                                                                            |
|  60 |     199.11902 |    701.683415 | Birgit Lang                                                                                                                                                           |
|  61 |     727.88242 |    548.944050 | T. Michael Keesey                                                                                                                                                     |
|  62 |     625.84868 |    779.609470 | Gareth Monger                                                                                                                                                         |
|  63 |     848.59889 |     24.573323 | Jagged Fang Designs                                                                                                                                                   |
|  64 |      36.95159 |    653.124359 | T. Michael Keesey                                                                                                                                                     |
|  65 |     655.86129 |    664.859488 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  66 |     931.13197 |    157.319943 | Chris huh                                                                                                                                                             |
|  67 |     323.02562 |    517.588828 | Chris huh                                                                                                                                                             |
|  68 |     101.15393 |     34.834158 | NA                                                                                                                                                                    |
|  69 |     205.91959 |    515.130199 | Gareth Monger                                                                                                                                                         |
|  70 |     593.45927 |    183.543784 | Birgit Lang                                                                                                                                                           |
|  71 |     182.06081 |     18.757436 | Nobu Tamura                                                                                                                                                           |
|  72 |     735.04693 |    333.849871 | Andrew A. Farke                                                                                                                                                       |
|  73 |     797.38509 |     98.712383 | Chris huh                                                                                                                                                             |
|  74 |      15.02328 |    249.621303 | Gareth Monger                                                                                                                                                         |
|  75 |     790.77882 |    184.822076 | Felix Vaux                                                                                                                                                            |
|  76 |     565.03996 |    416.776691 | Scott Hartman                                                                                                                                                         |
|  77 |     744.86135 |    770.809042 | Scott Hartman                                                                                                                                                         |
|  78 |     276.80921 |    359.677867 | Tasman Dixon                                                                                                                                                          |
|  79 |     912.68984 |    734.177607 | Dean Schnabel                                                                                                                                                         |
|  80 |     979.22913 |    769.429725 | Tasman Dixon                                                                                                                                                          |
|  81 |     854.75329 |    323.999384 | Julia B McHugh                                                                                                                                                        |
|  82 |     169.02575 |    619.471239 | NA                                                                                                                                                                    |
|  83 |     919.64835 |    720.226952 | Gareth Monger                                                                                                                                                         |
|  84 |     398.47673 |     94.238173 | Sarah Werning                                                                                                                                                         |
|  85 |     820.36238 |    305.456418 | Roberto Diaz Sibaja, based on Domser                                                                                                                                  |
|  86 |      57.62041 |    771.752529 | Richard Ruggiero, vectorized by Zimices                                                                                                                               |
|  87 |      32.31051 |     81.198336 | Tasman Dixon                                                                                                                                                          |
|  88 |      89.86430 |    587.114289 | Zimices                                                                                                                                                               |
|  89 |     661.40204 |    723.202230 | NA                                                                                                                                                                    |
|  90 |     613.51975 |    109.931585 | Claus Rebler                                                                                                                                                          |
|  91 |     535.89069 |    154.292995 | Armin Reindl                                                                                                                                                          |
|  92 |     990.52648 |    219.928118 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                      |
|  93 |     391.96078 |    373.633681 | Matt Crook                                                                                                                                                            |
|  94 |     414.34224 |    609.082300 | Gareth Monger                                                                                                                                                         |
|  95 |      47.92711 |    471.531480 | Chris huh                                                                                                                                                             |
|  96 |     991.11285 |     84.813862 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
|  97 |     335.15419 |    712.777254 | Ferran Sayol                                                                                                                                                          |
|  98 |     797.78857 |    646.592347 | Andrew A. Farke                                                                                                                                                       |
|  99 |     869.94246 |    489.098862 | NA                                                                                                                                                                    |
| 100 |     782.65699 |     46.065937 | Zimices                                                                                                                                                               |
| 101 |     959.73508 |    244.035091 | Tasman Dixon                                                                                                                                                          |
| 102 |     947.04293 |    422.735118 | T. Michael Keesey                                                                                                                                                     |
| 103 |     724.99254 |    730.649353 | NA                                                                                                                                                                    |
| 104 |     238.27152 |    103.054106 | Carlos Cano-Barbacil                                                                                                                                                  |
| 105 |     967.19247 |     48.173408 | Scott Hartman                                                                                                                                                         |
| 106 |     807.44030 |    753.642282 | Isaure Scavezzoni                                                                                                                                                     |
| 107 |     181.20859 |    307.342685 | Steven Traver                                                                                                                                                         |
| 108 |     551.61802 |     17.423432 | NA                                                                                                                                                                    |
| 109 |     480.89527 |    781.712308 | Maxime Dahirel (digitisation), Kees van Achterberg et al (doi: 10.3897/BDJ.8.e49017)(original publication)                                                            |
| 110 |     413.62835 |     71.173517 | Crystal Maier                                                                                                                                                         |
| 111 |     957.33337 |    624.216556 | Rebecca Groom                                                                                                                                                         |
| 112 |     623.75758 |    590.876089 | Steven Traver                                                                                                                                                         |
| 113 |     302.45530 |    298.322141 | Matt Crook                                                                                                                                                            |
| 114 |     183.56339 |    645.902291 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                                 |
| 115 |     992.61650 |     21.557569 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                      |
| 116 |      31.43010 |    401.214924 | Jaime Headden                                                                                                                                                         |
| 117 |     991.07815 |     54.793423 | terngirl                                                                                                                                                              |
| 118 |     890.36186 |    388.239601 | Rebecca Groom                                                                                                                                                         |
| 119 |    1004.59408 |    713.059087 | Maxime Dahirel                                                                                                                                                        |
| 120 |     871.31991 |    678.155759 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                          |
| 121 |     551.72813 |     96.691160 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 122 |    1002.73915 |    127.988241 | Zimices                                                                                                                                                               |
| 123 |     831.65393 |    475.433336 | Liftarn                                                                                                                                                               |
| 124 |     925.27906 |    394.728293 | NA                                                                                                                                                                    |
| 125 |     231.72342 |    130.679988 | Mathew Callaghan                                                                                                                                                      |
| 126 |     411.56156 |    787.707559 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 127 |     658.08870 |    523.244700 | Scott Hartman                                                                                                                                                         |
| 128 |     990.52644 |    403.433831 | Ferran Sayol                                                                                                                                                          |
| 129 |     100.01174 |    734.410041 | Zimices                                                                                                                                                               |
| 130 |     662.27763 |    194.958871 | Rebecca Groom                                                                                                                                                         |
| 131 |     226.33324 |    749.643922 | Gareth Monger                                                                                                                                                         |
| 132 |     336.17160 |    659.809557 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 133 |     836.28487 |    508.303154 | Ferran Sayol                                                                                                                                                          |
| 134 |      34.99828 |    530.526524 | Zimices                                                                                                                                                               |
| 135 |     618.20436 |    542.678434 | T. Michael Keesey (after Monika Betley)                                                                                                                               |
| 136 |     695.09838 |    143.495134 | FJDegrange                                                                                                                                                            |
| 137 |     123.84731 |    761.626819 | Gareth Monger                                                                                                                                                         |
| 138 |     497.18708 |    687.108826 | Gareth Monger                                                                                                                                                         |
| 139 |     553.84336 |    470.010315 | Jagged Fang Designs                                                                                                                                                   |
| 140 |     340.44618 |    392.293260 | Steven Traver                                                                                                                                                         |
| 141 |     433.62843 |    390.536618 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                                 |
| 142 |     325.23460 |    246.790471 | Christoph Schomburg                                                                                                                                                   |
| 143 |     442.29334 |    703.493863 | Matt Crook                                                                                                                                                            |
| 144 |     604.48397 |    636.929492 | Sarah Werning                                                                                                                                                         |
| 145 |     656.89833 |    330.732952 | Ferran Sayol                                                                                                                                                          |
| 146 |     691.88011 |    497.056767 | Bill Bouton (source photo) & T. Michael Keesey (vectorization)                                                                                                        |
| 147 |     372.96383 |    694.768078 | Iain Reid                                                                                                                                                             |
| 148 |     809.04933 |    450.559279 | Matt Crook                                                                                                                                                            |
| 149 |     773.83224 |     76.322600 | Steven Traver                                                                                                                                                         |
| 150 |     458.08970 |    438.539401 | Xavier Giroux-Bougard                                                                                                                                                 |
| 151 |     638.75681 |      7.593053 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 152 |     298.95063 |     97.390783 | Gareth Monger                                                                                                                                                         |
| 153 |     485.74657 |    250.773100 | Tyler McCraney                                                                                                                                                        |
| 154 |     482.90633 |    762.004926 | Javier Luque & Sarah Gerken                                                                                                                                           |
| 155 |     375.33654 |    523.828017 | Lily Hughes                                                                                                                                                           |
| 156 |     578.76986 |    597.123832 | T. Michael Keesey                                                                                                                                                     |
| 157 |     345.13741 |     62.910065 | Beth Reinke                                                                                                                                                           |
| 158 |     774.56889 |    459.671475 | Beth Reinke                                                                                                                                                           |
| 159 |     432.00410 |    531.946637 | Michelle Site                                                                                                                                                         |
| 160 |      76.75026 |    620.170182 | Margot Michaud                                                                                                                                                        |
| 161 |     503.35719 |     18.603336 | Birgit Lang                                                                                                                                                           |
| 162 |     607.33944 |    534.099629 | Alex Slavenko                                                                                                                                                         |
| 163 |     788.37975 |    269.162997 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                                     |
| 164 |     343.44249 |    625.789969 | Margot Michaud                                                                                                                                                        |
| 165 |      14.95326 |    686.371798 | Rebecca Groom                                                                                                                                                         |
| 166 |     254.70459 |    323.682441 | Manabu Bessho-Uehara                                                                                                                                                  |
| 167 |      73.19426 |    380.439537 | NA                                                                                                                                                                    |
| 168 |     429.39549 |    591.430879 | Birgit Lang                                                                                                                                                           |
| 169 |     116.85751 |    546.231621 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                                      |
| 170 |     249.42131 |    130.902425 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 171 |    1001.85048 |    476.321538 | Zimices                                                                                                                                                               |
| 172 |     130.15447 |    503.906295 | T. Michael Keesey                                                                                                                                                     |
| 173 |     369.24821 |     35.993185 | Matt Martyniuk                                                                                                                                                        |
| 174 |     431.32198 |     48.690957 | L. Shyamal                                                                                                                                                            |
| 175 |     914.97602 |    657.003546 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 176 |     672.36671 |    746.842091 | Jagged Fang Designs                                                                                                                                                   |
| 177 |     706.96339 |    788.436838 | Chris huh                                                                                                                                                             |
| 178 |     869.13921 |    602.369861 | Michelle Site                                                                                                                                                         |
| 179 |      21.46008 |    517.141033 | Josefine Bohr Brask                                                                                                                                                   |
| 180 |     498.11073 |    450.651636 | T. Michael Keesey (after Marek Velechovský)                                                                                                                           |
| 181 |     451.99802 |    785.711707 | Steven Traver                                                                                                                                                         |
| 182 |     353.98533 |    680.003158 | NA                                                                                                                                                                    |
| 183 |      38.25413 |    570.791446 | Ferran Sayol                                                                                                                                                          |
| 184 |      82.68430 |    385.373522 | Gareth Monger                                                                                                                                                         |
| 185 |      92.71614 |    410.086091 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 186 |      27.57631 |    729.580518 | NA                                                                                                                                                                    |
| 187 |     866.69812 |    666.139718 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                              |
| 188 |     228.40518 |    265.127727 | Christine Axon                                                                                                                                                        |
| 189 |     513.78255 |    568.811745 | Emily Jane McTavish, from Haeckel, E. H. P. A. (1904).Kunstformen der Natur. Bibliographisches                                                                        |
| 190 |     814.59586 |    381.509530 | Scott Hartman                                                                                                                                                         |
| 191 |     471.62345 |    721.476127 | T. Michael Keesey                                                                                                                                                     |
| 192 |     233.10948 |     27.745507 | Steven Traver                                                                                                                                                         |
| 193 |     991.75836 |    444.236663 | Frank Förster                                                                                                                                                         |
| 194 |      86.14984 |    131.728746 | Ghedoghedo, vectorized by Zimices                                                                                                                                     |
| 195 |      60.33868 |     64.231806 | T. Michael Keesey                                                                                                                                                     |
| 196 |     272.26888 |    146.559937 | Steven Coombs                                                                                                                                                         |
| 197 |     652.92198 |    686.461173 | Collin Gross                                                                                                                                                          |
| 198 |     998.79581 |    775.351929 | Matt Crook                                                                                                                                                            |
| 199 |    1003.29139 |    604.534167 | Roberto Díaz Sibaja                                                                                                                                                   |
| 200 |     905.24391 |    672.568027 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 201 |     334.76428 |     36.196416 | Iain Reid                                                                                                                                                             |
| 202 |     876.85451 |    105.219155 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 203 |     399.22283 |    405.898417 | NA                                                                                                                                                                    |
| 204 |     544.50337 |    768.551818 | Kent Elson Sorgon                                                                                                                                                     |
| 205 |     106.57164 |    472.431873 | T. Michael Keesey (photo by Bc999 \[Black crow\])                                                                                                                     |
| 206 |     989.04422 |    626.543857 | Zimices                                                                                                                                                               |
| 207 |     161.33186 |    234.716125 | Melissa Broussard                                                                                                                                                     |
| 208 |     509.01726 |    766.139598 | Ferran Sayol                                                                                                                                                          |
| 209 |     453.31484 |     11.254269 | Steven Traver                                                                                                                                                         |
| 210 |     611.66430 |    563.769565 | Maija Karala                                                                                                                                                          |
| 211 |     511.47258 |    383.528857 | Birgit Lang                                                                                                                                                           |
| 212 |     984.52422 |    581.133042 | Henry Lydecker                                                                                                                                                        |
| 213 |     302.22471 |    154.432412 | Jagged Fang Designs                                                                                                                                                   |
| 214 |     399.47072 |    437.528958 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 215 |     936.78662 |     21.369294 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 216 |     710.65357 |    663.683520 | Jagged Fang Designs                                                                                                                                                   |
| 217 |     167.68660 |    481.480345 | Margot Michaud                                                                                                                                                        |
| 218 |      54.12839 |     14.530650 | Zimices                                                                                                                                                               |
| 219 |     212.76078 |    156.302679 | Yan Wong                                                                                                                                                              |
| 220 |     873.40248 |    121.378332 | Iain Reid                                                                                                                                                             |
| 221 |     134.88469 |    222.864570 | Margot Michaud                                                                                                                                                        |
| 222 |     658.65329 |    469.048556 | T. Michael Keesey                                                                                                                                                     |
| 223 |     215.92348 |    381.766091 | Lukasiniho                                                                                                                                                            |
| 224 |     423.64112 |    513.546612 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 225 |     159.04923 |    122.250111 | Mathieu Basille                                                                                                                                                       |
| 226 |     220.78697 |     80.094060 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                    |
| 227 |     652.77397 |    563.280270 | T. Michael Keesey (after Joseph Wolf)                                                                                                                                 |
| 228 |     242.63943 |    401.944488 | Matt Crook                                                                                                                                                            |
| 229 |     208.21775 |    419.109988 | Shyamal                                                                                                                                                               |
| 230 |     370.91597 |    211.512024 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 231 |     451.53658 |    726.946351 | Ewald Rübsamen                                                                                                                                                        |
| 232 |    1006.17481 |    361.152450 | Birgit Lang                                                                                                                                                           |
| 233 |     543.52229 |    593.187882 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 234 |     364.68152 |    601.800566 | Matt Crook                                                                                                                                                            |
| 235 |     146.45968 |    311.222011 | Christoph Schomburg                                                                                                                                                   |
| 236 |     109.18161 |    124.237891 | Lukasiniho                                                                                                                                                            |
| 237 |     277.41412 |    375.470748 | NA                                                                                                                                                                    |
| 238 |     495.80914 |    797.962218 | Smokeybjb                                                                                                                                                             |
| 239 |      14.99954 |    342.315292 | Maxime Dahirel                                                                                                                                                        |
| 240 |     153.74076 |    723.012660 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 241 |     516.86800 |    740.691503 | Scott Hartman                                                                                                                                                         |
| 242 |     112.05570 |    320.712239 | Zimices                                                                                                                                                               |
| 243 |     415.07027 |    194.165245 | Zimices                                                                                                                                                               |
| 244 |     418.01124 |    376.844466 | Julio Garza                                                                                                                                                           |
| 245 |     273.19473 |    337.839199 | Collin Gross                                                                                                                                                          |
| 246 |     627.01601 |    643.971895 | Zimices                                                                                                                                                               |
| 247 |     751.90980 |    354.053614 | Zimices                                                                                                                                                               |
| 248 |     583.79060 |     28.335893 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 249 |     117.96070 |    252.383608 | Christoph Schomburg                                                                                                                                                   |
| 250 |     721.80948 |    675.545807 | Jagged Fang Designs                                                                                                                                                   |
| 251 |     892.18354 |    756.170712 | Ferran Sayol                                                                                                                                                          |
| 252 |     790.24235 |    293.834622 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                           |
| 253 |     893.94738 |    720.460896 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                    |
| 254 |     577.36226 |    631.181603 | Ferran Sayol                                                                                                                                                          |
| 255 |     760.12534 |    735.385586 | NA                                                                                                                                                                    |
| 256 |     407.00592 |    168.359624 | Fritz Geller-Grimm (vectorized by T. Michael Keesey)                                                                                                                  |
| 257 |     458.48788 |    600.168314 | Matt Crook                                                                                                                                                            |
| 258 |     337.41616 |    466.100575 | SecretJellyMan - from Mason McNair                                                                                                                                    |
| 259 |     526.81547 |     86.788492 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 260 |     549.23609 |    313.926128 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 261 |     313.65153 |    479.148466 | Zimices                                                                                                                                                               |
| 262 |     910.23458 |    172.674569 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 263 |     196.88713 |     52.790996 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 264 |     306.98729 |    550.262156 | Kimberly Haddrell                                                                                                                                                     |
| 265 |     985.03183 |    202.750892 | wsnaccad                                                                                                                                                              |
| 266 |     396.72717 |    141.904184 | Steven Traver                                                                                                                                                         |
| 267 |      17.97886 |     17.460178 | Emily Willoughby                                                                                                                                                      |
| 268 |     928.70262 |    690.707698 | Tasman Dixon                                                                                                                                                          |
| 269 |     999.90719 |    683.146986 | Blanco et al., 2014, vectorized by Zimices                                                                                                                            |
| 270 |      16.93819 |    576.424872 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 271 |     609.44837 |     25.624499 | Shyamal                                                                                                                                                               |
| 272 |     919.27065 |    496.158683 | Eduard Solà Vázquez, vectorised by Yan Wong                                                                                                                           |
| 273 |     999.14584 |    283.320268 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                         |
| 274 |     822.94388 |    559.523229 | Iain Reid                                                                                                                                                             |
| 275 |     997.09929 |    139.580706 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 276 |     648.83968 |    372.600267 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                          |
| 277 |      19.72246 |    172.423207 | Scott Hartman                                                                                                                                                         |
| 278 |     952.45680 |    274.909721 | Dmitry Bogdanov                                                                                                                                                       |
| 279 |     162.83207 |    734.984544 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 280 |     977.65546 |    433.600875 | Chris huh                                                                                                                                                             |
| 281 |     999.53569 |    170.593449 | Oscar Sanisidro                                                                                                                                                       |
| 282 |     744.90854 |    240.975582 | NA                                                                                                                                                                    |
| 283 |     496.09955 |    248.029845 | NA                                                                                                                                                                    |
| 284 |    1002.11112 |    458.541172 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                        |
| 285 |      33.40922 |    455.772267 | Rebecca Groom                                                                                                                                                         |
| 286 |     695.18098 |    407.639376 | Chris huh                                                                                                                                                             |
| 287 |     500.61692 |    669.339605 | Harold N Eyster                                                                                                                                                       |
| 288 |     503.58439 |     36.309874 | David Orr                                                                                                                                                             |
| 289 |     895.88262 |    644.386243 | Milton Tan                                                                                                                                                            |
| 290 |     801.05537 |    475.193853 | Margot Michaud                                                                                                                                                        |
| 291 |     776.58822 |    784.896008 | NA                                                                                                                                                                    |
| 292 |      18.36690 |     49.915818 | Michael Scroggie                                                                                                                                                      |
| 293 |     407.06584 |    538.771481 | Xavier A. Jenkins, Gabriel Ugueto                                                                                                                                     |
| 294 |     796.43734 |    796.841927 | Smokeybjb                                                                                                                                                             |
| 295 |     821.53555 |    400.944162 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                       |
| 296 |     716.95569 |    521.545002 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                              |
| 297 |     898.91162 |     31.533976 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 298 |     282.51464 |     20.417672 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 299 |     503.04516 |    361.663312 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey       |
| 300 |     566.67509 |    653.064501 | NA                                                                                                                                                                    |
| 301 |     591.77924 |    270.022469 | Peter Coxhead                                                                                                                                                         |
| 302 |     882.02543 |    689.477591 | Matt Martyniuk                                                                                                                                                        |
| 303 |     185.28055 |    275.494265 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                              |
| 304 |      52.50483 |    199.898473 | Margot Michaud                                                                                                                                                        |
| 305 |     403.84938 |    110.805063 | Jagged Fang Designs                                                                                                                                                   |
| 306 |     290.17866 |    464.653991 | Gareth Monger                                                                                                                                                         |
| 307 |     320.10391 |     14.187260 | Scott Hartman                                                                                                                                                         |
| 308 |     730.64452 |    276.681534 | wsnaccad                                                                                                                                                              |
| 309 |     807.54435 |    323.161129 | Gareth Monger                                                                                                                                                         |
| 310 |     276.80750 |    307.685824 | Ferran Sayol                                                                                                                                                          |
| 311 |     214.92198 |    125.179811 | Maija Karala                                                                                                                                                          |
| 312 |     857.12255 |    560.529401 | NA                                                                                                                                                                    |
| 313 |     742.90589 |    482.997625 | Zimices                                                                                                                                                               |
| 314 |     628.18908 |     66.708992 | Alex Slavenko                                                                                                                                                         |
| 315 |     433.07452 |    769.393314 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                             |
| 316 |      47.15729 |    235.407755 | Gareth Monger                                                                                                                                                         |
| 317 |     861.71774 |    128.081774 | Iain Reid                                                                                                                                                             |
| 318 |     473.86145 |    470.984931 | T. Michael Keesey                                                                                                                                                     |
| 319 |     790.18811 |    545.474351 | NA                                                                                                                                                                    |
| 320 |     825.15146 |    574.929641 | Katie S. Collins                                                                                                                                                      |
| 321 |     684.02946 |    171.553698 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 322 |     895.09890 |    520.703765 | Jessica Anne Miller                                                                                                                                                   |
| 323 |     759.61306 |    673.494170 | Caleb M. Brown                                                                                                                                                        |
| 324 |     514.93331 |    787.634711 | Dean Schnabel                                                                                                                                                         |
| 325 |     113.45737 |    379.798616 | Rebecca Groom                                                                                                                                                         |
| 326 |     735.26183 |    298.901232 | Matt Crook                                                                                                                                                            |
| 327 |     224.78537 |    657.494277 | NA                                                                                                                                                                    |
| 328 |     862.37369 |    405.458984 | Zimices                                                                                                                                                               |
| 329 |     381.63620 |    209.936043 | T. Michael Keesey                                                                                                                                                     |
| 330 |     138.66589 |    717.223726 | Scott Hartman                                                                                                                                                         |
| 331 |      29.58957 |    502.309330 | Gareth Monger                                                                                                                                                         |
| 332 |     685.16196 |    348.020578 | Warren H (photography), T. Michael Keesey (vectorization)                                                                                                             |
| 333 |     975.57318 |    396.008420 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 334 |     531.59404 |     35.040609 | Beth Reinke                                                                                                                                                           |
| 335 |     836.04797 |     56.585094 | Ferran Sayol                                                                                                                                                          |
| 336 |     311.33518 |    259.884557 | Zimices                                                                                                                                                               |
| 337 |     685.25391 |    766.910271 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
| 338 |     168.01252 |    347.687105 | T. Michael Keesey (after Tillyard)                                                                                                                                    |
| 339 |     769.14705 |    710.281857 | C. Camilo Julián-Caballero                                                                                                                                            |
| 340 |     135.30101 |    337.158700 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 341 |     298.67062 |    627.451402 | Scott Hartman                                                                                                                                                         |
| 342 |     813.31256 |    153.934282 | Michael Scroggie                                                                                                                                                      |
| 343 |     446.25156 |    501.575509 | Gareth Monger                                                                                                                                                         |
| 344 |     534.63034 |     65.906570 | Chris huh                                                                                                                                                             |
| 345 |      66.66418 |    608.107643 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                       |
| 346 |     262.77977 |    580.836244 | Beth Reinke                                                                                                                                                           |
| 347 |     381.28125 |    120.523307 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                       |
| 348 |     938.57780 |    172.345794 | Scott Hartman                                                                                                                                                         |
| 349 |     976.64920 |    347.337383 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 350 |     928.58072 |    256.924128 | Henry Lydecker                                                                                                                                                        |
| 351 |      51.83888 |    550.951992 | Matt Crook                                                                                                                                                            |
| 352 |     661.83163 |    160.568755 | Rene Martin                                                                                                                                                           |
| 353 |     717.38515 |    689.172273 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 354 |     668.44481 |    393.141997 | Mathew Wedel                                                                                                                                                          |
| 355 |     701.33354 |    115.984611 | T. Michael Keesey                                                                                                                                                     |
| 356 |     494.55700 |    436.948361 | M Kolmann                                                                                                                                                             |
| 357 |     720.25810 |    257.483772 | Tasman Dixon                                                                                                                                                          |
| 358 |     447.30274 |    290.732769 | Matt Crook                                                                                                                                                            |
| 359 |     202.34835 |    442.379221 | Jagged Fang Designs                                                                                                                                                   |
| 360 |      36.08984 |    590.472954 | Christoph Schomburg                                                                                                                                                   |
| 361 |     663.92473 |    411.747298 | Jagged Fang Designs                                                                                                                                                   |
| 362 |     882.85180 |    143.759739 | Ferran Sayol                                                                                                                                                          |
| 363 |     554.83948 |    790.205132 | Anthony Caravaggi                                                                                                                                                     |
| 364 |     518.61276 |    315.657822 | NA                                                                                                                                                                    |
| 365 |     582.80845 |     90.250245 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                     |
| 366 |     731.53867 |    569.513749 | T. Michael Keesey                                                                                                                                                     |
| 367 |     649.65241 |    311.903526 | Jesús Gómez, vectorized by Zimices                                                                                                                                    |
| 368 |     518.44971 |    259.872265 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                           |
| 369 |     920.61090 |    751.500350 | Tasman Dixon                                                                                                                                                          |
| 370 |     152.27450 |    594.359040 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                         |
| 371 |     252.24349 |    305.659327 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                       |
| 372 |     486.51413 |    342.202953 | Tyler Greenfield                                                                                                                                                      |
| 373 |      18.73092 |    382.403677 | Michael Scroggie                                                                                                                                                      |
| 374 |     946.28778 |    631.458926 | M Kolmann                                                                                                                                                             |
| 375 |     957.16452 |    422.271010 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 376 |      28.37372 |    429.281519 | Matt Crook                                                                                                                                                            |
| 377 |     844.63716 |    377.590184 | C. Camilo Julián-Caballero                                                                                                                                            |
| 378 |     261.01261 |     82.736594 | Chris huh                                                                                                                                                             |
| 379 |     528.95940 |    442.031770 | Heinrich Harder (vectorized by T. Michael Keesey)                                                                                                                     |
| 380 |     768.98471 |      9.722882 | AnAgnosticGod (vectorized by T. Michael Keesey)                                                                                                                       |
| 381 |      28.09767 |    795.708229 | Scott Hartman                                                                                                                                                         |
| 382 |     972.87864 |    452.789216 | Alex Slavenko                                                                                                                                                         |
| 383 |     837.67464 |    642.601502 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                       |
| 384 |     212.45989 |    323.087927 | Jonathan Wells                                                                                                                                                        |
| 385 |     417.65793 |    324.297907 | NA                                                                                                                                                                    |
| 386 |    1005.46944 |    253.755142 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                         |
| 387 |     599.39786 |    305.493429 | Iain Reid                                                                                                                                                             |
| 388 |     742.53372 |    100.595074 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 389 |     889.40339 |    195.850628 | NA                                                                                                                                                                    |
| 390 |     135.83943 |      4.308222 | Scott Hartman                                                                                                                                                         |
| 391 |     531.00238 |    299.880453 | Siobhon Egan                                                                                                                                                          |
| 392 |     282.14123 |    138.060739 | Ghedo and T. Michael Keesey                                                                                                                                           |
| 393 |     340.98113 |    590.681883 | Kamil S. Jaron                                                                                                                                                        |
| 394 |     318.64479 |    578.264693 | Zimices                                                                                                                                                               |
| 395 |     601.02925 |    654.117570 | Andrew A. Farke                                                                                                                                                       |
| 396 |     534.75463 |    779.823260 | Scott Hartman                                                                                                                                                         |
| 397 |     846.20431 |    532.902500 | Harold N Eyster                                                                                                                                                       |
| 398 |      89.76547 |     15.057669 | Sarah Werning                                                                                                                                                         |
| 399 |     394.48154 |    767.733569 | Tasman Dixon                                                                                                                                                          |
| 400 |     871.81550 |    646.051158 | T. Michael Keesey                                                                                                                                                     |
| 401 |     874.26040 |    728.079383 | Mathilde Cordellier                                                                                                                                                   |
| 402 |     635.85292 |    619.008264 | Tasman Dixon                                                                                                                                                          |
| 403 |     908.61319 |      6.700735 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 404 |     545.81737 |    254.090358 | Scott Hartman                                                                                                                                                         |
| 405 |     818.55253 |    740.297574 | Matt Crook                                                                                                                                                            |
| 406 |     574.42042 |    280.854824 | Margot Michaud                                                                                                                                                        |
| 407 |     139.96559 |    418.435609 | Margot Michaud                                                                                                                                                        |
| 408 |     235.17536 |    392.522931 | Jack Mayer Wood                                                                                                                                                       |
| 409 |     811.55610 |    235.851984 | Sarah Werning                                                                                                                                                         |
| 410 |     855.44396 |    358.987745 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                           |
| 411 |      35.64405 |    182.651120 | Natasha Vitek                                                                                                                                                         |
| 412 |     643.34343 |    200.281734 | Chris huh                                                                                                                                                             |
| 413 |     280.11127 |    493.268779 | Gopal Murali                                                                                                                                                          |
| 414 |     489.36271 |    238.195618 | Chris huh                                                                                                                                                             |
| 415 |     754.79748 |     55.016968 | Tasman Dixon                                                                                                                                                          |
| 416 |     209.14563 |      5.526829 | M Kolmann                                                                                                                                                             |
| 417 |     298.98586 |    281.570971 | Arthur S. Brum                                                                                                                                                        |
| 418 |     967.73156 |    136.034468 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
| 419 |     977.78997 |    420.320588 | C. Camilo Julián-Caballero                                                                                                                                            |
| 420 |     346.41597 |      9.067526 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 421 |     655.36426 |    352.373025 | C. Camilo Julián-Caballero                                                                                                                                            |
| 422 |      25.03963 |     29.158432 | Margot Michaud                                                                                                                                                        |
| 423 |     465.57354 |    456.696693 | Julio Garza                                                                                                                                                           |
| 424 |     206.73659 |    590.834679 | Gareth Monger                                                                                                                                                         |
| 425 |      72.14723 |    103.078662 | T. Michael Keesey                                                                                                                                                     |
| 426 |     778.26707 |    312.601354 | Ferran Sayol                                                                                                                                                          |
| 427 |     126.85753 |    464.793146 | Chris huh                                                                                                                                                             |
| 428 |     228.06011 |    368.562349 | Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization)                                                                                                |
| 429 |     673.87195 |    113.270197 | Nicolas Huet le Jeune and Jean-Gabriel Prêtre (vectorized by T. Michael Keesey)                                                                                       |
| 430 |     539.62256 |    427.792697 | Zimices                                                                                                                                                               |
| 431 |     939.69165 |    476.112046 | Tony Ayling                                                                                                                                                           |
| 432 |     742.03958 |    389.556759 | Iain Reid                                                                                                                                                             |
| 433 |     504.45708 |    470.071603 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 434 |     101.92483 |    619.958960 | Birgit Lang                                                                                                                                                           |
| 435 |     390.71278 |    691.311309 | Christine Axon                                                                                                                                                        |
| 436 |     745.70342 |    625.553158 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 437 |     219.60782 |    797.761993 | Smokeybjb                                                                                                                                                             |
| 438 |     383.52174 |    152.288188 | Joanna Wolfe                                                                                                                                                          |
| 439 |     301.56427 |    378.599750 | Steven Traver                                                                                                                                                         |
| 440 |     375.61407 |    714.630850 | Sarah Werning                                                                                                                                                         |
| 441 |     361.15510 |    793.975934 | Gareth Monger                                                                                                                                                         |
| 442 |     462.35792 |    257.325753 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 443 |    1017.76669 |    527.455621 | DW Bapst (modified from Bates et al., 2005)                                                                                                                           |
| 444 |     847.52335 |    762.178988 | Matt Crook                                                                                                                                                            |
| 445 |     723.35019 |    629.062981 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 446 |     335.60053 |    614.852736 | Charles R. Knight, vectorized by Zimices                                                                                                                              |
| 447 |     854.00711 |    506.018604 | Jagged Fang Designs                                                                                                                                                   |
| 448 |     613.16463 |     36.353145 | Chris huh                                                                                                                                                             |
| 449 |     799.59059 |    567.400777 | Nobu Tamura                                                                                                                                                           |
| 450 |     295.78185 |    163.642779 | Scott Hartman                                                                                                                                                         |
| 451 |     584.22215 |    787.868052 | Margot Michaud                                                                                                                                                        |
| 452 |     126.34346 |    637.192267 | Gareth Monger                                                                                                                                                         |
| 453 |     910.06684 |    794.155417 | Chris huh                                                                                                                                                             |
| 454 |     314.96975 |    145.990348 | Iain Reid                                                                                                                                                             |
| 455 |    1006.00552 |    195.631997 | Zimices                                                                                                                                                               |
| 456 |     612.94587 |    292.494155 | NA                                                                                                                                                                    |
| 457 |    1010.70131 |    641.387867 | Gareth Monger                                                                                                                                                         |
| 458 |     381.58682 |    173.725678 | Mark Hofstetter (vectorized by T. Michael Keesey)                                                                                                                     |
| 459 |     779.19142 |     28.181219 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 460 |     232.55175 |    463.109305 | Scott Hartman                                                                                                                                                         |
| 461 |     177.49891 |     32.103074 | Noah Schlottman                                                                                                                                                       |
| 462 |     789.41284 |    420.787098 | T. Michael Keesey                                                                                                                                                     |
| 463 |     286.36774 |    716.033306 | NA                                                                                                                                                                    |
| 464 |     694.30658 |    682.122607 | NA                                                                                                                                                                    |
| 465 |     191.37771 |    458.784116 | Gareth Monger                                                                                                                                                         |
| 466 |      24.97695 |     66.191546 | NA                                                                                                                                                                    |
| 467 |     642.07594 |    792.939158 | C. Abraczinskas                                                                                                                                                       |
| 468 |     693.38182 |    714.790934 | Ferran Sayol                                                                                                                                                          |
| 469 |     386.42289 |    584.434198 | Gareth Monger                                                                                                                                                         |
| 470 |     416.05943 |    210.605612 | Zimices                                                                                                                                                               |
| 471 |     891.13836 |    615.717038 | Nobu Tamura                                                                                                                                                           |
| 472 |    1007.77234 |    113.320943 | Darius Nau                                                                                                                                                            |
| 473 |     811.57698 |     74.513995 | Tauana J. Cunha                                                                                                                                                       |
| 474 |     857.87368 |    580.567020 | Steven Traver                                                                                                                                                         |
| 475 |     531.55932 |    546.889216 | Steven Traver                                                                                                                                                         |
| 476 |     595.25198 |    574.701699 | Yan Wong                                                                                                                                                              |
| 477 |     390.82797 |    678.962156 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 478 |     961.71809 |    561.831656 | Margot Michaud                                                                                                                                                        |
| 479 |     296.80630 |    573.203365 | Chris huh                                                                                                                                                             |
| 480 |      63.50690 |    243.378002 | Matt Crook                                                                                                                                                            |
| 481 |     755.93741 |    639.046172 | Steven Traver                                                                                                                                                         |
| 482 |    1007.70069 |    426.330679 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                  |
| 483 |     807.38737 |    354.067859 | Julia B McHugh                                                                                                                                                        |
| 484 |    1005.21972 |    381.777605 | Zimices                                                                                                                                                               |
| 485 |     337.58438 |    228.821270 | Shyamal                                                                                                                                                               |
| 486 |     163.52620 |    281.438416 | Jessica Anne Miller                                                                                                                                                   |
| 487 |     507.73474 |    326.544918 | Pete Buchholz                                                                                                                                                         |
| 488 |     290.24629 |    320.687688 | Gareth Monger                                                                                                                                                         |
| 489 |      74.88203 |    399.226769 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                                 |
| 490 |     915.68664 |    417.489304 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 491 |     243.32457 |    792.127495 | Steven Traver                                                                                                                                                         |
| 492 |     740.61151 |    661.561249 | Jagged Fang Designs                                                                                                                                                   |
| 493 |     781.28433 |    119.542010 | Andrew A. Farke                                                                                                                                                       |
| 494 |     461.11289 |     33.711697 | Mathew Wedel                                                                                                                                                          |
| 495 |     595.83664 |    616.069418 | Crystal Maier                                                                                                                                                         |
| 496 |     455.99605 |    498.401072 | Gareth Monger                                                                                                                                                         |
| 497 |     550.16324 |     72.740027 | Beth Reinke                                                                                                                                                           |
| 498 |     198.50275 |    789.893068 | nicubunu                                                                                                                                                              |
| 499 |     376.03920 |     13.380314 | Gareth Monger                                                                                                                                                         |
| 500 |     403.30530 |    569.645179 | Xavier Giroux-Bougard                                                                                                                                                 |
| 501 |     363.01182 |    369.414805 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 502 |     959.48071 |    230.286999 | Chris huh                                                                                                                                                             |
| 503 |    1018.46013 |    308.325753 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                         |
| 504 |     984.00169 |    732.104168 | T. Michael Keesey                                                                                                                                                     |
| 505 |     468.37811 |    624.545990 | Cesar Julian                                                                                                                                                          |
| 506 |     324.61326 |    741.518025 | Scott Hartman                                                                                                                                                         |
| 507 |     439.73814 |    211.648853 | Steven Traver                                                                                                                                                         |
| 508 |     967.70454 |    116.433262 | Mathilde Cordellier                                                                                                                                                   |
| 509 |     998.25977 |    270.792456 | Lauren Sumner-Rooney                                                                                                                                                  |
| 510 |     943.10217 |    759.110482 | B. Duygu Özpolat                                                                                                                                                      |
| 511 |     626.94287 |    241.879167 | Margot Michaud                                                                                                                                                        |
| 512 |     839.31668 |    752.236846 | Christoph Schomburg                                                                                                                                                   |
| 513 |     933.10482 |    468.749509 | M Kolmann                                                                                                                                                             |
| 514 |     209.76441 |    634.579638 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 515 |     254.87594 |    369.087699 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                       |
| 516 |     412.31783 |      8.131235 | Dmitry Bogdanov                                                                                                                                                       |
| 517 |     445.51730 |     53.459509 | Matt Crook                                                                                                                                                            |
| 518 |     856.96562 |    699.769889 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                             |
| 519 |     131.73265 |    704.063258 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 520 |      80.13096 |    490.746598 | Scott Hartman                                                                                                                                                         |

    #> Your tweet has been posted!
