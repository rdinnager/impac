
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

Margot Michaud, Matt Crook, Markus A. Grohme, Jon Hill (Photo by
Benjamint444:
<http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>), Gareth
Monger, Catherine Yasuda, T. Michael Keesey, Felix Vaux, Ray Simpson
(vectorized by T. Michael Keesey), Michelle Site, Jan A. Venter, Herbert
H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael
Keesey), Sarah Werning, Joanna Wolfe, Zimices / Julián Bayona, Dean
Schnabel, Andy Wilson, Philippe Janvier (vectorized by T. Michael
Keesey), Scott Hartman, Emily Willoughby, Dmitry Bogdanov (modified by
T. Michael Keesey), Tasman Dixon, Steven Traver, Harold N Eyster, Ferran
Sayol, JCGiron, Zimices, Jimmy Bernot, Jagged Fang Designs, Javier
Luque, Christina N. Hodson, Chris huh, Dmitry Bogdanov (vectorized by T.
Michael Keesey), Alexandre Vong, Henry Fairfield Osborn, vectorized by
Zimices, Karl Ragnar Gjertsen (vectorized by T. Michael Keesey), Felix
Vaux and Steven A. Trewick, C. Camilo Julián-Caballero, Michael
Scroggie, T. Michael Keesey (photo by J. M. Garg), Christoph Schomburg,
Mathieu Basille, M Kolmann, Haplochromis (vectorized by T. Michael
Keesey), Armin Reindl, Obsidian Soul (vectorized by T. Michael Keesey),
Joseph J. W. Sertich, Mark A. Loewen, Beth Reinke, Sherman Foote Denton
(illustration, 1897) and Timothy J. Bartley (silhouette), Michael P.
Taylor, Birgit Szabo, Diego Fontaneto, Elisabeth A. Herniou, Chiara
Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy
G. Barraclough (vectorized by T. Michael Keesey), L. Shyamal, CNZdenek,
Jose Carlos Arenas-Monroy, Roberto Díaz Sibaja, Gabriela Palomo-Munoz,
Scott Reid, Dmitry Bogdanov, Chris A. Hamilton, Darius Nau, Karkemish
(vectorized by T. Michael Keesey), Becky Barnes, Caleb M. Brown, Nobu
Tamura, vectorized by Zimices, Ieuan Jones, Melissa Broussard, U.S.
National Park Service (vectorized by William Gearty), Renato de Carvalho
Ferreira, annaleeblysse, Noah Schlottman, photo by Antonio Guillén,
Birgit Lang, Noah Schlottman, photo by Casey Dunn, David Sim
(photograph) and T. Michael Keesey (vectorization), T. Michael Keesey
(after Monika Betley), Jack Mayer Wood, J Levin W (illustration) and T.
Michael Keesey (vectorization), Julien Louys, Kanchi Nanjo, Ludwik
Gąsiorowski, Ignacio Contreras, Jaime Headden, Collin Gross, Carlos
Cano-Barbacil, Yan Wong, Ernst Haeckel (vectorized by T. Michael
Keesey), Alexander Schmidt-Lebuhn, Chloé Schmidt, James R. Spotila and
Ray Chatterji, Mathieu Pélissié, Tom Tarrant (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Riccardo Percudani, Kai R.
Caspar, Ghedo and T. Michael Keesey, Frank Förster, E. D. Cope (modified
by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel), Kamil S.
Jaron, Ghedoghedo, . Original drawing by M. Antón, published in Montoya
and Morales 1984. Vectorized by O. Sanisidro, MPF (vectorized by T.
Michael Keesey), Smokeybjb, Xavier Giroux-Bougard, Lukasiniho, Robbie
Cada (vectorized by T. Michael Keesey), Oscar Sanisidro, Jessica Anne
Miller, Zachary Quigley, Tony Ayling (vectorized by T. Michael Keesey),
Nobu Tamura (modified by T. Michael Keesey), Christine Axon, Pete
Buchholz, Andrew A. Farke, Michele Tobias, C. W. Nash (illustration) and
Timothy J. Bartley (silhouette), Mali’o Kodis, image from the
Smithsonian Institution, Sam Droege (photography) and T. Michael Keesey
(vectorization), Katie S. Collins, Mathew Wedel, Mark Witton, David Orr,
Steven Coombs, Lisa Byrne, Peileppe, Renata F. Martins, Fcb981
(vectorized by T. Michael Keesey), Douglas Brown (modified by T. Michael
Keesey), Matt Dempsey, Milton Tan, Noah Schlottman, photo from Moorea
Biocode, James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo
Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael
Keesey), Saguaro Pictures (source photo) and T. Michael Keesey, Robbie
N. Cada (vectorized by T. Michael Keesey), Stuart Humphries, Ben
Liebeskind, Gopal Murali, Duane Raver (vectorized by T. Michael Keesey),
H. F. O. March (vectorized by T. Michael Keesey), Michael Day, Frank
Förster (based on a picture by Jerry Kirkhart; modified by T. Michael
Keesey), Conty, Mali’o Kodis, photograph by P. Funch and R.M.
Kristensen, Tauana J. Cunha, Michael B. H. (vectorized by T. Michael
Keesey), Falconaumanni and T. Michael Keesey, Shyamal, Yan Wong from
drawing by Joseph Smit, Blanco et al., 2014, vectorized by Zimices,
xgirouxb, FunkMonk, Nobu Tamura (vectorized by T. Michael Keesey),
Baheerathan Murugavel, Robert Bruce Horsfall, from W.B. Scott’s 1912 “A
History of Land Mammals in the Western Hemisphere”, Daniel Jaron, Alex
Slavenko, Skye McDavid, Andrew Farke and Joseph Sertich, Robbie N. Cada
(modified by T. Michael Keesey), Charles R. Knight, vectorized by
Zimices, Iain Reid, Nina Skinner, SecretJellyMan - from Mason McNair,
Erika Schumacher, Karla Martinez, Tony Ayling, Jaime Headden, modified
by T. Michael Keesey, Joe Schneid (vectorized by T. Michael Keesey),
Ghedo (vectorized by T. Michael Keesey), Apokryltaros (vectorized by T.
Michael Keesey), Original drawing by Dmitry Bogdanov, vectorized by
Roberto Díaz Sibaja, Mattia Menchetti, Renato Santos, Hans Hillewaert
(vectorized by T. Michael Keesey), Raven Amos, Tyler Greenfield, Martien
Brand (original photo), Renato Santos (vector silhouette), Mason McNair,
Christian A. Masnaghetti, Julio Garza, Bruno C. Vellutini, Keith Murdock
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Fernando Carezzano, Eric Moody, Pranav Iyer (grey ideas), Danny
Cicchetti (vectorized by T. Michael Keesey), FunkMonk \[Michael B.H.\]
(modified by T. Michael Keesey), Marmelad, DW Bapst (Modified from
Bulman, 1964), Henry Lydecker

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    834.058785 |    302.403401 | Margot Michaud                                                                                                                                                        |
|   2 |    380.564544 |    593.808555 | Matt Crook                                                                                                                                                            |
|   3 |    939.542937 |    316.360285 | Markus A. Grohme                                                                                                                                                      |
|   4 |    561.345830 |    636.513207 | Jon Hill (Photo by Benjamint444: <http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>)                                                                           |
|   5 |    104.808527 |    669.128894 | Gareth Monger                                                                                                                                                         |
|   6 |    221.035814 |    387.861441 | Matt Crook                                                                                                                                                            |
|   7 |    726.878439 |    161.150892 | Catherine Yasuda                                                                                                                                                      |
|   8 |    480.500954 |    224.767438 | T. Michael Keesey                                                                                                                                                     |
|   9 |    805.095472 |    465.150985 | Gareth Monger                                                                                                                                                         |
|  10 |     63.623891 |    398.736997 | Felix Vaux                                                                                                                                                            |
|  11 |    543.299541 |    508.116734 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
|  12 |    447.196436 |    514.908780 | Michelle Site                                                                                                                                                         |
|  13 |    792.361366 |    210.645669 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
|  14 |    888.360476 |     80.051569 | Sarah Werning                                                                                                                                                         |
|  15 |    804.412874 |    680.169687 | Joanna Wolfe                                                                                                                                                          |
|  16 |    163.832264 |    746.253655 | Zimices / Julián Bayona                                                                                                                                               |
|  17 |    272.469509 |    669.495139 | Dean Schnabel                                                                                                                                                         |
|  18 |    107.462967 |     68.898568 | Andy Wilson                                                                                                                                                           |
|  19 |    469.356383 |    750.219491 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                    |
|  20 |    480.145655 |    118.528419 | Scott Hartman                                                                                                                                                         |
|  21 |    701.090339 |    484.528330 | Emily Willoughby                                                                                                                                                      |
|  22 |    935.069430 |    385.128430 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                       |
|  23 |    543.013626 |    322.319150 | Tasman Dixon                                                                                                                                                          |
|  24 |    196.980998 |    234.746542 | Steven Traver                                                                                                                                                         |
|  25 |    686.159711 |    648.730630 | Harold N Eyster                                                                                                                                                       |
|  26 |    211.529158 |    567.074720 | Matt Crook                                                                                                                                                            |
|  27 |    904.542454 |    644.260521 | Ferran Sayol                                                                                                                                                          |
|  28 |    376.895155 |    297.797495 | JCGiron                                                                                                                                                               |
|  29 |    599.466135 |    107.852295 | NA                                                                                                                                                                    |
|  30 |    308.921975 |    294.028581 | NA                                                                                                                                                                    |
|  31 |    109.561366 |    526.303566 | Zimices                                                                                                                                                               |
|  32 |     37.887638 |    101.697155 | NA                                                                                                                                                                    |
|  33 |    112.245709 |    331.056173 | Jimmy Bernot                                                                                                                                                          |
|  34 |    595.465017 |     35.936143 | Steven Traver                                                                                                                                                         |
|  35 |    413.831903 |    706.856404 | Jagged Fang Designs                                                                                                                                                   |
|  36 |    357.013930 |    490.949663 | Javier Luque                                                                                                                                                          |
|  37 |    935.380405 |    192.219233 | Jagged Fang Designs                                                                                                                                                   |
|  38 |    338.163284 |    154.903937 | Zimices                                                                                                                                                               |
|  39 |    275.021123 |     89.106138 | NA                                                                                                                                                                    |
|  40 |    703.437594 |    553.409004 | Gareth Monger                                                                                                                                                         |
|  41 |     48.612630 |    207.667476 | Christina N. Hodson                                                                                                                                                   |
|  42 |     11.804082 |    590.785259 | Gareth Monger                                                                                                                                                         |
|  43 |    920.475089 |    725.707754 | Chris huh                                                                                                                                                             |
|  44 |    334.454741 |    753.968456 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  45 |    474.631661 |    649.627716 | Alexandre Vong                                                                                                                                                        |
|  46 |    951.138326 |    476.148876 | Markus A. Grohme                                                                                                                                                      |
|  47 |    662.784904 |    764.173901 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
|  48 |    773.816292 |     41.974567 | Michelle Site                                                                                                                                                         |
|  49 |    729.075547 |     67.044022 | Markus A. Grohme                                                                                                                                                      |
|  50 |     89.213363 |    579.205385 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                                |
|  51 |    137.888380 |    464.678910 | Felix Vaux and Steven A. Trewick                                                                                                                                      |
|  52 |    597.121124 |    191.522328 | Scott Hartman                                                                                                                                                         |
|  53 |    205.827016 |     35.405963 | Jagged Fang Designs                                                                                                                                                   |
|  54 |    374.354194 |     42.355011 | Zimices                                                                                                                                                               |
|  55 |    802.930584 |    773.741339 | Jagged Fang Designs                                                                                                                                                   |
|  56 |    220.689828 |    505.482289 | NA                                                                                                                                                                    |
|  57 |    977.592479 |    578.785000 | Gareth Monger                                                                                                                                                         |
|  58 |    839.345095 |    132.419342 | Gareth Monger                                                                                                                                                         |
|  59 |    651.862922 |    715.629663 | C. Camilo Julián-Caballero                                                                                                                                            |
|  60 |    573.919419 |    242.704191 | Steven Traver                                                                                                                                                         |
|  61 |    189.537610 |    130.488333 | Jagged Fang Designs                                                                                                                                                   |
|  62 |    807.764360 |    601.748949 | Scott Hartman                                                                                                                                                         |
|  63 |    386.830392 |    212.784987 | Markus A. Grohme                                                                                                                                                      |
|  64 |    913.274720 |    566.368055 | Michael Scroggie                                                                                                                                                      |
|  65 |    703.688647 |    419.705042 | T. Michael Keesey (photo by J. M. Garg)                                                                                                                               |
|  66 |    221.348740 |    314.887078 | Christoph Schomburg                                                                                                                                                   |
|  67 |     74.448296 |    766.972995 | Mathieu Basille                                                                                                                                                       |
|  68 |    365.640117 |    421.419079 | Jagged Fang Designs                                                                                                                                                   |
|  69 |     95.289838 |     24.845156 | M Kolmann                                                                                                                                                             |
|  70 |    329.187366 |    368.140019 | Markus A. Grohme                                                                                                                                                      |
|  71 |    559.116139 |    749.716390 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
|  72 |    931.150114 |    222.303600 | Margot Michaud                                                                                                                                                        |
|  73 |    719.552323 |    122.563515 | Gareth Monger                                                                                                                                                         |
|  74 |    637.999198 |    167.864413 | Armin Reindl                                                                                                                                                          |
|  75 |    338.363252 |    708.698799 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
|  76 |    972.990006 |    341.780935 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                  |
|  77 |    253.857067 |    754.249460 | Jagged Fang Designs                                                                                                                                                   |
|  78 |    409.693065 |     10.783677 | Chris huh                                                                                                                                                             |
|  79 |    970.942812 |    170.080679 | NA                                                                                                                                                                    |
|  80 |    508.211610 |    450.198586 | Jagged Fang Designs                                                                                                                                                   |
|  81 |    992.221324 |     99.696499 | Steven Traver                                                                                                                                                         |
|  82 |    482.692331 |     56.124531 | Beth Reinke                                                                                                                                                           |
|  83 |    574.437752 |    785.307668 | Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)                                                                                         |
|  84 |    938.395269 |    424.388146 | Gareth Monger                                                                                                                                                         |
|  85 |    275.363029 |    458.104994 | NA                                                                                                                                                                    |
|  86 |    541.440081 |    549.878199 | Jagged Fang Designs                                                                                                                                                   |
|  87 |    635.954495 |    443.662745 | Michael P. Taylor                                                                                                                                                     |
|  88 |    993.499166 |    275.387263 | Markus A. Grohme                                                                                                                                                      |
|  89 |    688.001098 |    227.327077 | Birgit Szabo                                                                                                                                                          |
|  90 |    889.980485 |    444.762417 | Andy Wilson                                                                                                                                                           |
|  91 |    684.059260 |     33.089943 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                       |
|  92 |    633.114377 |    561.067425 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
|  93 |    956.593514 |    405.030609 | L. Shyamal                                                                                                                                                            |
|  94 |    732.301529 |    268.861332 | CNZdenek                                                                                                                                                              |
|  95 |    156.966646 |    694.749428 | Jose Carlos Arenas-Monroy                                                                                                                                             |
|  96 |    439.098239 |    151.716321 | NA                                                                                                                                                                    |
|  97 |    260.677858 |    621.505912 | Roberto Díaz Sibaja                                                                                                                                                   |
|  98 |     52.966240 |    304.769461 | Markus A. Grohme                                                                                                                                                      |
|  99 |    911.471139 |    771.126459 | Markus A. Grohme                                                                                                                                                      |
| 100 |    250.562632 |    715.791131 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 101 |    798.108106 |    541.725337 | Scott Reid                                                                                                                                                            |
| 102 |    729.053053 |     88.253810 | Dmitry Bogdanov                                                                                                                                                       |
| 103 |    491.526389 |    560.180060 | NA                                                                                                                                                                    |
| 104 |     96.146581 |    123.299433 | Chris A. Hamilton                                                                                                                                                     |
| 105 |    307.683884 |    196.906228 | Darius Nau                                                                                                                                                            |
| 106 |    290.340953 |    686.450606 | Karkemish (vectorized by T. Michael Keesey)                                                                                                                           |
| 107 |    755.042215 |    545.428734 | Becky Barnes                                                                                                                                                          |
| 108 |    520.237488 |    165.600658 | Caleb M. Brown                                                                                                                                                        |
| 109 |     79.232348 |    587.094998 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 110 |    349.707929 |     94.583164 | Gareth Monger                                                                                                                                                         |
| 111 |    935.625186 |     27.601515 | Ieuan Jones                                                                                                                                                           |
| 112 |    751.677072 |    322.589717 | Melissa Broussard                                                                                                                                                     |
| 113 |     51.087342 |    283.210266 | Michelle Site                                                                                                                                                         |
| 114 |    894.496912 |    526.779151 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 115 |    441.779687 |    274.204574 | Andy Wilson                                                                                                                                                           |
| 116 |    970.281586 |    755.549453 | Scott Hartman                                                                                                                                                         |
| 117 |    880.454100 |    312.939505 | U.S. National Park Service (vectorized by William Gearty)                                                                                                             |
| 118 |    470.019046 |    580.409869 | Zimices                                                                                                                                                               |
| 119 |    618.076353 |    463.687105 | Renato de Carvalho Ferreira                                                                                                                                           |
| 120 |    828.088780 |    574.769779 | NA                                                                                                                                                                    |
| 121 |    810.387244 |    183.966189 | annaleeblysse                                                                                                                                                         |
| 122 |    537.165561 |    704.271172 | Noah Schlottman, photo by Antonio Guillén                                                                                                                             |
| 123 |    661.581888 |    428.667225 | Birgit Lang                                                                                                                                                           |
| 124 |   1002.813838 |     49.401193 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 125 |    337.844615 |    118.583857 | Zimices                                                                                                                                                               |
| 126 |    905.726676 |    690.399003 | Markus A. Grohme                                                                                                                                                      |
| 127 |    220.695033 |    787.686585 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                          |
| 128 |    859.464127 |    357.243340 | Joanna Wolfe                                                                                                                                                          |
| 129 |    295.217526 |    569.023021 | Gareth Monger                                                                                                                                                         |
| 130 |    778.874485 |    177.735175 | Markus A. Grohme                                                                                                                                                      |
| 131 |    268.114014 |     45.546977 | Zimices                                                                                                                                                               |
| 132 |    918.096162 |    152.444520 | Chris huh                                                                                                                                                             |
| 133 |    262.842237 |    145.134336 | Jimmy Bernot                                                                                                                                                          |
| 134 |    714.009506 |    735.543940 | Scott Hartman                                                                                                                                                         |
| 135 |    277.643964 |    410.813083 | Scott Hartman                                                                                                                                                         |
| 136 |    935.629556 |    261.254012 | Gareth Monger                                                                                                                                                         |
| 137 |    983.533348 |    140.118517 | T. Michael Keesey (after Monika Betley)                                                                                                                               |
| 138 |    224.336352 |    270.559791 | Jack Mayer Wood                                                                                                                                                       |
| 139 |    184.561870 |    638.746455 | J Levin W (illustration) and T. Michael Keesey (vectorization)                                                                                                        |
| 140 |    202.729045 |    168.012756 | Tasman Dixon                                                                                                                                                          |
| 141 |    738.014137 |    762.833114 | Julien Louys                                                                                                                                                          |
| 142 |    375.957527 |    763.733952 | Tasman Dixon                                                                                                                                                          |
| 143 |    978.164809 |    368.258039 | Ferran Sayol                                                                                                                                                          |
| 144 |   1007.740952 |    313.539768 | Gareth Monger                                                                                                                                                         |
| 145 |    365.284376 |    668.635806 | Kanchi Nanjo                                                                                                                                                          |
| 146 |     85.020961 |    209.569324 | Birgit Lang                                                                                                                                                           |
| 147 |    152.423389 |    353.985848 | Birgit Lang                                                                                                                                                           |
| 148 |     56.216729 |    476.302690 | Ludwik Gąsiorowski                                                                                                                                                    |
| 149 |    843.720354 |    343.577468 | Joanna Wolfe                                                                                                                                                          |
| 150 |    781.822727 |     84.420802 | Ignacio Contreras                                                                                                                                                     |
| 151 |    610.035858 |    575.519023 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 152 |    200.820052 |    695.882448 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 153 |    205.862481 |    117.026929 | Jaime Headden                                                                                                                                                         |
| 154 |    961.839175 |    679.943853 | Andy Wilson                                                                                                                                                           |
| 155 |   1002.301375 |    707.522895 | Collin Gross                                                                                                                                                          |
| 156 |    510.886767 |    467.293167 | Christoph Schomburg                                                                                                                                                   |
| 157 |    652.255312 |    613.875170 | Carlos Cano-Barbacil                                                                                                                                                  |
| 158 |   1004.105621 |    255.116609 | Yan Wong                                                                                                                                                              |
| 159 |    870.424992 |    190.937720 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 160 |    751.893925 |    361.979887 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 161 |    408.196811 |    457.159920 | Chloé Schmidt                                                                                                                                                         |
| 162 |    446.782257 |    678.320424 | Ferran Sayol                                                                                                                                                          |
| 163 |    725.979225 |    590.077811 | Carlos Cano-Barbacil                                                                                                                                                  |
| 164 |    209.585465 |    336.358728 | NA                                                                                                                                                                    |
| 165 |     27.812884 |    281.726391 | Alexandre Vong                                                                                                                                                        |
| 166 |    100.243854 |    187.981215 | Carlos Cano-Barbacil                                                                                                                                                  |
| 167 |    208.200944 |    674.801862 | Matt Crook                                                                                                                                                            |
| 168 |     74.368190 |    633.968656 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 169 |     48.992822 |    730.339182 | Matt Crook                                                                                                                                                            |
| 170 |    906.377876 |    243.232532 | Mathieu Pélissié                                                                                                                                                      |
| 171 |    758.048002 |    622.980308 | Andy Wilson                                                                                                                                                           |
| 172 |    446.141074 |    235.511069 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 173 |    522.740298 |    140.085700 | Riccardo Percudani                                                                                                                                                    |
| 174 |    404.375712 |    679.066956 | Gareth Monger                                                                                                                                                         |
| 175 |    948.166196 |    496.962246 | Steven Traver                                                                                                                                                         |
| 176 |    132.149970 |    147.481762 | U.S. National Park Service (vectorized by William Gearty)                                                                                                             |
| 177 |    406.235951 |    105.672335 | Kai R. Caspar                                                                                                                                                         |
| 178 |    246.414258 |    185.532555 | Yan Wong                                                                                                                                                              |
| 179 |     27.109489 |    362.384392 | Gareth Monger                                                                                                                                                         |
| 180 |    375.208143 |     89.815297 | CNZdenek                                                                                                                                                              |
| 181 |    439.762341 |    173.461967 | Ghedo and T. Michael Keesey                                                                                                                                           |
| 182 |    957.460699 |    666.467284 | Margot Michaud                                                                                                                                                        |
| 183 |    861.660215 |    715.238992 | Markus A. Grohme                                                                                                                                                      |
| 184 |    508.907227 |    415.423949 | Chris huh                                                                                                                                                             |
| 185 |    958.799354 |    247.005731 | NA                                                                                                                                                                    |
| 186 |   1003.397816 |    445.453189 | Birgit Lang                                                                                                                                                           |
| 187 |    722.815165 |    699.697846 | Frank Förster                                                                                                                                                         |
| 188 |    523.170306 |    201.597048 | Zimices                                                                                                                                                               |
| 189 |    439.172814 |    417.029885 | Jimmy Bernot                                                                                                                                                          |
| 190 |    224.467722 |    126.900649 | NA                                                                                                                                                                    |
| 191 |    312.191851 |    657.743773 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                                      |
| 192 |    125.777850 |    418.120779 | Kamil S. Jaron                                                                                                                                                        |
| 193 |    893.733899 |    169.104230 | M Kolmann                                                                                                                                                             |
| 194 |    784.208210 |    571.333657 | Zimices                                                                                                                                                               |
| 195 |    517.829635 |    787.760552 | Ferran Sayol                                                                                                                                                          |
| 196 |     29.941343 |    426.678778 | T. Michael Keesey                                                                                                                                                     |
| 197 |     85.322067 |    475.958545 | Sarah Werning                                                                                                                                                         |
| 198 |    891.060913 |    785.985793 | Ghedoghedo                                                                                                                                                            |
| 199 |    918.481106 |    279.539746 | . Original drawing by M. Antón, published in Montoya and Morales 1984. Vectorized by O. Sanisidro                                                                     |
| 200 |    183.147614 |     92.686828 | MPF (vectorized by T. Michael Keesey)                                                                                                                                 |
| 201 |    833.772322 |     17.600546 | Scott Hartman                                                                                                                                                         |
| 202 |    749.546817 |    640.978199 | Kamil S. Jaron                                                                                                                                                        |
| 203 |    856.837694 |    730.552062 | Steven Traver                                                                                                                                                         |
| 204 |    482.216986 |     23.860517 | Steven Traver                                                                                                                                                         |
| 205 |    181.406677 |    517.669343 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 206 |    612.849462 |    699.951165 | Jagged Fang Designs                                                                                                                                                   |
| 207 |     16.838887 |    693.417489 | NA                                                                                                                                                                    |
| 208 |    294.765636 |    520.165647 | Smokeybjb                                                                                                                                                             |
| 209 |    155.163391 |    416.149631 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 210 |   1015.276223 |     26.417941 | Xavier Giroux-Bougard                                                                                                                                                 |
| 211 |    876.560314 |    700.760331 | Lukasiniho                                                                                                                                                            |
| 212 |    103.875153 |    157.639106 | NA                                                                                                                                                                    |
| 213 |    179.997021 |    295.048618 | Jagged Fang Designs                                                                                                                                                   |
| 214 |     80.067968 |    262.777565 | Tasman Dixon                                                                                                                                                          |
| 215 |    637.575129 |    220.633012 | Robbie Cada (vectorized by T. Michael Keesey)                                                                                                                         |
| 216 |    164.136674 |    169.520172 | Steven Traver                                                                                                                                                         |
| 217 |    629.705085 |     12.352286 | Sarah Werning                                                                                                                                                         |
| 218 |    552.462701 |    139.458145 | Oscar Sanisidro                                                                                                                                                       |
| 219 |     21.963132 |    126.827499 | T. Michael Keesey                                                                                                                                                     |
| 220 |    278.969901 |    534.179238 | Jessica Anne Miller                                                                                                                                                   |
| 221 |    453.232475 |    603.752701 | Collin Gross                                                                                                                                                          |
| 222 |    968.270807 |    644.876942 | Margot Michaud                                                                                                                                                        |
| 223 |    413.325566 |    186.979775 | Margot Michaud                                                                                                                                                        |
| 224 |    209.480816 |    294.808816 | Zachary Quigley                                                                                                                                                       |
| 225 |     31.667780 |    459.194771 | Ferran Sayol                                                                                                                                                          |
| 226 |    263.552906 |     14.210259 | Zachary Quigley                                                                                                                                                       |
| 227 |    293.189245 |    212.280503 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 228 |    723.240990 |    372.530295 | Steven Traver                                                                                                                                                         |
| 229 |   1003.733541 |    630.036971 | NA                                                                                                                                                                    |
| 230 |    455.758423 |     32.791147 | NA                                                                                                                                                                    |
| 231 |    404.436232 |     80.619262 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 232 |    447.961956 |    626.732845 | Dean Schnabel                                                                                                                                                         |
| 233 |    313.888543 |    463.327075 | L. Shyamal                                                                                                                                                            |
| 234 |    518.739586 |     85.897730 | Christine Axon                                                                                                                                                        |
| 235 |    809.568418 |    269.730825 | NA                                                                                                                                                                    |
| 236 |    422.886684 |    320.663153 | Scott Hartman                                                                                                                                                         |
| 237 |    748.781998 |    607.835526 | Pete Buchholz                                                                                                                                                         |
| 238 |    958.483821 |     88.415270 | Ferran Sayol                                                                                                                                                          |
| 239 |   1005.316876 |    766.228512 | Zimices                                                                                                                                                               |
| 240 |    665.582445 |    458.507233 | Steven Traver                                                                                                                                                         |
| 241 |    172.713787 |      7.539257 | Margot Michaud                                                                                                                                                        |
| 242 |    969.499170 |    775.677902 | Andrew A. Farke                                                                                                                                                       |
| 243 |    933.032539 |      9.701235 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 244 |    990.816735 |     18.061223 | Matt Crook                                                                                                                                                            |
| 245 |    833.587000 |    163.584454 | Margot Michaud                                                                                                                                                        |
| 246 |    297.913438 |    171.482882 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 247 |    947.179152 |    125.877141 | Zimices                                                                                                                                                               |
| 248 |    161.284771 |    560.478538 | Michele Tobias                                                                                                                                                        |
| 249 |    537.244971 |    563.749720 | Christoph Schomburg                                                                                                                                                   |
| 250 |     32.925178 |    525.046311 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                         |
| 251 |     45.929437 |    501.258049 | C. Camilo Julián-Caballero                                                                                                                                            |
| 252 |    221.935759 |    473.728623 | Matt Crook                                                                                                                                                            |
| 253 |    283.588481 |    491.537397 | U.S. National Park Service (vectorized by William Gearty)                                                                                                             |
| 254 |    253.903882 |    692.825747 | Andy Wilson                                                                                                                                                           |
| 255 |    110.644845 |    565.155613 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 256 |     74.483119 |    749.621116 | Margot Michaud                                                                                                                                                        |
| 257 |     37.643014 |    129.836512 | T. Michael Keesey                                                                                                                                                     |
| 258 |    824.764419 |    100.948341 | Zimices                                                                                                                                                               |
| 259 |    727.259157 |    224.388224 | Markus A. Grohme                                                                                                                                                      |
| 260 |    302.090994 |     53.731221 | Zimices                                                                                                                                                               |
| 261 |   1009.231726 |     84.108469 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                  |
| 262 |    336.865175 |    694.781882 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 263 |    570.690529 |    764.457733 | NA                                                                                                                                                                    |
| 264 |    650.945387 |    495.068308 | Katie S. Collins                                                                                                                                                      |
| 265 |    571.130864 |    453.498097 | Steven Traver                                                                                                                                                         |
| 266 |    830.853893 |    384.049284 | Carlos Cano-Barbacil                                                                                                                                                  |
| 267 |    987.627708 |    501.597727 | Margot Michaud                                                                                                                                                        |
| 268 |    922.192384 |    138.710567 | Scott Hartman                                                                                                                                                         |
| 269 |    667.818735 |    596.610772 | Mathew Wedel                                                                                                                                                          |
| 270 |    995.244210 |    422.007604 | Matt Crook                                                                                                                                                            |
| 271 |    955.122895 |    701.317821 | Jagged Fang Designs                                                                                                                                                   |
| 272 |    732.978419 |     16.927988 | Scott Hartman                                                                                                                                                         |
| 273 |    525.154972 |    432.016494 | Mark Witton                                                                                                                                                           |
| 274 |    410.866215 |    139.918970 | David Orr                                                                                                                                                             |
| 275 |    837.133867 |    122.893058 | Steven Coombs                                                                                                                                                         |
| 276 |    872.724877 |    227.816407 | Steven Traver                                                                                                                                                         |
| 277 |    889.477609 |    364.366914 | Michelle Site                                                                                                                                                         |
| 278 |     21.108386 |    327.602210 | Lisa Byrne                                                                                                                                                            |
| 279 |    746.624806 |    694.918955 | T. Michael Keesey                                                                                                                                                     |
| 280 |     20.910361 |    509.955534 | Peileppe                                                                                                                                                              |
| 281 |    485.854143 |     83.326317 | Sarah Werning                                                                                                                                                         |
| 282 |    655.144819 |    699.463042 | Zimices                                                                                                                                                               |
| 283 |    199.597167 |     72.750667 | Zimices                                                                                                                                                               |
| 284 |    422.927143 |    665.265509 | Michael Scroggie                                                                                                                                                      |
| 285 |     10.937872 |    736.663578 | Yan Wong                                                                                                                                                              |
| 286 |    873.357702 |     17.822308 | Felix Vaux                                                                                                                                                            |
| 287 |     31.406496 |    664.191642 | Margot Michaud                                                                                                                                                        |
| 288 |   1003.413810 |    664.082475 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 289 |    683.316553 |    120.518778 | Zimices                                                                                                                                                               |
| 290 |    598.026413 |    551.232413 | Ferran Sayol                                                                                                                                                          |
| 291 |    385.362650 |    190.993769 | Renata F. Martins                                                                                                                                                     |
| 292 |    336.542474 |    230.909252 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 293 |   1005.401420 |    128.572864 | Fcb981 (vectorized by T. Michael Keesey)                                                                                                                              |
| 294 |    206.856409 |      7.223761 | NA                                                                                                                                                                    |
| 295 |    294.544041 |    615.664866 | Scott Hartman                                                                                                                                                         |
| 296 |   1008.872667 |    210.970363 | Jaime Headden                                                                                                                                                         |
| 297 |    409.229232 |    265.166344 | Birgit Lang                                                                                                                                                           |
| 298 |    777.864664 |    515.807421 | Ignacio Contreras                                                                                                                                                     |
| 299 |     34.078960 |     31.792774 | Andrew A. Farke                                                                                                                                                       |
| 300 |    532.254960 |    185.982642 | Douglas Brown (modified by T. Michael Keesey)                                                                                                                         |
| 301 |    517.465852 |    769.834342 | Matt Dempsey                                                                                                                                                          |
| 302 |   1010.420632 |    587.182995 | Birgit Lang                                                                                                                                                           |
| 303 |    777.244660 |     22.178095 | T. Michael Keesey                                                                                                                                                     |
| 304 |    290.089179 |    603.723230 | Steven Traver                                                                                                                                                         |
| 305 |    146.253506 |    231.729012 | Milton Tan                                                                                                                                                            |
| 306 |    636.719165 |    195.903559 | Andy Wilson                                                                                                                                                           |
| 307 |    155.856095 |    263.275169 | T. Michael Keesey                                                                                                                                                     |
| 308 |    286.933830 |    390.359275 | Margot Michaud                                                                                                                                                        |
| 309 |    220.344393 |    638.731028 | Noah Schlottman, photo from Moorea Biocode                                                                                                                            |
| 310 |    380.531721 |    438.003743 | Emily Willoughby                                                                                                                                                      |
| 311 |     77.943108 |    725.615984 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 312 |    632.945228 |    478.364209 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                                 |
| 313 |    425.953064 |    713.856444 | Felix Vaux                                                                                                                                                            |
| 314 |    847.006717 |    199.131934 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 315 |    749.748672 |    718.729981 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 316 |    738.709072 |    151.136962 | T. Michael Keesey                                                                                                                                                     |
| 317 |   1008.987298 |    225.135653 | NA                                                                                                                                                                    |
| 318 |     40.615971 |      8.416143 | Stuart Humphries                                                                                                                                                      |
| 319 |    642.393974 |    520.809502 | Alexandre Vong                                                                                                                                                        |
| 320 |    544.994412 |     86.610393 | Ben Liebeskind                                                                                                                                                        |
| 321 |    176.084058 |    540.783451 | Jimmy Bernot                                                                                                                                                          |
| 322 |   1013.558488 |    345.275585 | Dean Schnabel                                                                                                                                                         |
| 323 |    760.146227 |    347.036863 | Gopal Murali                                                                                                                                                          |
| 324 |    528.544550 |    245.682370 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 325 |   1004.184627 |    689.339662 | Zimices                                                                                                                                                               |
| 326 |    606.221254 |    727.237757 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                         |
| 327 |    653.581434 |    387.863077 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                      |
| 328 |    301.038455 |    633.582044 | Michael Day                                                                                                                                                           |
| 329 |    131.758266 |    257.228500 | Frank Förster (based on a picture by Jerry Kirkhart; modified by T. Michael Keesey)                                                                                   |
| 330 |    861.832792 |    628.510930 | Scott Hartman                                                                                                                                                         |
| 331 |     42.270793 |    633.469075 | Conty                                                                                                                                                                 |
| 332 |    333.815154 |    524.879212 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                              |
| 333 |    103.992967 |    494.647105 | Roberto Díaz Sibaja                                                                                                                                                   |
| 334 |    948.271127 |    778.436578 | NA                                                                                                                                                                    |
| 335 |    771.873736 |    294.716673 | Ignacio Contreras                                                                                                                                                     |
| 336 |    936.647772 |     95.577770 | Tauana J. Cunha                                                                                                                                                       |
| 337 |      9.768496 |    272.746777 | Joanna Wolfe                                                                                                                                                          |
| 338 |    292.298103 |     32.814701 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 339 |     65.277605 |    325.983791 | Matt Crook                                                                                                                                                            |
| 340 |    345.329105 |    311.116620 | Ferran Sayol                                                                                                                                                          |
| 341 |    175.833476 |    678.222167 | Scott Hartman                                                                                                                                                         |
| 342 |    305.914664 |    222.623415 | Scott Hartman                                                                                                                                                         |
| 343 |    106.700790 |    714.494083 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                       |
| 344 |    202.268674 |    455.315233 | Joanna Wolfe                                                                                                                                                          |
| 345 |    367.585902 |    791.019597 | Zimices                                                                                                                                                               |
| 346 |    311.202624 |    433.810318 | NA                                                                                                                                                                    |
| 347 |    680.853406 |    430.474833 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 348 |   1008.770760 |    192.788242 | Gareth Monger                                                                                                                                                         |
| 349 |    563.109892 |    728.021732 | Shyamal                                                                                                                                                               |
| 350 |    882.586160 |    493.639921 | Yan Wong from drawing by Joseph Smit                                                                                                                                  |
| 351 |    108.337909 |    402.581735 | Margot Michaud                                                                                                                                                        |
| 352 |     10.657277 |    412.603140 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 353 |    238.693881 |    300.098292 | Christoph Schomburg                                                                                                                                                   |
| 354 |    315.298544 |    384.793939 | U.S. National Park Service (vectorized by William Gearty)                                                                                                             |
| 355 |     61.109836 |    146.326941 | Blanco et al., 2014, vectorized by Zimices                                                                                                                            |
| 356 |    891.963112 |    100.054759 | Michelle Site                                                                                                                                                         |
| 357 |    575.969079 |    497.399809 | Chris huh                                                                                                                                                             |
| 358 |     52.807377 |    123.884260 | xgirouxb                                                                                                                                                              |
| 359 |    986.957598 |    738.683652 | Christoph Schomburg                                                                                                                                                   |
| 360 |    336.068219 |    392.736263 | Margot Michaud                                                                                                                                                        |
| 361 |    365.173313 |      9.182425 | FunkMonk                                                                                                                                                              |
| 362 |     36.746800 |    104.460287 | Zimices                                                                                                                                                               |
| 363 |    387.902063 |    384.435129 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 364 |    853.995578 |    181.812339 | FunkMonk                                                                                                                                                              |
| 365 |    131.038782 |    130.623341 | Felix Vaux                                                                                                                                                            |
| 366 |    660.242438 |      9.535004 | NA                                                                                                                                                                    |
| 367 |    615.868961 |    621.217341 | Birgit Lang                                                                                                                                                           |
| 368 |    344.159432 |    259.526103 | Baheerathan Murugavel                                                                                                                                                 |
| 369 |    723.509769 |    213.315552 | Jagged Fang Designs                                                                                                                                                   |
| 370 |    721.433214 |    506.886799 | Joanna Wolfe                                                                                                                                                          |
| 371 |    837.087355 |    622.520558 | Mathieu Pélissié                                                                                                                                                      |
| 372 |    627.491914 |    425.289585 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 373 |    854.584938 |    402.776048 | Robert Bruce Horsfall, from W.B. Scott’s 1912 “A History of Land Mammals in the Western Hemisphere”                                                                   |
| 374 |     18.632163 |    487.846882 | Daniel Jaron                                                                                                                                                          |
| 375 |    830.868081 |    747.791668 | Alex Slavenko                                                                                                                                                         |
| 376 |    715.432877 |    136.169873 | T. Michael Keesey                                                                                                                                                     |
| 377 |    124.255214 |    169.971656 | Skye McDavid                                                                                                                                                          |
| 378 |    757.294213 |    745.624206 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 379 |    235.444094 |    779.183037 | Scott Hartman                                                                                                                                                         |
| 380 |    320.775176 |    543.964270 | Ferran Sayol                                                                                                                                                          |
| 381 |    387.330101 |    118.085899 | Jaime Headden                                                                                                                                                         |
| 382 |    267.290496 |    178.212542 | Andrew Farke and Joseph Sertich                                                                                                                                       |
| 383 |    734.460285 |    282.056473 | Andrew A. Farke                                                                                                                                                       |
| 384 |    292.794587 |    341.549734 | T. Michael Keesey                                                                                                                                                     |
| 385 |    186.679489 |    560.194132 | Gareth Monger                                                                                                                                                         |
| 386 |    676.690310 |     92.001454 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 387 |    204.358299 |    324.310128 | Ignacio Contreras                                                                                                                                                     |
| 388 |    142.359125 |    503.604995 | Tasman Dixon                                                                                                                                                          |
| 389 |    521.829107 |    483.249301 | Margot Michaud                                                                                                                                                        |
| 390 |    514.462001 |     69.205760 | Matt Crook                                                                                                                                                            |
| 391 |    249.100170 |    446.003398 | Kamil S. Jaron                                                                                                                                                        |
| 392 |    914.038936 |    505.461840 | Chloé Schmidt                                                                                                                                                         |
| 393 |    742.971413 |    736.597474 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
| 394 |    620.084159 |    140.790555 | Zimices                                                                                                                                                               |
| 395 |    842.388622 |    790.229118 | Charles R. Knight, vectorized by Zimices                                                                                                                              |
| 396 |    368.319752 |    746.538755 | Jagged Fang Designs                                                                                                                                                   |
| 397 |    749.079778 |    513.399929 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 398 |    251.339725 |    166.528666 | Tasman Dixon                                                                                                                                                          |
| 399 |    154.502338 |    394.846846 | Ben Liebeskind                                                                                                                                                        |
| 400 |    895.504111 |    756.717930 | Iain Reid                                                                                                                                                             |
| 401 |    243.220806 |    288.765394 | C. Camilo Julián-Caballero                                                                                                                                            |
| 402 |    950.889519 |    275.683480 | Kamil S. Jaron                                                                                                                                                        |
| 403 |    736.404628 |    781.057365 | Nina Skinner                                                                                                                                                          |
| 404 |    719.947780 |    674.374084 | Kamil S. Jaron                                                                                                                                                        |
| 405 |    135.022453 |    609.077313 | Zimices                                                                                                                                                               |
| 406 |    518.174897 |    541.946723 | Armin Reindl                                                                                                                                                          |
| 407 |    489.373463 |      2.759607 | Smokeybjb                                                                                                                                                             |
| 408 |    807.512619 |    613.268672 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 409 |    394.056550 |    783.272310 | SecretJellyMan - from Mason McNair                                                                                                                                    |
| 410 |    726.089789 |    790.974450 | Markus A. Grohme                                                                                                                                                      |
| 411 |    971.843591 |    119.457450 | Mathew Wedel                                                                                                                                                          |
| 412 |    900.482700 |     18.164715 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 413 |    729.239667 |    244.604939 | Chris huh                                                                                                                                                             |
| 414 |    968.766245 |    514.811241 | Dmitry Bogdanov                                                                                                                                                       |
| 415 |   1004.671346 |    395.350798 | Erika Schumacher                                                                                                                                                      |
| 416 |    917.170114 |    789.525585 | Birgit Lang                                                                                                                                                           |
| 417 |    818.441921 |    375.013772 | Jagged Fang Designs                                                                                                                                                   |
| 418 |    659.194703 |    541.252261 | Karla Martinez                                                                                                                                                        |
| 419 |    285.253438 |    741.608213 | Tony Ayling                                                                                                                                                           |
| 420 |   1011.783211 |    166.395820 | Emily Willoughby                                                                                                                                                      |
| 421 |    166.093033 |    384.935905 | Dean Schnabel                                                                                                                                                         |
| 422 |    174.665016 |    789.085332 | Jagged Fang Designs                                                                                                                                                   |
| 423 |     89.865155 |    549.187589 | Markus A. Grohme                                                                                                                                                      |
| 424 |    917.543547 |    680.803125 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 425 |    974.726466 |    711.210362 | T. Michael Keesey                                                                                                                                                     |
| 426 |    760.332169 |    429.733112 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                  |
| 427 |    433.079823 |    462.540582 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                         |
| 428 |    120.552211 |      9.239280 | Birgit Lang                                                                                                                                                           |
| 429 |    240.749315 |    333.299837 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                               |
| 430 |    226.629177 |    620.711183 | NA                                                                                                                                                                    |
| 431 |    273.395354 |    297.514569 | Zimices                                                                                                                                                               |
| 432 |    500.874821 |    489.574516 | Gareth Monger                                                                                                                                                         |
| 433 |    712.586204 |    466.451466 | Zimices                                                                                                                                                               |
| 434 |    268.153123 |    123.790249 | Jagged Fang Designs                                                                                                                                                   |
| 435 |    612.416685 |    669.601530 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 436 |    272.164274 |    423.758293 | NA                                                                                                                                                                    |
| 437 |    300.566673 |    719.963788 | Chris huh                                                                                                                                                             |
| 438 |    866.003288 |    438.539214 | T. Michael Keesey                                                                                                                                                     |
| 439 |    925.164933 |    178.623232 | Christoph Schomburg                                                                                                                                                   |
| 440 |    994.174804 |    514.373673 | Tasman Dixon                                                                                                                                                          |
| 441 |    697.390178 |    134.035109 | Scott Hartman                                                                                                                                                         |
| 442 |    586.348849 |    735.474709 | Milton Tan                                                                                                                                                            |
| 443 |    458.088574 |    299.431367 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 444 |    374.501872 |    352.881511 | Mattia Menchetti                                                                                                                                                      |
| 445 |    891.779911 |    288.531026 | Renato Santos                                                                                                                                                         |
| 446 |    618.452936 |    535.417039 | NA                                                                                                                                                                    |
| 447 |   1008.845776 |    617.471722 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 448 |    398.424538 |    729.714365 | Raven Amos                                                                                                                                                            |
| 449 |    558.592857 |    715.918161 | Tyler Greenfield                                                                                                                                                      |
| 450 |    418.182587 |    332.681909 | NA                                                                                                                                                                    |
| 451 |    353.070713 |    183.414697 | Matt Crook                                                                                                                                                            |
| 452 |    655.981535 |     34.498413 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 453 |    946.828761 |     13.896278 | Jagged Fang Designs                                                                                                                                                   |
| 454 |    660.673499 |    516.200595 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 455 |    568.965464 |    560.334961 | Zimices                                                                                                                                                               |
| 456 |    869.839785 |    252.198206 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                     |
| 457 |     23.051857 |    591.165541 | Mason McNair                                                                                                                                                          |
| 458 |    851.446832 |    375.431702 | Tauana J. Cunha                                                                                                                                                       |
| 459 |    217.067650 |     58.178869 | Jagged Fang Designs                                                                                                                                                   |
| 460 |     86.127984 |    174.214324 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 461 |    337.427548 |    791.638278 | Iain Reid                                                                                                                                                             |
| 462 |    950.783629 |    346.921592 | Scott Hartman                                                                                                                                                         |
| 463 |    968.590192 |    433.838674 | NA                                                                                                                                                                    |
| 464 |    114.613861 |    243.811709 | Christian A. Masnaghetti                                                                                                                                              |
| 465 |    914.666244 |    746.835424 | Tasman Dixon                                                                                                                                                          |
| 466 |    103.647838 |     92.353493 | Jagged Fang Designs                                                                                                                                                   |
| 467 |     23.785460 |    447.825165 | Julio Garza                                                                                                                                                           |
| 468 |    481.470237 |    154.282167 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 469 |   1012.673048 |    526.021874 | T. Michael Keesey                                                                                                                                                     |
| 470 |    502.546728 |    136.696202 | Bruno C. Vellutini                                                                                                                                                    |
| 471 |    461.053029 |      6.957358 | Scott Hartman                                                                                                                                                         |
| 472 |    141.953644 |    319.144086 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 473 |   1001.637440 |    718.996358 | Darius Nau                                                                                                                                                            |
| 474 |    746.084803 |    484.992075 | Sarah Werning                                                                                                                                                         |
| 475 |    369.438757 |    230.579728 | Dean Schnabel                                                                                                                                                         |
| 476 |    508.895345 |    688.633814 | Matt Crook                                                                                                                                                            |
| 477 |     36.129905 |    711.501868 | Chris huh                                                                                                                                                             |
| 478 |    750.107425 |    305.944876 | Margot Michaud                                                                                                                                                        |
| 479 |    715.018264 |    201.283036 | Markus A. Grohme                                                                                                                                                      |
| 480 |    702.941996 |    286.726210 | Jagged Fang Designs                                                                                                                                                   |
| 481 |    266.300872 |    770.341887 | Jaime Headden                                                                                                                                                         |
| 482 |    468.961196 |     52.001765 | Sarah Werning                                                                                                                                                         |
| 483 |      9.513802 |     17.750141 | Fernando Carezzano                                                                                                                                                    |
| 484 |    192.952982 |     58.297086 | Scott Hartman                                                                                                                                                         |
| 485 |     83.187547 |     12.323022 | Birgit Lang                                                                                                                                                           |
| 486 |    737.344590 |    401.596122 | Collin Gross                                                                                                                                                          |
| 487 |    455.832264 |     56.611560 | Scott Hartman                                                                                                                                                         |
| 488 |    191.653514 |    769.173431 | Kamil S. Jaron                                                                                                                                                        |
| 489 |    461.125042 |    627.626853 | NA                                                                                                                                                                    |
| 490 |    405.889263 |    419.940259 | Eric Moody                                                                                                                                                            |
| 491 |    321.218113 |    673.641966 | Chris huh                                                                                                                                                             |
| 492 |    187.174705 |    663.506322 | Ferran Sayol                                                                                                                                                          |
| 493 |    773.173220 |     97.714948 | Andy Wilson                                                                                                                                                           |
| 494 |    239.979988 |    147.996985 | Fernando Carezzano                                                                                                                                                    |
| 495 |    590.244816 |      9.183626 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 496 |    618.610659 |    789.891566 | Zimices                                                                                                                                                               |
| 497 |    770.879200 |    136.390464 | Andy Wilson                                                                                                                                                           |
| 498 |    606.170191 |    192.020795 | Tasman Dixon                                                                                                                                                          |
| 499 |    323.065461 |     62.176904 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                     |
| 500 |    913.496760 |    602.671953 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 501 |    154.442953 |     92.069892 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                             |
| 502 |    524.434551 |    264.313766 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 503 |    204.688777 |    356.889452 | Markus A. Grohme                                                                                                                                                      |
| 504 |    616.744104 |    505.022789 | Marmelad                                                                                                                                                              |
| 505 |    461.948663 |    443.098049 | Margot Michaud                                                                                                                                                        |
| 506 |    794.809197 |    169.567655 | Lukasiniho                                                                                                                                                            |
| 507 |    680.913404 |    250.100565 | Sarah Werning                                                                                                                                                         |
| 508 |    797.566327 |     61.418766 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 509 |    234.766229 |     66.908838 | NA                                                                                                                                                                    |
| 510 |    332.239416 |    638.945308 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                              |
| 511 |    552.003589 |    171.194149 | DW Bapst (Modified from Bulman, 1964)                                                                                                                                 |
| 512 |     76.398400 |    230.410941 | Henry Lydecker                                                                                                                                                        |
| 513 |    610.312106 |    483.200731 | Zimices                                                                                                                                                               |
| 514 |    132.883938 |    763.215865 | Scott Hartman                                                                                                                                                         |
| 515 |    955.349979 |    187.231115 | Gareth Monger                                                                                                                                                         |
| 516 |    922.739774 |    160.590687 | Markus A. Grohme                                                                                                                                                      |
| 517 |    410.924510 |    312.343920 | Chris huh                                                                                                                                                             |
| 518 |    924.230548 |    243.427043 | Markus A. Grohme                                                                                                                                                      |
| 519 |    237.928353 |    602.797083 | Jagged Fang Designs                                                                                                                                                   |

    #> Your tweet has been posted!
