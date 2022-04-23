
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

Yan Wong, Joe Schneid (vectorized by T. Michael Keesey), Dmitry Bogdanov
(vectorized by T. Michael Keesey), Gabriela Palomo-Munoz, Margot
Michaud, Dean Schnabel, Matt Crook, Steven Traver, ДиБгд (vectorized by
T. Michael Keesey), Matt Martyniuk (vectorized by T. Michael Keesey),
Roberto Diaz Sibaja, based on Domser, Ferran Sayol, Duane Raver
(vectorized by T. Michael Keesey), Gareth Monger, Felix Vaux, Noah
Schlottman, Scott Hartman, Nobu Tamura (vectorized by T. Michael
Keesey), Benjamin Monod-Broca, Philip Chalmers (vectorized by T. Michael
Keesey), Jose Carlos Arenas-Monroy, T. Michael Keesey, Ignacio
Contreras, Jordan Mallon (vectorized by T. Michael Keesey), Zimices, Yan
Wong from drawing by Joseph Smit, C. Camilo Julián-Caballero, Jessica
Anne Miller, Chris huh, Markus A. Grohme, Dmitry Bogdanov, Didier
Descouens (vectorized by T. Michael Keesey), Tracy A. Heath, Ramona J
Heim, Nobu Tamura, vectorized by Zimices, Mathilde Cordellier, Iain
Reid, Jagged Fang Designs, Skye McDavid, Smokeybjb (vectorized by T.
Michael Keesey), Mihai Dragos (vectorized by T. Michael Keesey), Tasman
Dixon, Timothy Knepp (vectorized by T. Michael Keesey), xgirouxb,
Stemonitis (photography) and T. Michael Keesey (vectorization), Kanchi
Nanjo, Henry Lydecker, M Kolmann, Lisa Byrne, Julie Blommaert based on
photo by Sofdrakou, T. Michael Keesey (vector) and Stuart Halliday
(photograph), Andrew A. Farke, Jaime Headden, Kamil S. Jaron, Crystal
Maier, Steven Haddock • Jellywatch.org, Birgit Lang, Emma Hughes,
Вальдимар (vectorized by T. Michael Keesey), Lankester Edwin Ray
(vectorized by T. Michael Keesey), John Gould (vectorized by T. Michael
Keesey), Yan Wong from photo by Denes Emoke, Milton Tan, Greg Schechter
(original photo), Renato Santos (vector silhouette), Robert Gay, Antonov
(vectorized by T. Michael Keesey), Jake Warner, David Orr, Sarah
Werning, Harold N Eyster, Emily Willoughby, Sharon Wegner-Larsen, Beth
Reinke, Maija Karala, Noah Schlottman, photo by Hans De Blauwe, Maxime
Dahirel, Cristina Guijarro, James R. Spotila and Ray Chatterji,
Falconaumanni and T. Michael Keesey, T. Michael Keesey (vectorization);
Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman,
Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase
(photography), Jan A. Venter, Herbert H. T. Prins, David A. Balfour &
Rob Slotow (vectorized by T. Michael Keesey), Michael B. H. (vectorized
by T. Michael Keesey), Andy Wilson, Javier Luque, Caleb M. Brown,
Anthony Caravaggi, Alexander Schmidt-Lebuhn, Peter Coxhead, Joanna
Wolfe, Danny Cicchetti (vectorized by T. Michael Keesey), Joseph J. W.
Sertich, Mark A. Loewen, Roberto Díaz Sibaja, Cristopher Silva, Collin
Gross, Dmitry Bogdanov (modified by T. Michael Keesey), L. Shyamal, Dori
<dori@merr.info> (source photo) and Nevit Dilmen, nicubunu, Brad
McFeeters (vectorized by T. Michael Keesey), Caroline Harding, MAF
(vectorized by T. Michael Keesey), Michelle Site, Brian Gratwicke
(photo) and T. Michael Keesey (vectorization), Meliponicultor Itaymbere,
Pete Buchholz, Matt Wilkins, Michael Scroggie, Jessica Rick, Shyamal,
Henry Fairfield Osborn, vectorized by Zimices, Walter Vladimir,
CNZdenek, Jiekun He, Smokeybjb, Becky Barnes, Ingo Braasch, Chris A.
Hamilton, Mattia Menchetti, Siobhon Egan, Cagri Cevrim, Christoph
Schomburg, Nobu Tamura (modified by T. Michael Keesey), Robert Bruce
Horsfall, vectorized by Zimices, Emma Kissling, Apokryltaros (vectorized
by T. Michael Keesey), Lukasiniho, Ernst Haeckel (vectorized by T.
Michael Keesey), Ghedoghedo, vectorized by Zimices, B. Duygu Özpolat,
Mette Aumala, Michele M Tobias, Lindberg (vectorized by T. Michael
Keesey), H. F. O. March (vectorized by T. Michael Keesey), Melissa
Broussard, Dave Angelini, Ben Liebeskind, Ricardo Araújo, Jonathan
Wells, Haplochromis (vectorized by T. Michael Keesey), zoosnow, Xavier
Giroux-Bougard, Michael “FunkMonk” B. H. (vectorized by T. Michael
Keesey), Fernando Carezzano, Darren Naish (vectorize by T. Michael
Keesey), Sergio A. Muñoz-Gómez, Jack Mayer Wood, Riccardo Percudani,
Jaime Headden, modified by T. Michael Keesey, Jesús Gómez, vectorized by
Zimices, T. Michael Keesey (after Marek Velechovský), Robert Bruce
Horsfall (vectorized by William Gearty), Pranav Iyer (grey ideas), Nobu
Tamura, modified by Andrew A. Farke, Christopher Laumer (vectorized by
T. Michael Keesey), White Wolf, Raven Amos, Birgit Lang; based on a
drawing by C.L. Koch, Nobu Tamura, Carlos Cano-Barbacil, Wynston Cooper
(photo) and Albertonykus (silhouette), Matt Martyniuk, John Curtis
(vectorized by T. Michael Keesey), Tyler Greenfield, Air Kebir NRG, Kent
Elson Sorgon, Jan Sevcik (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Steven Coombs, Ludwik Gąsiorowski, Konsta
Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist, I.
Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey), Arthur S.
Brum, Jimmy Bernot, Erika Schumacher, Matt Martyniuk (modified by T.
Michael Keesey), Joseph Wolf, 1863 (vectorization by Dinah Challen),
Neil Kelley, Noah Schlottman, photo by Casey Dunn, Thibaut Brunet, Diego
Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli,
Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by
T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                               |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     67.020285 |    356.827814 | Yan Wong                                                                                                                                                                             |
|   2 |    943.253288 |    413.438468 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                                        |
|   3 |    860.945078 |    140.110394 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|   4 |    829.266976 |    559.129651 | NA                                                                                                                                                                                   |
|   5 |    599.411598 |    675.171502 | Gabriela Palomo-Munoz                                                                                                                                                                |
|   6 |    882.994858 |    228.761867 | Margot Michaud                                                                                                                                                                       |
|   7 |    461.212289 |    232.095108 | Dean Schnabel                                                                                                                                                                        |
|   8 |    620.032924 |    299.943150 | Matt Crook                                                                                                                                                                           |
|   9 |    816.225753 |    670.798282 | Steven Traver                                                                                                                                                                        |
|  10 |    527.448108 |    397.423743 | ДиБгд (vectorized by T. Michael Keesey)                                                                                                                                              |
|  11 |    669.435891 |    410.169881 | Margot Michaud                                                                                                                                                                       |
|  12 |    361.419051 |    530.409825 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                                     |
|  13 |    167.426351 |    580.443192 | Matt Crook                                                                                                                                                                           |
|  14 |    702.931293 |     61.706310 | Roberto Diaz Sibaja, based on Domser                                                                                                                                                 |
|  15 |    335.221646 |    348.462774 | Ferran Sayol                                                                                                                                                                         |
|  16 |    740.762585 |    774.474929 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                                        |
|  17 |    446.195350 |     53.952178 | Gareth Monger                                                                                                                                                                        |
|  18 |     67.917111 |     73.114462 | Felix Vaux                                                                                                                                                                           |
|  19 |    254.903074 |    252.329256 | Noah Schlottman                                                                                                                                                                      |
|  20 |    136.714449 |    741.597472 | Scott Hartman                                                                                                                                                                        |
|  21 |    248.834773 |    697.155085 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  22 |    784.296909 |    402.472041 | Dean Schnabel                                                                                                                                                                        |
|  23 |    739.915998 |    517.439351 | Benjamin Monod-Broca                                                                                                                                                                 |
|  24 |    741.245556 |    603.315145 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                                    |
|  25 |    165.581932 |    148.881844 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
|  26 |     67.674789 |    651.476825 | T. Michael Keesey                                                                                                                                                                    |
|  27 |    666.491957 |    190.456754 | Ferran Sayol                                                                                                                                                                         |
|  28 |     81.695717 |    204.097524 | Ignacio Contreras                                                                                                                                                                    |
|  29 |    672.155252 |     99.633176 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                                      |
|  30 |    923.665553 |     57.664966 | Zimices                                                                                                                                                                              |
|  31 |     62.199408 |    498.518348 | Yan Wong from drawing by Joseph Smit                                                                                                                                                 |
|  32 |    858.714334 |    403.294095 | C. Camilo Julián-Caballero                                                                                                                                                           |
|  33 |    976.762280 |    157.979763 | Jessica Anne Miller                                                                                                                                                                  |
|  34 |    295.814811 |    745.600361 | Chris huh                                                                                                                                                                            |
|  35 |    952.401751 |    649.754135 | Zimices                                                                                                                                                                              |
|  36 |    947.878497 |    546.104434 | NA                                                                                                                                                                                   |
|  37 |    887.753203 |    747.046098 | Markus A. Grohme                                                                                                                                                                     |
|  38 |    740.454129 |    286.322741 | Dmitry Bogdanov                                                                                                                                                                      |
|  39 |    716.319170 |    231.181943 | Scott Hartman                                                                                                                                                                        |
|  40 |    286.008386 |     78.772874 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
|  41 |    617.480378 |    528.535803 | Zimices                                                                                                                                                                              |
|  42 |    157.132187 |    437.434591 | Tracy A. Heath                                                                                                                                                                       |
|  43 |    360.785006 |    242.957541 | Margot Michaud                                                                                                                                                                       |
|  44 |    305.560239 |    619.837982 | Chris huh                                                                                                                                                                            |
|  45 |    141.111234 |    287.777308 | Margot Michaud                                                                                                                                                                       |
|  46 |    407.888558 |    409.420654 | Matt Crook                                                                                                                                                                           |
|  47 |    596.687666 |    464.952040 | Ramona J Heim                                                                                                                                                                        |
|  48 |    548.176273 |    180.466374 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  49 |    163.619036 |     46.783650 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
|  50 |    591.968071 |     62.360653 | Gareth Monger                                                                                                                                                                        |
|  51 |    432.403605 |    741.538934 | C. Camilo Julián-Caballero                                                                                                                                                           |
|  52 |    370.737973 |    181.478897 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
|  53 |    759.351436 |    121.549856 | Mathilde Cordellier                                                                                                                                                                  |
|  54 |    477.753058 |    456.544092 | Iain Reid                                                                                                                                                                            |
|  55 |    365.902081 |    125.896073 | Jagged Fang Designs                                                                                                                                                                  |
|  56 |    773.118311 |    492.462692 | Skye McDavid                                                                                                                                                                         |
|  57 |    934.687261 |    704.135085 | Jagged Fang Designs                                                                                                                                                                  |
|  58 |    779.265423 |    752.838562 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                          |
|  59 |    856.266179 |    103.779381 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                                       |
|  60 |    503.417075 |    313.672481 | Gareth Monger                                                                                                                                                                        |
|  61 |    158.801139 |    229.711622 | Tasman Dixon                                                                                                                                                                         |
|  62 |    935.631663 |    296.473031 | Gareth Monger                                                                                                                                                                        |
|  63 |    168.356415 |    642.233314 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                                                      |
|  64 |    225.202344 |    785.258555 | Margot Michaud                                                                                                                                                                       |
|  65 |    560.828227 |    770.517446 | xgirouxb                                                                                                                                                                             |
|  66 |    963.932893 |    766.826114 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                                       |
|  67 |    425.347378 |    309.941852 | Kanchi Nanjo                                                                                                                                                                         |
|  68 |    716.875415 |     18.359041 | Henry Lydecker                                                                                                                                                                       |
|  69 |    828.773498 |    321.513591 | M Kolmann                                                                                                                                                                            |
|  70 |    625.319040 |    602.327282 | Lisa Byrne                                                                                                                                                                           |
|  71 |    542.821666 |    207.933005 | T. Michael Keesey                                                                                                                                                                    |
|  72 |    345.359839 |    278.257274 | NA                                                                                                                                                                                   |
|  73 |    731.006075 |    338.128752 | Julie Blommaert based on photo by Sofdrakou                                                                                                                                          |
|  74 |     49.197928 |    790.544551 | Ignacio Contreras                                                                                                                                                                    |
|  75 |    316.870990 |    450.367100 | C. Camilo Julián-Caballero                                                                                                                                                           |
|  76 |    317.339328 |     22.551774 | Margot Michaud                                                                                                                                                                       |
|  77 |     54.201132 |    561.608492 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                                          |
|  78 |    780.478427 |    214.868874 | Gareth Monger                                                                                                                                                                        |
|  79 |    988.892914 |    237.408262 | Andrew A. Farke                                                                                                                                                                      |
|  80 |    549.610676 |    340.040287 | Gareth Monger                                                                                                                                                                        |
|  81 |    350.781489 |    767.381987 | Jagged Fang Designs                                                                                                                                                                  |
|  82 |    509.189053 |    124.903849 | T. Michael Keesey                                                                                                                                                                    |
|  83 |     53.901353 |    298.075124 | Jaime Headden                                                                                                                                                                        |
|  84 |    515.061134 |    729.484684 | Kamil S. Jaron                                                                                                                                                                       |
|  85 |    590.855837 |    112.840396 | Crystal Maier                                                                                                                                                                        |
|  86 |    171.448449 |    520.818276 | Steven Haddock • Jellywatch.org                                                                                                                                                      |
|  87 |    453.684978 |    691.694857 | Jagged Fang Designs                                                                                                                                                                  |
|  88 |    830.948810 |     75.124731 | Zimices                                                                                                                                                                              |
|  89 |    194.939377 |    327.698465 | Birgit Lang                                                                                                                                                                          |
|  90 |    302.302863 |    311.434585 | Markus A. Grohme                                                                                                                                                                     |
|  91 |    436.223420 |    634.887695 | Emma Hughes                                                                                                                                                                          |
|  92 |     25.798200 |    674.935202 | Вальдимар (vectorized by T. Michael Keesey)                                                                                                                                          |
|  93 |    472.957031 |    671.650596 | Margot Michaud                                                                                                                                                                       |
|  94 |    871.182522 |    605.854074 | Margot Michaud                                                                                                                                                                       |
|  95 |    798.130889 |     55.643176 | Tasman Dixon                                                                                                                                                                         |
|  96 |    254.448352 |    597.125078 | Steven Traver                                                                                                                                                                        |
|  97 |    877.353944 |    725.788972 | NA                                                                                                                                                                                   |
|  98 |    268.659983 |    175.899702 | xgirouxb                                                                                                                                                                             |
|  99 |    634.178444 |    752.672658 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                                |
| 100 |    203.876411 |    367.811846 | T. Michael Keesey                                                                                                                                                                    |
| 101 |    959.787585 |    745.390669 | John Gould (vectorized by T. Michael Keesey)                                                                                                                                         |
| 102 |    982.974743 |    606.587201 | Ignacio Contreras                                                                                                                                                                    |
| 103 |    544.791744 |    572.897585 | Yan Wong from photo by Denes Emoke                                                                                                                                                   |
| 104 |    826.168912 |    462.604086 | Milton Tan                                                                                                                                                                           |
| 105 |    523.242458 |    504.958922 | Jagged Fang Designs                                                                                                                                                                  |
| 106 |    342.942819 |    657.771312 | Matt Crook                                                                                                                                                                           |
| 107 |    745.699344 |    676.445319 | Greg Schechter (original photo), Renato Santos (vector silhouette)                                                                                                                   |
| 108 |    517.844243 |     12.967667 | NA                                                                                                                                                                                   |
| 109 |    954.925762 |    254.911186 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 110 |    144.748702 |    693.901701 | Robert Gay                                                                                                                                                                           |
| 111 |    384.634768 |    452.685068 | Antonov (vectorized by T. Michael Keesey)                                                                                                                                            |
| 112 |     67.652647 |    147.613346 | Margot Michaud                                                                                                                                                                       |
| 113 |    628.655576 |    694.002315 | Zimices                                                                                                                                                                              |
| 114 |    289.288048 |    156.715480 | Chris huh                                                                                                                                                                            |
| 115 |    861.844384 |    342.642624 | Jake Warner                                                                                                                                                                          |
| 116 |    533.240189 |    278.271506 | David Orr                                                                                                                                                                            |
| 117 |    753.927486 |    447.884576 | Ferran Sayol                                                                                                                                                                         |
| 118 |    122.264863 |    780.178130 | Sarah Werning                                                                                                                                                                        |
| 119 |    207.208894 |    292.459097 | Matt Crook                                                                                                                                                                           |
| 120 |   1005.031918 |    301.613019 | Gareth Monger                                                                                                                                                                        |
| 121 |     46.959341 |    408.392660 | Harold N Eyster                                                                                                                                                                      |
| 122 |    331.667999 |    148.116843 | Emily Willoughby                                                                                                                                                                     |
| 123 |   1004.743822 |    501.321119 | Dean Schnabel                                                                                                                                                                        |
| 124 |    714.407276 |    744.867589 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 125 |    889.678157 |    596.412431 | Beth Reinke                                                                                                                                                                          |
| 126 |    303.028024 |    207.570495 | NA                                                                                                                                                                                   |
| 127 |     98.026736 |    658.912904 | Sarah Werning                                                                                                                                                                        |
| 128 |    449.091124 |     93.205267 | NA                                                                                                                                                                                   |
| 129 |    999.330520 |    726.510681 | Zimices                                                                                                                                                                              |
| 130 |    591.509262 |    205.978881 | Ignacio Contreras                                                                                                                                                                    |
| 131 |    279.029401 |    137.545504 | Maija Karala                                                                                                                                                                         |
| 132 |    692.415933 |    141.260116 | Matt Crook                                                                                                                                                                           |
| 133 |     87.204954 |    453.831064 | Zimices                                                                                                                                                                              |
| 134 |    239.602197 |    567.041365 | Margot Michaud                                                                                                                                                                       |
| 135 |    360.211456 |    781.976022 | Noah Schlottman, photo by Hans De Blauwe                                                                                                                                             |
| 136 |    193.781911 |    510.211440 | Maxime Dahirel                                                                                                                                                                       |
| 137 |    831.982530 |    429.223203 | Cristina Guijarro                                                                                                                                                                    |
| 138 |    938.237308 |    204.481691 | James R. Spotila and Ray Chatterji                                                                                                                                                   |
| 139 |    377.194824 |    222.965396 | Matt Crook                                                                                                                                                                           |
| 140 |    661.829657 |    540.199976 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 141 |    421.816067 |    197.678262 | Matt Crook                                                                                                                                                                           |
| 142 |    173.682088 |    348.826470 | Scott Hartman                                                                                                                                                                        |
| 143 |    730.012305 |    710.630205 | Gareth Monger                                                                                                                                                                        |
| 144 |    557.851201 |    244.227189 | Gareth Monger                                                                                                                                                                        |
| 145 |    831.787626 |    278.209980 | Emily Willoughby                                                                                                                                                                     |
| 146 |    878.148470 |    628.653937 | Mathilde Cordellier                                                                                                                                                                  |
| 147 |    379.666810 |     73.199806 | Falconaumanni and T. Michael Keesey                                                                                                                                                  |
| 148 |    405.584217 |    331.675835 | Ferran Sayol                                                                                                                                                                         |
| 149 |    849.948633 |    639.478978 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
| 150 |    714.774839 |    630.378743 | Matt Crook                                                                                                                                                                           |
| 151 |     97.869433 |     43.217531 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
| 152 |    866.945689 |    480.012472 | Zimices                                                                                                                                                                              |
| 153 |     31.045199 |    427.649449 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 154 |   1007.332569 |     63.013666 | Matt Crook                                                                                                                                                                           |
| 155 |    714.113915 |    210.749231 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                                      |
| 156 |     49.637922 |    529.438419 | Scott Hartman                                                                                                                                                                        |
| 157 |    874.130335 |     78.641337 | Matt Crook                                                                                                                                                                           |
| 158 |    893.964646 |    770.636382 | Jagged Fang Designs                                                                                                                                                                  |
| 159 |    227.516966 |    265.764431 | Andy Wilson                                                                                                                                                                          |
| 160 |    807.562377 |    179.611654 | Javier Luque                                                                                                                                                                         |
| 161 |     82.798168 |    437.421769 | Maija Karala                                                                                                                                                                         |
| 162 |     95.686667 |    421.797584 | Caleb M. Brown                                                                                                                                                                       |
| 163 |   1008.586846 |    212.265213 | Jagged Fang Designs                                                                                                                                                                  |
| 164 |    718.004546 |    685.852822 | Steven Traver                                                                                                                                                                        |
| 165 |    404.265924 |    136.384837 | Tasman Dixon                                                                                                                                                                         |
| 166 |    329.755570 |    326.761669 | Anthony Caravaggi                                                                                                                                                                    |
| 167 |    654.705596 |    236.524800 | Sarah Werning                                                                                                                                                                        |
| 168 |    742.915844 |    408.224523 | Jagged Fang Designs                                                                                                                                                                  |
| 169 |     95.616712 |    630.234305 | Zimices                                                                                                                                                                              |
| 170 |    784.486731 |    794.119040 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 171 |    493.652572 |    285.406466 | Peter Coxhead                                                                                                                                                                        |
| 172 |    637.249319 |    136.801135 | Joanna Wolfe                                                                                                                                                                         |
| 173 |    265.019622 |    727.881481 | Zimices                                                                                                                                                                              |
| 174 |    571.030793 |    366.381429 | Steven Traver                                                                                                                                                                        |
| 175 |     54.016841 |    151.218162 | Matt Crook                                                                                                                                                                           |
| 176 |    706.595898 |    538.146797 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 177 |    217.028524 |     75.786206 | Andy Wilson                                                                                                                                                                          |
| 178 |    453.745993 |    711.781009 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                                                    |
| 179 |    120.967357 |    534.129687 | Steven Haddock • Jellywatch.org                                                                                                                                                      |
| 180 |    627.188732 |    107.066019 | Zimices                                                                                                                                                                              |
| 181 |    792.477483 |    592.412767 | Matt Crook                                                                                                                                                                           |
| 182 |    187.172133 |    217.983810 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                                                                 |
| 183 |   1003.020911 |    171.502583 | T. Michael Keesey                                                                                                                                                                    |
| 184 |    315.008440 |    782.203326 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 185 |    210.121948 |    734.089023 | Zimices                                                                                                                                                                              |
| 186 |    909.724277 |    224.414005 | Ferran Sayol                                                                                                                                                                         |
| 187 |    937.574840 |    459.799762 | Zimices                                                                                                                                                                              |
| 188 |    677.985451 |    486.075572 | Cristopher Silva                                                                                                                                                                     |
| 189 |    209.315960 |     97.382842 | Collin Gross                                                                                                                                                                         |
| 190 |    502.291260 |    244.494142 | Dmitry Bogdanov (modified by T. Michael Keesey)                                                                                                                                      |
| 191 |    471.287416 |    422.590577 | Markus A. Grohme                                                                                                                                                                     |
| 192 |     22.927822 |    722.476112 | Collin Gross                                                                                                                                                                         |
| 193 |     58.334312 |    268.926347 | L. Shyamal                                                                                                                                                                           |
| 194 |    901.771339 |    665.902172 | Dori <dori@merr.info> (source photo) and Nevit Dilmen                                                                                                                                |
| 195 |    359.494153 |    693.955513 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 196 |    360.612171 |     12.087615 | Dean Schnabel                                                                                                                                                                        |
| 197 |    395.172406 |    770.972577 | nicubunu                                                                                                                                                                             |
| 198 |    796.266561 |    243.895150 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                                       |
| 199 |    655.372553 |     32.501254 | T. Michael Keesey                                                                                                                                                                    |
| 200 |    682.326686 |    581.617925 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |
| 201 |    776.501361 |    188.035008 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                                              |
| 202 |     26.600408 |    129.143856 | Zimices                                                                                                                                                                              |
| 203 |    871.404742 |    517.706097 | Michelle Site                                                                                                                                                                        |
| 204 |    248.591337 |    159.018333 | Brian Gratwicke (photo) and T. Michael Keesey (vectorization)                                                                                                                        |
| 205 |    849.680359 |     30.643365 | Scott Hartman                                                                                                                                                                        |
| 206 |    420.885941 |    658.652150 | Andrew A. Farke                                                                                                                                                                      |
| 207 |    816.283721 |    203.454567 | Meliponicultor Itaymbere                                                                                                                                                             |
| 208 |    533.260951 |     63.037532 | Andy Wilson                                                                                                                                                                          |
| 209 |    213.374153 |    196.934230 | Pete Buchholz                                                                                                                                                                        |
| 210 |    688.320982 |    554.975104 | Matt Wilkins                                                                                                                                                                         |
| 211 |    564.499540 |    152.435207 | Michael Scroggie                                                                                                                                                                     |
| 212 |     20.402655 |     37.834976 | Chris huh                                                                                                                                                                            |
| 213 |     22.942199 |    240.087014 | Gareth Monger                                                                                                                                                                        |
| 214 |    255.159199 |     15.776542 | Matt Crook                                                                                                                                                                           |
| 215 |     88.662016 |    272.967763 | Jessica Rick                                                                                                                                                                         |
| 216 |    490.360602 |    631.030201 | Tasman Dixon                                                                                                                                                                         |
| 217 |    249.447211 |    658.635141 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 218 |     45.893791 |    754.923100 | Zimices                                                                                                                                                                              |
| 219 |    264.079178 |    762.496722 | NA                                                                                                                                                                                   |
| 220 |    965.637797 |     14.283354 | Scott Hartman                                                                                                                                                                        |
| 221 |    878.093222 |    781.054868 | Markus A. Grohme                                                                                                                                                                     |
| 222 |    216.631234 |    614.201258 | Margot Michaud                                                                                                                                                                       |
| 223 |    436.111189 |    613.645576 | Jagged Fang Designs                                                                                                                                                                  |
| 224 |    801.958210 |      9.902724 | Shyamal                                                                                                                                                                              |
| 225 |    240.235057 |    120.225807 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                                        |
| 226 |     24.605534 |    546.261258 | Collin Gross                                                                                                                                                                         |
| 227 |    123.535141 |    394.270304 | Walter Vladimir                                                                                                                                                                      |
| 228 |    398.164942 |     10.174494 | Andrew A. Farke                                                                                                                                                                      |
| 229 |   1005.672850 |    467.964066 | CNZdenek                                                                                                                                                                             |
| 230 |    361.567486 |     48.289554 | Jiekun He                                                                                                                                                                            |
| 231 |    822.975168 |    301.418529 | Scott Hartman                                                                                                                                                                        |
| 232 |    526.321568 |    521.493033 | Tasman Dixon                                                                                                                                                                         |
| 233 |    766.445676 |     45.522823 | Matt Crook                                                                                                                                                                           |
| 234 |    515.993631 |    548.422828 | Yan Wong                                                                                                                                                                             |
| 235 |    614.574218 |    447.753930 | NA                                                                                                                                                                                   |
| 236 |    792.835936 |    340.324567 | Smokeybjb                                                                                                                                                                            |
| 237 |    702.797441 |    254.236493 | Becky Barnes                                                                                                                                                                         |
| 238 |    450.817318 |    364.450495 | Ingo Braasch                                                                                                                                                                         |
| 239 |    888.119010 |    128.477466 | Matt Crook                                                                                                                                                                           |
| 240 |    973.523984 |    736.394812 | T. Michael Keesey                                                                                                                                                                    |
| 241 |    783.471314 |     48.286874 | Matt Crook                                                                                                                                                                           |
| 242 |    867.284189 |     10.913904 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 243 |    923.869288 |    184.531329 | Chris A. Hamilton                                                                                                                                                                    |
| 244 |    681.152365 |    466.036557 | Iain Reid                                                                                                                                                                            |
| 245 |    654.375794 |    472.184917 | Margot Michaud                                                                                                                                                                       |
| 246 |    401.477249 |    154.593173 | Mattia Menchetti                                                                                                                                                                     |
| 247 |   1008.177989 |     37.941886 | Andy Wilson                                                                                                                                                                          |
| 248 |    933.497149 |     80.974472 | Matt Crook                                                                                                                                                                           |
| 249 |    380.107089 |     27.570237 | Siobhon Egan                                                                                                                                                                         |
| 250 |    820.556556 |    728.892821 | Gareth Monger                                                                                                                                                                        |
| 251 |    452.883609 |    406.870380 | Zimices                                                                                                                                                                              |
| 252 |    595.277573 |    571.724613 | Scott Hartman                                                                                                                                                                        |
| 253 |    936.730730 |    677.702236 | Skye McDavid                                                                                                                                                                         |
| 254 |    495.627133 |    482.255837 | Cagri Cevrim                                                                                                                                                                         |
| 255 |    862.804674 |    359.166921 | Markus A. Grohme                                                                                                                                                                     |
| 256 |    208.122693 |    595.919219 | Christoph Schomburg                                                                                                                                                                  |
| 257 |    297.268290 |    332.078261 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                          |
| 258 |    822.385838 |    260.486850 | Jose Carlos Arenas-Monroy                                                                                                                                                            |
| 259 |    427.345166 |    465.496219 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                                         |
| 260 |    208.667033 |    207.880333 | Emma Kissling                                                                                                                                                                        |
| 261 |    926.807363 |    655.852234 | Jagged Fang Designs                                                                                                                                                                  |
| 262 |    630.959955 |     54.627443 | Lisa Byrne                                                                                                                                                                           |
| 263 |    119.263841 |    170.283597 | Dean Schnabel                                                                                                                                                                        |
| 264 |    969.647359 |    106.170678 | Christoph Schomburg                                                                                                                                                                  |
| 265 |     84.787403 |     20.777707 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                                              |
| 266 |    299.945366 |    290.610185 | Gareth Monger                                                                                                                                                                        |
| 267 |    552.603119 |    137.213411 | Ferran Sayol                                                                                                                                                                         |
| 268 |    996.618974 |    351.279138 | Shyamal                                                                                                                                                                              |
| 269 |    266.768766 |    440.123592 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                       |
| 270 |     31.954864 |    594.818560 | Lukasiniho                                                                                                                                                                           |
| 271 |    510.045808 |    297.129286 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                                      |
| 272 |    529.971745 |     42.155531 | Ghedoghedo, vectorized by Zimices                                                                                                                                                    |
| 273 |    518.373904 |    468.683771 | Chris huh                                                                                                                                                                            |
| 274 |    269.320931 |     38.790152 | Margot Michaud                                                                                                                                                                       |
| 275 |    970.677667 |    510.172004 | B. Duygu Özpolat                                                                                                                                                                     |
| 276 |    267.184782 |    404.941290 | Felix Vaux                                                                                                                                                                           |
| 277 |     26.558133 |    628.426257 | Mette Aumala                                                                                                                                                                         |
| 278 |    306.296898 |    400.700053 | Michele M Tobias                                                                                                                                                                     |
| 279 |    559.943785 |    413.742159 | Steven Traver                                                                                                                                                                        |
| 280 |    700.812537 |    305.244090 | Margot Michaud                                                                                                                                                                       |
| 281 |    151.935068 |    494.500166 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 282 |    660.803185 |    785.250073 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                                           |
| 283 |    859.131158 |    693.574239 | Beth Reinke                                                                                                                                                                          |
| 284 |   1006.015150 |    258.723075 | Ferran Sayol                                                                                                                                                                         |
| 285 |    999.745767 |    576.355187 | Margot Michaud                                                                                                                                                                       |
| 286 |    691.923939 |    618.608881 | H. F. O. March (vectorized by T. Michael Keesey)                                                                                                                                     |
| 287 |    887.848531 |    192.236633 | Melissa Broussard                                                                                                                                                                    |
| 288 |    110.162411 |    400.936219 | Zimices                                                                                                                                                                              |
| 289 |    528.111905 |    233.896634 | Dean Schnabel                                                                                                                                                                        |
| 290 |    161.417700 |    374.386912 | Dave Angelini                                                                                                                                                                        |
| 291 |      9.142555 |     77.609043 | Ferran Sayol                                                                                                                                                                         |
| 292 |    905.129798 |    617.866741 | Chris huh                                                                                                                                                                            |
| 293 |    399.361491 |    369.425255 | Kanchi Nanjo                                                                                                                                                                         |
| 294 |    478.945589 |    339.751671 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 295 |    124.408707 |     84.670982 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 296 |    130.024793 |    671.045173 | Gareth Monger                                                                                                                                                                        |
| 297 |    629.423658 |    574.651697 | Zimices                                                                                                                                                                              |
| 298 |    778.801197 |     24.084496 | James R. Spotila and Ray Chatterji                                                                                                                                                   |
| 299 |    513.547037 |    431.954544 | Ben Liebeskind                                                                                                                                                                       |
| 300 |    681.349317 |    336.780856 | Gareth Monger                                                                                                                                                                        |
| 301 |    838.598762 |    506.548298 | Ben Liebeskind                                                                                                                                                                       |
| 302 |    660.875230 |     59.726179 | Chris huh                                                                                                                                                                            |
| 303 |    615.338878 |    178.874257 | Ignacio Contreras                                                                                                                                                                    |
| 304 |    872.694572 |    446.049909 | Andy Wilson                                                                                                                                                                          |
| 305 |    925.803662 |    132.890927 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 306 |     72.437070 |    581.003136 | Gareth Monger                                                                                                                                                                        |
| 307 |    996.297984 |    751.770050 | Margot Michaud                                                                                                                                                                       |
| 308 |    320.992779 |    647.202697 | Scott Hartman                                                                                                                                                                        |
| 309 |    494.656577 |    707.686043 | Margot Michaud                                                                                                                                                                       |
| 310 |    914.821303 |    435.787602 | Tracy A. Heath                                                                                                                                                                       |
| 311 |    759.398893 |    714.604591 | Sarah Werning                                                                                                                                                                        |
| 312 |    115.863011 |    100.528680 | Matt Crook                                                                                                                                                                           |
| 313 |    519.210712 |     78.879203 | Ricardo Araújo                                                                                                                                                                       |
| 314 |    297.085049 |    258.563754 | Michael Scroggie                                                                                                                                                                     |
| 315 |    887.021605 |    372.927660 | Jonathan Wells                                                                                                                                                                       |
| 316 |    325.012287 |    430.017062 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 317 |     60.509516 |    319.016035 | Ferran Sayol                                                                                                                                                                         |
| 318 |    179.618239 |    760.289035 | Margot Michaud                                                                                                                                                                       |
| 319 |    414.968886 |    776.509741 | T. Michael Keesey                                                                                                                                                                    |
| 320 |    576.588507 |     15.090349 | NA                                                                                                                                                                                   |
| 321 |    906.226145 |    791.741764 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                                       |
| 322 |    488.388834 |    783.039478 | T. Michael Keesey                                                                                                                                                                    |
| 323 |     36.252840 |    110.004710 | Margot Michaud                                                                                                                                                                       |
| 324 |    827.395126 |    372.089132 | zoosnow                                                                                                                                                                              |
| 325 |    866.245173 |    660.811070 | Nobu Tamura, vectorized by Zimices                                                                                                                                                   |
| 326 |    450.428817 |    126.469319 | Markus A. Grohme                                                                                                                                                                     |
| 327 |    190.580451 |    661.211849 | Xavier Giroux-Bougard                                                                                                                                                                |
| 328 |    336.352957 |    410.903719 | NA                                                                                                                                                                                   |
| 329 |     30.726674 |     14.956402 | Zimices                                                                                                                                                                              |
| 330 |    844.129377 |    792.146305 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                                           |
| 331 |    540.629326 |    484.570252 | Fernando Carezzano                                                                                                                                                                   |
| 332 |    596.542296 |    226.460589 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                                        |
| 333 |    706.687070 |    474.596251 | Chris huh                                                                                                                                                                            |
| 334 |   1000.703567 |    366.236221 | Caleb M. Brown                                                                                                                                                                       |
| 335 |    878.769775 |    579.447692 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
| 336 |    974.863434 |    709.001375 | Gareth Monger                                                                                                                                                                        |
| 337 |    360.956680 |    209.987214 | Tasman Dixon                                                                                                                                                                         |
| 338 |    224.347965 |    394.230946 | Chris huh                                                                                                                                                                            |
| 339 |    264.782765 |    145.130262 | Margot Michaud                                                                                                                                                                       |
| 340 |    589.333534 |    397.856093 | Emily Willoughby                                                                                                                                                                     |
| 341 |    716.518816 |    390.661708 | Gareth Monger                                                                                                                                                                        |
| 342 |    199.973390 |    249.566354 | Jack Mayer Wood                                                                                                                                                                      |
| 343 |     96.012210 |    611.085628 | Birgit Lang                                                                                                                                                                          |
| 344 |    514.189424 |    610.780630 | Riccardo Percudani                                                                                                                                                                   |
| 345 |    745.816272 |    203.482995 | Scott Hartman                                                                                                                                                                        |
| 346 |    288.625492 |     46.072944 | Chris huh                                                                                                                                                                            |
| 347 |     68.264868 |    729.382214 | Lukasiniho                                                                                                                                                                           |
| 348 |    521.947658 |     26.622593 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 349 |    848.917820 |    709.377339 | Jaime Headden, modified by T. Michael Keesey                                                                                                                                         |
| 350 |    103.911146 |    117.484665 | Iain Reid                                                                                                                                                                            |
| 351 |    190.239691 |    311.521766 | Jesús Gómez, vectorized by Zimices                                                                                                                                                   |
| 352 |     22.091260 |    781.387611 | Chris huh                                                                                                                                                                            |
| 353 |    883.797744 |    713.973152 | Scott Hartman                                                                                                                                                                        |
| 354 |    669.532822 |    568.460842 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 355 |     30.042983 |    261.001102 | Beth Reinke                                                                                                                                                                          |
| 356 |    219.687721 |    495.869472 | Felix Vaux                                                                                                                                                                           |
| 357 |    866.811474 |    535.917852 | Scott Hartman                                                                                                                                                                        |
| 358 |    641.198452 |    460.695410 | Jaime Headden, modified by T. Michael Keesey                                                                                                                                         |
| 359 |    986.261970 |    284.957651 | Sarah Werning                                                                                                                                                                        |
| 360 |   1006.477535 |    693.361089 | T. Michael Keesey (after Marek Velechovský)                                                                                                                                          |
| 361 |    603.899667 |    790.380515 | Ignacio Contreras                                                                                                                                                                    |
| 362 |    943.546412 |    222.744470 | Tracy A. Heath                                                                                                                                                                       |
| 363 |     11.978737 |    174.437404 | Andy Wilson                                                                                                                                                                          |
| 364 |    444.654485 |    111.516922 | Margot Michaud                                                                                                                                                                       |
| 365 |    887.904239 |    167.900143 | Margot Michaud                                                                                                                                                                       |
| 366 |    177.648498 |     91.695191 | Zimices                                                                                                                                                                              |
| 367 |    411.744457 |    166.305916 | Robert Bruce Horsfall (vectorized by William Gearty)                                                                                                                                 |
| 368 |    703.267733 |    604.527318 | NA                                                                                                                                                                                   |
| 369 |   1000.791418 |     88.121262 | T. Michael Keesey                                                                                                                                                                    |
| 370 |    957.275840 |    591.210501 | Pranav Iyer (grey ideas)                                                                                                                                                             |
| 371 |    443.879880 |    338.278848 | Iain Reid                                                                                                                                                                            |
| 372 |    318.523755 |    795.839950 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                                             |
| 373 |    223.635615 |    757.123590 | Margot Michaud                                                                                                                                                                       |
| 374 |    923.446408 |     20.365628 | Anthony Caravaggi                                                                                                                                                                    |
| 375 |    232.990989 |    536.306097 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                                                                 |
| 376 |    940.447996 |    605.023791 | James R. Spotila and Ray Chatterji                                                                                                                                                   |
| 377 |    293.053513 |    663.633036 | Scott Hartman                                                                                                                                                                        |
| 378 |    990.808767 |    187.946774 | Falconaumanni and T. Michael Keesey                                                                                                                                                  |
| 379 |     76.258629 |    253.778285 | Scott Hartman                                                                                                                                                                        |
| 380 |    283.855378 |    647.198226 | Jaime Headden                                                                                                                                                                        |
| 381 |    812.402042 |    441.409533 | White Wolf                                                                                                                                                                           |
| 382 |    369.911085 |    261.411607 | Markus A. Grohme                                                                                                                                                                     |
| 383 |    685.952232 |     48.673664 | Markus A. Grohme                                                                                                                                                                     |
| 384 |    193.951963 |    711.367228 | Raven Amos                                                                                                                                                                           |
| 385 |    132.002321 |    516.175681 | Felix Vaux                                                                                                                                                                           |
| 386 |     94.891336 |    568.873442 | Scott Hartman                                                                                                                                                                        |
| 387 |    890.147986 |    160.845619 | NA                                                                                                                                                                                   |
| 388 |    763.881685 |    534.175710 | Jagged Fang Designs                                                                                                                                                                  |
| 389 |    441.952172 |    774.470357 | Chris huh                                                                                                                                                                            |
| 390 |    995.022060 |     12.412877 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 391 |    895.249276 |    325.121771 | Matt Crook                                                                                                                                                                           |
| 392 |    882.978944 |    123.735909 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 393 |    399.227768 |    312.721793 | Birgit Lang; based on a drawing by C.L. Koch                                                                                                                                         |
| 394 |    303.284392 |    231.729186 | Jagged Fang Designs                                                                                                                                                                  |
| 395 |    614.997657 |    712.974154 | Anthony Caravaggi                                                                                                                                                                    |
| 396 |    671.772805 |     73.759905 | Nobu Tamura                                                                                                                                                                          |
| 397 |    712.503921 |    102.872730 | Scott Hartman                                                                                                                                                                        |
| 398 |    842.834261 |    492.233770 | Jagged Fang Designs                                                                                                                                                                  |
| 399 |    324.865969 |    707.889562 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 400 |     27.752011 |     59.766208 | Steven Traver                                                                                                                                                                        |
| 401 |    127.081293 |    314.448636 | Chris huh                                                                                                                                                                            |
| 402 |    551.287047 |    528.364525 | T. Michael Keesey                                                                                                                                                                    |
| 403 |     91.032490 |    781.673937 | Margot Michaud                                                                                                                                                                       |
| 404 |    429.211804 |    244.628517 | Wynston Cooper (photo) and Albertonykus (silhouette)                                                                                                                                 |
| 405 |   1008.157290 |    522.283724 | Markus A. Grohme                                                                                                                                                                     |
| 406 |    147.542061 |     88.196132 | Maxime Dahirel                                                                                                                                                                       |
| 407 |    901.728468 |    209.898146 | Matt Martyniuk                                                                                                                                                                       |
| 408 |    362.826238 |    101.247447 | Jagged Fang Designs                                                                                                                                                                  |
| 409 |    208.420043 |    757.544476 | Christoph Schomburg                                                                                                                                                                  |
| 410 |    717.887956 |    124.624335 | Gareth Monger                                                                                                                                                                        |
| 411 |    477.446739 |    296.247550 | Margot Michaud                                                                                                                                                                       |
| 412 |    979.403371 |    678.676884 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                                        |
| 413 |   1001.403306 |    319.558579 | T. Michael Keesey                                                                                                                                                                    |
| 414 |    460.536887 |    605.508625 | Tyler Greenfield                                                                                                                                                                     |
| 415 |    295.221373 |    422.904127 | Ingo Braasch                                                                                                                                                                         |
| 416 |    704.711293 |    653.373667 | Andy Wilson                                                                                                                                                                          |
| 417 |    780.434281 |    759.676937 | T. Michael Keesey                                                                                                                                                                    |
| 418 |    416.427090 |    365.673692 | Air Kebir NRG                                                                                                                                                                        |
| 419 |      7.469089 |    752.607726 | Robert Gay                                                                                                                                                                           |
| 420 |    920.550330 |    575.139462 | Steven Traver                                                                                                                                                                        |
| 421 |    819.577709 |    348.539029 | Kent Elson Sorgon                                                                                                                                                                    |
| 422 |    210.170285 |      7.057118 | Scott Hartman                                                                                                                                                                        |
| 423 |    792.286643 |    156.788307 | Matt Crook                                                                                                                                                                           |
| 424 |    186.981911 |    334.361051 | Caleb M. Brown                                                                                                                                                                       |
| 425 |    525.817602 |    690.423401 | Felix Vaux                                                                                                                                                                           |
| 426 |    192.438730 |    256.722995 | Sarah Werning                                                                                                                                                                        |
| 427 |    413.118459 |    106.828990 | Maija Karala                                                                                                                                                                         |
| 428 |    417.437089 |    708.055446 | Zimices                                                                                                                                                                              |
| 429 |    180.671596 |    193.845888 | Smokeybjb                                                                                                                                                                            |
| 430 |    935.773653 |    159.661936 | NA                                                                                                                                                                                   |
| 431 |    703.419928 |    154.053008 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                           |
| 432 |    595.296835 |    364.941720 | Steven Traver                                                                                                                                                                        |
| 433 |    218.195954 |    429.104662 | NA                                                                                                                                                                                   |
| 434 |    773.166901 |    232.579527 | Jagged Fang Designs                                                                                                                                                                  |
| 435 |    613.314195 |    494.744973 | Shyamal                                                                                                                                                                              |
| 436 |    851.637537 |     50.927177 | Smokeybjb                                                                                                                                                                            |
| 437 |    299.694309 |    769.375793 | Zimices                                                                                                                                                                              |
| 438 |    312.874410 |    135.622596 | Steven Coombs                                                                                                                                                                        |
| 439 |    470.987062 |    719.561183 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 440 |    535.910290 |    306.524668 | Ludwik Gąsiorowski                                                                                                                                                                   |
| 441 |    169.520844 |    791.861790 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                                   |
| 442 |    852.691012 |    700.036981 | Chris huh                                                                                                                                                                            |
| 443 |    575.509027 |      7.787281 | Chris huh                                                                                                                                                                            |
| 444 |    190.693925 |    608.834768 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                                                |
| 445 |    219.154947 |    186.348341 | Jagged Fang Designs                                                                                                                                                                  |
| 446 |     12.906750 |    309.332401 | NA                                                                                                                                                                                   |
| 447 |    199.880750 |    337.330476 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 448 |    419.024132 |    678.866651 | Zimices                                                                                                                                                                              |
| 449 |    947.411122 |    312.239582 | Siobhon Egan                                                                                                                                                                         |
| 450 |    860.705822 |    295.109404 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 451 |    316.618276 |      6.163582 | Dean Schnabel                                                                                                                                                                        |
| 452 |    910.792553 |    248.499008 | Jagged Fang Designs                                                                                                                                                                  |
| 453 |     68.843895 |    543.463543 | Scott Hartman                                                                                                                                                                        |
| 454 |     18.814635 |    610.954988 | Tasman Dixon                                                                                                                                                                         |
| 455 |    496.572409 |    513.136287 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                                          |
| 456 |    756.583428 |    399.046241 | Zimices                                                                                                                                                                              |
| 457 |    781.607621 |    609.575109 | Arthur S. Brum                                                                                                                                                                       |
| 458 |    896.234493 |    348.198776 | Sharon Wegner-Larsen                                                                                                                                                                 |
| 459 |     10.810553 |    516.396882 | Michele M Tobias                                                                                                                                                                     |
| 460 |    861.615842 |    772.524678 | Jagged Fang Designs                                                                                                                                                                  |
| 461 |     17.872879 |    418.117200 | T. Michael Keesey                                                                                                                                                                    |
| 462 |    874.412083 |    651.209625 | NA                                                                                                                                                                                   |
| 463 |    696.289622 |      5.365914 | Jagged Fang Designs                                                                                                                                                                  |
| 464 |    100.078254 |    794.056525 | Carlos Cano-Barbacil                                                                                                                                                                 |
| 465 |    243.351239 |    621.332433 | Michelle Site                                                                                                                                                                        |
| 466 |    473.302100 |     97.871278 | Yan Wong                                                                                                                                                                             |
| 467 |    349.046225 |     79.134467 | Jimmy Bernot                                                                                                                                                                         |
| 468 |     51.922632 |    715.814952 | Pete Buchholz                                                                                                                                                                        |
| 469 |    717.986231 |    704.218816 | Sarah Werning                                                                                                                                                                        |
| 470 |    311.866954 |    658.878572 | Markus A. Grohme                                                                                                                                                                     |
| 471 |    365.553476 |    680.170813 | Ferran Sayol                                                                                                                                                                         |
| 472 |    463.382370 |    788.283569 | Smokeybjb                                                                                                                                                                            |
| 473 |    273.365712 |    472.846682 | Kamil S. Jaron                                                                                                                                                                       |
| 474 |    988.906946 |    487.243944 | Markus A. Grohme                                                                                                                                                                     |
| 475 |    251.057323 |    649.476541 | Erika Schumacher                                                                                                                                                                     |
| 476 |    420.490705 |    388.443988 | Tasman Dixon                                                                                                                                                                         |
| 477 |    101.448675 |    674.674413 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                                       |
| 478 |    706.649063 |    570.636297 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                                                   |
| 479 |    218.011715 |    510.620608 | Neil Kelley                                                                                                                                                                          |
| 480 |    354.434192 |    713.317741 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                       |
| 481 |    243.812046 |     35.034320 | NA                                                                                                                                                                                   |
| 482 |    211.781302 |    660.484231 | Gareth Monger                                                                                                                                                                        |
| 483 |    726.485684 |    463.557691 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 484 |     92.914197 |    595.915490 | Jagged Fang Designs                                                                                                                                                                  |
| 485 |    708.711420 |     18.635942 | Gareth Monger                                                                                                                                                                        |
| 486 |    243.482349 |    128.687222 | Noah Schlottman, photo by Casey Dunn                                                                                                                                                 |
| 487 |    876.830134 |    464.029626 | Gareth Monger                                                                                                                                                                        |
| 488 |    693.378104 |    345.783085 | Kamil S. Jaron                                                                                                                                                                       |
| 489 |     94.508041 |      5.694682 | Iain Reid                                                                                                                                                                            |
| 490 |    517.223861 |     94.815316 | Anthony Caravaggi                                                                                                                                                                    |
| 491 |    454.219862 |    132.195531 | Thibaut Brunet                                                                                                                                                                       |
| 492 |    765.627615 |    580.595688 | T. Michael Keesey                                                                                                                                                                    |
| 493 |    677.248553 |    208.802587 | Harold N Eyster                                                                                                                                                                      |
| 494 |    909.874627 |    199.525532 | Birgit Lang                                                                                                                                                                          |
| 495 |    339.263087 |    424.478867 | Maija Karala                                                                                                                                                                         |
| 496 |     95.624487 |    137.735851 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
| 497 |    128.595521 |    380.784989 | Mette Aumala                                                                                                                                                                         |
| 498 |    538.280791 |    253.339433 | Tasman Dixon                                                                                                                                                                         |
| 499 |    884.857575 |    701.464593 | Gareth Monger                                                                                                                                                                        |
| 500 |    278.434278 |    113.576289 | Matt Martyniuk                                                                                                                                                                       |
| 501 |    591.287235 |    426.142580 | Birgit Lang                                                                                                                                                                          |
| 502 |    764.080198 |    323.763981 | Emma Kissling                                                                                                                                                                        |
| 503 |     87.171352 |    715.130865 | Jagged Fang Designs                                                                                                                                                                  |
| 504 |    778.257996 |     83.842241 | Scott Hartman                                                                                                                                                                        |
| 505 |    316.472763 |    339.308454 | Sarah Werning                                                                                                                                                                        |
| 506 |    353.194631 |    754.318729 | Chris huh                                                                                                                                                                            |
| 507 |    155.949379 |      5.525188 | Andrew A. Farke                                                                                                                                                                      |
| 508 |    913.263424 |    603.974579 | Tasman Dixon                                                                                                                                                                         |
| 509 |    899.775148 |     16.023199 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                                     |

    #> Your tweet has been posted!
