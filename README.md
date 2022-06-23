
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

Evan-Amos (vectorized by T. Michael Keesey), Zimices, Peter Coxhead,
Tasman Dixon, Anthony Caravaggi, Yan Wong, C. Camilo Julián-Caballero,
Andy Wilson, Chuanixn Yu, Apokryltaros (vectorized by T. Michael
Keesey), Margot Michaud, Nobu Tamura, Sergio A. Muñoz-Gómez, Ferran
Sayol, Neil Kelley, DW Bapst (modified from Bulman, 1970), Diana
Pomeroy, Gabriela Palomo-Munoz, FunkMonk, Scott Hartman, Fernando
Carezzano, L. Shyamal, Melissa Broussard, T. Michael Keesey (vector) and
Stuart Halliday (photograph), Beth Reinke, Steven Coombs, Felix Vaux,
Erika Schumacher, Falconaumanni and T. Michael Keesey, Kai R. Caspar,
Gareth Monger, xgirouxb, Chris huh, Rebecca Groom, Smokeybjb (modified
by Mike Keesey), Eric Moody, T. Michael Keesey, Mathew Wedel, Caroline
Harding, MAF (vectorized by T. Michael Keesey), Markus A. Grohme, Collin
Gross, Jonathan Wells, Armin Reindl, Alexander Schmidt-Lebuhn, Robert
Bruce Horsfall (vectorized by William Gearty), Jaime Headden, Jose
Carlos Arenas-Monroy, Emily Willoughby, Birgit Lang, Rafael Maia, Dmitry
Bogdanov (vectorized by T. Michael Keesey), Jagged Fang Designs, Tony
Ayling (vectorized by T. Michael Keesey), Kamil S. Jaron, Mattia
Menchetti, Shyamal, Ignacio Contreras, Lisa Byrne, Nobu Tamura
(vectorized by T. Michael Keesey), Ellen Edmonson and Hugh Chrisp
(illustration) and Timothy J. Bartley (silhouette), FunkMonk \[Michael
B.H.\] (modified by T. Michael Keesey), Bruno C. Vellutini, Michael P.
Taylor, Hans Hillewaert (photo) and T. Michael Keesey (vectorization),
Jordan Mallon (vectorized by T. Michael Keesey), Mali’o Kodis,
photograph by Hans Hillewaert, T. Michael Keesey (after Mauricio Antón),
Noah Schlottman, photo from Casey Dunn, Nobu Tamura and T. Michael
Keesey, Francisco Manuel Blanco (vectorized by T. Michael Keesey), Cesar
Julian, Matt Crook, Lukasiniho, Noah Schlottman, photo by Reinhard Jahn,
Smokeybjb, Alexandre Vong, Maija Karala, Mali’o Kodis, image from the
Smithsonian Institution, Robert Bruce Horsfall, vectorized by Zimices,
Sean McCann, Mr E? (vectorized by T. Michael Keesey), Marie-Aimée
Allard, Roberto Díaz Sibaja, Matt Martyniuk, Lindberg (vectorized by T.
Michael Keesey), Alex Slavenko, Anna Willoughby, Michael Scroggie,
Inessa Voet, Carlos Cano-Barbacil, Yan Wong (vectorization) from 1873
illustration, Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al., T.
Michael Keesey (after Joseph Wolf), Walter Vladimir, Tracy A. Heath,
Claus Rebler, Original drawing by Dmitry Bogdanov, vectorized by Roberto
Díaz Sibaja, David Orr, Tod Robbins, NOAA (vectorized by T. Michael
Keesey), Christoph Schomburg, Xavier Giroux-Bougard, Ingo Braasch,
Danielle Alba, Michelle Site, Milton Tan, C. W. Nash (illustration) and
Timothy J. Bartley (silhouette), Ekaterina Kopeykina (vectorized by T.
Michael Keesey), Mike Hanson, Mathieu Basille, CNZdenek, Louis Ranjard,
Siobhon Egan, Dori <dori@merr.info> (source photo) and Nevit Dilmen,
Kanchi Nanjo, Mykle Hoban, Steven Traver, Jaime Chirinos (vectorized by
T. Michael Keesey), ДиБгд (vectorized by T. Michael Keesey), Karla
Martinez, Dmitry Bogdanov (modified by T. Michael Keesey), Alan Manson
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Tauana J. Cunha, T. Michael Keesey (after Masteraah), Dmitry
Bogdanov, Matt Martyniuk (modified by T. Michael Keesey), T. Michael
Keesey (after A. Y. Ivantsov), Keith Murdock (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Pete Buchholz, Kailah
Thorn & Ben King, Oscar Sanisidro, Joshua Fowler, Sharon Wegner-Larsen,
Lafage, David Sim (photograph) and T. Michael Keesey (vectorization),
Gopal Murali, Julien Louys, Sarah Werning, , Ellen Edmonson
(illustration) and Timothy J. Bartley (silhouette), Manabu
Bessho-Uehara, Lip Kee Yap (vectorized by T. Michael Keesey), Mario
Quevedo, kotik, NASA, Ramona J Heim, Dave Angelini, Scott Reid, Jake
Warner, Todd Marshall, vectorized by Zimices, Pearson Scott Foresman
(vectorized by T. Michael Keesey), Harold N Eyster, Raven Amos, Dean
Schnabel, Chris Jennings (vectorized by A. Verrière), Matt Martyniuk
(vectorized by T. Michael Keesey), Cyril Matthey-Doret, adapted from
Bernard Chaubet, Cagri Cevrim, Noah Schlottman, Myriam\_Ramirez, Conty
(vectorized by T. Michael Keesey), G. M. Woodward, Andrew A. Farke,
Robbie N. Cada (vectorized by T. Michael Keesey), Noah Schlottman, photo
by Adam G. Clause, NOAA Great Lakes Environmental Research Laboratory
(illustration) and Timothy J. Bartley (silhouette), Michael Scroggie,
from original photograph by Gary M. Stolz, USFWS (original photograph in
public domain)., Yan Wong from wikipedia drawing (PD: Pearson Scott
Foresman), DFoidl (vectorized by T. Michael Keesey), Tony Ayling,
Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey), U.S.
National Park Service (vectorized by William Gearty), DW Bapst, modified
from Figure 1 of Belanger (2011, PALAIOS)., nicubunu, Mali’o Kodis,
image from Brockhaus and Efron Encyclopedic Dictionary, Moussa Direct
Ltd. (photography) and T. Michael Keesey (vectorization), Diego
Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli,
Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by
T. Michael Keesey), Jan A. Venter, Herbert H. T. Prins, David A. Balfour
& Rob Slotow (vectorized by T. Michael Keesey), Smokeybjb (vectorized by
T. Michael Keesey), New York Zoological Society, Audrey Ely, Sherman
Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette),
Chloé Schmidt, Christine Axon, Maxime Dahirel, Caio Bernardes,
vectorized by Zimices, Matt Dempsey, Andrew R. Gehrke, Scott Hartman,
modified by T. Michael Keesey, Abraão Leite, Frank Förster, Steven
Blackwood, Haplochromis (vectorized by T. Michael Keesey), Enoch Joseph
Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Javiera Constanzo, Obsidian Soul (vectorized by T. Michael
Keesey), Stuart Humphries, Nobu Tamura (vectorized by A. Verrière), Kent
Elson Sorgon, Duane Raver (vectorized by T. Michael Keesey), Julia B
McHugh, Nobu Tamura, vectorized by Zimices

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    221.648877 |    303.470866 | Evan-Amos (vectorized by T. Michael Keesey)                                                                                                                           |
|   2 |    130.348209 |     98.064731 | Zimices                                                                                                                                                               |
|   3 |    844.532106 |    324.599065 | Peter Coxhead                                                                                                                                                         |
|   4 |    834.969211 |    543.505793 | Tasman Dixon                                                                                                                                                          |
|   5 |    533.671766 |    702.366832 | Anthony Caravaggi                                                                                                                                                     |
|   6 |    350.607900 |    575.389697 | Yan Wong                                                                                                                                                              |
|   7 |    200.196572 |    713.893662 | C. Camilo Julián-Caballero                                                                                                                                            |
|   8 |    722.563570 |    730.291458 | Andy Wilson                                                                                                                                                           |
|   9 |    157.682861 |     25.074820 | Chuanixn Yu                                                                                                                                                           |
|  10 |    926.672565 |    313.980501 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
|  11 |    899.517895 |    684.384397 | Margot Michaud                                                                                                                                                        |
|  12 |    488.445700 |     72.664005 | Nobu Tamura                                                                                                                                                           |
|  13 |    515.076249 |    259.130514 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
|  14 |    632.273016 |    461.398510 | Ferran Sayol                                                                                                                                                          |
|  15 |    640.689485 |     96.350007 | Neil Kelley                                                                                                                                                           |
|  16 |    780.960314 |    452.870702 | Zimices                                                                                                                                                               |
|  17 |    928.370104 |    481.009800 | DW Bapst (modified from Bulman, 1970)                                                                                                                                 |
|  18 |    363.334692 |    721.413146 | Diana Pomeroy                                                                                                                                                         |
|  19 |    623.595067 |    200.846823 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  20 |     70.007576 |    617.969695 | Margot Michaud                                                                                                                                                        |
|  21 |    752.900061 |    390.149057 | FunkMonk                                                                                                                                                              |
|  22 |    941.286880 |    614.984341 | Scott Hartman                                                                                                                                                         |
|  23 |    925.255940 |    107.857465 | Fernando Carezzano                                                                                                                                                    |
|  24 |    660.037927 |    308.792760 | L. Shyamal                                                                                                                                                            |
|  25 |    190.638350 |    258.901636 | Melissa Broussard                                                                                                                                                     |
|  26 |    732.029238 |    214.654168 | Chuanixn Yu                                                                                                                                                           |
|  27 |    160.207127 |    332.443061 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                           |
|  28 |    170.936397 |    526.473840 | Beth Reinke                                                                                                                                                           |
|  29 |    476.635735 |    445.996890 | Steven Coombs                                                                                                                                                         |
|  30 |    988.638843 |    486.728933 | Felix Vaux                                                                                                                                                            |
|  31 |    496.509437 |    500.553797 | Erika Schumacher                                                                                                                                                      |
|  32 |    460.890710 |    637.052235 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
|  33 |    836.920708 |     54.808410 | Margot Michaud                                                                                                                                                        |
|  34 |    641.975937 |    610.063764 | NA                                                                                                                                                                    |
|  35 |    247.345777 |     98.203461 | Ferran Sayol                                                                                                                                                          |
|  36 |    218.534698 |    609.081439 | Kai R. Caspar                                                                                                                                                         |
|  37 |    307.868751 |    155.033102 | Gareth Monger                                                                                                                                                         |
|  38 |    923.745842 |    764.382204 | xgirouxb                                                                                                                                                              |
|  39 |    413.904975 |    535.973727 | Chris huh                                                                                                                                                             |
|  40 |    777.100859 |    648.774159 | Rebecca Groom                                                                                                                                                         |
|  41 |    319.771510 |    483.090157 | Smokeybjb (modified by Mike Keesey)                                                                                                                                   |
|  42 |     68.009442 |    691.919840 | Eric Moody                                                                                                                                                            |
|  43 |    644.016554 |    396.771662 | Gareth Monger                                                                                                                                                         |
|  44 |    615.766711 |    531.202108 | Scott Hartman                                                                                                                                                         |
|  45 |     68.843765 |    290.490996 | T. Michael Keesey                                                                                                                                                     |
|  46 |     67.678254 |    774.782356 | Mathew Wedel                                                                                                                                                          |
|  47 |    697.528493 |    573.335097 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                               |
|  48 |    480.546654 |    144.056035 | C. Camilo Julián-Caballero                                                                                                                                            |
|  49 |    492.254897 |    387.466227 | Markus A. Grohme                                                                                                                                                      |
|  50 |    246.362790 |    247.590715 | Collin Gross                                                                                                                                                          |
|  51 |     45.327789 |     90.952625 | NA                                                                                                                                                                    |
|  52 |    763.943637 |    121.399292 | Jonathan Wells                                                                                                                                                        |
|  53 |    936.081019 |    178.049562 | Armin Reindl                                                                                                                                                          |
|  54 |     70.775550 |    179.960468 | Zimices                                                                                                                                                               |
|  55 |    100.389725 |    246.029163 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|  56 |    958.610415 |     30.609890 | Robert Bruce Horsfall (vectorized by William Gearty)                                                                                                                  |
|  57 |    265.621494 |    506.283666 | T. Michael Keesey                                                                                                                                                     |
|  58 |     75.715706 |    738.519190 | Jaime Headden                                                                                                                                                         |
|  59 |     67.674115 |    518.784651 | T. Michael Keesey                                                                                                                                                     |
|  60 |    956.469495 |    360.662018 | Jose Carlos Arenas-Monroy                                                                                                                                             |
|  61 |    448.318160 |    200.097156 | Beth Reinke                                                                                                                                                           |
|  62 |    270.645131 |    559.247241 | Chris huh                                                                                                                                                             |
|  63 |    629.328821 |    726.132823 | Markus A. Grohme                                                                                                                                                      |
|  64 |    187.814014 |    767.483867 | NA                                                                                                                                                                    |
|  65 |    753.059034 |     18.181826 | Chris huh                                                                                                                                                             |
|  66 |    434.396834 |     36.360091 | Scott Hartman                                                                                                                                                         |
|  67 |    599.500421 |    775.272455 | Emily Willoughby                                                                                                                                                      |
|  68 |    333.914808 |     15.006868 | Birgit Lang                                                                                                                                                           |
|  69 |    746.736139 |    315.776231 | Rafael Maia                                                                                                                                                           |
|  70 |    944.996394 |    254.459288 | Markus A. Grohme                                                                                                                                                      |
|  71 |    206.342945 |    668.794678 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  72 |    564.073399 |     30.942727 | Jaime Headden                                                                                                                                                         |
|  73 |    369.175136 |     98.454867 | Jagged Fang Designs                                                                                                                                                   |
|  74 |    516.934311 |    588.943500 | Margot Michaud                                                                                                                                                        |
|  75 |    727.886008 |    479.631400 | Margot Michaud                                                                                                                                                        |
|  76 |    481.763167 |    324.987626 | Chris huh                                                                                                                                                             |
|  77 |    201.034313 |    150.488556 | Jaime Headden                                                                                                                                                         |
|  78 |    656.857062 |    437.010211 | Scott Hartman                                                                                                                                                         |
|  79 |    354.393517 |    505.445931 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
|  80 |    422.438262 |    649.702989 | Zimices                                                                                                                                                               |
|  81 |    764.682449 |    241.358711 | Kamil S. Jaron                                                                                                                                                        |
|  82 |     87.979711 |    490.983373 | Yan Wong                                                                                                                                                              |
|  83 |    473.236743 |    783.600334 | Mattia Menchetti                                                                                                                                                      |
|  84 |    515.520666 |    658.187339 | NA                                                                                                                                                                    |
|  85 |    989.768612 |    636.603447 | Shyamal                                                                                                                                                               |
|  86 |    772.877415 |    588.386191 | Ignacio Contreras                                                                                                                                                     |
|  87 |    501.140870 |    231.502107 | T. Michael Keesey                                                                                                                                                     |
|  88 |    695.794852 |    174.210886 | Jaime Headden                                                                                                                                                         |
|  89 |    800.421678 |    764.121096 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  90 |    664.766226 |    668.565753 | Markus A. Grohme                                                                                                                                                      |
|  91 |    901.328878 |    586.441387 | Lisa Byrne                                                                                                                                                            |
|  92 |    437.406478 |    361.035215 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  93 |    771.691030 |    736.713752 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
|  94 |    783.173597 |    719.321042 | T. Michael Keesey                                                                                                                                                     |
|  95 |    430.294681 |    561.363468 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                             |
|  96 |    859.453526 |    607.709428 | Bruno C. Vellutini                                                                                                                                                    |
|  97 |    953.598736 |     71.915744 | Jagged Fang Designs                                                                                                                                                   |
|  98 |    343.642397 |     61.911089 | NA                                                                                                                                                                    |
|  99 |    344.069707 |    456.399465 | Gareth Monger                                                                                                                                                         |
| 100 |    586.154766 |     11.484425 | Jagged Fang Designs                                                                                                                                                   |
| 101 |    488.606557 |    530.707171 | Michael P. Taylor                                                                                                                                                     |
| 102 |    959.989053 |    222.258216 | Margot Michaud                                                                                                                                                        |
| 103 |    932.247070 |    414.488328 | Scott Hartman                                                                                                                                                         |
| 104 |    880.409371 |    533.122556 | Hans Hillewaert (photo) and T. Michael Keesey (vectorization)                                                                                                         |
| 105 |    988.224139 |    708.204215 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                       |
| 106 |     78.273962 |     48.714150 | Shyamal                                                                                                                                                               |
| 107 |    526.584266 |    212.181454 | Mali’o Kodis, photograph by Hans Hillewaert                                                                                                                           |
| 108 |   1004.363880 |     22.303173 | T. Michael Keesey (after Mauricio Antón)                                                                                                                              |
| 109 |    251.688671 |     20.847163 | Gareth Monger                                                                                                                                                         |
| 110 |    667.269187 |    267.660144 | Kai R. Caspar                                                                                                                                                         |
| 111 |    570.725987 |    202.131515 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 112 |    545.459827 |    548.724170 | Nobu Tamura and T. Michael Keesey                                                                                                                                     |
| 113 |    487.543851 |    756.758515 | Francisco Manuel Blanco (vectorized by T. Michael Keesey)                                                                                                             |
| 114 |    468.053353 |    797.272025 | Gareth Monger                                                                                                                                                         |
| 115 |     34.844327 |    140.548656 | Kamil S. Jaron                                                                                                                                                        |
| 116 |   1002.875977 |    731.324851 | Cesar Julian                                                                                                                                                          |
| 117 |   1002.787398 |    106.824663 | Gareth Monger                                                                                                                                                         |
| 118 |    415.038720 |    221.740370 | Matt Crook                                                                                                                                                            |
| 119 |    122.233115 |    577.440367 | Lukasiniho                                                                                                                                                            |
| 120 |    432.262116 |    335.209627 | Noah Schlottman, photo by Reinhard Jahn                                                                                                                               |
| 121 |    897.839817 |      8.679572 | Smokeybjb                                                                                                                                                             |
| 122 |    174.619917 |    177.538185 | Alexandre Vong                                                                                                                                                        |
| 123 |    981.643378 |    160.118380 | Tasman Dixon                                                                                                                                                          |
| 124 |   1008.594614 |    232.814352 | Fernando Carezzano                                                                                                                                                    |
| 125 |    650.318186 |     44.950363 | Maija Karala                                                                                                                                                          |
| 126 |    250.418115 |    526.925423 | Kai R. Caspar                                                                                                                                                         |
| 127 |    941.875532 |    787.819819 | Margot Michaud                                                                                                                                                        |
| 128 |    804.086481 |    785.147467 | Jagged Fang Designs                                                                                                                                                   |
| 129 |    302.849069 |     39.215089 | Gareth Monger                                                                                                                                                         |
| 130 |    816.952311 |     83.300568 | Mathew Wedel                                                                                                                                                          |
| 131 |   1011.249328 |    194.455714 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                  |
| 132 |    667.038536 |     15.626466 | C. Camilo Julián-Caballero                                                                                                                                            |
| 133 |    847.882599 |    757.848850 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 134 |    827.982696 |     34.028156 | Margot Michaud                                                                                                                                                        |
| 135 |    472.735827 |    709.490187 | Zimices                                                                                                                                                               |
| 136 |    280.387368 |    682.922183 | Zimices                                                                                                                                                               |
| 137 |    758.368158 |    758.647939 | Sean McCann                                                                                                                                                           |
| 138 |    614.912074 |    695.914897 | T. Michael Keesey                                                                                                                                                     |
| 139 |    978.837238 |    561.590883 | Mr E? (vectorized by T. Michael Keesey)                                                                                                                               |
| 140 |    969.412636 |    281.675450 | Marie-Aimée Allard                                                                                                                                                    |
| 141 |    819.194597 |    620.083982 | Rebecca Groom                                                                                                                                                         |
| 142 |    769.067612 |    685.585864 | Roberto Díaz Sibaja                                                                                                                                                   |
| 143 |    935.926265 |    157.835877 | Matt Martyniuk                                                                                                                                                        |
| 144 |    822.059370 |    272.604346 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                            |
| 145 |     20.879406 |    324.366779 | Alex Slavenko                                                                                                                                                         |
| 146 |    648.092378 |    143.387902 | Anna Willoughby                                                                                                                                                       |
| 147 |    335.348618 |    789.616935 | Markus A. Grohme                                                                                                                                                      |
| 148 |    978.453689 |      9.654165 | Zimices                                                                                                                                                               |
| 149 |    657.392384 |    372.248738 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 150 |    393.771424 |    590.572907 | Michael Scroggie                                                                                                                                                      |
| 151 |    120.981547 |    662.877473 | Inessa Voet                                                                                                                                                           |
| 152 |    300.853773 |    588.013584 | Carlos Cano-Barbacil                                                                                                                                                  |
| 153 |    290.155390 |    195.904985 | Yan Wong (vectorization) from 1873 illustration                                                                                                                       |
| 154 |    855.078377 |    742.959817 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                                 |
| 155 |    750.946319 |     69.698807 | Carlos Cano-Barbacil                                                                                                                                                  |
| 156 |    773.797538 |     53.776353 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 157 |    847.765072 |    103.217926 | Mattia Menchetti                                                                                                                                                      |
| 158 |     18.492576 |     56.862809 | Michael P. Taylor                                                                                                                                                     |
| 159 |   1004.672460 |    777.139112 | Gareth Monger                                                                                                                                                         |
| 160 |    394.605059 |    615.461704 | Shyamal                                                                                                                                                               |
| 161 |    687.330988 |     50.474760 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 162 |    407.306107 |    513.719751 | Margot Michaud                                                                                                                                                        |
| 163 |    269.435784 |    125.623931 | T. Michael Keesey (after Joseph Wolf)                                                                                                                                 |
| 164 |    792.561689 |    257.490837 | NA                                                                                                                                                                    |
| 165 |    284.704022 |    608.812149 | Walter Vladimir                                                                                                                                                       |
| 166 |    531.561850 |    100.363840 | Tracy A. Heath                                                                                                                                                        |
| 167 |    743.597301 |    170.340499 | Claus Rebler                                                                                                                                                          |
| 168 |   1000.108416 |     56.937859 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 169 |    252.330026 |    175.400973 | Matt Crook                                                                                                                                                            |
| 170 |    140.320959 |    654.512194 | David Orr                                                                                                                                                             |
| 171 |     27.393650 |    439.879298 | Margot Michaud                                                                                                                                                        |
| 172 |    221.315074 |     60.639643 | Tod Robbins                                                                                                                                                           |
| 173 |    142.364029 |    587.787122 | NOAA (vectorized by T. Michael Keesey)                                                                                                                                |
| 174 |     74.399226 |    235.054049 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 175 |    299.752526 |    275.128791 | Christoph Schomburg                                                                                                                                                   |
| 176 |    141.410211 |    220.685934 | Xavier Giroux-Bougard                                                                                                                                                 |
| 177 |    376.294599 |    417.731774 | Ignacio Contreras                                                                                                                                                     |
| 178 |    315.652354 |    252.212151 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 179 |    174.643911 |    731.910960 | Jaime Headden                                                                                                                                                         |
| 180 |    969.362897 |    589.279050 | Andy Wilson                                                                                                                                                           |
| 181 |     37.547360 |     10.164032 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 182 |    272.178410 |    315.605995 | Ingo Braasch                                                                                                                                                          |
| 183 |    705.807535 |    319.283730 | Danielle Alba                                                                                                                                                         |
| 184 |    263.132740 |    782.719806 | Michelle Site                                                                                                                                                         |
| 185 |    306.847858 |    460.904784 | Scott Hartman                                                                                                                                                         |
| 186 |    745.597948 |     36.917294 | Milton Tan                                                                                                                                                            |
| 187 |    167.620213 |    570.395497 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                         |
| 188 |    147.651440 |    187.702324 | Ferran Sayol                                                                                                                                                          |
| 189 |    421.116357 |    480.005234 | Ekaterina Kopeykina (vectorized by T. Michael Keesey)                                                                                                                 |
| 190 |    821.654565 |    392.611465 | Michelle Site                                                                                                                                                         |
| 191 |    351.311846 |    658.569019 | Jagged Fang Designs                                                                                                                                                   |
| 192 |    999.144268 |    314.068564 | Matt Crook                                                                                                                                                            |
| 193 |    751.618223 |    270.649355 | Mike Hanson                                                                                                                                                           |
| 194 |    395.129340 |    788.187661 | Jagged Fang Designs                                                                                                                                                   |
| 195 |    105.052131 |    673.814078 | Mathieu Basille                                                                                                                                                       |
| 196 |    646.933892 |    514.499261 | CNZdenek                                                                                                                                                              |
| 197 |    848.958876 |     10.385652 | Markus A. Grohme                                                                                                                                                      |
| 198 |    515.113224 |    630.999030 | Louis Ranjard                                                                                                                                                         |
| 199 |     32.690057 |    457.417097 | Chris huh                                                                                                                                                             |
| 200 |    706.107019 |    125.707455 | Markus A. Grohme                                                                                                                                                      |
| 201 |    113.877097 |     10.138888 | Chris huh                                                                                                                                                             |
| 202 |    807.384534 |    298.691392 | Siobhon Egan                                                                                                                                                          |
| 203 |    676.766681 |    760.386831 | NA                                                                                                                                                                    |
| 204 |    993.610114 |    741.788111 | Dori <dori@merr.info> (source photo) and Nevit Dilmen                                                                                                                 |
| 205 |    221.027886 |     72.672562 | Armin Reindl                                                                                                                                                          |
| 206 |    275.415686 |    659.558376 | Inessa Voet                                                                                                                                                           |
| 207 |    219.568403 |    348.443364 | Gareth Monger                                                                                                                                                         |
| 208 |    630.269266 |    420.558183 | Kanchi Nanjo                                                                                                                                                          |
| 209 |    546.503838 |    375.446676 | Mykle Hoban                                                                                                                                                           |
| 210 |    782.538473 |    705.387426 | Steven Traver                                                                                                                                                         |
| 211 |    426.698147 |     97.099152 | Jaime Chirinos (vectorized by T. Michael Keesey)                                                                                                                      |
| 212 |    658.888000 |    347.803699 | T. Michael Keesey                                                                                                                                                     |
| 213 |    436.440273 |    774.037950 | ДиБгд (vectorized by T. Michael Keesey)                                                                                                                               |
| 214 |     17.132570 |    237.615092 | Karla Martinez                                                                                                                                                        |
| 215 |    531.863148 |    579.274244 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                       |
| 216 |    400.067568 |    394.260811 | Jagged Fang Designs                                                                                                                                                   |
| 217 |    245.109219 |     76.206241 | Chris huh                                                                                                                                                             |
| 218 |    565.855400 |    386.609045 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 219 |    881.195387 |    394.209461 | Margot Michaud                                                                                                                                                        |
| 220 |    934.609222 |    230.253646 | Tauana J. Cunha                                                                                                                                                       |
| 221 |    536.373323 |    747.550009 | Margot Michaud                                                                                                                                                        |
| 222 |    829.203721 |    413.575658 | T. Michael Keesey (after Masteraah)                                                                                                                                   |
| 223 |    706.002863 |    796.362581 | CNZdenek                                                                                                                                                              |
| 224 |    830.493096 |    692.567412 | Dmitry Bogdanov                                                                                                                                                       |
| 225 |   1003.573363 |    414.479101 | Ferran Sayol                                                                                                                                                          |
| 226 |     21.790453 |    531.125258 | Gareth Monger                                                                                                                                                         |
| 227 |     91.758804 |    788.780655 | Scott Hartman                                                                                                                                                         |
| 228 |    537.114529 |    350.359404 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                        |
| 229 |    560.302450 |    261.720436 | Matt Crook                                                                                                                                                            |
| 230 |    872.745498 |    788.836137 | NA                                                                                                                                                                    |
| 231 |    519.416287 |    786.067201 | Tracy A. Heath                                                                                                                                                        |
| 232 |    125.542450 |    740.322783 | Tasman Dixon                                                                                                                                                          |
| 233 |    109.840219 |    647.244875 | T. Michael Keesey (after A. Y. Ivantsov)                                                                                                                              |
| 234 |    441.867728 |    410.167525 | Margot Michaud                                                                                                                                                        |
| 235 |    878.144831 |    468.340892 | Zimices                                                                                                                                                               |
| 236 |    548.323821 |    217.457998 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 237 |    536.634405 |     54.098695 | Pete Buchholz                                                                                                                                                         |
| 238 |     30.188386 |    505.644199 | Kailah Thorn & Ben King                                                                                                                                               |
| 239 |    240.102827 |     10.050040 | Collin Gross                                                                                                                                                          |
| 240 |    144.980919 |    726.515848 | Jonathan Wells                                                                                                                                                        |
| 241 |   1007.811480 |    680.413752 | Gareth Monger                                                                                                                                                         |
| 242 |    989.298947 |     87.398121 | Margot Michaud                                                                                                                                                        |
| 243 |    838.896465 |    783.414701 | Zimices                                                                                                                                                               |
| 244 |    981.674933 |    667.574041 | Scott Hartman                                                                                                                                                         |
| 245 |    456.032502 |    280.586631 | NA                                                                                                                                                                    |
| 246 |    325.827805 |    220.447883 | Birgit Lang                                                                                                                                                           |
| 247 |     28.820879 |    481.688456 | Steven Traver                                                                                                                                                         |
| 248 |    280.025764 |    771.476664 | Oscar Sanisidro                                                                                                                                                       |
| 249 |    274.901372 |     33.159246 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 250 |     27.269949 |    554.640542 | Joshua Fowler                                                                                                                                                         |
| 251 |    871.654597 |    212.706263 | Felix Vaux                                                                                                                                                            |
| 252 |    307.712856 |    625.380688 | Jaime Headden                                                                                                                                                         |
| 253 |    427.224092 |    582.181796 | Erika Schumacher                                                                                                                                                      |
| 254 |    810.970673 |    166.713062 | Margot Michaud                                                                                                                                                        |
| 255 |    267.572863 |    153.902318 | Zimices                                                                                                                                                               |
| 256 |    141.611140 |    564.719274 | Milton Tan                                                                                                                                                            |
| 257 |    482.074683 |    296.561092 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 258 |   1007.362142 |    615.944341 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 259 |    640.762262 |    703.039347 | Matt Crook                                                                                                                                                            |
| 260 |    688.186246 |    465.583686 | Sharon Wegner-Larsen                                                                                                                                                  |
| 261 |    907.191912 |     66.743125 | Carlos Cano-Barbacil                                                                                                                                                  |
| 262 |    364.719028 |    644.484493 | Lafage                                                                                                                                                                |
| 263 |     88.774934 |    334.486826 | Margot Michaud                                                                                                                                                        |
| 264 |    570.107418 |    652.519791 | Collin Gross                                                                                                                                                          |
| 265 |    480.356979 |    564.860860 | Chuanixn Yu                                                                                                                                                           |
| 266 |    956.323234 |    688.808437 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                          |
| 267 |    954.755078 |    735.190737 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 268 |    736.994435 |    505.834099 | Matt Crook                                                                                                                                                            |
| 269 |    719.964281 |    757.473313 | Gopal Murali                                                                                                                                                          |
| 270 |    573.732698 |    490.819429 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 271 |    579.911147 |    238.637930 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                       |
| 272 |    450.939555 |    577.141644 | Tasman Dixon                                                                                                                                                          |
| 273 |    572.424655 |    472.175990 | Julien Louys                                                                                                                                                          |
| 274 |    891.541235 |    452.438540 | Margot Michaud                                                                                                                                                        |
| 275 |    875.618614 |     21.046128 | DW Bapst (modified from Bulman, 1970)                                                                                                                                 |
| 276 |    781.196531 |    366.838428 | NA                                                                                                                                                                    |
| 277 |   1002.291005 |    135.006006 | Andy Wilson                                                                                                                                                           |
| 278 |    407.785727 |      6.819086 | Margot Michaud                                                                                                                                                        |
| 279 |     72.958132 |    316.562813 | Margot Michaud                                                                                                                                                        |
| 280 |     20.583834 |    590.500339 | Matt Crook                                                                                                                                                            |
| 281 |    247.805500 |    645.142604 | Ingo Braasch                                                                                                                                                          |
| 282 |    907.340463 |     76.237205 | Sarah Werning                                                                                                                                                         |
| 283 |    755.784543 |    357.087219 | Scott Hartman                                                                                                                                                         |
| 284 |    128.622166 |    201.456506 |                                                                                                                                                                       |
| 285 |    228.132179 |     43.285941 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
| 286 |    405.454053 |     50.343139 | Manabu Bessho-Uehara                                                                                                                                                  |
| 287 |      4.987155 |    380.056604 | NA                                                                                                                                                                    |
| 288 |    497.881320 |    353.535427 | Scott Hartman                                                                                                                                                         |
| 289 |    241.298991 |    689.587334 | Gareth Monger                                                                                                                                                         |
| 290 |    146.160082 |    637.825506 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 291 |    293.525653 |    292.255995 | Steven Traver                                                                                                                                                         |
| 292 |    956.151414 |    140.605282 | Matt Crook                                                                                                                                                            |
| 293 |     96.081472 |    252.937457 | Steven Traver                                                                                                                                                         |
| 294 |    701.431613 |    264.477477 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                         |
| 295 |    340.505768 |    170.401772 | Margot Michaud                                                                                                                                                        |
| 296 |    881.457354 |    363.387883 | NA                                                                                                                                                                    |
| 297 |    877.287960 |    713.255913 | Michelle Site                                                                                                                                                         |
| 298 |    315.525714 |    643.305535 | NA                                                                                                                                                                    |
| 299 |    924.823178 |    558.958454 | Margot Michaud                                                                                                                                                        |
| 300 |   1007.007337 |    582.733280 | Mario Quevedo                                                                                                                                                         |
| 301 |    873.070322 |     66.276289 | Margot Michaud                                                                                                                                                        |
| 302 |    891.054896 |    622.987173 | Gareth Monger                                                                                                                                                         |
| 303 |    698.027316 |    298.540372 | Zimices                                                                                                                                                               |
| 304 |    251.912857 |     38.364910 | Gareth Monger                                                                                                                                                         |
| 305 |    930.623311 |    393.222548 | kotik                                                                                                                                                                 |
| 306 |    607.412848 |    710.418751 | FunkMonk                                                                                                                                                              |
| 307 |    832.647069 |    320.939056 | NASA                                                                                                                                                                  |
| 308 |    568.955941 |    146.039621 | Ramona J Heim                                                                                                                                                         |
| 309 |    392.801997 |    430.228031 | Chris huh                                                                                                                                                             |
| 310 |    582.699827 |     37.694993 | NA                                                                                                                                                                    |
| 311 |    702.499737 |    430.426841 | Dave Angelini                                                                                                                                                         |
| 312 |    380.930647 |    116.470122 | Scott Reid                                                                                                                                                            |
| 313 |    103.568133 |    776.975751 | Andy Wilson                                                                                                                                                           |
| 314 |    243.183322 |    343.064821 | Matt Crook                                                                                                                                                            |
| 315 |    846.438478 |     84.127125 | Jake Warner                                                                                                                                                           |
| 316 |    762.386219 |    777.869040 | Todd Marshall, vectorized by Zimices                                                                                                                                  |
| 317 |     70.740383 |     20.871538 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 318 |    641.418900 |    744.939360 | Emily Willoughby                                                                                                                                                      |
| 319 |    713.763152 |    637.132596 | Michelle Site                                                                                                                                                         |
| 320 |    479.470232 |    680.695060 | Melissa Broussard                                                                                                                                                     |
| 321 |    913.959382 |    159.122514 | Andy Wilson                                                                                                                                                           |
| 322 |    654.292603 |    788.883115 | Scott Hartman                                                                                                                                                         |
| 323 |    409.517469 |    183.637978 | NA                                                                                                                                                                    |
| 324 |    367.910823 |    437.082273 | Steven Traver                                                                                                                                                         |
| 325 |    402.245345 |    498.529001 | NA                                                                                                                                                                    |
| 326 |     89.685038 |    345.329791 | Christoph Schomburg                                                                                                                                                   |
| 327 |    871.952630 |    797.508340 | Christoph Schomburg                                                                                                                                                   |
| 328 |    721.330215 |     50.653926 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 329 |    197.758750 |    173.504871 | Harold N Eyster                                                                                                                                                       |
| 330 |    785.871646 |    486.352130 | Christoph Schomburg                                                                                                                                                   |
| 331 |    243.819699 |    325.912677 | Ignacio Contreras                                                                                                                                                     |
| 332 |    574.719642 |    405.750529 | Matt Crook                                                                                                                                                            |
| 333 |     18.812000 |    346.761769 | Gareth Monger                                                                                                                                                         |
| 334 |    545.402498 |    175.514394 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 335 |    865.090627 |    242.300021 | Dmitry Bogdanov                                                                                                                                                       |
| 336 |    348.427617 |     42.803142 | NA                                                                                                                                                                    |
| 337 |    506.944064 |     35.364136 | Matt Crook                                                                                                                                                            |
| 338 |    104.585921 |    216.271716 | Scott Hartman                                                                                                                                                         |
| 339 |    688.809113 |    611.721159 | L. Shyamal                                                                                                                                                            |
| 340 |    493.015171 |    274.422267 | Tasman Dixon                                                                                                                                                          |
| 341 |    545.330888 |    411.016918 | Raven Amos                                                                                                                                                            |
| 342 |     50.414932 |    671.637498 | Dean Schnabel                                                                                                                                                         |
| 343 |    291.212487 |     90.185222 | Chris Jennings (vectorized by A. Verrière)                                                                                                                            |
| 344 |    193.626554 |     47.110655 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 345 |    327.504356 |    566.036019 | Kamil S. Jaron                                                                                                                                                        |
| 346 |    484.632492 |     51.873962 | Markus A. Grohme                                                                                                                                                      |
| 347 |    110.151836 |    191.625404 | Jagged Fang Designs                                                                                                                                                   |
| 348 |    511.889263 |    299.651369 | Steven Traver                                                                                                                                                         |
| 349 |    882.721418 |    494.801995 | Steven Traver                                                                                                                                                         |
| 350 |    909.442303 |    145.340955 | T. Michael Keesey                                                                                                                                                     |
| 351 |     66.292865 |    584.220959 | Rebecca Groom                                                                                                                                                         |
| 352 |    769.823730 |    500.204827 | Smokeybjb                                                                                                                                                             |
| 353 |    576.483564 |    517.858043 | Beth Reinke                                                                                                                                                           |
| 354 |    242.716871 |    258.820634 | NA                                                                                                                                                                    |
| 355 |    956.306319 |    549.265252 | Margot Michaud                                                                                                                                                        |
| 356 |   1007.779002 |    663.806817 | Steven Traver                                                                                                                                                         |
| 357 |    134.143709 |    795.405349 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 358 |    823.695311 |    734.856303 | Andy Wilson                                                                                                                                                           |
| 359 |    512.498393 |    739.332364 | Beth Reinke                                                                                                                                                           |
| 360 |    514.596020 |    366.013639 | Zimices                                                                                                                                                               |
| 361 |    107.466835 |    490.833682 | Cyril Matthey-Doret, adapted from Bernard Chaubet                                                                                                                     |
| 362 |    996.587749 |    282.241845 | Cagri Cevrim                                                                                                                                                          |
| 363 |    179.741132 |    353.001022 | Chris huh                                                                                                                                                             |
| 364 |    283.318523 |    518.326453 | Zimices                                                                                                                                                               |
| 365 |    876.495424 |    280.669800 | Noah Schlottman                                                                                                                                                       |
| 366 |    592.001397 |    749.622560 | Milton Tan                                                                                                                                                            |
| 367 |    249.562114 |    297.496239 | Matt Crook                                                                                                                                                            |
| 368 |    577.096835 |     76.471613 | Maija Karala                                                                                                                                                          |
| 369 |    493.247482 |    593.162933 | Ferran Sayol                                                                                                                                                          |
| 370 |    218.290913 |    738.525736 | Jagged Fang Designs                                                                                                                                                   |
| 371 |    499.874890 |    100.786490 | Tasman Dixon                                                                                                                                                          |
| 372 |    470.212108 |    100.229452 | Myriam\_Ramirez                                                                                                                                                       |
| 373 |    486.027082 |    635.528388 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 374 |    939.957156 |    703.468395 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 375 |    425.317589 |    196.447385 | Birgit Lang                                                                                                                                                           |
| 376 |   1007.121665 |    764.467469 | G. M. Woodward                                                                                                                                                        |
| 377 |    548.837106 |     84.719767 | Kanchi Nanjo                                                                                                                                                          |
| 378 |   1000.600271 |    563.379463 | Scott Reid                                                                                                                                                            |
| 379 |    838.657230 |    120.187292 | Sarah Werning                                                                                                                                                         |
| 380 |    391.230650 |    531.072762 | Steven Coombs                                                                                                                                                         |
| 381 |    300.567440 |    777.410763 | NA                                                                                                                                                                    |
| 382 |     15.351891 |    769.788248 | Andrew A. Farke                                                                                                                                                       |
| 383 |    977.785253 |     66.515536 | Anna Willoughby                                                                                                                                                       |
| 384 |    956.059300 |    564.379938 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 385 |    678.039530 |    695.940635 | Noah Schlottman, photo by Adam G. Clause                                                                                                                              |
| 386 |    370.783182 |    471.057237 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 387 |    476.436761 |    151.287722 | Steven Traver                                                                                                                                                         |
| 388 |    406.625468 |    570.544277 | NA                                                                                                                                                                    |
| 389 |    612.726644 |    515.300011 | Markus A. Grohme                                                                                                                                                      |
| 390 |    516.862735 |    185.144277 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                            |
| 391 |    864.305677 |    644.932095 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 392 |    338.252246 |    185.751536 | Cesar Julian                                                                                                                                                          |
| 393 |    612.883866 |    338.246339 | NA                                                                                                                                                                    |
| 394 |    592.972928 |    362.648258 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                          |
| 395 |    670.384925 |    449.837274 | Jagged Fang Designs                                                                                                                                                   |
| 396 |    205.928469 |    584.925004 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 397 |    145.502282 |    684.419360 | Kamil S. Jaron                                                                                                                                                        |
| 398 |    472.386828 |    190.054201 | DFoidl (vectorized by T. Michael Keesey)                                                                                                                              |
| 399 |    472.699899 |    359.932595 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 400 |    371.463365 |     79.740667 | Margot Michaud                                                                                                                                                        |
| 401 |    426.100369 |    396.070707 | Gareth Monger                                                                                                                                                         |
| 402 |    554.950222 |    166.688154 | Zimices                                                                                                                                                               |
| 403 |    654.533944 |    159.165462 | Tony Ayling                                                                                                                                                           |
| 404 |    186.472301 |    580.074484 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 405 |    645.532635 |    173.695234 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                            |
| 406 |    408.752948 |    415.954844 | U.S. National Park Service (vectorized by William Gearty)                                                                                                             |
| 407 |    818.428657 |    141.308258 | DW Bapst, modified from Figure 1 of Belanger (2011, PALAIOS).                                                                                                         |
| 408 |    456.608704 |    485.644490 | Chris huh                                                                                                                                                             |
| 409 |     83.137675 |    735.290420 | Gareth Monger                                                                                                                                                         |
| 410 |    819.734571 |    189.123914 | Melissa Broussard                                                                                                                                                     |
| 411 |     23.658207 |    296.154928 | nicubunu                                                                                                                                                              |
| 412 |    248.351245 |    737.912054 | Lukasiniho                                                                                                                                                            |
| 413 |    103.916280 |    542.618502 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                                                  |
| 414 |    883.224855 |    691.523779 | Jaime Headden                                                                                                                                                         |
| 415 |    770.882276 |    149.878678 | Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization)                                                                                                |
| 416 |     11.512396 |    409.124194 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 417 |    994.405844 |    205.410032 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 418 |    470.534541 |     24.479275 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 419 |    587.989345 |    280.441022 | Scott Hartman                                                                                                                                                         |
| 420 |    338.289151 |    128.679598 | NA                                                                                                                                                                    |
| 421 |    766.752981 |    402.642724 | Chris huh                                                                                                                                                             |
| 422 |     28.526559 |    423.017468 | Steven Traver                                                                                                                                                         |
| 423 |    747.623373 |     52.994676 | Jagged Fang Designs                                                                                                                                                   |
| 424 |    981.715739 |    333.803087 | Sarah Werning                                                                                                                                                         |
| 425 |    217.852713 |    123.442121 | New York Zoological Society                                                                                                                                           |
| 426 |    879.966772 |    436.813185 | Audrey Ely                                                                                                                                                            |
| 427 |    844.542098 |    604.343946 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 428 |    964.981137 |    389.675161 | Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)                                                                                         |
| 429 |    588.181558 |    125.407772 | Chloé Schmidt                                                                                                                                                         |
| 430 |    898.167596 |    731.414092 | Ferran Sayol                                                                                                                                                          |
| 431 |     93.081064 |    319.827038 | Jagged Fang Designs                                                                                                                                                   |
| 432 |     35.712680 |    657.729449 | Christine Axon                                                                                                                                                        |
| 433 |    323.441054 |    533.220863 | Kamil S. Jaron                                                                                                                                                        |
| 434 |    623.097319 |    550.326603 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 435 |    970.188682 |    781.119807 | Margot Michaud                                                                                                                                                        |
| 436 |    867.348683 |    307.204859 | Maxime Dahirel                                                                                                                                                        |
| 437 |      7.933006 |    494.550752 | Sarah Werning                                                                                                                                                         |
| 438 |    432.440393 |     23.204632 | Zimices                                                                                                                                                               |
| 439 |    516.212561 |      6.322289 | Caio Bernardes, vectorized by Zimices                                                                                                                                 |
| 440 |    340.251025 |    775.410436 | Matt Dempsey                                                                                                                                                          |
| 441 |    618.704490 |    674.664330 | T. Michael Keesey                                                                                                                                                     |
| 442 |    969.256030 |    651.810621 | Ingo Braasch                                                                                                                                                          |
| 443 |    858.026785 |    296.115199 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 444 |   1007.223426 |    428.918987 | Tasman Dixon                                                                                                                                                          |
| 445 |    807.277940 |    288.202537 | Michelle Site                                                                                                                                                         |
| 446 |    622.403756 |    781.742164 | Sean McCann                                                                                                                                                           |
| 447 |    553.871078 |    364.600566 | Chris huh                                                                                                                                                             |
| 448 |    681.558198 |    211.919755 | Gareth Monger                                                                                                                                                         |
| 449 |    205.787310 |    559.264216 | Andrew R. Gehrke                                                                                                                                                      |
| 450 |    571.014430 |    719.055066 | Audrey Ely                                                                                                                                                            |
| 451 |     15.115752 |    741.970017 | Jagged Fang Designs                                                                                                                                                   |
| 452 |    788.095323 |    606.437101 | Tasman Dixon                                                                                                                                                          |
| 453 |    291.768781 |    534.716432 | C. Camilo Julián-Caballero                                                                                                                                            |
| 454 |    637.612109 |     33.529505 | Mathew Wedel                                                                                                                                                          |
| 455 |    733.773524 |     92.159018 | T. Michael Keesey                                                                                                                                                     |
| 456 |    770.569694 |    599.535858 | Markus A. Grohme                                                                                                                                                      |
| 457 |    256.250490 |    275.304201 | T. Michael Keesey                                                                                                                                                     |
| 458 |    549.366925 |    621.365200 | Felix Vaux                                                                                                                                                            |
| 459 |     96.188900 |    115.687991 | Margot Michaud                                                                                                                                                        |
| 460 |    236.410754 |    656.513885 | Scott Hartman, modified by T. Michael Keesey                                                                                                                          |
| 461 |    758.510403 |    191.531820 | FunkMonk                                                                                                                                                              |
| 462 |    548.608189 |    475.320535 | Abraão Leite                                                                                                                                                          |
| 463 |    378.330078 |    562.501807 | Gareth Monger                                                                                                                                                         |
| 464 |    677.092154 |    283.412555 | Scott Hartman                                                                                                                                                         |
| 465 |    971.805021 |    617.163378 | Ignacio Contreras                                                                                                                                                     |
| 466 |    950.548311 |    529.903238 | Frank Förster                                                                                                                                                         |
| 467 |    354.668811 |    447.950860 | Chris huh                                                                                                                                                             |
| 468 |    523.623504 |    326.627136 | Armin Reindl                                                                                                                                                          |
| 469 |    540.319595 |    522.255138 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 470 |    229.315368 |    217.908313 | Anna Willoughby                                                                                                                                                       |
| 471 |    449.003987 |     95.089551 | Steven Blackwood                                                                                                                                                      |
| 472 |    526.960626 |    772.804821 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 473 |    684.921881 |     27.928606 | Markus A. Grohme                                                                                                                                                      |
| 474 |    968.886797 |    424.215034 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 475 |    320.035686 |    239.131006 | Matt Dempsey                                                                                                                                                          |
| 476 |    635.733466 |    540.311356 | FunkMonk                                                                                                                                                              |
| 477 |     16.167118 |    151.422164 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
| 478 |     46.412136 |    444.958543 | Javiera Constanzo                                                                                                                                                     |
| 479 |    839.947998 |    630.417495 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 480 |    689.666282 |    768.319338 | Andy Wilson                                                                                                                                                           |
| 481 |     26.353365 |    156.356347 | Ingo Braasch                                                                                                                                                          |
| 482 |    286.132726 |    573.986186 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 483 |    641.915867 |     15.946217 | Ferran Sayol                                                                                                                                                          |
| 484 |   1017.578794 |    144.979040 | Gareth Monger                                                                                                                                                         |
| 485 |    826.060257 |     19.210183 | Stuart Humphries                                                                                                                                                      |
| 486 |     16.511245 |     74.289256 | Kai R. Caspar                                                                                                                                                         |
| 487 |    138.967445 |    482.720845 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 488 |    899.667054 |     49.125696 | Zimices                                                                                                                                                               |
| 489 |    952.467797 |    208.743973 | Markus A. Grohme                                                                                                                                                      |
| 490 |    591.690039 |    376.572234 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                               |
| 491 |    675.937149 |    418.188877 | Tracy A. Heath                                                                                                                                                        |
| 492 |     26.060852 |    125.061416 | Kent Elson Sorgon                                                                                                                                                     |
| 493 |    997.311983 |    690.860123 | Michael Scroggie                                                                                                                                                      |
| 494 |    167.683388 |    686.880176 | Scott Hartman                                                                                                                                                         |
| 495 |    208.163733 |     80.040621 | Nobu Tamura                                                                                                                                                           |
| 496 |    230.965912 |    486.536632 | Maija Karala                                                                                                                                                          |
| 497 |   1007.454990 |    641.748450 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                         |
| 498 |    756.023841 |    230.902707 | Jagged Fang Designs                                                                                                                                                   |
| 499 |    659.750673 |    767.390515 | NA                                                                                                                                                                    |
| 500 |    299.231511 |    672.946837 | Gareth Monger                                                                                                                                                         |
| 501 |    342.986792 |    151.138308 | Matt Crook                                                                                                                                                            |
| 502 |    262.895691 |    192.491288 | Julia B McHugh                                                                                                                                                        |
| 503 |     87.291186 |    140.601201 | Felix Vaux                                                                                                                                                            |
| 504 |     48.848838 |    553.452975 | T. Michael Keesey                                                                                                                                                     |
| 505 |    455.841546 |    307.917023 | Markus A. Grohme                                                                                                                                                      |
| 506 |    746.621128 |    150.831255 | Andy Wilson                                                                                                                                                           |
| 507 |    808.045936 |    494.505844 | Pete Buchholz                                                                                                                                                         |
| 508 |     16.983155 |    467.614674 | Tasman Dixon                                                                                                                                                          |
| 509 |   1008.856487 |     78.099018 | Harold N Eyster                                                                                                                                                       |
| 510 |    882.367195 |    192.368221 | Tasman Dixon                                                                                                                                                          |
| 511 |    546.449694 |    607.535507 | Ferran Sayol                                                                                                                                                          |
| 512 |    245.605012 |    163.389394 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 513 |     79.702250 |     30.569881 | Zimices                                                                                                                                                               |
| 514 |    418.438655 |    668.827465 | Birgit Lang                                                                                                                                                           |
| 515 |    961.085938 |    200.433674 | Manabu Bessho-Uehara                                                                                                                                                  |
| 516 |    296.834237 |     66.754081 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 517 |    219.632075 |    200.885948 | Scott Hartman                                                                                                                                                         |
| 518 |    162.662743 |    209.488622 | Matt Crook                                                                                                                                                            |
| 519 |    462.489214 |    313.352905 | Tasman Dixon                                                                                                                                                          |
| 520 |      6.523440 |    343.952304 | T. Michael Keesey                                                                                                                                                     |

    #> Your tweet has been posted!
