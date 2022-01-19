
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

Steven Coombs, Gabriela Palomo-Munoz, Sarah Alewijnse, DW Bapst
(modified from Mitchell 1990), Darren Naish (vectorize by T. Michael
Keesey), Steven Traver, Terpsichores, Chuanixn Yu, Jagged Fang Designs,
Zimices, Daniel Stadtmauer, Matt Crook, Oliver Voigt, T. Michael Keesey,
Maxwell Lefroy (vectorized by T. Michael Keesey), Gareth Monger, Chloé
Schmidt, Margot Michaud, J. J. Harrison (photo) & T. Michael Keesey,
Michelle Site, Robert Bruce Horsfall, from W.B. Scott’s 1912 “A History
of Land Mammals in the Western Hemisphere”, Steven Haddock
• Jellywatch.org, Dean Schnabel, Emily Willoughby, H. F. O. March
(vectorized by T. Michael Keesey), Birgit Lang, Felix Vaux, Filip em,
Ferran Sayol, Maxime Dahirel, Juan Carlos Jerí, Dmitry Bogdanov
(vectorized by T. Michael Keesey), Theodore W. Pietsch (photography) and
T. Michael Keesey (vectorization), Tracy A. Heath, Andrew A. Farke, Noah
Schlottman, photo by Casey Dunn, Chris huh, FunkMonk, T. Michael Keesey
(after Walker & al.), Dianne Bray / Museum Victoria (vectorized by T.
Michael Keesey), Markus A. Grohme, Ignacio Contreras, Smith609 and T.
Michael Keesey, Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti,
Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G.
Barraclough (vectorized by T. Michael Keesey), Collin Gross, Scott
Hartman, Nobu Tamura (vectorized by T. Michael Keesey), Joseph J. W.
Sertich, Mark A. Loewen, Dexter R. Mardis, Kamil S. Jaron, terngirl, L.
Shyamal, Darren Naish (vectorized by T. Michael Keesey), Tommaso
Cancellario, Jaime Headden, Tim H. Heupink, Leon Huynen, and David M.
Lambert (vectorized by T. Michael Keesey), Sean McCann, Pete Buchholz,
Ghedoghedo (vectorized by T. Michael Keesey), Beth Reinke, Richard J.
Harris, xgirouxb, Aleksey Nagovitsyn (vectorized by T. Michael Keesey),
mystica, Armin Reindl, Ben Moon, Tauana J. Cunha, Catherine Yasuda,
Becky Barnes, Chase Brownstein, Matt Martyniuk, Jose Carlos
Arenas-Monroy, Smokeybjb, C. Camilo Julián-Caballero, Taenadoman, Tess
Linden, Anthony Caravaggi, Crystal Maier, Hanyong Pu, Yoshitsugu
Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang,
Songhai Jia & T. Michael Keesey, Inessa Voet, Pranav Iyer (grey ideas),
Dave Angelini, Griensteidl and T. Michael Keesey, André Karwath
(vectorized by T. Michael Keesey), Steve Hillebrand/U. S. Fish and
Wildlife Service (source photo), T. Michael Keesey (vectorization),
Cathy, Fernando Carezzano, Rebecca Groom, T. Michael Keesey (after
Tillyard), Bennet McComish, photo by Avenue, Frank Förster, Tasman
Dixon, B Kimmel, Kanchi Nanjo, Katie S. Collins, Robbie N. Cada
(modified by T. Michael Keesey), Jaime Headden (vectorized by T. Michael
Keesey), Francisco Gascó (modified by Michael P. Taylor), Sharon
Wegner-Larsen, Myriam\_Ramirez, Mathew Wedel, Obsidian Soul (vectorized
by T. Michael Keesey), Caleb M. Brown, Rafael Maia, Christoph Schomburg,
Yan Wong, Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by
Maxime Dahirel), Ville-Veikko Sinkkonen, Amanda Katzer, Christian A.
Masnaghetti, Julia B McHugh, Darius Nau, Iain Reid, Kai R. Caspar,
Falconaumanni and T. Michael Keesey, Robert Bruce Horsfall, vectorized
by Zimices, Sarah Werning, Ian Burt (original) and T. Michael Keesey
(vectorization), Wynston Cooper (photo) and Albertonykus (silhouette),
Alex Slavenko, Charles R. Knight, vectorized by Zimices, T. Michael
Keesey (after Joseph Wolf), M Kolmann, Roberto Díaz Sibaja, Mali’o
Kodis, photograph by Hans Hillewaert, Ghedoghedo, vectorized by Zimices,
Christine Axon, Nobu Tamura, Maija Karala, Plukenet, C. W. Nash
(illustration) and Timothy J. Bartley (silhouette), Benchill, Fernando
Campos De Domenico, Jack Mayer Wood, Julie Blommaert based on photo by
Sofdrakou, Geoff Shaw, Noah Schlottman, photo from Casey Dunn, Shyamal,
CNZdenek, T. Michael Keesey (vector) and Stuart Halliday (photograph),
Dmitry Bogdanov, Matt Martyniuk (modified by T. Michael Keesey),
Alexander Schmidt-Lebuhn, Andreas Preuss / marauder, Mali’o Kodis,
photograph by Bruno Vellutini, Tambja (vectorized by T. Michael Keesey),
Xavier Giroux-Bougard, Espen Horn (model; vectorized by T. Michael
Keesey from a photo by H. Zell), Sherman Foote Denton (illustration,
1897) and Timothy J. Bartley (silhouette), Javier Luque, Tyler
Greenfield, Jean-Raphaël Guillaumin (photography) and T. Michael Keesey
(vectorization), Nina Skinner, Nobu Tamura, vectorized by Zimices, Young
and Zhao (1972:figure 4), modified by Michael P. Taylor, Agnello
Picorelli, Baheerathan Murugavel, Christina N. Hodson, Florian Pfaff, E.
D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J.
Wedel), Mariana Ruiz Villarreal (modified by T. Michael Keesey),
Scarlet23 (vectorized by T. Michael Keesey), G. M. Woodward, Bennet
McComish, photo by Hans Hillewaert, FJDegrange, Mathilde Cordellier, I.
Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey), Meliponicultor
Itaymbere, Original photo by Andrew Murray, vectorized by Roberto Díaz
Sibaja, Henry Lydecker, Josefine Bohr Brask, Gustav Mützel, T. Michael
Keesey (photo by Darren Swim), Matt Dempsey, DW Bapst (Modified from
photograph taken by Charles Mitchell), Lip Kee Yap (vectorized by T.
Michael Keesey), James R. Spotila and Ray Chatterji, John Conway, Cyril
Matthey-Doret, adapted from Bernard Chaubet, Yan Wong from illustration
by Jules Richard (1907), Mali’o Kodis, photograph by P. Funch and R.M.
Kristensen, DW Bapst (modified from Bates et al., 2005), Tyler McCraney,
Nobu Tamura (modified by T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    580.799314 |    131.600151 | Steven Coombs                                                                                                                                                         |
|   2 |    687.735732 |    739.207791 | Gabriela Palomo-Munoz                                                                                                                                                 |
|   3 |    139.538684 |    587.105917 | Sarah Alewijnse                                                                                                                                                       |
|   4 |     97.836546 |    432.457336 | DW Bapst (modified from Mitchell 1990)                                                                                                                                |
|   5 |    918.470450 |    629.118254 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
|   6 |    661.171947 |     45.015438 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
|   7 |    801.132714 |    678.749535 | NA                                                                                                                                                                    |
|   8 |    247.612237 |     67.245359 | NA                                                                                                                                                                    |
|   9 |    812.945877 |    186.818259 | Steven Traver                                                                                                                                                         |
|  10 |    382.660581 |    125.176824 | Terpsichores                                                                                                                                                          |
|  11 |    648.547876 |    608.738571 | Chuanixn Yu                                                                                                                                                           |
|  12 |    454.034461 |    214.883714 | Jagged Fang Designs                                                                                                                                                   |
|  13 |    363.417938 |    395.143437 | Zimices                                                                                                                                                               |
|  14 |    486.095854 |     74.502066 | Jagged Fang Designs                                                                                                                                                   |
|  15 |    614.145982 |    500.027984 | Jagged Fang Designs                                                                                                                                                   |
|  16 |    828.700352 |    762.661284 | Daniel Stadtmauer                                                                                                                                                     |
|  17 |    478.635984 |    701.142199 | Matt Crook                                                                                                                                                            |
|  18 |    938.979586 |    491.219682 | Oliver Voigt                                                                                                                                                          |
|  19 |    868.949875 |    365.390928 | T. Michael Keesey                                                                                                                                                     |
|  20 |    356.159197 |    295.483525 | Zimices                                                                                                                                                               |
|  21 |    376.354108 |    660.969655 | NA                                                                                                                                                                    |
|  22 |    199.971459 |    728.940946 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
|  23 |    788.176978 |    456.946503 | Gareth Monger                                                                                                                                                         |
|  24 |    790.442727 |    535.564944 | Matt Crook                                                                                                                                                            |
|  25 |     96.301107 |    102.410485 | Chloé Schmidt                                                                                                                                                         |
|  26 |    273.893259 |    232.236809 | Zimices                                                                                                                                                               |
|  27 |    961.768169 |    700.517681 | Jagged Fang Designs                                                                                                                                                   |
|  28 |    157.616770 |    332.109437 | Margot Michaud                                                                                                                                                        |
|  29 |    645.911976 |    370.305973 | Zimices                                                                                                                                                               |
|  30 |    605.619552 |    272.505886 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                            |
|  31 |    958.098004 |    356.500805 | Michelle Site                                                                                                                                                         |
|  32 |    147.556059 |    280.743230 | T. Michael Keesey                                                                                                                                                     |
|  33 |    523.275182 |    392.293055 | Robert Bruce Horsfall, from W.B. Scott’s 1912 “A History of Land Mammals in the Western Hemisphere”                                                                   |
|  34 |     60.664115 |    563.285135 | Steven Haddock • Jellywatch.org                                                                                                                                       |
|  35 |    267.323988 |    534.751468 | Dean Schnabel                                                                                                                                                         |
|  36 |     76.767235 |    775.494336 | Emily Willoughby                                                                                                                                                      |
|  37 |    717.849963 |    290.820235 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                      |
|  38 |     77.677550 |    693.722431 | Birgit Lang                                                                                                                                                           |
|  39 |    914.409567 |     38.800173 | Felix Vaux                                                                                                                                                            |
|  40 |    259.327241 |    791.225995 | Filip em                                                                                                                                                              |
|  41 |    936.393822 |    148.595486 | Steven Traver                                                                                                                                                         |
|  42 |    304.410461 |    720.139643 | Ferran Sayol                                                                                                                                                          |
|  43 |    233.200288 |    426.781885 | NA                                                                                                                                                                    |
|  44 |    831.769933 |     82.995303 | Maxime Dahirel                                                                                                                                                        |
|  45 |    605.643667 |    433.107984 | Juan Carlos Jerí                                                                                                                                                      |
|  46 |    638.662498 |    193.875716 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  47 |    473.325227 |    570.774846 | Steven Coombs                                                                                                                                                         |
|  48 |    488.993589 |    251.415505 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                               |
|  49 |    187.835910 |    178.337464 | Zimices                                                                                                                                                               |
|  50 |    454.097553 |    492.776096 | Tracy A. Heath                                                                                                                                                        |
|  51 |    731.915835 |    405.136508 | Matt Crook                                                                                                                                                            |
|  52 |    585.182963 |    724.213635 | Andrew A. Farke                                                                                                                                                       |
|  53 |    442.638485 |     59.794598 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
|  54 |     66.425645 |    242.915580 | Chris huh                                                                                                                                                             |
|  55 |    175.463985 |    594.733600 | FunkMonk                                                                                                                                                              |
|  56 |    124.420593 |     43.482072 | Michelle Site                                                                                                                                                         |
|  57 |     25.387442 |    393.606563 | T. Michael Keesey (after Walker & al.)                                                                                                                                |
|  58 |    499.888671 |     12.849757 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                       |
|  59 |    373.254166 |    528.351051 | Markus A. Grohme                                                                                                                                                      |
|  60 |    499.749083 |    607.916956 | Steven Traver                                                                                                                                                         |
|  61 |    499.909852 |    778.217370 | Markus A. Grohme                                                                                                                                                      |
|  62 |    686.686588 |    661.320336 | Ignacio Contreras                                                                                                                                                     |
|  63 |    167.415554 |    515.892335 | Smith609 and T. Michael Keesey                                                                                                                                        |
|  64 |    988.128535 |    155.346459 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
|  65 |    908.737205 |    551.840755 | Chris huh                                                                                                                                                             |
|  66 |    700.889624 |    225.767311 | Collin Gross                                                                                                                                                          |
|  67 |    595.625969 |    559.416312 | Emily Willoughby                                                                                                                                                      |
|  68 |    450.739950 |    120.102938 | Markus A. Grohme                                                                                                                                                      |
|  69 |    150.187612 |    221.874177 | Scott Hartman                                                                                                                                                         |
|  70 |     67.437520 |    167.210424 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  71 |    762.586233 |     27.144136 | T. Michael Keesey                                                                                                                                                     |
|  72 |    477.126886 |    319.503628 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                  |
|  73 |    687.822702 |    768.580289 | NA                                                                                                                                                                    |
|  74 |    434.713569 |    193.172372 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
|  75 |    309.048618 |    140.790083 | Birgit Lang                                                                                                                                                           |
|  76 |    507.390621 |    451.282741 | Chris huh                                                                                                                                                             |
|  77 |    264.551922 |    320.761617 | Matt Crook                                                                                                                                                            |
|  78 |    332.445074 |    470.088714 | Dexter R. Mardis                                                                                                                                                      |
|  79 |    248.475283 |    640.321187 | Kamil S. Jaron                                                                                                                                                        |
|  80 |    811.132928 |    395.823264 | NA                                                                                                                                                                    |
|  81 |    982.715940 |    430.701429 | Felix Vaux                                                                                                                                                            |
|  82 |    741.620008 |    600.311973 | NA                                                                                                                                                                    |
|  83 |     85.060704 |    629.072182 | Collin Gross                                                                                                                                                          |
|  84 |    602.612172 |     63.273318 | Margot Michaud                                                                                                                                                        |
|  85 |    582.205092 |    662.495745 | Dean Schnabel                                                                                                                                                         |
|  86 |    840.742924 |     12.058541 | Ignacio Contreras                                                                                                                                                     |
|  87 |    694.705079 |    536.585502 | Jagged Fang Designs                                                                                                                                                   |
|  88 |    175.397619 |    119.655273 | terngirl                                                                                                                                                              |
|  89 |     33.447519 |    489.198175 | T. Michael Keesey                                                                                                                                                     |
|  90 |    949.012478 |    760.492701 | Scott Hartman                                                                                                                                                         |
|  91 |    569.678685 |    351.849802 | Scott Hartman                                                                                                                                                         |
|  92 |    636.152042 |    318.639302 | Zimices                                                                                                                                                               |
|  93 |    711.232184 |    109.573245 | Matt Crook                                                                                                                                                            |
|  94 |     66.134103 |    287.372070 | Gareth Monger                                                                                                                                                         |
|  95 |    360.696206 |     39.829265 | Matt Crook                                                                                                                                                            |
|  96 |    235.985083 |    366.179583 | Ferran Sayol                                                                                                                                                          |
|  97 |    219.361378 |     16.505750 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  98 |     33.033722 |     51.134084 | Zimices                                                                                                                                                               |
|  99 |    253.132932 |    481.386839 | L. Shyamal                                                                                                                                                            |
| 100 |    878.445709 |    578.588807 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 101 |    914.902474 |    312.528407 | Tommaso Cancellario                                                                                                                                                   |
| 102 |    241.098962 |    279.738579 | Jaime Headden                                                                                                                                                         |
| 103 |    996.528703 |    263.066966 | Ferran Sayol                                                                                                                                                          |
| 104 |    781.552200 |    330.225893 | Ferran Sayol                                                                                                                                                          |
| 105 |    943.358577 |    242.401677 | Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael Keesey)                                                                                   |
| 106 |    870.006858 |    699.077476 | Sean McCann                                                                                                                                                           |
| 107 |    686.755977 |    700.907066 | Margot Michaud                                                                                                                                                        |
| 108 |    851.417759 |    676.709532 | Scott Hartman                                                                                                                                                         |
| 109 |    378.986010 |    788.397856 | Pete Buchholz                                                                                                                                                         |
| 110 |    154.752682 |    660.048204 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 111 |    984.437727 |    386.905188 | Beth Reinke                                                                                                                                                           |
| 112 |    434.393536 |    589.437594 | Chris huh                                                                                                                                                             |
| 113 |    389.168246 |    442.668474 | Gareth Monger                                                                                                                                                         |
| 114 |    893.734399 |    350.548396 | Gareth Monger                                                                                                                                                         |
| 115 |    621.554600 |    458.909204 | Richard J. Harris                                                                                                                                                     |
| 116 |    290.063650 |    644.624384 | Matt Crook                                                                                                                                                            |
| 117 |    275.900370 |    167.086584 | T. Michael Keesey                                                                                                                                                     |
| 118 |    553.356105 |    329.498490 | Gareth Monger                                                                                                                                                         |
| 119 |    556.010442 |    284.607533 | xgirouxb                                                                                                                                                              |
| 120 |    120.091057 |    372.263757 | T. Michael Keesey                                                                                                                                                     |
| 121 |    420.549800 |    768.723857 | NA                                                                                                                                                                    |
| 122 |     30.178590 |    320.288421 | Dean Schnabel                                                                                                                                                         |
| 123 |    845.863819 |    275.568831 | Aleksey Nagovitsyn (vectorized by T. Michael Keesey)                                                                                                                  |
| 124 |    438.297930 |    161.416520 | mystica                                                                                                                                                               |
| 125 |    203.604216 |    126.247152 | Ferran Sayol                                                                                                                                                          |
| 126 |    691.709232 |    396.934545 | Matt Crook                                                                                                                                                            |
| 127 |     44.611629 |    141.588561 | Armin Reindl                                                                                                                                                          |
| 128 |    561.142778 |     39.703024 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 129 |    594.854478 |    770.495288 | Matt Crook                                                                                                                                                            |
| 130 |    772.147224 |     69.142724 | Chris huh                                                                                                                                                             |
| 131 |    184.167303 |    766.313989 | Collin Gross                                                                                                                                                          |
| 132 |     19.119724 |    113.901662 | Ben Moon                                                                                                                                                              |
| 133 |    866.759055 |    290.930772 | Ferran Sayol                                                                                                                                                          |
| 134 |    616.438754 |    679.545313 | Tauana J. Cunha                                                                                                                                                       |
| 135 |    566.924242 |    209.582437 | Catherine Yasuda                                                                                                                                                      |
| 136 |    491.856530 |    292.999019 | Becky Barnes                                                                                                                                                          |
| 137 |     76.427883 |    196.486367 | Margot Michaud                                                                                                                                                        |
| 138 |    548.213973 |    696.904835 | Armin Reindl                                                                                                                                                          |
| 139 |    719.256131 |    466.499439 | Scott Hartman                                                                                                                                                         |
| 140 |    878.958132 |    495.130577 | Chase Brownstein                                                                                                                                                      |
| 141 |    935.073808 |    570.899134 | Matt Martyniuk                                                                                                                                                        |
| 142 |    989.751286 |    769.410145 | Margot Michaud                                                                                                                                                        |
| 143 |    821.276550 |    600.185881 | Markus A. Grohme                                                                                                                                                      |
| 144 |     44.996703 |    358.070900 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 145 |    958.195641 |     99.275580 | FunkMonk                                                                                                                                                              |
| 146 |    570.887740 |    629.739565 | T. Michael Keesey                                                                                                                                                     |
| 147 |    830.583605 |    245.280632 | Matt Crook                                                                                                                                                            |
| 148 |    362.607428 |    240.686598 | NA                                                                                                                                                                    |
| 149 |    999.809245 |    565.767905 | Scott Hartman                                                                                                                                                         |
| 150 |    525.964343 |    191.043784 | Smokeybjb                                                                                                                                                             |
| 151 |    133.674190 |    352.038982 | C. Camilo Julián-Caballero                                                                                                                                            |
| 152 |    333.993893 |    128.846159 | Beth Reinke                                                                                                                                                           |
| 153 |     96.922144 |    185.042225 | NA                                                                                                                                                                    |
| 154 |    533.855191 |    539.143605 | Matt Crook                                                                                                                                                            |
| 155 |    685.804571 |    457.297693 | Taenadoman                                                                                                                                                            |
| 156 |    652.719828 |    104.516952 | Tess Linden                                                                                                                                                           |
| 157 |    303.367689 |     11.868156 | Zimices                                                                                                                                                               |
| 158 |     98.916209 |    512.315566 | Jaime Headden                                                                                                                                                         |
| 159 |    329.597059 |     39.483674 | Steven Traver                                                                                                                                                         |
| 160 |    988.030278 |    603.561607 | L. Shyamal                                                                                                                                                            |
| 161 |     59.055614 |     71.096183 | Anthony Caravaggi                                                                                                                                                     |
| 162 |     89.910926 |    343.907470 | T. Michael Keesey                                                                                                                                                     |
| 163 |    594.522661 |     32.659578 | Ferran Sayol                                                                                                                                                          |
| 164 |    860.584869 |    536.027040 | Crystal Maier                                                                                                                                                         |
| 165 |     55.863371 |    733.686348 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                           |
| 166 |    860.097703 |    239.946504 | Jagged Fang Designs                                                                                                                                                   |
| 167 |    228.925205 |    496.907525 | T. Michael Keesey                                                                                                                                                     |
| 168 |    178.553758 |    264.139870 | Margot Michaud                                                                                                                                                        |
| 169 |     71.973227 |    533.356332 | Matt Crook                                                                                                                                                            |
| 170 |    234.141643 |    129.280007 | Inessa Voet                                                                                                                                                           |
| 171 |    804.688063 |    294.180132 | Matt Crook                                                                                                                                                            |
| 172 |    709.593837 |    557.741413 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 173 |     32.108016 |    625.844526 | Dave Angelini                                                                                                                                                         |
| 174 |    857.226021 |    460.998167 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 175 |     27.546053 |    219.346820 | Ferran Sayol                                                                                                                                                          |
| 176 |     64.150843 |    669.096123 | Ferran Sayol                                                                                                                                                          |
| 177 |    862.668337 |    136.118122 | André Karwath (vectorized by T. Michael Keesey)                                                                                                                       |
| 178 |   1010.863468 |    451.249775 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                    |
| 179 |    984.301341 |    672.557570 | Margot Michaud                                                                                                                                                        |
| 180 |    439.041833 |    711.375914 | Steven Traver                                                                                                                                                         |
| 181 |     39.601519 |     20.908452 | Smokeybjb                                                                                                                                                             |
| 182 |     27.941016 |    550.801280 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 183 |    318.977155 |    622.352283 | Chuanixn Yu                                                                                                                                                           |
| 184 |    130.285091 |    141.452182 | Zimices                                                                                                                                                               |
| 185 |    664.682286 |    467.826016 | Scott Hartman                                                                                                                                                         |
| 186 |    653.400145 |    693.612798 | Michelle Site                                                                                                                                                         |
| 187 |   1015.287159 |    202.942198 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 188 |     71.724207 |    452.373431 | Cathy                                                                                                                                                                 |
| 189 |    827.449092 |    551.958691 | T. Michael Keesey                                                                                                                                                     |
| 190 |   1001.862411 |    701.913879 | Markus A. Grohme                                                                                                                                                      |
| 191 |    753.140931 |     59.085009 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 192 |    176.652327 |    385.150800 | Fernando Carezzano                                                                                                                                                    |
| 193 |    657.125072 |    413.325154 | Rebecca Groom                                                                                                                                                         |
| 194 |    890.674053 |    521.054605 | T. Michael Keesey (after Tillyard)                                                                                                                                    |
| 195 |    840.840931 |    614.408450 | Jagged Fang Designs                                                                                                                                                   |
| 196 |    992.421598 |    746.902828 | Bennet McComish, photo by Avenue                                                                                                                                      |
| 197 |    727.730778 |    681.857808 | NA                                                                                                                                                                    |
| 198 |    316.292868 |    606.081700 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 199 |    974.824166 |     60.750909 | Chris huh                                                                                                                                                             |
| 200 |    212.989461 |    264.531124 | Frank Förster                                                                                                                                                         |
| 201 |    173.410581 |    461.981738 | Zimices                                                                                                                                                               |
| 202 |    295.147787 |    584.758196 | Tasman Dixon                                                                                                                                                          |
| 203 |    206.199593 |    506.680058 | Matt Crook                                                                                                                                                            |
| 204 |    125.017858 |    159.194877 | Tasman Dixon                                                                                                                                                          |
| 205 |    696.262878 |    368.592244 | B Kimmel                                                                                                                                                              |
| 206 |    117.851455 |    789.676438 | Margot Michaud                                                                                                                                                        |
| 207 |    551.972435 |     55.875360 | Zimices                                                                                                                                                               |
| 208 |    271.807326 |    148.291691 | Matt Crook                                                                                                                                                            |
| 209 |    730.678518 |    710.262984 | Matt Crook                                                                                                                                                            |
| 210 |    377.234287 |    497.463359 | Tasman Dixon                                                                                                                                                          |
| 211 |    817.003092 |    134.097422 | C. Camilo Julián-Caballero                                                                                                                                            |
| 212 |    525.407665 |     84.585735 | Kanchi Nanjo                                                                                                                                                          |
| 213 |    760.024939 |    754.089751 | Katie S. Collins                                                                                                                                                      |
| 214 |    274.478751 |    340.379614 | Chris huh                                                                                                                                                             |
| 215 |    400.311512 |    199.457840 | Armin Reindl                                                                                                                                                          |
| 216 |    377.258072 |     84.008692 | Emily Willoughby                                                                                                                                                      |
| 217 |    720.606493 |    641.891700 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
| 218 |    247.302515 |    773.458915 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                       |
| 219 |    318.399296 |    405.224149 | Felix Vaux                                                                                                                                                            |
| 220 |    443.681339 |    543.577583 | Gareth Monger                                                                                                                                                         |
| 221 |     31.414658 |    788.274940 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                       |
| 222 |    347.427228 |    505.952448 | Chris huh                                                                                                                                                             |
| 223 |    772.125344 |    111.626891 | Margot Michaud                                                                                                                                                        |
| 224 |    708.450338 |    186.972762 | Gareth Monger                                                                                                                                                         |
| 225 |    643.956135 |    255.602902 | Juan Carlos Jerí                                                                                                                                                      |
| 226 |     21.469457 |     84.057121 | Markus A. Grohme                                                                                                                                                      |
| 227 |    262.702576 |    391.223488 | T. Michael Keesey                                                                                                                                                     |
| 228 |    254.721801 |    591.185159 | Ferran Sayol                                                                                                                                                          |
| 229 |    923.484637 |    273.178123 | Jagged Fang Designs                                                                                                                                                   |
| 230 |      8.971259 |    281.587797 | Gareth Monger                                                                                                                                                         |
| 231 |     45.317560 |    650.598702 | C. Camilo Julián-Caballero                                                                                                                                            |
| 232 |    427.111595 |    330.502053 | Margot Michaud                                                                                                                                                        |
| 233 |     33.168529 |    689.905246 | Sharon Wegner-Larsen                                                                                                                                                  |
| 234 |    581.298172 |     16.566350 | NA                                                                                                                                                                    |
| 235 |    524.121198 |    336.966422 | Chuanixn Yu                                                                                                                                                           |
| 236 |     79.836935 |    594.304952 | Myriam\_Ramirez                                                                                                                                                       |
| 237 |    129.422288 |    702.428981 | Matt Crook                                                                                                                                                            |
| 238 |    815.013995 |    490.202202 | Mathew Wedel                                                                                                                                                          |
| 239 |    844.213048 |     23.230613 | FunkMonk                                                                                                                                                              |
| 240 |    830.885121 |    114.619212 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 241 |    348.946188 |    762.475929 | Caleb M. Brown                                                                                                                                                        |
| 242 |    179.326017 |     10.814048 | Markus A. Grohme                                                                                                                                                      |
| 243 |    872.579066 |    629.996523 | Rafael Maia                                                                                                                                                           |
| 244 |    505.209149 |    351.787388 | Christoph Schomburg                                                                                                                                                   |
| 245 |    789.294325 |    415.670820 | Yan Wong                                                                                                                                                              |
| 246 |    152.407011 |    382.227298 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                         |
| 247 |    710.815219 |    328.200035 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 248 |    624.140059 |    701.443901 | Scott Hartman                                                                                                                                                         |
| 249 |    404.429256 |    414.686513 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 250 |    611.954037 |     90.123276 | Chris huh                                                                                                                                                             |
| 251 |    117.659100 |    502.982178 | Steven Traver                                                                                                                                                         |
| 252 |    466.588781 |    750.811631 | Amanda Katzer                                                                                                                                                         |
| 253 |    962.554761 |    724.720909 | FunkMonk                                                                                                                                                              |
| 254 |    700.440209 |    167.123628 | NA                                                                                                                                                                    |
| 255 |    737.412823 |     77.444834 | Gareth Monger                                                                                                                                                         |
| 256 |    181.018046 |     81.885823 | Christian A. Masnaghetti                                                                                                                                              |
| 257 |    237.580110 |    698.882023 | Margot Michaud                                                                                                                                                        |
| 258 |    489.180335 |    169.327845 | Julia B McHugh                                                                                                                                                        |
| 259 |    771.815557 |    421.063246 | Birgit Lang                                                                                                                                                           |
| 260 |    626.429404 |    113.075784 | T. Michael Keesey                                                                                                                                                     |
| 261 |    559.617117 |    307.052861 | Theodore W. Pietsch (photography) and T. Michael Keesey (vectorization)                                                                                               |
| 262 |    734.968995 |    573.106396 | Gareth Monger                                                                                                                                                         |
| 263 |    390.710074 |    222.133314 | NA                                                                                                                                                                    |
| 264 |    841.362617 |     38.961602 | Darius Nau                                                                                                                                                            |
| 265 |    529.362561 |    216.043958 | Birgit Lang                                                                                                                                                           |
| 266 |     57.244553 |    590.962963 | Iain Reid                                                                                                                                                             |
| 267 |    426.355082 |    750.751800 | Kai R. Caspar                                                                                                                                                         |
| 268 |    610.087275 |    634.328041 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 269 |     68.446461 |    260.694547 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 270 |    166.402224 |    362.525196 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 271 |    479.096977 |    156.450664 | Scott Hartman                                                                                                                                                         |
| 272 |    962.778807 |     12.271022 | Tasman Dixon                                                                                                                                                          |
| 273 |    836.420290 |    727.456504 | Scott Hartman                                                                                                                                                         |
| 274 |    940.033133 |    218.441553 | Sarah Werning                                                                                                                                                         |
| 275 |    679.164739 |    162.641702 | Gareth Monger                                                                                                                                                         |
| 276 |    798.437167 |     98.263804 | Collin Gross                                                                                                                                                          |
| 277 |    982.558180 |    750.289457 | Tasman Dixon                                                                                                                                                          |
| 278 |    219.838566 |    745.370236 | FunkMonk                                                                                                                                                              |
| 279 |    153.667128 |    256.513834 | Scott Hartman                                                                                                                                                         |
| 280 |    184.585093 |    657.903930 | Tauana J. Cunha                                                                                                                                                       |
| 281 |    400.488642 |    256.918301 | Smokeybjb                                                                                                                                                             |
| 282 |    430.662685 |     80.656729 | Collin Gross                                                                                                                                                          |
| 283 |    334.066819 |      6.516295 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 284 |    328.489908 |    424.088840 | Scott Hartman                                                                                                                                                         |
| 285 |    780.994269 |    784.993852 | Birgit Lang                                                                                                                                                           |
| 286 |    584.735622 |     89.780829 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                             |
| 287 |    521.434084 |     41.479626 | Wynston Cooper (photo) and Albertonykus (silhouette)                                                                                                                  |
| 288 |    282.321359 |    278.308822 | Alex Slavenko                                                                                                                                                         |
| 289 |    498.679194 |    185.068118 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 290 |    806.660145 |     44.893256 | Collin Gross                                                                                                                                                          |
| 291 |     94.811873 |     11.832808 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                  |
| 292 |    159.103253 |    690.984297 | Sarah Werning                                                                                                                                                         |
| 293 |    557.840503 |     24.398828 | Charles R. Knight, vectorized by Zimices                                                                                                                              |
| 294 |    127.847180 |    739.690267 | T. Michael Keesey (after Joseph Wolf)                                                                                                                                 |
| 295 |    444.666162 |    283.091271 | Margot Michaud                                                                                                                                                        |
| 296 |    673.493324 |    250.914221 | Markus A. Grohme                                                                                                                                                      |
| 297 |    663.143311 |    488.458081 | Scott Hartman                                                                                                                                                         |
| 298 |    573.347387 |    237.214650 | M Kolmann                                                                                                                                                             |
| 299 |    980.898789 |    580.020277 | Roberto Díaz Sibaja                                                                                                                                                   |
| 300 |    895.095345 |    724.324855 | NA                                                                                                                                                                    |
| 301 |    572.233352 |    587.363401 | Zimices                                                                                                                                                               |
| 302 |    545.630652 |    475.721826 | C. Camilo Julián-Caballero                                                                                                                                            |
| 303 |    254.357596 |    281.831820 | Gareth Monger                                                                                                                                                         |
| 304 |    954.226382 |    420.009230 | Ferran Sayol                                                                                                                                                          |
| 305 |    409.485329 |    113.701277 | NA                                                                                                                                                                    |
| 306 |    832.486352 |    392.098592 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                           |
| 307 |    953.693897 |    289.720763 | Gareth Monger                                                                                                                                                         |
| 308 |     12.693456 |    345.559155 | Armin Reindl                                                                                                                                                          |
| 309 |    845.484737 |    582.426815 | Jagged Fang Designs                                                                                                                                                   |
| 310 |    964.564720 |    379.501165 | Ghedoghedo, vectorized by Zimices                                                                                                                                     |
| 311 |    210.314032 |    369.925221 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 312 |    686.088497 |    553.466071 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 313 |    400.383734 |    481.216150 | T. Michael Keesey                                                                                                                                                     |
| 314 |    928.396388 |    116.438449 | Birgit Lang                                                                                                                                                           |
| 315 |    973.963606 |    220.235249 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 316 |    227.330092 |    551.845603 | Christine Axon                                                                                                                                                        |
| 317 |    945.799695 |    394.220114 | Scott Hartman                                                                                                                                                         |
| 318 |    987.673238 |    642.729808 | NA                                                                                                                                                                    |
| 319 |    269.470161 |     14.297444 | NA                                                                                                                                                                    |
| 320 |    998.410326 |    729.473542 | Michelle Site                                                                                                                                                         |
| 321 |    322.286625 |    192.330982 | Matt Crook                                                                                                                                                            |
| 322 |     19.081753 |    187.260245 | Zimices                                                                                                                                                               |
| 323 |    272.034804 |    750.669047 | Steven Traver                                                                                                                                                         |
| 324 |    562.727514 |    612.828063 | Nobu Tamura                                                                                                                                                           |
| 325 |   1006.108580 |    380.528734 | Michelle Site                                                                                                                                                         |
| 326 |    614.281064 |    789.381114 | Margot Michaud                                                                                                                                                        |
| 327 |     27.607585 |    204.186766 | Maija Karala                                                                                                                                                          |
| 328 |    793.481476 |    450.565313 | Jagged Fang Designs                                                                                                                                                   |
| 329 |    689.502484 |    750.386574 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 330 |    525.374033 |    292.700135 | Margot Michaud                                                                                                                                                        |
| 331 |    648.052290 |    212.846156 | Jagged Fang Designs                                                                                                                                                   |
| 332 |    654.549196 |    163.398953 | Plukenet                                                                                                                                                              |
| 333 |    967.272134 |    796.619266 | Jagged Fang Designs                                                                                                                                                   |
| 334 |    293.354868 |    402.886641 | Jagged Fang Designs                                                                                                                                                   |
| 335 |    746.227995 |    631.387599 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                         |
| 336 |    885.831389 |    129.439878 | Benchill                                                                                                                                                              |
| 337 |    531.194706 |    429.230828 | Jaime Headden                                                                                                                                                         |
| 338 |    661.298485 |    294.411956 | Steven Traver                                                                                                                                                         |
| 339 |    874.094728 |    111.217320 | Matt Crook                                                                                                                                                            |
| 340 |    148.328654 |    409.179322 | Alex Slavenko                                                                                                                                                         |
| 341 |    462.047096 |    599.655907 | Caleb M. Brown                                                                                                                                                        |
| 342 |    458.057511 |    642.533591 | Fernando Campos De Domenico                                                                                                                                           |
| 343 |    188.737525 |    789.137944 | Jack Mayer Wood                                                                                                                                                       |
| 344 |    192.395722 |    700.019366 | Chris huh                                                                                                                                                             |
| 345 |    201.853645 |    646.894537 | Julie Blommaert based on photo by Sofdrakou                                                                                                                           |
| 346 |    735.776005 |    370.084492 | Geoff Shaw                                                                                                                                                            |
| 347 |     57.599466 |    333.951778 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 348 |    151.295387 |    105.308227 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 349 |    806.500334 |    790.917819 | Ignacio Contreras                                                                                                                                                     |
| 350 |    485.049058 |     96.776617 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 351 |    546.583780 |    643.113941 | Kai R. Caspar                                                                                                                                                         |
| 352 |    559.146083 |    758.092646 | NA                                                                                                                                                                    |
| 353 |    181.356515 |     67.875052 | T. Michael Keesey                                                                                                                                                     |
| 354 |    570.237934 |     75.414007 | Zimices                                                                                                                                                               |
| 355 |     34.457744 |    287.033737 | Emily Willoughby                                                                                                                                                      |
| 356 |    299.302983 |    100.860052 | Matt Crook                                                                                                                                                            |
| 357 |    681.510412 |    711.984632 | Chris huh                                                                                                                                                             |
| 358 |     73.689145 |    217.692675 | Markus A. Grohme                                                                                                                                                      |
| 359 |    171.553335 |    445.448266 | Shyamal                                                                                                                                                               |
| 360 |    312.327224 |    262.739618 | Alex Slavenko                                                                                                                                                         |
| 361 |     48.738252 |    184.223679 | Scott Hartman                                                                                                                                                         |
| 362 |    464.807395 |     51.305511 | Markus A. Grohme                                                                                                                                                      |
| 363 |    439.177441 |    628.944838 | NA                                                                                                                                                                    |
| 364 |     27.294992 |    594.145377 | CNZdenek                                                                                                                                                              |
| 365 |    651.452779 |    529.807624 | Chase Brownstein                                                                                                                                                      |
| 366 |    209.422185 |    246.448364 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                           |
| 367 |    174.188430 |    739.490102 | Matt Crook                                                                                                                                                            |
| 368 |     59.058837 |    319.987677 | Tracy A. Heath                                                                                                                                                        |
| 369 |    471.559064 |    551.215711 | Gareth Monger                                                                                                                                                         |
| 370 |    743.206457 |      7.464957 | Chris huh                                                                                                                                                             |
| 371 |    240.485168 |     97.318889 | Dmitry Bogdanov                                                                                                                                                       |
| 372 |    403.556543 |    244.487362 | NA                                                                                                                                                                    |
| 373 |    876.685062 |    661.502227 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                        |
| 374 |   1015.872699 |    233.762458 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 375 |    711.788404 |    786.570241 | Sarah Werning                                                                                                                                                         |
| 376 |    437.269800 |     92.622403 | Steven Traver                                                                                                                                                         |
| 377 |   1003.583133 |    404.371457 | Gareth Monger                                                                                                                                                         |
| 378 |    673.339678 |    204.479900 | T. Michael Keesey                                                                                                                                                     |
| 379 |    476.765735 |    362.408959 | Andreas Preuss / marauder                                                                                                                                             |
| 380 |    575.484668 |    466.158111 | Scott Hartman                                                                                                                                                         |
| 381 |    286.832722 |    766.929390 | T. Michael Keesey                                                                                                                                                     |
| 382 |    716.027977 |    497.053968 | Felix Vaux                                                                                                                                                            |
| 383 |    948.763591 |    187.070127 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                           |
| 384 |    579.865076 |    619.949633 | Tambja (vectorized by T. Michael Keesey)                                                                                                                              |
| 385 |    161.953144 |    633.042612 | Chris huh                                                                                                                                                             |
| 386 |    325.118404 |    548.106806 | Chris huh                                                                                                                                                             |
| 387 |     15.730785 |    660.076057 | Matt Crook                                                                                                                                                            |
| 388 |    772.276945 |    259.126486 | Xavier Giroux-Bougard                                                                                                                                                 |
| 389 |    704.956966 |     11.855887 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                           |
| 390 |    970.107421 |    263.111335 | Scott Hartman                                                                                                                                                         |
| 391 |    850.106916 |    432.524101 | Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)                                                                                         |
| 392 |    946.854503 |     83.532517 | Zimices                                                                                                                                                               |
| 393 |    736.506889 |    191.877929 | Javier Luque                                                                                                                                                          |
| 394 |    361.347818 |    204.962289 | Ferran Sayol                                                                                                                                                          |
| 395 |    922.803969 |    422.638048 | Ignacio Contreras                                                                                                                                                     |
| 396 |    152.269832 |    775.691664 | Tyler Greenfield                                                                                                                                                      |
| 397 |    785.729787 |    434.104447 | Margot Michaud                                                                                                                                                        |
| 398 |    521.695376 |    588.358794 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 399 |     40.621386 |    530.145770 | Zimices                                                                                                                                                               |
| 400 |    131.206915 |    127.565181 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 401 |    353.101603 |    345.152386 | Jagged Fang Designs                                                                                                                                                   |
| 402 |    103.737763 |    522.109276 | Chris huh                                                                                                                                                             |
| 403 |    394.806535 |    341.667329 | Maija Karala                                                                                                                                                          |
| 404 |    258.682699 |    179.864993 | Tasman Dixon                                                                                                                                                          |
| 405 |    292.024860 |    486.331315 | Jagged Fang Designs                                                                                                                                                   |
| 406 |    821.384644 |    443.745101 | Scott Hartman                                                                                                                                                         |
| 407 |    845.221090 |    538.624460 | Felix Vaux                                                                                                                                                            |
| 408 |    232.132296 |    520.200305 | Birgit Lang                                                                                                                                                           |
| 409 |   1007.381685 |    532.841196 | Jean-Raphaël Guillaumin (photography) and T. Michael Keesey (vectorization)                                                                                           |
| 410 |    122.492700 |    227.985443 | Tasman Dixon                                                                                                                                                          |
| 411 |    288.463066 |    191.905628 | Julia B McHugh                                                                                                                                                        |
| 412 |    699.622555 |    144.733848 | Nina Skinner                                                                                                                                                          |
| 413 |    453.639911 |    352.723771 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 414 |     34.156054 |     13.012681 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                         |
| 415 |    417.017050 |    575.914691 | Margot Michaud                                                                                                                                                        |
| 416 |   1016.155133 |    592.347465 | Agnello Picorelli                                                                                                                                                     |
| 417 |    781.102006 |    489.328679 | Jagged Fang Designs                                                                                                                                                   |
| 418 |     78.134412 |    491.125300 | Chris huh                                                                                                                                                             |
| 419 |    310.964992 |    434.430589 | Gareth Monger                                                                                                                                                         |
| 420 |     38.133670 |    453.830887 | Gareth Monger                                                                                                                                                         |
| 421 |     63.555323 |    613.522483 | Sharon Wegner-Larsen                                                                                                                                                  |
| 422 |    153.802557 |    312.063512 | Tyler Greenfield                                                                                                                                                      |
| 423 |     26.796790 |    740.570109 | Baheerathan Murugavel                                                                                                                                                 |
| 424 |     13.193214 |    537.587399 | Christina N. Hodson                                                                                                                                                   |
| 425 |    637.497807 |    411.568143 | Florian Pfaff                                                                                                                                                         |
| 426 |    266.011283 |    304.067038 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                      |
| 427 |    488.398265 |    594.971561 | Zimices                                                                                                                                                               |
| 428 |    254.476160 |    463.604970 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 429 |    617.431673 |    407.350453 | Mariana Ruiz Villarreal (modified by T. Michael Keesey)                                                                                                               |
| 430 |    684.772683 |    323.578274 | Tambja (vectorized by T. Michael Keesey)                                                                                                                              |
| 431 |    594.552632 |    537.526079 | Jack Mayer Wood                                                                                                                                                       |
| 432 |    809.990890 |    504.400956 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
| 433 |    996.238466 |    465.913493 | NA                                                                                                                                                                    |
| 434 |    790.653286 |    606.131275 | NA                                                                                                                                                                    |
| 435 |    295.642744 |    453.058077 | G. M. Woodward                                                                                                                                                        |
| 436 |   1000.628534 |     90.619810 | Margot Michaud                                                                                                                                                        |
| 437 |    423.670377 |    145.277287 | Ignacio Contreras                                                                                                                                                     |
| 438 |    885.637006 |    791.868696 | Margot Michaud                                                                                                                                                        |
| 439 |    186.035489 |    635.950955 | Margot Michaud                                                                                                                                                        |
| 440 |    248.097112 |      7.483742 | Bennet McComish, photo by Hans Hillewaert                                                                                                                             |
| 441 |    554.075279 |    252.478074 | FJDegrange                                                                                                                                                            |
| 442 |    762.980547 |    355.553999 | Jagged Fang Designs                                                                                                                                                   |
| 443 |    966.958554 |     26.649273 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 444 |    187.497387 |    312.588613 | Tasman Dixon                                                                                                                                                          |
| 445 |    334.667937 |    713.905781 | Mathilde Cordellier                                                                                                                                                   |
| 446 |    149.363172 |    232.370554 | Jagged Fang Designs                                                                                                                                                   |
| 447 |     87.594339 |    502.924563 | Chris huh                                                                                                                                                             |
| 448 |     27.590198 |    229.940056 | Matt Crook                                                                                                                                                            |
| 449 |    565.642191 |    689.819483 | Tasman Dixon                                                                                                                                                          |
| 450 |     22.647762 |     76.668888 | Markus A. Grohme                                                                                                                                                      |
| 451 |     41.402556 |    641.681261 | CNZdenek                                                                                                                                                              |
| 452 |    336.968302 |    562.435775 | Chris huh                                                                                                                                                             |
| 453 |    416.793462 |    456.724569 | Shyamal                                                                                                                                                               |
| 454 |    431.553266 |    607.236802 | Matt Crook                                                                                                                                                            |
| 455 |    592.219650 |    686.789279 | Scott Hartman                                                                                                                                                         |
| 456 |    647.143387 |    230.101632 | Anthony Caravaggi                                                                                                                                                     |
| 457 |    705.090430 |    676.402446 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                           |
| 458 |    433.476323 |    180.300076 | Gareth Monger                                                                                                                                                         |
| 459 |    891.527921 |    370.115777 | Meliponicultor Itaymbere                                                                                                                                              |
| 460 |   1006.373982 |    499.633637 | T. Michael Keesey                                                                                                                                                     |
| 461 |   1016.120262 |    492.779711 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 462 |      6.951439 |    622.575941 | T. Michael Keesey (after Walker & al.)                                                                                                                                |
| 463 |      6.416981 |    783.113936 | Fernando Carezzano                                                                                                                                                    |
| 464 |    555.141900 |    176.574868 | Original photo by Andrew Murray, vectorized by Roberto Díaz Sibaja                                                                                                    |
| 465 |    408.764760 |    179.002945 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 466 |    501.542722 |    305.991952 | Henry Lydecker                                                                                                                                                        |
| 467 |    811.891876 |    737.853339 | Ignacio Contreras                                                                                                                                                     |
| 468 |    938.284717 |     67.018163 | Josefine Bohr Brask                                                                                                                                                   |
| 469 |    667.784176 |    650.346254 | Gustav Mützel                                                                                                                                                         |
| 470 |    582.633352 |    328.857483 | T. Michael Keesey (photo by Darren Swim)                                                                                                                              |
| 471 |    208.443313 |    487.095584 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 472 |    171.883759 |    403.890342 | Tasman Dixon                                                                                                                                                          |
| 473 |    333.767261 |    250.640609 | Matt Dempsey                                                                                                                                                          |
| 474 |    171.877672 |    571.745242 | NA                                                                                                                                                                    |
| 475 |    163.676798 |    247.337253 | T. Michael Keesey                                                                                                                                                     |
| 476 |    353.529466 |    183.402047 | Matt Martyniuk                                                                                                                                                        |
| 477 |     32.738475 |    266.403813 | Zimices                                                                                                                                                               |
| 478 |    706.359463 |    514.961728 | Emily Willoughby                                                                                                                                                      |
| 479 |    332.815421 |    109.780563 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                         |
| 480 |    975.663684 |    567.453595 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                         |
| 481 |    917.880180 |    738.821144 | Chris huh                                                                                                                                                             |
| 482 |    137.887555 |    240.644736 | Chris huh                                                                                                                                                             |
| 483 |    816.051658 |    430.196003 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 484 |    977.839164 |    710.206043 | Matt Martyniuk                                                                                                                                                        |
| 485 |    719.489554 |    165.640956 | NA                                                                                                                                                                    |
| 486 |     32.539310 |    607.609970 | John Conway                                                                                                                                                           |
| 487 |    283.931845 |    183.541745 | Scott Hartman                                                                                                                                                         |
| 488 |    478.661883 |    524.723607 | Cyril Matthey-Doret, adapted from Bernard Chaubet                                                                                                                     |
| 489 |    390.766336 |    770.971432 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 490 |    752.750884 |    695.137085 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                    |
| 491 |    888.342254 |    655.386829 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 492 |    732.615791 |     40.343686 | Christoph Schomburg                                                                                                                                                   |
| 493 |    448.088660 |      2.127679 | T. Michael Keesey                                                                                                                                                     |
| 494 |    836.664253 |    361.108877 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 495 |    664.631258 |    795.246659 | Gareth Monger                                                                                                                                                         |
| 496 |    148.228267 |    786.768642 | Darius Nau                                                                                                                                                            |
| 497 |    425.929264 |    342.659111 | Margot Michaud                                                                                                                                                        |
| 498 |     88.753312 |    138.707141 | Zimices                                                                                                                                                               |
| 499 |    991.390150 |    784.462899 | Filip em                                                                                                                                                              |
| 500 |    322.036951 |     56.223543 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                              |
| 501 |    423.246077 |    233.392926 | Steven Coombs                                                                                                                                                         |
| 502 |    683.851757 |    311.001173 | Chris huh                                                                                                                                                             |
| 503 |    907.245136 |    412.221438 | Zimices                                                                                                                                                               |
| 504 |    364.634437 |     53.752502 | NA                                                                                                                                                                    |
| 505 |    185.052124 |    536.481819 | DW Bapst (modified from Bates et al., 2005)                                                                                                                           |
| 506 |    739.052346 |    490.500200 | Chloé Schmidt                                                                                                                                                         |
| 507 |    648.413179 |    714.953402 | Tyler McCraney                                                                                                                                                        |
| 508 |    579.917200 |    646.857142 | NA                                                                                                                                                                    |
| 509 |    295.511706 |     35.166114 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 510 |    197.867523 |    282.995327 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 511 |    986.220301 |    301.492559 | Scott Hartman                                                                                                                                                         |
| 512 |    526.405744 |    272.980278 | Maxime Dahirel                                                                                                                                                        |
| 513 |     54.950508 |    195.508072 | Scott Hartman                                                                                                                                                         |
| 514 |    279.601084 |    292.438124 | Tasman Dixon                                                                                                                                                          |

    #> Your tweet has been posted!
