
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

Jagged Fang Designs, Obsidian Soul (vectorized by T. Michael Keesey),
Smokeybjb, Kanako Bessho-Uehara, C. Camilo Julián-Caballero, Birgit
Lang, Crystal Maier, Gareth Monger, Xavier A. Jenkins, Gabriel Ugueto,
Jessica Anne Miller, Ferran Sayol, Collin Gross, Rebecca Groom, Richard
Parker (vectorized by T. Michael Keesey), Archaeodontosaurus (vectorized
by T. Michael Keesey), Manabu Sakamoto, Sean McCann, Chris huh, Dmitry
Bogdanov, Madeleine Price Ball, Chris Hay, Zimices, based in Mauricio
Antón skeletal, Andy Wilson, Iain Reid, Campbell Fleming, Gabriela
Palomo-Munoz, Fcb981 (vectorized by T. Michael Keesey), Jaime Headden,
Felix Vaux, Ingo Braasch, Steven Traver, Zimices, Sarah Werning, Martin
R. Smith, Tasman Dixon, Matt Celeskey, Ron Holmes/U. S. Fish and
Wildlife Service (source photo), T. Michael Keesey (vectorization),
Margot Michaud, Yan Wong, Dean Schnabel, Kamil S. Jaron, Beth Reinke,
Markus A. Grohme, Terpsichores, Skye M, Joseph J. W. Sertich, Mark A.
Loewen, Robert Gay, Matt Martyniuk, Dmitry Bogdanov (vectorized by T.
Michael Keesey), Manabu Bessho-Uehara, T. Michael Keesey, Scott Hartman,
Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes
(www.carnivorosaustrales.org), Mattia Menchetti / Yan Wong, David Orr,
Nobu Tamura (modified by T. Michael Keesey), Jessica Rick, Thea Boodhoo
(photograph) and T. Michael Keesey (vectorization), Javiera Constanzo,
Matt Crook, Lip Kee Yap (vectorized by T. Michael Keesey), CNZdenek,
Melissa Broussard, Sharon Wegner-Larsen, S.Martini, Armin Reindl, Mali’o
Kodis, image from the “Proceedings of the Zoological Society of London”,
Harold N Eyster, Brad McFeeters (vectorized by T. Michael Keesey),
Ignacio Contreras, Andrew A. Farke, Todd Marshall, vectorized by
Zimices, Christopher Watson (photo) and T. Michael Keesey
(vectorization), Roderic Page and Lois Page, Trond R. Oskars, Inessa
Voet, annaleeblysse, FunkMonk (Michael B.H.; vectorized by T. Michael
Keesey), Joanna Wolfe, Mathew Wedel, Kimberly Haddrell, Natalie Claunch,
Wynston Cooper (photo) and Albertonykus (silhouette), Pranav Iyer (grey
ideas), Emily Willoughby, James Neenan, Liftarn, Brian Gratwicke (photo)
and T. Michael Keesey (vectorization), Fernando Carezzano, Marie
Russell, Andreas Trepte (vectorized by T. Michael Keesey), Michelle
Site, Emma Hughes, Maky (vectorization), Gabriella Skollar
(photography), Rebecca Lewis (editing), Rachel Shoop, Claus Rebler,
Jiekun He, Mathilde Cordellier, Robert Hering, Yan Wong (vectorization)
from 1873 illustration, Jake Warner, Christine Axon, Alexander
Schmidt-Lebuhn, Juan Carlos Jerí, Ludwik Gąsiorowski, Kai R. Caspar,
Ghedoghedo (vectorized by T. Michael Keesey), Arthur S. Brum, Nobu
Tamura (vectorized by T. Michael Keesey), FunkMonk, LeonardoG
(photography) and T. Michael Keesey (vectorization), Matt Dempsey,
Christoph Schomburg, Christina N. Hodson, Jaime Chirinos (vectorized by
T. Michael Keesey), Scarlet23 (vectorized by T. Michael Keesey), André
Karwath (vectorized by T. Michael Keesey), Tracy A. Heath, Chris A.
Hamilton, Mike Hanson, Chuanixn Yu, Noah Schlottman, photo by Martin V.
Sørensen, Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J.
Bartley (silhouette), Charles R. Knight, vectorized by Zimices, Caleb
Brown, Chase Brownstein, Karina Garcia, Steven Coombs, Matt Wilkins,
Smith609 and T. Michael Keesey, Zachary Quigley, Tommaso Cancellario,
Martin Kevil, Nobu Tamura, vectorized by Zimices, Caio Bernardes,
vectorized by Zimices, Hans Hillewaert, Berivan Temiz, Jan A. Venter,
Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T.
Michael Keesey), Cristopher Silva, Dennis C. Murphy, after
<https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png>,
Heinrich Harder (vectorized by William Gearty), Noah Schlottman, Agnello
Picorelli, Vanessa Guerra, Tyler Greenfield, Mali’o Kodis, photograph by
Jim Vargo, Carlos Cano-Barbacil, Anthony Caravaggi, Julio Garza, Julie
Blommaert based on photo by Sofdrakou, Dinah Challen, Robbie N. Cada
(modified by T. Michael Keesey), David Sim (photograph) and T. Michael
Keesey (vectorization), Lee Harding (photo), John E. McCormack, Michael
G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn,
Robb T. Brumfield & T. Michael Keesey, Jimmy Bernot, Noah Schlottman,
photo from Casey Dunn, Thibaut Brunet, Dexter R. Mardis, Ieuan Jones,
Andrew A. Farke, modified from original by H. Milne Edwards, Danielle
Alba, Tony Ayling (vectorized by T. Michael Keesey), Original drawing by
Nobu Tamura, vectorized by Roberto Díaz Sibaja, U.S. Fish and Wildlife
Service (illustration) and Timothy J. Bartley (silhouette), M Kolmann,
Ville Koistinen and T. Michael Keesey, Maija Karala, Henry Fairfield
Osborn, vectorized by Zimices, Kailah Thorn & Mark Hutchinson, Michael
Scroggie, from original photograph by Gary M. Stolz, USFWS (original
photograph in public domain)., Apokryltaros (vectorized by T. Michael
Keesey), Smokeybjb, vectorized by Zimices, Shyamal, Robert Gay, modified
from FunkMonk (Michael B.H.) and T. Michael Keesey., Steven Blackwood,
Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey
(vectorization), Pete Buchholz, Neil Kelley, Nobu Tamura (vectorized by
A. Verrière), Michael Scroggie, H. Filhol (vectorized by T. Michael
Keesey), Steven Haddock • Jellywatch.org, Taenadoman, david maas / dave
hone, Lukas Panzarin (vectorized by T. Michael Keesey), Lukasiniho, V.
Deepak, Erika Schumacher, Audrey Ely, Myriam\_Ramirez, Milton Tan, Filip
em, Julia B McHugh, I. Geoffroy Saint-Hilaire (vectorized by T. Michael
Keesey), Alexandre Vong, Kanchi Nanjo, FJDegrange, Meliponicultor
Itaymbere, James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo
Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael
Keesey), Mathieu Basille, L. Shyamal, Ricardo Araújo, Xavier
Giroux-Bougard, Walter Vladimir, Mette Aumala, FunkMonk \[Michael B.H.\]
(modified by T. Michael Keesey), Bruno Maggia

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                          |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
|   1 |    766.047543 |    540.519148 | Jagged Fang Designs                                                                                                                                                             |
|   2 |    431.336888 |    755.549253 | Jagged Fang Designs                                                                                                                                                             |
|   3 |    646.742247 |    725.339935 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                 |
|   4 |    590.866076 |    436.611978 | Smokeybjb                                                                                                                                                                       |
|   5 |    137.146630 |     44.884240 | Kanako Bessho-Uehara                                                                                                                                                            |
|   6 |    871.676841 |    139.210823 | C. Camilo Julián-Caballero                                                                                                                                                      |
|   7 |    257.968223 |    567.249772 | Birgit Lang                                                                                                                                                                     |
|   8 |    432.968295 |    351.623161 | NA                                                                                                                                                                              |
|   9 |     82.609985 |    353.328663 | Crystal Maier                                                                                                                                                                   |
|  10 |    465.575901 |    589.790155 | Gareth Monger                                                                                                                                                                   |
|  11 |    411.973244 |    245.129555 | C. Camilo Julián-Caballero                                                                                                                                                      |
|  12 |    120.497200 |    213.513569 | Xavier A. Jenkins, Gabriel Ugueto                                                                                                                                               |
|  13 |    805.701974 |    704.290909 | Jessica Anne Miller                                                                                                                                                             |
|  14 |    729.496460 |     86.066249 | Ferran Sayol                                                                                                                                                                    |
|  15 |    954.207131 |    383.590755 | Collin Gross                                                                                                                                                                    |
|  16 |    855.571780 |    383.412080 | NA                                                                                                                                                                              |
|  17 |    591.444186 |    546.615070 | Rebecca Groom                                                                                                                                                                   |
|  18 |    810.873764 |    250.442438 | Richard Parker (vectorized by T. Michael Keesey)                                                                                                                                |
|  19 |    533.597417 |    683.788501 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                            |
|  20 |    741.312741 |    412.424158 | Manabu Sakamoto                                                                                                                                                                 |
|  21 |    245.428684 |    342.679037 | Sean McCann                                                                                                                                                                     |
|  22 |     74.693129 |    753.948869 | Chris huh                                                                                                                                                                       |
|  23 |    441.210908 |    186.311289 | Dmitry Bogdanov                                                                                                                                                                 |
|  24 |    544.612291 |    362.453983 | Madeleine Price Ball                                                                                                                                                            |
|  25 |    657.167038 |    482.945092 | Gareth Monger                                                                                                                                                                   |
|  26 |    670.132796 |    309.046609 | Chris Hay                                                                                                                                                                       |
|  27 |    584.708301 |    172.185908 | Zimices, based in Mauricio Antón skeletal                                                                                                                                       |
|  28 |    168.166736 |    529.687334 | Andy Wilson                                                                                                                                                                     |
|  29 |    291.474721 |    203.754999 | Iain Reid                                                                                                                                                                       |
|  30 |    134.300746 |    699.041670 | Campbell Fleming                                                                                                                                                                |
|  31 |    366.574375 |     39.074500 | Gabriela Palomo-Munoz                                                                                                                                                           |
|  32 |    907.608928 |    599.734516 | Fcb981 (vectorized by T. Michael Keesey)                                                                                                                                        |
|  33 |    414.197472 |    512.781092 | Jaime Headden                                                                                                                                                                   |
|  34 |    952.797647 |    484.863971 | Felix Vaux                                                                                                                                                                      |
|  35 |    651.375727 |    110.788360 | Gareth Monger                                                                                                                                                                   |
|  36 |    356.576519 |    703.856331 | Ingo Braasch                                                                                                                                                                    |
|  37 |    945.213824 |    693.264937 | Steven Traver                                                                                                                                                                   |
|  38 |    511.454021 |     42.280372 | Zimices                                                                                                                                                                         |
|  39 |    712.988108 |    650.124796 | Sarah Werning                                                                                                                                                                   |
|  40 |    225.616923 |    125.284798 | Martin R. Smith                                                                                                                                                                 |
|  41 |    252.392608 |    757.697778 | Chris huh                                                                                                                                                                       |
|  42 |    925.356775 |    749.633889 | Tasman Dixon                                                                                                                                                                    |
|  43 |    119.211382 |    132.137788 | Gabriela Palomo-Munoz                                                                                                                                                           |
|  44 |    957.909206 |    258.408958 | Ferran Sayol                                                                                                                                                                    |
|  45 |    279.402882 |    471.858825 | Matt Celeskey                                                                                                                                                                   |
|  46 |    553.778826 |    276.229372 | Gareth Monger                                                                                                                                                                   |
|  47 |    254.621393 |    650.845976 | Ron Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                                    |
|  48 |    857.526980 |    313.808121 | Chris huh                                                                                                                                                                       |
|  49 |    358.120486 |    116.950508 | Margot Michaud                                                                                                                                                                  |
|  50 |    874.987987 |     60.291275 | Yan Wong                                                                                                                                                                        |
|  51 |    622.599688 |    620.072823 | Dean Schnabel                                                                                                                                                                   |
|  52 |    124.882081 |    467.535635 | Kamil S. Jaron                                                                                                                                                                  |
|  53 |    831.368178 |    460.840771 | Beth Reinke                                                                                                                                                                     |
|  54 |    142.015935 |    621.903627 | Markus A. Grohme                                                                                                                                                                |
|  55 |     49.188747 |     70.963022 | Terpsichores                                                                                                                                                                    |
|  56 |    836.665077 |    520.959730 | NA                                                                                                                                                                              |
|  57 |    429.751175 |    449.012460 | Gabriela Palomo-Munoz                                                                                                                                                           |
|  58 |    437.996572 |    649.412221 | Skye M                                                                                                                                                                          |
|  59 |    698.841020 |    187.284413 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                            |
|  60 |    836.599352 |     39.130326 | Jagged Fang Designs                                                                                                                                                             |
|  61 |    959.834118 |    175.857814 | Collin Gross                                                                                                                                                                    |
|  62 |    528.739349 |    771.415550 | Robert Gay                                                                                                                                                                      |
|  63 |    354.279638 |    419.252930 | Chris huh                                                                                                                                                                       |
|  64 |    687.870496 |    500.571074 | Jagged Fang Designs                                                                                                                                                             |
|  65 |    804.847355 |    158.720880 | Matt Martyniuk                                                                                                                                                                  |
|  66 |    622.470903 |     33.617979 | Margot Michaud                                                                                                                                                                  |
|  67 |     43.446994 |    582.019235 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
|  68 |    958.574383 |    437.118446 | Chris huh                                                                                                                                                                       |
|  69 |     40.183255 |    664.921759 | Dean Schnabel                                                                                                                                                                   |
|  70 |    479.814849 |    104.965385 | Manabu Bessho-Uehara                                                                                                                                                            |
|  71 |    240.863618 |    435.098580 | T. Michael Keesey                                                                                                                                                               |
|  72 |    225.958839 |    713.120157 | Markus A. Grohme                                                                                                                                                                |
|  73 |     61.515618 |    245.754667 | Zimices                                                                                                                                                                         |
|  74 |    238.593878 |     65.026225 | Scott Hartman                                                                                                                                                                   |
|  75 |    539.704371 |    410.815609 | Gareth Monger                                                                                                                                                                   |
|  76 |    683.789312 |    223.154460 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                                    |
|  77 |    185.528784 |    329.369054 | Mattia Menchetti / Yan Wong                                                                                                                                                     |
|  78 |    502.635238 |    182.616303 | David Orr                                                                                                                                                                       |
|  79 |    752.297912 |    775.462444 | Chris huh                                                                                                                                                                       |
|  80 |    735.473787 |    720.152611 | Scott Hartman                                                                                                                                                                   |
|  81 |    298.831943 |     79.070213 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                     |
|  82 |    864.475094 |    780.239803 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
|  83 |    993.438123 |     32.984559 | Gabriela Palomo-Munoz                                                                                                                                                           |
|  84 |    981.989107 |    518.066937 | Margot Michaud                                                                                                                                                                  |
|  85 |    448.785238 |     22.495591 | T. Michael Keesey                                                                                                                                                               |
|  86 |    989.549193 |    107.267157 | Birgit Lang                                                                                                                                                                     |
|  87 |    792.840712 |    616.993593 | Scott Hartman                                                                                                                                                                   |
|  88 |    778.053352 |    355.410739 | Scott Hartman                                                                                                                                                                   |
|  89 |    224.192119 |     29.161775 | Chris huh                                                                                                                                                                       |
|  90 |    458.567635 |    286.158838 | Chris huh                                                                                                                                                                       |
|  91 |    156.716759 |    277.038348 | Gareth Monger                                                                                                                                                                   |
|  92 |    984.611160 |    755.158792 | Jessica Rick                                                                                                                                                                    |
|  93 |    859.899499 |    681.740991 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                                 |
|  94 |    538.092058 |    618.652902 | Javiera Constanzo                                                                                                                                                               |
|  95 |    905.952897 |    267.852493 | Matt Crook                                                                                                                                                                      |
|  96 |    346.272447 |    172.447721 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                                   |
|  97 |    585.547932 |    311.648731 | CNZdenek                                                                                                                                                                        |
|  98 |    363.977345 |    615.803657 | Melissa Broussard                                                                                                                                                               |
|  99 |    758.291742 |    479.497483 | Sharon Wegner-Larsen                                                                                                                                                            |
| 100 |    373.323404 |    675.318325 | S.Martini                                                                                                                                                                       |
| 101 |    618.595564 |    356.656177 | Markus A. Grohme                                                                                                                                                                |
| 102 |     78.563954 |    527.269993 | Margot Michaud                                                                                                                                                                  |
| 103 |    245.968018 |    265.934004 | Armin Reindl                                                                                                                                                                    |
| 104 |    148.745003 |    168.276263 | Chris huh                                                                                                                                                                       |
| 105 |    614.648349 |    765.510698 | NA                                                                                                                                                                              |
| 106 |    993.190740 |    607.719273 | Gareth Monger                                                                                                                                                                   |
| 107 |    734.693366 |    258.350913 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                                                  |
| 108 |    194.712162 |    410.113411 | Felix Vaux                                                                                                                                                                      |
| 109 |    335.753631 |    772.776579 | Harold N Eyster                                                                                                                                                                 |
| 110 |    170.164794 |     86.197058 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                |
| 111 |     86.411689 |    695.983594 | Zimices                                                                                                                                                                         |
| 112 |    269.368457 |    792.722444 | Ignacio Contreras                                                                                                                                                               |
| 113 |    955.326712 |     46.096365 | Ferran Sayol                                                                                                                                                                    |
| 114 |    924.644569 |     94.321607 | Jaime Headden                                                                                                                                                                   |
| 115 |    243.037223 |    242.924449 | Margot Michaud                                                                                                                                                                  |
| 116 |    618.225841 |    383.385057 | Matt Crook                                                                                                                                                                      |
| 117 |    862.290062 |    629.278969 | Andrew A. Farke                                                                                                                                                                 |
| 118 |    457.199465 |     54.115660 | Steven Traver                                                                                                                                                                   |
| 119 |    319.020749 |    348.448799 | Tasman Dixon                                                                                                                                                                    |
| 120 |    218.012514 |    537.674078 | Todd Marshall, vectorized by Zimices                                                                                                                                            |
| 121 |    379.155661 |    468.277626 | Gareth Monger                                                                                                                                                                   |
| 122 |    948.363320 |    790.383609 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                     |
| 123 |    260.012590 |    258.079251 | Smokeybjb                                                                                                                                                                       |
| 124 |    785.505499 |    423.861877 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                                                |
| 125 |    630.257250 |    677.855549 | Roderic Page and Lois Page                                                                                                                                                      |
| 126 |    561.879427 |     86.353585 | Dean Schnabel                                                                                                                                                                   |
| 127 |    334.165547 |    479.863392 | Sharon Wegner-Larsen                                                                                                                                                            |
| 128 |    160.882679 |    183.413440 | Chris huh                                                                                                                                                                       |
| 129 |    549.249831 |    483.937291 | Matt Crook                                                                                                                                                                      |
| 130 |   1001.649475 |    572.171991 | Trond R. Oskars                                                                                                                                                                 |
| 131 |    541.237488 |    519.792398 | Inessa Voet                                                                                                                                                                     |
| 132 |    861.700455 |    196.999663 | NA                                                                                                                                                                              |
| 133 |    348.532561 |    364.618196 | annaleeblysse                                                                                                                                                                   |
| 134 |    886.385895 |    541.797559 | Gareth Monger                                                                                                                                                                   |
| 135 |    265.921331 |    229.606900 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                                        |
| 136 |    221.851843 |    670.271234 | Matt Crook                                                                                                                                                                      |
| 137 |    120.884948 |    708.924763 | Joanna Wolfe                                                                                                                                                                    |
| 138 |    342.723526 |    733.155612 | Mathew Wedel                                                                                                                                                                    |
| 139 |    472.904219 |    308.627009 | Kimberly Haddrell                                                                                                                                                               |
| 140 |    850.375191 |    481.460074 | Margot Michaud                                                                                                                                                                  |
| 141 |     16.520887 |    590.166406 | Natalie Claunch                                                                                                                                                                 |
| 142 |    767.199727 |     32.751280 | S.Martini                                                                                                                                                                       |
| 143 |    714.194668 |    299.020448 | Zimices                                                                                                                                                                         |
| 144 |    527.050546 |    225.935205 | Wynston Cooper (photo) and Albertonykus (silhouette)                                                                                                                            |
| 145 |    691.787176 |    594.520586 | Melissa Broussard                                                                                                                                                               |
| 146 |    856.657908 |    726.596798 | Pranav Iyer (grey ideas)                                                                                                                                                        |
| 147 |    235.774113 |    376.184264 | Emily Willoughby                                                                                                                                                                |
| 148 |    269.948522 |     37.197906 | NA                                                                                                                                                                              |
| 149 |    820.517854 |    414.326003 | James Neenan                                                                                                                                                                    |
| 150 |    575.507630 |    127.720561 | Liftarn                                                                                                                                                                         |
| 151 |    984.420178 |    785.043692 | Brian Gratwicke (photo) and T. Michael Keesey (vectorization)                                                                                                                   |
| 152 |    348.585873 |    449.726561 | Fernando Carezzano                                                                                                                                                              |
| 153 |    297.716421 |    286.023038 | Steven Traver                                                                                                                                                                   |
| 154 |    175.988342 |    587.991945 | David Orr                                                                                                                                                                       |
| 155 |    533.772118 |    123.916499 | Zimices                                                                                                                                                                         |
| 156 |    874.050797 |    257.448466 | Matt Crook                                                                                                                                                                      |
| 157 |    193.006302 |    657.063692 | Marie Russell                                                                                                                                                                   |
| 158 |    846.341887 |    760.837297 | Matt Crook                                                                                                                                                                      |
| 159 |     27.880333 |    426.180068 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                                |
| 160 |    481.707494 |    531.100901 | Michelle Site                                                                                                                                                                   |
| 161 |    197.551270 |    470.740784 | Emma Hughes                                                                                                                                                                     |
| 162 |    785.467653 |     56.421029 | Sarah Werning                                                                                                                                                                   |
| 163 |    745.827623 |      6.127048 | NA                                                                                                                                                                              |
| 164 |    750.840966 |    366.361867 | Maky (vectorization), Gabriella Skollar (photography), Rebecca Lewis (editing)                                                                                                  |
| 165 |    915.797549 |    426.000475 | Rachel Shoop                                                                                                                                                                    |
| 166 |    462.953864 |    709.506275 | Claus Rebler                                                                                                                                                                    |
| 167 |    529.158019 |    336.669887 | Jiekun He                                                                                                                                                                       |
| 168 |    941.328777 |    643.817493 | Andy Wilson                                                                                                                                                                     |
| 169 |     53.038255 |    151.359663 | NA                                                                                                                                                                              |
| 170 |    944.343472 |    314.588450 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 171 |    205.153388 |    744.764726 | NA                                                                                                                                                                              |
| 172 |    974.572081 |    573.804071 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                            |
| 173 |   1008.025943 |    262.604992 | Mathilde Cordellier                                                                                                                                                             |
| 174 |    822.089951 |    181.627534 | Scott Hartman                                                                                                                                                                   |
| 175 |   1003.255645 |    675.171828 | Felix Vaux                                                                                                                                                                      |
| 176 |    678.088670 |    655.444921 | T. Michael Keesey                                                                                                                                                               |
| 177 |    352.008834 |    290.499743 | Yan Wong                                                                                                                                                                        |
| 178 |    851.797315 |    555.078594 | Gareth Monger                                                                                                                                                                   |
| 179 |    605.158668 |    731.210266 | Markus A. Grohme                                                                                                                                                                |
| 180 |    700.197057 |    372.595036 | Robert Hering                                                                                                                                                                   |
| 181 |     51.971801 |    120.668109 | Beth Reinke                                                                                                                                                                     |
| 182 |    185.627455 |    280.507563 | Yan Wong (vectorization) from 1873 illustration                                                                                                                                 |
| 183 |    651.382750 |    687.341678 | Jake Warner                                                                                                                                                                     |
| 184 |    272.297774 |    632.578265 | Matt Crook                                                                                                                                                                      |
| 185 |    918.571187 |     64.464232 | Jagged Fang Designs                                                                                                                                                             |
| 186 |    306.338725 |     44.435563 | Christine Axon                                                                                                                                                                  |
| 187 |    614.321051 |    589.257327 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 188 |    293.839830 |    240.910971 | Juan Carlos Jerí                                                                                                                                                                |
| 189 |    462.955873 |    741.833836 | Steven Traver                                                                                                                                                                   |
| 190 |    115.879403 |    499.410516 | Ludwik Gąsiorowski                                                                                                                                                              |
| 191 |     15.556555 |    149.851352 | Jagged Fang Designs                                                                                                                                                             |
| 192 |     19.433439 |    381.398964 | Kai R. Caspar                                                                                                                                                                   |
| 193 |    206.319818 |    565.257433 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                    |
| 194 |    416.164854 |    734.948029 | Arthur S. Brum                                                                                                                                                                  |
| 195 |    645.057835 |    589.545447 | NA                                                                                                                                                                              |
| 196 |    728.332024 |    169.062159 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 197 |    978.664573 |    663.397856 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 198 |    686.352852 |    443.969413 | FunkMonk                                                                                                                                                                        |
| 199 |    781.780058 |    476.429019 | NA                                                                                                                                                                              |
| 200 |     24.318949 |    293.189534 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                                                   |
| 201 |     28.445550 |    498.784540 | Ferran Sayol                                                                                                                                                                    |
| 202 |    777.824065 |    582.458318 | Margot Michaud                                                                                                                                                                  |
| 203 |    768.991638 |    492.538128 | Jagged Fang Designs                                                                                                                                                             |
| 204 |    650.971640 |    780.246545 | Matt Crook                                                                                                                                                                      |
| 205 |    347.304185 |    503.227439 | Matt Crook                                                                                                                                                                      |
| 206 |    727.727234 |    324.598336 | Matt Dempsey                                                                                                                                                                    |
| 207 |    774.649748 |    320.862255 | NA                                                                                                                                                                              |
| 208 |     29.402559 |    446.068069 | Gareth Monger                                                                                                                                                                   |
| 209 |    192.368320 |    394.807862 | Jaime Headden                                                                                                                                                                   |
| 210 |    879.003439 |     95.285095 | Matt Crook                                                                                                                                                                      |
| 211 |     15.875986 |    192.264370 | Christoph Schomburg                                                                                                                                                             |
| 212 |    322.861521 |    531.188232 | Gareth Monger                                                                                                                                                                   |
| 213 |    856.817096 |     60.386208 | Birgit Lang                                                                                                                                                                     |
| 214 |    920.482060 |    779.286828 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 215 |    300.959641 |    513.898083 | Christina N. Hodson                                                                                                                                                             |
| 216 |    887.125750 |    691.824605 | Matt Crook                                                                                                                                                                      |
| 217 |    150.429120 |    774.196610 | NA                                                                                                                                                                              |
| 218 |    738.559264 |    576.374062 | Scott Hartman                                                                                                                                                                   |
| 219 |    323.418787 |    663.437056 | Zimices                                                                                                                                                                         |
| 220 |    139.778276 |    785.414168 | Zimices                                                                                                                                                                         |
| 221 |    204.717654 |    599.418767 | Ludwik Gąsiorowski                                                                                                                                                              |
| 222 |    102.866010 |    592.107383 | NA                                                                                                                                                                              |
| 223 |    917.613633 |    518.031499 | Manabu Bessho-Uehara                                                                                                                                                            |
| 224 |    394.880688 |    774.202260 | Michelle Site                                                                                                                                                                   |
| 225 |    836.970252 |    577.012898 | T. Michael Keesey                                                                                                                                                               |
| 226 |    798.514946 |     73.360697 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 227 |    374.618963 |    786.474365 | Jaime Chirinos (vectorized by T. Michael Keesey)                                                                                                                                |
| 228 |    372.433442 |    734.052100 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                                     |
| 229 |    149.158137 |    581.163717 | Collin Gross                                                                                                                                                                    |
| 230 |    143.342884 |    435.363509 | Dean Schnabel                                                                                                                                                                   |
| 231 |    929.585785 |    555.078755 | T. Michael Keesey                                                                                                                                                               |
| 232 |    461.731393 |    774.586253 | T. Michael Keesey                                                                                                                                                               |
| 233 |    435.295067 |    478.692334 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 234 |    897.665036 |     27.276233 | Christoph Schomburg                                                                                                                                                             |
| 235 |    360.529597 |    644.851849 | Jagged Fang Designs                                                                                                                                                             |
| 236 |    594.113323 |    207.456004 | André Karwath (vectorized by T. Michael Keesey)                                                                                                                                 |
| 237 |    490.384904 |    695.434122 | Tracy A. Heath                                                                                                                                                                  |
| 238 |    582.364745 |    666.962161 | Chris A. Hamilton                                                                                                                                                               |
| 239 |    633.840400 |    268.199445 | Tasman Dixon                                                                                                                                                                    |
| 240 |    103.469576 |    658.482905 | NA                                                                                                                                                                              |
| 241 |    373.610783 |    197.399397 | NA                                                                                                                                                                              |
| 242 |    310.111517 |    167.620763 | Jagged Fang Designs                                                                                                                                                             |
| 243 |   1005.527240 |    645.065923 | Mike Hanson                                                                                                                                                                     |
| 244 |    246.964780 |    285.960344 | Chuanixn Yu                                                                                                                                                                     |
| 245 |    799.861840 |     94.574548 | Tasman Dixon                                                                                                                                                                    |
| 246 |    183.217821 |    107.302861 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                                    |
| 247 |    422.707599 |    719.707756 | Margot Michaud                                                                                                                                                                  |
| 248 |    508.003351 |    793.403303 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                               |
| 249 |    974.460289 |    537.166888 | Chris huh                                                                                                                                                                       |
| 250 |    276.000462 |    167.279153 | Charles R. Knight, vectorized by Zimices                                                                                                                                        |
| 251 |    993.422891 |    548.517962 | Ferran Sayol                                                                                                                                                                    |
| 252 |    768.476810 |    105.293224 | Matt Crook                                                                                                                                                                      |
| 253 |    689.643285 |     17.030399 | Zimices                                                                                                                                                                         |
| 254 |    336.775794 |    330.913168 | T. Michael Keesey                                                                                                                                                               |
| 255 |    878.038418 |    134.667108 | Chris huh                                                                                                                                                                       |
| 256 |    752.202748 |    677.177925 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 257 |    368.728992 |    391.840260 | Michelle Site                                                                                                                                                                   |
| 258 |    382.979199 |    169.212711 | Tasman Dixon                                                                                                                                                                    |
| 259 |   1012.249870 |    321.466130 | Michelle Site                                                                                                                                                                   |
| 260 |    304.503327 |    357.784909 | Caleb Brown                                                                                                                                                                     |
| 261 |    885.946701 |    191.100007 | Iain Reid                                                                                                                                                                       |
| 262 |     35.909459 |    786.062694 | Markus A. Grohme                                                                                                                                                                |
| 263 |    905.043314 |    221.070339 | NA                                                                                                                                                                              |
| 264 |    752.511421 |    127.471332 | Gareth Monger                                                                                                                                                                   |
| 265 |    725.945245 |    314.943088 | Markus A. Grohme                                                                                                                                                                |
| 266 |    950.208944 |    516.623745 | Chase Brownstein                                                                                                                                                                |
| 267 |     14.951321 |    320.014833 | Karina Garcia                                                                                                                                                                   |
| 268 |    878.099709 |    485.360393 | Steven Traver                                                                                                                                                                   |
| 269 |    286.575273 |    300.615577 | Steven Coombs                                                                                                                                                                   |
| 270 |     80.537117 |    655.234665 | Gareth Monger                                                                                                                                                                   |
| 271 |    398.660086 |    156.141888 | T. Michael Keesey                                                                                                                                                               |
| 272 |    877.412443 |    154.525404 | Matt Wilkins                                                                                                                                                                    |
| 273 |    285.975008 |    127.222893 | Smith609 and T. Michael Keesey                                                                                                                                                  |
| 274 |    693.550863 |    528.635056 | Scott Hartman                                                                                                                                                                   |
| 275 |    241.637772 |    730.123921 | Zachary Quigley                                                                                                                                                                 |
| 276 |    970.486611 |     74.772964 | Tommaso Cancellario                                                                                                                                                             |
| 277 |    353.617995 |    213.906903 | Martin Kevil                                                                                                                                                                    |
| 278 |   1000.922151 |    209.994583 | Gareth Monger                                                                                                                                                                   |
| 279 |    510.140645 |    425.554218 | T. Michael Keesey                                                                                                                                                               |
| 280 |    731.949555 |    754.251760 | Zimices                                                                                                                                                                         |
| 281 |    189.894760 |    789.090487 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 282 |    143.925468 |    500.007824 | Gareth Monger                                                                                                                                                                   |
| 283 |    692.082330 |    359.574184 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 284 |    130.862618 |     95.999342 | Caio Bernardes, vectorized by Zimices                                                                                                                                           |
| 285 |    592.235489 |    714.024544 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 286 |    310.989332 |    441.180201 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 287 |    905.344751 |    206.580744 | Birgit Lang                                                                                                                                                                     |
| 288 |    709.019923 |    472.977936 | Hans Hillewaert                                                                                                                                                                 |
| 289 |     97.342597 |    231.751028 | Birgit Lang                                                                                                                                                                     |
| 290 |    931.764351 |    342.231503 | NA                                                                                                                                                                              |
| 291 |    420.134012 |    561.629990 | Margot Michaud                                                                                                                                                                  |
| 292 |    240.005306 |     45.812799 | Berivan Temiz                                                                                                                                                                   |
| 293 |    948.185849 |    130.187646 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                             |
| 294 |    914.089720 |    713.346430 | Ferran Sayol                                                                                                                                                                    |
| 295 |    709.335371 |    456.066379 | Cristopher Silva                                                                                                                                                                |
| 296 |    289.294070 |     15.674987 | Margot Michaud                                                                                                                                                                  |
| 297 |     82.332183 |    778.852436 | Dennis C. Murphy, after <https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png> |
| 298 |    681.953192 |    716.975095 | Heinrich Harder (vectorized by William Gearty)                                                                                                                                  |
| 299 |    391.753666 |    575.916994 | Noah Schlottman                                                                                                                                                                 |
| 300 |     97.314405 |    553.030098 | Scott Hartman                                                                                                                                                                   |
| 301 |    874.222245 |    714.743458 | Margot Michaud                                                                                                                                                                  |
| 302 |    844.754449 |     97.602308 | Agnello Picorelli                                                                                                                                                               |
| 303 |    857.725594 |     45.080626 | Joanna Wolfe                                                                                                                                                                    |
| 304 |    657.437376 |    247.950480 | Vanessa Guerra                                                                                                                                                                  |
| 305 |    175.151358 |    574.095764 | Gareth Monger                                                                                                                                                                   |
| 306 |     79.749035 |    259.478388 | Scott Hartman                                                                                                                                                                   |
| 307 |    214.794563 |    102.754005 | Jiekun He                                                                                                                                                                       |
| 308 |     60.490559 |     94.899697 | Felix Vaux                                                                                                                                                                      |
| 309 |    776.401085 |    181.742318 | Tyler Greenfield                                                                                                                                                                |
| 310 |    146.781072 |    412.673571 | Mali’o Kodis, photograph by Jim Vargo                                                                                                                                           |
| 311 |    343.342082 |     75.298613 | Carlos Cano-Barbacil                                                                                                                                                            |
| 312 |    810.980772 |    791.298868 | Anthony Caravaggi                                                                                                                                                               |
| 313 |    168.227411 |    353.279175 | Ferran Sayol                                                                                                                                                                    |
| 314 |    769.088891 |    725.288604 | Matt Crook                                                                                                                                                                      |
| 315 |    897.352146 |     14.438802 | T. Michael Keesey                                                                                                                                                               |
| 316 |    994.859299 |    290.238916 | Andy Wilson                                                                                                                                                                     |
| 317 |    498.966427 |    452.186344 | Ignacio Contreras                                                                                                                                                               |
| 318 |    312.738868 |    731.149017 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 319 |    670.408909 |    543.004737 | Julio Garza                                                                                                                                                                     |
| 320 |    326.646217 |    522.883613 | Jagged Fang Designs                                                                                                                                                             |
| 321 |    737.360273 |     25.344489 | Markus A. Grohme                                                                                                                                                                |
| 322 |    410.896860 |     19.419766 | Julie Blommaert based on photo by Sofdrakou                                                                                                                                     |
| 323 |    943.305150 |    271.759716 | Dinah Challen                                                                                                                                                                   |
| 324 |    832.413109 |    206.490968 | NA                                                                                                                                                                              |
| 325 |    941.811900 |     19.119126 | Zimices                                                                                                                                                                         |
| 326 |    410.538212 |     68.673301 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 327 |     36.046954 |    210.196573 | Matt Crook                                                                                                                                                                      |
| 328 |    174.489685 |    700.407961 | Margot Michaud                                                                                                                                                                  |
| 329 |    423.005050 |     54.518173 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 330 |    778.870611 |    345.796103 | Zimices                                                                                                                                                                         |
| 331 |    415.082690 |    129.599426 | Andy Wilson                                                                                                                                                                     |
| 332 |     19.803990 |    467.638425 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 333 |    262.112024 |    406.161113 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                                  |
| 334 |    368.794307 |    565.103044 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 335 |    455.218031 |    687.866703 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                                    |
| 336 |     82.214348 |     95.476602 | Joanna Wolfe                                                                                                                                                                    |
| 337 |    576.940875 |    503.243601 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                     |
| 338 |    313.887791 |    279.229154 | Harold N Eyster                                                                                                                                                                 |
| 339 |    587.918057 |    448.593785 | Jagged Fang Designs                                                                                                                                                             |
| 340 |    385.061899 |    277.436579 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 341 |    317.598028 |    138.247996 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 342 |    373.296132 |    307.683046 | Jagged Fang Designs                                                                                                                                                             |
| 343 |    523.881344 |    610.363356 | Jimmy Bernot                                                                                                                                                                    |
| 344 |    824.869206 |    750.656858 | Noah Schlottman, photo from Casey Dunn                                                                                                                                          |
| 345 |    735.148235 |    177.104568 | Gareth Monger                                                                                                                                                                   |
| 346 |    522.981293 |    532.266142 | Thibaut Brunet                                                                                                                                                                  |
| 347 |    396.953893 |    607.127073 | Dexter R. Mardis                                                                                                                                                                |
| 348 |    462.815313 |    727.799893 | Carlos Cano-Barbacil                                                                                                                                                            |
| 349 |    259.901082 |    776.368003 | Scott Hartman                                                                                                                                                                   |
| 350 |     80.348010 |    439.425303 | Ieuan Jones                                                                                                                                                                     |
| 351 |    688.152403 |    770.823427 | Ferran Sayol                                                                                                                                                                    |
| 352 |     67.763946 |    458.397125 | Zimices                                                                                                                                                                         |
| 353 |     14.371965 |     17.453388 | Felix Vaux                                                                                                                                                                      |
| 354 |    308.301748 |    143.168153 | NA                                                                                                                                                                              |
| 355 |    487.355498 |    777.883424 | Andrew A. Farke, modified from original by H. Milne Edwards                                                                                                                     |
| 356 |    711.795357 |    441.341637 | Jagged Fang Designs                                                                                                                                                             |
| 357 |    632.243749 |    339.440220 | Jaime Headden                                                                                                                                                                   |
| 358 |    547.138171 |     58.958070 | Danielle Alba                                                                                                                                                                   |
| 359 |    484.551937 |    378.510010 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                   |
| 360 |    805.647173 |    569.597446 | Steven Traver                                                                                                                                                                   |
| 361 |    113.442375 |    788.563656 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                                              |
| 362 |    796.421896 |    654.159233 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                                               |
| 363 |    710.896738 |    149.189274 | M Kolmann                                                                                                                                                                       |
| 364 |    691.973724 |    351.445875 | Gareth Monger                                                                                                                                                                   |
| 365 |    712.720161 |    265.142876 | Ignacio Contreras                                                                                                                                                               |
| 366 |    220.114882 |    350.205789 | Christine Axon                                                                                                                                                                  |
| 367 |    343.697387 |    315.012537 | Gareth Monger                                                                                                                                                                   |
| 368 |     14.621663 |     64.950692 | Ville Koistinen and T. Michael Keesey                                                                                                                                           |
| 369 |    503.784782 |    206.446574 | Maija Karala                                                                                                                                                                    |
| 370 |   1008.265601 |    454.322732 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                                   |
| 371 |    390.237871 |    659.597014 | Ingo Braasch                                                                                                                                                                    |
| 372 |    198.953562 |    355.763665 | Kailah Thorn & Mark Hutchinson                                                                                                                                                  |
| 373 |    327.049001 |    623.119150 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                                      |
| 374 |    295.561396 |    404.527003 | Scott Hartman                                                                                                                                                                   |
| 375 |    430.695581 |    409.442278 | Gareth Monger                                                                                                                                                                   |
| 376 |    255.133414 |    606.794221 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                  |
| 377 |    181.321124 |    740.922457 | Smokeybjb, vectorized by Zimices                                                                                                                                                |
| 378 |     69.509390 |     12.272779 | Scott Hartman                                                                                                                                                                   |
| 379 |     75.291653 |    501.196358 | Dmitry Bogdanov                                                                                                                                                                 |
| 380 |    809.277535 |    313.387543 | Harold N Eyster                                                                                                                                                                 |
| 381 |    150.135153 |    593.948304 | Shyamal                                                                                                                                                                         |
| 382 |    297.996958 |    586.504798 | Jagged Fang Designs                                                                                                                                                             |
| 383 |    251.275425 |    630.373203 | Matt Crook                                                                                                                                                                      |
| 384 |    867.849445 |    646.777406 | Gareth Monger                                                                                                                                                                   |
| 385 |    761.283122 |    441.275366 | Zimices                                                                                                                                                                         |
| 386 |    824.763554 |    131.285924 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                                        |
| 387 |    518.486423 |    481.321488 | Matt Crook                                                                                                                                                                      |
| 388 |    264.249597 |    415.185231 | Tasman Dixon                                                                                                                                                                    |
| 389 |    982.882801 |    139.205234 | Felix Vaux                                                                                                                                                                      |
| 390 |    571.940279 |    698.239678 | Maija Karala                                                                                                                                                                    |
| 391 |    729.529846 |    385.872259 | Chris huh                                                                                                                                                                       |
| 392 |    863.638824 |    462.828380 | S.Martini                                                                                                                                                                       |
| 393 |    625.759452 |    446.354302 | Steven Traver                                                                                                                                                                   |
| 394 |    223.637099 |    210.514913 | NA                                                                                                                                                                              |
| 395 |    214.963122 |    496.997602 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 396 |    976.302031 |    222.945852 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                             |
| 397 |    312.873134 |    260.972971 | Jaime Headden                                                                                                                                                                   |
| 398 |    136.084229 |    742.293962 | T. Michael Keesey                                                                                                                                                               |
| 399 |     18.728007 |    351.912686 | Margot Michaud                                                                                                                                                                  |
| 400 |    967.489944 |    332.525479 | Jagged Fang Designs                                                                                                                                                             |
| 401 |    810.240549 |     17.629991 | Margot Michaud                                                                                                                                                                  |
| 402 |    902.576853 |    468.098467 | Steven Blackwood                                                                                                                                                                |
| 403 |    345.890158 |    673.191577 | Matt Crook                                                                                                                                                                      |
| 404 |   1017.655329 |    487.108594 | Agnello Picorelli                                                                                                                                                               |
| 405 |    788.190386 |    125.253261 | Ferran Sayol                                                                                                                                                                    |
| 406 |    568.830951 |    748.274036 | Margot Michaud                                                                                                                                                                  |
| 407 |    313.222068 |    573.893493 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                                              |
| 408 |     40.154300 |    735.567660 | NA                                                                                                                                                                              |
| 409 |    207.223946 |    309.488825 | Markus A. Grohme                                                                                                                                                                |
| 410 |    877.784591 |    234.921368 | Pete Buchholz                                                                                                                                                                   |
| 411 |    590.717967 |     89.875750 | NA                                                                                                                                                                              |
| 412 |    208.014656 |     41.199126 | Margot Michaud                                                                                                                                                                  |
| 413 |    440.858721 |    782.129297 | Steven Traver                                                                                                                                                                   |
| 414 |    199.933020 |      5.876618 | Jagged Fang Designs                                                                                                                                                             |
| 415 |    674.955232 |    263.960905 | Markus A. Grohme                                                                                                                                                                |
| 416 |    275.238002 |    442.498570 | Scott Hartman                                                                                                                                                                   |
| 417 |    709.477855 |    515.939161 | Chris huh                                                                                                                                                                       |
| 418 |    752.827475 |    426.643779 | Neil Kelley                                                                                                                                                                     |
| 419 |    800.110522 |    491.861244 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 420 |    279.467876 |    372.494421 | Andy Wilson                                                                                                                                                                     |
| 421 |    969.948962 |    551.958207 | Zimices                                                                                                                                                                         |
| 422 |    908.124652 |    732.858247 | Steven Traver                                                                                                                                                                   |
| 423 |    406.747092 |    464.494376 | Scott Hartman                                                                                                                                                                   |
| 424 |    601.062017 |    283.771624 | Steven Traver                                                                                                                                                                   |
| 425 |    822.911440 |    588.987080 | Margot Michaud                                                                                                                                                                  |
| 426 |    642.426928 |    418.543681 | Melissa Broussard                                                                                                                                                               |
| 427 |    291.938061 |    786.446327 | Sarah Werning                                                                                                                                                                   |
| 428 |    385.144789 |    653.744377 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                                         |
| 429 |    442.981417 |    545.151574 | Scott Hartman                                                                                                                                                                   |
| 430 |    723.832792 |    334.764251 | Jagged Fang Designs                                                                                                                                                             |
| 431 |    217.901354 |    517.421222 | Matt Crook                                                                                                                                                                      |
| 432 |    435.982796 |    280.531219 | Michael Scroggie                                                                                                                                                                |
| 433 |    717.738846 |     12.046176 | Zimices                                                                                                                                                                         |
| 434 |    329.305392 |    595.824850 | H. Filhol (vectorized by T. Michael Keesey)                                                                                                                                     |
| 435 |    472.843285 |    517.162233 | Matt Crook                                                                                                                                                                      |
| 436 |    231.755356 |    783.809744 | Michelle Site                                                                                                                                                                   |
| 437 |    888.809394 |    788.947385 | Steven Haddock • Jellywatch.org                                                                                                                                                 |
| 438 |    379.390838 |     77.064027 | Steven Coombs                                                                                                                                                                   |
| 439 |    379.991269 |    485.938994 | Taenadoman                                                                                                                                                                      |
| 440 |    976.165038 |    638.803825 | Sarah Werning                                                                                                                                                                   |
| 441 |    312.079474 |      6.402014 | Zimices                                                                                                                                                                         |
| 442 |     57.422732 |    598.708720 | Scott Hartman                                                                                                                                                                   |
| 443 |    999.432805 |     69.667244 | david maas / dave hone                                                                                                                                                          |
| 444 |    900.499144 |     22.052406 | Ignacio Contreras                                                                                                                                                               |
| 445 |    661.357450 |    581.239973 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 446 |    192.897559 |    191.798946 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 447 |    736.202774 |    593.594357 | Margot Michaud                                                                                                                                                                  |
| 448 |    997.866775 |    727.927954 | Matt Crook                                                                                                                                                                      |
| 449 |    558.221807 |    793.630639 | Yan Wong                                                                                                                                                                        |
| 450 |    896.268112 |    344.273363 | NA                                                                                                                                                                              |
| 451 |    223.431543 |    574.952947 | Matt Crook                                                                                                                                                                      |
| 452 |    715.494514 |    695.125452 | Gareth Monger                                                                                                                                                                   |
| 453 |    878.421861 |    552.766824 | Maija Karala                                                                                                                                                                    |
| 454 |    348.174662 |    582.921276 | Lukas Panzarin (vectorized by T. Michael Keesey)                                                                                                                                |
| 455 |    951.911459 |    776.189598 | Jaime Headden                                                                                                                                                                   |
| 456 |    772.389995 |    569.040941 | Scott Hartman                                                                                                                                                                   |
| 457 |    559.041619 |    395.112338 | Zimices                                                                                                                                                                         |
| 458 |    918.253301 |    330.743547 | Gareth Monger                                                                                                                                                                   |
| 459 |    181.988035 |    302.265063 | Lukasiniho                                                                                                                                                                      |
| 460 |    303.485375 |    679.198131 | Zimices                                                                                                                                                                         |
| 461 |    178.889048 |    426.763026 | V. Deepak                                                                                                                                                                       |
| 462 |    110.158046 |    580.323764 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 463 |    693.999649 |    568.202876 | Erika Schumacher                                                                                                                                                                |
| 464 |    911.054668 |    232.300602 | T. Michael Keesey                                                                                                                                                               |
| 465 |    872.359595 |     16.720064 | Audrey Ely                                                                                                                                                                      |
| 466 |    358.294229 |      5.375497 | Thibaut Brunet                                                                                                                                                                  |
| 467 |    877.989864 |    671.485702 | Myriam\_Ramirez                                                                                                                                                                 |
| 468 |    275.573540 |    102.712574 | Michelle Site                                                                                                                                                                   |
| 469 |    352.545373 |    158.669754 | Jagged Fang Designs                                                                                                                                                             |
| 470 |    256.936646 |    209.882139 | Birgit Lang                                                                                                                                                                     |
| 471 |    498.561547 |     14.369195 | Milton Tan                                                                                                                                                                      |
| 472 |   1007.161148 |    467.877597 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 473 |    507.526017 |    562.050760 | FunkMonk                                                                                                                                                                        |
| 474 |     42.145296 |    796.079495 | Jaime Headden                                                                                                                                                                   |
| 475 |    829.285310 |    628.834041 | Gareth Monger                                                                                                                                                                   |
| 476 |    952.919590 |    149.573382 | Tasman Dixon                                                                                                                                                                    |
| 477 |    244.008423 |    446.136555 | Tyler Greenfield                                                                                                                                                                |
| 478 |     17.723600 |    739.406723 | Gareth Monger                                                                                                                                                                   |
| 479 |    935.908387 |    189.677842 | Filip em                                                                                                                                                                        |
| 480 |    793.087213 |    190.825101 | Zimices                                                                                                                                                                         |
| 481 |    956.663642 |    300.717755 | Ferran Sayol                                                                                                                                                                    |
| 482 |    323.614963 |    370.665769 | Matt Crook                                                                                                                                                                      |
| 483 |    566.995432 |    106.975072 | Chris huh                                                                                                                                                                       |
| 484 |    122.027311 |    685.401939 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 485 |    631.012317 |    498.999866 | Jake Warner                                                                                                                                                                     |
| 486 |    114.771320 |    732.071666 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 487 |    255.034859 |     15.875062 | Pete Buchholz                                                                                                                                                                   |
| 488 |    745.209737 |    646.938493 | Zimices                                                                                                                                                                         |
| 489 |    124.557256 |    520.648296 | Steven Haddock • Jellywatch.org                                                                                                                                                 |
| 490 |    422.146332 |    689.953656 | Tasman Dixon                                                                                                                                                                    |
| 491 |    170.672989 |    276.207916 | NA                                                                                                                                                                              |
| 492 |     90.355656 |    722.883444 | Julia B McHugh                                                                                                                                                                  |
| 493 |    393.348300 |    722.202341 | Zimices                                                                                                                                                                         |
| 494 |    195.798175 |    383.246381 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                                     |
| 495 |    923.869215 |    291.859720 | Alexandre Vong                                                                                                                                                                  |
| 496 |    580.460467 |    299.685319 | Scott Hartman                                                                                                                                                                   |
| 497 |    501.372265 |    728.830602 | Armin Reindl                                                                                                                                                                    |
| 498 |    574.225812 |     72.859471 | Scott Hartman                                                                                                                                                                   |
| 499 |    665.061733 |    566.350753 | Scott Hartman                                                                                                                                                                   |
| 500 |    843.956551 |     11.714721 | Sarah Werning                                                                                                                                                                   |
| 501 |    796.950384 |    419.261367 | Kanchi Nanjo                                                                                                                                                                    |
| 502 |   1004.648526 |     82.913404 | Dean Schnabel                                                                                                                                                                   |
| 503 |    681.305175 |    683.227572 | Margot Michaud                                                                                                                                                                  |
| 504 |    106.402663 |    540.306792 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                   |
| 505 |    827.090984 |     85.883817 | Jagged Fang Designs                                                                                                                                                             |
| 506 |    103.649125 |    677.605436 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 507 |     11.733401 |    422.954514 | FJDegrange                                                                                                                                                                      |
| 508 |    764.084162 |    703.939979 | Jagged Fang Designs                                                                                                                                                             |
| 509 |     13.079984 |    704.984127 | Meliponicultor Itaymbere                                                                                                                                                        |
| 510 |   1017.089484 |    657.931760 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                            |
| 511 |    700.000919 |    164.430128 | Mathieu Basille                                                                                                                                                                 |
| 512 |    555.764104 |    603.295720 | Gareth Monger                                                                                                                                                                   |
| 513 |    163.145036 |    490.486134 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 514 |    933.133583 |    109.227464 | Yan Wong                                                                                                                                                                        |
| 515 |    906.593132 |    149.661446 | Shyamal                                                                                                                                                                         |
| 516 |    394.866860 |    292.826644 | Joanna Wolfe                                                                                                                                                                    |
| 517 |    750.636162 |    295.140076 | Christine Axon                                                                                                                                                                  |
| 518 |      5.792882 |    654.326925 | T. Michael Keesey                                                                                                                                                               |
| 519 |    493.215231 |     33.114337 | L. Shyamal                                                                                                                                                                      |
| 520 |    224.183671 |    643.492900 | Ricardo Araújo                                                                                                                                                                  |
| 521 |    268.644705 |    525.068272 | Zimices                                                                                                                                                                         |
| 522 |    297.017106 |    182.470771 | Scott Hartman                                                                                                                                                                   |
| 523 |    898.580191 |    756.323835 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                                  |
| 524 |    567.817546 |    740.428531 | Armin Reindl                                                                                                                                                                    |
| 525 |    959.243219 |    407.914254 | Xavier Giroux-Bougard                                                                                                                                                           |
| 526 |    651.026438 |    397.741350 | Jagged Fang Designs                                                                                                                                                             |
| 527 |    461.189502 |    613.250374 | Scott Hartman                                                                                                                                                                   |
| 528 |     29.643179 |    270.245057 | Jagged Fang Designs                                                                                                                                                             |
| 529 |      4.362157 |    390.733062 | Gareth Monger                                                                                                                                                                   |
| 530 |    586.845865 |    474.401269 | S.Martini                                                                                                                                                                       |
| 531 |     18.202881 |    512.288537 | Chris huh                                                                                                                                                                       |
| 532 |    104.615845 |    520.664793 | Walter Vladimir                                                                                                                                                                 |
| 533 |    355.079946 |    654.585762 | Mette Aumala                                                                                                                                                                    |
| 534 |    590.748798 |    737.642010 | Gareth Monger                                                                                                                                                                   |
| 535 |    143.708685 |    279.179122 | Erika Schumacher                                                                                                                                                                |
| 536 |    441.587911 |     77.418028 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                                       |
| 537 |    804.781553 |    440.755703 | T. Michael Keesey                                                                                                                                                               |
| 538 |     25.692859 |    261.268338 | Bruno Maggia                                                                                                                                                                    |
| 539 |    761.033391 |    750.878710 | Javiera Constanzo                                                                                                                                                               |
| 540 |    587.824590 |    655.669371 | Jagged Fang Designs                                                                                                                                                             |
| 541 |    461.648263 |    177.621659 | Xavier Giroux-Bougard                                                                                                                                                           |
| 542 |    180.452707 |    762.334572 | Yan Wong                                                                                                                                                                        |
| 543 |    140.797470 |    373.135995 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 544 |    805.577122 |    201.731036 | Robert Gay                                                                                                                                                                      |
| 545 |    496.563150 |    713.051694 | Matt Martyniuk                                                                                                                                                                  |
| 546 |    212.626227 |     81.146899 | Chris huh                                                                                                                                                                       |
| 547 |    498.107395 |    192.219249 | Chris huh                                                                                                                                                                       |

    #> Your tweet has been posted!
