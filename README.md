
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

T. Michael Keesey, Trond R. Oskars, Ferran Sayol, Zimices, Matt Crook,
Margot Michaud, Ville-Veikko Sinkkonen, CNZdenek, Alex Slavenko, Hugo
Gruson, Gabriela Palomo-Munoz, Steven Traver, Robert Gay, Erika
Schumacher, Steven Blackwood, Christoph Schomburg, Gareth Monger, Jagged
Fang Designs, Dmitry Bogdanov (vectorized by T. Michael Keesey), Harold
N Eyster, Jaime Headden, Marie Russell, Chris huh, Birgit Lang, Beth
Reinke, Noah Schlottman, photo by Martin V. Sørensen, Kamil S. Jaron,
Scott Hartman, Saguaro Pictures (source photo) and T. Michael Keesey,
Pearson Scott Foresman (vectorized by T. Michael Keesey), Mali’o Kodis,
photograph by G. Giribet, Xavier Giroux-Bougard, Noah Schlottman,
kreidefossilien.de, Matt Martyniuk (modified by T. Michael Keesey),
Darren Naish (vectorize by T. Michael Keesey), Mo Hassan, Nicholas J.
Czaplewski, vectorized by Zimices, Tasman Dixon, Verisimilus, DW Bapst
(modified from Bates et al., 2005), Nobu Tamura (vectorized by T.
Michael Keesey), www.studiospectre.com, Sarah Werning, Adrian Reich,
Sergio A. Muñoz-Gómez, Jimmy Bernot, Katie S. Collins, Ignacio
Contreras, Markus A. Grohme, Original drawing by Dmitry Bogdanov,
vectorized by Roberto Díaz Sibaja, Brockhaus and Efron, Tomas Willems
(vectorized by T. Michael Keesey), Caleb M. Brown, Roberto Díaz Sibaja,
Emily Willoughby, Anthony Caravaggi, Meliponicultor Itaymbere, Bruno C.
Vellutini, Conty (vectorized by T. Michael Keesey), Mathew Wedel, Tony
Ayling, Fernando Carezzano, Sharon Wegner-Larsen, FunkMonk, Haplochromis
(vectorized by T. Michael Keesey), (after Spotila 2004), Florian Pfaff,
Duane Raver (vectorized by T. Michael Keesey), Andy Wilson, Maky
(vectorization), Gabriella Skollar (photography), Rebecca Lewis
(editing), (after McCulloch 1908), Jaime A. Headden (vectorized by T.
Michael Keesey), FunkMonk (Michael B.H.; vectorized by T. Michael
Keesey), Tauana J. Cunha, Alexandre Vong, John Gould (vectorized by T.
Michael Keesey), Dein Freund der Baum (vectorized by T. Michael Keesey),
Michael Scroggie, Rebecca Groom, T. Michael Keesey (after James & al.),
Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy, C.
Camilo Julián-Caballero, Ieuan Jones, Collin Gross, Mykle Hoban, Dean
Schnabel, Myriam\_Ramirez, Inessa Voet, Stuart Humphries, Carlos
Cano-Barbacil, Dave Souza (vectorized by T. Michael Keesey), B. Duygu
Özpolat, terngirl, Philip Chalmers (vectorized by T. Michael Keesey),
Young and Zhao (1972:figure 4), modified by Michael P. Taylor, Tom
Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Jake Warner, Tyler Greenfield and Dean Schnabel, Cesar
Julian, Martin R. Smith, after Skovsted et al 2015, Mattia Menchetti,
FJDegrange, Noah Schlottman, photo by Casey Dunn, Iain Reid, Shyamal,
Jesús Gómez, vectorized by Zimices, Lukasiniho, Manabu Sakamoto, Julio
Garza, James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez,
Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey),
Jose Carlos Arenas-Monroy, Original scheme by ‘Haplochromis’, vectorized
by Roberto Díaz Sibaja, Qiang Ou, Douglas Brown (modified by T. Michael
Keesey), Ingo Braasch, Lafage, Jack Mayer Wood, T. Michael Keesey (after
Masteraah), Aviceda (vectorized by T. Michael Keesey), Mathilde
Cordellier, Steven Coombs, Jiekun He, Mette Aumala, Amanda Katzer, Felix
Vaux, Peter Coxhead, Dmitry Bogdanov, Robert Gay, modifed from
Olegivvit, Henry Lydecker, Campbell Fleming, Armin Reindl, Jan A.
Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized
by T. Michael Keesey), Emily Jane McTavish, Maija Karala, Mariana Ruiz
Villarreal (modified by T. Michael Keesey), Kai R. Caspar, Mateus Zica
(modified by T. Michael Keesey), Dexter R. Mardis, Nobu Tamura, Ellen
Edmonson (illustration) and Timothy J. Bartley (silhouette), Skye
McDavid, SauropodomorphMonarch, Rene Martin, Meyers
Konversations-Lexikon 1897 (vectorized: Yan Wong), L. Shyamal, Milton
Tan, Apokryltaros (vectorized by T. Michael Keesey), Agnello Picorelli,
Andreas Hejnol, Michelle Site, Mary Harrsch (modified by T. Michael
Keesey), Michele M Tobias, T. Michael Keesey (from a photograph by Frank
Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences), Danielle Alba,
Andrew A. Farke, Emily Jane McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Becky Barnes, Mali’o Kodis, photograph by John Slapcinsky, Smokeybjb,
Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela
Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough
(vectorized by T. Michael Keesey), Moussa Direct Ltd. (photography) and
T. Michael Keesey (vectorization), Nobu Tamura (modified by T. Michael
Keesey), S.Martini, Matt Dempsey, Cagri Cevrim, NOAA Great Lakes
Environmental Research Laboratory (illustration) and Timothy J. Bartley
(silhouette), Obsidian Soul (vectorized by T. Michael Keesey), Scott
Hartman (modified by T. Michael Keesey), Andrew R. Gehrke, Tyler
Greenfield, Yan Wong, Yusan Yang, Jay Matternes (vectorized by T.
Michael Keesey), Tambja (vectorized by T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    116.618677 |    254.602420 | T. Michael Keesey                                                                                                                                                     |
|   2 |    925.964377 |    655.748721 | Trond R. Oskars                                                                                                                                                       |
|   3 |     92.044620 |    355.391957 | T. Michael Keesey                                                                                                                                                     |
|   4 |    308.290615 |    454.109780 | Ferran Sayol                                                                                                                                                          |
|   5 |    744.859624 |    217.071404 | Zimices                                                                                                                                                               |
|   6 |    855.026981 |    521.606690 | T. Michael Keesey                                                                                                                                                     |
|   7 |    247.916979 |    275.301774 | Matt Crook                                                                                                                                                            |
|   8 |    592.820798 |    526.726650 | Margot Michaud                                                                                                                                                        |
|   9 |    700.576060 |    132.268371 | Ville-Veikko Sinkkonen                                                                                                                                                |
|  10 |    112.285949 |    157.506133 | T. Michael Keesey                                                                                                                                                     |
|  11 |     70.840470 |    695.589249 | CNZdenek                                                                                                                                                              |
|  12 |    949.682380 |    296.382569 | Alex Slavenko                                                                                                                                                         |
|  13 |    905.773876 |    103.236974 | Hugo Gruson                                                                                                                                                           |
|  14 |    721.954615 |    662.430282 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  15 |    649.199513 |    332.135413 | Steven Traver                                                                                                                                                         |
|  16 |    335.763332 |    324.683379 | Robert Gay                                                                                                                                                            |
|  17 |    323.324852 |    111.682934 | Erika Schumacher                                                                                                                                                      |
|  18 |    626.415791 |    433.361406 | Steven Blackwood                                                                                                                                                      |
|  19 |    256.499316 |    381.272311 | Zimices                                                                                                                                                               |
|  20 |    857.177015 |    182.199991 | Ferran Sayol                                                                                                                                                          |
|  21 |    391.853787 |    734.162007 | Ferran Sayol                                                                                                                                                          |
|  22 |    911.767174 |    406.936272 | Christoph Schomburg                                                                                                                                                   |
|  23 |    253.642490 |     40.227797 | Zimices                                                                                                                                                               |
|  24 |    787.196791 |     44.827716 | Gareth Monger                                                                                                                                                         |
|  25 |    776.053082 |    776.880942 | Jagged Fang Designs                                                                                                                                                   |
|  26 |    519.912450 |    689.911158 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  27 |    417.478128 |    220.080780 | NA                                                                                                                                                                    |
|  28 |    652.250865 |    757.337080 | Harold N Eyster                                                                                                                                                       |
|  29 |    177.456703 |    125.874661 | Jaime Headden                                                                                                                                                         |
|  30 |    182.982751 |    712.290662 | Marie Russell                                                                                                                                                         |
|  31 |    490.527813 |    157.164916 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  32 |    543.191605 |    480.750654 | Chris huh                                                                                                                                                             |
|  33 |    833.117931 |    300.121090 | Birgit Lang                                                                                                                                                           |
|  34 |    923.476028 |    227.170513 | Matt Crook                                                                                                                                                            |
|  35 |    220.953297 |    579.146407 | T. Michael Keesey                                                                                                                                                     |
|  36 |    138.551593 |    626.352491 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  37 |    613.974744 |    233.565779 | Margot Michaud                                                                                                                                                        |
|  38 |    761.898364 |    476.795931 | Beth Reinke                                                                                                                                                           |
|  39 |     62.223734 |    535.622870 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                          |
|  40 |    100.715779 |    418.086769 | Margot Michaud                                                                                                                                                        |
|  41 |    589.301865 |    120.820031 | Kamil S. Jaron                                                                                                                                                        |
|  42 |    527.905443 |    571.987505 | Jagged Fang Designs                                                                                                                                                   |
|  43 |    519.909818 |    745.022357 | Scott Hartman                                                                                                                                                         |
|  44 |    987.926690 |    429.205395 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                                 |
|  45 |    300.196566 |    761.229804 | Chris huh                                                                                                                                                             |
|  46 |    859.018558 |    600.634559 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
|  47 |    951.464889 |    120.077222 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                |
|  48 |     50.832630 |    255.307411 | T. Michael Keesey                                                                                                                                                     |
|  49 |     67.661534 |     84.837089 | Xavier Giroux-Bougard                                                                                                                                                 |
|  50 |    973.290117 |     69.089424 | Noah Schlottman                                                                                                                                                       |
|  51 |    534.433762 |    349.623572 | kreidefossilien.de                                                                                                                                                    |
|  52 |    490.560252 |     55.850327 | Chris huh                                                                                                                                                             |
|  53 |    958.994797 |    503.921478 | Scott Hartman                                                                                                                                                         |
|  54 |    344.822968 |    170.429372 | Jagged Fang Designs                                                                                                                                                   |
|  55 |    663.021972 |     25.637772 | Noah Schlottman                                                                                                                                                       |
|  56 |    719.615381 |    541.373640 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                                        |
|  57 |    415.298960 |    609.438660 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
|  58 |    883.061932 |    745.258341 | Mo Hassan                                                                                                                                                             |
|  59 |    314.414841 |    646.852099 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                         |
|  60 |    195.650716 |    222.420805 | Tasman Dixon                                                                                                                                                          |
|  61 |    682.749395 |     74.170361 | Verisimilus                                                                                                                                                           |
|  62 |    955.099820 |    554.263945 | Matt Crook                                                                                                                                                            |
|  63 |    401.131071 |     37.652505 | Zimices                                                                                                                                                               |
|  64 |    519.347973 |    245.850850 | Zimices                                                                                                                                                               |
|  65 |    123.540232 |     41.270547 | NA                                                                                                                                                                    |
|  66 |    632.255081 |    707.864274 | Tasman Dixon                                                                                                                                                          |
|  67 |    814.153757 |    517.067877 | DW Bapst (modified from Bates et al., 2005)                                                                                                                           |
|  68 |    824.524490 |    100.219837 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  69 |    773.004420 |    403.096491 | www.studiospectre.com                                                                                                                                                 |
|  70 |    492.756045 |    782.831929 | NA                                                                                                                                                                    |
|  71 |    186.640180 |     91.548433 | Chris huh                                                                                                                                                             |
|  72 |    805.156416 |    354.766224 | Gareth Monger                                                                                                                                                         |
|  73 |    274.450209 |    663.924477 | Scott Hartman                                                                                                                                                         |
|  74 |    804.019482 |    702.794971 | Ferran Sayol                                                                                                                                                          |
|  75 |    197.597456 |     68.447281 | NA                                                                                                                                                                    |
|  76 |     46.567594 |    109.610133 | Tasman Dixon                                                                                                                                                          |
|  77 |    838.712928 |    437.707308 | Sarah Werning                                                                                                                                                         |
|  78 |    126.192220 |    553.162389 | Adrian Reich                                                                                                                                                          |
|  79 |    392.930407 |    108.224791 | Matt Crook                                                                                                                                                            |
|  80 |    710.080073 |    761.821407 | Ferran Sayol                                                                                                                                                          |
|  81 |    110.089038 |    765.943858 | Margot Michaud                                                                                                                                                        |
|  82 |    560.985658 |    766.314850 | Erika Schumacher                                                                                                                                                      |
|  83 |    462.837333 |    509.131014 | Zimices                                                                                                                                                               |
|  84 |     47.961419 |    631.039282 | NA                                                                                                                                                                    |
|  85 |    263.482239 |    204.207387 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
|  86 |     77.911683 |    727.907425 | Zimices                                                                                                                                                               |
|  87 |    507.424534 |    520.304676 | Jimmy Bernot                                                                                                                                                          |
|  88 |    973.494160 |    240.412019 | Matt Crook                                                                                                                                                            |
|  89 |    497.975246 |    442.138185 | Matt Crook                                                                                                                                                            |
|  90 |    144.548729 |    469.095028 | Chris huh                                                                                                                                                             |
|  91 |    340.726855 |    254.150193 | Margot Michaud                                                                                                                                                        |
|  92 |    986.270893 |    736.641007 | Katie S. Collins                                                                                                                                                      |
|  93 |    335.706737 |    721.225213 | Margot Michaud                                                                                                                                                        |
|  94 |    717.344463 |    583.679136 | Ignacio Contreras                                                                                                                                                     |
|  95 |    946.475267 |    532.926052 | Markus A. Grohme                                                                                                                                                      |
|  96 |    715.105568 |    366.196649 | Gareth Monger                                                                                                                                                         |
|  97 |     68.424927 |    172.961319 | Chris huh                                                                                                                                                             |
|  98 |     84.245178 |    478.813530 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  99 |     75.664260 |    501.272479 | Scott Hartman                                                                                                                                                         |
| 100 |    463.361828 |     85.127832 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 101 |    230.115956 |    751.789720 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 102 |    656.925502 |    562.420238 | Chris huh                                                                                                                                                             |
| 103 |    201.445093 |    424.857223 | Margot Michaud                                                                                                                                                        |
| 104 |     26.391741 |    254.157607 | Brockhaus and Efron                                                                                                                                                   |
| 105 |    963.005194 |    782.019458 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                                       |
| 106 |    444.866570 |    532.738985 | Caleb M. Brown                                                                                                                                                        |
| 107 |    673.556011 |    168.716804 | Markus A. Grohme                                                                                                                                                      |
| 108 |    503.161617 |     18.932563 | Margot Michaud                                                                                                                                                        |
| 109 |    165.968579 |    286.420708 | Roberto Díaz Sibaja                                                                                                                                                   |
| 110 |    723.307897 |    614.275747 | Christoph Schomburg                                                                                                                                                   |
| 111 |     20.242937 |    729.777960 | Steven Traver                                                                                                                                                         |
| 112 |   1005.508020 |    605.899402 | Matt Crook                                                                                                                                                            |
| 113 |     22.982829 |    203.718067 | Ferran Sayol                                                                                                                                                          |
| 114 |    603.399362 |    636.026286 | Emily Willoughby                                                                                                                                                      |
| 115 |    765.218627 |    594.620521 | NA                                                                                                                                                                    |
| 116 |    867.916229 |    380.677079 | Anthony Caravaggi                                                                                                                                                     |
| 117 |    594.070098 |    743.673875 | Meliponicultor Itaymbere                                                                                                                                              |
| 118 |    177.123403 |    337.698732 | Ferran Sayol                                                                                                                                                          |
| 119 |    256.044106 |    576.427515 | Bruno C. Vellutini                                                                                                                                                    |
| 120 |    956.636155 |    445.821700 | Chris huh                                                                                                                                                             |
| 121 |    208.533108 |    174.779603 | Steven Traver                                                                                                                                                         |
| 122 |    362.490901 |    367.017771 | Matt Crook                                                                                                                                                            |
| 123 |    500.267696 |    633.260871 | Chris huh                                                                                                                                                             |
| 124 |    543.541811 |     44.803670 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 125 |    592.801187 |     23.247648 | Mathew Wedel                                                                                                                                                          |
| 126 |    267.536402 |    710.493842 | Chris huh                                                                                                                                                             |
| 127 |    205.180174 |    663.984358 | Matt Crook                                                                                                                                                            |
| 128 |     44.465879 |    761.237434 | Tony Ayling                                                                                                                                                           |
| 129 |    981.207966 |    338.426840 | Chris huh                                                                                                                                                             |
| 130 |    666.572203 |     93.600434 | Jagged Fang Designs                                                                                                                                                   |
| 131 |    515.768685 |     79.614366 | Tasman Dixon                                                                                                                                                          |
| 132 |     16.637642 |    147.366704 | Anthony Caravaggi                                                                                                                                                     |
| 133 |    917.922415 |    556.765304 | Scott Hartman                                                                                                                                                         |
| 134 |    635.143816 |    269.286262 | Margot Michaud                                                                                                                                                        |
| 135 |    128.350979 |    325.182704 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 136 |    378.399246 |    396.170000 | Zimices                                                                                                                                                               |
| 137 |    180.403097 |    389.842456 | Fernando Carezzano                                                                                                                                                    |
| 138 |    995.110811 |    329.754288 | Sarah Werning                                                                                                                                                         |
| 139 |    736.558054 |    326.379035 | Sharon Wegner-Larsen                                                                                                                                                  |
| 140 |    554.523784 |    619.076503 | FunkMonk                                                                                                                                                              |
| 141 |     81.585279 |    244.341267 | Matt Crook                                                                                                                                                            |
| 142 |     29.268661 |    428.094533 | Matt Crook                                                                                                                                                            |
| 143 |    391.564326 |    334.285451 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 144 |    675.929758 |    705.042020 | Matt Crook                                                                                                                                                            |
| 145 |    647.193733 |    592.321446 | Katie S. Collins                                                                                                                                                      |
| 146 |    853.047794 |     17.607387 | (after Spotila 2004)                                                                                                                                                  |
| 147 |    651.933799 |    457.854879 | Ignacio Contreras                                                                                                                                                     |
| 148 |    887.510062 |     53.736737 | Florian Pfaff                                                                                                                                                         |
| 149 |    525.655237 |    709.992273 | Chris huh                                                                                                                                                             |
| 150 |    188.025226 |    257.789099 | Ferran Sayol                                                                                                                                                          |
| 151 |    539.072216 |    724.618663 | Zimices                                                                                                                                                               |
| 152 |    330.435607 |    691.811410 | Gareth Monger                                                                                                                                                         |
| 153 |    332.789404 |    393.129894 | NA                                                                                                                                                                    |
| 154 |    227.073258 |    186.775171 | Gareth Monger                                                                                                                                                         |
| 155 |    806.281644 |     63.463500 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                         |
| 156 |    784.932863 |    683.701208 | Andy Wilson                                                                                                                                                           |
| 157 |    790.305617 |    174.358033 | Steven Traver                                                                                                                                                         |
| 158 |    329.948184 |     56.971953 | Steven Traver                                                                                                                                                         |
| 159 |    687.696012 |    512.918378 | NA                                                                                                                                                                    |
| 160 |    571.078635 |    702.736695 | Maky (vectorization), Gabriella Skollar (photography), Rebecca Lewis (editing)                                                                                        |
| 161 |    572.977445 |    398.643381 | Margot Michaud                                                                                                                                                        |
| 162 |    356.513982 |    604.011377 | Zimices                                                                                                                                                               |
| 163 |    854.085254 |    782.245935 | Ferran Sayol                                                                                                                                                          |
| 164 |    717.645129 |    226.230146 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 165 |    733.203705 |    740.315758 | Kamil S. Jaron                                                                                                                                                        |
| 166 |    285.321955 |    679.851597 | Chris huh                                                                                                                                                             |
| 167 |    291.231614 |    275.578399 | Matt Crook                                                                                                                                                            |
| 168 |    950.620665 |    383.074068 | (after McCulloch 1908)                                                                                                                                                |
| 169 |     42.298780 |    457.716580 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 170 |     16.311857 |    576.056501 | NA                                                                                                                                                                    |
| 171 |    576.848048 |    275.946214 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                                    |
| 172 |    528.146512 |     96.799013 | NA                                                                                                                                                                    |
| 173 |    121.369851 |     67.580417 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                              |
| 174 |     34.092027 |     22.902878 | Steven Traver                                                                                                                                                         |
| 175 |    976.088804 |    606.254176 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 176 |    166.509588 |     13.222940 | CNZdenek                                                                                                                                                              |
| 177 |   1003.471321 |    289.503340 | Tauana J. Cunha                                                                                                                                                       |
| 178 |    955.271384 |    405.990196 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 179 |    713.934201 |    460.595001 | CNZdenek                                                                                                                                                              |
| 180 |    406.043003 |    551.570468 | Alexandre Vong                                                                                                                                                        |
| 181 |    870.278575 |    406.990252 | T. Michael Keesey                                                                                                                                                     |
| 182 |    691.641148 |    256.685197 | John Gould (vectorized by T. Michael Keesey)                                                                                                                          |
| 183 |    993.547830 |    154.317298 | Tasman Dixon                                                                                                                                                          |
| 184 |    862.265144 |    109.217496 | Dein Freund der Baum (vectorized by T. Michael Keesey)                                                                                                                |
| 185 |    622.323891 |    771.541128 | Margot Michaud                                                                                                                                                        |
| 186 |   1006.978260 |     50.369039 | Michael Scroggie                                                                                                                                                      |
| 187 |    548.687070 |    455.398631 | Rebecca Groom                                                                                                                                                         |
| 188 |    908.162196 |    514.297187 | T. Michael Keesey (after James & al.)                                                                                                                                 |
| 189 |    915.828879 |    259.659472 | Ferran Sayol                                                                                                                                                          |
| 190 |    226.022650 |    119.117918 | Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy                                                                                                        |
| 191 |    836.332006 |    489.011895 | Margot Michaud                                                                                                                                                        |
| 192 |    724.820742 |    698.157858 | T. Michael Keesey                                                                                                                                                     |
| 193 |    834.298665 |    136.231451 | C. Camilo Julián-Caballero                                                                                                                                            |
| 194 |    680.983895 |    491.511051 | Ieuan Jones                                                                                                                                                           |
| 195 |    694.494055 |     45.341238 | Collin Gross                                                                                                                                                          |
| 196 |    992.416517 |    362.072736 | Scott Hartman                                                                                                                                                         |
| 197 |    331.311032 |     81.472624 | Mykle Hoban                                                                                                                                                           |
| 198 |     22.352370 |    391.085226 | Sharon Wegner-Larsen                                                                                                                                                  |
| 199 |    248.467154 |    348.518492 | Dean Schnabel                                                                                                                                                         |
| 200 |    578.688181 |    366.006609 | Brockhaus and Efron                                                                                                                                                   |
| 201 |     26.762156 |    673.546579 | Zimices                                                                                                                                                               |
| 202 |    517.477534 |    610.695174 | Markus A. Grohme                                                                                                                                                      |
| 203 |    213.883869 |    793.387790 | Jagged Fang Designs                                                                                                                                                   |
| 204 |    241.732861 |    791.274822 | Dean Schnabel                                                                                                                                                         |
| 205 |    304.541202 |    787.937942 | Gareth Monger                                                                                                                                                         |
| 206 |    341.360697 |    774.482570 | Christoph Schomburg                                                                                                                                                   |
| 207 |    732.131827 |    370.919594 | Steven Traver                                                                                                                                                         |
| 208 |    949.097137 |    131.395241 | Gareth Monger                                                                                                                                                         |
| 209 |    352.773673 |    176.886997 | Myriam\_Ramirez                                                                                                                                                       |
| 210 |    189.005015 |    157.118218 | Andy Wilson                                                                                                                                                           |
| 211 |    506.949702 |    287.019572 | Jaime Headden                                                                                                                                                         |
| 212 |    757.993067 |    276.136484 | Ferran Sayol                                                                                                                                                          |
| 213 |   1008.089825 |     29.116198 | Margot Michaud                                                                                                                                                        |
| 214 |    639.100436 |    660.460144 | Katie S. Collins                                                                                                                                                      |
| 215 |    407.660988 |    315.919771 | Inessa Voet                                                                                                                                                           |
| 216 |   1001.988134 |    184.066577 | Tasman Dixon                                                                                                                                                          |
| 217 |    804.186044 |    743.638991 | Gareth Monger                                                                                                                                                         |
| 218 |    646.952607 |    630.121744 | Stuart Humphries                                                                                                                                                      |
| 219 |    782.966766 |    150.229298 | Jagged Fang Designs                                                                                                                                                   |
| 220 |    392.574390 |    359.033403 | Carlos Cano-Barbacil                                                                                                                                                  |
| 221 |    787.123043 |    560.401869 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                          |
| 222 |    290.883122 |     81.526902 | Margot Michaud                                                                                                                                                        |
| 223 |    189.472674 |    542.873086 | Zimices                                                                                                                                                               |
| 224 |    765.786552 |     10.102397 | Jagged Fang Designs                                                                                                                                                   |
| 225 |    169.105517 |    785.418265 | Zimices                                                                                                                                                               |
| 226 |    192.311489 |      6.163032 | Tasman Dixon                                                                                                                                                          |
| 227 |     15.101419 |    788.866251 | B. Duygu Özpolat                                                                                                                                                      |
| 228 |    885.828771 |    223.796350 | Steven Traver                                                                                                                                                         |
| 229 |    723.256345 |    490.784479 | terngirl                                                                                                                                                              |
| 230 |    455.255041 |    429.346010 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                     |
| 231 |    628.646373 |    579.495804 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                         |
| 232 |     15.692479 |    338.865736 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 233 |    701.083276 |    400.034989 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 234 |    472.558058 |    476.906610 | Jake Warner                                                                                                                                                           |
| 235 |    333.815346 |    630.331302 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 236 |    836.941198 |    370.595521 | T. Michael Keesey                                                                                                                                                     |
| 237 |    734.237574 |    277.824098 | Tyler Greenfield and Dean Schnabel                                                                                                                                    |
| 238 |    747.543245 |    754.531652 | Gareth Monger                                                                                                                                                         |
| 239 |    630.184617 |    393.503978 | Cesar Julian                                                                                                                                                          |
| 240 |    574.559425 |    294.977545 | Martin R. Smith, after Skovsted et al 2015                                                                                                                            |
| 241 |     33.394030 |    154.964630 | Gareth Monger                                                                                                                                                         |
| 242 |    844.267924 |    639.874641 | Matt Crook                                                                                                                                                            |
| 243 |    666.382131 |    721.769743 | Jagged Fang Designs                                                                                                                                                   |
| 244 |    395.274226 |    346.046313 | Mattia Menchetti                                                                                                                                                      |
| 245 |    155.913635 |    665.534104 | Scott Hartman                                                                                                                                                         |
| 246 |    558.183333 |     59.243923 | FJDegrange                                                                                                                                                            |
| 247 |    796.264925 |    631.033141 | NA                                                                                                                                                                    |
| 248 |    199.255203 |    190.065001 | Markus A. Grohme                                                                                                                                                      |
| 249 |    923.404966 |    177.776058 | Margot Michaud                                                                                                                                                        |
| 250 |     54.252443 |    788.829144 | Margot Michaud                                                                                                                                                        |
| 251 |    574.232966 |    322.543139 | FunkMonk                                                                                                                                                              |
| 252 |    950.160739 |    343.577058 | Gareth Monger                                                                                                                                                         |
| 253 |    484.926254 |    378.750958 | Chris huh                                                                                                                                                             |
| 254 |    195.566139 |    109.036879 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 255 |    740.332725 |    304.606020 | Iain Reid                                                                                                                                                             |
| 256 |    916.078143 |     20.890595 | Steven Traver                                                                                                                                                         |
| 257 |    437.167004 |    274.694564 | Shyamal                                                                                                                                                               |
| 258 |     33.036021 |    747.500435 | Scott Hartman                                                                                                                                                         |
| 259 |     34.146147 |    367.353126 | Erika Schumacher                                                                                                                                                      |
| 260 |    186.762105 |    589.763600 | Jesús Gómez, vectorized by Zimices                                                                                                                                    |
| 261 |     54.656895 |    440.144070 | NA                                                                                                                                                                    |
| 262 |    534.008669 |      9.931598 | Steven Traver                                                                                                                                                         |
| 263 |    155.229915 |    584.818973 | Katie S. Collins                                                                                                                                                      |
| 264 |   1007.113908 |    634.314358 | Margot Michaud                                                                                                                                                        |
| 265 |     67.673989 |    190.723097 | T. Michael Keesey                                                                                                                                                     |
| 266 |    155.691620 |    197.220180 | Gareth Monger                                                                                                                                                         |
| 267 |    287.157963 |    202.274751 | Dean Schnabel                                                                                                                                                         |
| 268 |    336.898382 |    791.195469 | Lukasiniho                                                                                                                                                            |
| 269 |    507.742825 |    722.796815 | Harold N Eyster                                                                                                                                                       |
| 270 |    685.458542 |    457.400944 | T. Michael Keesey                                                                                                                                                     |
| 271 |    269.524067 |     94.362194 | Manabu Sakamoto                                                                                                                                                       |
| 272 |    341.925482 |    224.151173 | Matt Crook                                                                                                                                                            |
| 273 |    180.072739 |    446.657282 | Beth Reinke                                                                                                                                                           |
| 274 |     70.150664 |     19.037975 | Julio Garza                                                                                                                                                           |
| 275 |    469.189836 |    402.032783 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 276 |    406.347151 |    134.648926 | C. Camilo Julián-Caballero                                                                                                                                            |
| 277 |    118.513386 |      7.502029 | Kamil S. Jaron                                                                                                                                                        |
| 278 |    901.818703 |    783.465940 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 279 |    813.101991 |     17.590256 | Gareth Monger                                                                                                                                                         |
| 280 |    184.263397 |    573.708350 | Ferran Sayol                                                                                                                                                          |
| 281 |    998.742161 |    658.145173 | Original scheme by ‘Haplochromis’, vectorized by Roberto Díaz Sibaja                                                                                                  |
| 282 |    459.575083 |    762.278572 | Scott Hartman                                                                                                                                                         |
| 283 |     63.399672 |    598.437261 | Jagged Fang Designs                                                                                                                                                   |
| 284 |    959.260133 |    478.773990 | Qiang Ou                                                                                                                                                              |
| 285 |    359.406234 |    564.023295 | Steven Traver                                                                                                                                                         |
| 286 |    657.976206 |    651.537828 | Christoph Schomburg                                                                                                                                                   |
| 287 |     76.609922 |    283.848254 | Douglas Brown (modified by T. Michael Keesey)                                                                                                                         |
| 288 |    153.552921 |    248.402564 | Sarah Werning                                                                                                                                                         |
| 289 |    732.037924 |    346.508466 | Ingo Braasch                                                                                                                                                          |
| 290 |    661.308531 |     48.494046 | Lafage                                                                                                                                                                |
| 291 |     32.723377 |     65.521208 | Anthony Caravaggi                                                                                                                                                     |
| 292 |    131.804705 |    682.482397 | Jack Mayer Wood                                                                                                                                                       |
| 293 |    380.261827 |    382.988895 | Steven Traver                                                                                                                                                         |
| 294 |    724.583998 |    567.937810 | T. Michael Keesey (after Masteraah)                                                                                                                                   |
| 295 |    647.736308 |    545.542052 | Aviceda (vectorized by T. Michael Keesey)                                                                                                                             |
| 296 |    672.218419 |    191.760937 | Jagged Fang Designs                                                                                                                                                   |
| 297 |    586.896976 |    598.734606 | Iain Reid                                                                                                                                                             |
| 298 |    874.368111 |    703.029567 | Collin Gross                                                                                                                                                          |
| 299 |     87.694268 |    528.526264 | Matt Crook                                                                                                                                                            |
| 300 |    140.008878 |    177.293048 | Mathilde Cordellier                                                                                                                                                   |
| 301 |   1003.026534 |    386.542654 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 302 |     23.818732 |    181.236162 | Iain Reid                                                                                                                                                             |
| 303 |    168.370355 |    182.476330 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 304 |    156.226824 |    346.302155 | Ferran Sayol                                                                                                                                                          |
| 305 |    350.657536 |    131.827859 | Steven Coombs                                                                                                                                                         |
| 306 |    388.792095 |    666.505733 | Jiekun He                                                                                                                                                             |
| 307 |    129.968234 |    142.600332 | Zimices                                                                                                                                                               |
| 308 |    820.584622 |    223.472803 | Rebecca Groom                                                                                                                                                         |
| 309 |    894.131521 |    345.960615 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 310 |    281.492418 |    733.706992 | Scott Hartman                                                                                                                                                         |
| 311 |    845.292809 |    662.083166 | Steven Traver                                                                                                                                                         |
| 312 |     92.088331 |    512.010283 | Mette Aumala                                                                                                                                                          |
| 313 |    941.408623 |    194.759124 | Carlos Cano-Barbacil                                                                                                                                                  |
| 314 |    489.549357 |    340.893857 | Christoph Schomburg                                                                                                                                                   |
| 315 |   1004.732747 |    472.544714 | Amanda Katzer                                                                                                                                                         |
| 316 |    721.452308 |    240.491270 | Felix Vaux                                                                                                                                                            |
| 317 |    655.645814 |    787.303847 | NA                                                                                                                                                                    |
| 318 |    918.074051 |    336.267978 | Scott Hartman                                                                                                                                                         |
| 319 |     14.995330 |     15.590905 | Peter Coxhead                                                                                                                                                         |
| 320 |    117.822202 |    661.833360 | Dmitry Bogdanov                                                                                                                                                       |
| 321 |    453.267136 |    162.333401 | Robert Gay, modifed from Olegivvit                                                                                                                                    |
| 322 |    335.992828 |    674.667178 | Jagged Fang Designs                                                                                                                                                   |
| 323 |    100.699062 |    321.054634 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 324 |    544.477756 |     80.153970 | Zimices                                                                                                                                                               |
| 325 |    203.759838 |    763.907186 | Jagged Fang Designs                                                                                                                                                   |
| 326 |     89.787670 |    671.991393 | Henry Lydecker                                                                                                                                                        |
| 327 |    664.188384 |    587.757099 | Campbell Fleming                                                                                                                                                      |
| 328 |    841.424629 |    235.647831 | Armin Reindl                                                                                                                                                          |
| 329 |    983.420471 |    583.125296 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 330 |    229.284258 |    158.107772 | Scott Hartman                                                                                                                                                         |
| 331 |    489.742403 |    403.700793 | Ferran Sayol                                                                                                                                                          |
| 332 |    903.426548 |    469.433354 | Emily Jane McTavish                                                                                                                                                   |
| 333 |    992.398812 |    138.791164 | Scott Hartman                                                                                                                                                         |
| 334 |    861.431196 |    705.185829 | Margot Michaud                                                                                                                                                        |
| 335 |    714.453782 |    723.846765 | Ferran Sayol                                                                                                                                                          |
| 336 |   1008.282665 |    264.100009 | NA                                                                                                                                                                    |
| 337 |     94.663808 |    115.140359 | Maija Karala                                                                                                                                                          |
| 338 |    682.574222 |    792.311659 | Tasman Dixon                                                                                                                                                          |
| 339 |    598.581415 |     48.343928 | Mariana Ruiz Villarreal (modified by T. Michael Keesey)                                                                                                               |
| 340 |      8.852739 |    641.851622 | Gareth Monger                                                                                                                                                         |
| 341 |    256.573133 |    330.458831 | Zimices                                                                                                                                                               |
| 342 |    620.696760 |    195.131512 | Kai R. Caspar                                                                                                                                                         |
| 343 |    210.097499 |    273.597882 | Lafage                                                                                                                                                                |
| 344 |    766.101212 |    730.162250 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                           |
| 345 |    248.787525 |    241.614426 | Gareth Monger                                                                                                                                                         |
| 346 |    344.392894 |    124.486810 | Dexter R. Mardis                                                                                                                                                      |
| 347 |    381.784366 |     62.582131 | Collin Gross                                                                                                                                                          |
| 348 |    412.866164 |    518.600313 | Nobu Tamura                                                                                                                                                           |
| 349 |   1002.355265 |     89.081448 | Gareth Monger                                                                                                                                                         |
| 350 |    915.533354 |    218.075155 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
| 351 |    796.795032 |    373.821141 | Dave Souza (vectorized by T. Michael Keesey)                                                                                                                          |
| 352 |    116.678624 |    128.662019 | Chris huh                                                                                                                                                             |
| 353 |    864.404714 |    457.685029 | Chris huh                                                                                                                                                             |
| 354 |    113.237127 |    183.754593 | Chris huh                                                                                                                                                             |
| 355 |    763.863751 |     69.852993 | Skye McDavid                                                                                                                                                          |
| 356 |    626.230341 |    612.377082 | Matt Crook                                                                                                                                                            |
| 357 |   1008.353794 |    211.777340 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 358 |    700.915831 |    625.355543 | Chris huh                                                                                                                                                             |
| 359 |    664.976676 |    239.227867 | Gareth Monger                                                                                                                                                         |
| 360 |    794.298722 |    792.948161 | Scott Hartman                                                                                                                                                         |
| 361 |    393.744610 |    632.552214 | Maija Karala                                                                                                                                                          |
| 362 |    274.638863 |    417.619557 | Markus A. Grohme                                                                                                                                                      |
| 363 |    252.738804 |    538.516775 | SauropodomorphMonarch                                                                                                                                                 |
| 364 |     30.077648 |    133.779345 | Mykle Hoban                                                                                                                                                           |
| 365 |    801.730066 |    762.734455 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 366 |    321.800544 |     19.248316 | Gareth Monger                                                                                                                                                         |
| 367 |    614.869753 |    452.856390 | Mathew Wedel                                                                                                                                                          |
| 368 |    757.771586 |    171.397625 | Steven Traver                                                                                                                                                         |
| 369 |     26.481690 |     41.261877 | Carlos Cano-Barbacil                                                                                                                                                  |
| 370 |    592.861849 |    574.771078 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 371 |    882.459823 |    200.025589 | Gareth Monger                                                                                                                                                         |
| 372 |    764.562545 |    328.211038 | Mathilde Cordellier                                                                                                                                                   |
| 373 |   1002.448618 |    768.512329 | Rene Martin                                                                                                                                                           |
| 374 |    404.297785 |    536.497914 | B. Duygu Özpolat                                                                                                                                                      |
| 375 |    703.698259 |    485.133650 | Meyers Konversations-Lexikon 1897 (vectorized: Yan Wong)                                                                                                              |
| 376 |    926.201301 |    715.235077 | Jaime Headden                                                                                                                                                         |
| 377 |    601.915824 |    785.781956 | Scott Hartman                                                                                                                                                         |
| 378 |    650.299110 |    487.032901 | Tasman Dixon                                                                                                                                                          |
| 379 |    209.949495 |    732.723590 | Gareth Monger                                                                                                                                                         |
| 380 |    854.932155 |    250.021898 | L. Shyamal                                                                                                                                                            |
| 381 |    617.162438 |    124.959972 | Milton Tan                                                                                                                                                            |
| 382 |     68.816341 |    130.816076 | Iain Reid                                                                                                                                                             |
| 383 |   1001.725672 |     14.360327 | Andy Wilson                                                                                                                                                           |
| 384 |    260.169906 |    608.529486 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 385 |    510.392146 |    190.473134 | Alexandre Vong                                                                                                                                                        |
| 386 |    698.770385 |    230.223193 | Gareth Monger                                                                                                                                                         |
| 387 |    375.287295 |    547.892670 | Agnello Picorelli                                                                                                                                                     |
| 388 |    791.122612 |    437.130905 | Mykle Hoban                                                                                                                                                           |
| 389 |    783.291614 |    661.217056 | FunkMonk                                                                                                                                                              |
| 390 |    666.075268 |    387.045923 | Iain Reid                                                                                                                                                             |
| 391 |    673.062100 |    183.256670 | CNZdenek                                                                                                                                                              |
| 392 |    633.238082 |    686.154127 | Birgit Lang                                                                                                                                                           |
| 393 |    478.415015 |     18.777451 | Andreas Hejnol                                                                                                                                                        |
| 394 |    707.742511 |    444.362901 | Michelle Site                                                                                                                                                         |
| 395 |    763.286453 |    544.791553 | Mary Harrsch (modified by T. Michael Keesey)                                                                                                                          |
| 396 |    819.950804 |    713.464042 | Gareth Monger                                                                                                                                                         |
| 397 |    423.655969 |    659.793501 | Michele M Tobias                                                                                                                                                      |
| 398 |    675.874190 |    408.181902 | Dean Schnabel                                                                                                                                                         |
| 399 |    186.042990 |    525.751182 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                                     |
| 400 |    408.288116 |     79.417675 | Armin Reindl                                                                                                                                                          |
| 401 |     70.074333 |    776.131562 | Markus A. Grohme                                                                                                                                                      |
| 402 |    988.033973 |    681.541787 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 403 |    282.818089 |    720.141710 | Michelle Site                                                                                                                                                         |
| 404 |    566.175886 |    679.350258 | Nobu Tamura                                                                                                                                                           |
| 405 |    765.732177 |    184.175117 | Scott Hartman                                                                                                                                                         |
| 406 |    577.604834 |    687.411023 | Scott Hartman                                                                                                                                                         |
| 407 |    813.595087 |    387.492841 | Collin Gross                                                                                                                                                          |
| 408 |    482.575924 |    766.434182 | Margot Michaud                                                                                                                                                        |
| 409 |    241.249736 |    599.199804 | Ferran Sayol                                                                                                                                                          |
| 410 |    151.833075 |     64.269740 | Matt Crook                                                                                                                                                            |
| 411 |    412.308682 |    298.487858 | Chris huh                                                                                                                                                             |
| 412 |     16.254784 |    597.240607 | Zimices                                                                                                                                                               |
| 413 |    627.237572 |    476.656396 | Chris huh                                                                                                                                                             |
| 414 |    476.271814 |    543.887372 | Kamil S. Jaron                                                                                                                                                        |
| 415 |     99.125531 |    104.163823 | Jagged Fang Designs                                                                                                                                                   |
| 416 |    170.905872 |    309.071292 | Danielle Alba                                                                                                                                                         |
| 417 |    321.316371 |    237.313566 | Jagged Fang Designs                                                                                                                                                   |
| 418 |    380.676957 |    256.348606 | Jagged Fang Designs                                                                                                                                                   |
| 419 |    451.086410 |    232.837565 | Matt Crook                                                                                                                                                            |
| 420 |    510.774244 |    620.163678 | Gareth Monger                                                                                                                                                         |
| 421 |    405.280445 |    158.449634 | Maija Karala                                                                                                                                                          |
| 422 |    116.793802 |    164.201558 | Markus A. Grohme                                                                                                                                                      |
| 423 |    217.572200 |    307.418839 | Margot Michaud                                                                                                                                                        |
| 424 |     70.817948 |     58.147994 | Andrew A. Farke                                                                                                                                                       |
| 425 |    376.894558 |    783.898489 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                           |
| 426 |    355.635399 |    138.136078 | Markus A. Grohme                                                                                                                                                      |
| 427 |    487.377585 |    602.259852 | Jagged Fang Designs                                                                                                                                                   |
| 428 |    375.187825 |    637.677616 | Tasman Dixon                                                                                                                                                          |
| 429 |    882.073117 |     15.655074 | Cesar Julian                                                                                                                                                          |
| 430 |    248.616158 |    702.272791 | Becky Barnes                                                                                                                                                          |
| 431 |    509.803406 |    108.625232 | Mathew Wedel                                                                                                                                                          |
| 432 |    516.539979 |     36.415010 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                           |
| 433 |    669.502044 |    734.450289 | Scott Hartman                                                                                                                                                         |
| 434 |    137.548063 |    576.902112 | Smokeybjb                                                                                                                                                             |
| 435 |    157.973685 |    767.614041 | Michael Scroggie                                                                                                                                                      |
| 436 |    306.705921 |    134.401046 | Tasman Dixon                                                                                                                                                          |
| 437 |    459.605635 |    793.418027 | Smokeybjb                                                                                                                                                             |
| 438 |    476.878722 |    360.574838 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 439 |   1016.198170 |    699.855288 | Moussa Direct Ltd. (photography) and T. Michael Keesey (vectorization)                                                                                                |
| 440 |    974.763486 |    510.846030 | Michelle Site                                                                                                                                                         |
| 441 |    100.475745 |    652.580194 | Iain Reid                                                                                                                                                             |
| 442 |    374.969689 |    754.242096 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 443 |     24.240861 |    460.223438 | Steven Traver                                                                                                                                                         |
| 444 |    294.368068 |    700.179142 | Milton Tan                                                                                                                                                            |
| 445 |     63.937171 |      8.425138 | Jagged Fang Designs                                                                                                                                                   |
| 446 |    321.713360 |    275.972978 | Gareth Monger                                                                                                                                                         |
| 447 |     86.383952 |    193.582665 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 448 |    572.716565 |    351.474906 | T. Michael Keesey                                                                                                                                                     |
| 449 |    123.430174 |    487.157372 | Rene Martin                                                                                                                                                           |
| 450 |    113.316129 |    793.381627 | Gareth Monger                                                                                                                                                         |
| 451 |    749.460361 |    383.182460 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 452 |   1001.184264 |    351.985966 | FunkMonk                                                                                                                                                              |
| 453 |    843.549842 |    686.995081 | S.Martini                                                                                                                                                             |
| 454 |    373.617763 |     89.373519 | Matt Dempsey                                                                                                                                                          |
| 455 |   1008.177636 |    557.526065 | Gareth Monger                                                                                                                                                         |
| 456 |     24.037481 |    299.105771 | Gareth Monger                                                                                                                                                         |
| 457 |    936.813806 |    259.453556 | Cagri Cevrim                                                                                                                                                          |
| 458 |    205.272354 |    198.673797 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 459 |     30.667590 |    643.291748 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 460 |    758.699948 |    793.788218 | Jagged Fang Designs                                                                                                                                                   |
| 461 |    317.002721 |    215.934669 | Xavier Giroux-Bougard                                                                                                                                                 |
| 462 |     86.933357 |    547.904942 | Chris huh                                                                                                                                                             |
| 463 |    778.011371 |    122.841242 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 464 |    931.847516 |    596.753784 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 465 |     46.709992 |    192.081776 | Margot Michaud                                                                                                                                                        |
| 466 |     79.326025 |    324.768929 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                         |
| 467 |   1006.749612 |    673.049193 | Chris huh                                                                                                                                                             |
| 468 |    922.194552 |    478.808026 | Gareth Monger                                                                                                                                                         |
| 469 |    847.330799 |    401.332070 | Christoph Schomburg                                                                                                                                                   |
| 470 |    245.112044 |    122.829476 | T. Michael Keesey                                                                                                                                                     |
| 471 |     64.302911 |     28.732250 | Henry Lydecker                                                                                                                                                        |
| 472 |    964.275816 |    146.567128 | Emily Willoughby                                                                                                                                                      |
| 473 |    279.352836 |    688.648208 | Emily Willoughby                                                                                                                                                      |
| 474 |    699.745278 |    600.656581 | Zimices                                                                                                                                                               |
| 475 |    714.223855 |    260.772126 | Ferran Sayol                                                                                                                                                          |
| 476 |     21.887801 |    238.644532 | Andrew R. Gehrke                                                                                                                                                      |
| 477 |    618.043721 |    468.952303 | Chris huh                                                                                                                                                             |
| 478 |    366.528749 |     81.377510 | Scott Hartman                                                                                                                                                         |
| 479 |    196.383253 |     47.702024 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 480 |    328.715253 |     99.315843 | Dmitry Bogdanov                                                                                                                                                       |
| 481 |    872.426585 |     39.263799 | Tyler Greenfield                                                                                                                                                      |
| 482 |    991.799299 |    570.491400 | Roberto Díaz Sibaja                                                                                                                                                   |
| 483 |    685.779070 |    213.534876 | Matt Crook                                                                                                                                                            |
| 484 |    624.980783 |     61.759516 | Birgit Lang                                                                                                                                                           |
| 485 |    781.922035 |     15.571445 | Ieuan Jones                                                                                                                                                           |
| 486 |    170.247368 |    103.701032 | Chris huh                                                                                                                                                             |
| 487 |    945.020792 |      7.410007 | Gareth Monger                                                                                                                                                         |
| 488 |     97.020253 |    378.625493 | Tasman Dixon                                                                                                                                                          |
| 489 |    547.727602 |    590.512477 | Ignacio Contreras                                                                                                                                                     |
| 490 |    191.167790 |    684.350024 | NA                                                                                                                                                                    |
| 491 |    715.941312 |    307.203314 | Yan Wong                                                                                                                                                              |
| 492 |    170.936714 |    563.559148 | Matt Crook                                                                                                                                                            |
| 493 |    676.892676 |    438.094186 | Gareth Monger                                                                                                                                                         |
| 494 |    219.518559 |    397.759598 | Yusan Yang                                                                                                                                                            |
| 495 |    609.268732 |    798.470745 | Christoph Schomburg                                                                                                                                                   |
| 496 |    124.182841 |    595.323776 | Ignacio Contreras                                                                                                                                                     |
| 497 |    928.783936 |    545.317417 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                                       |
| 498 |     26.130781 |    712.903551 | Jagged Fang Designs                                                                                                                                                   |
| 499 |    954.183980 |    416.229101 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 500 |    109.974757 |    727.780937 | T. Michael Keesey (after James & al.)                                                                                                                                 |
| 501 |    778.720124 |    708.189951 | Matt Crook                                                                                                                                                            |
| 502 |    420.486383 |    282.946842 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                          |
| 503 |    246.118476 |    202.932459 | Zimices                                                                                                                                                               |
| 504 |    135.414202 |    388.311119 | NA                                                                                                                                                                    |
| 505 |    521.927162 |    412.495067 | T. Michael Keesey                                                                                                                                                     |
| 506 |    278.733510 |    783.821292 | Gareth Monger                                                                                                                                                         |
| 507 |    207.430469 |    345.756090 | Tambja (vectorized by T. Michael Keesey)                                                                                                                              |
| 508 |    273.995027 |    296.012550 | Matt Dempsey                                                                                                                                                          |
| 509 |     80.373241 |    268.113780 | Chris huh                                                                                                                                                             |
| 510 |    907.097116 |    319.502756 | Roberto Díaz Sibaja                                                                                                                                                   |

    #> Your tweet has been posted!
