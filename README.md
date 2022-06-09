
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

Zimices, Gareth Monger, Bryan Carstens, Michael Day, Markus A. Grohme,
Hans Hillewaert (vectorized by T. Michael Keesey), Lukasiniho, Inessa
Voet, Tasman Dixon, Kanako Bessho-Uehara, Ferran Sayol, Steven Traver,
T. Michael Keesey, Kamil S. Jaron, Gabriela Palomo-Munoz, Matt Crook,
Margot Michaud, Matt Martyniuk, Smokeybjb, Oscar Sanisidro, Diego
Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli,
Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by
T. Michael Keesey), Scott Hartman, Erika Schumacher, RS, Mali’o Kodis,
photograph by Derek Keats (<http://www.flickr.com/photos/dkeats/>),
Jaime Headden, NOAA Great Lakes Environmental Research Laboratory
(illustration) and Timothy J. Bartley (silhouette), Xavier A. Jenkins,
Gabriel Ugueto, Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen
(vectorized by T. Michael Keesey), Joanna Wolfe, Andy Wilson, Jagged
Fang Designs, Chris huh, Caleb Brown, Jordan Mallon (vectorized by T.
Michael Keesey), Felix Vaux, Christoph Schomburg, Dann Pigdon, Josefine
Bohr Brask, Original drawing by Dmitry Bogdanov, vectorized by Roberto
Díaz Sibaja, Noah Schlottman, Dean Schnabel, Martin R. Smith, Dmitry
Bogdanov (vectorized by T. Michael Keesey), Tim Bertelink (modified by
T. Michael Keesey), Collin Gross, Yan Wong from wikipedia drawing (PD:
Pearson Scott Foresman), ДиБгд (vectorized by T. Michael Keesey), Blanco
et al., 2014, vectorized by Zimices, Thibaut Brunet,
SauropodomorphMonarch, Mathieu Pélissié, Maija Karala, Matthew Hooge
(vectorized by T. Michael Keesey), Iain Reid, Tarique Sani (photo), John
E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Nobu
Tamura, vectorized by Zimices, Armin Reindl, Michelle Site, Matt
Martyniuk (modified by T. Michael Keesey), Carlos Cano-Barbacil, Emily
Jane McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
James R. Spotila and Ray Chatterji, Sam Fraser-Smith (vectorized by T.
Michael Keesey), Samanta Orellana, Pete Buchholz, Henry Lydecker, (after
McCulloch 1908), T. Michael Keesey (after Kukalová), Nobu Tamura
(modified by T. Michael Keesey), xgirouxb, Conty (vectorized by T.
Michael Keesey), Kenneth Lacovara (vectorized by T. Michael Keesey),
Michael Scroggie, Yan Wong, C. Camilo Julián-Caballero, Birgit Lang,
Apokryltaros (vectorized by T. Michael Keesey), L. Shyamal, Ludwik
Gąsiorowski, Ramona J Heim, T. Michael Keesey (photo by J. M. Garg),
Melissa Broussard, Emma Hughes, Jonathan Wells, Noah Schlottman, photo
by Casey Dunn, M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and
Ulf Jondelius (vectorized by T. Michael Keesey), Mateus Zica (modified
by T. Michael Keesey), Ricardo N. Martinez & Oscar A. Alcober, Ellen
Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley
(silhouette), Manabu Bessho-Uehara, Jan A. Venter, Herbert H. T. Prins,
David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey),
Mathilde Cordellier, Steven Coombs, Matt Wilkins (photo by Patrick
Kavanagh), Adam Stuart Smith (vectorized by T. Michael Keesey), Unknown
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Richard Parker (vectorized by T. Michael Keesey), T. Michael
Keesey (vectorization) and Larry Loos (photography), Kai R. Caspar, Noah
Schlottman, photo from Casey Dunn, Robert Hering, Evan-Amos (vectorized
by T. Michael Keesey), Riccardo Percudani, Nancy Wyman (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Smokeybjb,
vectorized by Zimices, Alex Slavenko, David Sim (photograph) and T.
Michael Keesey (vectorization), Sarah Werning, Matus Valach, Ignacio
Contreras, Roberto Díaz Sibaja, Harold N Eyster, Estelle Bourdon,
Terpsichores, Milton Tan, Rene Martin, Beth Reinke, Alexander
Schmidt-Lebuhn, Mali’o Kodis, photograph by Aqua-Photos
(<http://www.flickr.com/people/undervannsfotografen/>), Emily
Willoughby, Stanton F. Fink (vectorized by T. Michael Keesey), Mike
Hanson, Chuanixn Yu, Manabu Sakamoto, Hugo Gruson, FunkMonk, Jose Carlos
Arenas-Monroy, Francisco Gascó (modified by Michael P. Taylor), Geoff
Shaw, Jack Mayer Wood, Mason McNair, Sharon Wegner-Larsen, Arthur S.
Brum, Jakovche, Benjamin Monod-Broca, Nobu Tamura (vectorized by T.
Michael Keesey), Matt Celeskey, Maxime Dahirel, Ingo Braasch, Walter
Vladimir, Tony Ayling (vectorized by T. Michael Keesey), Darren Naish
(vectorized by T. Michael Keesey), Mette Aumala, Shyamal, M Hutchinson,
Anthony Caravaggi, Charles R. Knight (vectorized by T. Michael Keesey),
AnAgnosticGod (vectorized by T. Michael Keesey), Lily Hughes, Tracy A.
Heath, CNZdenek, Agnello Picorelli, Andrew A. Farke, (after Spotila
2004), Alexandre Vong, Robbie N. Cada (vectorized by T. Michael Keesey),
Scott Hartman (modified by T. Michael Keesey), DW Bapst (Modified from
photograph taken by Charles Mitchell), Jerry Oldenettel (vectorized by
T. Michael Keesey), Renato de Carvalho Ferreira, Smokeybjb (vectorized
by T. Michael Keesey), Mali’o Kodis, photograph by Hans Hillewaert,
Allison Pease, Pranav Iyer (grey ideas), Ghedoghedo (vectorized by T.
Michael Keesey), Matt Dempsey, Nobu Tamura, modified by Andrew A. Farke,
Gustav Mützel, Ian Burt (original) and T. Michael Keesey
(vectorization), Stuart Humphries, Joschua Knüppe, Rebecca Groom, Duane
Raver (vectorized by T. Michael Keesey), Caleb M. Brown, Michael Ströck
(vectorized by T. Michael Keesey), Lafage, Andrew R. Gehrke,
TaraTaylorDesign, Campbell Fleming, Madeleine Price Ball, Brad McFeeters
(vectorized by T. Michael Keesey), Frederick William Frohawk (vectorized
by T. Michael Keesey), NASA, Dexter R. Mardis, Giant Blue Anteater
(vectorized by T. Michael Keesey), Sean McCann, Nina Skinner, Young and
Zhao (1972:figure 4), modified by Michael P. Taylor

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     89.929729 |    373.230695 | Zimices                                                                                                                                                               |
|   2 |    181.388959 |    240.834220 | Gareth Monger                                                                                                                                                         |
|   3 |    566.039895 |    648.218995 | Bryan Carstens                                                                                                                                                        |
|   4 |    362.126042 |    315.771305 | Michael Day                                                                                                                                                           |
|   5 |    249.838647 |    699.375361 | Markus A. Grohme                                                                                                                                                      |
|   6 |    160.113595 |    487.926566 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
|   7 |    224.653361 |     14.313916 | Markus A. Grohme                                                                                                                                                      |
|   8 |    668.870037 |    503.429604 | Lukasiniho                                                                                                                                                            |
|   9 |    921.942196 |    193.960294 | Inessa Voet                                                                                                                                                           |
|  10 |    404.908253 |    488.239779 | Tasman Dixon                                                                                                                                                          |
|  11 |    578.647694 |    353.577048 | NA                                                                                                                                                                    |
|  12 |    697.984682 |    189.367920 | Kanako Bessho-Uehara                                                                                                                                                  |
|  13 |    777.676316 |    584.158535 | Ferran Sayol                                                                                                                                                          |
|  14 |    886.323633 |    564.023336 | Gareth Monger                                                                                                                                                         |
|  15 |    854.447556 |    272.179586 | Markus A. Grohme                                                                                                                                                      |
|  16 |    950.148992 |    738.659395 | Gareth Monger                                                                                                                                                         |
|  17 |    395.524336 |    209.500532 | Zimices                                                                                                                                                               |
|  18 |    541.389111 |    161.480215 | Zimices                                                                                                                                                               |
|  19 |    252.812342 |    562.124690 | Steven Traver                                                                                                                                                         |
|  20 |    178.567146 |    156.578074 | T. Michael Keesey                                                                                                                                                     |
|  21 |    467.889407 |    380.735213 | Kamil S. Jaron                                                                                                                                                        |
|  22 |    738.204916 |    719.642444 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  23 |    416.928067 |    720.681067 | Gareth Monger                                                                                                                                                         |
|  24 |    240.944228 |    348.730707 | Matt Crook                                                                                                                                                            |
|  25 |    366.490624 |    422.823388 | Margot Michaud                                                                                                                                                        |
|  26 |    679.408453 |    315.682743 | Matt Martyniuk                                                                                                                                                        |
|  27 |    482.658626 |    224.155967 | Smokeybjb                                                                                                                                                             |
|  28 |    865.328024 |    441.158655 | Oscar Sanisidro                                                                                                                                                       |
|  29 |    133.120338 |     72.248643 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
|  30 |    371.128433 |    648.242593 | Scott Hartman                                                                                                                                                         |
|  31 |    185.160104 |    103.736740 | Erika Schumacher                                                                                                                                                      |
|  32 |    315.784595 |     70.648058 | RS                                                                                                                                                                    |
|  33 |    850.759008 |    700.113281 | Mali’o Kodis, photograph by Derek Keats (<http://www.flickr.com/photos/dkeats/>)                                                                                      |
|  34 |    480.179862 |    106.319222 | Jaime Headden                                                                                                                                                         |
|  35 |    559.209539 |    441.491723 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
|  36 |    605.620294 |    693.081974 | Matt Crook                                                                                                                                                            |
|  37 |    392.759691 |    135.090277 | Xavier A. Jenkins, Gabriel Ugueto                                                                                                                                     |
|  38 |    121.425899 |    754.231214 | T. Michael Keesey                                                                                                                                                     |
|  39 |     63.883049 |    524.411960 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
|  40 |    554.250608 |    270.638617 | Joanna Wolfe                                                                                                                                                          |
|  41 |    711.379849 |     69.678556 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  42 |    546.294761 |     72.481468 | Zimices                                                                                                                                                               |
|  43 |     88.443531 |    628.417210 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  44 |    946.068389 |     85.410255 | Matt Crook                                                                                                                                                            |
|  45 |    567.108094 |    500.255744 | Steven Traver                                                                                                                                                         |
|  46 |    456.342746 |    658.439443 | NA                                                                                                                                                                    |
|  47 |    761.813558 |    371.590445 | Matt Crook                                                                                                                                                            |
|  48 |     61.976457 |    233.252592 | Andy Wilson                                                                                                                                                           |
|  49 |    566.030784 |     35.328954 | Jagged Fang Designs                                                                                                                                                   |
|  50 |    396.445344 |    558.222304 | Tasman Dixon                                                                                                                                                          |
|  51 |    290.969406 |    476.091570 | Chris huh                                                                                                                                                             |
|  52 |    765.530202 |    154.466627 | Caleb Brown                                                                                                                                                           |
|  53 |    259.909208 |    767.066194 | Andy Wilson                                                                                                                                                           |
|  54 |    724.670275 |    632.819044 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                       |
|  55 |    965.688465 |    329.677841 | Steven Traver                                                                                                                                                         |
|  56 |    957.458095 |    544.593290 | Felix Vaux                                                                                                                                                            |
|  57 |    782.044696 |    440.715307 | Christoph Schomburg                                                                                                                                                   |
|  58 |    850.863555 |     44.372954 | NA                                                                                                                                                                    |
|  59 |    135.439079 |    179.873241 | Dann Pigdon                                                                                                                                                           |
|  60 |    304.649516 |    172.200065 | Josefine Bohr Brask                                                                                                                                                   |
|  61 |     82.107283 |    271.985498 | Tasman Dixon                                                                                                                                                          |
|  62 |    664.412215 |    139.166886 | Scott Hartman                                                                                                                                                         |
|  63 |    241.179153 |    643.955495 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
|  64 |     45.205407 |    151.356622 | Noah Schlottman                                                                                                                                                       |
|  65 |    725.153411 |    266.262457 | Zimices                                                                                                                                                               |
|  66 |    878.001105 |    350.857274 | Dean Schnabel                                                                                                                                                         |
|  67 |    996.314754 |    629.159563 | Martin R. Smith                                                                                                                                                       |
|  68 |    506.073324 |    762.328328 | Scott Hartman                                                                                                                                                         |
|  69 |    231.729989 |    422.239412 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  70 |    799.628417 |    497.390606 | Scott Hartman                                                                                                                                                         |
|  71 |    368.689361 |     21.457853 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                         |
|  72 |    645.132394 |    772.437755 | Jagged Fang Designs                                                                                                                                                   |
|  73 |    929.213045 |    244.040377 | Jaime Headden                                                                                                                                                         |
|  74 |    280.789552 |    131.485878 | Collin Gross                                                                                                                                                          |
|  75 |    294.652271 |    277.923401 | Ferran Sayol                                                                                                                                                          |
|  76 |    759.070225 |    116.955739 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                          |
|  77 |    878.268988 |    136.312094 | ДиБгд (vectorized by T. Michael Keesey)                                                                                                                               |
|  78 |    334.625497 |    746.129893 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  79 |    887.273516 |    783.110796 | Blanco et al., 2014, vectorized by Zimices                                                                                                                            |
|  80 |    554.697879 |    783.594052 | Thibaut Brunet                                                                                                                                                        |
|  81 |    174.452296 |    320.155246 | Gareth Monger                                                                                                                                                         |
|  82 |    651.647984 |    407.301276 | Gareth Monger                                                                                                                                                         |
|  83 |     31.211400 |     50.975244 | SauropodomorphMonarch                                                                                                                                                 |
|  84 |    825.989456 |     94.933395 | Steven Traver                                                                                                                                                         |
|  85 |    800.006688 |    234.250909 | Margot Michaud                                                                                                                                                        |
|  86 |    159.891471 |    205.142983 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  87 |     80.395932 |     33.420293 | NA                                                                                                                                                                    |
|  88 |    767.167006 |    523.936918 | Mathieu Pélissié                                                                                                                                                      |
|  89 |    909.361511 |    645.300629 | Margot Michaud                                                                                                                                                        |
|  90 |    684.925887 |     28.396490 | Margot Michaud                                                                                                                                                        |
|  91 |    392.548190 |     62.520968 | NA                                                                                                                                                                    |
|  92 |     71.935256 |    321.435172 | Scott Hartman                                                                                                                                                         |
|  93 |     55.027291 |    485.411244 | Maija Karala                                                                                                                                                          |
|  94 |    506.854200 |    532.132611 | Matt Crook                                                                                                                                                            |
|  95 |    638.212213 |    744.662511 | Jagged Fang Designs                                                                                                                                                   |
|  96 |    124.018314 |    562.402256 | Zimices                                                                                                                                                               |
|  97 |    136.319089 |    430.119356 | T. Michael Keesey                                                                                                                                                     |
|  98 |    234.315500 |    195.221098 | Gareth Monger                                                                                                                                                         |
|  99 |    429.812324 |    273.843471 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                                       |
| 100 |    628.103043 |     54.355512 | Michael Day                                                                                                                                                           |
| 101 |     41.941147 |    714.392965 | Collin Gross                                                                                                                                                          |
| 102 |    366.189653 |    783.036424 | Zimices                                                                                                                                                               |
| 103 |    767.961040 |    314.081009 | Iain Reid                                                                                                                                                             |
| 104 |    779.648927 |    654.320191 | Gareth Monger                                                                                                                                                         |
| 105 |     30.808825 |    765.333644 | Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey          |
| 106 |    984.652622 |    472.752292 | Lukasiniho                                                                                                                                                            |
| 107 |    779.319871 |     19.719860 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 108 |    572.534566 |    108.687843 | NA                                                                                                                                                                    |
| 109 |    366.166000 |    365.647985 | Christoph Schomburg                                                                                                                                                   |
| 110 |    710.176577 |    451.318584 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 111 |     64.826679 |    446.960540 | Steven Traver                                                                                                                                                         |
| 112 |    963.926947 |    430.529223 | Ferran Sayol                                                                                                                                                          |
| 113 |    766.958738 |    421.616947 | Armin Reindl                                                                                                                                                          |
| 114 |    472.716589 |     44.478684 | NA                                                                                                                                                                    |
| 115 |     62.301325 |     52.580619 | T. Michael Keesey                                                                                                                                                     |
| 116 |    178.204573 |    782.880176 | Michelle Site                                                                                                                                                         |
| 117 |    513.112532 |    343.698900 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                        |
| 118 |    831.457788 |    545.659963 | Carlos Cano-Barbacil                                                                                                                                                  |
| 119 |    645.890703 |    719.900310 | Chris huh                                                                                                                                                             |
| 120 |    823.302587 |    476.653162 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                           |
| 121 |    104.430446 |    691.534858 | T. Michael Keesey                                                                                                                                                     |
| 122 |    577.528524 |    219.191859 | Matt Crook                                                                                                                                                            |
| 123 |    467.925591 |    206.028158 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 124 |     33.848327 |    450.669082 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                                    |
| 125 |    984.419581 |    786.949364 | Jaime Headden                                                                                                                                                         |
| 126 |    426.793891 |    337.483308 | Ferran Sayol                                                                                                                                                          |
| 127 |     29.065111 |    304.199402 | Samanta Orellana                                                                                                                                                      |
| 128 |    445.945865 |    302.656098 | Pete Buchholz                                                                                                                                                         |
| 129 |    705.234737 |    582.423122 | Henry Lydecker                                                                                                                                                        |
| 130 |     91.993490 |     91.141717 | Matt Crook                                                                                                                                                            |
| 131 |    292.476848 |    629.056913 | Scott Hartman                                                                                                                                                         |
| 132 |     28.715326 |    627.846742 | Steven Traver                                                                                                                                                         |
| 133 |    677.439518 |    409.106543 | Lukasiniho                                                                                                                                                            |
| 134 |    542.071883 |    229.625969 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 135 |    821.319256 |    309.513048 | (after McCulloch 1908)                                                                                                                                                |
| 136 |    623.598765 |    232.013878 | T. Michael Keesey (after Kukalová)                                                                                                                                    |
| 137 |    932.709903 |    265.653534 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 138 |    715.937748 |    592.874153 | xgirouxb                                                                                                                                                              |
| 139 |    955.771992 |    641.443036 | Jaime Headden                                                                                                                                                         |
| 140 |     38.387807 |    647.307163 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 141 |    201.676949 |     45.765206 | Matt Crook                                                                                                                                                            |
| 142 |    395.335799 |    626.434028 | Steven Traver                                                                                                                                                         |
| 143 |    305.346392 |    670.737401 | Scott Hartman                                                                                                                                                         |
| 144 |    770.035275 |    462.844483 | Steven Traver                                                                                                                                                         |
| 145 |    464.198960 |    585.131061 | Kamil S. Jaron                                                                                                                                                        |
| 146 |    320.022380 |    616.017886 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                    |
| 147 |   1007.051133 |    530.732566 | Michael Scroggie                                                                                                                                                      |
| 148 |    156.748596 |    518.788321 | Yan Wong                                                                                                                                                              |
| 149 |    814.716380 |    758.867773 | C. Camilo Julián-Caballero                                                                                                                                            |
| 150 |    377.287855 |    603.375039 | Birgit Lang                                                                                                                                                           |
| 151 |   1003.231086 |    173.607989 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 152 |    130.309976 |    779.127189 | L. Shyamal                                                                                                                                                            |
| 153 |    145.089200 |    619.053450 | Dean Schnabel                                                                                                                                                         |
| 154 |    444.033391 |    451.795178 | Scott Hartman                                                                                                                                                         |
| 155 |   1006.659699 |    403.065642 | Ludwik Gąsiorowski                                                                                                                                                    |
| 156 |    925.677615 |    758.109194 | Ramona J Heim                                                                                                                                                         |
| 157 |    276.996411 |    448.082050 | xgirouxb                                                                                                                                                              |
| 158 |    674.055293 |    638.929989 | T. Michael Keesey (photo by J. M. Garg)                                                                                                                               |
| 159 |    642.473798 |    590.825369 | Steven Traver                                                                                                                                                         |
| 160 |    174.231711 |    663.376556 | Ferran Sayol                                                                                                                                                          |
| 161 |    259.538122 |    667.947248 | Michelle Site                                                                                                                                                         |
| 162 |    813.203000 |    186.169369 | Melissa Broussard                                                                                                                                                     |
| 163 |    796.042994 |    563.977233 | Emma Hughes                                                                                                                                                           |
| 164 |    168.301613 |     61.525221 | Jonathan Wells                                                                                                                                                        |
| 165 |    574.723278 |     63.170992 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 166 |    888.322354 |    617.365427 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                              |
| 167 |     21.923554 |    370.417011 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                           |
| 168 |    639.729136 |    357.467195 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                                |
| 169 |    457.055877 |    665.260730 | Collin Gross                                                                                                                                                          |
| 170 |    156.453226 |    636.384441 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 171 |     26.976613 |    403.762822 | Manabu Bessho-Uehara                                                                                                                                                  |
| 172 |    973.635742 |    150.792284 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 173 |    470.852068 |    484.407226 | Mathilde Cordellier                                                                                                                                                   |
| 174 |    230.931097 |    286.090271 | Steven Coombs                                                                                                                                                         |
| 175 |    574.660726 |    540.715532 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                              |
| 176 |    331.125895 |    569.116878 | Ferran Sayol                                                                                                                                                          |
| 177 |     32.656987 |     69.018980 | Jagged Fang Designs                                                                                                                                                   |
| 178 |    933.262716 |    508.683555 | Martin R. Smith                                                                                                                                                       |
| 179 |    306.978172 |    101.096966 | Ferran Sayol                                                                                                                                                          |
| 180 |    474.221414 |    709.978718 | T. Michael Keesey                                                                                                                                                     |
| 181 |    734.672952 |     29.610118 | Zimices                                                                                                                                                               |
| 182 |    768.200916 |    341.571801 | Zimices                                                                                                                                                               |
| 183 |    396.571810 |    105.435358 | Adam Stuart Smith (vectorized by T. Michael Keesey)                                                                                                                   |
| 184 |    618.905311 |    637.396423 | Margot Michaud                                                                                                                                                        |
| 185 |     44.166284 |      4.177750 | NA                                                                                                                                                                    |
| 186 |    485.867912 |    313.220195 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 187 |    313.768161 |    523.754494 | Scott Hartman                                                                                                                                                         |
| 188 |   1010.795508 |     20.108147 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 189 |    889.041081 |    387.970381 | Scott Hartman                                                                                                                                                         |
| 190 |    219.791420 |     53.996489 | Matt Crook                                                                                                                                                            |
| 191 |    839.854850 |    203.178475 | Richard Parker (vectorized by T. Michael Keesey)                                                                                                                      |
| 192 |   1007.623446 |    353.963988 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                                        |
| 193 |    886.064252 |    604.686446 | Kai R. Caspar                                                                                                                                                         |
| 194 |    158.319484 |    290.593196 | T. Michael Keesey                                                                                                                                                     |
| 195 |    907.505931 |    301.004600 | Zimices                                                                                                                                                               |
| 196 |    937.792404 |    693.020162 | Steven Traver                                                                                                                                                         |
| 197 |    785.749079 |    383.436833 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 198 |    506.762159 |    460.473403 | Robert Hering                                                                                                                                                         |
| 199 |     55.761590 |    558.326366 | Michelle Site                                                                                                                                                         |
| 200 |    262.814432 |     30.256262 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 201 |    582.103825 |    415.195663 | Evan-Amos (vectorized by T. Michael Keesey)                                                                                                                           |
| 202 |   1005.245435 |    319.267431 | Gareth Monger                                                                                                                                                         |
| 203 |    688.376227 |    732.172265 | Ferran Sayol                                                                                                                                                          |
| 204 |    459.365767 |    516.417810 | T. Michael Keesey                                                                                                                                                     |
| 205 |    407.980664 |    393.856613 | Riccardo Percudani                                                                                                                                                    |
| 206 |    135.018763 |     78.717540 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 207 |     22.901545 |    256.896791 | Ferran Sayol                                                                                                                                                          |
| 208 |    465.519229 |     22.364394 | Smokeybjb, vectorized by Zimices                                                                                                                                      |
| 209 |    784.704462 |    190.516452 | Birgit Lang                                                                                                                                                           |
| 210 |    811.104631 |    741.701291 | Alex Slavenko                                                                                                                                                         |
| 211 |    515.185743 |     55.278384 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                          |
| 212 |    118.780996 |    596.051875 | Sarah Werning                                                                                                                                                         |
| 213 |    824.980204 |    508.028787 | C. Camilo Julián-Caballero                                                                                                                                            |
| 214 |    424.894086 |    372.806195 | Matus Valach                                                                                                                                                          |
| 215 |    155.015506 |    403.824317 | Andy Wilson                                                                                                                                                           |
| 216 |    963.098350 |      9.919493 | Ignacio Contreras                                                                                                                                                     |
| 217 |    288.865759 |     78.590359 | Gareth Monger                                                                                                                                                         |
| 218 |    857.082611 |     73.117583 | Roberto Díaz Sibaja                                                                                                                                                   |
| 219 |   1002.620572 |    236.236764 | Sarah Werning                                                                                                                                                         |
| 220 |    774.722645 |    630.920177 | Christoph Schomburg                                                                                                                                                   |
| 221 |    859.741076 |    765.978189 | Zimices                                                                                                                                                               |
| 222 |     22.908245 |    605.271959 | Lukasiniho                                                                                                                                                            |
| 223 |    865.792204 |    246.840603 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 224 |    623.931643 |    111.070469 | Chris huh                                                                                                                                                             |
| 225 |    701.058438 |    390.771881 | T. Michael Keesey                                                                                                                                                     |
| 226 |    822.964612 |     16.920270 | Harold N Eyster                                                                                                                                                       |
| 227 |    161.930227 |    727.330438 | Matt Crook                                                                                                                                                            |
| 228 |    130.782038 |    392.129294 | NA                                                                                                                                                                    |
| 229 |    523.307020 |     90.148276 | Alex Slavenko                                                                                                                                                         |
| 230 |    373.417228 |    154.479148 | Estelle Bourdon                                                                                                                                                       |
| 231 |     35.903815 |    693.952338 | Jagged Fang Designs                                                                                                                                                   |
| 232 |    355.134671 |    260.279717 | Scott Hartman                                                                                                                                                         |
| 233 |    453.319943 |     64.221138 | Ferran Sayol                                                                                                                                                          |
| 234 |    802.913007 |    254.917781 | Terpsichores                                                                                                                                                          |
| 235 |    624.034910 |     26.148749 | Scott Hartman                                                                                                                                                         |
| 236 |     16.528090 |    564.322505 | Margot Michaud                                                                                                                                                        |
| 237 |    779.542471 |    712.477043 | Ignacio Contreras                                                                                                                                                     |
| 238 |    581.775979 |    674.729852 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                          |
| 239 |    637.699922 |     13.666510 | Pete Buchholz                                                                                                                                                         |
| 240 |    315.950399 |    213.069868 | Milton Tan                                                                                                                                                            |
| 241 |    803.439845 |    105.460483 | Christoph Schomburg                                                                                                                                                   |
| 242 |    311.002512 |    350.694833 | C. Camilo Julián-Caballero                                                                                                                                            |
| 243 |    610.985834 |    269.137759 | Rene Martin                                                                                                                                                           |
| 244 |    869.830483 |    361.307324 | Beth Reinke                                                                                                                                                           |
| 245 |    467.575404 |    746.116323 | Jonathan Wells                                                                                                                                                        |
| 246 |    504.133514 |    421.353218 | NA                                                                                                                                                                    |
| 247 |    792.173510 |    446.259942 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 248 |    380.145362 |    707.262312 | Mali’o Kodis, photograph by Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>)                                                                        |
| 249 |    245.839365 |    236.706176 | Emily Willoughby                                                                                                                                                      |
| 250 |     21.607421 |     21.371480 | Jagged Fang Designs                                                                                                                                                   |
| 251 |    738.765138 |      9.742145 | Zimices                                                                                                                                                               |
| 252 |    201.904279 |    408.292446 | Scott Hartman                                                                                                                                                         |
| 253 |    157.235460 |    338.496940 | Beth Reinke                                                                                                                                                           |
| 254 |    986.250948 |    164.266310 | Tasman Dixon                                                                                                                                                          |
| 255 |    787.774850 |    780.760784 | Carlos Cano-Barbacil                                                                                                                                                  |
| 256 |    682.341857 |    592.808490 | Christoph Schomburg                                                                                                                                                   |
| 257 |    578.319212 |    293.472577 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 258 |    606.733941 |     68.481906 | T. Michael Keesey                                                                                                                                                     |
| 259 |    838.552357 |    767.843444 | Jagged Fang Designs                                                                                                                                                   |
| 260 |    861.832479 |    632.317250 | Chris huh                                                                                                                                                             |
| 261 |    869.493648 |     95.118582 | Christoph Schomburg                                                                                                                                                   |
| 262 |     81.254676 |    209.254457 | Sarah Werning                                                                                                                                                         |
| 263 |    664.974835 |    108.509853 | Mike Hanson                                                                                                                                                           |
| 264 |    495.231282 |    602.994950 | Chuanixn Yu                                                                                                                                                           |
| 265 |   1003.407152 |    248.750542 | Markus A. Grohme                                                                                                                                                      |
| 266 |    744.637546 |    545.416848 | Manabu Sakamoto                                                                                                                                                       |
| 267 |    195.605710 |    296.205936 | Scott Hartman                                                                                                                                                         |
| 268 |     36.660617 |    670.934115 | NA                                                                                                                                                                    |
| 269 |   1004.079892 |    269.030849 | Ignacio Contreras                                                                                                                                                     |
| 270 |    421.315622 |    294.345523 | Smokeybjb, vectorized by Zimices                                                                                                                                      |
| 271 |    541.238940 |    778.400790 | Ignacio Contreras                                                                                                                                                     |
| 272 |    138.105188 |    681.306326 | Hugo Gruson                                                                                                                                                           |
| 273 |    131.094205 |    305.026972 | Steven Traver                                                                                                                                                         |
| 274 |    924.459055 |     10.595220 | Ferran Sayol                                                                                                                                                          |
| 275 |    108.412404 |    703.306157 | FunkMonk                                                                                                                                                              |
| 276 |    315.998039 |    138.094247 | Jonathan Wells                                                                                                                                                        |
| 277 |    999.291528 |    386.289575 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 278 |    514.658402 |    365.851963 | NA                                                                                                                                                                    |
| 279 |    763.827154 |     50.529524 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                       |
| 280 |    702.928143 |    751.195407 | Geoff Shaw                                                                                                                                                            |
| 281 |    373.891317 |    471.554252 | Steven Traver                                                                                                                                                         |
| 282 |    195.056128 |    736.667932 | Maija Karala                                                                                                                                                          |
| 283 |    209.720150 |    670.265284 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 284 |     66.826461 |    337.484373 | Jack Mayer Wood                                                                                                                                                       |
| 285 |     68.571887 |    223.067011 | Kai R. Caspar                                                                                                                                                         |
| 286 |    861.455100 |    319.051555 | Margot Michaud                                                                                                                                                        |
| 287 |     13.438496 |    482.095568 | Gareth Monger                                                                                                                                                         |
| 288 |    903.114544 |    762.030043 | Scott Hartman                                                                                                                                                         |
| 289 |    601.754122 |    203.413189 | Andy Wilson                                                                                                                                                           |
| 290 |    362.555328 |    722.914057 | NA                                                                                                                                                                    |
| 291 |    762.664630 |    637.478705 | Scott Hartman                                                                                                                                                         |
| 292 |     17.741389 |    204.869589 | Mason McNair                                                                                                                                                          |
| 293 |     94.622868 |    785.663542 | Beth Reinke                                                                                                                                                           |
| 294 |    862.288229 |    299.764274 | NA                                                                                                                                                                    |
| 295 |    360.573017 |    395.733969 | Matt Crook                                                                                                                                                            |
| 296 |    733.839729 |    509.252368 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 297 |    813.230029 |    627.664364 | T. Michael Keesey                                                                                                                                                     |
| 298 |    709.885497 |    571.994112 | Ferran Sayol                                                                                                                                                          |
| 299 |    349.688488 |    668.979193 | Margot Michaud                                                                                                                                                        |
| 300 |   1007.314771 |    504.819775 | Sharon Wegner-Larsen                                                                                                                                                  |
| 301 |    113.252577 |    453.424178 | T. Michael Keesey                                                                                                                                                     |
| 302 |   1006.418770 |    141.567992 | Arthur S. Brum                                                                                                                                                        |
| 303 |    754.515973 |    402.673443 | Dean Schnabel                                                                                                                                                         |
| 304 |    864.598287 |    401.164118 | Jakovche                                                                                                                                                              |
| 305 |    508.295956 |    749.409577 | Harold N Eyster                                                                                                                                                       |
| 306 |    100.065712 |    513.173493 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 307 |    394.928631 |    589.862672 | Benjamin Monod-Broca                                                                                                                                                  |
| 308 |    653.304670 |    343.469510 | Margot Michaud                                                                                                                                                        |
| 309 |    584.851707 |    664.888951 | C. Camilo Julián-Caballero                                                                                                                                            |
| 310 |    217.623393 |     74.197908 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 311 |    195.650725 |    771.272888 | Ferran Sayol                                                                                                                                                          |
| 312 |    682.976622 |    428.091333 | Jagged Fang Designs                                                                                                                                                   |
| 313 |   1010.238562 |     86.688296 | Gareth Monger                                                                                                                                                         |
| 314 |    536.715741 |      8.355159 | Chris huh                                                                                                                                                             |
| 315 |    140.976469 |    135.363894 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 316 |    472.254389 |    784.661746 | Matt Celeskey                                                                                                                                                         |
| 317 |    193.002928 |    618.213051 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 318 |    984.527588 |    358.877769 | T. Michael Keesey                                                                                                                                                     |
| 319 |    802.330167 |    788.599476 | NA                                                                                                                                                                    |
| 320 |     62.660381 |    794.484326 | Zimices                                                                                                                                                               |
| 321 |    127.887203 |    229.642801 | Kamil S. Jaron                                                                                                                                                        |
| 322 |    421.152906 |    240.166208 | Margot Michaud                                                                                                                                                        |
| 323 |    613.687010 |     94.504834 | Maxime Dahirel                                                                                                                                                        |
| 324 |    337.277455 |    766.258031 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 325 |    475.974206 |    247.186919 | Ingo Braasch                                                                                                                                                          |
| 326 |    931.190941 |    405.736649 | Matt Celeskey                                                                                                                                                         |
| 327 |    943.644172 |    656.368398 | Walter Vladimir                                                                                                                                                       |
| 328 |    618.056604 |    621.330013 | Gareth Monger                                                                                                                                                         |
| 329 |    630.489968 |    251.933998 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 330 |    546.702654 |    559.989221 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 331 |    795.007145 |    404.570757 | Markus A. Grohme                                                                                                                                                      |
| 332 |    404.062613 |    276.267644 | RS                                                                                                                                                                    |
| 333 |    240.309397 |    469.971087 | Margot Michaud                                                                                                                                                        |
| 334 |    171.575460 |    736.509171 | Margot Michaud                                                                                                                                                        |
| 335 |    205.270763 |    205.751265 | Mette Aumala                                                                                                                                                          |
| 336 |      7.649309 |    524.773152 | Gareth Monger                                                                                                                                                         |
| 337 |    433.613874 |    787.782012 | Steven Traver                                                                                                                                                         |
| 338 |    621.946367 |    208.752916 | Matt Crook                                                                                                                                                            |
| 339 |    750.342963 |    360.527550 | Shyamal                                                                                                                                                               |
| 340 |    974.335829 |    261.329743 | M Hutchinson                                                                                                                                                          |
| 341 |    538.174638 |    420.523165 | Joanna Wolfe                                                                                                                                                          |
| 342 |    933.642531 |    666.258975 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 343 |    188.998746 |    142.443713 | Chris huh                                                                                                                                                             |
| 344 |    590.982473 |    650.572717 | Anthony Caravaggi                                                                                                                                                     |
| 345 |    450.413117 |    126.708323 | Shyamal                                                                                                                                                               |
| 346 |    412.888423 |    535.919248 | Matt Crook                                                                                                                                                            |
| 347 |    266.205812 |    263.260818 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 348 |    259.568749 |    280.410103 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                                   |
| 349 |    462.114620 |     10.112267 | Jagged Fang Designs                                                                                                                                                   |
| 350 |    896.175919 |    410.335102 | Jaime Headden                                                                                                                                                         |
| 351 |    951.599522 |    609.481840 | Scott Hartman                                                                                                                                                         |
| 352 |    737.689767 |    331.263769 | AnAgnosticGod (vectorized by T. Michael Keesey)                                                                                                                       |
| 353 |    233.268312 |    463.843930 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 354 |    764.350968 |    695.365424 | T. Michael Keesey                                                                                                                                                     |
| 355 |   1004.598220 |    749.756653 | Margot Michaud                                                                                                                                                        |
| 356 |    483.526667 |    491.843540 | Gareth Monger                                                                                                                                                         |
| 357 |    936.560600 |    625.424617 | Jagged Fang Designs                                                                                                                                                   |
| 358 |    684.788429 |    120.580165 | Lily Hughes                                                                                                                                                           |
| 359 |    989.024395 |    283.003510 | Andy Wilson                                                                                                                                                           |
| 360 |     16.242367 |    425.249838 | Felix Vaux                                                                                                                                                            |
| 361 |    682.637073 |     10.384163 | Tracy A. Heath                                                                                                                                                        |
| 362 |    599.004030 |     16.028637 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 363 |    621.703952 |    285.228809 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                       |
| 364 |    252.897219 |     52.033790 | Tasman Dixon                                                                                                                                                          |
| 365 |    625.511430 |    181.285921 | Chuanixn Yu                                                                                                                                                           |
| 366 |     51.598053 |    734.630095 | Carlos Cano-Barbacil                                                                                                                                                  |
| 367 |    485.319699 |     82.049679 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 368 |    482.825881 |    272.274247 | Zimices                                                                                                                                                               |
| 369 |     90.686320 |     58.048042 | Matt Crook                                                                                                                                                            |
| 370 |    345.611683 |    144.863167 | CNZdenek                                                                                                                                                              |
| 371 |    359.775955 |     88.534619 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 372 |    129.407087 |    285.560157 | Gareth Monger                                                                                                                                                         |
| 373 |    892.117834 |    496.770387 | Zimices                                                                                                                                                               |
| 374 |    457.947134 |    167.200439 | Zimices                                                                                                                                                               |
| 375 |    672.347132 |    210.154706 | Agnello Picorelli                                                                                                                                                     |
| 376 |    985.349027 |    449.307029 | T. Michael Keesey                                                                                                                                                     |
| 377 |    715.378451 |    790.593530 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 378 |    795.714343 |    319.552345 | Christoph Schomburg                                                                                                                                                   |
| 379 |    850.801075 |     13.934369 | Christoph Schomburg                                                                                                                                                   |
| 380 |    781.744934 |    700.520326 | Andrew A. Farke                                                                                                                                                       |
| 381 |     27.221117 |    343.278539 | Ferran Sayol                                                                                                                                                          |
| 382 |    988.359408 |     21.353599 | Tasman Dixon                                                                                                                                                          |
| 383 |    117.500781 |    148.876271 | Maija Karala                                                                                                                                                          |
| 384 |     88.424567 |      7.677635 | Tasman Dixon                                                                                                                                                          |
| 385 |    791.012983 |    547.626402 | Matt Crook                                                                                                                                                            |
| 386 |    125.397325 |    631.893820 | Jaime Headden                                                                                                                                                         |
| 387 |     94.212885 |    561.317373 | FunkMonk                                                                                                                                                              |
| 388 |     90.865938 |    724.215575 | Matt Celeskey                                                                                                                                                         |
| 389 |    850.734883 |    224.030850 | Christoph Schomburg                                                                                                                                                   |
| 390 |    396.923360 |    312.951193 | Michael Scroggie                                                                                                                                                      |
| 391 |   1007.749452 |    222.327843 | NA                                                                                                                                                                    |
| 392 |    668.026663 |    709.448649 | Matt Crook                                                                                                                                                            |
| 393 |    270.634585 |    206.123672 | (after Spotila 2004)                                                                                                                                                  |
| 394 |    680.000985 |    277.817401 | Alexandre Vong                                                                                                                                                        |
| 395 |    811.116012 |    525.320770 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 396 |    185.930418 |    443.963359 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                         |
| 397 |   1012.952736 |    423.207249 | L. Shyamal                                                                                                                                                            |
| 398 |    424.769939 |    329.492879 | Ignacio Contreras                                                                                                                                                     |
| 399 |     54.851391 |    410.639730 | DW Bapst (Modified from photograph taken by Charles Mitchell)                                                                                                         |
| 400 |    803.431116 |    295.219150 | Zimices                                                                                                                                                               |
| 401 |    939.164774 |    470.322293 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                    |
| 402 |    229.597949 |    270.666666 | Carlos Cano-Barbacil                                                                                                                                                  |
| 403 |    571.058806 |     90.629093 | Steven Traver                                                                                                                                                         |
| 404 |    892.126688 |    325.425481 | Chris huh                                                                                                                                                             |
| 405 |     19.292194 |    665.842765 | Matt Crook                                                                                                                                                            |
| 406 |    951.581317 |     23.104865 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 407 |    967.868173 |    695.778364 | Renato de Carvalho Ferreira                                                                                                                                           |
| 408 |   1001.220873 |    187.133783 | Gareth Monger                                                                                                                                                         |
| 409 |    719.670257 |    315.444482 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 410 |    479.351264 |    289.010716 | Zimices                                                                                                                                                               |
| 411 |    349.179959 |    347.475459 | Margot Michaud                                                                                                                                                        |
| 412 |    799.659410 |    730.623720 | NA                                                                                                                                                                    |
| 413 |    327.127490 |    252.766177 | T. Michael Keesey                                                                                                                                                     |
| 414 |    647.833339 |    616.280735 | Margot Michaud                                                                                                                                                        |
| 415 |     19.498452 |    236.552198 | Ferran Sayol                                                                                                                                                          |
| 416 |    329.403004 |    338.153494 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                           |
| 417 |    542.283492 |    207.313717 | Allison Pease                                                                                                                                                         |
| 418 |    154.549797 |    652.931626 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 419 |    280.760639 |    433.781305 | Ignacio Contreras                                                                                                                                                     |
| 420 |    436.369923 |    742.709755 | Matt Martyniuk                                                                                                                                                        |
| 421 |    133.869830 |    714.941481 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 422 |    661.286672 |    568.990322 | Ignacio Contreras                                                                                                                                                     |
| 423 |    504.110945 |     17.154086 | Zimices                                                                                                                                                               |
| 424 |     77.337222 |    698.546791 | Michelle Site                                                                                                                                                         |
| 425 |    452.210720 |    728.474462 | Jack Mayer Wood                                                                                                                                                       |
| 426 |    554.883274 |    700.058303 | Kamil S. Jaron                                                                                                                                                        |
| 427 |    593.382220 |    466.014964 | Matt Martyniuk                                                                                                                                                        |
| 428 |    793.823743 |    477.317187 | T. Michael Keesey                                                                                                                                                     |
| 429 |    395.094309 |    459.704611 | Markus A. Grohme                                                                                                                                                      |
| 430 |    136.787481 |      7.226957 | Scott Hartman                                                                                                                                                         |
| 431 |     53.654287 |    263.464579 | Jagged Fang Designs                                                                                                                                                   |
| 432 |     87.818681 |    305.420625 | Gareth Monger                                                                                                                                                         |
| 433 |    816.076502 |    452.508109 | Gareth Monger                                                                                                                                                         |
| 434 |    986.171034 |    558.038735 | Maija Karala                                                                                                                                                          |
| 435 |    271.265908 |    620.929586 | Steven Coombs                                                                                                                                                         |
| 436 |    864.743087 |    596.522096 | Chris huh                                                                                                                                                             |
| 437 |    744.666417 |    467.190110 | Jagged Fang Designs                                                                                                                                                   |
| 438 |    426.014624 |    322.566662 | Matt Dempsey                                                                                                                                                          |
| 439 |    403.738327 |    472.464611 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 440 |    159.594522 |    449.745715 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                              |
| 441 |    781.630393 |     77.842037 | Chris huh                                                                                                                                                             |
| 442 |    224.065763 |    452.595909 | Gustav Mützel                                                                                                                                                         |
| 443 |    292.524780 |    402.781996 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                             |
| 444 |    471.342993 |    446.929756 | Matt Crook                                                                                                                                                            |
| 445 |    158.641789 |    781.258222 | Stuart Humphries                                                                                                                                                      |
| 446 |    337.767362 |    681.911152 | Matt Dempsey                                                                                                                                                          |
| 447 |    485.447167 |    570.645089 | Joschua Knüppe                                                                                                                                                        |
| 448 |    464.467790 |    543.819524 | Christoph Schomburg                                                                                                                                                   |
| 449 |    627.494528 |    161.326261 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 450 |    147.982145 |     46.029082 | Manabu Sakamoto                                                                                                                                                       |
| 451 |    400.518395 |    347.708841 | Martin R. Smith                                                                                                                                                       |
| 452 |    291.064018 |    503.467276 | Zimices                                                                                                                                                               |
| 453 |    739.032537 |    232.176162 | Jagged Fang Designs                                                                                                                                                   |
| 454 |    124.762930 |    725.971987 | Andy Wilson                                                                                                                                                           |
| 455 |    102.181552 |    115.755448 | Ignacio Contreras                                                                                                                                                     |
| 456 |    671.291397 |    681.608220 | Samanta Orellana                                                                                                                                                      |
| 457 |    193.222648 |    522.934590 | Rebecca Groom                                                                                                                                                         |
| 458 |    259.871722 |    440.614857 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                         |
| 459 |    135.408725 |    545.720726 | Chris huh                                                                                                                                                             |
| 460 |    984.586599 |    697.332928 | Chris huh                                                                                                                                                             |
| 461 |    703.225528 |    423.095980 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 462 |    338.585790 |    505.841622 | Margot Michaud                                                                                                                                                        |
| 463 |     34.499021 |    503.870686 | Caleb M. Brown                                                                                                                                                        |
| 464 |    491.194813 |    585.226922 | Birgit Lang                                                                                                                                                           |
| 465 |    359.500067 |    630.019689 | Gareth Monger                                                                                                                                                         |
| 466 |    374.330685 |    673.606750 | Alex Slavenko                                                                                                                                                         |
| 467 |     78.657430 |    259.817644 | T. Michael Keesey                                                                                                                                                     |
| 468 |    903.499398 |    146.085892 | Iain Reid                                                                                                                                                             |
| 469 |    955.692541 |    617.014972 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                                      |
| 470 |    400.572604 |    760.116406 | Lafage                                                                                                                                                                |
| 471 |    476.561927 |    260.361454 | Chris huh                                                                                                                                                             |
| 472 |    262.046431 |    152.425086 | Zimices                                                                                                                                                               |
| 473 |    146.202690 |    369.982527 | Beth Reinke                                                                                                                                                           |
| 474 |    973.143621 |    248.924657 | Jaime Headden                                                                                                                                                         |
| 475 |    372.791959 |    230.919804 | Andrew R. Gehrke                                                                                                                                                      |
| 476 |    331.694727 |    533.344678 | Chris huh                                                                                                                                                             |
| 477 |     40.985134 |    748.839639 | Gareth Monger                                                                                                                                                         |
| 478 |    643.533434 |    215.176072 | Maija Karala                                                                                                                                                          |
| 479 |    952.611129 |    474.839280 | Caleb M. Brown                                                                                                                                                        |
| 480 |    166.830502 |    532.769466 | Beth Reinke                                                                                                                                                           |
| 481 |     98.057703 |    604.653714 | TaraTaylorDesign                                                                                                                                                      |
| 482 |    261.632189 |    105.300007 | Zimices                                                                                                                                                               |
| 483 |    755.819119 |    198.248106 | Steven Traver                                                                                                                                                         |
| 484 |    654.365537 |    373.447409 | Margot Michaud                                                                                                                                                        |
| 485 |    437.519889 |    445.219580 | Chris huh                                                                                                                                                             |
| 486 |    360.012015 |    582.680344 | Ferran Sayol                                                                                                                                                          |
| 487 |    615.182788 |    406.168975 | Ferran Sayol                                                                                                                                                          |
| 488 |    820.297489 |    573.075252 | Matt Crook                                                                                                                                                            |
| 489 |    534.079443 |    615.743041 | Campbell Fleming                                                                                                                                                      |
| 490 |    214.757380 |    128.061458 | Madeleine Price Ball                                                                                                                                                  |
| 491 |    697.306254 |    706.323430 | NA                                                                                                                                                                    |
| 492 |     34.637481 |    223.275798 | Steven Traver                                                                                                                                                         |
| 493 |    840.293783 |    175.988283 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 494 |    288.369029 |    658.218596 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 495 |    175.106907 |    392.094131 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                           |
| 496 |    263.175962 |    232.023216 | NASA                                                                                                                                                                  |
| 497 |    125.630202 |    407.478514 | Margot Michaud                                                                                                                                                        |
| 498 |    325.106697 |    544.430236 | Emily Willoughby                                                                                                                                                      |
| 499 |   1003.952379 |    120.349545 | Dexter R. Mardis                                                                                                                                                      |
| 500 |    715.517971 |    489.075666 | Gareth Monger                                                                                                                                                         |
| 501 |    426.854797 |    417.932191 | Ignacio Contreras                                                                                                                                                     |
| 502 |    432.217195 |    113.635297 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                                 |
| 503 |    435.543765 |    201.547206 | Scott Hartman                                                                                                                                                         |
| 504 |    906.947798 |    596.345641 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 505 |    429.760092 |     50.185503 | Gareth Monger                                                                                                                                                         |
| 506 |    628.933941 |    535.193278 | Dean Schnabel                                                                                                                                                         |
| 507 |    377.424194 |     45.555691 | Markus A. Grohme                                                                                                                                                      |
| 508 |    472.402567 |    149.200187 | Carlos Cano-Barbacil                                                                                                                                                  |
| 509 |    250.290517 |    507.975580 | Chris huh                                                                                                                                                             |
| 510 |    760.913857 |    788.321628 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 511 |     27.063417 |     84.551344 | Erika Schumacher                                                                                                                                                      |
| 512 |    597.049740 |    752.493610 | Agnello Picorelli                                                                                                                                                     |
| 513 |    719.182121 |    606.556383 | Markus A. Grohme                                                                                                                                                      |
| 514 |    582.181646 |    766.937031 | Jaime Headden                                                                                                                                                         |
| 515 |    198.884462 |    184.129778 | Michelle Site                                                                                                                                                         |
| 516 |    464.448268 |    687.830933 | Gareth Monger                                                                                                                                                         |
| 517 |    293.986070 |     44.647415 | Chris huh                                                                                                                                                             |
| 518 |    284.139749 |    114.199977 | Chris huh                                                                                                                                                             |
| 519 |    739.328261 |    351.238164 | Riccardo Percudani                                                                                                                                                    |
| 520 |    696.473845 |    217.642568 | T. Michael Keesey                                                                                                                                                     |
| 521 |    319.777275 |    588.916154 | Chris huh                                                                                                                                                             |
| 522 |    653.267393 |    117.804500 | NA                                                                                                                                                                    |
| 523 |     89.152682 |    144.121051 | Maxime Dahirel                                                                                                                                                        |
| 524 |    191.924109 |    271.116519 | NA                                                                                                                                                                    |
| 525 |    840.550605 |    383.601039 | Sean McCann                                                                                                                                                           |
| 526 |    415.597352 |    774.106590 | Matt Crook                                                                                                                                                            |
| 527 |    997.098341 |    773.963931 | Maija Karala                                                                                                                                                          |
| 528 |   1007.424553 |    301.615795 | Nina Skinner                                                                                                                                                          |
| 529 |    953.304736 |    793.613497 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 530 |    358.063894 |    494.619955 | T. Michael Keesey                                                                                                                                                     |
| 531 |    436.311430 |    590.582902 | Harold N Eyster                                                                                                                                                       |
| 532 |    363.751587 |    760.672685 | Carlos Cano-Barbacil                                                                                                                                                  |
| 533 |    720.211237 |    541.609375 | Matt Crook                                                                                                                                                            |
| 534 |    399.219434 |    162.812072 | Maija Karala                                                                                                                                                          |
| 535 |    807.268772 |    750.707500 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 536 |     60.196153 |     86.988661 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                         |
| 537 |    224.835032 |    501.066405 | Armin Reindl                                                                                                                                                          |
| 538 |     88.856803 |    344.281383 | Armin Reindl                                                                                                                                                          |
| 539 |    580.830782 |    313.221968 | Scott Hartman                                                                                                                                                         |
| 540 |    818.715518 |    164.595090 | Armin Reindl                                                                                                                                                          |
| 541 |    349.718727 |    101.105274 | Dexter R. Mardis                                                                                                                                                      |
| 542 |    862.816723 |    639.373056 | Markus A. Grohme                                                                                                                                                      |
| 543 |    718.412567 |    379.279016 | Ferran Sayol                                                                                                                                                          |
| 544 |    288.277040 |    149.194745 | T. Michael Keesey                                                                                                                                                     |
| 545 |    208.020746 |    181.301463 | Gareth Monger                                                                                                                                                         |
| 546 |    928.309578 |    394.720559 | NA                                                                                                                                                                    |

    #> Your tweet has been posted!
