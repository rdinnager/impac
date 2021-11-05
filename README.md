
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

Emily Willoughby, Zimices, Mathieu Basille, Tauana J. Cunha, Xavier
Giroux-Bougard, Matt Crook, Apokryltaros (vectorized by T. Michael
Keesey), T. Michael Keesey, Jaime Headden, modified by T. Michael
Keesey, Mathilde Cordellier, Tom Tarrant (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Birgit Lang, Joanna Wolfe,
Beth Reinke, Keith Murdock (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Darren Naish (vectorize by T. Michael
Keesey), Tess Linden, Smith609 and T. Michael Keesey, Ferran Sayol,
Anthony Caravaggi, Noah Schlottman, photo from Casey Dunn, Alex
Slavenko, Gabriela Palomo-Munoz, Robert Gay, modifed from Olegivvit,
Lauren Anderson, Margot Michaud, T. Michael Keesey (from a photo by
Maximilian Paradiz), Matthew E. Clapham, C. Camilo Julián-Caballero,
Nobu Tamura (vectorized by T. Michael Keesey), Lukas Panzarin, Tasman
Dixon, Nobu Tamura, Jose Carlos Arenas-Monroy, Steven Traver, Roberto
Díaz Sibaja, Kamil S. Jaron, Christine Axon, Rachel Shoop, Chris huh,
Caleb M. Brown, Walter Vladimir, Jake Warner, Aviceda (photo) & T.
Michael Keesey, Sergio A. Muñoz-Gómez, Michael B. H. (vectorized by T.
Michael Keesey), Jaime Headden (vectorized by T. Michael Keesey), Scott
Hartman, Iain Reid, NASA, Jagged Fang Designs, Stanton F. Fink
(vectorized by T. Michael Keesey), Gareth Monger, Becky Barnes,
Terpsichores, Birgit Lang, based on a photo by D. Sikes, Dean Schnabel,
Ghedoghedo, vectorized by Zimices, Smokeybjb, Sarah Werning, Nobu
Tamura, vectorized by Zimices, Alexandre Vong, Dmitry Bogdanov
(vectorized by T. Michael Keesey), Shyamal, Melissa Broussard, Espen
Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell),
Tracy A. Heath, Mo Hassan, Javier Luque, Frank Förster (based on a
picture by Hans Hillewaert), Cyril Matthey-Doret, adapted from Bernard
Chaubet, Ian Burt (original) and T. Michael Keesey (vectorization), Rene
Martin, Matthias Buschmann (vectorized by T. Michael Keesey), Yan Wong,
ArtFavor & annaleeblysse, Benjamint444, B. Duygu Özpolat, Jon Hill
(Photo by DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), Jon M
Laurent, Philippe Janvier (vectorized by T. Michael Keesey), Alexander
Schmidt-Lebuhn, CNZdenek, Caio Bernardes, vectorized by Zimices, Bill
Bouton (source photo) & T. Michael Keesey (vectorization), (after
Spotila 2004), Julio Garza, Joseph J. W. Sertich, Mark A. Loewen, Jan A.
Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized
by T. Michael Keesey), Jimmy Bernot, Sherman F. Denton via rawpixel.com
(illustration) and Timothy J. Bartley (silhouette), Ellen Edmonson and
Hugh Chrisp (vectorized by T. Michael Keesey), Steven Coombs, Matt
Martyniuk, Saguaro Pictures (source photo) and T. Michael Keesey,
Haplochromis (vectorized by T. Michael Keesey), Michael Scroggie, Renata
F. Martins, Bruno C. Vellutini, Christoph Schomburg, NOAA Great Lakes
Environmental Research Laboratory (illustration) and Timothy J. Bartley
(silhouette), FunkMonk, Brad McFeeters (vectorized by T. Michael
Keesey), Amanda Katzer, Robert Gay, Chase Brownstein, Myriam\_Ramirez,
Steven Coombs (vectorized by T. Michael Keesey), M Kolmann, Noah
Schlottman, photo by Antonio Guillén, Jaime Headden, Emil Schmidt
(vectorized by Maxime Dahirel), Catherine Yasuda, Mike Hanson, Stacy
Spensley (Modified), Matt Martyniuk (vectorized by T. Michael Keesey),
Lisa Byrne, Chris Jennings (vectorized by A. Verrière), Mykle Hoban,
Bennet McComish, photo by Avenue, DW Bapst (modified from Bulman, 1970),
T. Michael Keesey (from a mount by Allis Markham), Ghedo (vectorized by
T. Michael Keesey), Josefine Bohr Brask, C. Abraczinskas, L. Shyamal,
Natasha Vitek, Francesco Veronesi (vectorized by T. Michael Keesey),
Daniel Stadtmauer, Kelly, Michelle Site, Emily Jane McTavish, from
Haeckel, E. H. P. A. (1904).Kunstformen der Natur. Bibliographisches,
Mali’o Kodis, photograph by John Slapcinsky, Felix Vaux, James R.
Spotila and Ray Chatterji, Carlos Cano-Barbacil, Noah Schlottman, Mark
Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Joe Schneid (vectorized by T. Michael Keesey), Maija
Karala, Scarlet23 (vectorized by T. Michael Keesey), Kailah Thorn & Ben
King, Harold N Eyster, Ghedoghedo (vectorized by T. Michael Keesey),
Matt Wilkins, Steven Haddock • Jellywatch.org, Rebecca Groom, Kai R.
Caspar, Crystal Maier, Mali’o Kodis, image from Brockhaus and Efron
Encyclopedic Dictionary, Lip Kee Yap (vectorized by T. Michael Keesey),
Andrés Sánchez, Jonathan Wells, Dave Souza (vectorized by T. Michael
Keesey), Lafage, Henry Lydecker, Sharon Wegner-Larsen, Juan Carlos Jerí,
Tomas Willems (vectorized by T. Michael Keesey), Michele Tobias, Y. de
Hoev. (vectorized by T. Michael Keesey), Siobhon Egan, Aviceda
(vectorized by T. Michael Keesey), Katie S. Collins, Kailah Thorn & Mark
Hutchinson, Konsta Happonen, from a CC-BY-NC image by pelhonen on
iNaturalist, Emma Kissling, Cristian Osorio & Paula Carrera, Proyecto
Carnivoros Australes (www.carnivorosaustrales.org), Zachary Quigley,
Matt Dempsey, Lukasiniho, David Orr, Noah Schlottman, photo by Martin V.
Sørensen, T. Michael Keesey (photo by Sean Mack), Cesar Julian, Dianne
Bray / Museum Victoria (vectorized by T. Michael Keesey), Milton Tan,
Mattia Menchetti, Martin Kevil, Jack Mayer Wood, FJDegrange, Jay
Matternes (vectorized by T. Michael Keesey), AnAgnosticGod (vectorized
by T. Michael Keesey), Collin Gross, Wayne Decatur, Tambja (vectorized
by T. Michael Keesey), Nina Skinner, Ludwik Gasiorowski, Andrew A.
Farke, Stuart Humphries, Pearson Scott Foresman (vectorized by T.
Michael Keesey), Yan Wong from drawing by T. F. Zimmermann, Karla
Martinez, S.Martini, Pranav Iyer (grey ideas), T. Michael Keesey (after
A. Y. Ivantsov)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                         |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    219.061135 |    377.813972 | Emily Willoughby                                                                                                                                               |
|   2 |    458.030048 |    315.098394 | Zimices                                                                                                                                                        |
|   3 |    748.515815 |    262.365912 | Mathieu Basille                                                                                                                                                |
|   4 |    146.734905 |     62.757332 | Zimices                                                                                                                                                        |
|   5 |    203.928450 |    533.061927 | Zimices                                                                                                                                                        |
|   6 |    368.970255 |    736.699549 | Tauana J. Cunha                                                                                                                                                |
|   7 |    922.505365 |    119.506311 | Xavier Giroux-Bougard                                                                                                                                          |
|   8 |    709.551034 |    382.592040 | NA                                                                                                                                                             |
|   9 |    952.415653 |    424.380928 | Matt Crook                                                                                                                                                     |
|  10 |    898.161968 |    322.018328 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                 |
|  11 |    193.713775 |    735.353246 | T. Michael Keesey                                                                                                                                              |
|  12 |    808.643748 |    438.514070 | Zimices                                                                                                                                                        |
|  13 |    124.370872 |    242.622945 | Jaime Headden, modified by T. Michael Keesey                                                                                                                   |
|  14 |    614.770077 |     68.631931 | Mathilde Cordellier                                                                                                                                            |
|  15 |    298.826765 |    637.508052 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
|  16 |    611.549690 |    475.377227 | Birgit Lang                                                                                                                                                    |
|  17 |    625.469332 |    572.843444 | Joanna Wolfe                                                                                                                                                   |
|  18 |    141.017604 |    616.994499 | Beth Reinke                                                                                                                                                    |
|  19 |    970.897173 |    627.307240 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey  |
|  20 |    725.586852 |    737.705927 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                  |
|  21 |    870.002660 |    659.715114 | Tess Linden                                                                                                                                                    |
|  22 |    444.479830 |    690.914125 | NA                                                                                                                                                             |
|  23 |    789.322442 |    555.853446 | Smith609 and T. Michael Keesey                                                                                                                                 |
|  24 |     60.553127 |    340.059272 | Ferran Sayol                                                                                                                                                   |
|  25 |    375.948622 |    495.413337 | Anthony Caravaggi                                                                                                                                              |
|  26 |    389.295810 |    142.403458 | Noah Schlottman, photo from Casey Dunn                                                                                                                         |
|  27 |    411.432380 |     46.149025 | Alex Slavenko                                                                                                                                                  |
|  28 |    528.182595 |    390.224572 | Gabriela Palomo-Munoz                                                                                                                                          |
|  29 |    565.574021 |    221.748397 | Robert Gay, modifed from Olegivvit                                                                                                                             |
|  30 |     86.155200 |    159.297814 | Lauren Anderson                                                                                                                                                |
|  31 |    431.942165 |    598.429056 | Margot Michaud                                                                                                                                                 |
|  32 |    817.969811 |     86.658038 | Matt Crook                                                                                                                                                     |
|  33 |    632.384355 |    281.063174 | Beth Reinke                                                                                                                                                    |
|  34 |     73.945675 |    716.847917 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                         |
|  35 |    174.460433 |    161.483824 | NA                                                                                                                                                             |
|  36 |    884.749093 |    522.192865 | Gabriela Palomo-Munoz                                                                                                                                          |
|  37 |     78.284988 |    447.221569 | Matthew E. Clapham                                                                                                                                             |
|  38 |    441.276895 |    444.028509 | C. Camilo Julián-Caballero                                                                                                                                     |
|  39 |    700.447280 |    181.816741 | NA                                                                                                                                                             |
|  40 |    335.157559 |    391.735005 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
|  41 |    684.179029 |    653.470530 | Lukas Panzarin                                                                                                                                                 |
|  42 |    289.424891 |     19.131301 | Tasman Dixon                                                                                                                                                   |
|  43 |    956.494462 |    715.453987 | Nobu Tamura                                                                                                                                                    |
|  44 |    681.202778 |    449.233994 | Jose Carlos Arenas-Monroy                                                                                                                                      |
|  45 |    678.868223 |    327.246860 | Steven Traver                                                                                                                                                  |
|  46 |    583.429200 |    686.926077 | Roberto Díaz Sibaja                                                                                                                                            |
|  47 |    611.091989 |    740.955943 | Margot Michaud                                                                                                                                                 |
|  48 |    252.854027 |    474.487924 | Kamil S. Jaron                                                                                                                                                 |
|  49 |    223.607342 |    272.492029 | Margot Michaud                                                                                                                                                 |
|  50 |    204.208318 |    612.162693 | Christine Axon                                                                                                                                                 |
|  51 |    313.367663 |    274.873233 | Rachel Shoop                                                                                                                                                   |
|  52 |    801.529738 |    151.560467 | C. Camilo Julián-Caballero                                                                                                                                     |
|  53 |    741.094058 |     43.277575 | Birgit Lang                                                                                                                                                    |
|  54 |    878.049496 |    771.088663 | Chris huh                                                                                                                                                      |
|  55 |    509.982667 |    605.594175 | Ferran Sayol                                                                                                                                                   |
|  56 |    289.243490 |     58.978556 | Caleb M. Brown                                                                                                                                                 |
|  57 |    753.114262 |    625.355447 | Walter Vladimir                                                                                                                                                |
|  58 |    500.820141 |    512.950693 | Jake Warner                                                                                                                                                    |
|  59 |    251.966493 |    214.659496 | Margot Michaud                                                                                                                                                 |
|  60 |    997.210028 |    188.349046 | Aviceda (photo) & T. Michael Keesey                                                                                                                            |
|  61 |    633.735646 |     26.679854 | Alex Slavenko                                                                                                                                                  |
|  62 |    844.515291 |    731.527785 | NA                                                                                                                                                             |
|  63 |    549.626132 |     95.071192 | Sergio A. Muñoz-Gómez                                                                                                                                          |
|  64 |    264.707452 |    332.609958 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                |
|  65 |    760.894557 |    670.251283 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                |
|  66 |    938.289661 |     22.520468 | Scott Hartman                                                                                                                                                  |
|  67 |    279.280591 |    147.425546 | Iain Reid                                                                                                                                                      |
|  68 |    783.713995 |    334.825384 | NASA                                                                                                                                                           |
|  69 |    504.877580 |    767.946257 | Scott Hartman                                                                                                                                                  |
|  70 |    516.086785 |    238.171304 | Steven Traver                                                                                                                                                  |
|  71 |    715.083934 |    570.643157 | Chris huh                                                                                                                                                      |
|  72 |    132.262538 |    387.824202 | Zimices                                                                                                                                                        |
|  73 |    752.193281 |    394.987136 | Jagged Fang Designs                                                                                                                                            |
|  74 |    763.157118 |    205.291089 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                              |
|  75 |    454.457762 |    109.912483 | Gareth Monger                                                                                                                                                  |
|  76 |    516.705816 |     32.624767 | Matt Crook                                                                                                                                                     |
|  77 |    824.696079 |    572.294017 | Sergio A. Muñoz-Gómez                                                                                                                                          |
|  78 |    972.805108 |    266.577858 | Margot Michaud                                                                                                                                                 |
|  79 |     24.267726 |    138.136141 | Matt Crook                                                                                                                                                     |
|  80 |    690.207339 |     85.643411 | Zimices                                                                                                                                                        |
|  81 |    606.320554 |    383.763477 | Becky Barnes                                                                                                                                                   |
|  82 |    419.174944 |    218.485945 | T. Michael Keesey                                                                                                                                              |
|  83 |    155.444432 |    288.341930 | Terpsichores                                                                                                                                                   |
|  84 |    950.089967 |    230.203780 | Margot Michaud                                                                                                                                                 |
|  85 |    615.326322 |    654.416047 | Birgit Lang, based on a photo by D. Sikes                                                                                                                      |
|  86 |    939.089778 |    502.134911 | Zimices                                                                                                                                                        |
|  87 |    262.451186 |    526.396755 | Margot Michaud                                                                                                                                                 |
|  88 |    770.008543 |    498.741833 | Dean Schnabel                                                                                                                                                  |
|  89 |    892.816881 |    392.363928 | Scott Hartman                                                                                                                                                  |
|  90 |    226.319753 |    784.676563 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
|  91 |    359.090345 |     74.140529 | Ghedoghedo, vectorized by Zimices                                                                                                                              |
|  92 |     30.982053 |    521.783536 | T. Michael Keesey                                                                                                                                              |
|  93 |    993.052494 |    526.243771 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
|  94 |    955.205188 |    697.176639 | Smokeybjb                                                                                                                                                      |
|  95 |    899.188196 |    237.354948 | Sarah Werning                                                                                                                                                  |
|  96 |    796.058461 |    634.437165 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
|  97 |    238.596008 |    633.932342 | Smokeybjb                                                                                                                                                      |
|  98 |     53.056696 |    632.494533 | Alexandre Vong                                                                                                                                                 |
|  99 |    526.761484 |    741.310829 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 100 |    181.122291 |    326.499765 | Zimices                                                                                                                                                        |
| 101 |    812.034417 |    400.204255 | Jagged Fang Designs                                                                                                                                            |
| 102 |    724.173951 |    540.774846 | Lukas Panzarin                                                                                                                                                 |
| 103 |    822.470616 |    206.302512 | Kamil S. Jaron                                                                                                                                                 |
| 104 |    916.467522 |    589.328167 | Shyamal                                                                                                                                                        |
| 105 |    610.034008 |    183.833045 | Melissa Broussard                                                                                                                                              |
| 106 |     41.517682 |    175.118739 | Ferran Sayol                                                                                                                                                   |
| 107 |    522.090915 |    415.227979 | Gareth Monger                                                                                                                                                  |
| 108 |    320.436969 |    451.733333 | Espen Horn (model; vectorized by T. Michael Keesey from a photo by H. Zell)                                                                                    |
| 109 |    584.733017 |    132.597416 | Gareth Monger                                                                                                                                                  |
| 110 |    572.851381 |    783.710289 | Scott Hartman                                                                                                                                                  |
| 111 |    456.111686 |     23.868256 | T. Michael Keesey                                                                                                                                              |
| 112 |    696.595930 |    770.731812 | Tasman Dixon                                                                                                                                                   |
| 113 |    492.180398 |    234.263645 | Tracy A. Heath                                                                                                                                                 |
| 114 |    535.174831 |    641.850704 | Steven Traver                                                                                                                                                  |
| 115 |    496.858511 |    209.204663 | Mo Hassan                                                                                                                                                      |
| 116 |    301.782509 |    583.591137 | Zimices                                                                                                                                                        |
| 117 |    527.710827 |     61.795063 | Zimices                                                                                                                                                        |
| 118 |    807.301007 |    662.347290 | Javier Luque                                                                                                                                                   |
| 119 |    366.378840 |    576.765136 | Frank Förster (based on a picture by Hans Hillewaert)                                                                                                          |
| 120 |    332.352390 |    354.659907 | Cyril Matthey-Doret, adapted from Bernard Chaubet                                                                                                              |
| 121 |    563.616712 |    344.016344 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                      |
| 122 |    123.934995 |    197.460061 | Scott Hartman                                                                                                                                                  |
| 123 |    704.064141 |     63.010151 | Ferran Sayol                                                                                                                                                   |
| 124 |    845.941814 |    621.165446 | T. Michael Keesey                                                                                                                                              |
| 125 |    229.178962 |    230.997925 | Rene Martin                                                                                                                                                    |
| 126 |    570.560491 |    606.967824 | Margot Michaud                                                                                                                                                 |
| 127 |    748.171235 |    254.004230 | NA                                                                                                                                                             |
| 128 |    976.822813 |    764.001831 | Roberto Díaz Sibaja                                                                                                                                            |
| 129 |     15.160519 |    548.450492 | Matthias Buschmann (vectorized by T. Michael Keesey)                                                                                                           |
| 130 |    129.325056 |    779.166044 | Gareth Monger                                                                                                                                                  |
| 131 |    697.168728 |     26.147666 | Jagged Fang Designs                                                                                                                                            |
| 132 |    522.753778 |      6.082152 | Tasman Dixon                                                                                                                                                   |
| 133 |    883.206148 |    411.094408 | Yan Wong                                                                                                                                                       |
| 134 |    738.966829 |    483.011513 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 135 |    298.400789 |    155.885148 | ArtFavor & annaleeblysse                                                                                                                                       |
| 136 |    443.347941 |    760.863421 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 137 |     76.173364 |    787.484038 | Melissa Broussard                                                                                                                                              |
| 138 |     19.678149 |    705.958427 | Benjamint444                                                                                                                                                   |
| 139 |    342.357151 |    169.570605 | B. Duygu Özpolat                                                                                                                                               |
| 140 |    802.738145 |    176.157639 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                 |
| 141 |    498.373842 |    434.975094 | Javier Luque                                                                                                                                                   |
| 142 |    432.162879 |    522.471529 | Kamil S. Jaron                                                                                                                                                 |
| 143 |   1005.035210 |     11.339923 | Melissa Broussard                                                                                                                                              |
| 144 |    202.295068 |     95.832581 | Jon M Laurent                                                                                                                                                  |
| 145 |    311.637253 |    514.438052 | Zimices                                                                                                                                                        |
| 146 |     39.840076 |    292.466681 | Ferran Sayol                                                                                                                                                   |
| 147 |    480.376976 |    473.519520 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                             |
| 148 |    225.286518 |     61.391259 | Matt Crook                                                                                                                                                     |
| 149 |    888.313686 |     64.011834 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 150 |    601.335501 |    651.004193 | Steven Traver                                                                                                                                                  |
| 151 |    635.645083 |    157.295887 | Matt Crook                                                                                                                                                     |
| 152 |   1011.546831 |    726.764631 | NA                                                                                                                                                             |
| 153 |    501.739083 |    562.914302 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 154 |    589.306110 |    355.062973 | T. Michael Keesey                                                                                                                                              |
| 155 |    719.428603 |    302.455746 | Matt Crook                                                                                                                                                     |
| 156 |     52.466802 |     16.689073 | Chris huh                                                                                                                                                      |
| 157 |    472.640863 |    198.351035 | CNZdenek                                                                                                                                                       |
| 158 |    622.658662 |    356.860748 | Matt Crook                                                                                                                                                     |
| 159 |     16.525363 |    205.446838 | Emily Willoughby                                                                                                                                               |
| 160 |    491.966937 |    541.455384 | NA                                                                                                                                                             |
| 161 |    832.298666 |     15.242330 | Matt Crook                                                                                                                                                     |
| 162 |    511.088217 |     93.676625 | C. Camilo Julián-Caballero                                                                                                                                     |
| 163 |    831.125108 |    122.933585 | Caio Bernardes, vectorized by Zimices                                                                                                                          |
| 164 |    306.651094 |    726.911205 | T. Michael Keesey                                                                                                                                              |
| 165 |    168.630486 |    413.512914 | Bill Bouton (source photo) & T. Michael Keesey (vectorization)                                                                                                 |
| 166 |    635.274874 |    206.819761 | Matt Crook                                                                                                                                                     |
| 167 |    424.856639 |    352.689395 | Margot Michaud                                                                                                                                                 |
| 168 |    370.972985 |     52.283249 | (after Spotila 2004)                                                                                                                                           |
| 169 |    253.220336 |    184.685056 | Gareth Monger                                                                                                                                                  |
| 170 |    317.090270 |    534.708826 | Matt Crook                                                                                                                                                     |
| 171 |    830.083251 |    698.197376 | Zimices                                                                                                                                                        |
| 172 |    271.114790 |    602.507536 | Ferran Sayol                                                                                                                                                   |
| 173 |    945.332613 |    627.384259 | Gareth Monger                                                                                                                                                  |
| 174 |    819.982666 |    267.243367 | C. Camilo Julián-Caballero                                                                                                                                     |
| 175 |    297.250310 |    757.594089 | Julio Garza                                                                                                                                                    |
| 176 |    739.339168 |     86.034902 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 177 |    481.981950 |    650.197416 | Steven Traver                                                                                                                                                  |
| 178 |    406.812410 |    403.464037 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                           |
| 179 |    577.482712 |    520.357596 | Steven Traver                                                                                                                                                  |
| 180 |     22.363873 |     83.625171 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                            |
| 181 |    997.996497 |    566.859701 | Jimmy Bernot                                                                                                                                                   |
| 182 |    690.193704 |      9.788985 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                          |
| 183 |    815.583948 |     34.919158 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                               |
| 184 |    727.183152 |    499.414987 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                |
| 185 |    441.040451 |     69.387662 | Margot Michaud                                                                                                                                                 |
| 186 |    449.505764 |    657.773546 | Steven Coombs                                                                                                                                                  |
| 187 |    249.346103 |    573.635048 | Christine Axon                                                                                                                                                 |
| 188 |    319.122453 |    690.048514 | Matt Martyniuk                                                                                                                                                 |
| 189 |     78.734776 |    513.169374 | Tauana J. Cunha                                                                                                                                                |
| 190 |    652.946734 |    402.003772 | Ferran Sayol                                                                                                                                                   |
| 191 |     80.889674 |    751.373883 | T. Michael Keesey                                                                                                                                              |
| 192 |    985.530297 |    483.992700 | Joanna Wolfe                                                                                                                                                   |
| 193 |     74.757930 |    534.735847 | Noah Schlottman, photo from Casey Dunn                                                                                                                         |
| 194 |    196.244582 |     24.148742 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 195 |     25.318343 |    657.580020 | NA                                                                                                                                                             |
| 196 |    517.313117 |    175.570914 | NA                                                                                                                                                             |
| 197 |    175.117503 |    467.606226 | Matt Crook                                                                                                                                                     |
| 198 |     19.068419 |     40.507864 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                            |
| 199 |    854.722076 |    415.088674 | Melissa Broussard                                                                                                                                              |
| 200 |    727.068559 |    282.460438 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 201 |    762.375353 |     98.969834 | Zimices                                                                                                                                                        |
| 202 |    771.170397 |    297.917264 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                          |
| 203 |    765.042092 |    516.473762 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                 |
| 204 |    888.038509 |    444.439635 | Michael Scroggie                                                                                                                                               |
| 205 |    149.044143 |    686.021609 | Jose Carlos Arenas-Monroy                                                                                                                                      |
| 206 |    415.400436 |    421.576764 | Ferran Sayol                                                                                                                                                   |
| 207 |    242.844881 |    600.089322 | T. Michael Keesey                                                                                                                                              |
| 208 |    566.894717 |     21.406443 | Renata F. Martins                                                                                                                                              |
| 209 |    362.479724 |    426.183501 | Margot Michaud                                                                                                                                                 |
| 210 |    803.785139 |    313.572699 | T. Michael Keesey                                                                                                                                              |
| 211 |    401.919133 |    708.126921 | Margot Michaud                                                                                                                                                 |
| 212 |    654.643836 |    686.811515 | Zimices                                                                                                                                                        |
| 213 |    332.576420 |    523.672838 | Bruno C. Vellutini                                                                                                                                             |
| 214 |    272.245934 |    103.853438 | Matt Crook                                                                                                                                                     |
| 215 |    849.690866 |    575.592342 | CNZdenek                                                                                                                                                       |
| 216 |    309.448800 |    190.445669 | Christoph Schomburg                                                                                                                                            |
| 217 |    746.894268 |    523.913616 | T. Michael Keesey                                                                                                                                              |
| 218 |    545.841454 |    428.076943 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                          |
| 219 |    461.505833 |    786.970825 | C. Camilo Julián-Caballero                                                                                                                                     |
| 220 |    779.386428 |    468.013560 | NA                                                                                                                                                             |
| 221 |     23.705048 |    739.361781 | Margot Michaud                                                                                                                                                 |
| 222 |    998.176302 |    101.721761 | Bruno C. Vellutini                                                                                                                                             |
| 223 |    262.089539 |    420.076417 | Zimices                                                                                                                                                        |
| 224 |     81.459296 |    666.746671 | NA                                                                                                                                                             |
| 225 |     76.368432 |    619.975886 | FunkMonk                                                                                                                                                       |
| 226 |     11.674234 |    275.599578 | Melissa Broussard                                                                                                                                              |
| 227 |    294.165623 |    702.291373 | Zimices                                                                                                                                                        |
| 228 |    761.055272 |    772.362356 | Zimices                                                                                                                                                        |
| 229 |    742.523960 |    127.221302 | Margot Michaud                                                                                                                                                 |
| 230 |    114.064441 |    290.006692 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                               |
| 231 |    839.041116 |    710.487555 | Amanda Katzer                                                                                                                                                  |
| 232 |    350.494748 |    313.636190 | NA                                                                                                                                                             |
| 233 |    907.789448 |    513.223062 | Robert Gay                                                                                                                                                     |
| 234 |    629.535323 |    330.853863 | Chase Brownstein                                                                                                                                               |
| 235 |     95.471132 |    119.571944 | Myriam\_Ramirez                                                                                                                                                |
| 236 |    890.854356 |    172.495554 | Steven Coombs (vectorized by T. Michael Keesey)                                                                                                                |
| 237 |     22.120399 |    107.274669 | Gareth Monger                                                                                                                                                  |
| 238 |    988.791915 |    354.488540 | Birgit Lang                                                                                                                                                    |
| 239 |    388.246649 |     97.589964 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                |
| 240 |      6.376706 |    471.366640 | T. Michael Keesey                                                                                                                                              |
| 241 |    601.412260 |    451.888784 | M Kolmann                                                                                                                                                      |
| 242 |    429.980306 |    116.121483 | C. Camilo Julián-Caballero                                                                                                                                     |
| 243 |    891.977511 |    367.497932 | Ferran Sayol                                                                                                                                                   |
| 244 |    472.424365 |    746.524052 | Noah Schlottman, photo by Antonio Guillén                                                                                                                      |
| 245 |    236.135759 |    194.994980 | Scott Hartman                                                                                                                                                  |
| 246 |    768.955925 |    787.678755 | Jaime Headden                                                                                                                                                  |
| 247 |    304.947057 |    772.151769 | Tauana J. Cunha                                                                                                                                                |
| 248 |     57.086480 |    132.127368 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                    |
| 249 |    358.330589 |    123.189864 | Steven Traver                                                                                                                                                  |
| 250 |   1003.890922 |     52.119444 | Catherine Yasuda                                                                                                                                               |
| 251 |    722.531251 |    683.968331 | NA                                                                                                                                                             |
| 252 |     53.248998 |     42.874163 | Zimices                                                                                                                                                        |
| 253 |    133.671298 |    766.741145 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 254 |    353.099237 |    644.558726 | Chase Brownstein                                                                                                                                               |
| 255 |    595.225139 |    412.410847 | Mike Hanson                                                                                                                                                    |
| 256 |    287.779939 |    506.190442 | Gabriela Palomo-Munoz                                                                                                                                          |
| 257 |    293.286536 |    606.143835 | Stacy Spensley (Modified)                                                                                                                                      |
| 258 |    328.594685 |    105.734641 | Matt Crook                                                                                                                                                     |
| 259 |     38.034904 |    261.640395 | Margot Michaud                                                                                                                                                 |
| 260 |    186.400959 |    287.601041 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                 |
| 261 |    807.402467 |    766.974901 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                               |
| 262 |    504.046246 |    121.000344 | T. Michael Keesey                                                                                                                                              |
| 263 |    912.039325 |    481.942532 | Margot Michaud                                                                                                                                                 |
| 264 |    565.135570 |    136.224243 | Dean Schnabel                                                                                                                                                  |
| 265 |    184.910039 |    437.650302 | Lisa Byrne                                                                                                                                                     |
| 266 |    324.382399 |    291.147462 | Chris Jennings (vectorized by A. Verrière)                                                                                                                     |
| 267 |    878.353095 |    471.468930 | Gareth Monger                                                                                                                                                  |
| 268 |    927.833959 |    380.907157 | Steven Traver                                                                                                                                                  |
| 269 |    211.860880 |    569.274102 | Birgit Lang                                                                                                                                                    |
| 270 |    547.757807 |     37.476523 | Mykle Hoban                                                                                                                                                    |
| 271 |    909.161998 |    790.540473 | C. Camilo Julián-Caballero                                                                                                                                     |
| 272 |    160.617363 |    445.185758 | Margot Michaud                                                                                                                                                 |
| 273 |    467.451371 |    433.873137 | Steven Traver                                                                                                                                                  |
| 274 |     63.858698 |    202.160048 | Scott Hartman                                                                                                                                                  |
| 275 |     23.434743 |    793.408408 | Dean Schnabel                                                                                                                                                  |
| 276 |    725.921328 |     46.831190 | Bennet McComish, photo by Avenue                                                                                                                               |
| 277 |    758.605493 |    169.648229 | Christoph Schomburg                                                                                                                                            |
| 278 |    560.870392 |    631.804166 | Lauren Anderson                                                                                                                                                |
| 279 |    421.351339 |    758.502141 | DW Bapst (modified from Bulman, 1970)                                                                                                                          |
| 280 |    535.114477 |    370.073436 | Gareth Monger                                                                                                                                                  |
| 281 |    750.372317 |    313.527441 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                              |
| 282 |   1008.127016 |    335.749943 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                        |
| 283 |   1008.360768 |    641.380307 | Josefine Bohr Brask                                                                                                                                            |
| 284 |    273.153614 |    175.333340 | Joanna Wolfe                                                                                                                                                   |
| 285 |     55.908634 |    718.335833 | Joanna Wolfe                                                                                                                                                   |
| 286 |    345.915899 |    249.824880 | Scott Hartman                                                                                                                                                  |
| 287 |    535.410280 |    700.543404 | FunkMonk                                                                                                                                                       |
| 288 |    365.490152 |    219.572994 | Scott Hartman                                                                                                                                                  |
| 289 |    671.191277 |    792.460623 | C. Abraczinskas                                                                                                                                                |
| 290 |    710.387454 |    597.873325 | Scott Hartman                                                                                                                                                  |
| 291 |    363.915317 |    669.616740 | Emily Willoughby                                                                                                                                               |
| 292 |    914.032875 |    633.701892 | Steven Traver                                                                                                                                                  |
| 293 |    693.903918 |    557.393684 | NA                                                                                                                                                             |
| 294 |    557.373304 |    575.357696 | Christine Axon                                                                                                                                                 |
| 295 |    842.553600 |    248.796056 | L. Shyamal                                                                                                                                                     |
| 296 |    177.854125 |    783.591121 | Natasha Vitek                                                                                                                                                  |
| 297 |    334.706620 |    671.125571 | Jagged Fang Designs                                                                                                                                            |
| 298 |    470.126819 |    174.342245 | Gabriela Palomo-Munoz                                                                                                                                          |
| 299 |    380.334067 |    402.935203 | Melissa Broussard                                                                                                                                              |
| 300 |    890.348948 |     42.970594 | Matt Crook                                                                                                                                                     |
| 301 |    321.075015 |     76.855901 | Steven Traver                                                                                                                                                  |
| 302 |    498.822806 |    788.191584 | Jaime Headden                                                                                                                                                  |
| 303 |    327.521435 |    564.709793 | Zimices                                                                                                                                                        |
| 304 |    104.828050 |    774.927195 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                           |
| 305 |    115.511512 |    115.190392 | Ghedoghedo, vectorized by Zimices                                                                                                                              |
| 306 |    836.807317 |    606.227982 | Ferran Sayol                                                                                                                                                   |
| 307 |    768.616457 |    759.342024 | Daniel Stadtmauer                                                                                                                                              |
| 308 |    576.767394 |    454.755306 | Jagged Fang Designs                                                                                                                                            |
| 309 |    968.403785 |    157.157880 | Kelly                                                                                                                                                          |
| 310 |    385.750296 |    428.796591 | Anthony Caravaggi                                                                                                                                              |
| 311 |     54.884778 |    768.351595 | NA                                                                                                                                                             |
| 312 |    947.136381 |    745.757694 | Gareth Monger                                                                                                                                                  |
| 313 |    754.375492 |    421.499645 | Michelle Site                                                                                                                                                  |
| 314 |    867.377026 |    601.639707 | Emily Jane McTavish, from Haeckel, E. H. P. A. (1904).Kunstformen der Natur. Bibliographisches                                                                 |
| 315 |    915.785351 |    400.651569 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                    |
| 316 |    793.199809 |    770.722996 | Felix Vaux                                                                                                                                                     |
| 317 |    238.439309 |    126.602942 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 318 |    156.873562 |    585.908846 | Steven Coombs                                                                                                                                                  |
| 319 |    924.161094 |    717.242159 | James R. Spotila and Ray Chatterji                                                                                                                             |
| 320 |    477.919713 |    351.796702 | Zimices                                                                                                                                                        |
| 321 |    183.043266 |     10.198388 | Carlos Cano-Barbacil                                                                                                                                           |
| 322 |    557.082086 |    156.047079 | Jagged Fang Designs                                                                                                                                            |
| 323 |     15.152475 |    252.886033 | Noah Schlottman                                                                                                                                                |
| 324 |    966.448412 |    287.974427 | Matt Crook                                                                                                                                                     |
| 325 |    395.589219 |      7.920252 | Steven Traver                                                                                                                                                  |
| 326 |     24.806773 |    578.586370 | Michelle Site                                                                                                                                                  |
| 327 |    707.572438 |    789.506846 | Scott Hartman                                                                                                                                                  |
| 328 |    802.434888 |    506.198068 | Matt Crook                                                                                                                                                     |
| 329 |   1011.275375 |    282.638715 | Mark Hannaford (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 330 |     20.812959 |    324.381810 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                  |
| 331 |    845.647994 |    465.764765 | Matt Crook                                                                                                                                                     |
| 332 |    211.650699 |     35.507764 | FunkMonk                                                                                                                                                       |
| 333 |    502.628829 |    752.795821 | Birgit Lang                                                                                                                                                    |
| 334 |    404.089740 |     64.178201 | Steven Traver                                                                                                                                                  |
| 335 |    691.228618 |    539.439823 | Maija Karala                                                                                                                                                   |
| 336 |    299.525009 |     66.340367 | Kelly                                                                                                                                                          |
| 337 |    294.680563 |    361.489800 | Matt Crook                                                                                                                                                     |
| 338 |    543.928876 |    236.477551 | Terpsichores                                                                                                                                                   |
| 339 |    195.494555 |    212.126339 | NA                                                                                                                                                             |
| 340 |    653.355313 |    224.526474 | Rachel Shoop                                                                                                                                                   |
| 341 |     70.478508 |    285.526858 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                    |
| 342 |   1002.391342 |     31.993633 | Chris huh                                                                                                                                                      |
| 343 |   1007.362854 |    759.259949 | Tauana J. Cunha                                                                                                                                                |
| 344 |    534.630098 |    347.612332 | Ferran Sayol                                                                                                                                                   |
| 345 |    214.617157 |    594.668183 | Kailah Thorn & Ben King                                                                                                                                        |
| 346 |    944.166938 |    554.941931 | Harold N Eyster                                                                                                                                                |
| 347 |    577.127061 |    388.786654 | Christine Axon                                                                                                                                                 |
| 348 |    731.872555 |    324.062996 | Ferran Sayol                                                                                                                                                   |
| 349 |    426.297541 |    784.700647 | Matt Crook                                                                                                                                                     |
| 350 |    368.151260 |    165.108600 | NA                                                                                                                                                             |
| 351 |   1017.274263 |    429.934228 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
| 352 |    931.594111 |    203.619033 | Steven Traver                                                                                                                                                  |
| 353 |    577.318075 |    567.247236 | Matt Wilkins                                                                                                                                                   |
| 354 |    647.125025 |    525.011189 | Scott Hartman                                                                                                                                                  |
| 355 |    460.300988 |    486.366323 | Margot Michaud                                                                                                                                                 |
| 356 |    725.768362 |     69.412609 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                 |
| 357 |    946.446016 |     47.689952 | NA                                                                                                                                                             |
| 358 |    317.654719 |     30.037707 | Zimices                                                                                                                                                        |
| 359 |    606.432370 |    789.363030 | Steven Haddock • Jellywatch.org                                                                                                                                |
| 360 |    542.185611 |    602.467768 | NA                                                                                                                                                             |
| 361 |    518.463646 |     42.878722 | Scott Hartman                                                                                                                                                  |
| 362 |    944.915015 |    466.581478 | Kamil S. Jaron                                                                                                                                                 |
| 363 |    108.465099 |    365.498425 | Jagged Fang Designs                                                                                                                                            |
| 364 |    260.261993 |     97.770827 | Rebecca Groom                                                                                                                                                  |
| 365 |    494.382086 |      8.899857 | Kai R. Caspar                                                                                                                                                  |
| 366 |    514.053166 |    705.885111 | Crystal Maier                                                                                                                                                  |
| 367 |    653.384529 |    597.557791 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                           |
| 368 |    813.143976 |    653.939712 | Christoph Schomburg                                                                                                                                            |
| 369 |    886.752115 |    701.911597 | Alexandre Vong                                                                                                                                                 |
| 370 |    956.032688 |    766.706595 | Felix Vaux                                                                                                                                                     |
| 371 |    252.851842 |    162.690577 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                  |
| 372 |    799.873263 |    488.466412 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                |
| 373 |    185.282489 |    305.130244 | Zimices                                                                                                                                                        |
| 374 |    532.710004 |    489.533252 | Beth Reinke                                                                                                                                                    |
| 375 |    803.062246 |    711.043527 | Jagged Fang Designs                                                                                                                                            |
| 376 |    328.049992 |    712.080873 | T. Michael Keesey                                                                                                                                              |
| 377 |     23.474095 |    595.857937 | Gabriela Palomo-Munoz                                                                                                                                          |
| 378 |    919.690325 |    666.487723 | T. Michael Keesey                                                                                                                                              |
| 379 |    935.033404 |     64.503272 | Andrés Sánchez                                                                                                                                                 |
| 380 |     24.756728 |    634.130205 | Kai R. Caspar                                                                                                                                                  |
| 381 |    127.168401 |    327.187413 | Matt Crook                                                                                                                                                     |
| 382 |    782.904926 |    385.638439 | Jonathan Wells                                                                                                                                                 |
| 383 |    654.649133 |    772.698857 | NA                                                                                                                                                             |
| 384 |    189.321816 |    684.982481 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                   |
| 385 |     40.273983 |    782.629826 | Lafage                                                                                                                                                         |
| 386 |    487.328004 |    157.670843 | Margot Michaud                                                                                                                                                 |
| 387 |    313.379857 |    501.336534 | Chris huh                                                                                                                                                      |
| 388 |    797.932592 |    691.864726 | Henry Lydecker                                                                                                                                                 |
| 389 |    953.670109 |    528.281380 | Sharon Wegner-Larsen                                                                                                                                           |
| 390 |    617.550715 |    402.687343 | Jaime Headden                                                                                                                                                  |
| 391 |    274.631209 |    795.414522 | Juan Carlos Jerí                                                                                                                                               |
| 392 |    306.569316 |    431.000785 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                                |
| 393 |    240.387587 |     75.400393 | Michele Tobias                                                                                                                                                 |
| 394 |    585.814625 |    430.747133 | NA                                                                                                                                                             |
| 395 |    261.996949 |    114.932195 | Christoph Schomburg                                                                                                                                            |
| 396 |    385.323686 |     38.250713 | NA                                                                                                                                                             |
| 397 |    681.042777 |    109.343709 | Tracy A. Heath                                                                                                                                                 |
| 398 |    236.837660 |    563.183670 | Chris huh                                                                                                                                                      |
| 399 |     69.839627 |    695.407896 | Matt Crook                                                                                                                                                     |
| 400 |    681.095956 |    739.003038 | T. Michael Keesey                                                                                                                                              |
| 401 |    774.742764 |    700.251817 | Beth Reinke                                                                                                                                                    |
| 402 |    685.360822 |    399.360381 | Y. de Hoev. (vectorized by T. Michael Keesey)                                                                                                                  |
| 403 |    826.250269 |    134.902250 | Siobhon Egan                                                                                                                                                   |
| 404 |    225.406189 |    427.297706 | Aviceda (vectorized by T. Michael Keesey)                                                                                                                      |
| 405 |     52.273056 |    685.403494 | Sarah Werning                                                                                                                                                  |
| 406 |    436.498781 |    395.539495 | Katie S. Collins                                                                                                                                               |
| 407 |    806.031471 |    143.896408 | Chris huh                                                                                                                                                      |
| 408 |      3.202714 |    177.950073 | NA                                                                                                                                                             |
| 409 |    973.505928 |    786.980389 | Kailah Thorn & Mark Hutchinson                                                                                                                                 |
| 410 |    714.770580 |    413.131819 | Jagged Fang Designs                                                                                                                                            |
| 411 |    420.782061 |    484.937194 | Henry Lydecker                                                                                                                                                 |
| 412 |    826.069916 |    524.059550 | Shyamal                                                                                                                                                        |
| 413 |    643.014280 |    178.349716 | Steven Traver                                                                                                                                                  |
| 414 |   1005.690966 |    616.302922 | Margot Michaud                                                                                                                                                 |
| 415 |    810.462194 |    467.356903 | T. Michael Keesey                                                                                                                                              |
| 416 |    732.485106 |    796.933032 | Smokeybjb                                                                                                                                                      |
| 417 |    812.727032 |    568.207735 | Ferran Sayol                                                                                                                                                   |
| 418 |    407.606140 |    740.761987 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                              |
| 419 |     85.795960 |    384.081473 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                 |
| 420 |    130.144226 |    653.538016 | Gabriela Palomo-Munoz                                                                                                                                          |
| 421 |    898.564629 |    218.303358 | Emma Kissling                                                                                                                                                  |
| 422 |    852.779632 |     18.195645 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                   |
| 423 |    761.819953 |    358.486510 | Chris huh                                                                                                                                                      |
| 424 |    958.678753 |    791.712067 | Zachary Quigley                                                                                                                                                |
| 425 |     32.765984 |     58.713800 | Chris huh                                                                                                                                                      |
| 426 |    664.285319 |    715.052314 | Matt Dempsey                                                                                                                                                   |
| 427 |    129.618622 |    702.529109 | Jagged Fang Designs                                                                                                                                            |
| 428 |    448.929442 |      4.563694 | Roberto Díaz Sibaja                                                                                                                                            |
| 429 |    925.910454 |    733.348093 | Gareth Monger                                                                                                                                                  |
| 430 |    350.227341 |    366.330675 | C. Camilo Julián-Caballero                                                                                                                                     |
| 431 |    415.603199 |    472.863357 | Maija Karala                                                                                                                                                   |
| 432 |    139.188236 |    217.028374 | Jake Warner                                                                                                                                                    |
| 433 |    235.765499 |    667.214476 | Jagged Fang Designs                                                                                                                                            |
| 434 |    605.913037 |    529.499851 | Lukasiniho                                                                                                                                                     |
| 435 |    567.584619 |    370.152205 | NA                                                                                                                                                             |
| 436 |    945.215206 |    675.163053 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 437 |    742.173338 |    701.838892 | David Orr                                                                                                                                                      |
| 438 |    236.985761 |    112.316159 | T. Michael Keesey                                                                                                                                              |
| 439 |    154.573371 |    792.792007 | Chris huh                                                                                                                                                      |
| 440 |    475.781182 |    405.526739 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                   |
| 441 |    273.514434 |    542.472754 | Jagged Fang Designs                                                                                                                                            |
| 442 |    328.894153 |    793.783262 | Smokeybjb                                                                                                                                                      |
| 443 |    117.949156 |    499.604608 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                             |
| 444 |    939.062755 |    350.379617 | Jagged Fang Designs                                                                                                                                            |
| 445 |    946.165698 |    659.852848 | T. Michael Keesey                                                                                                                                              |
| 446 |    103.584473 |    391.692123 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 447 |    629.184075 |    136.839770 | T. Michael Keesey (photo by Sean Mack)                                                                                                                         |
| 448 |    507.230504 |    475.846831 | Matt Crook                                                                                                                                                     |
| 449 |     25.370591 |    236.122024 | Margot Michaud                                                                                                                                                 |
| 450 |    689.316363 |     51.974964 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                               |
| 451 |    562.106439 |    500.134647 | Chris huh                                                                                                                                                      |
| 452 |    107.765845 |    522.481504 | Zimices                                                                                                                                                        |
| 453 |    380.213507 |    233.581393 | Chris huh                                                                                                                                                      |
| 454 |    605.512124 |    776.168289 | Cesar Julian                                                                                                                                                   |
| 455 |    988.083765 |    507.292547 | Jagged Fang Designs                                                                                                                                            |
| 456 |    782.379208 |     77.971780 | Margot Michaud                                                                                                                                                 |
| 457 |    931.966205 |    261.738979 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                |
| 458 |    750.006000 |    514.865403 | Caleb M. Brown                                                                                                                                                 |
| 459 |    475.753419 |    419.733292 | Chris huh                                                                                                                                                      |
| 460 |    170.772776 |    275.065295 | Matt Crook                                                                                                                                                     |
| 461 |    932.233709 |    366.259652 | Shyamal                                                                                                                                                        |
| 462 |    815.301381 |    301.115959 | Gareth Monger                                                                                                                                                  |
| 463 |    563.412433 |    543.979640 | Milton Tan                                                                                                                                                     |
| 464 |    702.708020 |    691.088368 | Mattia Menchetti                                                                                                                                               |
| 465 |    672.018148 |    679.979096 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 466 |    757.632656 |      6.611301 | Martin Kevil                                                                                                                                                   |
| 467 |    117.405140 |    794.740818 | Jack Mayer Wood                                                                                                                                                |
| 468 |    309.740425 |    336.155035 | FJDegrange                                                                                                                                                     |
| 469 |    907.801458 |    611.904942 | (after Spotila 2004)                                                                                                                                           |
| 470 |    772.820907 |    654.661681 | Smokeybjb                                                                                                                                                      |
| 471 |    527.678493 |    785.051354 | Gareth Monger                                                                                                                                                  |
| 472 |    616.273688 |    319.138821 | Scott Hartman                                                                                                                                                  |
| 473 |    802.258538 |    681.962178 | Roberto Díaz Sibaja                                                                                                                                            |
| 474 |    743.584257 |    469.018892 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                                |
| 475 |    248.532350 |    777.268330 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 476 |   1001.707051 |    652.250695 | Chris huh                                                                                                                                                      |
| 477 |    907.709781 |     77.757630 | AnAgnosticGod (vectorized by T. Michael Keesey)                                                                                                                |
| 478 |   1005.830211 |    778.882346 | Sharon Wegner-Larsen                                                                                                                                           |
| 479 |    557.750654 |    768.731695 | Tracy A. Heath                                                                                                                                                 |
| 480 |    848.593885 |    227.739094 | Jonathan Wells                                                                                                                                                 |
| 481 |    126.952739 |    251.354608 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                          |
| 482 |    108.781904 |     15.127197 | Joanna Wolfe                                                                                                                                                   |
| 483 |    745.098060 |    345.959961 | Felix Vaux                                                                                                                                                     |
| 484 |     90.904097 |    277.482014 | Collin Gross                                                                                                                                                   |
| 485 |    255.887479 |    653.100826 | Maija Karala                                                                                                                                                   |
| 486 |     22.290360 |      9.500802 | Wayne Decatur                                                                                                                                                  |
| 487 |     27.175989 |    397.007999 | Tambja (vectorized by T. Michael Keesey)                                                                                                                       |
| 488 |    332.834135 |    420.511197 | Chris huh                                                                                                                                                      |
| 489 |    329.494651 |    212.719897 | Nina Skinner                                                                                                                                                   |
| 490 |     30.259152 |    674.112579 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 491 |    806.903525 |    255.004837 | C. Camilo Julián-Caballero                                                                                                                                     |
| 492 |    501.854659 |    143.982655 | Ludwik Gasiorowski                                                                                                                                             |
| 493 |    117.663124 |      3.127413 | NA                                                                                                                                                             |
| 494 |    993.376226 |    743.006667 | (after Spotila 2004)                                                                                                                                           |
| 495 |    625.418386 |    622.455417 | Andrew A. Farke                                                                                                                                                |
| 496 |    218.651152 |    655.479130 | Stuart Humphries                                                                                                                                               |
| 497 |    686.911041 |    626.858819 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                       |
| 498 |    334.477414 |    261.962992 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 499 |    814.704465 |    717.226338 | NA                                                                                                                                                             |
| 500 |    921.509989 |    752.252276 | Christine Axon                                                                                                                                                 |
| 501 |    970.165247 |    221.573894 | Carlos Cano-Barbacil                                                                                                                                           |
| 502 |    540.984299 |    265.732046 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                      |
| 503 |    911.125430 |    599.648227 | Gareth Monger                                                                                                                                                  |
| 504 |    799.587143 |    243.393948 | Maija Karala                                                                                                                                                   |
| 505 |    149.378963 |    466.337937 | Tasman Dixon                                                                                                                                                   |
| 506 |    369.028717 |    611.312900 | Karla Martinez                                                                                                                                                 |
| 507 |    919.499715 |    562.207492 | Gareth Monger                                                                                                                                                  |
| 508 |    159.612817 |     12.085975 | Ferran Sayol                                                                                                                                                   |
| 509 |    524.360923 |    192.869503 | Chris huh                                                                                                                                                      |
| 510 |    340.763738 |    408.481443 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 511 |    731.661644 |    591.938095 | S.Martini                                                                                                                                                      |
| 512 |    345.919279 |    333.752590 | M Kolmann                                                                                                                                                      |
| 513 |     19.617428 |    684.966062 | Chris huh                                                                                                                                                      |
| 514 |     11.382894 |    406.091399 | Gareth Monger                                                                                                                                                  |
| 515 |    800.942785 |     13.132137 | NA                                                                                                                                                             |
| 516 |    493.046786 |     85.568956 | Pranav Iyer (grey ideas)                                                                                                                                       |
| 517 |    238.337174 |    296.886174 | Scott Hartman                                                                                                                                                  |
| 518 |    712.842943 |    105.041323 | Smokeybjb                                                                                                                                                      |
| 519 |    465.385096 |     11.358899 | Scott Hartman                                                                                                                                                  |
| 520 |    182.428626 |    223.103125 | Scott Hartman                                                                                                                                                  |
| 521 |    728.358576 |    417.157959 | Scott Hartman                                                                                                                                                  |
| 522 |    512.112576 |    425.346814 | Zimices                                                                                                                                                        |
| 523 |    486.787242 |    176.526042 | Ferran Sayol                                                                                                                                                   |
| 524 |    200.010816 |    456.719261 | Gabriela Palomo-Munoz                                                                                                                                          |
| 525 |    871.864924 |    790.478188 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 526 |    823.384190 |    380.716176 | Ferran Sayol                                                                                                                                                   |
| 527 |    992.504471 |    253.709640 | Gareth Monger                                                                                                                                                  |
| 528 |    377.807435 |    134.891871 | Zimices                                                                                                                                                        |
| 529 |    336.314264 |    680.119856 | Birgit Lang                                                                                                                                                    |
| 530 |    897.383945 |    162.764162 | Margot Michaud                                                                                                                                                 |
| 531 |    966.955040 |    374.872339 | Tracy A. Heath                                                                                                                                                 |
| 532 |   1003.648514 |    664.543664 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                               |
| 533 |    912.757479 |     60.799416 | Jagged Fang Designs                                                                                                                                            |
| 534 |    272.466057 |    435.173609 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                       |

    #> Your tweet has been posted!
