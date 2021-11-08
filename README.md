
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

Ville-Veikko Sinkkonen, Andrew A. Farke, Zimices, Matt Dempsey, Ferran
Sayol, Henry Fairfield Osborn, vectorized by Zimices, Margot Michaud,
Caleb M. Brown, Lee Harding (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Matt Crook, B. Duygu Özpolat, Nobu
Tamura, vectorized by Zimices, Jon Hill (Photo by DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), Didier
Descouens (vectorized by T. Michael Keesey), Michelle Site, Gabriela
Palomo-Munoz, Gareth Monger, Arthur S. Brum, Iain Reid, Nobu Tamura
(vectorized by T. Michael Keesey), T. Michael Keesey, Chris huh, Steven
Traver, Allison Pease, Alex Slavenko, Dean Schnabel, Cristina Guijarro,
SecretJellyMan, Hans Hillewaert (vectorized by T. Michael Keesey),
Jagged Fang Designs, Steven Coombs, Pete Buchholz, Yan Wong, Jim Bendon
(photography) and T. Michael Keesey (vectorization), Mary Harrsch
(modified by T. Michael Keesey), Michele M Tobias, NOAA Great Lakes
Environmental Research Laboratory (illustration) and Timothy J. Bartley
(silhouette), Christoph Schomburg, Mariana Ruiz Villarreal (modified by
T. Michael Keesey), Owen Jones (derived from a CC-BY 2.0 photograph by
Paulo B. Chaves), Scott Hartman, Darius Nau, Tracy A. Heath, T. Michael
Keesey (after James & al.), Jessica Anne Miller, Roberto Díaz Sibaja,
Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes
(www.carnivorosaustrales.org), Sergio A. Muñoz-Gómez, Anthony Caravaggi,
Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow
(vectorized by T. Michael Keesey), Steven Blackwood, , Noah Schlottman,
Scott Hartman (modified by T. Michael Keesey), Mali’o Kodis, photograph
by Bruno Vellutini, Pollyanna von Knorring and T. Michael Keesey, Tauana
J. Cunha, Jimmy Bernot, Brad McFeeters (vectorized by T. Michael
Keesey), Kamil S. Jaron, Cesar Julian, Lukasiniho, Dori <dori@merr.info>
(source photo) and Nevit Dilmen, Dmitry Bogdanov (vectorized by T.
Michael Keesey), Gabriele Midolo, Carlos Cano-Barbacil, Beth Reinke,
Mathieu Basille, Alexander Schmidt-Lebuhn, Lisa M. “Pixxl” (photo), John
E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Javier
Luque, Mali’o Kodis, image by Rebecca Ritger, Burton Robert, USFWS,
Siobhon Egan, Felix Vaux, Dennis C. Murphy, after
<https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png>,
Liftarn, Katie S. Collins, Armin Reindl, NASA, nicubunu, Collin Gross,
Michael Scroggie, Smokeybjb (vectorized by T. Michael Keesey), Lily
Hughes, Enoch Joseph Wetsy (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Tasman Dixon, FunkMonk, Juan Carlos
Jerí, S.Martini, xgirouxb, Scott Hartman (vectorized by T. Michael
Keesey), Chuanixn Yu, Joe Schneid (vectorized by T. Michael Keesey),
Oscar Sanisidro, Sam Droege (photography) and T. Michael Keesey
(vectorization), Geoff Shaw, Mariana Ruiz (vectorized by T. Michael
Keesey), JCGiron, Mali’o Kodis, photograph from Jersabek et al, 2003, C.
Camilo Julián-Caballero, Jiekun He, Chloé Schmidt, Arthur Weasley
(vectorized by T. Michael Keesey), Maxime Dahirel, Maha Ghazal, Ron
Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey
(vectorization), Noah Schlottman, photo from Casey Dunn, Darren Naish
(vectorized by T. Michael Keesey), Acrocynus (vectorized by T. Michael
Keesey), Nobu Tamura (vectorized by A. Verrière), Gopal Murali, L.
Shyamal, Original drawing by Antonov, vectorized by Roberto Díaz Sibaja,
Dmitry Bogdanov, Rebecca Groom, Birgit Lang, Ray Simpson (vectorized by
T. Michael Keesey), Jaime Headden, Cristopher Silva, Sarah Werning,
Kimberly Haddrell, Smokeybjb, Mali’o Kodis, photograph by P. Funch and
R.M. Kristensen, (after Spotila 2004), Maxwell Lefroy (vectorized by T.
Michael Keesey), Kai R. Caspar, Chris Jennings (vectorized by A.
Verrière), Joris van der Ham (vectorized by T. Michael Keesey), M
Kolmann, Manabu Sakamoto, FunkMonk (Michael B. H.), T. Michael Keesey
(after Tillyard), Shyamal, Nicholas J. Czaplewski, vectorized by
Zimices, Josefine Bohr Brask, Becky Barnes, Milton Tan, Craig Dylke,
SauropodomorphMonarch, Inessa Voet, Lisa Byrne, Christopher Chávez, DW
Bapst (Modified from photograph taken by Charles Mitchell), Martin R.
Smith, John Gould (vectorized by T. Michael Keesey), Noah Schlottman,
photo by Antonio Guillén, Melissa Broussard, Harold N Eyster, Nobu
Tamura, CNZdenek, Emily Willoughby, Emil Schmidt (vectorized by Maxime
Dahirel), Kenneth Lacovara (vectorized by T. Michael Keesey), RS, Tambja
(vectorized by T. Michael Keesey), Robbie N. Cada (vectorized by T.
Michael Keesey), Alexandre Vong, Jaime A. Headden (vectorized by T.
Michael Keesey), Margret Flinsch, vectorized by Zimices, James I.
Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and
Jelle P. Wiersma (vectorized by T. Michael Keesey), Danny Cicchetti
(vectorized by T. Michael Keesey), Tyler Greenfield, Ingo Braasch, Conty
(vectorized by T. Michael Keesey), Mario Quevedo, Mason McNair, Matt
Martyniuk, Caroline Harding, MAF (vectorized by T. Michael Keesey), Tony
Ayling (vectorized by T. Michael Keesey), Henry Lydecker, Xavier
Giroux-Bougard, Kent Elson Sorgon, Maija Karala, Lafage, Hans Hillewaert
(photo) and T. Michael Keesey (vectorization), Kailah Thorn & Mark
Hutchinson, Auckland Museum and T. Michael Keesey, Eduard Solà
(vectorized by T. Michael Keesey),
\<U+0414\>\<U+0438\>\<U+0411\>\<U+0433\>\<U+0434\> (vectorized by T.
Michael Keesey), Apokryltaros (vectorized by T. Michael Keesey), Mihai
Dragos (vectorized by T. Michael Keesey), Sherman F. Denton via
rawpixel.com (illustration) and Timothy J. Bartley (silhouette), Steven
Haddock • Jellywatch.org, Blanco et al., 2014, vectorized by Zimices,
Tomas Willems (vectorized by T. Michael Keesey), Bennet McComish, photo
by Hans Hillewaert, Rachel Shoop

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                          |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
|   1 |    143.928981 |    665.178507 | Ville-Veikko Sinkkonen                                                                                                                                                          |
|   2 |    409.118816 |    216.973597 | Andrew A. Farke                                                                                                                                                                 |
|   3 |    507.154785 |    584.247572 | Zimices                                                                                                                                                                         |
|   4 |    464.056694 |    678.427372 | Matt Dempsey                                                                                                                                                                    |
|   5 |    681.907778 |    110.578318 | Ferran Sayol                                                                                                                                                                    |
|   6 |    757.583732 |    128.056249 | NA                                                                                                                                                                              |
|   7 |    662.075203 |    618.417648 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                                   |
|   8 |    823.616334 |    609.292254 | Margot Michaud                                                                                                                                                                  |
|   9 |    582.705067 |    387.332868 | Caleb M. Brown                                                                                                                                                                  |
|  10 |    762.116306 |    711.590926 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                     |
|  11 |    873.781461 |    287.677693 | Matt Crook                                                                                                                                                                      |
|  12 |    804.555594 |    502.086329 | B. Duygu Özpolat                                                                                                                                                                |
|  13 |    264.470288 |    734.582481 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
|  14 |     39.392946 |     64.835831 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                                  |
|  15 |    237.458914 |    381.643463 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                              |
|  16 |    695.162052 |    682.607779 | Caleb M. Brown                                                                                                                                                                  |
|  17 |    498.346183 |    480.081277 | Michelle Site                                                                                                                                                                   |
|  18 |    756.971630 |    330.788272 | Zimices                                                                                                                                                                         |
|  19 |    379.541903 |    468.333849 | Gabriela Palomo-Munoz                                                                                                                                                           |
|  20 |    154.992630 |    402.718235 | Gareth Monger                                                                                                                                                                   |
|  21 |    651.184500 |    538.636112 | Arthur S. Brum                                                                                                                                                                  |
|  22 |    444.931867 |    644.987212 | Iain Reid                                                                                                                                                                       |
|  23 |    577.503491 |    235.121951 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
|  24 |    297.016475 |    594.622672 | T. Michael Keesey                                                                                                                                                               |
|  25 |    212.815410 |    301.546997 | Chris huh                                                                                                                                                                       |
|  26 |    224.826800 |    466.267797 | Chris huh                                                                                                                                                                       |
|  27 |    917.564435 |    441.019120 | Steven Traver                                                                                                                                                                   |
|  28 |    865.288957 |    778.904634 | Zimices                                                                                                                                                                         |
|  29 |    158.412481 |    570.285463 | Allison Pease                                                                                                                                                                   |
|  30 |    342.669081 |    757.454133 | Alex Slavenko                                                                                                                                                                   |
|  31 |    562.935285 |    721.978280 | Dean Schnabel                                                                                                                                                                   |
|  32 |    482.606225 |    385.080787 | Matt Crook                                                                                                                                                                      |
|  33 |    953.021756 |    249.065651 | Cristina Guijarro                                                                                                                                                               |
|  34 |    123.719377 |    135.198792 | SecretJellyMan                                                                                                                                                                  |
|  35 |    517.250593 |     65.839073 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                               |
|  36 |    943.896529 |     45.884975 | Gareth Monger                                                                                                                                                                   |
|  37 |    673.084773 |    427.374360 | Matt Crook                                                                                                                                                                      |
|  38 |    921.913270 |    137.467757 | Gabriela Palomo-Munoz                                                                                                                                                           |
|  39 |    648.123916 |    337.410958 | Ferran Sayol                                                                                                                                                                    |
|  40 |     77.032384 |    474.493045 | Jagged Fang Designs                                                                                                                                                             |
|  41 |    824.586654 |    164.742142 | Steven Traver                                                                                                                                                                   |
|  42 |    384.141192 |    345.051123 | Steven Coombs                                                                                                                                                                   |
|  43 |    361.293992 |     72.876393 | Pete Buchholz                                                                                                                                                                   |
|  44 |     66.161368 |    240.181257 | Yan Wong                                                                                                                                                                        |
|  45 |    406.851363 |    310.232049 | Chris huh                                                                                                                                                                       |
|  46 |    906.667566 |    706.867209 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                                  |
|  47 |    750.472543 |    245.176449 | Mary Harrsch (modified by T. Michael Keesey)                                                                                                                                    |
|  48 |    940.863802 |    545.518576 | Michele M Tobias                                                                                                                                                                |
|  49 |     81.983152 |    743.101678 | Zimices                                                                                                                                                                         |
|  50 |     60.695991 |    361.753834 | NA                                                                                                                                                                              |
|  51 |    356.484686 |    394.557442 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                           |
|  52 |    261.820223 |    120.952424 | Christoph Schomburg                                                                                                                                                             |
|  53 |    406.249774 |    587.275676 | Mariana Ruiz Villarreal (modified by T. Michael Keesey)                                                                                                                         |
|  54 |    699.936111 |    466.506959 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                                             |
|  55 |    527.533234 |    146.183983 | Scott Hartman                                                                                                                                                                   |
|  56 |    204.618947 |     67.197161 | Steven Traver                                                                                                                                                                   |
|  57 |    128.618169 |    533.051516 | Chris huh                                                                                                                                                                       |
|  58 |    664.207130 |    196.195160 | Pete Buchholz                                                                                                                                                                   |
|  59 |    841.371794 |     64.819307 | Gareth Monger                                                                                                                                                                   |
|  60 |    575.265903 |    509.145726 | Darius Nau                                                                                                                                                                      |
|  61 |    898.531442 |    356.661458 | Tracy A. Heath                                                                                                                                                                  |
|  62 |    328.800698 |    685.724769 | T. Michael Keesey (after James & al.)                                                                                                                                           |
|  63 |    960.135828 |    627.573934 | Jagged Fang Designs                                                                                                                                                             |
|  64 |    188.634174 |    261.830337 | Chris huh                                                                                                                                                                       |
|  65 |    638.290796 |     44.310948 | Margot Michaud                                                                                                                                                                  |
|  66 |    702.225459 |    760.616587 | Ferran Sayol                                                                                                                                                                    |
|  67 |     76.571387 |    592.612670 | Scott Hartman                                                                                                                                                                   |
|  68 |    803.477599 |    411.007588 | Jessica Anne Miller                                                                                                                                                             |
|  69 |    482.926981 |    775.668275 | Scott Hartman                                                                                                                                                                   |
|  70 |    251.038337 |    505.048834 | Scott Hartman                                                                                                                                                                   |
|  71 |    366.486814 |    535.142955 | Roberto Díaz Sibaja                                                                                                                                                             |
|  72 |    734.043938 |     33.916106 | Matt Dempsey                                                                                                                                                                    |
|  73 |    987.205185 |    713.401731 | NA                                                                                                                                                                              |
|  74 |    960.345699 |    414.366047 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                                    |
|  75 |    855.681610 |    465.853566 | Sergio A. Muñoz-Gómez                                                                                                                                                           |
|  76 |    489.735109 |    237.981164 | Margot Michaud                                                                                                                                                                  |
|  77 |     59.313755 |    448.362140 | Anthony Caravaggi                                                                                                                                                               |
|  78 |    975.308025 |    466.934498 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                             |
|  79 |    212.164958 |    779.432914 | Steven Blackwood                                                                                                                                                                |
|  80 |     30.832099 |    308.740341 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
|  81 |    637.427057 |    576.073043 | Yan Wong                                                                                                                                                                        |
|  82 |    707.127767 |    284.204804 |                                                                                                                                                                                 |
|  83 |    526.480929 |    307.825333 | Noah Schlottman                                                                                                                                                                 |
|  84 |     55.310497 |    514.491104 | Mary Harrsch (modified by T. Michael Keesey)                                                                                                                                    |
|  85 |    214.164792 |    613.453980 | Matt Dempsey                                                                                                                                                                    |
|  86 |    250.657388 |    558.787177 | NA                                                                                                                                                                              |
|  87 |    207.507218 |    158.156781 | Gareth Monger                                                                                                                                                                   |
|  88 |    985.913402 |    106.234450 | Alex Slavenko                                                                                                                                                                   |
|  89 |    723.891366 |    572.662149 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
|  90 |    273.406442 |    706.544228 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                                   |
|  91 |    966.636769 |    331.127580 | Matt Crook                                                                                                                                                                      |
|  92 |    174.330418 |    213.184121 | Chris huh                                                                                                                                                                       |
|  93 |    333.243764 |    635.959813 | T. Michael Keesey                                                                                                                                                               |
|  94 |    491.850905 |    294.140072 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                                     |
|  95 |    837.224788 |    713.136643 | NA                                                                                                                                                                              |
|  96 |    682.871460 |     74.184825 | Ferran Sayol                                                                                                                                                                    |
|  97 |    107.643881 |     45.338885 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                              |
|  98 |    580.432611 |    124.715230 | Ferran Sayol                                                                                                                                                                    |
|  99 |    752.105061 |    464.571356 | Michelle Site                                                                                                                                                                   |
| 100 |    674.864013 |    252.702210 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                                    |
| 101 |    573.999759 |    462.715693 | Steven Traver                                                                                                                                                                   |
| 102 |    980.935401 |     64.754818 | NA                                                                                                                                                                              |
| 103 |    532.393230 |    638.757780 | Jagged Fang Designs                                                                                                                                                             |
| 104 |    261.792392 |    318.243434 | Tauana J. Cunha                                                                                                                                                                 |
| 105 |    844.864890 |    226.359708 | Margot Michaud                                                                                                                                                                  |
| 106 |   1011.771789 |    138.592305 | Jimmy Bernot                                                                                                                                                                    |
| 107 |    812.087665 |     11.225486 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                |
| 108 |    386.117947 |    716.588212 | Ferran Sayol                                                                                                                                                                    |
| 109 |   1008.607352 |    180.442307 | Scott Hartman                                                                                                                                                                   |
| 110 |    848.548996 |    755.843414 | Chris huh                                                                                                                                                                       |
| 111 |     10.472249 |    407.870411 | T. Michael Keesey                                                                                                                                                               |
| 112 |    106.731122 |    607.573393 | Kamil S. Jaron                                                                                                                                                                  |
| 113 |     57.999884 |    191.400120 | Cesar Julian                                                                                                                                                                    |
| 114 |    996.151002 |    200.858297 | NA                                                                                                                                                                              |
| 115 |    787.067085 |    755.927518 | Lukasiniho                                                                                                                                                                      |
| 116 |    742.649411 |    624.586453 | Dori <dori@merr.info> (source photo) and Nevit Dilmen                                                                                                                           |
| 117 |     89.846432 |    489.601530 | Zimices                                                                                                                                                                         |
| 118 |    801.552772 |     48.477438 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 119 |    384.409254 |    781.498361 | Jagged Fang Designs                                                                                                                                                             |
| 120 |    411.826882 |    513.431318 | Dean Schnabel                                                                                                                                                                   |
| 121 |     27.890053 |    736.403226 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 122 |    406.547921 |    140.624934 | Sergio A. Muñoz-Gómez                                                                                                                                                           |
| 123 |     20.367475 |    692.060481 | Yan Wong                                                                                                                                                                        |
| 124 |    934.952354 |    672.179384 | Gareth Monger                                                                                                                                                                   |
| 125 |    395.398933 |    266.218507 | Gabriele Midolo                                                                                                                                                                 |
| 126 |    607.890396 |     73.978688 | Gareth Monger                                                                                                                                                                   |
| 127 |    889.792794 |     11.057063 | Dean Schnabel                                                                                                                                                                   |
| 128 |    826.400039 |    556.782554 | Carlos Cano-Barbacil                                                                                                                                                            |
| 129 |    775.961926 |    782.292832 | Alex Slavenko                                                                                                                                                                   |
| 130 |    998.362110 |    519.012933 | T. Michael Keesey                                                                                                                                                               |
| 131 |     16.617004 |    622.451808 | Beth Reinke                                                                                                                                                                     |
| 132 |    610.920078 |    780.509718 | Chris huh                                                                                                                                                                       |
| 133 |    382.256196 |    139.437459 | Scott Hartman                                                                                                                                                                   |
| 134 |    961.238877 |    644.812714 | T. Michael Keesey                                                                                                                                                               |
| 135 |    734.368813 |    779.653505 | Mathieu Basille                                                                                                                                                                 |
| 136 |    552.315518 |    295.402542 | Margot Michaud                                                                                                                                                                  |
| 137 |    746.945607 |    678.115518 | Gareth Monger                                                                                                                                                                   |
| 138 |    835.712267 |    262.098393 | Andrew A. Farke                                                                                                                                                                 |
| 139 |    712.838809 |     88.363031 | Tracy A. Heath                                                                                                                                                                  |
| 140 |    552.893663 |    772.337724 | Alexander Schmidt-Lebuhn                                                                                                                                                        |
| 141 |    189.442981 |    518.604587 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                 |
| 142 |    233.655164 |      8.872811 | Javier Luque                                                                                                                                                                    |
| 143 |    225.847973 |    537.831684 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                                           |
| 144 |    365.999836 |    624.448851 | Burton Robert, USFWS                                                                                                                                                            |
| 145 |    651.886428 |    150.195506 | Siobhon Egan                                                                                                                                                                    |
| 146 |    799.750649 |    690.284899 | Felix Vaux                                                                                                                                                                      |
| 147 |    225.663002 |    220.421958 | Gareth Monger                                                                                                                                                                   |
| 148 |    254.361179 |    593.736683 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 149 |    294.002062 |    472.634285 | Jagged Fang Designs                                                                                                                                                             |
| 150 |    308.475488 |     87.942615 | Dennis C. Murphy, after <https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png> |
| 151 |    286.654112 |    408.523378 | Liftarn                                                                                                                                                                         |
| 152 |    666.212976 |     10.682170 | Katie S. Collins                                                                                                                                                                |
| 153 |     68.565005 |     27.341619 | Ferran Sayol                                                                                                                                                                    |
| 154 |    332.475972 |    309.007853 | Zimices                                                                                                                                                                         |
| 155 |    317.423819 |    132.752563 | Armin Reindl                                                                                                                                                                    |
| 156 |    356.461657 |    658.317818 | NASA                                                                                                                                                                            |
| 157 |    587.259792 |    625.927136 | Ferran Sayol                                                                                                                                                                    |
| 158 |    976.857823 |     51.461858 | nicubunu                                                                                                                                                                        |
| 159 |    580.189615 |    572.013282 | Gareth Monger                                                                                                                                                                   |
| 160 |    869.522152 |    539.480268 | Collin Gross                                                                                                                                                                    |
| 161 |    509.279425 |    210.025635 | NA                                                                                                                                                                              |
| 162 |    923.160824 |     67.074105 | Michael Scroggie                                                                                                                                                                |
| 163 |    258.123229 |    668.075315 | Matt Crook                                                                                                                                                                      |
| 164 |    764.369014 |    546.103107 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                     |
| 165 |    712.133652 |    696.126118 | Gareth Monger                                                                                                                                                                   |
| 166 |    701.844243 |    456.133090 | NA                                                                                                                                                                              |
| 167 |    237.385722 |    139.425135 | Lily Hughes                                                                                                                                                                     |
| 168 |    581.599013 |    676.172675 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey              |
| 169 |    285.793652 |    338.980763 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 170 |    467.337909 |    613.319982 | Zimices                                                                                                                                                                         |
| 171 |    434.505878 |    623.571764 | Matt Dempsey                                                                                                                                                                    |
| 172 |    289.667425 |    143.818428 | Tasman Dixon                                                                                                                                                                    |
| 173 |    638.013327 |    752.913219 | Jagged Fang Designs                                                                                                                                                             |
| 174 |    300.119919 |    286.122287 | FunkMonk                                                                                                                                                                        |
| 175 |    424.195688 |    553.271212 | Scott Hartman                                                                                                                                                                   |
| 176 |     94.212112 |    788.152550 | Scott Hartman                                                                                                                                                                   |
| 177 |    333.849387 |    376.824062 | Juan Carlos Jerí                                                                                                                                                                |
| 178 |     56.848703 |    561.426748 | Margot Michaud                                                                                                                                                                  |
| 179 |    461.914128 |    734.150289 | Matt Crook                                                                                                                                                                      |
| 180 |    922.700079 |     98.836145 | S.Martini                                                                                                                                                                       |
| 181 |    879.537839 |     75.889394 | Zimices                                                                                                                                                                         |
| 182 |    159.880934 |    733.012853 | Tasman Dixon                                                                                                                                                                    |
| 183 |     97.525124 |    409.580122 | xgirouxb                                                                                                                                                                        |
| 184 |    407.433215 |     15.091584 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 185 |    109.096019 |    358.825646 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                                 |
| 186 |    868.949442 |    201.287125 | NA                                                                                                                                                                              |
| 187 |    583.486437 |     21.394935 | Steven Traver                                                                                                                                                                   |
| 188 |    264.963105 |    644.730023 | Chris huh                                                                                                                                                                       |
| 189 |    129.320514 |    335.880799 | Chuanixn Yu                                                                                                                                                                     |
| 190 |    769.354107 |    380.631364 | Chris huh                                                                                                                                                                       |
| 191 |    574.886573 |    271.841659 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                                   |
| 192 |    427.499451 |    407.110494 | Chris huh                                                                                                                                                                       |
| 193 |     27.240444 |    154.019312 | Oscar Sanisidro                                                                                                                                                                 |
| 194 |    301.792941 |    446.052204 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                                  |
| 195 |    993.064349 |    648.544139 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 196 |    435.044326 |    376.363302 | Margot Michaud                                                                                                                                                                  |
| 197 |    460.599947 |     12.329313 | Matt Crook                                                                                                                                                                      |
| 198 |    556.944927 |    108.379221 | Matt Crook                                                                                                                                                                      |
| 199 |    373.675940 |    504.683809 | Ferran Sayol                                                                                                                                                                    |
| 200 |    780.740465 |    194.928367 | Matt Crook                                                                                                                                                                      |
| 201 |    774.113896 |    475.523595 | Margot Michaud                                                                                                                                                                  |
| 202 |    897.222495 |     43.969152 | Margot Michaud                                                                                                                                                                  |
| 203 |    312.853128 |    515.097514 | Geoff Shaw                                                                                                                                                                      |
| 204 |    317.571348 |    365.302493 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                                    |
| 205 |    490.693677 |    694.284549 | Iain Reid                                                                                                                                                                       |
| 206 |   1010.436317 |    358.505448 | Mariana Ruiz (vectorized by T. Michael Keesey)                                                                                                                                  |
| 207 |    486.563764 |    333.440827 | Tracy A. Heath                                                                                                                                                                  |
| 208 |    814.103439 |    742.364981 | Chris huh                                                                                                                                                                       |
| 209 |    650.115553 |    489.704343 | Margot Michaud                                                                                                                                                                  |
| 210 |    264.691525 |    256.627146 | NASA                                                                                                                                                                            |
| 211 |    413.554293 |    251.034883 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 212 |    768.047081 |    283.388325 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 213 |    967.715840 |    197.729395 | Margot Michaud                                                                                                                                                                  |
| 214 |    901.055122 |    632.295328 | Zimices                                                                                                                                                                         |
| 215 |    995.616651 |    434.435802 | JCGiron                                                                                                                                                                         |
| 216 |    214.879390 |    319.128580 | Matt Crook                                                                                                                                                                      |
| 217 |    820.745722 |    346.454140 | Scott Hartman                                                                                                                                                                   |
| 218 |     16.462437 |    344.464318 | Mali’o Kodis, photograph from Jersabek et al, 2003                                                                                                                              |
| 219 |    600.082399 |    148.781693 | Chris huh                                                                                                                                                                       |
| 220 |    212.200438 |    403.324675 | Margot Michaud                                                                                                                                                                  |
| 221 |    873.685238 |    167.841873 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 222 |    833.795080 |    495.760678 | Jiekun He                                                                                                                                                                       |
| 223 |    617.094739 |    771.778773 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 224 |    587.330846 |    785.247035 | Chloé Schmidt                                                                                                                                                                   |
| 225 |    516.992992 |     19.014197 | Zimices                                                                                                                                                                         |
| 226 |    981.415532 |    614.131174 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                                |
| 227 |    885.280947 |    512.418482 | NA                                                                                                                                                                              |
| 228 |    672.971585 |    166.059019 | Cesar Julian                                                                                                                                                                    |
| 229 |    689.091826 |    368.047692 | Maxime Dahirel                                                                                                                                                                  |
| 230 |    900.726557 |    225.374223 | Maha Ghazal                                                                                                                                                                     |
| 231 |    473.063327 |    273.401779 | Ron Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                                    |
| 232 |    400.277229 |    654.525082 | Collin Gross                                                                                                                                                                    |
| 233 |    585.931281 |    596.996432 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 234 |    418.008923 |    117.494433 | Mathieu Basille                                                                                                                                                                 |
| 235 |    876.778269 |    568.004295 | Noah Schlottman, photo from Casey Dunn                                                                                                                                          |
| 236 |    314.301177 |    325.855974 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                  |
| 237 |    875.685137 |     50.497202 | NA                                                                                                                                                                              |
| 238 |    333.974328 |    143.638036 | Gareth Monger                                                                                                                                                                   |
| 239 |    461.367947 |    354.656385 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                                     |
| 240 |    575.847038 |    762.707052 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                                         |
| 241 |    311.290923 |    493.066805 | Margot Michaud                                                                                                                                                                  |
| 242 |   1007.537484 |    792.927311 | Margot Michaud                                                                                                                                                                  |
| 243 |    136.016935 |    494.589661 | Alex Slavenko                                                                                                                                                                   |
| 244 |   1000.710066 |    306.358055 | Scott Hartman                                                                                                                                                                   |
| 245 |    446.009232 |    471.897847 | Gopal Murali                                                                                                                                                                    |
| 246 |    485.485327 |    111.018968 | L. Shyamal                                                                                                                                                                      |
| 247 |    318.204886 |    607.930954 | Matt Crook                                                                                                                                                                      |
| 248 |    821.028676 |    511.053124 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                                  |
| 249 |    578.872850 |    160.907481 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 250 |    180.153898 |    730.292843 | T. Michael Keesey                                                                                                                                                               |
| 251 |   1002.220692 |     14.913922 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 252 |    250.815645 |    530.422234 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 253 |    675.837855 |    385.797950 | Gareth Monger                                                                                                                                                                   |
| 254 |    340.534936 |    719.735108 | T. Michael Keesey                                                                                                                                                               |
| 255 |    447.551467 |    713.129960 | Chris huh                                                                                                                                                                       |
| 256 |     22.609496 |    778.038154 | Christoph Schomburg                                                                                                                                                             |
| 257 |    827.724882 |    674.967326 | Margot Michaud                                                                                                                                                                  |
| 258 |    428.634423 |     10.051949 | Dmitry Bogdanov                                                                                                                                                                 |
| 259 |    847.129403 |    130.693038 | Gareth Monger                                                                                                                                                                   |
| 260 |    595.023140 |    309.325575 | Rebecca Groom                                                                                                                                                                   |
| 261 |     90.406947 |    325.757304 | NA                                                                                                                                                                              |
| 262 |     49.830505 |    424.226177 | Scott Hartman                                                                                                                                                                   |
| 263 |    667.863009 |    511.550959 | Birgit Lang                                                                                                                                                                     |
| 264 |    179.803614 |    329.823628 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 265 |    786.240976 |     43.719059 | Beth Reinke                                                                                                                                                                     |
| 266 |    451.962407 |     32.132211 | Tasman Dixon                                                                                                                                                                    |
| 267 |     58.474702 |    116.804368 | NA                                                                                                                                                                              |
| 268 |    192.867917 |    226.729611 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                                   |
| 269 |    656.752556 |    451.061555 | Steven Traver                                                                                                                                                                   |
| 270 |    736.303482 |    203.124730 | Jaime Headden                                                                                                                                                                   |
| 271 |    255.182423 |    210.247674 | Chris huh                                                                                                                                                                       |
| 272 |    230.152278 |    276.544289 | Yan Wong                                                                                                                                                                        |
| 273 |     17.353791 |    526.700778 | Cristopher Silva                                                                                                                                                                |
| 274 |    269.930706 |     15.661847 | Sarah Werning                                                                                                                                                                   |
| 275 |    716.132077 |    260.018068 | Kimberly Haddrell                                                                                                                                                               |
| 276 |    997.837194 |    161.603953 | Scott Hartman                                                                                                                                                                   |
| 277 |     97.491567 |    388.801770 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 278 |    146.642031 |     65.061498 | Smokeybjb                                                                                                                                                                       |
| 279 |     68.268567 |    283.513017 | Jagged Fang Designs                                                                                                                                                             |
| 280 |    484.036593 |    734.288911 | Cesar Julian                                                                                                                                                                    |
| 281 |    246.633132 |    622.137240 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                                        |
| 282 |    556.857583 |    546.235749 | (after Spotila 2004)                                                                                                                                                            |
| 283 |    619.995005 |    614.779135 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                                |
| 284 |    753.586415 |    793.237858 | NA                                                                                                                                                                              |
| 285 |    822.453989 |    659.529057 | Zimices                                                                                                                                                                         |
| 286 |    150.062163 |    601.195507 | Gareth Monger                                                                                                                                                                   |
| 287 |    113.000017 |    458.942820 | T. Michael Keesey                                                                                                                                                               |
| 288 |    196.359571 |    117.668720 | Dean Schnabel                                                                                                                                                                   |
| 289 |    471.708721 |    251.762009 | Birgit Lang                                                                                                                                                                     |
| 290 |    341.278264 |     14.363062 | Scott Hartman                                                                                                                                                                   |
| 291 |    503.219170 |    659.448542 | Kai R. Caspar                                                                                                                                                                   |
| 292 |    948.467893 |    784.187700 | Chris Jennings (vectorized by A. Verrière)                                                                                                                                      |
| 293 |    207.982949 |    420.582352 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                                             |
| 294 |    780.060479 |    427.046449 | Zimices                                                                                                                                                                         |
| 295 |    436.306246 |    529.550358 | M Kolmann                                                                                                                                                                       |
| 296 |     73.891973 |     77.985116 | Steven Traver                                                                                                                                                                   |
| 297 |     67.850664 |    614.665511 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 298 |    790.344548 |    511.318366 | Ferran Sayol                                                                                                                                                                    |
| 299 |    489.293136 |    160.732699 | Steven Traver                                                                                                                                                                   |
| 300 |     92.562037 |    379.181079 | Yan Wong                                                                                                                                                                        |
| 301 |    659.961814 |    723.416928 | Scott Hartman                                                                                                                                                                   |
| 302 |    213.930268 |    718.806544 | Jagged Fang Designs                                                                                                                                                             |
| 303 |    576.915183 |    650.220632 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 304 |    198.436051 |     15.939206 | Chuanixn Yu                                                                                                                                                                     |
| 305 |    448.195712 |    133.397880 | Nobu Tamura, vectorized by Zimices                                                                                                                                              |
| 306 |    990.757034 |    380.990835 | Steven Traver                                                                                                                                                                   |
| 307 |    911.406942 |    753.214123 | NA                                                                                                                                                                              |
| 308 |    407.627266 |    629.215695 | Scott Hartman                                                                                                                                                                   |
| 309 |    376.520583 |    425.535711 | Margot Michaud                                                                                                                                                                  |
| 310 |    599.419369 |    485.378931 | Chris huh                                                                                                                                                                       |
| 311 |    549.785351 |    206.861323 | Steven Coombs                                                                                                                                                                   |
| 312 |    554.364983 |    308.031504 | Beth Reinke                                                                                                                                                                     |
| 313 |    866.359319 |    736.619655 | T. Michael Keesey                                                                                                                                                               |
| 314 |    618.200494 |    404.341997 | Gareth Monger                                                                                                                                                                   |
| 315 |    595.201479 |    559.082401 | Manabu Sakamoto                                                                                                                                                                 |
| 316 |    122.802685 |     22.349614 | Zimices                                                                                                                                                                         |
| 317 |    520.152594 |    407.972449 | FunkMonk (Michael B. H.)                                                                                                                                                        |
| 318 |    667.136972 |    400.121109 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 319 |    915.544840 |     15.458765 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                |
| 320 |    957.269188 |    181.751546 | Margot Michaud                                                                                                                                                                  |
| 321 |    411.073617 |    790.498156 | Ferran Sayol                                                                                                                                                                    |
| 322 |    664.840766 |    709.914812 | Jagged Fang Designs                                                                                                                                                             |
| 323 |    650.499461 |    291.313454 | Margot Michaud                                                                                                                                                                  |
| 324 |    625.991637 |    732.703781 | Margot Michaud                                                                                                                                                                  |
| 325 |    292.670706 |    158.897291 | T. Michael Keesey (after Tillyard)                                                                                                                                              |
| 326 |    826.251093 |    330.088643 | Matt Crook                                                                                                                                                                      |
| 327 |    565.884507 |    490.432519 | Michelle Site                                                                                                                                                                   |
| 328 |   1005.143508 |     81.934611 | Liftarn                                                                                                                                                                         |
| 329 |    587.616563 |     94.914665 | Shyamal                                                                                                                                                                         |
| 330 |    482.876788 |    746.571436 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                                   |
| 331 |    764.931792 |    600.340921 | Matt Crook                                                                                                                                                                      |
| 332 |    736.583961 |    599.096464 | Scott Hartman                                                                                                                                                                   |
| 333 |    545.333057 |    663.348605 | Josefine Bohr Brask                                                                                                                                                             |
| 334 |    332.392376 |    784.952963 | Ferran Sayol                                                                                                                                                                    |
| 335 |    154.343731 |     16.017034 | Becky Barnes                                                                                                                                                                    |
| 336 |    897.835628 |    384.710310 | Chris huh                                                                                                                                                                       |
| 337 |     20.896925 |    748.641113 | Margot Michaud                                                                                                                                                                  |
| 338 |    457.547992 |    106.461545 | Dean Schnabel                                                                                                                                                                   |
| 339 |     25.264804 |    382.393715 | Zimices                                                                                                                                                                         |
| 340 |    774.269432 |    646.376075 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                     |
| 341 |    583.794406 |    539.885206 | T. Michael Keesey                                                                                                                                                               |
| 342 |    376.457861 |     11.143967 | Milton Tan                                                                                                                                                                      |
| 343 |    314.165115 |    737.320899 | Steven Coombs                                                                                                                                                                   |
| 344 |    864.530869 |    313.214818 | Sarah Werning                                                                                                                                                                   |
| 345 |     54.933241 |    542.159374 | Smokeybjb                                                                                                                                                                       |
| 346 |    633.518274 |    638.198042 | Tasman Dixon                                                                                                                                                                    |
| 347 |    751.853707 |     60.221605 | Margot Michaud                                                                                                                                                                  |
| 348 |    871.941452 |    241.513326 | Zimices                                                                                                                                                                         |
| 349 |     72.692194 |     62.641584 | Milton Tan                                                                                                                                                                      |
| 350 |    263.161364 |    485.488505 | Siobhon Egan                                                                                                                                                                    |
| 351 |    768.634625 |    665.921346 | Craig Dylke                                                                                                                                                                     |
| 352 |    411.954995 |    418.744332 | Jagged Fang Designs                                                                                                                                                             |
| 353 |    685.637183 |    336.106764 | SauropodomorphMonarch                                                                                                                                                           |
| 354 |     95.158885 |    293.645755 | Inessa Voet                                                                                                                                                                     |
| 355 |    347.715002 |    326.567046 | Margot Michaud                                                                                                                                                                  |
| 356 |    972.383548 |     22.411469 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                     |
| 357 |    411.139394 |    557.767803 | Iain Reid                                                                                                                                                                       |
| 358 |    623.442581 |    158.487139 | Lisa Byrne                                                                                                                                                                      |
| 359 |    911.307167 |    646.216886 | Christopher Chávez                                                                                                                                                              |
| 360 |    474.273511 |    428.001782 | Matt Crook                                                                                                                                                                      |
| 361 |    705.653500 |    516.174356 | Margot Michaud                                                                                                                                                                  |
| 362 |    194.109863 |    167.001018 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                                   |
| 363 |    265.214502 |    602.399708 | Martin R. Smith                                                                                                                                                                 |
| 364 |     59.425230 |     92.038803 | Margot Michaud                                                                                                                                                                  |
| 365 |    651.016771 |    701.622569 | Matt Crook                                                                                                                                                                      |
| 366 |    683.733380 |    303.704707 | Jaime Headden                                                                                                                                                                   |
| 367 |    605.538644 |    466.136861 | John Gould (vectorized by T. Michael Keesey)                                                                                                                                    |
| 368 |     46.451391 |    291.206059 | Noah Schlottman, photo by Antonio Guillén                                                                                                                                       |
| 369 |    461.982838 |    528.379378 | Zimices                                                                                                                                                                         |
| 370 |    934.901182 |    204.199545 | Jagged Fang Designs                                                                                                                                                             |
| 371 |    863.366059 |    152.457210 | Steven Traver                                                                                                                                                                   |
| 372 |     17.858452 |    489.656395 | Melissa Broussard                                                                                                                                                               |
| 373 |    739.813503 |    641.041759 | Chris huh                                                                                                                                                                       |
| 374 |    810.145088 |    712.065034 | Michelle Site                                                                                                                                                                   |
| 375 |    433.848184 |    569.489707 | Harold N Eyster                                                                                                                                                                 |
| 376 |    937.894287 |    212.044770 | Nobu Tamura                                                                                                                                                                     |
| 377 |    537.879417 |    675.096788 | CNZdenek                                                                                                                                                                        |
| 378 |    276.741592 |    510.344340 | Emily Willoughby                                                                                                                                                                |
| 379 |    175.370508 |    495.470747 | Ferran Sayol                                                                                                                                                                    |
| 380 |    160.656386 |    199.253582 | NA                                                                                                                                                                              |
| 381 |   1013.507847 |    268.133371 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                                     |
| 382 |    326.772195 |    572.189406 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                              |
| 383 |    619.927733 |    701.647998 | Carlos Cano-Barbacil                                                                                                                                                            |
| 384 |    546.568999 |    479.250373 | Gareth Monger                                                                                                                                                                   |
| 385 |    170.509904 |    753.589935 | RS                                                                                                                                                                              |
| 386 |    720.732856 |    113.256372 | Tambja (vectorized by T. Michael Keesey)                                                                                                                                        |
| 387 |    986.151724 |    493.152290 | Dean Schnabel                                                                                                                                                                   |
| 388 |    610.909862 |      5.431111 | Chris huh                                                                                                                                                                       |
| 389 |    726.447961 |    177.328967 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                                  |
| 390 |    714.835194 |    530.593642 | T. Michael Keesey (after James & al.)                                                                                                                                           |
| 391 |    850.027471 |    382.192206 | SecretJellyMan                                                                                                                                                                  |
| 392 |    680.842006 |    450.537557 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                                                                  |
| 393 |     33.580379 |    427.946372 |                                                                                                                                                                                 |
| 394 |    681.869823 |     97.638802 | T. Michael Keesey                                                                                                                                                               |
| 395 |    725.783958 |    591.542602 | Scott Hartman                                                                                                                                                                   |
| 396 |    418.790671 |    267.567562 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                                  |
| 397 |    787.315482 |    161.793239 | Oscar Sanisidro                                                                                                                                                                 |
| 398 |    335.493358 |    257.166475 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                                |
| 399 |   1008.431397 |    769.670015 | Alexandre Vong                                                                                                                                                                  |
| 400 |    296.803684 |    429.955881 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                              |
| 401 |    417.355444 |    703.516119 | Margret Flinsch, vectorized by Zimices                                                                                                                                          |
| 402 |     32.099538 |    676.191029 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                            |
| 403 |     72.861797 |    431.564550 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                               |
| 404 |    810.280504 |     87.175944 | Smokeybjb                                                                                                                                                                       |
| 405 |     29.288794 |    409.878812 | Rebecca Groom                                                                                                                                                                   |
| 406 |     58.169223 |    792.385020 | Tyler Greenfield                                                                                                                                                                |
| 407 |    406.874321 |    687.568204 | Ingo Braasch                                                                                                                                                                    |
| 408 |    255.924845 |     44.505145 | Margot Michaud                                                                                                                                                                  |
| 409 |    540.047812 |    494.426104 | Chris huh                                                                                                                                                                       |
| 410 |    950.429627 |     93.073617 | Gareth Monger                                                                                                                                                                   |
| 411 |    436.062620 |    756.936855 | Zimices                                                                                                                                                                         |
| 412 |   1006.615144 |    230.078642 | Conty (vectorized by T. Michael Keesey)                                                                                                                                         |
| 413 |    239.322316 |    728.041368 | B. Duygu Özpolat                                                                                                                                                                |
| 414 |    483.255696 |    792.443427 | Chris huh                                                                                                                                                                       |
| 415 |     15.295187 |    284.707436 | Margot Michaud                                                                                                                                                                  |
| 416 |    188.700008 |    344.978313 | Steven Coombs                                                                                                                                                                   |
| 417 |    742.662548 |    396.375752 | Mario Quevedo                                                                                                                                                                   |
| 418 |    160.894409 |      3.494306 | Margot Michaud                                                                                                                                                                  |
| 419 |     23.658691 |    546.022731 | NA                                                                                                                                                                              |
| 420 |    516.031791 |    786.953308 | Chris huh                                                                                                                                                                       |
| 421 |    834.629516 |    450.122923 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 422 |    969.776379 |    373.742848 | Mason McNair                                                                                                                                                                    |
| 423 |    356.565513 |    290.775853 | Matt Martyniuk                                                                                                                                                                  |
| 424 |    384.914281 |    673.012026 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                                         |
| 425 |    898.755634 |    608.582626 | Shyamal                                                                                                                                                                         |
| 426 |    486.996677 |    352.490287 | NA                                                                                                                                                                              |
| 427 |     97.085109 |    200.141508 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                   |
| 428 |    505.692827 |    301.405031 | Ferran Sayol                                                                                                                                                                    |
| 429 |    441.551818 |    417.038740 | Pete Buchholz                                                                                                                                                                   |
| 430 |     16.212676 |    441.061715 | Michelle Site                                                                                                                                                                   |
| 431 |    392.748472 |    361.669485 | Nobu Tamura                                                                                                                                                                     |
| 432 |     55.181913 |    151.720765 | Zimices                                                                                                                                                                         |
| 433 |    591.352017 |    742.641481 | Scott Hartman                                                                                                                                                                   |
| 434 |    446.430925 |    331.689494 | Gareth Monger                                                                                                                                                                   |
| 435 |    242.475771 |    578.864961 | Jagged Fang Designs                                                                                                                                                             |
| 436 |    253.046532 |    438.634345 | Jagged Fang Designs                                                                                                                                                             |
| 437 |    111.723036 |    594.312690 | Henry Lydecker                                                                                                                                                                  |
| 438 |    150.274585 |    474.635322 | Xavier Giroux-Bougard                                                                                                                                                           |
| 439 |    967.762341 |    298.733319 | Kent Elson Sorgon                                                                                                                                                               |
| 440 |    576.554804 |     60.047974 | Gabriela Palomo-Munoz                                                                                                                                                           |
| 441 |    179.536718 |    603.137398 | Jagged Fang Designs                                                                                                                                                             |
| 442 |    763.678454 |    560.702489 | Chris huh                                                                                                                                                                       |
| 443 |    945.904945 |    664.796811 | Chris huh                                                                                                                                                                       |
| 444 |    253.829248 |    719.024506 | NA                                                                                                                                                                              |
| 445 |    836.521480 |    137.016229 | Scott Hartman                                                                                                                                                                   |
| 446 |    973.657694 |    782.345846 | Kai R. Caspar                                                                                                                                                                   |
| 447 |    995.422247 |    172.353100 | Maija Karala                                                                                                                                                                    |
| 448 |    561.805651 |    148.040208 | Margot Michaud                                                                                                                                                                  |
| 449 |    827.459788 |    377.921461 | Dean Schnabel                                                                                                                                                                   |
| 450 |    742.608213 |    462.768440 | Beth Reinke                                                                                                                                                                     |
| 451 |    134.137486 |    787.093432 | Zimices                                                                                                                                                                         |
| 452 |    868.588076 |    300.908745 | Lafage                                                                                                                                                                          |
| 453 |     97.851301 |    400.526893 | Steven Traver                                                                                                                                                                   |
| 454 |    813.777288 |    268.489562 | Ferran Sayol                                                                                                                                                                    |
| 455 |    991.446684 |    594.375878 | Hans Hillewaert (photo) and T. Michael Keesey (vectorization)                                                                                                                   |
| 456 |     96.099827 |    347.853255 | Kailah Thorn & Mark Hutchinson                                                                                                                                                  |
| 457 |   1007.573993 |    407.913850 | Auckland Museum and T. Michael Keesey                                                                                                                                           |
| 458 |    316.554498 |    473.068289 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 459 |    878.495311 |    492.129116 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                                   |
| 460 |    881.399310 |    528.566445 | \<U+0414\>\<U+0438\>\<U+0411\>\<U+0433\>\<U+0434\> (vectorized by T. Michael Keesey)                                                                                            |
| 461 |    460.134574 |    391.751801 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                  |
| 462 |    373.075651 |    379.664994 | Geoff Shaw                                                                                                                                                                      |
| 463 |    760.058897 |    181.114274 | Gareth Monger                                                                                                                                                                   |
| 464 |    786.446600 |    210.543798 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                   |
| 465 |    398.482074 |    375.364814 | Sarah Werning                                                                                                                                                                   |
| 466 |    816.115984 |    118.082131 | T. Michael Keesey                                                                                                                                                               |
| 467 |    521.206780 |    266.636572 | Zimices                                                                                                                                                                         |
| 468 |    761.584553 |     42.562678 | Michelle Site                                                                                                                                                                   |
| 469 |    273.399162 |    218.643605 | Gareth Monger                                                                                                                                                                   |
| 470 |    862.379340 |    186.334743 | Matt Crook                                                                                                                                                                      |
| 471 |    697.691194 |      7.596943 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                                  |
| 472 |     32.848217 |    621.457989 | Juan Carlos Jerí                                                                                                                                                                |
| 473 |    462.576812 |    293.584687 | NA                                                                                                                                                                              |
| 474 |    268.593705 |    760.572896 | Jagged Fang Designs                                                                                                                                                             |
| 475 |    622.713876 |     21.503722 | nicubunu                                                                                                                                                                        |
| 476 |    996.996744 |    633.609425 | Tasman Dixon                                                                                                                                                                    |
| 477 |     89.684577 |    422.455008 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                                           |
| 478 |    769.125176 |     62.495573 | Chris huh                                                                                                                                                                       |
| 479 |    233.442266 |    236.900887 | Steven Traver                                                                                                                                                                   |
| 480 |    777.393625 |    520.659444 | Steven Haddock • Jellywatch.org                                                                                                                                                 |
| 481 |    570.608488 |    480.944713 | Jagged Fang Designs                                                                                                                                                             |
| 482 |    618.971375 |     99.382369 | Alexandre Vong                                                                                                                                                                  |
| 483 |    834.586600 |    470.514058 | Gareth Monger                                                                                                                                                                   |
| 484 |     28.781700 |    325.693597 | Milton Tan                                                                                                                                                                      |
| 485 |    316.678992 |    694.618241 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                               |
| 486 |    627.794003 |    499.167600 | T. Michael Keesey                                                                                                                                                               |
| 487 |    484.812540 |    627.398723 | C. Camilo Julián-Caballero                                                                                                                                                      |
| 488 |    309.407436 |    100.681642 | Jagged Fang Designs                                                                                                                                                             |
| 489 |   1003.023105 |    566.241553 | Sarah Werning                                                                                                                                                                   |
| 490 |    324.944132 |     21.259851 | Blanco et al., 2014, vectorized by Zimices                                                                                                                                      |
| 491 |    582.225483 |    532.297025 | Jagged Fang Designs                                                                                                                                                             |
| 492 |    112.851252 |    794.070953 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                                   |
| 493 |    818.662113 |    758.641122 | Javier Luque                                                                                                                                                                    |
| 494 |    324.635733 |    107.495313 | Kent Elson Sorgon                                                                                                                                                               |
| 495 |      7.245267 |    712.019229 | Dean Schnabel                                                                                                                                                                   |
| 496 |    151.293620 |    230.802402 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                                                 |
| 497 |    587.786070 |    244.692087 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                     |
| 498 |    357.568769 |    130.686988 | Felix Vaux                                                                                                                                                                      |
| 499 |    409.433006 |    525.876824 | Margot Michaud                                                                                                                                                                  |
| 500 |    236.670048 |    760.354641 | Bennet McComish, photo by Hans Hillewaert                                                                                                                                       |
| 501 |     21.821661 |     23.398722 | Birgit Lang                                                                                                                                                                     |
| 502 |    141.209564 |    208.489080 | Chris huh                                                                                                                                                                       |
| 503 |    267.700644 |     75.392348 | Gareth Monger                                                                                                                                                                   |
| 504 |    874.935732 |     23.527750 | Ferran Sayol                                                                                                                                                                    |
| 505 |    311.967628 |     12.012582 | NA                                                                                                                                                                              |
| 506 |    904.288417 |     66.263517 | Rachel Shoop                                                                                                                                                                    |
| 507 |    447.222651 |    630.570630 | Caleb M. Brown                                                                                                                                                                  |
| 508 |    813.721323 |     39.908178 | NASA                                                                                                                                                                            |
| 509 |    650.977022 |    246.685170 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                  |
| 510 |    102.803554 |    520.242579 | Margot Michaud                                                                                                                                                                  |
| 511 |    465.478110 |    150.421198 | CNZdenek                                                                                                                                                                        |
| 512 |    209.622577 |    475.931860 | Maija Karala                                                                                                                                                                    |
| 513 |    689.768444 |    196.790909 | Gareth Monger                                                                                                                                                                   |
| 514 |     28.571814 |    199.159009 | Scott Hartman                                                                                                                                                                   |
| 515 |    524.664681 |    535.006887 | Jagged Fang Designs                                                                                                                                                             |
| 516 |    762.306962 |    763.654960 | Milton Tan                                                                                                                                                                      |

    #> Your tweet has been posted!
