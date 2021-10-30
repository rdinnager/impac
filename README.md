
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

Scott Hartman, Gareth Monger, Mathilde Cordellier, Margot Michaud,
Ferran Sayol, Felix Vaux, Nobu Tamura (vectorized by T. Michael Keesey),
Estelle Bourdon, Zimices, Steven Traver, Andrew A. Farke, Michele M
Tobias, Christoph Schomburg, Matt Crook, Kailah Thorn & Mark Hutchinson,
Rebecca Groom, Alexander Schmidt-Lebuhn, T. Michael Keesey (after C. De
Muizon), Beth Reinke, Joanna Wolfe, Luis Cunha, Tasman Dixon, Mali’o
Kodis, photograph by Bruno Vellutini, Kelly, Matus Valach, Robert Gay,
\[unknown\], Smokeybjb, Sharon Wegner-Larsen, Jagged Fang Designs,
FunkMonk, Emily Willoughby, Francesco “Architetto” Rollandin, James R.
Spotila and Ray Chatterji, Matt Hayes, Yan Wong, Dmitry Bogdanov
(vectorized by T. Michael Keesey), Steven Coombs, Scott Reid, T. Michael
Keesey, Michelle Site, Chris huh, Karl Ragnar Gjertsen (vectorized by T.
Michael Keesey), Cristian Osorio & Paula Carrera, Proyecto Carnivoros
Australes (www.carnivorosaustrales.org), Matt Celeskey, Scarlet23
(vectorized by T. Michael Keesey), Gabriela Palomo-Munoz, Original
scheme by ‘Haplochromis’, vectorized by Roberto Díaz Sibaja, CNZdenek,
Tauana J. Cunha, Sarah Werning, Tyler Greenfield, T. Michael Keesey
(after Mauricio Antón), Milton Tan, Sergio A. Muñoz-Gómez, Falconaumanni
and T. Michael Keesey, Cristopher Silva, Joseph Wolf, 1863
(vectorization by Dinah Challen), Rafael Maia, L. Shyamal, B. Duygu
Özpolat, Michael Scroggie, Kamil S. Jaron, Armin Reindl, Rainer Schoch,
Alexandre Vong, Anthony Caravaggi, Lee Harding (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Birgit Lang, Kai
R. Caspar, Crystal Maier, Harold N Eyster, Tracy A. Heath, Leann
Biancani, photo by Kenneth Clifton, FunkMonk \[Michael B.H.\] (modified
by T. Michael Keesey), Mariana Ruiz Villarreal, Terpsichores,
Apokryltaros (vectorized by T. Michael Keesey), Matt Dempsey, Timothy
Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy
J. Bartley (silhouette), Jan Sevcik (photo), John E. McCormack, Michael
G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn,
Robb T. Brumfield & T. Michael Keesey, Ludwik Gasiorowski, Jerry
Oldenettel (vectorized by T. Michael Keesey), C. Camilo
Julián-Caballero, Jan A. Venter, Herbert H. T. Prins, David A. Balfour
& Rob Slotow (vectorized by T. Michael Keesey), nicubunu, Lauren
Anderson, Mike Hanson, Caleb M. Brown, Jaime Headden, Smokeybjb
(modified by Mike Keesey), Jose Carlos Arenas-Monroy, Steve
Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael
Keesey (vectorization), Sebastian Stabinger, Mathieu Basille, Danielle
Alba, Dean Schnabel, Yan Wong from drawing by T. F. Zimmermann, Chris
Jennings (Risiatto), Ricardo Araújo, Ernst Haeckel (vectorized by T.
Michael Keesey), Katie S. Collins, Nobu Tamura, vectorized by Zimices,
Shyamal, Darren Naish (vectorized by T. Michael Keesey), Yan Wong
(vectorization) from 1873 illustration, Dmitry Bogdanov, Jack Mayer
Wood, Charles R. Knight (vectorized by T. Michael Keesey), Rachel Shoop,
Mattia Menchetti, Didier Descouens (vectorized by T. Michael Keesey),
Dave Angelini, Sidney Frederic Harmer, Arthur Everett Shipley
(vectorized by Maxime Dahirel), Xavier Giroux-Bougard, Birgit Lang;
original image by virmisco.org, Jessica Anne Miller, Maija Karala, Matt
Wilkins, Stanton F. Fink (vectorized by T. Michael Keesey), Nancy Wyman
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Original drawing by Nobu Tamura, vectorized by Roberto Díaz
Sibaja, Iain Reid, Lisa Byrne, Alex Slavenko, Maxime Dahirel, Collin
Gross, Owen Jones, Dinah Challen, Caroline Harding, MAF (vectorized by
T. Michael Keesey), Kent Elson Sorgon, Maxwell Lefroy (vectorized by T.
Michael Keesey), Jimmy Bernot, Ghedo (vectorized by T. Michael Keesey),
\<U+0414\>\<U+0438\>\<U+0411\>\<U+0433\>\<U+0434\> (vectorized by T.
Michael Keesey), Noah Schlottman, photo by Casey Dunn, Mathew Wedel, RS,
Jake Warner, Melissa Broussard, Jay Matternes (vectorized by T. Michael
Keesey), Manabu Bessho-Uehara, Courtney Rockenbach, T. Michael Keesey
(vectorization); Yves Bousquet (photography), Stacy Spensley (Modified),
Walter Vladimir, Pollyanna von Knorring and T. Michael Keesey, Sarah
Alewijnse, Ian Burt (original) and T. Michael Keesey (vectorization),
Roberto Díaz Sibaja, Carlos Cano-Barbacil, George Edward Lodge (modified
by T. Michael Keesey), Mykle Hoban, Berivan Temiz, Lankester Edwin Ray
(vectorized by T. Michael Keesey), Michael P. Taylor, NOAA Great Lakes
Environmental Research Laboratory (illustration) and Timothy J. Bartley
(silhouette), Tim Bertelink (modified by T. Michael Keesey), Pete
Buchholz, Lauren Sumner-Rooney, Jaime Headden, modified by T. Michael
Keesey, Ellen Edmonson (illustration) and Timothy J. Bartley
(silhouette), Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti,
Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G.
Barraclough (vectorized by T. Michael Keesey), Ellen Edmonson and Hugh
Chrisp (illustration) and Timothy J. Bartley (silhouette), Matt
Martyniuk, Rene Martin, Melissa Ingala, Ville-Veikko Sinkkonen, Original
drawing by Antonov, vectorized by Roberto Díaz Sibaja, M Kolmann,
Ghedoghedo, vectorized by Zimices, Cristina Guijarro, Kenneth Lacovara
(vectorized by T. Michael Keesey), Alexandra van der Geer, T. Michael
Keesey (after Heinrich Harder), E. R. Waite & H. M. Hale (vectorized by
T. Michael Keesey), T. Michael Keesey (after Walker & al.), Griensteidl
and T. Michael Keesey, Tony Ayling, AnAgnosticGod (vectorized by T.
Michael Keesey), Original drawing by Dmitry Bogdanov, vectorized by
Roberto Díaz Sibaja, Saguaro Pictures (source photo) and T. Michael
Keesey, David Tana, Young and Zhao (1972:figure 4), modified by Michael
P. Taylor, Bennet McComish, photo by Avenue

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    934.937413 |    169.229229 | Scott Hartman                                                                                                                                                         |
|   2 |    718.280239 |    556.514164 | Gareth Monger                                                                                                                                                         |
|   3 |    938.036756 |     73.650029 | Mathilde Cordellier                                                                                                                                                   |
|   4 |    437.582329 |    657.850913 | Margot Michaud                                                                                                                                                        |
|   5 |    901.333418 |    231.080628 | Ferran Sayol                                                                                                                                                          |
|   6 |    913.850761 |    500.918679 | Felix Vaux                                                                                                                                                            |
|   7 |    314.523034 |    497.384831 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|   8 |    870.120469 |    644.960657 | Estelle Bourdon                                                                                                                                                       |
|   9 |    611.942076 |    443.609389 | Zimices                                                                                                                                                               |
|  10 |    832.466636 |    302.003900 | Steven Traver                                                                                                                                                         |
|  11 |     49.013617 |    585.806325 | Andrew A. Farke                                                                                                                                                       |
|  12 |    792.166397 |    639.725385 | Michele M Tobias                                                                                                                                                      |
|  13 |    700.488017 |    712.327970 | NA                                                                                                                                                                    |
|  14 |    685.792508 |    444.802480 | Christoph Schomburg                                                                                                                                                   |
|  15 |     84.153052 |    146.454058 | Andrew A. Farke                                                                                                                                                       |
|  16 |    272.710776 |    268.255208 | Matt Crook                                                                                                                                                            |
|  17 |    405.809384 |    372.594404 | NA                                                                                                                                                                    |
|  18 |    426.346718 |    189.797414 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
|  19 |    119.371832 |    485.685406 | Rebecca Groom                                                                                                                                                         |
|  20 |    251.109172 |    355.683461 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|  21 |    617.142155 |    234.260849 | T. Michael Keesey (after C. De Muizon)                                                                                                                                |
|  22 |    135.646260 |    742.873593 | Beth Reinke                                                                                                                                                           |
|  23 |    211.332719 |    132.640674 | Margot Michaud                                                                                                                                                        |
|  24 |    111.697906 |    417.901890 | Scott Hartman                                                                                                                                                         |
|  25 |    707.836712 |    176.008306 | Ferran Sayol                                                                                                                                                          |
|  26 |    548.072099 |    527.209540 | Joanna Wolfe                                                                                                                                                          |
|  27 |    797.747059 |    531.041436 | Luis Cunha                                                                                                                                                            |
|  28 |    939.083591 |    593.356571 | Tasman Dixon                                                                                                                                                          |
|  29 |    147.476719 |    604.493275 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                           |
|  30 |    321.136237 |    318.609912 | Kelly                                                                                                                                                                 |
|  31 |    631.989009 |     91.113942 | NA                                                                                                                                                                    |
|  32 |    961.948090 |    441.332782 | Matus Valach                                                                                                                                                          |
|  33 |    434.355718 |    764.180756 | Robert Gay                                                                                                                                                            |
|  34 |    776.838051 |    394.054465 | Matt Crook                                                                                                                                                            |
|  35 |    415.204665 |     60.910309 | \[unknown\]                                                                                                                                                           |
|  36 |    295.104801 |     71.280513 | Smokeybjb                                                                                                                                                             |
|  37 |     89.432865 |    247.343731 | Sharon Wegner-Larsen                                                                                                                                                  |
|  38 |     78.585216 |     34.853788 | Gareth Monger                                                                                                                                                         |
|  39 |    790.450297 |     70.770927 | Gareth Monger                                                                                                                                                         |
|  40 |    632.630021 |    336.158980 | Ferran Sayol                                                                                                                                                          |
|  41 |    245.798752 |    580.449302 | Jagged Fang Designs                                                                                                                                                   |
|  42 |    216.034300 |    636.076953 | FunkMonk                                                                                                                                                              |
|  43 |    516.279092 |    417.415547 | Emily Willoughby                                                                                                                                                      |
|  44 |    506.964378 |    475.839272 | Francesco “Architetto” Rollandin                                                                                                                                      |
|  45 |    138.483742 |    340.500570 | Tasman Dixon                                                                                                                                                          |
|  46 |    452.850662 |    293.797596 | James R. Spotila and Ray Chatterji                                                                                                                                    |
|  47 |    948.263710 |    324.702723 | Matt Crook                                                                                                                                                            |
|  48 |    543.441400 |    165.097115 | Matt Hayes                                                                                                                                                            |
|  49 |    286.244880 |    152.620396 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  50 |    405.046272 |    553.676578 | Scott Hartman                                                                                                                                                         |
|  51 |    171.605942 |     55.347520 | Gareth Monger                                                                                                                                                         |
|  52 |    751.847178 |    227.798466 | Yan Wong                                                                                                                                                              |
|  53 |    826.133976 |    158.780753 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  54 |    877.532431 |    742.779289 | Steven Coombs                                                                                                                                                         |
|  55 |    513.124198 |     99.838609 | Scott Reid                                                                                                                                                            |
|  56 |    269.802645 |    771.392770 | T. Michael Keesey                                                                                                                                                     |
|  57 |    205.337569 |    488.046951 | Michelle Site                                                                                                                                                         |
|  58 |    139.059866 |     87.511693 | Beth Reinke                                                                                                                                                           |
|  59 |    329.931822 |    432.244498 | Chris huh                                                                                                                                                             |
|  60 |    589.612052 |    737.582414 | Jagged Fang Designs                                                                                                                                                   |
|  61 |    204.052312 |    219.375887 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                                |
|  62 |    612.023359 |    568.538614 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                          |
|  63 |    648.287326 |    766.186566 | Margot Michaud                                                                                                                                                        |
|  64 |    846.485151 |    495.456897 | Gareth Monger                                                                                                                                                         |
|  65 |    107.991191 |    317.189603 | NA                                                                                                                                                                    |
|  66 |    420.485853 |    224.952146 | Matt Celeskey                                                                                                                                                         |
|  67 |    263.398217 |     32.919120 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
|  68 |     39.689932 |    702.280100 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  69 |    167.710787 |    381.743202 | Margot Michaud                                                                                                                                                        |
|  70 |    397.943782 |    498.451949 | T. Michael Keesey                                                                                                                                                     |
|  71 |     31.406465 |    171.974174 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  72 |    539.008427 |     46.203322 | Original scheme by ‘Haplochromis’, vectorized by Roberto Díaz Sibaja                                                                                                  |
|  73 |     27.673364 |    757.481773 | NA                                                                                                                                                                    |
|  74 |    314.290537 |    617.658491 | CNZdenek                                                                                                                                                              |
|  75 |    541.649124 |    320.406366 | Tauana J. Cunha                                                                                                                                                       |
|  76 |    963.820285 |    655.431012 | Matt Crook                                                                                                                                                            |
|  77 |    972.287697 |    143.613684 | Steven Traver                                                                                                                                                         |
|  78 |    385.451884 |    319.403336 | NA                                                                                                                                                                    |
|  79 |    704.022649 |    656.261558 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  80 |    366.872095 |     76.903632 | Matt Crook                                                                                                                                                            |
|  81 |    190.544561 |    679.316094 | Scott Hartman                                                                                                                                                         |
|  82 |    854.358713 |     80.996532 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  83 |    203.358489 |     20.717114 | Sarah Werning                                                                                                                                                         |
|  84 |    982.699764 |    550.354538 | Tyler Greenfield                                                                                                                                                      |
|  85 |    189.368971 |    173.833306 | Scott Hartman                                                                                                                                                         |
|  86 |     65.240867 |    376.379943 | Gareth Monger                                                                                                                                                         |
|  87 |    640.791280 |    159.647182 | Scott Hartman                                                                                                                                                         |
|  88 |    959.073516 |    786.244723 | T. Michael Keesey (after Mauricio Antón)                                                                                                                              |
|  89 |    756.105839 |    314.436518 | Milton Tan                                                                                                                                                            |
|  90 |    435.334579 |    492.436808 | NA                                                                                                                                                                    |
|  91 |    704.510137 |     37.564179 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
|  92 |    722.297737 |    338.663644 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
|  93 |    920.965072 |    407.914975 | Steven Traver                                                                                                                                                         |
|  94 |    507.066931 |    739.686541 | Scott Hartman                                                                                                                                                         |
|  95 |    336.257257 |    590.136981 | Cristopher Silva                                                                                                                                                      |
|  96 |    467.498517 |    333.813376 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  97 |    487.193931 |     46.176447 | Joseph Wolf, 1863 (vectorization by Dinah Challen)                                                                                                                    |
|  98 |    729.655086 |     98.036926 | Jagged Fang Designs                                                                                                                                                   |
|  99 |    841.179365 |    347.819820 | Rafael Maia                                                                                                                                                           |
| 100 |    206.819151 |    752.674027 | Gareth Monger                                                                                                                                                         |
| 101 |    983.239296 |    374.689146 | L. Shyamal                                                                                                                                                            |
| 102 |    650.096805 |    527.919170 | B. Duygu Özpolat                                                                                                                                                      |
| 103 |    546.840859 |    269.151263 | Margot Michaud                                                                                                                                                        |
| 104 |     39.063384 |    433.927497 | NA                                                                                                                                                                    |
| 105 |    150.059640 |    522.975513 | Sarah Werning                                                                                                                                                         |
| 106 |    727.666345 |    275.198096 | Matus Valach                                                                                                                                                          |
| 107 |    351.069403 |    190.994080 | T. Michael Keesey                                                                                                                                                     |
| 108 |    786.243207 |    455.506011 | Zimices                                                                                                                                                               |
| 109 |    760.117167 |    729.185997 | Gareth Monger                                                                                                                                                         |
| 110 |    740.202734 |    457.769322 | Michael Scroggie                                                                                                                                                      |
| 111 |    675.851852 |    118.388997 | Jagged Fang Designs                                                                                                                                                   |
| 112 |     96.182766 |     65.490521 | Christoph Schomburg                                                                                                                                                   |
| 113 |    408.720002 |    436.726095 | Chris huh                                                                                                                                                             |
| 114 |   1006.417368 |    504.754719 | Margot Michaud                                                                                                                                                        |
| 115 |    118.861022 |    546.898544 | Ferran Sayol                                                                                                                                                          |
| 116 |    836.987732 |    784.253669 | Smokeybjb                                                                                                                                                             |
| 117 |    770.068390 |    778.370853 | Scott Hartman                                                                                                                                                         |
| 118 |    393.351771 |    708.012778 | Margot Michaud                                                                                                                                                        |
| 119 |     65.515588 |    787.667044 | Kamil S. Jaron                                                                                                                                                        |
| 120 |    337.842875 |    541.541931 | Ferran Sayol                                                                                                                                                          |
| 121 |    746.339912 |     49.686404 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 122 |    637.955186 |    495.753635 | Armin Reindl                                                                                                                                                          |
| 123 |    668.499962 |    231.901199 | Michelle Site                                                                                                                                                         |
| 124 |    239.606894 |    106.288138 | Margot Michaud                                                                                                                                                        |
| 125 |    357.652655 |    777.142100 | Rainer Schoch                                                                                                                                                         |
| 126 |    232.995835 |     44.670551 | Zimices                                                                                                                                                               |
| 127 |    712.223984 |    646.900212 | Andrew A. Farke                                                                                                                                                       |
| 128 |    567.267145 |    536.858630 | Zimices                                                                                                                                                               |
| 129 |     33.490749 |    235.548784 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 130 |    320.558564 |     34.654441 | Tasman Dixon                                                                                                                                                          |
| 131 |    691.242926 |    336.990181 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 132 |    114.648257 |    587.987397 | Alexandre Vong                                                                                                                                                        |
| 133 |    631.248960 |    187.909779 | Gareth Monger                                                                                                                                                         |
| 134 |    871.485442 |    334.803988 | Zimices                                                                                                                                                               |
| 135 |    618.718669 |     16.118795 | Zimices                                                                                                                                                               |
| 136 |    337.424768 |    721.010625 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 137 |    768.820202 |    752.748174 | Anthony Caravaggi                                                                                                                                                     |
| 138 |    628.406360 |    292.711010 | Zimices                                                                                                                                                               |
| 139 |    908.295557 |    141.148207 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 140 |     27.861029 |     52.673665 | Birgit Lang                                                                                                                                                           |
| 141 |    747.439119 |    472.491243 | Kai R. Caspar                                                                                                                                                         |
| 142 |    510.583282 |    249.913369 | Crystal Maier                                                                                                                                                         |
| 143 |    881.832219 |    421.693261 | Tasman Dixon                                                                                                                                                          |
| 144 |    275.359499 |    592.714315 | Harold N Eyster                                                                                                                                                       |
| 145 |    391.080263 |    268.669797 | Margot Michaud                                                                                                                                                        |
| 146 |    245.365276 |    683.170227 | Matt Crook                                                                                                                                                            |
| 147 |    197.508077 |    286.997374 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 148 |    553.724027 |    355.022466 | Gareth Monger                                                                                                                                                         |
| 149 |    377.980835 |    525.494998 | Tracy A. Heath                                                                                                                                                        |
| 150 |    963.755599 |    439.048865 | T. Michael Keesey                                                                                                                                                     |
| 151 |    467.179226 |    162.111651 | Matt Crook                                                                                                                                                            |
| 152 |   1013.590228 |    198.239974 | Birgit Lang                                                                                                                                                           |
| 153 |    767.271876 |    283.474150 | Kai R. Caspar                                                                                                                                                         |
| 154 |    937.564344 |    548.421578 | Leann Biancani, photo by Kenneth Clifton                                                                                                                              |
| 155 |    986.657991 |      6.001612 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                             |
| 156 |    937.482215 |    693.650572 | Mariana Ruiz Villarreal                                                                                                                                               |
| 157 |    582.018747 |     26.526352 | Ferran Sayol                                                                                                                                                          |
| 158 |    240.542933 |    430.752298 | Matt Crook                                                                                                                                                            |
| 159 |    236.235706 |    459.667167 | Terpsichores                                                                                                                                                          |
| 160 |    726.699585 |    503.004217 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 161 |    612.945380 |    712.930094 | Matt Dempsey                                                                                                                                                          |
| 162 |    998.141376 |     83.196270 | Timothy Knepp of the U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                |
| 163 |    218.334620 |     83.266544 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 164 |    693.206700 |     80.717902 | Matt Crook                                                                                                                                                            |
| 165 |    703.630325 |    499.946142 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 166 |    161.671369 |    434.276305 | Scott Hartman                                                                                                                                                         |
| 167 |    162.762383 |    448.675316 | Ludwik Gasiorowski                                                                                                                                                    |
| 168 |    877.331444 |     41.998974 | T. Michael Keesey                                                                                                                                                     |
| 169 |   1010.704470 |    583.017543 | Ferran Sayol                                                                                                                                                          |
| 170 |    280.706186 |    414.209956 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                    |
| 171 |    265.513553 |    189.615537 | C. Camilo Julián-Caballero                                                                                                                                            |
| 172 |    913.336702 |    306.117976 | Steven Traver                                                                                                                                                         |
| 173 |    966.123653 |    616.017500 | Steven Traver                                                                                                                                                         |
| 174 |    946.345202 |    369.098912 | Chris huh                                                                                                                                                             |
| 175 |    196.031914 |    414.731631 | Rebecca Groom                                                                                                                                                         |
| 176 |    952.944858 |     14.190423 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 177 |     15.688310 |    508.612387 | Zimices                                                                                                                                                               |
| 178 |    574.170897 |     79.243640 | Tasman Dixon                                                                                                                                                          |
| 179 |    208.899010 |    195.709255 | Matt Crook                                                                                                                                                            |
| 180 |    489.904487 |    370.137891 | Matt Crook                                                                                                                                                            |
| 181 |    657.528639 |    473.332599 | Chris huh                                                                                                                                                             |
| 182 |     79.706662 |    756.603933 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 183 |    869.534561 |    528.188168 | Margot Michaud                                                                                                                                                        |
| 184 |    625.406832 |    622.907305 | Matt Crook                                                                                                                                                            |
| 185 |    914.675327 |    779.747455 | Tasman Dixon                                                                                                                                                          |
| 186 |    745.218565 |    161.845717 | Michelle Site                                                                                                                                                         |
| 187 |    786.790314 |    210.420690 | Matt Crook                                                                                                                                                            |
| 188 |    380.121687 |    128.174767 | NA                                                                                                                                                                    |
| 189 |    845.983789 |     34.786735 | Kai R. Caspar                                                                                                                                                         |
| 190 |    839.255373 |    697.990651 | Ferran Sayol                                                                                                                                                          |
| 191 |    373.949656 |    730.201982 | Scott Hartman                                                                                                                                                         |
| 192 |    349.231725 |    341.217354 | Zimices                                                                                                                                                               |
| 193 |    897.036211 |     76.159436 | Zimices                                                                                                                                                               |
| 194 |    647.017660 |    392.031734 | nicubunu                                                                                                                                                              |
| 195 |    286.892657 |     12.555407 | Tasman Dixon                                                                                                                                                          |
| 196 |    586.009332 |    397.162431 | Lauren Anderson                                                                                                                                                       |
| 197 |    657.210827 |     16.598302 | Matt Crook                                                                                                                                                            |
| 198 |    594.318345 |    701.162245 | Margot Michaud                                                                                                                                                        |
| 199 |    144.100028 |    261.447821 | Tasman Dixon                                                                                                                                                          |
| 200 |    868.536137 |    777.046576 | Tracy A. Heath                                                                                                                                                        |
| 201 |    263.225563 |    611.293598 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 202 |    461.390882 |    522.599918 | Margot Michaud                                                                                                                                                        |
| 203 |    431.145167 |    149.481826 | Mike Hanson                                                                                                                                                           |
| 204 |    338.671400 |    106.074236 | Caleb M. Brown                                                                                                                                                        |
| 205 |    734.832959 |     32.358834 | Jaime Headden                                                                                                                                                         |
| 206 |    883.473554 |     59.682163 | Smokeybjb (modified by Mike Keesey)                                                                                                                                   |
| 207 |    338.002007 |    567.476209 | Scott Hartman                                                                                                                                                         |
| 208 |    194.251586 |    593.651185 | Margot Michaud                                                                                                                                                        |
| 209 |    649.626709 |    712.894583 | Tasman Dixon                                                                                                                                                          |
| 210 |    722.085220 |    218.640157 | T. Michael Keesey                                                                                                                                                     |
| 211 |    598.795217 |    383.663583 | Steven Traver                                                                                                                                                         |
| 212 |    143.132307 |    423.743905 | T. Michael Keesey (after C. De Muizon)                                                                                                                                |
| 213 |    815.004760 |    694.031305 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 214 |     49.775799 |     83.411953 | Sarah Werning                                                                                                                                                         |
| 215 |    337.499730 |    404.670493 | Margot Michaud                                                                                                                                                        |
| 216 |    304.704260 |    205.570574 | Zimices                                                                                                                                                               |
| 217 |    656.648528 |    271.992007 | Steven Coombs                                                                                                                                                         |
| 218 |    607.173898 |    374.720194 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 219 |    137.046808 |    108.613907 | Scott Hartman                                                                                                                                                         |
| 220 |    190.369866 |    552.249329 | Gareth Monger                                                                                                                                                         |
| 221 |    993.081829 |     52.071814 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                    |
| 222 |    533.929904 |    557.046983 | Terpsichores                                                                                                                                                          |
| 223 |    871.668542 |    709.249602 | Jaime Headden                                                                                                                                                         |
| 224 |    224.314694 |    154.701345 | Margot Michaud                                                                                                                                                        |
| 225 |    789.544585 |    767.246857 | Sebastian Stabinger                                                                                                                                                   |
| 226 |     61.175902 |    392.316930 | Mathieu Basille                                                                                                                                                       |
| 227 |    106.596041 |    612.375452 | NA                                                                                                                                                                    |
| 228 |     17.071944 |    312.623446 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 229 |    166.161427 |    569.265317 | Danielle Alba                                                                                                                                                         |
| 230 |   1006.994432 |    109.844941 | NA                                                                                                                                                                    |
| 231 |    563.424549 |    249.346621 | Dean Schnabel                                                                                                                                                         |
| 232 |    239.790265 |    201.875155 | NA                                                                                                                                                                    |
| 233 |    356.213473 |    226.714174 | Yan Wong from drawing by T. F. Zimmermann                                                                                                                             |
| 234 |     17.667364 |    632.280684 | Matt Crook                                                                                                                                                            |
| 235 |    349.165625 |     43.759081 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 236 |    703.059667 |    472.546222 | Margot Michaud                                                                                                                                                        |
| 237 |    838.788774 |    645.260888 | Margot Michaud                                                                                                                                                        |
| 238 |     55.253742 |    293.885174 | Chris huh                                                                                                                                                             |
| 239 |    119.151182 |    452.204355 | Steven Traver                                                                                                                                                         |
| 240 |    879.804658 |    404.946188 | Jagged Fang Designs                                                                                                                                                   |
| 241 |    548.288121 |    445.067114 | Chris Jennings (Risiatto)                                                                                                                                             |
| 242 |    123.196056 |    373.692405 | Dean Schnabel                                                                                                                                                         |
| 243 |    106.808475 |    630.865686 | Jagged Fang Designs                                                                                                                                                   |
| 244 |     72.755758 |     59.523484 | Chris huh                                                                                                                                                             |
| 245 |    617.393567 |    509.062299 | Ricardo Araújo                                                                                                                                                        |
| 246 |    514.430274 |     12.731947 | Scott Hartman                                                                                                                                                         |
| 247 |    720.609898 |    456.871904 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 248 |    663.294061 |    172.137332 | Chris huh                                                                                                                                                             |
| 249 |     19.324623 |    365.465225 | Katie S. Collins                                                                                                                                                      |
| 250 |    995.959509 |    344.201627 | NA                                                                                                                                                                    |
| 251 |    942.459129 |    636.055114 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 252 |    298.101270 |    100.814470 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 253 |    612.035997 |    487.205458 | Shyamal                                                                                                                                                               |
| 254 |    474.753839 |    115.400593 | NA                                                                                                                                                                    |
| 255 |    856.005406 |    578.497013 | Matt Celeskey                                                                                                                                                         |
| 256 |    818.777206 |    495.007058 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 257 |    909.856282 |    271.582131 | Margot Michaud                                                                                                                                                        |
| 258 |     63.818643 |    359.301541 | Steven Traver                                                                                                                                                         |
| 259 |    832.482753 |    413.009930 | NA                                                                                                                                                                    |
| 260 |    859.778595 |    389.432904 | Matt Crook                                                                                                                                                            |
| 261 |    337.823780 |     16.668639 | Yan Wong (vectorization) from 1873 illustration                                                                                                                       |
| 262 |    464.580220 |     72.667063 | L. Shyamal                                                                                                                                                            |
| 263 |    183.916966 |    300.875661 | Chris huh                                                                                                                                                             |
| 264 |    458.840861 |    420.076713 | Steven Traver                                                                                                                                                         |
| 265 |     32.580356 |      8.757385 | Zimices                                                                                                                                                               |
| 266 |    177.845182 |    465.786437 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                          |
| 267 |    122.267382 |     11.094180 | Dmitry Bogdanov                                                                                                                                                       |
| 268 |    807.968790 |      9.855784 | Jack Mayer Wood                                                                                                                                                       |
| 269 |     40.689597 |    345.117697 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                                   |
| 270 |    822.635001 |    667.317291 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 271 |    141.587693 |    328.192356 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 272 |   1004.384815 |    361.848166 | Zimices                                                                                                                                                               |
| 273 |    978.406102 |    767.651685 | Harold N Eyster                                                                                                                                                       |
| 274 |    216.201759 |    690.436540 | Rachel Shoop                                                                                                                                                          |
| 275 |    690.808409 |    108.147498 | Scott Hartman                                                                                                                                                         |
| 276 |    540.269314 |    421.647406 | Joanna Wolfe                                                                                                                                                          |
| 277 |    546.079123 |    126.327208 | Michelle Site                                                                                                                                                         |
| 278 |    225.086655 |    555.427328 | Mattia Menchetti                                                                                                                                                      |
| 279 |    820.024205 |    783.704223 | T. Michael Keesey                                                                                                                                                     |
| 280 |    515.675140 |     75.109585 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 281 |    558.119335 |    382.181373 | Gareth Monger                                                                                                                                                         |
| 282 |     78.645544 |    456.419211 | Jagged Fang Designs                                                                                                                                                   |
| 283 |    213.306759 |    269.381942 | Steven Traver                                                                                                                                                         |
| 284 |    436.878580 |    405.149761 | T. Michael Keesey                                                                                                                                                     |
| 285 |    914.430028 |    288.939769 | NA                                                                                                                                                                    |
| 286 |     56.719209 |    756.115195 | Dave Angelini                                                                                                                                                         |
| 287 |   1001.776677 |    783.070232 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                         |
| 288 |    616.927172 |    396.783857 | T. Michael Keesey                                                                                                                                                     |
| 289 |    259.819161 |    470.702879 | Beth Reinke                                                                                                                                                           |
| 290 |    835.043181 |    614.314438 | Xavier Giroux-Bougard                                                                                                                                                 |
| 291 |    254.830050 |    560.206568 | Steven Traver                                                                                                                                                         |
| 292 |   1004.142860 |    623.926559 | Crystal Maier                                                                                                                                                         |
| 293 |    216.382254 |    716.516888 | Steven Traver                                                                                                                                                         |
| 294 |    609.671394 |    274.708440 | Birgit Lang; original image by virmisco.org                                                                                                                           |
| 295 |    266.093051 |    736.909130 | Matt Crook                                                                                                                                                            |
| 296 |    787.343610 |    273.823747 | Matt Crook                                                                                                                                                            |
| 297 |    966.652874 |    201.470430 | Jaime Headden                                                                                                                                                         |
| 298 |     91.095454 |    507.300664 | Scott Hartman                                                                                                                                                         |
| 299 |    358.488306 |    258.039877 | Jessica Anne Miller                                                                                                                                                   |
| 300 |    533.206655 |    243.381390 | FunkMonk                                                                                                                                                              |
| 301 |     28.433263 |    470.797110 | Beth Reinke                                                                                                                                                           |
| 302 |    515.365110 |     38.921877 | Dean Schnabel                                                                                                                                                         |
| 303 |      9.813215 |     81.521091 | Maija Karala                                                                                                                                                          |
| 304 |    560.271212 |    781.225736 | Matt Wilkins                                                                                                                                                          |
| 305 |    927.837231 |     21.670556 | Jagged Fang Designs                                                                                                                                                   |
| 306 |     42.363071 |    201.002137 | Xavier Giroux-Bougard                                                                                                                                                 |
| 307 |    649.706845 |    789.306534 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                     |
| 308 |    911.702119 |    322.095726 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 309 |    994.356047 |    711.026107 | Tracy A. Heath                                                                                                                                                        |
| 310 |    282.424735 |    650.256590 | Nancy Wyman (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 311 |    837.687594 |    113.113266 | NA                                                                                                                                                                    |
| 312 |   1001.407209 |    686.485691 | Original drawing by Nobu Tamura, vectorized by Roberto Díaz Sibaja                                                                                                    |
| 313 |    866.442790 |    496.685263 | Dean Schnabel                                                                                                                                                         |
| 314 |    428.875921 |    530.744979 | Iain Reid                                                                                                                                                             |
| 315 |    259.118341 |    535.512332 | Steven Traver                                                                                                                                                         |
| 316 |    299.093164 |    563.269186 | Steven Traver                                                                                                                                                         |
| 317 |   1008.688308 |    151.323218 | Ferran Sayol                                                                                                                                                          |
| 318 |    823.517812 |    677.016267 | Lisa Byrne                                                                                                                                                            |
| 319 |    460.697640 |    385.343025 | Alex Slavenko                                                                                                                                                         |
| 320 |    547.734610 |    490.975428 | Maxime Dahirel                                                                                                                                                        |
| 321 |    860.329170 |    557.568278 | T. Michael Keesey                                                                                                                                                     |
| 322 |    891.287687 |    720.992912 | Gareth Monger                                                                                                                                                         |
| 323 |    567.677090 |    553.697478 | NA                                                                                                                                                                    |
| 324 |    345.215751 |    132.074075 | Alex Slavenko                                                                                                                                                         |
| 325 |     18.390635 |    541.873727 | Collin Gross                                                                                                                                                          |
| 326 |    743.847516 |    657.796812 | Margot Michaud                                                                                                                                                        |
| 327 |    780.827494 |    709.248165 | Kai R. Caspar                                                                                                                                                         |
| 328 |    814.844791 |    513.568672 | NA                                                                                                                                                                    |
| 329 |    194.610209 |    787.949785 | Owen Jones                                                                                                                                                            |
| 330 |    189.607570 |    368.380276 | Jagged Fang Designs                                                                                                                                                   |
| 331 |    313.785525 |     11.790315 | Xavier Giroux-Bougard                                                                                                                                                 |
| 332 |     47.394015 |    222.259962 | Margot Michaud                                                                                                                                                        |
| 333 |    492.910956 |    391.948635 | NA                                                                                                                                                                    |
| 334 |    587.509674 |    281.620639 | Dinah Challen                                                                                                                                                         |
| 335 |    589.395821 |    476.968546 | Matt Crook                                                                                                                                                            |
| 336 |    714.920116 |    373.982962 | Gareth Monger                                                                                                                                                         |
| 337 |     98.817634 |    689.510442 | Mike Hanson                                                                                                                                                           |
| 338 |    859.333477 |    179.130734 | Kai R. Caspar                                                                                                                                                         |
| 339 |    417.277804 |    126.894022 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 340 |    963.992414 |    175.213136 | Tasman Dixon                                                                                                                                                          |
| 341 |    398.168777 |    420.183734 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                               |
| 342 |    361.392486 |    201.784204 | Zimices                                                                                                                                                               |
| 343 |    107.433611 |    755.050798 | Gareth Monger                                                                                                                                                         |
| 344 |    883.797255 |    441.125863 | Zimices                                                                                                                                                               |
| 345 |    843.784008 |    378.730419 | Kent Elson Sorgon                                                                                                                                                     |
| 346 |    448.665144 |    125.256736 | Alexandre Vong                                                                                                                                                        |
| 347 |    523.830049 |    354.427313 | Zimices                                                                                                                                                               |
| 348 |    544.808744 |    693.555828 | Steven Traver                                                                                                                                                         |
| 349 |     33.931820 |    144.772177 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 350 |    345.100526 |    366.236907 | Jimmy Bernot                                                                                                                                                          |
| 351 |    712.689447 |    235.690312 | Zimices                                                                                                                                                               |
| 352 |    143.449572 |    681.468294 | Ghedo (vectorized by T. Michael Keesey)                                                                                                                               |
| 353 |    325.932833 |    530.354991 | Jagged Fang Designs                                                                                                                                                   |
| 354 |    569.221251 |    108.995487 | \<U+0414\>\<U+0438\>\<U+0411\>\<U+0433\>\<U+0434\> (vectorized by T. Michael Keesey)                                                                                  |
| 355 |    307.299783 |    383.310015 | Birgit Lang                                                                                                                                                           |
| 356 |      9.391407 |    416.975863 | T. Michael Keesey                                                                                                                                                     |
| 357 |    118.671783 |    661.186936 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 358 |     17.684329 |    268.950597 | Mathew Wedel                                                                                                                                                          |
| 359 |     70.849665 |    209.057449 | Matt Crook                                                                                                                                                            |
| 360 |    992.806463 |    208.982104 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 361 |    791.408655 |    129.710819 | L. Shyamal                                                                                                                                                            |
| 362 |    574.380697 |     39.611725 | Chris huh                                                                                                                                                             |
| 363 |    921.975234 |    374.203770 | Emily Willoughby                                                                                                                                                      |
| 364 |    782.771053 |    232.266754 | Michael Scroggie                                                                                                                                                      |
| 365 |    576.435428 |    368.006580 | RS                                                                                                                                                                    |
| 366 |     12.024462 |    672.216924 | NA                                                                                                                                                                    |
| 367 |    313.089005 |    793.551700 | Chris huh                                                                                                                                                             |
| 368 |    591.201830 |    719.486816 | Tauana J. Cunha                                                                                                                                                       |
| 369 |    884.171192 |     18.572199 | Margot Michaud                                                                                                                                                        |
| 370 |    788.375175 |    248.666947 | Zimices                                                                                                                                                               |
| 371 |    689.162029 |    367.104596 | Jake Warner                                                                                                                                                           |
| 372 |     32.647027 |     94.109557 | Zimices                                                                                                                                                               |
| 373 |    913.159432 |     10.416462 | Melissa Broussard                                                                                                                                                     |
| 374 |    702.910148 |     14.291907 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                                       |
| 375 |    822.290233 |    713.200668 | Manabu Bessho-Uehara                                                                                                                                                  |
| 376 |    628.411874 |    722.273729 | Courtney Rockenbach                                                                                                                                                   |
| 377 |    143.916563 |    392.308949 | Mathew Wedel                                                                                                                                                          |
| 378 |    657.945025 |    189.570573 | Matt Crook                                                                                                                                                            |
| 379 |    182.271289 |    223.107421 | Gareth Monger                                                                                                                                                         |
| 380 |    423.823080 |    332.449227 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                                        |
| 381 |    759.533738 |    581.512376 | Stacy Spensley (Modified)                                                                                                                                             |
| 382 |    296.820612 |     49.993527 | Walter Vladimir                                                                                                                                                       |
| 383 |    480.376626 |    787.124242 | Margot Michaud                                                                                                                                                        |
| 384 |    246.651037 |    141.865455 | Alex Slavenko                                                                                                                                                         |
| 385 |    153.521600 |    508.182702 | Harold N Eyster                                                                                                                                                       |
| 386 |    356.106095 |    624.478652 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 387 |    760.203399 |    148.915770 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                          |
| 388 |    769.557622 |    796.571701 | Smokeybjb                                                                                                                                                             |
| 389 |     88.144567 |    525.346107 | Matt Crook                                                                                                                                                            |
| 390 |    127.167301 |    255.472640 | Matt Crook                                                                                                                                                            |
| 391 |    464.403296 |     10.402336 | Kamil S. Jaron                                                                                                                                                        |
| 392 |   1007.517595 |    404.145909 | NA                                                                                                                                                                    |
| 393 |    886.659586 |    109.520090 | Emily Willoughby                                                                                                                                                      |
| 394 |     89.617431 |     75.031249 | Dean Schnabel                                                                                                                                                         |
| 395 |    874.237934 |    146.612639 | Matt Crook                                                                                                                                                            |
| 396 |    782.828776 |    174.411678 | Sarah Alewijnse                                                                                                                                                       |
| 397 |    647.493739 |     33.069590 | C. Camilo Julián-Caballero                                                                                                                                            |
| 398 |    286.589819 |    220.679171 | Ian Burt (original) and T. Michael Keesey (vectorization)                                                                                                             |
| 399 |     12.014080 |    237.335643 | Beth Reinke                                                                                                                                                           |
| 400 |     96.095849 |    771.394230 | Matt Crook                                                                                                                                                            |
| 401 |    222.106118 |    780.672126 | Jaime Headden                                                                                                                                                         |
| 402 |    983.961909 |    117.596604 | Roberto Díaz Sibaja                                                                                                                                                   |
| 403 |    138.795152 |    278.287001 | Carlos Cano-Barbacil                                                                                                                                                  |
| 404 |    998.172167 |    752.934578 | Gareth Monger                                                                                                                                                         |
| 405 |    602.787201 |    687.612600 | Jaime Headden                                                                                                                                                         |
| 406 |    884.566729 |    275.987354 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                                   |
| 407 |    571.838539 |     67.209892 | Margot Michaud                                                                                                                                                        |
| 408 |     71.222185 |    471.778547 | Matt Crook                                                                                                                                                            |
| 409 |    352.651877 |     62.160319 | Mykle Hoban                                                                                                                                                           |
| 410 |    549.552756 |    214.875616 | B. Duygu Özpolat                                                                                                                                                      |
| 411 |    140.935542 |    789.232861 | Berivan Temiz                                                                                                                                                         |
| 412 |    297.631908 |    395.388633 | Steven Coombs                                                                                                                                                         |
| 413 |    859.553476 |      9.954988 | Scott Hartman                                                                                                                                                         |
| 414 |     83.311627 |     95.868160 | Jagged Fang Designs                                                                                                                                                   |
| 415 |    789.056368 |    340.732340 | Caleb M. Brown                                                                                                                                                        |
| 416 |    176.167440 |    277.778960 | Jack Mayer Wood                                                                                                                                                       |
| 417 |    110.864432 |    391.094273 | Michelle Site                                                                                                                                                         |
| 418 |    369.381052 |      7.386479 | Jaime Headden                                                                                                                                                         |
| 419 |    192.320861 |     67.038013 | Jagged Fang Designs                                                                                                                                                   |
| 420 |    927.852487 |    565.406069 | Scott Hartman                                                                                                                                                         |
| 421 |    721.828248 |    610.824839 | Michelle Site                                                                                                                                                         |
| 422 |   1008.572907 |    241.085185 | NA                                                                                                                                                                    |
| 423 |    564.926396 |    283.511142 | Chris huh                                                                                                                                                             |
| 424 |    774.620482 |    194.620321 | Birgit Lang                                                                                                                                                           |
| 425 |    380.721242 |    451.045566 | Maija Karala                                                                                                                                                          |
| 426 |    866.708110 |    413.699521 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 427 |    211.731118 |     70.160573 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
| 428 |    103.032882 |     44.127338 | Matt Dempsey                                                                                                                                                          |
| 429 |    178.514482 |    397.424938 | Scott Hartman                                                                                                                                                         |
| 430 |    685.047867 |    127.704532 | Scott Hartman                                                                                                                                                         |
| 431 |    729.190006 |     76.685449 | Rebecca Groom                                                                                                                                                         |
| 432 |    105.420883 |    696.067343 | Michael P. Taylor                                                                                                                                                     |
| 433 |    164.624900 |    104.467847 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 434 |    184.999404 |    532.016437 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 435 |    367.034043 |    720.216120 | Jagged Fang Designs                                                                                                                                                   |
| 436 |    993.896586 |     74.514041 | Gareth Monger                                                                                                                                                         |
| 437 |    502.377498 |     95.328138 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                         |
| 438 |    519.250941 |    381.168060 | Steven Traver                                                                                                                                                         |
| 439 |    990.451845 |    742.480553 | Scott Hartman                                                                                                                                                         |
| 440 |    544.636859 |    790.534419 | Zimices                                                                                                                                                               |
| 441 |    880.679809 |    173.752659 | Jagged Fang Designs                                                                                                                                                   |
| 442 |     31.567030 |    726.969820 | Chris huh                                                                                                                                                             |
| 443 |    975.954903 |    707.285358 | Matt Crook                                                                                                                                                            |
| 444 |   1003.459631 |    517.567202 | Iain Reid                                                                                                                                                             |
| 445 |    951.471813 |    531.898592 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 446 |    344.570666 |    708.028751 | Margot Michaud                                                                                                                                                        |
| 447 |    373.288750 |    282.823515 | Mathew Wedel                                                                                                                                                          |
| 448 |    726.195360 |    788.427220 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                          |
| 449 |    926.248334 |    647.905067 | CNZdenek                                                                                                                                                              |
| 450 |     29.177230 |    395.987004 | Margot Michaud                                                                                                                                                        |
| 451 |    586.963135 |    777.045437 | Margot Michaud                                                                                                                                                        |
| 452 |    198.442981 |     40.831688 | Scott Hartman                                                                                                                                                         |
| 453 |    367.541743 |     51.612843 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 454 |    898.477305 |    794.524333 | Gareth Monger                                                                                                                                                         |
| 455 |     18.269656 |    651.208041 | Pete Buchholz                                                                                                                                                         |
| 456 |   1008.516179 |    311.004111 | Birgit Lang                                                                                                                                                           |
| 457 |    566.496279 |    240.375960 | Jack Mayer Wood                                                                                                                                                       |
| 458 |    878.891729 |    552.417187 | Kent Elson Sorgon                                                                                                                                                     |
| 459 |    889.299056 |    383.481355 | Lauren Sumner-Rooney                                                                                                                                                  |
| 460 |    293.317495 |    293.394747 | Jaime Headden, modified by T. Michael Keesey                                                                                                                          |
| 461 |    220.364107 |    703.019687 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
| 462 |    979.785423 |    464.485308 | Felix Vaux                                                                                                                                                            |
| 463 |    593.555381 |    196.768161 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 464 |    989.837150 |    175.837297 | T. Michael Keesey                                                                                                                                                     |
| 465 |    819.906068 |    630.635450 | T. Michael Keesey                                                                                                                                                     |
| 466 |    427.813756 |    138.752755 | Zimices                                                                                                                                                               |
| 467 |    153.498932 |    644.278885 | Christoph Schomburg                                                                                                                                                   |
| 468 |    228.824172 |    603.122270 | Steven Traver                                                                                                                                                         |
| 469 |    804.858992 |    539.355999 | Sarah Werning                                                                                                                                                         |
| 470 |    449.759465 |    464.016103 | Gareth Monger                                                                                                                                                         |
| 471 |    979.215651 |     27.759465 | Caleb M. Brown                                                                                                                                                        |
| 472 |    109.855841 |    295.488206 | Chris huh                                                                                                                                                             |
| 473 |    514.893793 |    448.128631 | Tasman Dixon                                                                                                                                                          |
| 474 |     90.043694 |    368.323784 | NA                                                                                                                                                                    |
| 475 |    835.121549 |    543.081333 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 476 |    416.632474 |    256.542534 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 477 |    463.813418 |    232.919083 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 478 |    967.555917 |    283.639519 | Matt Crook                                                                                                                                                            |
| 479 |     28.492270 |    323.639107 | Gareth Monger                                                                                                                                                         |
| 480 |    456.959486 |    712.137829 | Zimices                                                                                                                                                               |
| 481 |    534.981237 |    459.847548 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 482 |    459.486433 |    433.135092 | Dmitry Bogdanov                                                                                                                                                       |
| 483 |    166.611081 |     68.927566 | NA                                                                                                                                                                    |
| 484 |    599.400146 |    187.614748 | Chris huh                                                                                                                                                             |
| 485 |    954.585744 |    578.945224 | Matt Martyniuk                                                                                                                                                        |
| 486 |    485.779607 |    347.551294 | Rene Martin                                                                                                                                                           |
| 487 |    666.191140 |    496.008116 | Dean Schnabel                                                                                                                                                         |
| 488 |    585.660289 |    597.617354 | Emily Willoughby                                                                                                                                                      |
| 489 |    453.873111 |    534.358724 | NA                                                                                                                                                                    |
| 490 |     82.154105 |    474.423558 | Matt Crook                                                                                                                                                            |
| 491 |    956.273092 |    135.955695 | Matt Crook                                                                                                                                                            |
| 492 |    161.518205 |    780.516011 | Melissa Ingala                                                                                                                                                        |
| 493 |    258.428042 |    625.062602 | Scott Hartman                                                                                                                                                         |
| 494 |    294.749174 |    177.291135 | Ville-Veikko Sinkkonen                                                                                                                                                |
| 495 |     92.250664 |    107.931798 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                        |
| 496 |    764.084940 |    634.837342 | Alex Slavenko                                                                                                                                                         |
| 497 |    614.167091 |    742.134131 | M Kolmann                                                                                                                                                             |
| 498 |    542.271911 |    765.446534 | Mathew Wedel                                                                                                                                                          |
| 499 |    338.178853 |    124.034499 | Chris huh                                                                                                                                                             |
| 500 |    307.806028 |    408.673656 | Ghedoghedo, vectorized by Zimices                                                                                                                                     |
| 501 |    268.533944 |    211.967471 | Cristina Guijarro                                                                                                                                                     |
| 502 |    330.816433 |    393.315556 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 503 |    594.631058 |    125.596621 | Rene Martin                                                                                                                                                           |
| 504 |    266.298710 |     50.757043 | Iain Reid                                                                                                                                                             |
| 505 |    179.633396 |    307.810482 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                    |
| 506 |     40.599353 |    155.382844 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
| 507 |    431.415963 |    456.385899 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 508 |    508.635499 |    792.462023 | Christoph Schomburg                                                                                                                                                   |
| 509 |    752.775811 |     82.762520 | Jagged Fang Designs                                                                                                                                                   |
| 510 |    821.509480 |     34.483371 | Alexandra van der Geer                                                                                                                                                |
| 511 |    244.331679 |     19.641951 | Caleb M. Brown                                                                                                                                                        |
| 512 |    882.127328 |    320.024941 | Smokeybjb                                                                                                                                                             |
| 513 |    165.088928 |    113.968311 | Scott Hartman                                                                                                                                                         |
| 514 |    477.361528 |    253.817798 | T. Michael Keesey (after Heinrich Harder)                                                                                                                             |
| 515 |    928.605690 |    627.203491 | Jagged Fang Designs                                                                                                                                                   |
| 516 |    828.117530 |    421.687424 | Zimices                                                                                                                                                               |
| 517 |     11.903551 |    774.771806 | Ferran Sayol                                                                                                                                                          |
| 518 |    869.872490 |    359.243162 | Dean Schnabel                                                                                                                                                         |
| 519 |   1014.302406 |    667.580825 | T. Michael Keesey                                                                                                                                                     |
| 520 |    457.543042 |    375.851869 | Mathew Wedel                                                                                                                                                          |
| 521 |    693.202563 |    789.620083 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                            |
| 522 |    604.576557 |    178.895690 | Iain Reid                                                                                                                                                             |
| 523 |    942.113696 |    712.683116 | T. Michael Keesey (after Walker & al.)                                                                                                                                |
| 524 |    803.870015 |    517.009969 | Jake Warner                                                                                                                                                           |
| 525 |    837.148014 |    576.267470 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 526 |    171.348135 |    545.146604 | Rebecca Groom                                                                                                                                                         |
| 527 |    529.210296 |    710.153077 | Scott Hartman                                                                                                                                                         |
| 528 |    449.243688 |    794.811562 | NA                                                                                                                                                                    |
| 529 |    119.822730 |     23.708479 | Tony Ayling                                                                                                                                                           |
| 530 |    246.338629 |    251.459655 | Matt Crook                                                                                                                                                            |
| 531 |    876.526480 |    500.546164 | T. Michael Keesey                                                                                                                                                     |
| 532 |     19.511171 |    608.776076 | AnAgnosticGod (vectorized by T. Michael Keesey)                                                                                                                       |
| 533 |     29.192547 |     71.062938 | T. Michael Keesey                                                                                                                                                     |
| 534 |    929.510366 |    759.200611 | Zimices                                                                                                                                                               |
| 535 |    961.723491 |    558.198006 | Armin Reindl                                                                                                                                                          |
| 536 |     15.734575 |    332.556676 | Margot Michaud                                                                                                                                                        |
| 537 |    348.155111 |    796.398913 | M Kolmann                                                                                                                                                             |
| 538 |   1006.326436 |    566.293163 | Jake Warner                                                                                                                                                           |
| 539 |     44.311315 |    716.807580 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 540 |    810.702148 |    198.655170 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                                 |
| 541 |    141.970070 |    667.934827 | Tracy A. Heath                                                                                                                                                        |
| 542 |    242.259144 |     91.966340 | David Tana                                                                                                                                                            |
| 543 |    402.443277 |    409.289013 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                         |
| 544 |    309.778267 |    636.605923 | Caleb M. Brown                                                                                                                                                        |
| 545 |    104.177185 |    196.147616 | Bennet McComish, photo by Avenue                                                                                                                                      |

    #> Your tweet has been posted!
