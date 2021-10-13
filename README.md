
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

Zimices, Margot Michaud, Cesar Julian, FunkMonk, Dmitry Bogdanov
(vectorized by T. Michael Keesey), Harold N Eyster, Ferran Sayol, Xavier
Giroux-Bougard, Chris huh, Tauana J. Cunha, C. Camilo Julián-Caballero,
Steven Haddock • Jellywatch.org, Ian Burt (original) and T. Michael
Keesey (vectorization), FJDegrange, Maija Karala, Rebecca Groom, Sam
Droege (photography) and T. Michael Keesey (vectorization), Original
scheme by ‘Haplochromis’, vectorized by Roberto Díaz Sibaja, Birgit
Lang, Andrew A. Farke, shell lines added by Yan Wong, Nobu Tamura,
Gareth Monger, Chris Hay, Dmitry Bogdanov, T. Michael Keesey (after
Kukalová), Mathilde Cordellier, Jagged Fang Designs, Madeleine Price
Ball, Terpsichores, Alexander Schmidt-Lebuhn, Caleb M. Brown, Scott
Hartman (modified by T. Michael Keesey), Christoph Schomburg, Darren
Naish (vectorize by T. Michael Keesey), Tasman Dixon, Timothy Knepp
(vectorized by T. Michael Keesey), Scott Hartman, Ludwik Gasiorowski,
Andrew A. Farke, Kai R. Caspar, Espen Horn (model; vectorized by T.
Michael Keesey from a photo by H. Zell), CNZdenek, Joanna Wolfe, Katie
S. Collins, Collin Gross, Inessa Voet, Juan Carlos Jerí, T. Michael
Keesey, Christine Axon, Steven Traver, Smokeybjb, Matt Dempsey, Rene
Martin, Fernando Campos De Domenico, Matt Crook, Lauren Anderson, Walter
Vladimir, B. Duygu Özpolat, Danny Cicchetti (vectorized by T. Michael
Keesey), Roberto Díaz Sibaja, Chase Brownstein, Kamil S. Jaron,
Acrocynus (vectorized by T. Michael Keesey), Tyler Greenfield, Robert
Gay, modifed from Olegivvit, Julio Garza, Crystal Maier, Nobu Tamura,
vectorized by Zimices, SecretJellyMan, Hans Hillewaert, Renato Santos,
Sean McCann, Jakovche, Noah Schlottman, photo by Casey Dunn, Gabriela
Palomo-Munoz, Melissa Broussard, Javier Luque, Didier Descouens
(vectorized by T. Michael Keesey), Neil Kelley, Dave Angelini, Darius
Nau, Gopal Murali, Obsidian Soul (vectorized by T. Michael Keesey), Nobu
Tamura (vectorized by T. Michael Keesey), Dr. Thomas G. Barnes, USFWS,
Mathew Wedel, xgirouxb, Michelle Site, T. Michael Keesey (after Mauricio
Antón), Michael Scroggie, Smokeybjb (modified by T. Michael Keesey),
Beth Reinke, Tracy A. Heath, Scott Reid, Zsoldos Márton (vectorized by
T. Michael Keesey), Tim Bertelink (modified by T. Michael Keesey), U.S.
Fish and Wildlife Service (illustration) and Timothy J. Bartley
(silhouette), Stemonitis (photography) and T. Michael Keesey
(vectorization), Lani Mohan, Haplochromis (vectorized by T. Michael
Keesey), T. Michael Keesey (vector) and Stuart Halliday (photograph),
Yan Wong, Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B.
Chaves), Jake Warner, Kanako Bessho-Uehara, Robert Gay, modified from
FunkMonk (Michael B.H.) and T. Michael Keesey., Lafage, Mercedes Yrayzoz
(vectorized by T. Michael Keesey), Lily Hughes, Matt Martyniuk, Roule
Jammes (vectorized by T. Michael Keesey), Matt Martyniuk (vectorized by
T. Michael Keesey), Mali’o Kodis, image from Higgins and Kristensen,
1986, Lukasiniho, Noah Schlottman, photo by Hans De Blauwe, Sarah
Werning, Richard Parker (vectorized by T. Michael Keesey), Ingo Braasch,
Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant
C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield &
T. Michael Keesey, Steven Coombs, Mariana Ruiz Villarreal (modified by
T. Michael Keesey), Louis Ranjard, T. Michael Keesey (after MPF), Chris
A. Hamilton, L. Shyamal, Qiang Ou, Doug Backlund (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Kent Elson
Sorgon, Trond R. Oskars, Iain Reid, Ghedoghedo (vectorized by T. Michael
Keesey), Elizabeth Parker, DW Bapst (modified from Bates et al., 2005),
Matt Celeskey, Brad McFeeters (vectorized by T. Michael Keesey), Matt
Wilkins, Emily Willoughby, Saguaro Pictures (source photo) and T.
Michael Keesey, Aviceda (photo) & T. Michael Keesey, Martin R. Smith,
Brockhaus and Efron, S.Martini, Servien (vectorized by T. Michael
Keesey), NOAA Great Lakes Environmental Research Laboratory
(illustration) and Timothy J. Bartley (silhouette), E. D. Cope (modified
by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel),
Meliponicultor Itaymbere, Martin R. Smith, from photo by Jürgen Schoner,
Dmitry Bogdanov, vectorized by Zimices, Gustav Mützel, Tarique Sani
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Melissa Ingala, Robbie N. Cada (vectorized by T. Michael
Keesey), Tyler McCraney, Andrew R. Gehrke, Giant Blue Anteater
(vectorized by T. Michael Keesey), Matt Hayes, Ralf Janssen,
Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael
Keesey), Milton Tan, Michael P. Taylor, Ewald Rübsamen, Matthias
Buschmann (vectorized by T. Michael Keesey), Pete Buchholz, Maxwell
Lefroy (vectorized by T. Michael Keesey), Felix Vaux, FunkMonk (Michael
B.H.; vectorized by T. Michael Keesey), Emily Jane McTavish, Kailah
Thorn & Mark Hutchinson, Benjamin Monod-Broca, Conty (vectorized by T.
Michael Keesey), Jaime Headden, Nobu Tamura (vectorized by A. Verrière),
Sarah Alewijnse, Mathieu Basille, Sergio A. Muñoz-Gómez, Jay Matternes
(modified by T. Michael Keesey), Cristian Osorio & Paula Carrera,
Proyecto Carnivoros Australes (www.carnivorosaustrales.org), Craig
Dylke, Geoff Shaw, Ghedoghedo, Lee Harding (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Henry Lydecker, Duane
Raver/USFWS, Campbell Fleming

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                             |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    595.320023 |    713.268513 | Zimices                                                                                                                                                            |
|   2 |    271.876504 |    384.861669 | Margot Michaud                                                                                                                                                     |
|   3 |    731.178822 |    520.819759 | Cesar Julian                                                                                                                                                       |
|   4 |    650.338729 |    638.866309 | FunkMonk                                                                                                                                                           |
|   5 |    401.816019 |    322.199768 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
|   6 |    228.684289 |    283.647697 | Harold N Eyster                                                                                                                                                    |
|   7 |    855.897823 |    481.966644 | Ferran Sayol                                                                                                                                                       |
|   8 |    598.038711 |    136.096324 | Xavier Giroux-Bougard                                                                                                                                              |
|   9 |    491.445497 |    254.736228 | Chris huh                                                                                                                                                          |
|  10 |     78.772109 |    545.959045 | Tauana J. Cunha                                                                                                                                                    |
|  11 |    341.856669 |     23.265432 | Chris huh                                                                                                                                                          |
|  12 |    900.012572 |    370.987103 | C. Camilo Julián-Caballero                                                                                                                                         |
|  13 |    226.457974 |    605.079412 | Steven Haddock • Jellywatch.org                                                                                                                                    |
|  14 |    494.330949 |    475.924272 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                          |
|  15 |    635.371370 |    279.582098 | FJDegrange                                                                                                                                                         |
|  16 |    922.376596 |    716.004830 | Maija Karala                                                                                                                                                       |
|  17 |    561.439233 |     70.179194 | NA                                                                                                                                                                 |
|  18 |    734.692968 |    122.982512 | Rebecca Groom                                                                                                                                                      |
|  19 |    251.937898 |    106.902159 | Harold N Eyster                                                                                                                                                    |
|  20 |    381.880348 |    232.607213 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                     |
|  21 |    820.613443 |    248.441773 | Original scheme by ‘Haplochromis’, vectorized by Roberto Díaz Sibaja                                                                                               |
|  22 |    435.298641 |     96.564514 | Birgit Lang                                                                                                                                                        |
|  23 |    190.282045 |     39.427045 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                     |
|  24 |    817.854593 |     50.859830 | Nobu Tamura                                                                                                                                                        |
|  25 |    316.563617 |    706.437655 | Gareth Monger                                                                                                                                                      |
|  26 |    120.933055 |    159.554971 | Chris Hay                                                                                                                                                          |
|  27 |    629.983721 |    395.908095 | Dmitry Bogdanov                                                                                                                                                    |
|  28 |    684.823264 |     50.465519 | T. Michael Keesey (after Kukalová)                                                                                                                                 |
|  29 |    962.952293 |    125.360708 | Mathilde Cordellier                                                                                                                                                |
|  30 |    413.125375 |    622.961544 | Harold N Eyster                                                                                                                                                    |
|  31 |    663.719727 |    558.045846 | Jagged Fang Designs                                                                                                                                                |
|  32 |    188.825648 |    719.035389 | Madeleine Price Ball                                                                                                                                               |
|  33 |     83.866069 |    397.744078 | Terpsichores                                                                                                                                                       |
|  34 |    472.590102 |    726.648304 | Alexander Schmidt-Lebuhn                                                                                                                                           |
|  35 |    414.685515 |    510.715882 | NA                                                                                                                                                                 |
|  36 |    873.800804 |    780.406350 | Caleb M. Brown                                                                                                                                                     |
|  37 |    206.045595 |    471.383935 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                      |
|  38 |    848.471880 |    131.091944 | Christoph Schomburg                                                                                                                                                |
|  39 |    811.222102 |    674.593795 | Ferran Sayol                                                                                                                                                       |
|  40 |     75.207291 |    670.155507 | Margot Michaud                                                                                                                                                     |
|  41 |    956.930343 |    264.964787 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                      |
|  42 |    906.579672 |    598.876119 | Tasman Dixon                                                                                                                                                       |
|  43 |    468.429233 |     19.807667 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                    |
|  44 |    750.371753 |    308.044681 | Scott Hartman                                                                                                                                                      |
|  45 |    350.676553 |    158.066879 | Jagged Fang Designs                                                                                                                                                |
|  46 |     39.792161 |     96.984401 | Ludwik Gasiorowski                                                                                                                                                 |
|  47 |    528.884507 |    618.288856 | NA                                                                                                                                                                 |
|  48 |    574.166826 |    190.422569 | Tasman Dixon                                                                                                                                                       |
|  49 |    733.899304 |    436.965112 | Zimices                                                                                                                                                            |
|  50 |    592.389860 |    515.990801 | Tasman Dixon                                                                                                                                                       |
|  51 |    848.630858 |    571.108936 | Andrew A. Farke                                                                                                                                                    |
|  52 |     74.265185 |    256.505915 | Scott Hartman                                                                                                                                                      |
|  53 |    669.656996 |    204.467831 | NA                                                                                                                                                                 |
|  54 |     72.651312 |    202.328936 | Kai R. Caspar                                                                                                                                                      |
|  55 |    222.944214 |    522.099404 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                        |
|  56 |    885.456028 |    321.054750 | CNZdenek                                                                                                                                                           |
|  57 |    342.388725 |     99.776303 | Joanna Wolfe                                                                                                                                                       |
|  58 |    641.306786 |    467.786134 | NA                                                                                                                                                                 |
|  59 |    756.428514 |    738.571244 | Katie S. Collins                                                                                                                                                   |
|  60 |     72.951190 |    485.027833 | Collin Gross                                                                                                                                                       |
|  61 |     69.036448 |     19.000826 | NA                                                                                                                                                                 |
|  62 |    912.241712 |    438.911517 | Inessa Voet                                                                                                                                                        |
|  63 |    722.152563 |    237.625282 | Chris huh                                                                                                                                                          |
|  64 |    577.327966 |    282.660719 | Juan Carlos Jerí                                                                                                                                                   |
|  65 |    181.496802 |     86.035786 | Jagged Fang Designs                                                                                                                                                |
|  66 |    251.025382 |    190.966638 | T. Michael Keesey                                                                                                                                                  |
|  67 |    500.779721 |    368.961407 | Scott Hartman                                                                                                                                                      |
|  68 |    321.703437 |    526.797800 | Ferran Sayol                                                                                                                                                       |
|  69 |    787.806348 |    389.012976 | Gareth Monger                                                                                                                                                      |
|  70 |    822.520208 |    543.848686 | T. Michael Keesey                                                                                                                                                  |
|  71 |     62.894983 |    758.545671 | Margot Michaud                                                                                                                                                     |
|  72 |    577.457036 |    788.637027 | Gareth Monger                                                                                                                                                      |
|  73 |    432.304276 |    568.935554 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
|  74 |    681.691841 |    607.616214 | Scott Hartman                                                                                                                                                      |
|  75 |    422.845785 |    775.253337 | Christine Axon                                                                                                                                                     |
|  76 |     60.759282 |    590.826169 | Gareth Monger                                                                                                                                                      |
|  77 |    141.016575 |    593.925798 | Gareth Monger                                                                                                                                                      |
|  78 |    325.180670 |    289.072534 | Steven Traver                                                                                                                                                      |
|  79 |    387.068798 |    448.971462 | Smokeybjb                                                                                                                                                          |
|  80 |    217.222815 |    763.370310 | Matt Dempsey                                                                                                                                                       |
|  81 |     62.200257 |    290.365457 | Rene Martin                                                                                                                                                        |
|  82 |    302.495421 |    625.573437 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
|  83 |    174.986746 |    109.323562 | Fernando Campos De Domenico                                                                                                                                        |
|  84 |    180.519722 |    595.383322 | Matt Crook                                                                                                                                                         |
|  85 |    525.837766 |    645.768815 | Matt Crook                                                                                                                                                         |
|  86 |    757.095349 |    577.523902 | Lauren Anderson                                                                                                                                                    |
|  87 |    154.341689 |    294.320698 | NA                                                                                                                                                                 |
|  88 |    291.674942 |    777.681308 | Tasman Dixon                                                                                                                                                       |
|  89 |    983.203428 |    405.426771 | NA                                                                                                                                                                 |
|  90 |    550.049363 |    319.315757 | Collin Gross                                                                                                                                                       |
|  91 |    190.555993 |    433.439487 | Walter Vladimir                                                                                                                                                    |
|  92 |    956.854680 |    521.799333 | B. Duygu Özpolat                                                                                                                                                   |
|  93 |    697.354209 |    706.258947 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                  |
|  94 |    580.508517 |    557.200965 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
|  95 |    406.648552 |    737.183746 | Roberto Díaz Sibaja                                                                                                                                                |
|  96 |    677.650194 |    161.424497 | Chase Brownstein                                                                                                                                                   |
|  97 |    934.839938 |    474.933582 | Zimices                                                                                                                                                            |
|  98 |    510.985149 |    218.340941 | Tasman Dixon                                                                                                                                                       |
|  99 |     92.879184 |     83.558008 | Kamil S. Jaron                                                                                                                                                     |
| 100 |    473.169834 |    190.797317 | Margot Michaud                                                                                                                                                     |
| 101 |    883.739825 |    224.464371 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                        |
| 102 |    475.609310 |    657.267664 | Tyler Greenfield                                                                                                                                                   |
| 103 |    629.052624 |    583.548882 | Margot Michaud                                                                                                                                                     |
| 104 |     17.481137 |    384.313180 | Robert Gay, modifed from Olegivvit                                                                                                                                 |
| 105 |    907.741928 |    246.733709 | Julio Garza                                                                                                                                                        |
| 106 |    244.222948 |    485.397907 | Kamil S. Jaron                                                                                                                                                     |
| 107 |    289.782543 |    580.822161 | Matt Crook                                                                                                                                                         |
| 108 |    910.524873 |     19.128995 | Crystal Maier                                                                                                                                                      |
| 109 |    395.802637 |    705.775366 | Chris huh                                                                                                                                                          |
| 110 |    494.585520 |    143.747791 | NA                                                                                                                                                                 |
| 111 |    985.093007 |    498.745174 | Nobu Tamura, vectorized by Zimices                                                                                                                                 |
| 112 |    567.238594 |     15.226287 | SecretJellyMan                                                                                                                                                     |
| 113 |     22.933570 |    230.914737 | Ferran Sayol                                                                                                                                                       |
| 114 |    364.240701 |    266.969994 | Hans Hillewaert                                                                                                                                                    |
| 115 |    416.338705 |    170.942040 | Renato Santos                                                                                                                                                      |
| 116 |    978.974356 |    542.705927 | Sean McCann                                                                                                                                                        |
| 117 |   1003.319711 |    434.295541 | Jakovche                                                                                                                                                           |
| 118 |    221.779844 |    685.151696 | Noah Schlottman, photo by Casey Dunn                                                                                                                               |
| 119 |   1005.192742 |    327.336149 | NA                                                                                                                                                                 |
| 120 |    834.155300 |     15.488380 | Margot Michaud                                                                                                                                                     |
| 121 |     27.360188 |    717.451051 | Zimices                                                                                                                                                            |
| 122 |    556.757582 |    479.675908 | Gabriela Palomo-Munoz                                                                                                                                              |
| 123 |    118.201550 |    736.631526 | Melissa Broussard                                                                                                                                                  |
| 124 |    467.254836 |    687.399256 | Ferran Sayol                                                                                                                                                       |
| 125 |    354.579109 |    467.955450 | Javier Luque                                                                                                                                                       |
| 126 |    752.553686 |    778.950682 | Steven Traver                                                                                                                                                      |
| 127 |    291.914421 |    495.403919 | T. Michael Keesey                                                                                                                                                  |
| 128 |    924.729871 |    553.040096 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                 |
| 129 |    659.027614 |    227.796474 | Harold N Eyster                                                                                                                                                    |
| 130 |    500.055371 |    393.553874 | Ferran Sayol                                                                                                                                                       |
| 131 |    899.340454 |    751.454097 | Zimices                                                                                                                                                            |
| 132 |    343.440853 |    600.765917 | Chris huh                                                                                                                                                          |
| 133 |    904.196066 |    785.387796 | Neil Kelley                                                                                                                                                        |
| 134 |    656.107768 |    520.566147 | Matt Crook                                                                                                                                                         |
| 135 |    529.833672 |    446.837341 | Dave Angelini                                                                                                                                                      |
| 136 |    139.286006 |    243.018021 | Gareth Monger                                                                                                                                                      |
| 137 |    962.505812 |     10.952150 | Chris huh                                                                                                                                                          |
| 138 |    537.390828 |    412.490845 | Gabriela Palomo-Munoz                                                                                                                                              |
| 139 |    963.957242 |    355.390068 | Gareth Monger                                                                                                                                                      |
| 140 |    250.633040 |    662.728234 | Margot Michaud                                                                                                                                                     |
| 141 |    523.375497 |    109.071322 | Zimices                                                                                                                                                            |
| 142 |    669.725426 |    447.273023 | Christine Axon                                                                                                                                                     |
| 143 |    483.476374 |    287.357887 | Darius Nau                                                                                                                                                         |
| 144 |   1007.992708 |    756.648326 | Gopal Murali                                                                                                                                                       |
| 145 |    699.503965 |    755.545827 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                    |
| 146 |    183.998851 |    787.991133 | Jakovche                                                                                                                                                           |
| 147 |    489.182515 |    160.002282 | Scott Hartman                                                                                                                                                      |
| 148 |    884.242431 |     15.149624 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 149 |    580.807044 |    505.833968 | Tasman Dixon                                                                                                                                                       |
| 150 |    722.739242 |     13.672939 | Dr. Thomas G. Barnes, USFWS                                                                                                                                        |
| 151 |    743.592244 |    400.233221 | Nobu Tamura                                                                                                                                                        |
| 152 |    312.028702 |    131.053322 | Mathew Wedel                                                                                                                                                       |
| 153 |    361.960033 |    661.338305 | Zimices                                                                                                                                                            |
| 154 |    353.965838 |    783.182591 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 155 |    133.321554 |    698.733016 | T. Michael Keesey                                                                                                                                                  |
| 156 |    458.412122 |    454.961101 | NA                                                                                                                                                                 |
| 157 |    996.585997 |    304.639564 | xgirouxb                                                                                                                                                           |
| 158 |    144.256465 |    474.750265 | Kai R. Caspar                                                                                                                                                      |
| 159 |     17.590660 |    536.279179 | Matt Crook                                                                                                                                                         |
| 160 |    902.484565 |     90.482322 | T. Michael Keesey                                                                                                                                                  |
| 161 |    589.214489 |    490.266633 | Michelle Site                                                                                                                                                      |
| 162 |    944.833944 |    663.188921 | Steven Traver                                                                                                                                                      |
| 163 |    357.799303 |     66.540239 | T. Michael Keesey (after Mauricio Antón)                                                                                                                           |
| 164 |    670.046714 |    105.934945 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 165 |    778.111959 |    265.589092 | Michael Scroggie                                                                                                                                                   |
| 166 |    955.635875 |    209.990810 | Maija Karala                                                                                                                                                       |
| 167 |    962.178069 |    776.685309 | Smokeybjb (modified by T. Michael Keesey)                                                                                                                          |
| 168 |    144.391751 |      5.962493 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 169 |    891.029100 |    550.604906 | Zimices                                                                                                                                                            |
| 170 |    498.146359 |    790.378306 | Chris huh                                                                                                                                                          |
| 171 |     52.020072 |    505.139414 | Beth Reinke                                                                                                                                                        |
| 172 |    100.360768 |    439.094551 | NA                                                                                                                                                                 |
| 173 |    165.334737 |    316.862483 | Margot Michaud                                                                                                                                                     |
| 174 |    239.322029 |    438.520617 | Scott Hartman                                                                                                                                                      |
| 175 |    184.351222 |    143.346272 | Matt Crook                                                                                                                                                         |
| 176 |    936.490508 |    509.177590 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 177 |    718.542730 |    630.629821 | Mathilde Cordellier                                                                                                                                                |
| 178 |     50.559477 |    329.612251 | Tracy A. Heath                                                                                                                                                     |
| 179 |     93.446626 |    579.838894 | Scott Reid                                                                                                                                                         |
| 180 |    384.995726 |    182.787249 | Ferran Sayol                                                                                                                                                       |
| 181 |     35.924536 |    624.973695 | Tasman Dixon                                                                                                                                                       |
| 182 |    702.778935 |    576.660179 | Matt Crook                                                                                                                                                         |
| 183 |    598.807012 |    155.610225 | Zimices                                                                                                                                                            |
| 184 |    608.937150 |    209.702225 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                                   |
| 185 |    750.053349 |    477.829898 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                      |
| 186 |    872.018347 |     27.041711 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                                  |
| 187 |    386.043418 |     64.393621 | T. Michael Keesey                                                                                                                                                  |
| 188 |    734.281024 |    207.942321 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                     |
| 189 |    821.158188 |    729.978588 | Lani Mohan                                                                                                                                                         |
| 190 |    627.791571 |     15.185904 | Dmitry Bogdanov                                                                                                                                                    |
| 191 |    669.338121 |    773.858060 | Matt Crook                                                                                                                                                         |
| 192 |    732.585333 |    576.896390 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                     |
| 193 |    880.451058 |    683.337231 | Matt Crook                                                                                                                                                         |
| 194 |    409.452111 |    355.594983 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                        |
| 195 |    909.603504 |    268.224390 | Yan Wong                                                                                                                                                           |
| 196 |    753.559700 |    647.564276 | Scott Hartman                                                                                                                                                      |
| 197 |     55.231684 |    102.706931 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                                |
| 198 |    709.147157 |    492.822358 | Jake Warner                                                                                                                                                        |
| 199 |     74.759171 |    520.429104 | T. Michael Keesey                                                                                                                                                  |
| 200 |    306.873895 |    212.488224 | Kanako Bessho-Uehara                                                                                                                                               |
| 201 |    797.182833 |    607.415606 | Chris huh                                                                                                                                                          |
| 202 |    512.713939 |    274.361728 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                           |
| 203 |    859.614133 |    274.364448 | Nobu Tamura                                                                                                                                                        |
| 204 |    733.144508 |    680.670201 | Lafage                                                                                                                                                             |
| 205 |    815.938354 |    345.812014 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                                 |
| 206 |    794.137863 |    778.425958 | Scott Hartman                                                                                                                                                      |
| 207 |    711.239153 |    788.942394 | Lily Hughes                                                                                                                                                        |
| 208 |     81.356710 |    229.616709 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 209 |    987.876908 |    741.330049 | Matt Crook                                                                                                                                                         |
| 210 |    312.813612 |    228.080383 | Gabriela Palomo-Munoz                                                                                                                                              |
| 211 |    543.783390 |    347.147095 | Gareth Monger                                                                                                                                                      |
| 212 |    321.270956 |     55.542495 | NA                                                                                                                                                                 |
| 213 |    302.878688 |    262.527627 | Roberto Díaz Sibaja                                                                                                                                                |
| 214 |    533.113695 |    222.892454 | Matt Martyniuk                                                                                                                                                     |
| 215 |    149.365651 |    263.473134 | T. Michael Keesey                                                                                                                                                  |
| 216 |    718.712508 |    381.063150 | Juan Carlos Jerí                                                                                                                                                   |
| 217 |    997.698061 |    635.501467 | Roule Jammes (vectorized by T. Michael Keesey)                                                                                                                     |
| 218 |    734.767111 |    183.455641 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                   |
| 219 |    919.568094 |    137.524976 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 220 |    558.638137 |    446.833827 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                   |
| 221 |    241.597068 |    222.438769 | Margot Michaud                                                                                                                                                     |
| 222 |    721.314903 |    320.735845 | Birgit Lang                                                                                                                                                        |
| 223 |    125.306194 |    320.871223 | Matt Crook                                                                                                                                                         |
| 224 |    354.394020 |    512.952358 | Ferran Sayol                                                                                                                                                       |
| 225 |    142.207258 |    779.235990 | Mali’o Kodis, image from Higgins and Kristensen, 1986                                                                                                              |
| 226 |    514.253558 |    610.437111 | Fernando Campos De Domenico                                                                                                                                        |
| 227 |    136.045442 |    507.857438 | Ferran Sayol                                                                                                                                                       |
| 228 |    259.052476 |     25.143619 | Lukasiniho                                                                                                                                                         |
| 229 |    609.140363 |    758.594049 | Gareth Monger                                                                                                                                                      |
| 230 |    272.171079 |    306.197522 | Zimices                                                                                                                                                            |
| 231 |   1002.528469 |    699.217558 | Zimices                                                                                                                                                            |
| 232 |   1003.635990 |    207.846833 | Rebecca Groom                                                                                                                                                      |
| 233 |    944.054320 |    286.899410 | Fernando Campos De Domenico                                                                                                                                        |
| 234 |    888.367909 |    278.222643 | Zimices                                                                                                                                                            |
| 235 |    717.597915 |    354.030510 | Zimices                                                                                                                                                            |
| 236 |     87.121537 |    788.480088 | Jagged Fang Designs                                                                                                                                                |
| 237 |    646.733103 |    331.717844 | Noah Schlottman, photo by Hans De Blauwe                                                                                                                           |
| 238 |    309.848495 |    746.465856 | Sarah Werning                                                                                                                                                      |
| 239 |    767.834994 |     22.449197 | Richard Parker (vectorized by T. Michael Keesey)                                                                                                                   |
| 240 |    813.264035 |    204.804492 | Steven Traver                                                                                                                                                      |
| 241 |   1011.370060 |    273.651507 | NA                                                                                                                                                                 |
| 242 |     17.910056 |    650.193427 | Ingo Braasch                                                                                                                                                       |
| 243 |     20.479580 |    787.208208 | Chris huh                                                                                                                                                          |
| 244 |    805.552918 |    752.505016 | Kamil S. Jaron                                                                                                                                                     |
| 245 |    162.898619 |    141.442985 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 246 |     18.418923 |    339.202626 | Steven Coombs                                                                                                                                                      |
| 247 |    993.606531 |    676.283713 | Steven Traver                                                                                                                                                      |
| 248 |    893.684891 |    295.109573 | C. Camilo Julián-Caballero                                                                                                                                         |
| 249 |     83.463859 |    127.060560 | Mariana Ruiz Villarreal (modified by T. Michael Keesey)                                                                                                            |
| 250 |    716.810871 |     64.952882 | Gareth Monger                                                                                                                                                      |
| 251 |    603.677333 |    643.627564 | T. Michael Keesey                                                                                                                                                  |
| 252 |    560.598008 |    387.506105 | Hans Hillewaert                                                                                                                                                    |
| 253 |    160.463947 |    547.107600 | Louis Ranjard                                                                                                                                                      |
| 254 |    795.512251 |    789.813255 | Tasman Dixon                                                                                                                                                       |
| 255 |    928.001653 |    184.849961 | Margot Michaud                                                                                                                                                     |
| 256 |     67.516143 |     41.992013 | Zimices                                                                                                                                                            |
| 257 |    299.572687 |     13.319950 | Steven Coombs                                                                                                                                                      |
| 258 |    386.674438 |    685.062960 | Smokeybjb                                                                                                                                                          |
| 259 |    524.983570 |    542.556473 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 260 |    280.679516 |     64.954160 | Tasman Dixon                                                                                                                                                       |
| 261 |    817.665115 |    359.717846 | Nobu Tamura, vectorized by Zimices                                                                                                                                 |
| 262 |   1000.946741 |    236.145701 | Birgit Lang                                                                                                                                                        |
| 263 |    551.633843 |    662.256680 | Maija Karala                                                                                                                                                       |
| 264 |   1000.353866 |    453.359785 | Rebecca Groom                                                                                                                                                      |
| 265 |    311.236803 |    591.070391 | T. Michael Keesey (after MPF)                                                                                                                                      |
| 266 |    708.634049 |    689.962923 | Chris A. Hamilton                                                                                                                                                  |
| 267 |    398.228590 |    270.655332 | L. Shyamal                                                                                                                                                         |
| 268 |    529.534165 |    719.853300 | Sarah Werning                                                                                                                                                      |
| 269 |    319.772957 |    640.882984 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 270 |     88.522307 |    609.074884 | Jagged Fang Designs                                                                                                                                                |
| 271 |    330.946163 |    476.972441 | Michelle Site                                                                                                                                                      |
| 272 |    792.144041 |     14.808059 | Margot Michaud                                                                                                                                                     |
| 273 |    101.137682 |     43.603657 | Qiang Ou                                                                                                                                                           |
| 274 |    338.660964 |    588.681398 | Scott Hartman                                                                                                                                                      |
| 275 |    679.921585 |    120.172396 | Gareth Monger                                                                                                                                                      |
| 276 |    985.730689 |    378.251503 | Michelle Site                                                                                                                                                      |
| 277 |    724.409317 |     88.191970 | Chris huh                                                                                                                                                          |
| 278 |    164.243486 |    663.556869 | Doug Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey      |
| 279 |    201.935100 |    188.699123 | Kent Elson Sorgon                                                                                                                                                  |
| 280 |    770.937736 |    192.875500 | Matt Crook                                                                                                                                                         |
| 281 |    456.167066 |    145.177763 | Steven Traver                                                                                                                                                      |
| 282 |    535.554827 |     90.037665 | NA                                                                                                                                                                 |
| 283 |    329.742124 |    189.092995 | Jagged Fang Designs                                                                                                                                                |
| 284 |    238.700750 |    448.013497 | T. Michael Keesey                                                                                                                                                  |
| 285 |    496.572712 |    132.617884 | Jagged Fang Designs                                                                                                                                                |
| 286 |     96.582198 |    276.151647 | Steven Traver                                                                                                                                                      |
| 287 |    376.071232 |    549.183344 | Trond R. Oskars                                                                                                                                                    |
| 288 |    533.396036 |    152.702950 | Margot Michaud                                                                                                                                                     |
| 289 |    276.303794 |    322.733855 | Scott Hartman                                                                                                                                                      |
| 290 |    937.972628 |    785.430490 | Iain Reid                                                                                                                                                          |
| 291 |    908.437376 |    671.885797 | NA                                                                                                                                                                 |
| 292 |    600.826718 |    118.839641 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                       |
| 293 |    550.281744 |    162.568023 | Elizabeth Parker                                                                                                                                                   |
| 294 |    563.711469 |    768.945172 | Tasman Dixon                                                                                                                                                       |
| 295 |    926.020626 |    681.366502 | L. Shyamal                                                                                                                                                         |
| 296 |    501.271181 |    626.702701 | DW Bapst (modified from Bates et al., 2005)                                                                                                                        |
| 297 |    593.090777 |    585.614398 | Zimices                                                                                                                                                            |
| 298 |     18.626345 |    265.201749 | Ferran Sayol                                                                                                                                                       |
| 299 |    899.345581 |     40.223860 | Matt Celeskey                                                                                                                                                      |
| 300 |    995.764686 |    197.300589 | Kent Elson Sorgon                                                                                                                                                  |
| 301 |    964.887774 |    632.088210 | Steven Traver                                                                                                                                                      |
| 302 |    868.550565 |    223.079920 | Michelle Site                                                                                                                                                      |
| 303 |    606.003591 |    665.411698 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                   |
| 304 |    675.269468 |    667.697540 | Matt Wilkins                                                                                                                                                       |
| 305 |    710.553011 |    559.588066 | Emily Willoughby                                                                                                                                                   |
| 306 |    795.626771 |    146.867308 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                              |
| 307 |    599.740804 |     21.168822 | Aviceda (photo) & T. Michael Keesey                                                                                                                                |
| 308 |    842.557839 |    748.510176 | Yan Wong                                                                                                                                                           |
| 309 |    473.418311 |    121.428252 | T. Michael Keesey                                                                                                                                                  |
| 310 |    153.676304 |    219.525082 | NA                                                                                                                                                                 |
| 311 |     33.793190 |    452.669309 | Tasman Dixon                                                                                                                                                       |
| 312 |    484.354948 |    607.906782 | Iain Reid                                                                                                                                                          |
| 313 |    638.046102 |    111.844441 | Cesar Julian                                                                                                                                                       |
| 314 |    700.337949 |    313.983527 | Emily Willoughby                                                                                                                                                   |
| 315 |    163.940833 |    409.255095 | CNZdenek                                                                                                                                                           |
| 316 |    303.969351 |    550.566228 | Scott Hartman                                                                                                                                                      |
| 317 |     79.411412 |    350.432131 | Martin R. Smith                                                                                                                                                    |
| 318 |    929.895986 |    746.701482 | Scott Hartman                                                                                                                                                      |
| 319 |    124.010804 |    443.042195 | Kai R. Caspar                                                                                                                                                      |
| 320 |     14.535827 |    693.305630 | Brockhaus and Efron                                                                                                                                                |
| 321 |    899.489438 |    198.583153 | Juan Carlos Jerí                                                                                                                                                   |
| 322 |    437.984580 |    281.592814 | Steven Traver                                                                                                                                                      |
| 323 |    471.228775 |    763.928755 | NA                                                                                                                                                                 |
| 324 |    635.126314 |    771.152171 | S.Martini                                                                                                                                                          |
| 325 |    499.780102 |    123.059209 | Tasman Dixon                                                                                                                                                       |
| 326 |    462.746157 |    237.305161 | Matt Crook                                                                                                                                                         |
| 327 |    121.441698 |    679.442083 | Xavier Giroux-Bougard                                                                                                                                              |
| 328 |    368.232094 |    156.306131 | Scott Hartman                                                                                                                                                      |
| 329 |    520.342519 |    348.022975 | Scott Hartman                                                                                                                                                      |
| 330 |    113.787669 |    226.895832 | Gabriela Palomo-Munoz                                                                                                                                              |
| 331 |    598.111784 |    627.940981 | NA                                                                                                                                                                 |
| 332 |    393.899210 |    126.229893 | Scott Hartman                                                                                                                                                      |
| 333 |    121.911663 |    270.878129 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                                 |
| 334 |    839.424860 |    422.364588 | Servien (vectorized by T. Michael Keesey)                                                                                                                          |
| 335 |    743.234070 |    699.842458 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                              |
| 336 |    249.207249 |     88.389612 | Matt Crook                                                                                                                                                         |
| 337 |    861.791736 |    433.361278 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                   |
| 338 |     44.165878 |    173.353798 | Collin Gross                                                                                                                                                       |
| 339 |    790.262220 |    504.515634 | FJDegrange                                                                                                                                                         |
| 340 |    703.706739 |    207.511900 | Collin Gross                                                                                                                                                       |
| 341 |   1009.445995 |    621.305125 | Matt Wilkins                                                                                                                                                       |
| 342 |    825.385610 |    378.129277 | Meliponicultor Itaymbere                                                                                                                                           |
| 343 |    709.835267 |    291.049255 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                          |
| 344 |    869.713533 |    655.618762 | Martin R. Smith, from photo by Jürgen Schoner                                                                                                                      |
| 345 |    474.624440 |    334.106755 | Gabriela Palomo-Munoz                                                                                                                                              |
| 346 |    694.230098 |    739.416726 | Gabriela Palomo-Munoz                                                                                                                                              |
| 347 |    248.133192 |    774.725154 | Zimices                                                                                                                                                            |
| 348 |    318.971893 |    344.319537 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                             |
| 349 |    387.821344 |    473.361154 | Gustav Mützel                                                                                                                                                      |
| 350 |    753.267042 |    385.348246 | Andrew A. Farke                                                                                                                                                    |
| 351 |     14.733802 |    567.280058 | Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey       |
| 352 |     12.879883 |    316.929860 | Ferran Sayol                                                                                                                                                       |
| 353 |    257.916966 |    642.866890 | Jagged Fang Designs                                                                                                                                                |
| 354 |    454.140283 |    582.557820 | Melissa Ingala                                                                                                                                                     |
| 355 |    244.821554 |    720.500623 | Kent Elson Sorgon                                                                                                                                                  |
| 356 |    435.129459 |    188.725933 | Margot Michaud                                                                                                                                                     |
| 357 |    431.333239 |    721.247527 | Zimices                                                                                                                                                            |
| 358 |    451.154369 |    749.365617 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                   |
| 359 |    886.540930 |    397.064002 | Cesar Julian                                                                                                                                                       |
| 360 |    513.673796 |    329.866386 | Gareth Monger                                                                                                                                                      |
| 361 |    817.875919 |    783.315423 | NA                                                                                                                                                                 |
| 362 |    288.624590 |    536.456117 | Cesar Julian                                                                                                                                                       |
| 363 |    265.037180 |     53.677894 | Matt Crook                                                                                                                                                         |
| 364 |    394.963360 |     10.959629 | Tyler McCraney                                                                                                                                                     |
| 365 |    285.589454 |    254.527067 | Gareth Monger                                                                                                                                                      |
| 366 |    140.545867 |    443.817445 | Andrew R. Gehrke                                                                                                                                                   |
| 367 |    194.493779 |    224.272678 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                   |
| 368 |    563.089142 |    290.538904 | Dmitry Bogdanov                                                                                                                                                    |
| 369 |    171.894023 |    172.730500 | Tasman Dixon                                                                                                                                                       |
| 370 |     16.679242 |    726.014227 | Ferran Sayol                                                                                                                                                       |
| 371 |    785.734248 |    401.479927 | Jagged Fang Designs                                                                                                                                                |
| 372 |    539.022810 |    622.929663 | Scott Hartman                                                                                                                                                      |
| 373 |    206.031065 |    633.658507 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                              |
| 374 |    886.096529 |    666.020023 | NA                                                                                                                                                                 |
| 375 |    214.238438 |    553.393458 | Gabriela Palomo-Munoz                                                                                                                                              |
| 376 |    428.136997 |    664.212786 | xgirouxb                                                                                                                                                           |
| 377 |    755.737743 |    494.798881 | Gabriela Palomo-Munoz                                                                                                                                              |
| 378 |    577.251896 |    495.240510 | Jagged Fang Designs                                                                                                                                                |
| 379 |    509.152049 |    751.134735 | Steven Traver                                                                                                                                                      |
| 380 |   1007.971662 |    525.819117 | Melissa Broussard                                                                                                                                                  |
| 381 |    423.515597 |     45.112322 | Matt Hayes                                                                                                                                                         |
| 382 |    657.924398 |    405.990366 | S.Martini                                                                                                                                                          |
| 383 |    156.086945 |    487.891711 | Smokeybjb                                                                                                                                                          |
| 384 |    126.147938 |    388.619556 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                             |
| 385 |    966.878587 |    741.019364 | Robert Gay, modifed from Olegivvit                                                                                                                                 |
| 386 |    807.014118 |    417.776864 | Matt Martyniuk                                                                                                                                                     |
| 387 |     86.868622 |    718.209589 | NA                                                                                                                                                                 |
| 388 |    216.692651 |    421.525364 | Steven Traver                                                                                                                                                      |
| 389 |    163.043785 |    332.009815 | Milton Tan                                                                                                                                                         |
| 390 |     78.215422 |    452.141323 | Michael P. Taylor                                                                                                                                                  |
| 391 |    533.304763 |    662.580148 | Ewald Rübsamen                                                                                                                                                     |
| 392 |    802.699161 |    706.664136 | Katie S. Collins                                                                                                                                                   |
| 393 |    175.519913 |    635.596060 | Matthias Buschmann (vectorized by T. Michael Keesey)                                                                                                               |
| 394 |    773.687698 |    783.673753 | Tyler Greenfield                                                                                                                                                   |
| 395 |    725.270663 |    585.970088 | Pete Buchholz                                                                                                                                                      |
| 396 |    488.494565 |    109.601674 | Inessa Voet                                                                                                                                                        |
| 397 |    456.258761 |    321.006651 | T. Michael Keesey                                                                                                                                                  |
| 398 |    117.147840 |    777.489808 | Steven Coombs                                                                                                                                                      |
| 399 |    117.006628 |    764.324604 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                   |
| 400 |    758.917361 |    637.891337 | Jagged Fang Designs                                                                                                                                                |
| 401 |    363.342525 |    248.746257 | Chris huh                                                                                                                                                          |
| 402 |    862.843459 |     66.928719 | Tasman Dixon                                                                                                                                                       |
| 403 |    766.323789 |    341.247529 | Felix Vaux                                                                                                                                                         |
| 404 |    195.755522 |    200.363355 | Zimices                                                                                                                                                            |
| 405 |    139.299223 |    380.116756 | NA                                                                                                                                                                 |
| 406 |    521.150584 |    170.614673 | Tasman Dixon                                                                                                                                                       |
| 407 |    732.358578 |    665.860801 | Gareth Monger                                                                                                                                                      |
| 408 |    778.009561 |    156.198476 | Scott Hartman                                                                                                                                                      |
| 409 |    227.305488 |    789.772502 | Jakovche                                                                                                                                                           |
| 410 |     48.962409 |    727.428752 | Scott Hartman                                                                                                                                                      |
| 411 |    350.403425 |    187.983646 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                           |
| 412 |    251.176288 |    705.528391 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                       |
| 413 |    125.843378 |     43.342405 | Scott Reid                                                                                                                                                         |
| 414 |    311.075516 |    466.744595 | Mathew Wedel                                                                                                                                                       |
| 415 |    652.220838 |    143.780546 | Emily Jane McTavish                                                                                                                                                |
| 416 |   1012.224693 |    587.322830 | NA                                                                                                                                                                 |
| 417 |    308.159964 |    238.638049 | Gabriela Palomo-Munoz                                                                                                                                              |
| 418 |    889.496051 |     61.627412 | Emily Willoughby                                                                                                                                                   |
| 419 |    211.035366 |    144.499734 | Kailah Thorn & Mark Hutchinson                                                                                                                                     |
| 420 |    318.354998 |    454.394582 | Benjamin Monod-Broca                                                                                                                                               |
| 421 |    209.069575 |    782.175914 | Scott Hartman                                                                                                                                                      |
| 422 |    998.550018 |    718.740116 | Zimices                                                                                                                                                            |
| 423 |    997.358420 |     22.536576 | Margot Michaud                                                                                                                                                     |
| 424 |    424.955427 |    472.759951 | Conty (vectorized by T. Michael Keesey)                                                                                                                            |
| 425 |    172.896424 |    495.470243 | Jaime Headden                                                                                                                                                      |
| 426 |    533.687787 |    511.713926 | Lukasiniho                                                                                                                                                         |
| 427 |    965.591500 |     23.637060 | Zimices                                                                                                                                                            |
| 428 |    745.264654 |    262.621506 | NA                                                                                                                                                                 |
| 429 |    456.769689 |    572.452348 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 430 |    941.395420 |    297.798663 | Zimices                                                                                                                                                            |
| 431 |    943.345608 |    394.963095 | Gareth Monger                                                                                                                                                      |
| 432 |    736.725907 |     78.546552 | NA                                                                                                                                                                 |
| 433 |    176.424182 |    692.286568 | Matt Martyniuk                                                                                                                                                     |
| 434 |    581.223589 |    349.441488 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                            |
| 435 |    541.826783 |    359.470395 | Iain Reid                                                                                                                                                          |
| 436 |    221.380027 |    669.272594 | Chris huh                                                                                                                                                          |
| 437 |    942.509827 |    747.983637 | Margot Michaud                                                                                                                                                     |
| 438 |   1007.821293 |    789.342862 | Tasman Dixon                                                                                                                                                       |
| 439 |    143.577652 |    683.036177 | Steven Traver                                                                                                                                                      |
| 440 |   1015.780357 |    175.197866 | NA                                                                                                                                                                 |
| 441 |    920.269076 |    153.318418 | Sarah Alewijnse                                                                                                                                                    |
| 442 |    657.482437 |    791.283863 | Chris huh                                                                                                                                                          |
| 443 |    894.502283 |    698.386878 | NA                                                                                                                                                                 |
| 444 |    433.042689 |    501.392175 | Gareth Monger                                                                                                                                                      |
| 445 |    664.866494 |    427.437629 | Mathieu Basille                                                                                                                                                    |
| 446 |    151.429661 |    152.777494 | Jagged Fang Designs                                                                                                                                                |
| 447 |    268.341902 |    241.821151 | Jagged Fang Designs                                                                                                                                                |
| 448 |    875.985131 |      6.121295 | Chris huh                                                                                                                                                          |
| 449 |    150.466318 |    576.724290 | Sergio A. Muñoz-Gómez                                                                                                                                              |
| 450 |    507.029820 |    772.818864 | Ferran Sayol                                                                                                                                                       |
| 451 |    533.170140 |    493.112036 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                      |
| 452 |    644.682585 |    219.193478 | Beth Reinke                                                                                                                                                        |
| 453 |    590.712555 |    454.182637 | Tasman Dixon                                                                                                                                                       |
| 454 |    954.335942 |    189.338697 | T. Michael Keesey                                                                                                                                                  |
| 455 |    588.271186 |    544.241842 | Margot Michaud                                                                                                                                                     |
| 456 |    245.139185 |      7.197798 | Darius Nau                                                                                                                                                         |
| 457 |    510.803695 |    307.201831 | Matt Crook                                                                                                                                                         |
| 458 |    870.638793 |    189.060701 | Matt Crook                                                                                                                                                         |
| 459 |    727.264799 |     93.019118 | Scott Hartman                                                                                                                                                      |
| 460 |    463.412890 |    341.160585 | Jagged Fang Designs                                                                                                                                                |
| 461 |     20.538727 |    518.497807 | Nobu Tamura                                                                                                                                                        |
| 462 |    827.631178 |    633.617399 | NA                                                                                                                                                                 |
| 463 |     15.806623 |    171.922583 | T. Michael Keesey                                                                                                                                                  |
| 464 |    988.511022 |    617.230247 | Smokeybjb                                                                                                                                                          |
| 465 |    394.164954 |    661.074165 | Jay Matternes (modified by T. Michael Keesey)                                                                                                                      |
| 466 |    813.644275 |    327.056945 | Steven Traver                                                                                                                                                      |
| 467 |    611.309203 |    773.157332 | Lafage                                                                                                                                                             |
| 468 |   1002.944306 |    361.423754 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                     |
| 469 |    827.544945 |    289.309029 | Scott Hartman                                                                                                                                                      |
| 470 |    572.082120 |    114.957446 | Scott Hartman                                                                                                                                                      |
| 471 |    270.130257 |    228.162166 | Matt Dempsey                                                                                                                                                       |
| 472 |    629.463628 |    152.294495 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                       |
| 473 |    460.562290 |    214.743483 | NA                                                                                                                                                                 |
| 474 |    249.841128 |    334.184565 | Milton Tan                                                                                                                                                         |
| 475 |    963.433932 |    229.920698 | Zimices                                                                                                                                                            |
| 476 |    480.990446 |    417.618677 | Alexander Schmidt-Lebuhn                                                                                                                                           |
| 477 |    776.207831 |    699.505711 | Craig Dylke                                                                                                                                                        |
| 478 |    899.673240 |    441.326863 | Joanna Wolfe                                                                                                                                                       |
| 479 |    226.911156 |    743.056405 | Felix Vaux                                                                                                                                                         |
| 480 |    620.448426 |    495.386564 | Geoff Shaw                                                                                                                                                         |
| 481 |    544.589373 |    196.807117 | Sarah Werning                                                                                                                                                      |
| 482 |    731.431043 |    771.638826 | Matt Crook                                                                                                                                                         |
| 483 |    323.189257 |    534.612614 | Felix Vaux                                                                                                                                                         |
| 484 |    527.681050 |    467.471314 | T. Michael Keesey                                                                                                                                                  |
| 485 |    277.945294 |    484.428033 | T. Michael Keesey                                                                                                                                                  |
| 486 |    601.921682 |    254.679251 | CNZdenek                                                                                                                                                           |
| 487 |    408.250735 |    287.741034 | Zimices                                                                                                                                                            |
| 488 |    951.946239 |    679.309507 | Ghedoghedo                                                                                                                                                         |
| 489 |      6.690332 |    213.278950 | Margot Michaud                                                                                                                                                     |
| 490 |    452.497963 |    228.125526 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 491 |    101.825286 |    116.784010 | Nobu Tamura, vectorized by Zimices                                                                                                                                 |
| 492 |    133.881170 |    462.888183 | NA                                                                                                                                                                 |
| 493 |    432.787850 |    683.648054 | Chris huh                                                                                                                                                          |
| 494 |    606.724015 |    731.112892 | Iain Reid                                                                                                                                                          |
| 495 |   1008.478283 |    384.959407 | Gareth Monger                                                                                                                                                      |
| 496 |    865.353949 |    295.677521 | Matt Crook                                                                                                                                                         |
| 497 |     67.488295 |    775.743600 | Chris huh                                                                                                                                                          |
| 498 |    457.570059 |    269.669861 | NA                                                                                                                                                                 |
| 499 |    843.488414 |    439.234902 | Chris huh                                                                                                                                                          |
| 500 |    198.605568 |     63.556162 | FunkMonk                                                                                                                                                           |
| 501 |    578.303382 |    532.085295 | Henry Lydecker                                                                                                                                                     |
| 502 |    750.023154 |    796.090331 | Duane Raver/USFWS                                                                                                                                                  |
| 503 |    699.506103 |    344.993010 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 504 |    526.243710 |    143.802274 | Caleb M. Brown                                                                                                                                                     |
| 505 |    802.248073 |     99.224732 | Campbell Fleming                                                                                                                                                   |
| 506 |    928.779472 |    568.784774 | Scott Hartman                                                                                                                                                      |
| 507 |    759.391061 |    221.985736 | Chris huh                                                                                                                                                          |

    #> Your tweet has been posted!
