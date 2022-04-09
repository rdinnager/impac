
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

Steven Traver, Zimices, Andy Wilson, Andrew A. Farke, Nobu Tamura
(vectorized by T. Michael Keesey), Markus A. Grohme, T. Michael Keesey,
Jagged Fang Designs, Gareth Monger, Nancy Wyman (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Chris huh, Noah
Schlottman, photo by Casey Dunn, Aviceda (vectorized by T. Michael
Keesey), Dmitry Bogdanov (vectorized by T. Michael Keesey), Didier
Descouens (vectorized by T. Michael Keesey), Margot Michaud, Matt Crook,
Mali’o Kodis, photograph by Bruno Vellutini, Sarah Werning, Collin
Gross, Manabu Bessho-Uehara, xgirouxb, Joanna Wolfe, Scott Hartman, M.
A. Broussard, Mali’o Kodis, photograph by G. Giribet, Meyer-Wachsmuth I,
Curini Galletti M, Jondelius U (<doi:10.1371/journal.pone.0107688>).
Vectorization by Y. Wong, Alexander Schmidt-Lebuhn, Mo Hassan, Kai R.
Caspar, Gabriela Palomo-Munoz, Trond R. Oskars, Chloé Schmidt, Birgit
Lang, Katie S. Collins, Smokeybjb (modified by Mike Keesey), Dean
Schnabel, Kamil S. Jaron, L. Shyamal, kotik, Jaime Headden, James
Neenan, Caleb M. Brown, Beth Reinke, Ignacio Contreras, Henry Lydecker,
Stephen O’Connor (vectorized by T. Michael Keesey), Christoph Schomburg,
Alex Slavenko, Sergio A. Muñoz-Gómez, Matt Celeskey, Ghedoghedo
(vectorized by T. Michael Keesey), Lukasiniho, Michelle Site, Ferran
Sayol, Iain Reid, Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall,
Sharon Wegner-Larsen, Nobu Tamura, vectorized by Zimices, Marie-Aimée
Allard, Rebecca Groom, Cesar Julian, Crystal Maier, C. Camilo
Julián-Caballero, Sherman F. Denton via rawpixel.com (illustration) and
Timothy J. Bartley (silhouette), Mali’o Kodis, photograph by Derek Keats
(<http://www.flickr.com/photos/dkeats/>), Mike Hanson, Darren Naish
(vectorize by T. Michael Keesey), Ernst Haeckel (vectorized by T.
Michael Keesey), Dmitry Bogdanov, Jack Mayer Wood, Harold N Eyster, John
Curtis (vectorized by T. Michael Keesey), Stacy Spensley (Modified),
Stanton F. Fink, vectorized by Zimices, Jimmy Bernot, Maija Karala,
Inessa Voet, Tasman Dixon, T. Michael Keesey (photo by Darren Swim), Jon
Hill, Mathew Wedel, Yan Wong, Leon P. A. M. Claessens, Patrick M.
O’Connor, David M. Unwin, Renato de Carvalho Ferreira, Michael P.
Taylor, Antonov (vectorized by T. Michael Keesey), Sherman Foote Denton
(illustration, 1897) and Timothy J. Bartley (silhouette), Noah
Schlottman, Christian A. Masnaghetti, Mali’o Kodis, image by Rebecca
Ritger, Steven Haddock • Jellywatch.org, Donovan Reginald Rosevear
(vectorized by T. Michael Keesey), Lafage, Maxime Dahirel, Natasha
Vitek, Milton Tan, Bill Bouton (source photo) & T. Michael Keesey
(vectorization), Joe Schneid (vectorized by T. Michael Keesey), Ingo
Braasch, Kanako Bessho-Uehara, Martin Kevil, CNZdenek, Dave Angelini,
Tyler Greenfield, John Conway, zoosnow, Matt Martyniuk, Scott D.
Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A.
Forster, Joshua A. Smith, Alan L. Titus, Tony Ayling (vectorized by T.
Michael Keesey), Nobu Tamura (modified by T. Michael Keesey), Emily
Willoughby, Haplochromis (vectorized by T. Michael Keesey), Mali’o
Kodis, photograph from
<http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>, Tod Robbins,
Auckland Museum and T. Michael Keesey, Meliponicultor Itaymbere, Darius
Nau, Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette),
Michael Ströck (vectorized by T. Michael Keesey), Walter Vladimir, Oscar
Sanisidro, Smokeybjb, Mali’o Kodis, image from the Smithsonian
Institution, ArtFavor & annaleeblysse, Michael Scroggie, Roberto Díaz
Sibaja, Christopher Watson (photo) and T. Michael Keesey
(vectorization), FunkMonk, Smokeybjb (modified by T. Michael Keesey),
Riccardo Percudani, Emil Schmidt (vectorized by Maxime Dahirel),
Jakovche, Fernando Carezzano, Brian Gratwicke (photo) and T. Michael
Keesey (vectorization), Kristina Gagalova, M. Antonio Todaro, Tobias
Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael
Keesey), Pranav Iyer (grey ideas), Ghedoghedo, vectorized by Zimices,
FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey), David Sim
(photograph) and T. Michael Keesey (vectorization), Ryan Cupo, James R.
Spotila and Ray Chatterji, Sean McCann, Shyamal, T. Tischler, Andrew
Farke and Joseph Sertich, Konsta Happonen, from a CC-BY-NC image by
pelhonen on iNaturalist, Nobu Tamura, M Kolmann, Matt Dempsey, Jan A.
Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized
by T. Michael Keesey), Dori <dori@merr.info> (source photo) and Nevit
Dilmen, Gopal Murali, Ricardo N. Martinez & Oscar A. Alcober, Felix
Vaux, Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Alyssa Bell & Luis Chiappe 2015,
dx.doi.org/10.1371/journal.pone.0141690, SauropodomorphMonarch, Geoff
Shaw, Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael
Keesey., Mali’o Kodis, image from Brockhaus and Efron Encyclopedic
Dictionary, Neil Kelley, Siobhon Egan, Arthur S. Brum, david maas / dave
hone, Carlos Cano-Barbacil, Taenadoman, Moussa Direct Ltd. (photography)
and T. Michael Keesey (vectorization), Darren Naish (vectorized by T.
Michael Keesey), Young and Zhao (1972:figure 4), modified by Michael P.
Taylor, Robert Gay, modifed from Olegivvit, Owen Jones (derived from a
CC-BY 2.0 photograph by Paulo B. Chaves), T. K. Robinson, Noah
Schlottman, photo from Casey Dunn, Melissa Broussard, Scott Hartman,
modified by T. Michael Keesey, Juan Carlos Jerí, Dave Souza (vectorized
by T. Michael Keesey), Apokryltaros (vectorized by T. Michael Keesey),
Bruno Maggia, Zsoldos Márton (vectorized by T. Michael Keesey), Danny
Cicchetti (vectorized by T. Michael Keesey), Robbie N. Cada (vectorized
by T. Michael Keesey), E. Lear, 1819 (vectorization by Yan Wong), Mali’o
Kodis, photograph by P. Funch and R.M. Kristensen, David Orr, Lily
Hughes, U.S. Fish and Wildlife Service (illustration) and Timothy J.
Bartley (silhouette)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                      |
| --: | ------------: | ------------: | :---------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    653.251219 |    705.495732 | Steven Traver                                                                                                                                               |
|   2 |    306.886042 |     57.492252 | Zimices                                                                                                                                                     |
|   3 |    231.037300 |    613.881698 | Andy Wilson                                                                                                                                                 |
|   4 |    446.602760 |    514.170988 | Andrew A. Farke                                                                                                                                             |
|   5 |    941.227492 |    381.145697 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
|   6 |    776.702227 |    142.547216 | Markus A. Grohme                                                                                                                                            |
|   7 |    202.398960 |    140.775038 | T. Michael Keesey                                                                                                                                           |
|   8 |    778.551948 |    509.919456 | Jagged Fang Designs                                                                                                                                         |
|   9 |    199.270623 |    723.908464 | Gareth Monger                                                                                                                                               |
|  10 |    699.695110 |    476.924607 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
|  11 |    158.174074 |    459.934047 | Chris huh                                                                                                                                                   |
|  12 |    850.174726 |     32.132517 | Noah Schlottman, photo by Casey Dunn                                                                                                                        |
|  13 |    130.509133 |    320.497370 | Jagged Fang Designs                                                                                                                                         |
|  14 |    192.189167 |    375.141371 | Aviceda (vectorized by T. Michael Keesey)                                                                                                                   |
|  15 |    771.489455 |    233.305083 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
|  16 |    527.220666 |    374.005702 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                          |
|  17 |    904.278939 |    542.344254 | Zimices                                                                                                                                                     |
|  18 |    646.485025 |    618.663540 | Margot Michaud                                                                                                                                              |
|  19 |    496.467022 |    287.607454 | Matt Crook                                                                                                                                                  |
|  20 |    947.651050 |    687.745693 | Matt Crook                                                                                                                                                  |
|  21 |    963.753224 |    134.843042 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                 |
|  22 |     68.887988 |    715.791111 | Sarah Werning                                                                                                                                               |
|  23 |    317.196897 |    416.749646 | Andy Wilson                                                                                                                                                 |
|  24 |    392.443963 |    721.363941 | Chris huh                                                                                                                                                   |
|  25 |    521.009867 |    644.285084 | Collin Gross                                                                                                                                                |
|  26 |    894.382722 |    280.508134 | Manabu Bessho-Uehara                                                                                                                                        |
|  27 |    572.822896 |     94.067580 | xgirouxb                                                                                                                                                    |
|  28 |    676.891899 |    317.955322 | Joanna Wolfe                                                                                                                                                |
|  29 |    895.615320 |    601.370077 | Scott Hartman                                                                                                                                               |
|  30 |    777.408983 |    732.789862 | M. A. Broussard                                                                                                                                             |
|  31 |    301.928345 |    284.149668 | Mali’o Kodis, photograph by G. Giribet                                                                                                                      |
|  32 |    635.327140 |    176.582818 | Steven Traver                                                                                                                                               |
|  33 |    607.417731 |    283.677634 | Meyer-Wachsmuth I, Curini Galletti M, Jondelius U (<doi:10.1371/journal.pone.0107688>). Vectorization by Y. Wong                                            |
|  34 |    850.996063 |    400.541081 | Alexander Schmidt-Lebuhn                                                                                                                                    |
|  35 |    593.742325 |    481.989783 | Chris huh                                                                                                                                                   |
|  36 |    795.585874 |    342.106504 | Scott Hartman                                                                                                                                               |
|  37 |    726.314332 |     62.623713 | Mo Hassan                                                                                                                                                   |
|  38 |    401.348115 |    191.660995 | Kai R. Caspar                                                                                                                                               |
|  39 |     94.519527 |    193.882198 | Gabriela Palomo-Munoz                                                                                                                                       |
|  40 |    808.876976 |    625.516913 | Trond R. Oskars                                                                                                                                             |
|  41 |    483.128894 |    170.135156 | Chloé Schmidt                                                                                                                                               |
|  42 |    346.014871 |    571.169566 | Birgit Lang                                                                                                                                                 |
|  43 |    431.862712 |    760.777656 | Katie S. Collins                                                                                                                                            |
|  44 |    494.381562 |    569.210280 | Andy Wilson                                                                                                                                                 |
|  45 |     87.500493 |    562.352824 | NA                                                                                                                                                          |
|  46 |    883.723469 |    459.550144 | Margot Michaud                                                                                                                                              |
|  47 |    533.885286 |    447.347480 | Smokeybjb (modified by Mike Keesey)                                                                                                                         |
|  48 |    390.356907 |    686.173355 | Margot Michaud                                                                                                                                              |
|  49 |    905.733477 |    248.915758 | Margot Michaud                                                                                                                                              |
|  50 |    245.566106 |    514.901252 | Dean Schnabel                                                                                                                                               |
|  51 |    115.985102 |     25.850330 | Scott Hartman                                                                                                                                               |
|  52 |     84.667500 |     81.354859 | Kamil S. Jaron                                                                                                                                              |
|  53 |     53.828351 |    340.934924 | L. Shyamal                                                                                                                                                  |
|  54 |    314.081330 |    632.791226 | Chris huh                                                                                                                                                   |
|  55 |    682.840182 |    372.186376 | Andy Wilson                                                                                                                                                 |
|  56 |    900.688084 |     69.239755 | Zimices                                                                                                                                                     |
|  57 |    442.543684 |     64.251563 | T. Michael Keesey                                                                                                                                           |
|  58 |    368.571047 |    273.478874 | kotik                                                                                                                                                       |
|  59 |    427.109536 |    413.453539 | Andy Wilson                                                                                                                                                 |
|  60 |    883.454175 |    749.401305 | Gareth Monger                                                                                                                                               |
|  61 |    622.262272 |    768.543236 | Chris huh                                                                                                                                                   |
|  62 |    406.842809 |    349.942005 | Jaime Headden                                                                                                                                               |
|  63 |    139.389938 |    274.956206 | James Neenan                                                                                                                                                |
|  64 |    196.029449 |    774.391728 | NA                                                                                                                                                          |
|  65 |     63.254041 |    416.774823 | Gabriela Palomo-Munoz                                                                                                                                       |
|  66 |    314.090196 |    168.672396 | Caleb M. Brown                                                                                                                                              |
|  67 |    607.687844 |    514.544379 | Beth Reinke                                                                                                                                                 |
|  68 |    285.205430 |    420.330616 | NA                                                                                                                                                          |
|  69 |    866.887208 |    116.028937 | Scott Hartman                                                                                                                                               |
|  70 |    629.468947 |    408.270323 | Ignacio Contreras                                                                                                                                           |
|  71 |    182.503911 |    672.379761 | NA                                                                                                                                                          |
|  72 |    956.984340 |    217.774429 | Alexander Schmidt-Lebuhn                                                                                                                                    |
|  73 |    612.299845 |    553.273558 | Chris huh                                                                                                                                                   |
|  74 |    705.755162 |    678.850325 | Henry Lydecker                                                                                                                                              |
|  75 |    929.414388 |    322.532831 | Markus A. Grohme                                                                                                                                            |
|  76 |    993.496807 |    148.800953 | T. Michael Keesey                                                                                                                                           |
|  77 |    783.755870 |    544.010997 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                          |
|  78 |    849.847274 |    191.295166 | Christoph Schomburg                                                                                                                                         |
|  79 |    462.270100 |    669.739266 | Alex Slavenko                                                                                                                                               |
|  80 |    528.029644 |    761.630941 | Gareth Monger                                                                                                                                               |
|  81 |    424.587347 |    614.121797 | Jagged Fang Designs                                                                                                                                         |
|  82 |    931.459705 |     15.122546 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
|  83 |    223.511428 |    578.988316 | Jagged Fang Designs                                                                                                                                         |
|  84 |    379.800786 |     89.037650 | Sergio A. Muñoz-Gómez                                                                                                                                       |
|  85 |    986.002694 |    287.123394 | Matt Celeskey                                                                                                                                               |
|  86 |    992.871273 |    557.384729 | Jagged Fang Designs                                                                                                                                         |
|  87 |    750.307601 |    398.900478 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                |
|  88 |     25.186757 |    229.577439 | Lukasiniho                                                                                                                                                  |
|  89 |    443.273809 |    246.949278 | Margot Michaud                                                                                                                                              |
|  90 |    888.898229 |    649.671752 | Andy Wilson                                                                                                                                                 |
|  91 |    559.777947 |    606.506157 | Zimices                                                                                                                                                     |
|  92 |    135.393264 |    131.221585 | Margot Michaud                                                                                                                                              |
|  93 |     33.909719 |     22.349103 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
|  94 |    950.599692 |    359.645791 | Michelle Site                                                                                                                                               |
|  95 |    595.064639 |     45.104693 | Christoph Schomburg                                                                                                                                         |
|  96 |    556.687581 |    209.146417 | Margot Michaud                                                                                                                                              |
|  97 |    756.651432 |    268.853457 | Scott Hartman                                                                                                                                               |
|  98 |    151.199816 |    518.860105 | L. Shyamal                                                                                                                                                  |
|  99 |    865.862311 |    379.737436 | Scott Hartman                                                                                                                                               |
| 100 |    843.457478 |    766.979901 | NA                                                                                                                                                          |
| 101 |    802.406311 |    299.720835 | Chris huh                                                                                                                                                   |
| 102 |    974.343478 |    599.455098 | Ferran Sayol                                                                                                                                                |
| 103 |    787.087987 |      9.587502 | Iain Reid                                                                                                                                                   |
| 104 |    693.954932 |    264.992304 | Zimices                                                                                                                                                     |
| 105 |    331.488449 |    776.478370 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                       |
| 106 |     59.938412 |    769.316873 | Sharon Wegner-Larsen                                                                                                                                        |
| 107 |    542.119265 |    517.267780 | Markus A. Grohme                                                                                                                                            |
| 108 |     17.044929 |    794.606929 | Nobu Tamura, vectorized by Zimices                                                                                                                          |
| 109 |     99.914608 |    645.443944 | Gabriela Palomo-Munoz                                                                                                                                       |
| 110 |    521.894476 |    700.515399 | Chris huh                                                                                                                                                   |
| 111 |     31.391835 |    505.617614 | Marie-Aimée Allard                                                                                                                                          |
| 112 |    165.825772 |    587.532879 | Rebecca Groom                                                                                                                                               |
| 113 |    247.955368 |    764.207806 | Jagged Fang Designs                                                                                                                                         |
| 114 |    944.292597 |    787.700872 | Gareth Monger                                                                                                                                               |
| 115 |    307.804094 |    790.192665 | Cesar Julian                                                                                                                                                |
| 116 |    269.567416 |    143.711414 | Zimices                                                                                                                                                     |
| 117 |    962.777559 |    763.190165 | Gareth Monger                                                                                                                                               |
| 118 |    746.083712 |    563.543498 | Crystal Maier                                                                                                                                               |
| 119 |    105.880018 |    749.379318 | Ferran Sayol                                                                                                                                                |
| 120 |    259.809215 |    180.516511 | C. Camilo Julián-Caballero                                                                                                                                  |
| 121 |    191.880146 |    641.599375 | Margot Michaud                                                                                                                                              |
| 122 |    563.346352 |    540.643539 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                       |
| 123 |    505.339470 |     39.032443 | Ferran Sayol                                                                                                                                                |
| 124 |    992.988428 |     62.719074 | T. Michael Keesey                                                                                                                                           |
| 125 |    896.613020 |    501.383941 | Henry Lydecker                                                                                                                                              |
| 126 |    478.808070 |    689.461079 | Mali’o Kodis, photograph by Derek Keats (<http://www.flickr.com/photos/dkeats/>)                                                                            |
| 127 |    746.363431 |    315.400251 | Mike Hanson                                                                                                                                                 |
| 128 |    240.574269 |    361.909349 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 129 |    274.490241 |    764.709498 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                               |
| 130 |    623.860153 |    727.844264 | T. Michael Keesey                                                                                                                                           |
| 131 |    309.264476 |    137.173457 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                             |
| 132 |    594.798989 |    383.321555 | Dmitry Bogdanov                                                                                                                                             |
| 133 |    383.867306 |     18.091159 | Jack Mayer Wood                                                                                                                                             |
| 134 |    992.871277 |    504.650357 | Harold N Eyster                                                                                                                                             |
| 135 |    311.061449 |    381.055717 | Andy Wilson                                                                                                                                                 |
| 136 |    249.002992 |    269.910299 | Steven Traver                                                                                                                                               |
| 137 |    706.732658 |    176.836441 | John Curtis (vectorized by T. Michael Keesey)                                                                                                               |
| 138 |    584.870371 |    677.591186 | Steven Traver                                                                                                                                               |
| 139 |    780.588938 |    475.082239 | Margot Michaud                                                                                                                                              |
| 140 |    278.912517 |    335.567363 | Stacy Spensley (Modified)                                                                                                                                   |
| 141 |    201.738857 |    223.100235 | Stanton F. Fink, vectorized by Zimices                                                                                                                      |
| 142 |    182.449925 |    397.791995 | Margot Michaud                                                                                                                                              |
| 143 |     46.412346 |    275.481494 | T. Michael Keesey                                                                                                                                           |
| 144 |    430.156304 |    275.559975 | Jimmy Bernot                                                                                                                                                |
| 145 |    992.501142 |    350.582682 | T. Michael Keesey                                                                                                                                           |
| 146 |    535.259127 |    672.751675 | Kai R. Caspar                                                                                                                                               |
| 147 |    859.233782 |    687.770724 | Matt Crook                                                                                                                                                  |
| 148 |    759.839251 |    650.254694 | Gabriela Palomo-Munoz                                                                                                                                       |
| 149 |    544.651638 |    588.819058 | Zimices                                                                                                                                                     |
| 150 |    564.093524 |    737.110550 | Sarah Werning                                                                                                                                               |
| 151 |    835.908566 |    282.699405 | Maija Karala                                                                                                                                                |
| 152 |     59.009934 |    667.642181 | Inessa Voet                                                                                                                                                 |
| 153 |    121.857179 |    783.911530 | Gareth Monger                                                                                                                                               |
| 154 |    469.161736 |    275.138984 | Gareth Monger                                                                                                                                               |
| 155 |    499.816865 |    244.494324 | NA                                                                                                                                                          |
| 156 |    123.425622 |    502.398744 | Tasman Dixon                                                                                                                                                |
| 157 |     69.109175 |    486.589209 | Zimices                                                                                                                                                     |
| 158 |     38.671936 |     55.115569 | T. Michael Keesey (photo by Darren Swim)                                                                                                                    |
| 159 |    344.403347 |     18.560347 | Gabriela Palomo-Munoz                                                                                                                                       |
| 160 |    167.755273 |    339.134491 | Markus A. Grohme                                                                                                                                            |
| 161 |    779.562093 |    493.908294 | Jon Hill                                                                                                                                                    |
| 162 |    697.866388 |    677.825561 | Mathew Wedel                                                                                                                                                |
| 163 |    310.167514 |    211.626564 | NA                                                                                                                                                          |
| 164 |    837.973331 |    217.133898 | Gabriela Palomo-Munoz                                                                                                                                       |
| 165 |    601.909421 |    360.832346 | Yan Wong                                                                                                                                                    |
| 166 |    681.889381 |    540.825997 | Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin                                                                                                |
| 167 |     49.202864 |    637.371872 | Renato de Carvalho Ferreira                                                                                                                                 |
| 168 |    322.193919 |    350.663011 | Margot Michaud                                                                                                                                              |
| 169 |    130.512142 |    378.544459 | T. Michael Keesey                                                                                                                                           |
| 170 |    177.056873 |     87.623276 | Gabriela Palomo-Munoz                                                                                                                                       |
| 171 |    752.917477 |    117.004658 | Jagged Fang Designs                                                                                                                                         |
| 172 |    807.479669 |    177.418117 | Tasman Dixon                                                                                                                                                |
| 173 |    786.158618 |    422.541372 | NA                                                                                                                                                          |
| 174 |    972.891103 |    475.968719 | Jagged Fang Designs                                                                                                                                         |
| 175 |    986.463000 |    246.394142 | Collin Gross                                                                                                                                                |
| 176 |    348.240067 |    525.724684 | Sarah Werning                                                                                                                                               |
| 177 |    654.462271 |    145.177870 | NA                                                                                                                                                          |
| 178 |    419.427730 |    326.499689 | Michael P. Taylor                                                                                                                                           |
| 179 |    917.892002 |    772.783925 | Antonov (vectorized by T. Michael Keesey)                                                                                                                   |
| 180 |    205.388800 |     26.563228 | Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)                                                                               |
| 181 |     94.995592 |    246.593081 | Gareth Monger                                                                                                                                               |
| 182 |   1012.526601 |    616.951567 | Noah Schlottman                                                                                                                                             |
| 183 |    732.325550 |    176.501091 | Matt Crook                                                                                                                                                  |
| 184 |    944.975475 |     42.362077 | Steven Traver                                                                                                                                               |
| 185 |    965.763553 |     29.277181 | Christian A. Masnaghetti                                                                                                                                    |
| 186 |    494.369139 |     87.210401 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                       |
| 187 |    589.303291 |    583.373848 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 188 |    214.104217 |    264.368974 | T. Michael Keesey                                                                                                                                           |
| 189 |    908.929285 |    623.876093 | Zimices                                                                                                                                                     |
| 190 |    153.934046 |    477.378774 | Steven Haddock • Jellywatch.org                                                                                                                             |
| 191 |    242.213509 |    414.535325 | Donovan Reginald Rosevear (vectorized by T. Michael Keesey)                                                                                                 |
| 192 |    588.306270 |    457.283520 | NA                                                                                                                                                          |
| 193 |    274.582966 |    123.605758 | Lafage                                                                                                                                                      |
| 194 |    843.635911 |    313.741338 | Matt Crook                                                                                                                                                  |
| 195 |     18.259603 |    560.594941 | Gareth Monger                                                                                                                                               |
| 196 |    346.072215 |    255.443433 | Matt Crook                                                                                                                                                  |
| 197 |    309.989541 |    603.535233 | Sharon Wegner-Larsen                                                                                                                                        |
| 198 |    711.287196 |    579.084628 | Margot Michaud                                                                                                                                              |
| 199 |    562.150713 |    676.496548 | Maxime Dahirel                                                                                                                                              |
| 200 |    954.140343 |    198.947849 | NA                                                                                                                                                          |
| 201 |    647.098297 |    742.413027 | Kai R. Caspar                                                                                                                                               |
| 202 |    599.998463 |    741.877139 | Natasha Vitek                                                                                                                                               |
| 203 |    836.162100 |    664.237706 | T. Michael Keesey                                                                                                                                           |
| 204 |    697.455752 |    784.912749 | Margot Michaud                                                                                                                                              |
| 205 |    122.810775 |    538.531894 | Birgit Lang                                                                                                                                                 |
| 206 |    114.951429 |    419.073895 | Milton Tan                                                                                                                                                  |
| 207 |    254.650946 |    659.524372 | Bill Bouton (source photo) & T. Michael Keesey (vectorization)                                                                                              |
| 208 |    176.674655 |    323.748718 | Chris huh                                                                                                                                                   |
| 209 |    871.815329 |    654.916816 | Steven Traver                                                                                                                                               |
| 210 |    781.423001 |    392.967972 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                               |
| 211 |    918.682900 |    132.475226 | Margot Michaud                                                                                                                                              |
| 212 |    993.221921 |    753.935376 | NA                                                                                                                                                          |
| 213 |    144.530853 |     78.174250 | Gareth Monger                                                                                                                                               |
| 214 |    912.189964 |    162.177337 | Ingo Braasch                                                                                                                                                |
| 215 |    706.112580 |    389.790425 | NA                                                                                                                                                          |
| 216 |    556.294335 |    415.408754 | Steven Traver                                                                                                                                               |
| 217 |    235.024149 |    446.798978 | Zimices                                                                                                                                                     |
| 218 |    486.822273 |    731.350169 | Kanako Bessho-Uehara                                                                                                                                        |
| 219 |    434.718434 |    168.382899 | Michelle Site                                                                                                                                               |
| 220 |    306.106681 |    264.925350 | Manabu Bessho-Uehara                                                                                                                                        |
| 221 |    647.600352 |    669.098459 | Nobu Tamura, vectorized by Zimices                                                                                                                          |
| 222 |    542.125474 |     27.430927 | T. Michael Keesey                                                                                                                                           |
| 223 |    831.559724 |     89.021367 | Martin Kevil                                                                                                                                                |
| 224 |    667.803515 |    747.823088 | NA                                                                                                                                                          |
| 225 |    966.787898 |    625.991128 | Steven Traver                                                                                                                                               |
| 226 |    322.029717 |    546.012347 | CNZdenek                                                                                                                                                    |
| 227 |    900.210045 |    580.712098 | Tasman Dixon                                                                                                                                                |
| 228 |    437.205927 |    472.866801 | Dave Angelini                                                                                                                                               |
| 229 |    393.053104 |    460.368687 | Kai R. Caspar                                                                                                                                               |
| 230 |    933.692260 |    503.320533 | Margot Michaud                                                                                                                                              |
| 231 |    960.694310 |    240.398213 | Tyler Greenfield                                                                                                                                            |
| 232 |     64.450411 |    129.297208 | John Conway                                                                                                                                                 |
| 233 |    320.516020 |    725.979005 | zoosnow                                                                                                                                                     |
| 234 |    633.178421 |    378.369483 | NA                                                                                                                                                          |
| 235 |    198.727901 |    424.599986 | Matt Martyniuk                                                                                                                                              |
| 236 |    421.122675 |     74.518343 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                    |
| 237 |     73.935600 |    795.410315 | Jagged Fang Designs                                                                                                                                         |
| 238 |    804.609091 |    274.120140 | Andy Wilson                                                                                                                                                 |
| 239 |     39.570880 |    457.236251 | T. Michael Keesey                                                                                                                                           |
| 240 |    257.605006 |    674.752533 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                               |
| 241 |    227.809090 |      3.020894 | Scott Hartman                                                                                                                                               |
| 242 |    498.675014 |    515.074473 | T. Michael Keesey                                                                                                                                           |
| 243 |    132.818079 |    360.789623 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                 |
| 244 |    316.942526 |    747.042449 | Emily Willoughby                                                                                                                                            |
| 245 |    490.226206 |    264.350594 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                              |
| 246 |    695.690853 |    232.448420 | Mali’o Kodis, photograph from <http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>                                                                       |
| 247 |    662.212817 |    429.160917 | Steven Traver                                                                                                                                               |
| 248 |    977.938159 |    489.417344 | Chris huh                                                                                                                                                   |
| 249 |    871.225968 |    253.354447 | Tod Robbins                                                                                                                                                 |
| 250 |    265.550413 |    198.474989 | Auckland Museum and T. Michael Keesey                                                                                                                       |
| 251 |     34.995794 |    374.116262 | Margot Michaud                                                                                                                                              |
| 252 |    372.085875 |    545.519086 | Ferran Sayol                                                                                                                                                |
| 253 |    256.552680 |    696.044334 | Dean Schnabel                                                                                                                                               |
| 254 |     20.832426 |    169.551083 | Gareth Monger                                                                                                                                               |
| 255 |     91.654140 |    152.682818 | Zimices                                                                                                                                                     |
| 256 |    319.798886 |    485.077035 | Markus A. Grohme                                                                                                                                            |
| 257 |     19.660009 |    617.779013 | Matt Crook                                                                                                                                                  |
| 258 |    986.762685 |    648.797074 | Gabriela Palomo-Munoz                                                                                                                                       |
| 259 |   1013.083260 |    157.207124 | Meliponicultor Itaymbere                                                                                                                                    |
| 260 |     33.962444 |    126.020810 | Collin Gross                                                                                                                                                |
| 261 |    990.382048 |    459.862517 | Zimices                                                                                                                                                     |
| 262 |    345.578423 |    742.428140 | Jagged Fang Designs                                                                                                                                         |
| 263 |    240.947487 |    793.805012 | Gareth Monger                                                                                                                                               |
| 264 |    420.790148 |    126.527270 | Matt Crook                                                                                                                                                  |
| 265 |    874.528529 |     91.692530 | Collin Gross                                                                                                                                                |
| 266 |    801.064145 |    453.245407 | T. Michael Keesey                                                                                                                                           |
| 267 |    250.226121 |    120.481431 | Chris huh                                                                                                                                                   |
| 268 |    726.845704 |    401.484763 | Matt Crook                                                                                                                                                  |
| 269 |    502.450433 |    608.616468 | Darius Nau                                                                                                                                                  |
| 270 |    237.848022 |     35.566847 | Gabriela Palomo-Munoz                                                                                                                                       |
| 271 |   1001.006360 |     27.056873 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                           |
| 272 |   1006.056983 |    731.609166 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                |
| 273 |    802.108328 |    248.444681 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                            |
| 274 |    627.517338 |    387.691586 | Walter Vladimir                                                                                                                                             |
| 275 |    817.797599 |    690.161380 | Oscar Sanisidro                                                                                                                                             |
| 276 |    644.196318 |     36.058481 | Jaime Headden                                                                                                                                               |
| 277 |    516.192816 |     10.453067 | Jagged Fang Designs                                                                                                                                         |
| 278 |     15.803967 |    186.698862 | Dean Schnabel                                                                                                                                               |
| 279 |    799.539727 |    792.967554 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 280 |    644.169251 |    751.131440 | Smokeybjb                                                                                                                                                   |
| 281 |    522.157217 |    616.076886 | Tasman Dixon                                                                                                                                                |
| 282 |    855.217645 |    786.759345 | Andrew A. Farke                                                                                                                                             |
| 283 |    699.713052 |    761.143935 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                        |
| 284 |    376.023988 |    145.399764 | ArtFavor & annaleeblysse                                                                                                                                    |
| 285 |    732.611002 |    483.629487 | Michael Scroggie                                                                                                                                            |
| 286 |    107.096361 |    681.578889 | Kamil S. Jaron                                                                                                                                              |
| 287 |    692.631218 |      9.990228 | Roberto Díaz Sibaja                                                                                                                                         |
| 288 |    400.928376 |     57.472776 | Noah Schlottman                                                                                                                                             |
| 289 |    814.675519 |    383.551518 | Emily Willoughby                                                                                                                                            |
| 290 |    645.258017 |    109.578923 | Matt Crook                                                                                                                                                  |
| 291 |    587.508865 |    248.441161 | Jack Mayer Wood                                                                                                                                             |
| 292 |    835.238210 |    431.591316 | Matt Crook                                                                                                                                                  |
| 293 |    167.566475 |    282.232744 | Maija Karala                                                                                                                                                |
| 294 |    454.251220 |    682.235564 | Sharon Wegner-Larsen                                                                                                                                        |
| 295 |    657.621387 |    349.397891 | Chris huh                                                                                                                                                   |
| 296 |    680.695642 |    362.838376 | Christopher Watson (photo) and T. Michael Keesey (vectorization)                                                                                            |
| 297 |    133.977082 |    744.877711 | FunkMonk                                                                                                                                                    |
| 298 |    655.491451 |    259.583329 | Smokeybjb (modified by T. Michael Keesey)                                                                                                                   |
| 299 |    709.874598 |    556.452509 | Zimices                                                                                                                                                     |
| 300 |     15.974108 |    743.423071 | Chris huh                                                                                                                                                   |
| 301 |    325.428175 |    250.481315 | Riccardo Percudani                                                                                                                                          |
| 302 |    513.791985 |    330.567647 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                 |
| 303 |    455.428945 |    625.705215 | Jakovche                                                                                                                                                    |
| 304 |    169.011032 |     63.691045 | Zimices                                                                                                                                                     |
| 305 |    435.409104 |    638.983996 | Dean Schnabel                                                                                                                                               |
| 306 |    985.210529 |    395.959552 | Caleb M. Brown                                                                                                                                              |
| 307 |    718.280347 |    738.602145 | Gabriela Palomo-Munoz                                                                                                                                       |
| 308 |    398.217213 |    474.854786 | C. Camilo Julián-Caballero                                                                                                                                  |
| 309 |    157.211944 |    551.336952 | Margot Michaud                                                                                                                                              |
| 310 |    468.253094 |    397.724061 | Andy Wilson                                                                                                                                                 |
| 311 |    480.761967 |    534.952095 | Fernando Carezzano                                                                                                                                          |
| 312 |    159.390459 |    631.629055 | Brian Gratwicke (photo) and T. Michael Keesey (vectorization)                                                                                               |
| 313 |    152.841625 |    698.295829 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 314 |    645.686034 |     83.198217 | CNZdenek                                                                                                                                                    |
| 315 |    763.248294 |    616.972585 | Birgit Lang                                                                                                                                                 |
| 316 |    444.587470 |    221.751710 | Chris huh                                                                                                                                                   |
| 317 |     15.852645 |    476.393990 | NA                                                                                                                                                          |
| 318 |      8.430686 |    763.978704 | Kristina Gagalova                                                                                                                                           |
| 319 |    805.396371 |     20.725616 | Chris huh                                                                                                                                                   |
| 320 |    630.331810 |    531.219263 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                    |
| 321 |   1005.718975 |    256.910708 | Dean Schnabel                                                                                                                                               |
| 322 |    277.317409 |    112.496647 | Pranav Iyer (grey ideas)                                                                                                                                    |
| 323 |    476.429850 |    522.793988 | Zimices                                                                                                                                                     |
| 324 |    992.898134 |    533.586518 | Ghedoghedo, vectorized by Zimices                                                                                                                           |
| 325 |    847.959883 |     17.214838 | Zimices                                                                                                                                                     |
| 326 |    264.007169 |     16.561256 | Kamil S. Jaron                                                                                                                                              |
| 327 |    217.048312 |    294.943242 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 328 |     15.397600 |     88.064177 | Margot Michaud                                                                                                                                              |
| 329 |    562.743333 |    180.819283 | Zimices                                                                                                                                                     |
| 330 |    908.089027 |    306.243696 | Jagged Fang Designs                                                                                                                                         |
| 331 |    862.839659 |    714.347634 | Jaime Headden                                                                                                                                               |
| 332 |    544.505743 |    294.478367 | Michael Scroggie                                                                                                                                            |
| 333 |    675.577025 |    166.627775 | Scott Hartman                                                                                                                                               |
| 334 |    804.701079 |    316.365056 | Zimices                                                                                                                                                     |
| 335 |    283.519431 |    654.499406 | Gabriela Palomo-Munoz                                                                                                                                       |
| 336 |    905.764695 |    151.457719 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                   |
| 337 |    576.118641 |    428.104913 | Andy Wilson                                                                                                                                                 |
| 338 |    634.481945 |    451.274618 | Matt Crook                                                                                                                                                  |
| 339 |    935.485758 |    625.702366 | Sharon Wegner-Larsen                                                                                                                                        |
| 340 |    212.490494 |    398.765333 | Zimices                                                                                                                                                     |
| 341 |    313.756826 |    658.527241 | Jagged Fang Designs                                                                                                                                         |
| 342 |    560.656182 |     33.826568 | Markus A. Grohme                                                                                                                                            |
| 343 |    671.117307 |    121.219544 | Beth Reinke                                                                                                                                                 |
| 344 |     96.003352 |    669.335996 | Markus A. Grohme                                                                                                                                            |
| 345 |    497.426277 |    478.967877 | Zimices                                                                                                                                                     |
| 346 |    720.999206 |    781.152917 | Ferran Sayol                                                                                                                                                |
| 347 |    162.211390 |    158.322808 | T. Michael Keesey                                                                                                                                           |
| 348 |    194.456410 |    303.064894 | Zimices                                                                                                                                                     |
| 349 |   1013.556928 |    307.394739 | Gareth Monger                                                                                                                                               |
| 350 |    190.469819 |    482.434175 | Zimices                                                                                                                                                     |
| 351 |    760.918224 |    288.667722 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 352 |    560.075196 |    161.863594 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                 |
| 353 |    600.705474 |    324.952241 | Andrew A. Farke                                                                                                                                             |
| 354 |    584.528846 |    708.756207 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                |
| 355 |    938.907907 |    441.782690 | Ryan Cupo                                                                                                                                                   |
| 356 |    608.313666 |    424.138781 | Tasman Dixon                                                                                                                                                |
| 357 |    909.180177 |    659.526133 | Margot Michaud                                                                                                                                              |
| 358 |    920.839180 |    203.425551 | James R. Spotila and Ray Chatterji                                                                                                                          |
| 359 |    707.991319 |      3.116420 | NA                                                                                                                                                          |
| 360 |    308.268182 |    199.772928 | Jagged Fang Designs                                                                                                                                         |
| 361 |    650.948008 |     22.337322 | Rebecca Groom                                                                                                                                               |
| 362 |     57.745985 |    117.270591 | Scott Hartman                                                                                                                                               |
| 363 |    958.585233 |    514.463262 | Sean McCann                                                                                                                                                 |
| 364 |    862.649378 |    391.282007 | Birgit Lang                                                                                                                                                 |
| 365 |    162.070168 |    330.457399 | Smokeybjb                                                                                                                                                   |
| 366 |    466.908962 |    105.356646 | Scott Hartman                                                                                                                                               |
| 367 |    734.878164 |    645.573451 | Ignacio Contreras                                                                                                                                           |
| 368 |    859.331515 |    130.348732 | Walter Vladimir                                                                                                                                             |
| 369 |    567.538666 |    530.407487 | Shyamal                                                                                                                                                     |
| 370 |    961.752378 |    739.455026 | T. Tischler                                                                                                                                                 |
| 371 |    851.985210 |    612.249371 | Ferran Sayol                                                                                                                                                |
| 372 |    341.918055 |    601.154907 | Andy Wilson                                                                                                                                                 |
| 373 |     25.789134 |    265.134622 | Andrew Farke and Joseph Sertich                                                                                                                             |
| 374 |    178.608046 |    600.838153 | Emily Willoughby                                                                                                                                            |
| 375 |    963.536411 |    432.375594 | Gareth Monger                                                                                                                                               |
| 376 |    582.763563 |    239.778248 | NA                                                                                                                                                          |
| 377 |   1014.039403 |    663.188005 | Yan Wong                                                                                                                                                    |
| 378 |   1003.802285 |    386.241044 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                           |
| 379 |   1007.187989 |    593.754329 | Sherman F. Denton via rawpixel.com (illustration) and Timothy J. Bartley (silhouette)                                                                       |
| 380 |     77.029574 |    391.508741 | Ferran Sayol                                                                                                                                                |
| 381 |    854.711994 |    628.279953 | Nobu Tamura                                                                                                                                                 |
| 382 |    190.937451 |     13.583243 | Collin Gross                                                                                                                                                |
| 383 |    647.021305 |     69.906228 | Chris huh                                                                                                                                                   |
| 384 |    313.430092 |    509.910611 | M Kolmann                                                                                                                                                   |
| 385 |    769.460217 |    264.038905 | Matt Dempsey                                                                                                                                                |
| 386 |    496.869512 |     63.924016 | Zimices                                                                                                                                                     |
| 387 |    802.025257 |    125.020206 | Gareth Monger                                                                                                                                               |
| 388 |    595.571566 |    600.483862 | Zimices                                                                                                                                                     |
| 389 |    746.411035 |    782.056330 | Jimmy Bernot                                                                                                                                                |
| 390 |   1000.385547 |    780.559494 | Matt Crook                                                                                                                                                  |
| 391 |     30.803348 |    772.794076 | Michael Scroggie                                                                                                                                            |
| 392 |     62.950059 |    286.830252 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                         |
| 393 |    942.520896 |    571.871137 | T. Michael Keesey                                                                                                                                           |
| 394 |    704.859328 |    519.880351 | Sharon Wegner-Larsen                                                                                                                                        |
| 395 |    775.582729 |    444.831142 | Dori <dori@merr.info> (source photo) and Nevit Dilmen                                                                                                       |
| 396 |      7.732210 |    512.664472 | Gopal Murali                                                                                                                                                |
| 397 |    261.994942 |    221.936804 | T. Michael Keesey                                                                                                                                           |
| 398 |    560.059190 |    282.672462 | Ferran Sayol                                                                                                                                                |
| 399 |    330.422363 |    504.958132 | Kai R. Caspar                                                                                                                                               |
| 400 |    712.845726 |    279.616267 | Chris huh                                                                                                                                                   |
| 401 |    413.492575 |    645.309257 | Chris huh                                                                                                                                                   |
| 402 |    718.917349 |    255.079666 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                      |
| 403 |    482.745095 |    623.505276 | Markus A. Grohme                                                                                                                                            |
| 404 |    550.658012 |    728.160423 | Felix Vaux                                                                                                                                                  |
| 405 |    803.115506 |    415.942241 | Dmitry Bogdanov                                                                                                                                             |
| 406 |    509.157842 |    523.284483 | T. Michael Keesey                                                                                                                                           |
| 407 |     98.237105 |    223.245744 | Dean Schnabel                                                                                                                                               |
| 408 |    158.381736 |    205.965115 | Andy Wilson                                                                                                                                                 |
| 409 |    656.491774 |    490.075280 | Gareth Monger                                                                                                                                               |
| 410 |    572.652766 |    747.079627 | Jaime Headden                                                                                                                                               |
| 411 |    663.843751 |    398.156725 | C. Camilo Julián-Caballero                                                                                                                                  |
| 412 |    384.868946 |    321.399936 | Matt Crook                                                                                                                                                  |
| 413 |     22.565362 |    135.299318 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey     |
| 414 |    570.574395 |     10.513587 | Margot Michaud                                                                                                                                              |
| 415 |    813.366191 |     55.077351 | Zimices                                                                                                                                                     |
| 416 |    884.087752 |    358.076162 | Caleb M. Brown                                                                                                                                              |
| 417 |    154.650615 |    320.328149 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 418 |    716.315241 |    341.714343 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                    |
| 419 |    391.174801 |    308.907063 | SauropodomorphMonarch                                                                                                                                       |
| 420 |    170.202423 |    468.382619 | NA                                                                                                                                                          |
| 421 |    779.250569 |    191.922973 | Gareth Monger                                                                                                                                               |
| 422 |    511.284138 |    416.647792 | Gabriela Palomo-Munoz                                                                                                                                       |
| 423 |    378.190172 |    426.214171 | Zimices                                                                                                                                                     |
| 424 |    828.051905 |    550.482418 | Geoff Shaw                                                                                                                                                  |
| 425 |    778.425288 |    573.657013 | Margot Michaud                                                                                                                                              |
| 426 |     87.397604 |    126.482963 | Zimices                                                                                                                                                     |
| 427 |    983.843187 |    444.079954 | T. Michael Keesey                                                                                                                                           |
| 428 |    242.053806 |     14.546652 | Gabriela Palomo-Munoz                                                                                                                                       |
| 429 |    178.141490 |     37.498859 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                    |
| 430 |    468.243764 |    201.070148 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 431 |    648.167663 |    455.536163 | Gabriela Palomo-Munoz                                                                                                                                       |
| 432 |    328.651460 |    110.371483 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                        |
| 433 |    467.697010 |    471.627817 | Neil Kelley                                                                                                                                                 |
| 434 |    539.100185 |    713.110943 | Andy Wilson                                                                                                                                                 |
| 435 |    613.350683 |      7.526792 | C. Camilo Julián-Caballero                                                                                                                                  |
| 436 |    477.048858 |      9.105124 | Ignacio Contreras                                                                                                                                           |
| 437 |    872.302615 |    216.851410 | Margot Michaud                                                                                                                                              |
| 438 |    264.166955 |    172.569486 | Siobhon Egan                                                                                                                                                |
| 439 |     43.341150 |    392.167809 | T. Tischler                                                                                                                                                 |
| 440 |    921.439159 |    231.858946 | Chris huh                                                                                                                                                   |
| 441 |    428.865612 |    450.379933 | Emily Willoughby                                                                                                                                            |
| 442 |    525.832813 |    483.891128 | Gareth Monger                                                                                                                                               |
| 443 |    999.330445 |     15.718833 | NA                                                                                                                                                          |
| 444 |    296.989567 |    758.731297 | Arthur S. Brum                                                                                                                                              |
| 445 |    347.986374 |    342.388675 | Tod Robbins                                                                                                                                                 |
| 446 |    166.675231 |     47.615302 | Gareth Monger                                                                                                                                               |
| 447 |    270.195774 |    789.862322 | david maas / dave hone                                                                                                                                      |
| 448 |    991.273741 |    426.211637 | Jagged Fang Designs                                                                                                                                         |
| 449 |    378.931023 |    782.132004 | Sarah Werning                                                                                                                                               |
| 450 |    265.441395 |    472.489276 | Ignacio Contreras                                                                                                                                           |
| 451 |    130.653113 |    158.636379 | Steven Traver                                                                                                                                               |
| 452 |     29.386564 |    674.533029 | Jack Mayer Wood                                                                                                                                             |
| 453 |    846.986817 |    203.031428 | Carlos Cano-Barbacil                                                                                                                                        |
| 454 |    173.473223 |    249.512977 | Taenadoman                                                                                                                                                  |
| 455 |    228.889185 |    308.128192 | Gareth Monger                                                                                                                                               |
| 456 |    943.926632 |     34.346236 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                    |
| 457 |   1017.943830 |    428.783330 | Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization)                                                                                      |
| 458 |    947.793585 |    465.234597 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                              |
| 459 |    169.648191 |    535.374988 | Markus A. Grohme                                                                                                                                            |
| 460 |    702.771441 |    794.135515 | Margot Michaud                                                                                                                                              |
| 461 |    578.478203 |    498.969409 | T. Michael Keesey                                                                                                                                           |
| 462 |    129.821831 |    691.628677 | Scott Hartman                                                                                                                                               |
| 463 |    805.354227 |    524.578899 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                               |
| 464 |    757.460920 |    588.656397 | Margot Michaud                                                                                                                                              |
| 465 |    903.272731 |    757.321848 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                    |
| 466 |    833.333321 |    360.050719 | Noah Schlottman                                                                                                                                             |
| 467 |     61.845144 |     44.677989 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                              |
| 468 |    464.752367 |    453.482414 | xgirouxb                                                                                                                                                    |
| 469 |    152.872162 |    654.434972 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 470 |    426.784425 |     47.694686 | Robert Gay, modifed from Olegivvit                                                                                                                          |
| 471 |    807.146044 |     41.395516 | Scott Hartman                                                                                                                                               |
| 472 |    414.696217 |    456.656675 | Andy Wilson                                                                                                                                                 |
| 473 |    938.551283 |    117.249169 | Gareth Monger                                                                                                                                               |
| 474 |    306.204745 |    121.261100 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                         |
| 475 |    430.797584 |    292.936266 | Margot Michaud                                                                                                                                              |
| 476 |    317.646607 |    478.321369 | Chris huh                                                                                                                                                   |
| 477 |    771.675698 |    658.596020 | T. K. Robinson                                                                                                                                              |
| 478 |     49.798717 |    212.822972 | Gareth Monger                                                                                                                                               |
| 479 |    624.025294 |    395.672193 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 480 |    945.567252 |    457.142084 | Noah Schlottman, photo from Casey Dunn                                                                                                                      |
| 481 |    152.718437 |    183.641157 | Sergio A. Muñoz-Gómez                                                                                                                                       |
| 482 |    468.575052 |    719.416749 | Neil Kelley                                                                                                                                                 |
| 483 |    337.439311 |    135.081171 | Zimices                                                                                                                                                     |
| 484 |    717.669246 |    157.584182 | Chris huh                                                                                                                                                   |
| 485 |    211.591481 |    491.367236 | Melissa Broussard                                                                                                                                           |
| 486 |    383.816094 |    524.431672 | Scott Hartman, modified by T. Michael Keesey                                                                                                                |
| 487 |    930.871261 |    175.342551 | Margot Michaud                                                                                                                                              |
| 488 |    420.156273 |    157.867983 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                |
| 489 |    354.517607 |    197.045926 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 490 |    846.074017 |    167.109392 | Scott Hartman                                                                                                                                               |
| 491 |    508.384218 |    666.688510 | Iain Reid                                                                                                                                                   |
| 492 |    708.326872 |    356.142178 | NA                                                                                                                                                          |
| 493 |    538.599867 |     17.363647 | Zimices                                                                                                                                                     |
| 494 |    105.914350 |    108.460027 | Iain Reid                                                                                                                                                   |
| 495 |    289.844278 |    620.103404 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 496 |    100.117050 |      2.773800 | Scott Hartman                                                                                                                                               |
| 497 |    695.246300 |    118.546525 | Juan Carlos Jerí                                                                                                                                            |
| 498 |    519.277596 |    721.166064 | Chris huh                                                                                                                                                   |
| 499 |    703.463662 |    700.367413 | FunkMonk                                                                                                                                                    |
| 500 |    684.687297 |    570.755060 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                |
| 501 |    610.002718 |    657.344762 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                              |
| 502 |    477.970641 |    185.421359 | NA                                                                                                                                                          |
| 503 |    813.967704 |    101.695920 | Bruno Maggia                                                                                                                                                |
| 504 |    865.478381 |    423.001393 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                            |
| 505 |    379.815470 |    762.553088 | Scott Hartman                                                                                                                                               |
| 506 |    251.970709 |    248.812243 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                           |
| 507 |    385.367196 |    369.177999 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                            |
| 508 |    477.355570 |    382.879417 | T. Michael Keesey                                                                                                                                           |
| 509 |    976.300230 |    379.698171 | Iain Reid                                                                                                                                                   |
| 510 |    458.119659 |    172.107973 | Margot Michaud                                                                                                                                              |
| 511 |    823.112651 |    750.276084 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                               |
| 512 |    259.599816 |    328.843561 | E. Lear, 1819 (vectorization by Yan Wong)                                                                                                                   |
| 513 |    361.998135 |     54.227556 | Matt Crook                                                                                                                                                  |
| 514 |    235.940898 |     68.721688 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                    |
| 515 |    787.881015 |    435.206004 | Chris huh                                                                                                                                                   |
| 516 |    361.776959 |    362.258481 | Gabriela Palomo-Munoz                                                                                                                                       |
| 517 |    864.399203 |    336.598580 | David Orr                                                                                                                                                   |
| 518 |    252.631511 |    189.379552 | Jagged Fang Designs                                                                                                                                         |
| 519 |    391.587478 |    641.385279 | Scott Hartman                                                                                                                                               |
| 520 |    312.054732 |    586.903853 | Gabriela Palomo-Munoz                                                                                                                                       |
| 521 |    170.108680 |    117.422480 | Christoph Schomburg                                                                                                                                         |
| 522 |     58.688861 |     36.531716 | Zimices                                                                                                                                                     |
| 523 |    413.190945 |    569.791314 | Gabriela Palomo-Munoz                                                                                                                                       |
| 524 |    570.472811 |    642.448921 | Jaime Headden                                                                                                                                               |
| 525 |    725.442227 |    754.323009 | Smokeybjb                                                                                                                                                   |
| 526 |    693.999560 |    667.718372 | Nobu Tamura                                                                                                                                                 |
| 527 |    451.152309 |    365.933374 | Chris huh                                                                                                                                                   |
| 528 |    683.055034 |    279.338406 | Ignacio Contreras                                                                                                                                           |
| 529 |    166.915792 |    423.686322 | Gareth Monger                                                                                                                                               |
| 530 |     17.953588 |    725.600164 | Tasman Dixon                                                                                                                                                |
| 531 |    891.043408 |    697.260508 | Jaime Headden                                                                                                                                               |
| 532 |    113.094210 |    406.985141 | Gareth Monger                                                                                                                                               |
| 533 |    986.817890 |    520.035189 | Mathew Wedel                                                                                                                                                |
| 534 |    810.624467 |    784.084134 | NA                                                                                                                                                          |
| 535 |    842.939574 |    498.786789 | Chris huh                                                                                                                                                   |
| 536 |    490.030540 |     30.354994 | Emily Willoughby                                                                                                                                            |
| 537 |    627.035878 |    494.411660 | Lily Hughes                                                                                                                                                 |
| 538 |    275.407675 |    258.911287 | NA                                                                                                                                                          |
| 539 |    504.322199 |    109.844804 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                           |
| 540 |    208.640839 |    551.186763 | Scott Hartman                                                                                                                                               |
| 541 |    995.899774 |    331.476150 | Nobu Tamura                                                                                                                                                 |
| 542 |    337.498994 |    233.118324 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                           |
| 543 |    246.068900 |    750.442262 | Michelle Site                                                                                                                                               |

    #> Your tweet has been posted!
