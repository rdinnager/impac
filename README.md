
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

Matt Crook, Evan Swigart (photography) and T. Michael Keesey
(vectorization), Nobu Tamura (vectorized by T. Michael Keesey), Collin
Gross, Gabriela Palomo-Munoz, Sarefo (vectorized by T. Michael Keesey),
Sarah Werning, Steven Traver, Zimices, New York Zoological Society,
Margot Michaud, Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti,
Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G.
Barraclough (vectorized by T. Michael Keesey), Matt Martyniuk, Michelle
Site, Qiang Ou, Michele M Tobias, Derek Bakken (photograph) and T.
Michael Keesey (vectorization), T. Michael Keesey, Ghedoghedo
(vectorized by T. Michael Keesey), Jagged Fang Designs, Martin R. Smith,
T. Michael Keesey (after A. Y. Ivantsov), Tyler Greenfield, Todd
Marshall, vectorized by Zimices, Gareth Monger, Yan Wong from wikipedia
drawing (PD: Pearson Scott Foresman), Adrian Reich, Conty (vectorized by
T. Michael Keesey), Pete Buchholz, Chris huh, Scott Hartman, Andrew A.
Farke, T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler,
Ted M. Townsend & Miguel Vences), Remes K, Ortega F, Fierro I, Joger U,
Kosma R, et al., Emily Jane McTavish, Alexandre Vong, Tasman Dixon,
Alexander Schmidt-Lebuhn, Chase Brownstein, Joseph J. W. Sertich, Mark
A. Loewen, Ingo Braasch, Manabu Bessho-Uehara, James Neenan, C. Camilo
Julián-Caballero, Jaime Headden, Emily Willoughby, Nobu Tamura,
vectorized by Zimices, Chloé Schmidt, Shyamal, Mike Hanson, Scarlet23
(vectorized by T. Michael Keesey), Ferran Sayol, Dmitry Bogdanov
(vectorized by T. Michael Keesey), Stephen O’Connor (vectorized by T.
Michael Keesey), Tauana J. Cunha, Mathilde Cordellier, Didier Descouens
(vectorized by T. Michael Keesey), Melissa Broussard, T. Michael Keesey
(photo by J. M. Garg), Michael Scroggie, from original photograph by
Gary M. Stolz, USFWS (original photograph in public domain)., Chris A.
Hamilton, L. Shyamal, Trond R. Oskars, Harold N Eyster, Mathew Wedel,
Lukasiniho, Dave Angelini, FunkMonk, Henry Fairfield Osborn, vectorized
by Zimices, Christoph Schomburg, Steve Hillebrand/U. S. Fish and
Wildlife Service (source photo), T. Michael Keesey (vectorization),
Lauren Anderson, Smokeybjb, Michael “FunkMonk” B. H. (vectorized by T.
Michael Keesey), Katie S. Collins, Keith Murdock (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Noah Schlottman,
photo by Gustav Paulay for Moorea Biocode, Hans Hillewaert (vectorized
by T. Michael Keesey), Paul O. Lewis, Maxime Dahirel, Obsidian Soul
(vectorized by T. Michael Keesey), Philippe Janvier (vectorized by T.
Michael Keesey), Beth Reinke, Becky Barnes, Darren Naish (vectorized by
T. Michael Keesey), Anthony Caravaggi, Mattia Menchetti, Falconaumanni
and T. Michael Keesey, Kai R. Caspar, Robbie N. Cada (modified by T.
Michael Keesey), Yan Wong, Kent Elson Sorgon, Kamil S. Jaron, Mark
Miller, Tracy A. Heath, Ricardo Araújo, Mo Hassan, Sean McCann, T.
Michael Keesey (from a mount by Allis Markham), Francisco Manuel Blanco
(vectorized by T. Michael Keesey), Julio Garza, Kelly, Iain Reid, Dean
Schnabel, Archaeodontosaurus (vectorized by T. Michael Keesey), Kenneth
Lacovara (vectorized by T. Michael Keesey), Xavier Giroux-Bougard, Cesar
Julian, Birgit Lang, Jaime A. Headden (vectorized by T. Michael Keesey),
Rebecca Groom, Michael Scroggie, Richard Ruggiero, vectorized by
Zimices, Maija Karala, CNZdenek, Armin Reindl, Rafael Maia, Joanna
Wolfe, Tony Ayling (vectorized by T. Michael Keesey), Andreas Trepte
(vectorized by T. Michael Keesey), Geoff Shaw, Jiekun He, Cristian
Osorio & Paula Carrera, Proyecto Carnivoros Australes
(www.carnivorosaustrales.org), DW Bapst (modified from Bulman, 1970), T.
Michael Keesey (after Joseph Wolf), Scott Hartman, modified by T.
Michael Keesey, Aleksey Nagovitsyn (vectorized by T. Michael Keesey),
Oscar Sanisidro, Sergio A. Muñoz-Gómez, Mali’o Kodis, drawing by Manvir
Singh, JCGiron, Alex Slavenko, Matt Martyniuk (modified by Serenchia),
Frank Denota, Scott Hartman (vectorized by T. Michael Keesey), Ernst
Haeckel (vectorized by T. Michael Keesey), Jaime Headden, modified by T.
Michael Keesey, Carlos Cano-Barbacil, James R. Spotila and Ray
Chatterji, Meliponicultor Itaymbere, Matt Martyniuk (modified by T.
Michael Keesey), T. Michael Keesey (vectorization); Yves Bousquet
(photography), xgirouxb, Milton Tan, Owen Jones (derived from a CC-BY
2.0 photograph by Paulo B. Chaves), Isaure Scavezzoni, Andrew A. Farke,
modified from original by Robert Bruce Horsfall, from Scott 1912, Filip
em, Mike Keesey (vectorization) and Vaibhavcho (photography), Zachary
Quigley, James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo
Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael
Keesey), Amanda Katzer, Raven Amos, Karla Martinez, Arthur Weasley
(vectorized by T. Michael Keesey), Tyler McCraney, DW Bapst (Modified
from Bulman, 1964), Mark Hofstetter (vectorized by T. Michael Keesey),
Brad McFeeters (vectorized by T. Michael Keesey), Zsoldos Márton
(vectorized by T. Michael Keesey), Emily Jane McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Cagri Cevrim, Josefine Bohr Brask, Siobhon Egan, Nobu Tamura, Jack Mayer
Wood, T. Tischler, I. Geoffroy Saint-Hilaire (vectorized by T. Michael
Keesey), Hans Hillewaert (photo) and T. Michael Keesey (vectorization),
Roberto Díaz Sibaja, Craig Dylke, Ville-Veikko Sinkkonen, T. Michael
Keesey (after C. De Muizon)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    816.825863 |    584.940434 | Matt Crook                                                                                                                                                            |
|   2 |    158.873216 |    181.824203 | Evan Swigart (photography) and T. Michael Keesey (vectorization)                                                                                                      |
|   3 |    422.473467 |    642.207727 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|   4 |     79.212193 |    709.633545 | Collin Gross                                                                                                                                                          |
|   5 |    122.866838 |    426.382367 | Gabriela Palomo-Munoz                                                                                                                                                 |
|   6 |    584.752167 |    409.114337 | Sarefo (vectorized by T. Michael Keesey)                                                                                                                              |
|   7 |    761.635487 |    287.547931 | Sarah Werning                                                                                                                                                         |
|   8 |    559.788384 |    533.367971 | Steven Traver                                                                                                                                                         |
|   9 |    267.655552 |    305.524066 | Zimices                                                                                                                                                               |
|  10 |    422.813364 |    119.626250 | New York Zoological Society                                                                                                                                           |
|  11 |     67.010506 |    307.429347 | Margot Michaud                                                                                                                                                        |
|  12 |    739.439244 |    125.152940 | Margot Michaud                                                                                                                                                        |
|  13 |    919.752326 |    344.839875 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
|  14 |    361.364250 |    530.334964 | Matt Martyniuk                                                                                                                                                        |
|  15 |    881.276394 |    174.306031 | Michelle Site                                                                                                                                                         |
|  16 |    162.301650 |    583.964861 | Steven Traver                                                                                                                                                         |
|  17 |    881.366480 |    608.414337 | NA                                                                                                                                                                    |
|  18 |    892.306407 |     58.891105 | NA                                                                                                                                                                    |
|  19 |    252.618023 |     96.538502 | Zimices                                                                                                                                                               |
|  20 |    782.868675 |    460.170733 | Matt Crook                                                                                                                                                            |
|  21 |    579.678416 |    223.317569 | Qiang Ou                                                                                                                                                              |
|  22 |    887.460643 |    687.260946 | Steven Traver                                                                                                                                                         |
|  23 |    692.807185 |    423.643907 | Michele M Tobias                                                                                                                                                      |
|  24 |    390.905003 |    254.768571 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
|  25 |     88.134912 |    505.009968 | T. Michael Keesey                                                                                                                                                     |
|  26 |    548.734612 |     84.207963 | Matt Crook                                                                                                                                                            |
|  27 |    758.959299 |    754.694609 | Zimices                                                                                                                                                               |
|  28 |    894.967620 |    281.029538 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
|  29 |    284.298091 |    701.064482 | NA                                                                                                                                                                    |
|  30 |    252.053958 |     40.825944 | Jagged Fang Designs                                                                                                                                                   |
|  31 |    963.738409 |    192.431678 | Michelle Site                                                                                                                                                         |
|  32 |   1004.970089 |    263.569275 | Martin R. Smith                                                                                                                                                       |
|  33 |    201.684604 |    427.631927 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                              |
|  34 |    537.881122 |    732.136795 | Matt Crook                                                                                                                                                            |
|  35 |    440.932773 |    445.460830 | Zimices                                                                                                                                                               |
|  36 |    457.191078 |    523.989922 | Zimices                                                                                                                                                               |
|  37 |    516.931971 |    288.134984 | Tyler Greenfield                                                                                                                                                      |
|  38 |    455.468763 |    360.823133 | Zimices                                                                                                                                                               |
|  39 |    864.060860 |    496.245934 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
|  40 |    437.193857 |     45.318060 | Jagged Fang Designs                                                                                                                                                   |
|  41 |    415.458774 |    718.539994 | Margot Michaud                                                                                                                                                        |
|  42 |    786.725480 |    371.503616 | Margot Michaud                                                                                                                                                        |
|  43 |     93.767354 |     63.635136 | Gareth Monger                                                                                                                                                         |
|  44 |    939.827715 |    757.577503 | Margot Michaud                                                                                                                                                        |
|  45 |    659.129698 |    255.827586 | Jagged Fang Designs                                                                                                                                                   |
|  46 |    679.614603 |    303.943513 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                          |
|  47 |    265.331238 |    472.582133 | Adrian Reich                                                                                                                                                          |
|  48 |    123.061933 |    140.604433 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
|  49 |    663.472956 |    536.423284 | Pete Buchholz                                                                                                                                                         |
|  50 |    389.299840 |    774.863328 | Chris huh                                                                                                                                                             |
|  51 |     92.410115 |    648.159225 | Scott Hartman                                                                                                                                                         |
|  52 |    209.284037 |    767.878324 | Tyler Greenfield                                                                                                                                                      |
|  53 |     40.212621 |     63.394095 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
|  54 |    319.052534 |    158.186542 | Zimices                                                                                                                                                               |
|  55 |     60.108070 |    257.010219 | Jagged Fang Designs                                                                                                                                                   |
|  56 |    457.018674 |    239.708980 | Andrew A. Farke                                                                                                                                                       |
|  57 |    318.260483 |     61.755286 | Gareth Monger                                                                                                                                                         |
|  58 |    519.311842 |     33.259143 | Scott Hartman                                                                                                                                                         |
|  59 |    691.030695 |     24.747914 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                                     |
|  60 |    212.613558 |    727.895746 | T. Michael Keesey                                                                                                                                                     |
|  61 |    276.631281 |    555.035003 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                                 |
|  62 |    582.897024 |    732.005321 | Emily Jane McTavish                                                                                                                                                   |
|  63 |    124.161669 |    314.333943 | Alexandre Vong                                                                                                                                                        |
|  64 |    818.654448 |    235.147710 | Tasman Dixon                                                                                                                                                          |
|  65 |    489.179905 |    596.755035 | Chris huh                                                                                                                                                             |
|  66 |     16.570605 |    540.046854 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|  67 |    987.198425 |    580.597824 | Chase Brownstein                                                                                                                                                      |
|  68 |    944.203021 |    340.952236 | Zimices                                                                                                                                                               |
|  69 |     58.040839 |    593.313499 | Steven Traver                                                                                                                                                         |
|  70 |    782.466493 |    652.678145 | NA                                                                                                                                                                    |
|  71 |    143.936479 |    662.543666 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                  |
|  72 |    414.176852 |    110.463756 | NA                                                                                                                                                                    |
|  73 |    412.750610 |    169.960263 | Ingo Braasch                                                                                                                                                          |
|  74 |     60.400156 |    778.832968 | Chase Brownstein                                                                                                                                                      |
|  75 |    985.509652 |    654.045423 | Manabu Bessho-Uehara                                                                                                                                                  |
|  76 |    173.312604 |     53.299289 | James Neenan                                                                                                                                                          |
|  77 |    822.739414 |    207.044638 | Matt Crook                                                                                                                                                            |
|  78 |    189.118356 |    684.058140 | Zimices                                                                                                                                                               |
|  79 |    552.433580 |    292.554544 | C. Camilo Julián-Caballero                                                                                                                                            |
|  80 |     43.938911 |    157.848712 | T. Michael Keesey                                                                                                                                                     |
|  81 |    125.327092 |    506.694323 | Chris huh                                                                                                                                                             |
|  82 |    603.270162 |    657.564350 | Jaime Headden                                                                                                                                                         |
|  83 |    152.837921 |    386.559483 | Chris huh                                                                                                                                                             |
|  84 |    532.044577 |    159.346490 | Emily Willoughby                                                                                                                                                      |
|  85 |     81.107218 |    545.899475 | T. Michael Keesey                                                                                                                                                     |
|  86 |    492.322720 |    168.329821 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  87 |    202.261960 |    734.115726 | Jagged Fang Designs                                                                                                                                                   |
|  88 |     16.991740 |    188.669356 | Gareth Monger                                                                                                                                                         |
|  89 |    985.410316 |    512.805831 | Chloé Schmidt                                                                                                                                                         |
|  90 |    163.240875 |     23.465789 | Shyamal                                                                                                                                                               |
|  91 |    497.010146 |    702.731252 | Matt Crook                                                                                                                                                            |
|  92 |    142.394606 |    105.296729 | Gareth Monger                                                                                                                                                         |
|  93 |     38.722184 |    440.799043 | Mike Hanson                                                                                                                                                           |
|  94 |    301.447437 |    410.192040 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
|  95 |    698.636735 |    202.763882 | Ferran Sayol                                                                                                                                                          |
|  96 |    839.211082 |    335.090566 | Matt Martyniuk                                                                                                                                                        |
|  97 |    174.703105 |    479.217587 | NA                                                                                                                                                                    |
|  98 |    992.765096 |     35.498791 | Emily Willoughby                                                                                                                                                      |
|  99 |    927.692338 |    402.235033 | T. Michael Keesey                                                                                                                                                     |
| 100 |    888.161590 |    571.078606 | Sarah Werning                                                                                                                                                         |
| 101 |    979.123751 |     74.956917 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 102 |    212.362955 |    404.407067 | Scott Hartman                                                                                                                                                         |
| 103 |     40.440733 |    360.084653 | Ferran Sayol                                                                                                                                                          |
| 104 |    856.884835 |    452.420668 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 105 |    677.771992 |    325.901559 | Margot Michaud                                                                                                                                                        |
| 106 |    915.132837 |    253.803944 | Scott Hartman                                                                                                                                                         |
| 107 |    242.171176 |    159.362645 | Michelle Site                                                                                                                                                         |
| 108 |    300.031876 |     15.333421 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                                    |
| 109 |    651.931531 |     52.853814 | Tauana J. Cunha                                                                                                                                                       |
| 110 |    431.755361 |    291.454898 | Mathilde Cordellier                                                                                                                                                   |
| 111 |    875.087924 |    780.771293 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 112 |    993.497664 |    119.896472 | Zimices                                                                                                                                                               |
| 113 |    480.868743 |    203.116968 | Melissa Broussard                                                                                                                                                     |
| 114 |    224.130461 |    208.412668 | NA                                                                                                                                                                    |
| 115 |    842.305291 |    369.733298 | Scott Hartman                                                                                                                                                         |
| 116 |    169.539879 |    504.101533 | T. Michael Keesey (photo by J. M. Garg)                                                                                                                               |
| 117 |    883.693830 |    336.735125 | Zimices                                                                                                                                                               |
| 118 |    441.394940 |    138.414840 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 119 |    589.353459 |    776.788300 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                            |
| 120 |    911.744751 |    455.579926 | Chris A. Hamilton                                                                                                                                                     |
| 121 |    952.330724 |    675.340215 | L. Shyamal                                                                                                                                                            |
| 122 |   1008.736276 |    369.058755 | Trond R. Oskars                                                                                                                                                       |
| 123 |     21.492351 |    715.118770 | Matt Crook                                                                                                                                                            |
| 124 |    881.336914 |    410.592334 | Harold N Eyster                                                                                                                                                       |
| 125 |    775.310780 |    313.817269 | Matt Crook                                                                                                                                                            |
| 126 |    801.691809 |    572.509983 | Mathew Wedel                                                                                                                                                          |
| 127 |    927.935200 |    642.562926 | NA                                                                                                                                                                    |
| 128 |    623.481872 |     93.085924 | Lukasiniho                                                                                                                                                            |
| 129 |    284.150644 |    775.202565 | Dave Angelini                                                                                                                                                         |
| 130 |     33.999701 |    666.109443 | FunkMonk                                                                                                                                                              |
| 131 |     95.052808 |    109.541060 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 132 |    815.847377 |    530.168622 | Scott Hartman                                                                                                                                                         |
| 133 |    103.364892 |    388.773742 | NA                                                                                                                                                                    |
| 134 |    141.437783 |    684.829387 | Mathew Wedel                                                                                                                                                          |
| 135 |    407.696615 |    219.838027 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 136 |    602.175134 |    148.706952 | Christoph Schomburg                                                                                                                                                   |
| 137 |    351.947702 |    458.941193 | Zimices                                                                                                                                                               |
| 138 |    951.501731 |    782.245249 | Chris huh                                                                                                                                                             |
| 139 |    467.773045 |     68.851276 | Matt Crook                                                                                                                                                            |
| 140 |    345.044487 |     22.659832 | Ferran Sayol                                                                                                                                                          |
| 141 |    929.116884 |    228.288779 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 142 |    139.218882 |    758.266585 | Zimices                                                                                                                                                               |
| 143 |    251.394328 |    715.811216 | Zimices                                                                                                                                                               |
| 144 |    346.095872 |     95.738177 | Tasman Dixon                                                                                                                                                          |
| 145 |    856.919076 |    224.812432 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                    |
| 146 |    468.343244 |     92.663618 | Matt Crook                                                                                                                                                            |
| 147 |    705.537463 |    343.404059 | Lauren Anderson                                                                                                                                                       |
| 148 |    619.584760 |    576.813171 | Melissa Broussard                                                                                                                                                     |
| 149 |    667.466570 |    224.316920 | Smokeybjb                                                                                                                                                             |
| 150 |    606.456944 |     17.964892 | L. Shyamal                                                                                                                                                            |
| 151 |    254.146689 |    745.157544 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                            |
| 152 |    260.771680 |    530.064120 | Katie S. Collins                                                                                                                                                      |
| 153 |    738.710754 |    382.098558 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 154 |    150.309003 |    265.200235 | Ferran Sayol                                                                                                                                                          |
| 155 |     59.848885 |    186.510028 | Noah Schlottman, photo by Gustav Paulay for Moorea Biocode                                                                                                            |
| 156 |    669.149445 |    495.916743 | Gareth Monger                                                                                                                                                         |
| 157 |    102.307194 |     11.317345 | Gareth Monger                                                                                                                                                         |
| 158 |    573.719523 |    603.883369 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 159 |    983.598581 |    791.388839 | Scott Hartman                                                                                                                                                         |
| 160 |    376.987613 |    380.566050 | Christoph Schomburg                                                                                                                                                   |
| 161 |    633.245257 |    487.125398 | Paul O. Lewis                                                                                                                                                         |
| 162 |    215.974440 |    634.105641 | Maxime Dahirel                                                                                                                                                        |
| 163 |    425.473348 |    685.795724 | Melissa Broussard                                                                                                                                                     |
| 164 |    755.564212 |    535.487728 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 165 |    834.055453 |    734.137570 | Steven Traver                                                                                                                                                         |
| 166 |    644.431771 |    597.475950 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                    |
| 167 |    269.845953 |      8.368185 | Beth Reinke                                                                                                                                                           |
| 168 |    774.097588 |    407.788080 | Becky Barnes                                                                                                                                                          |
| 169 |    484.579753 |    567.030752 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 170 |    957.061723 |    544.496315 | FunkMonk                                                                                                                                                              |
| 171 |    693.758297 |     54.141519 | Anthony Caravaggi                                                                                                                                                     |
| 172 |    657.174297 |     82.508557 | Chris huh                                                                                                                                                             |
| 173 |    466.637158 |    313.528267 | Mattia Menchetti                                                                                                                                                      |
| 174 |    102.857856 |    220.317303 | Tasman Dixon                                                                                                                                                          |
| 175 |    442.941124 |     68.835920 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 176 |    343.983842 |    206.987401 | Kai R. Caspar                                                                                                                                                         |
| 177 |    167.221159 |     78.718499 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
| 178 |    548.042334 |    260.116082 | Yan Wong                                                                                                                                                              |
| 179 |    489.008083 |    145.528683 | Gareth Monger                                                                                                                                                         |
| 180 |    783.128981 |    147.599341 | Kent Elson Sorgon                                                                                                                                                     |
| 181 |    961.539932 |    295.868184 | NA                                                                                                                                                                    |
| 182 |    403.724345 |    339.916299 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 183 |    203.641860 |    158.918188 | Kamil S. Jaron                                                                                                                                                        |
| 184 |    508.439196 |    719.651416 | Margot Michaud                                                                                                                                                        |
| 185 |    592.128079 |    577.594301 | Zimices                                                                                                                                                               |
| 186 |    421.497556 |    244.304962 | Sarah Werning                                                                                                                                                         |
| 187 |    951.253807 |    376.436700 | Matt Crook                                                                                                                                                            |
| 188 |    957.937869 |    714.841650 | Mark Miller                                                                                                                                                           |
| 189 |    513.407285 |     59.987567 | Zimices                                                                                                                                                               |
| 190 |    938.374969 |    622.247976 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 191 |    235.287604 |    370.444365 | Tracy A. Heath                                                                                                                                                        |
| 192 |     67.694754 |    123.504732 | Ricardo Araújo                                                                                                                                                        |
| 193 |    618.029387 |    635.017867 | FunkMonk                                                                                                                                                              |
| 194 |     19.664838 |    135.506849 | Michelle Site                                                                                                                                                         |
| 195 |    437.795217 |     26.232059 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 196 |    766.113308 |    688.919558 | Ricardo Araújo                                                                                                                                                        |
| 197 |    685.388847 |    769.660916 | Matt Crook                                                                                                                                                            |
| 198 |    700.942514 |    243.337782 | Tasman Dixon                                                                                                                                                          |
| 199 |    991.680057 |    730.752572 | Mo Hassan                                                                                                                                                             |
| 200 |    196.886153 |    124.412345 | Tasman Dixon                                                                                                                                                          |
| 201 |    539.597310 |    326.266937 | Tasman Dixon                                                                                                                                                          |
| 202 |    183.658191 |    656.621587 | Sean McCann                                                                                                                                                           |
| 203 |    692.947501 |    349.846079 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                                     |
| 204 |    615.749378 |    125.047923 | NA                                                                                                                                                                    |
| 205 |    828.821037 |    582.571673 | Francisco Manuel Blanco (vectorized by T. Michael Keesey)                                                                                                             |
| 206 |    968.679816 |     81.790975 | Julio Garza                                                                                                                                                           |
| 207 |    995.748301 |    340.829552 | Margot Michaud                                                                                                                                                        |
| 208 |    756.333296 |     21.309929 | Kelly                                                                                                                                                                 |
| 209 |     65.858348 |    762.143942 | Iain Reid                                                                                                                                                             |
| 210 |     28.259155 |    742.453449 | Dean Schnabel                                                                                                                                                         |
| 211 |    159.692355 |    736.252100 | Chris huh                                                                                                                                                             |
| 212 |    380.694189 |     65.839078 | Iain Reid                                                                                                                                                             |
| 213 |    543.017654 |    769.293121 | Matt Crook                                                                                                                                                            |
| 214 |    426.865144 |    577.155407 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                  |
| 215 |    785.856601 |     17.174011 | Matt Crook                                                                                                                                                            |
| 216 |    478.452506 |    388.066682 | Tasman Dixon                                                                                                                                                          |
| 217 |   1010.384128 |    689.166323 | Gareth Monger                                                                                                                                                         |
| 218 |    855.431898 |    208.926394 | Emily Willoughby                                                                                                                                                      |
| 219 |    826.669705 |    627.149021 | Zimices                                                                                                                                                               |
| 220 |    386.916423 |    328.888240 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 221 |    113.231706 |    761.104230 | Tracy A. Heath                                                                                                                                                        |
| 222 |    483.563930 |    122.540415 | NA                                                                                                                                                                    |
| 223 |    544.190241 |    612.740982 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                    |
| 224 |    866.066484 |    741.477660 | Zimices                                                                                                                                                               |
| 225 |    817.722006 |    121.896757 | Christoph Schomburg                                                                                                                                                   |
| 226 |    157.504168 |    782.506928 | Beth Reinke                                                                                                                                                           |
| 227 |    882.976372 |    370.498808 | Tracy A. Heath                                                                                                                                                        |
| 228 |     50.560715 |    230.917848 | Chris huh                                                                                                                                                             |
| 229 |    652.961933 |    794.567739 | Xavier Giroux-Bougard                                                                                                                                                 |
| 230 |    582.173886 |    496.376989 | Tracy A. Heath                                                                                                                                                        |
| 231 |      8.962843 |     60.278727 | T. Michael Keesey                                                                                                                                                     |
| 232 |    834.072051 |    262.466035 | T. Michael Keesey                                                                                                                                                     |
| 233 |    812.478091 |    164.660213 | Ferran Sayol                                                                                                                                                          |
| 234 |    521.341555 |    415.729462 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 235 |    664.007777 |    353.969295 | Tauana J. Cunha                                                                                                                                                       |
| 236 |    324.817004 |    117.130882 | Cesar Julian                                                                                                                                                          |
| 237 |    365.470718 |    174.229652 | Birgit Lang                                                                                                                                                           |
| 238 |    769.628698 |    497.724917 | Gareth Monger                                                                                                                                                         |
| 239 |    121.227248 |    412.724942 | Zimices                                                                                                                                                               |
| 240 |    267.411224 |    593.329632 | C. Camilo Julián-Caballero                                                                                                                                            |
| 241 |    982.492454 |    367.856207 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                    |
| 242 |    801.494484 |    477.933380 | Zimices                                                                                                                                                               |
| 243 |    879.012100 |    307.437940 | Rebecca Groom                                                                                                                                                         |
| 244 |    134.025055 |    792.497175 | Scott Hartman                                                                                                                                                         |
| 245 |    194.133507 |    503.265068 | T. Michael Keesey                                                                                                                                                     |
| 246 |    498.489806 |    785.576739 | Zimices                                                                                                                                                               |
| 247 |    841.829660 |    750.060583 | Michael Scroggie                                                                                                                                                      |
| 248 |    806.880183 |    670.609713 | Richard Ruggiero, vectorized by Zimices                                                                                                                               |
| 249 |    814.845161 |    716.109444 | Matt Crook                                                                                                                                                            |
| 250 |    112.088783 |    241.373289 | Tasman Dixon                                                                                                                                                          |
| 251 |    310.291235 |    529.165844 | Zimices                                                                                                                                                               |
| 252 |     97.116918 |    207.775256 | NA                                                                                                                                                                    |
| 253 |    229.135009 |    121.777794 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
| 254 |    980.950458 |     16.495699 | Maija Karala                                                                                                                                                          |
| 255 |    165.827553 |    346.379591 | Steven Traver                                                                                                                                                         |
| 256 |    622.043808 |     39.163709 | NA                                                                                                                                                                    |
| 257 |     89.827123 |     36.836916 | Zimices                                                                                                                                                               |
| 258 |    222.884055 |    181.246232 | Collin Gross                                                                                                                                                          |
| 259 |    880.089420 |    106.091994 | CNZdenek                                                                                                                                                              |
| 260 |    651.821368 |    620.609514 | Armin Reindl                                                                                                                                                          |
| 261 |    790.812920 |    713.386401 | Anthony Caravaggi                                                                                                                                                     |
| 262 |    254.954322 |    788.805523 | Tasman Dixon                                                                                                                                                          |
| 263 |    948.616876 |     92.536182 | Rafael Maia                                                                                                                                                           |
| 264 |    452.286708 |    698.575983 | Joanna Wolfe                                                                                                                                                          |
| 265 |    359.986552 |    486.548670 | Steven Traver                                                                                                                                                         |
| 266 |    942.454305 |     19.970185 | Christoph Schomburg                                                                                                                                                   |
| 267 |    649.879190 |    102.390160 | NA                                                                                                                                                                    |
| 268 |    223.122778 |    601.747352 | Margot Michaud                                                                                                                                                        |
| 269 |    962.178134 |    124.552883 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 270 |    154.913638 |    707.237365 | Becky Barnes                                                                                                                                                          |
| 271 |    298.102375 |    181.905236 | Margot Michaud                                                                                                                                                        |
| 272 |    386.432420 |    356.124339 | Chris huh                                                                                                                                                             |
| 273 |    503.820175 |    378.119355 | Beth Reinke                                                                                                                                                           |
| 274 |    399.817870 |     78.695046 | Tyler Greenfield                                                                                                                                                      |
| 275 |    260.862347 |    600.431602 | New York Zoological Society                                                                                                                                           |
| 276 |    128.125912 |    473.982803 | Zimices                                                                                                                                                               |
| 277 |    656.579049 |    392.792652 | Andreas Trepte (vectorized by T. Michael Keesey)                                                                                                                      |
| 278 |    433.742803 |    268.819955 | Birgit Lang                                                                                                                                                           |
| 279 |    540.395679 |    621.003470 | Geoff Shaw                                                                                                                                                            |
| 280 |    635.750465 |    436.503353 | Jiekun He                                                                                                                                                             |
| 281 |    334.184570 |    129.808241 | C. Camilo Julián-Caballero                                                                                                                                            |
| 282 |    953.895574 |    105.799985 | Sarah Werning                                                                                                                                                         |
| 283 |    336.683162 |    789.981371 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                          |
| 284 |    334.576458 |    584.520706 | Gareth Monger                                                                                                                                                         |
| 285 |    201.594864 |      9.621188 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 286 |    437.516081 |    397.917500 | Zimices                                                                                                                                                               |
| 287 |    607.034351 |    284.356411 | DW Bapst (modified from Bulman, 1970)                                                                                                                                 |
| 288 |    765.832749 |    442.008582 | Gareth Monger                                                                                                                                                         |
| 289 |    984.873851 |    619.329284 | T. Michael Keesey (after Joseph Wolf)                                                                                                                                 |
| 290 |    742.166977 |     45.768119 | Steven Traver                                                                                                                                                         |
| 291 |    999.589980 |    475.726007 | Anthony Caravaggi                                                                                                                                                     |
| 292 |    580.060444 |    794.496879 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 293 |    768.882258 |     45.907814 | Jaime Headden                                                                                                                                                         |
| 294 |    867.960891 |    383.216120 | Scott Hartman, modified by T. Michael Keesey                                                                                                                          |
| 295 |    630.314601 |    149.688142 | Aleksey Nagovitsyn (vectorized by T. Michael Keesey)                                                                                                                  |
| 296 |    524.364909 |    565.229289 | Oscar Sanisidro                                                                                                                                                       |
| 297 |    955.290410 |    274.387370 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 298 |    805.536837 |    189.099927 | C. Camilo Julián-Caballero                                                                                                                                            |
| 299 |    225.378779 |    556.053267 | Ingo Braasch                                                                                                                                                          |
| 300 |    814.011117 |    136.513297 | Matt Crook                                                                                                                                                            |
| 301 |   1012.114208 |    149.495120 | Mali’o Kodis, drawing by Manvir Singh                                                                                                                                 |
| 302 |    728.782810 |    478.365733 | Matt Crook                                                                                                                                                            |
| 303 |    696.480205 |    503.178058 | Chris huh                                                                                                                                                             |
| 304 |    360.568356 |    721.123244 | Chris huh                                                                                                                                                             |
| 305 |    454.351932 |    576.219407 | Scott Hartman                                                                                                                                                         |
| 306 |    293.412428 |    195.722364 | Matt Crook                                                                                                                                                            |
| 307 |    870.653226 |    724.337516 | Zimices                                                                                                                                                               |
| 308 |    831.989323 |    158.169271 | Matt Crook                                                                                                                                                            |
| 309 |    176.414213 |    360.254552 | Matt Crook                                                                                                                                                            |
| 310 |    235.314372 |    564.569156 | Tasman Dixon                                                                                                                                                          |
| 311 |    134.395788 |    427.745141 | Margot Michaud                                                                                                                                                        |
| 312 |    394.793630 |      8.099801 | Chloé Schmidt                                                                                                                                                         |
| 313 |    315.307974 |    774.504909 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 314 |    507.104630 |    307.418492 | NA                                                                                                                                                                    |
| 315 |     17.201946 |    390.257978 | Collin Gross                                                                                                                                                          |
| 316 |    926.965714 |    559.033446 | Chris huh                                                                                                                                                             |
| 317 |    809.997418 |    511.944674 | Beth Reinke                                                                                                                                                           |
| 318 |    983.624614 |    716.985552 | Margot Michaud                                                                                                                                                        |
| 319 |    817.940772 |     17.930509 | Mark Miller                                                                                                                                                           |
| 320 |    796.623824 |    694.143974 | Chris huh                                                                                                                                                             |
| 321 |    625.980878 |    644.780291 | Chris huh                                                                                                                                                             |
| 322 |    640.992245 |    286.582182 | Jagged Fang Designs                                                                                                                                                   |
| 323 |    853.525299 |    317.558941 | T. Michael Keesey                                                                                                                                                     |
| 324 |    581.574193 |    726.515823 | NA                                                                                                                                                                    |
| 325 |    704.868008 |    783.265662 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 326 |    498.175045 |    675.830507 | JCGiron                                                                                                                                                               |
| 327 |    553.549694 |    678.758612 | Matt Crook                                                                                                                                                            |
| 328 |    147.199846 |    460.665007 | Ingo Braasch                                                                                                                                                          |
| 329 |    921.095688 |    213.529422 | Zimices                                                                                                                                                               |
| 330 |    535.651116 |    245.065461 | Alex Slavenko                                                                                                                                                         |
| 331 |    941.115968 |    591.281245 | Gareth Monger                                                                                                                                                         |
| 332 |    942.982678 |    238.062283 | Emily Willoughby                                                                                                                                                      |
| 333 |    141.331966 |      6.208877 | T. Michael Keesey                                                                                                                                                     |
| 334 |    329.264086 |    567.163430 | Steven Traver                                                                                                                                                         |
| 335 |    381.052120 |    498.900324 | Gareth Monger                                                                                                                                                         |
| 336 |    409.994294 |    407.431728 | Margot Michaud                                                                                                                                                        |
| 337 |    840.072712 |    520.126142 | Matt Martyniuk (modified by Serenchia)                                                                                                                                |
| 338 |    406.868686 |    664.261359 | Ferran Sayol                                                                                                                                                          |
| 339 |     93.404175 |    492.006876 | Jagged Fang Designs                                                                                                                                                   |
| 340 |    397.772034 |    192.289224 | Frank Denota                                                                                                                                                          |
| 341 |    140.315427 |    135.796941 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                       |
| 342 |    576.104061 |    152.367141 | Katie S. Collins                                                                                                                                                      |
| 343 |    774.674159 |    795.288757 | Jagged Fang Designs                                                                                                                                                   |
| 344 |    473.854648 |     42.760384 | Zimices                                                                                                                                                               |
| 345 |    995.571862 |    550.208646 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 346 |    909.751955 |    197.179312 | Matt Crook                                                                                                                                                            |
| 347 |   1008.338447 |    597.641605 | NA                                                                                                                                                                    |
| 348 |    372.113502 |    452.672196 | Manabu Bessho-Uehara                                                                                                                                                  |
| 349 |    549.663111 |    173.186161 | NA                                                                                                                                                                    |
| 350 |    442.739519 |    791.712628 | Emily Willoughby                                                                                                                                                      |
| 351 |     61.722277 |    456.399204 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 352 |    863.267716 |    256.203155 | Zimices                                                                                                                                                               |
| 353 |    961.454142 |      5.673643 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 354 |    792.055174 |    590.173605 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 355 |     21.257634 |    642.375405 | Carlos Cano-Barbacil                                                                                                                                                  |
| 356 |    759.924118 |    696.382744 | Julio Garza                                                                                                                                                           |
| 357 |    491.043687 |    745.574377 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 358 |    518.129519 |    711.962157 | Meliponicultor Itaymbere                                                                                                                                              |
| 359 |    811.915968 |    781.577032 | Scott Hartman                                                                                                                                                         |
| 360 |    440.439809 |    684.665345 | Chris huh                                                                                                                                                             |
| 361 |    932.545523 |     52.025028 | Gareth Monger                                                                                                                                                         |
| 362 |    343.455688 |    393.101453 | T. Michael Keesey                                                                                                                                                     |
| 363 |    135.093473 |    398.052154 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 364 |    724.927611 |    327.051033 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 365 |    821.609605 |    274.334427 | Jagged Fang Designs                                                                                                                                                   |
| 366 |     69.582776 |    105.790558 | NA                                                                                                                                                                    |
| 367 |    116.380198 |    405.147859 | Chris huh                                                                                                                                                             |
| 368 |    756.023184 |    711.619869 | Jagged Fang Designs                                                                                                                                                   |
| 369 |    436.176283 |    310.987393 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 370 |    393.237198 |    316.262185 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                        |
| 371 |    334.612020 |    431.130810 | Gareth Monger                                                                                                                                                         |
| 372 |    256.733362 |    580.853543 | NA                                                                                                                                                                    |
| 373 |    834.512437 |    183.755259 | Christoph Schomburg                                                                                                                                                   |
| 374 |    870.501795 |    636.999808 | Scott Hartman                                                                                                                                                         |
| 375 |    976.621877 |    689.327341 | Scott Hartman                                                                                                                                                         |
| 376 |     10.187401 |     20.860601 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                                        |
| 377 |    284.450816 |    523.927187 | Gareth Monger                                                                                                                                                         |
| 378 |    219.138119 |     15.067745 | Smokeybjb                                                                                                                                                             |
| 379 |    862.883853 |    620.267570 | Margot Michaud                                                                                                                                                        |
| 380 |    329.366625 |    108.510011 | xgirouxb                                                                                                                                                              |
| 381 |    779.889096 |    510.299713 | Milton Tan                                                                                                                                                            |
| 382 |    674.225275 |    580.215613 | Zimices                                                                                                                                                               |
| 383 |    768.219900 |    392.783858 | Steven Traver                                                                                                                                                         |
| 384 |    409.564978 |    577.409709 | Yan Wong                                                                                                                                                              |
| 385 |    884.650455 |    465.650851 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                                   |
| 386 |    328.914481 |     40.079111 | Isaure Scavezzoni                                                                                                                                                     |
| 387 |    436.078646 |     97.856304 | Gareth Monger                                                                                                                                                         |
| 388 |     74.893870 |    286.298854 | Chris huh                                                                                                                                                             |
| 389 |    899.567600 |    620.948661 | Jagged Fang Designs                                                                                                                                                   |
| 390 |    632.319140 |    177.469656 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                                     |
| 391 |    879.208399 |    391.989135 | Collin Gross                                                                                                                                                          |
| 392 |    511.998879 |    189.118465 | Jaime Headden                                                                                                                                                         |
| 393 |    807.968580 |    348.703463 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 394 |    811.345789 |    401.899890 | C. Camilo Julián-Caballero                                                                                                                                            |
| 395 |    706.956634 |    289.983340 | Filip em                                                                                                                                                              |
| 396 |    216.191778 |     49.157940 | Christoph Schomburg                                                                                                                                                   |
| 397 |     67.231334 |     17.749506 | Mike Keesey (vectorization) and Vaibhavcho (photography)                                                                                                              |
| 398 |    724.828014 |    790.540370 | Zimices                                                                                                                                                               |
| 399 |    859.838680 |    197.627314 | Zachary Quigley                                                                                                                                                       |
| 400 |   1015.978703 |     84.796922 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 401 |   1014.907647 |    533.944848 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                  |
| 402 |    180.112595 |    751.346112 | Amanda Katzer                                                                                                                                                         |
| 403 |    401.165085 |    395.384910 | Zimices                                                                                                                                                               |
| 404 |     65.704542 |    215.543955 | NA                                                                                                                                                                    |
| 405 |    301.337273 |     61.711181 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 406 |    152.330186 |    360.523566 | Michael Scroggie                                                                                                                                                      |
| 407 |    172.495878 |    792.935885 | Scott Hartman                                                                                                                                                         |
| 408 |    584.753820 |    331.837884 | Mattia Menchetti                                                                                                                                                      |
| 409 |    947.145973 |    645.149260 | Margot Michaud                                                                                                                                                        |
| 410 |    941.348871 |    795.474639 | Gareth Monger                                                                                                                                                         |
| 411 |    779.578520 |    334.355023 | Margot Michaud                                                                                                                                                        |
| 412 |     68.723430 |    629.818376 | Zimices                                                                                                                                                               |
| 413 |     79.773209 |    366.730991 | Raven Amos                                                                                                                                                            |
| 414 |    825.174072 |    291.558209 | Rebecca Groom                                                                                                                                                         |
| 415 |    356.151767 |    678.943802 | Jagged Fang Designs                                                                                                                                                   |
| 416 |    638.359292 |    680.957788 | Karla Martinez                                                                                                                                                        |
| 417 |    293.309027 |    583.529008 | Tracy A. Heath                                                                                                                                                        |
| 418 |    312.673610 |    705.775350 | Collin Gross                                                                                                                                                          |
| 419 |    194.702522 |    464.035204 | Jagged Fang Designs                                                                                                                                                   |
| 420 |    903.758901 |    233.058984 | Scott Hartman                                                                                                                                                         |
| 421 |    172.343594 |     93.868873 | NA                                                                                                                                                                    |
| 422 |    998.425798 |    100.576913 | Tauana J. Cunha                                                                                                                                                       |
| 423 |    567.843807 |    747.720396 | Ferran Sayol                                                                                                                                                          |
| 424 |    781.259365 |    419.525989 | Michael Scroggie                                                                                                                                                      |
| 425 |    978.698367 |    261.545844 | L. Shyamal                                                                                                                                                            |
| 426 |    418.364049 |    551.912378 | Matt Crook                                                                                                                                                            |
| 427 |     12.579507 |    604.697656 | T. Michael Keesey                                                                                                                                                     |
| 428 |     83.983400 |    482.024242 | Margot Michaud                                                                                                                                                        |
| 429 |     62.155047 |    350.069380 | T. Michael Keesey                                                                                                                                                     |
| 430 |     31.359425 |    633.473799 | Jagged Fang Designs                                                                                                                                                   |
| 431 |    547.062834 |    665.190420 | Matt Crook                                                                                                                                                            |
| 432 |    639.905534 |    415.071766 | Gareth Monger                                                                                                                                                         |
| 433 |   1008.652227 |     28.882222 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                      |
| 434 |    537.242593 |    751.614293 | T. Michael Keesey                                                                                                                                                     |
| 435 |    301.016049 |    598.323398 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 436 |    849.359552 |    471.088851 | Tyler McCraney                                                                                                                                                        |
| 437 |    438.946720 |     91.573545 | DW Bapst (Modified from Bulman, 1964)                                                                                                                                 |
| 438 |   1007.056652 |    756.921806 | Beth Reinke                                                                                                                                                           |
| 439 |    116.738298 |    375.602097 | Scott Hartman                                                                                                                                                         |
| 440 |    106.511483 |    581.061017 | Mark Hofstetter (vectorized by T. Michael Keesey)                                                                                                                     |
| 441 |    198.511807 |     69.894207 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                    |
| 442 |     61.551906 |    186.464231 | Michael Scroggie                                                                                                                                                      |
| 443 |    236.282054 |    388.044363 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 444 |    471.652807 |    400.010400 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 445 |    825.589101 |    222.334612 | L. Shyamal                                                                                                                                                            |
| 446 |    159.798573 |    249.560278 | CNZdenek                                                                                                                                                              |
| 447 |    950.371130 |    315.130301 | Gareth Monger                                                                                                                                                         |
| 448 |    574.114404 |    618.883072 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                                      |
| 449 |    816.128083 |    457.812537 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                           |
| 450 |    798.524692 |     39.485596 | Jaime Headden                                                                                                                                                         |
| 451 |    911.446154 |    107.076308 | Gareth Monger                                                                                                                                                         |
| 452 |    352.013053 |    248.630422 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 453 |    829.603188 |    114.240600 | Scott Hartman                                                                                                                                                         |
| 454 |    101.794746 |    541.405986 | Chris huh                                                                                                                                                             |
| 455 |    266.279270 |    413.429323 | Jagged Fang Designs                                                                                                                                                   |
| 456 |    341.397962 |    750.636434 | Matt Crook                                                                                                                                                            |
| 457 |    865.390451 |    350.529199 | Ferran Sayol                                                                                                                                                          |
| 458 |    735.229540 |      8.224321 | Steven Traver                                                                                                                                                         |
| 459 |    411.797172 |     70.041555 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
| 460 |    628.526829 |    556.561619 | Scott Hartman                                                                                                                                                         |
| 461 |   1017.029397 |    641.176041 | Maxime Dahirel                                                                                                                                                        |
| 462 |     11.485405 |    764.740018 | Dean Schnabel                                                                                                                                                         |
| 463 |     33.016134 |    537.745838 | Cagri Cevrim                                                                                                                                                          |
| 464 |    452.881715 |    459.050778 | Josefine Bohr Brask                                                                                                                                                   |
| 465 |    965.239300 |     45.557697 | Siobhon Egan                                                                                                                                                          |
| 466 |    363.101044 |    158.473925 | NA                                                                                                                                                                    |
| 467 |    534.500188 |     37.574565 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 468 |     88.389953 |    307.517594 | NA                                                                                                                                                                    |
| 469 |    845.211323 |     51.977261 | Emily Willoughby                                                                                                                                                      |
| 470 |    117.032682 |    457.373197 | Nobu Tamura                                                                                                                                                           |
| 471 |    109.028230 |    167.694883 | Jack Mayer Wood                                                                                                                                                       |
| 472 |    494.361966 |    326.529030 | Scott Hartman                                                                                                                                                         |
| 473 |     70.232225 |    741.374476 | DW Bapst (Modified from Bulman, 1964)                                                                                                                                 |
| 474 |    105.380144 |    791.937320 | Andrew A. Farke                                                                                                                                                       |
| 475 |    517.386416 |    656.775748 | Michelle Site                                                                                                                                                         |
| 476 |    508.432824 |    406.441095 | Jagged Fang Designs                                                                                                                                                   |
| 477 |    794.338707 |    126.953628 | NA                                                                                                                                                                    |
| 478 |    625.424674 |     71.941740 | Ferran Sayol                                                                                                                                                          |
| 479 |    661.169935 |    482.017733 | Gareth Monger                                                                                                                                                         |
| 480 |    349.788045 |    593.366718 | T. Michael Keesey                                                                                                                                                     |
| 481 |    251.906734 |    206.955819 | Matt Crook                                                                                                                                                            |
| 482 |    286.965070 |     19.803260 | Ferran Sayol                                                                                                                                                          |
| 483 |    332.886315 |    222.251414 | T. Tischler                                                                                                                                                           |
| 484 |    816.861942 |    214.302662 | Tasman Dixon                                                                                                                                                          |
| 485 |    899.331418 |    430.614333 | Scott Hartman                                                                                                                                                         |
| 486 |    931.029746 |    131.925340 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                           |
| 487 |    639.306478 |    396.318357 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                  |
| 488 |    100.426599 |    627.380126 | Hans Hillewaert (photo) and T. Michael Keesey (vectorization)                                                                                                         |
| 489 |    925.428853 |    447.403539 | Ferran Sayol                                                                                                                                                          |
| 490 |    900.384668 |    445.336738 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 491 |    628.806196 |    540.350903 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 492 |     15.448849 |    222.833886 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 493 |    622.954443 |    789.546189 | Roberto Díaz Sibaja                                                                                                                                                   |
| 494 |     31.595295 |     74.677948 | Gareth Monger                                                                                                                                                         |
| 495 |    518.401642 |      8.295004 | Craig Dylke                                                                                                                                                           |
| 496 |    830.216727 |    769.374052 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 497 |    731.684248 |    219.198044 | Zachary Quigley                                                                                                                                                       |
| 498 |    611.387621 |     33.144186 | Scott Hartman                                                                                                                                                         |
| 499 |    180.167722 |    415.872548 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 500 |    914.662962 |    477.609118 | Margot Michaud                                                                                                                                                        |
| 501 |      8.349762 |    370.454506 | Gareth Monger                                                                                                                                                         |
| 502 |    326.350868 |    668.002632 | Chris huh                                                                                                                                                             |
| 503 |    107.387725 |    360.108865 | Mathew Wedel                                                                                                                                                          |
| 504 |    655.019662 |    210.900752 | FunkMonk                                                                                                                                                              |
| 505 |    184.596789 |    136.890349 | Milton Tan                                                                                                                                                            |
| 506 |    938.970295 |    567.751029 | Collin Gross                                                                                                                                                          |
| 507 |    807.236630 |    631.353941 | Gareth Monger                                                                                                                                                         |
| 508 |    376.324478 |     59.707305 | Gareth Monger                                                                                                                                                         |
| 509 |    216.061993 |    691.578126 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 510 |    467.187772 |    765.339644 | Matt Crook                                                                                                                                                            |
| 511 |     45.687578 |    735.270652 | Lauren Anderson                                                                                                                                                       |
| 512 |    760.518462 |    251.802331 | T. Michael Keesey (after C. De Muizon)                                                                                                                                |
| 513 |    985.413671 |    303.407698 | Armin Reindl                                                                                                                                                          |
| 514 |    449.970722 |    473.554746 | Zimices                                                                                                                                                               |
| 515 |    245.998967 |    641.997039 | Margot Michaud                                                                                                                                                        |
| 516 |    888.416257 |    515.435334 | NA                                                                                                                                                                    |
