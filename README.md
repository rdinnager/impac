
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

Conty (vectorized by T. Michael Keesey), Margot Michaud, Jose Carlos
Arenas-Monroy, Scott Hartman, Rebecca Groom, Jay Matternes (modified by
T. Michael Keesey), Birgit Lang, Terpsichores, Steven Traver, Mali’o
Kodis, photograph from
<http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>, Jimmy Bernot,
Beth Reinke, Jagged Fang Designs, Nobu Tamura, vectorized by Zimices,
Maija Karala, Matt Crook, Zimices, Chris Hay, Jaime Headden, Andy
Wilson, Iain Reid, Gabriela Palomo-Munoz, T. Tischler, Mariana Ruiz
Villarreal (modified by T. Michael Keesey), Kamil S. Jaron, Ferran
Sayol, Chris huh, T. Michael Keesey (after Heinrich Harder), Lukas
Panzarin (vectorized by T. Michael Keesey), Peter Coxhead, Alexander
Schmidt-Lebuhn, Gareth Monger, Dean Schnabel, Tasman Dixon, Todd
Marshall, vectorized by Zimices, xgirouxb, Michael P. Taylor, Caleb M.
Brown, Harold N Eyster, Christopher Laumer (vectorized by T. Michael
Keesey), Ignacio Contreras, John Conway, Christine Axon, Noah
Schlottman, photo from Casey Dunn, RS, Gabriele Midolo, Emily
Willoughby, Markus A. Grohme, T. Michael Keesey, FunkMonk, M Kolmann,
James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis
Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey), Matt
Martyniuk, FJDegrange, Ernst Haeckel (vectorized by T. Michael Keesey),
Tracy A. Heath, Mali’o Kodis, image from Higgins and Kristensen, 1986,
Luis Cunha, Brian Swartz (vectorized by T. Michael Keesey), Noah
Schlottman, photo by David J Patterson, Sergio A. Muñoz-Gómez, Chuanixn
Yu, Nobu Tamura (vectorized by A. Verrière), Armin Reindl, Sarah
Werning, Roberto Díaz Sibaja, Dave Souza (vectorized by T. Michael
Keesey), C. Camilo Julián-Caballero, Brad McFeeters (vectorized by T.
Michael Keesey), Mario Quevedo, nicubunu, Nobu Tamura (vectorized by T.
Michael Keesey), Alexis Simon, Amanda Katzer, Becky Barnes, Collin
Gross, FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey), Mali’o
Kodis, image from Brockhaus and Efron Encyclopedic Dictionary, T.
Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M.
Townsend & Miguel Vences), Jesús Gómez, vectorized by Zimices, Stanton
F. Fink (vectorized by T. Michael Keesey), Chloé Schmidt, Mali’o Kodis,
photograph by Melissa Frey, T. Michael Keesey (vectorization); Yves
Bousquet (photography), Andrew A. Farke, Richard Ruggiero, vectorized by
Zimices, MPF (vectorized by T. Michael Keesey), Kai R. Caspar, Cesar
Julian, Lukasiniho, Ingo Braasch, Robert Gay, modifed from Olegivvit,
Kelly, Inessa Voet, Jan A. Venter, Herbert H. T. Prins, David A. Balfour
& Rob Slotow (vectorized by T. Michael Keesey), Juan Carlos Jerí, Hans
Hillewaert (vectorized by T. Michael Keesey), Jon Hill (Photo by
DickDaniels:
<http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>), I.
Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey), Didier
Descouens (vectorized by T. Michael Keesey), mystica, Liftarn, Felix
Vaux, Erika Schumacher, Lafage, Mo Hassan, Kanchi Nanjo, Tauana J.
Cunha, T. Michael Keesey (after Mivart), Scott Reid, Yan Wong from photo
by Denes Emoke, Young and Zhao (1972:figure 4), modified by Michael P.
Taylor, Joanna Wolfe, Joe Schneid (vectorized by T. Michael Keesey),
CNZdenek, Esme Ashe-Jepson, Dmitry Bogdanov (vectorized by T. Michael
Keesey), Robert Bruce Horsfall, vectorized by Zimices, Aadx, Melissa
Broussard, Matus Valach, Frank Förster (based on a picture by Jerry
Kirkhart; modified by T. Michael Keesey), Jiekun He, Вальдимар
(vectorized by T. Michael Keesey), SecretJellyMan, David Orr, Milton
Tan, Alexandre Vong, Derek Bakken (photograph) and T. Michael Keesey
(vectorization), Ricardo N. Martinez & Oscar A. Alcober, T. Michael
Keesey (after Monika Betley), Agnello Picorelli, Christoph Schomburg,
Robert Bruce Horsfall (vectorized by T. Michael Keesey), Joseph J. W.
Sertich, Mark A. Loewen, Katie S. Collins, Smokeybjb (vectorized by T.
Michael Keesey), Steven Coombs, Carlos Cano-Barbacil, Francesca Belem
Lopes Palmeira, Josefine Bohr Brask, Ghedoghedo, vectorized by Zimices,
Jessica Anne Miller, Original drawing by Antonov, vectorized by Roberto
Díaz Sibaja, Michael Scroggie, Darren Naish (vectorized by T. Michael
Keesey), T. Michael Keesey (from a photo by Maximilian Paradiz), Ieuan
Jones, Pete Buchholz, Rene Martin, Michelle Site, Eduard Solà
(vectorized by T. Michael Keesey), Steven Blackwood, Mathilde
Cordellier, Obsidian Soul (vectorized by T. Michael Keesey), L. Shyamal,
Mali’o Kodis, photograph from Jersabek et al, 2003, Skye McDavid, Noah
Schlottman, photo by Martin V. Sørensen, Mathew Wedel, Andrew A. Farke,
shell lines added by Yan Wong, Kimberly Haddrell, Zimices / Julián
Bayona, Mali’o Kodis, drawing by Manvir Singh, Noah Schlottman, photo by
Casey Dunn, Mette Aumala, Gopal Murali, Renato Santos, Blanco et al.,
2014, vectorized by Zimices, Michele M Tobias from an image By Dcrjsr -
Own work, CC BY 3.0,
<https://commons.wikimedia.org/w/index.php?curid=18059686>, Tyler
McCraney, Scott Hartman, modified by T. Michael Keesey, Joseph Smit
(modified by T. Michael Keesey), Smokeybjb, Brockhaus and Efron, Mykle
Hoban, Archaeodontosaurus (vectorized by T. Michael Keesey), Tony Ayling
(vectorized by T. Michael Keesey), SauropodomorphMonarch, Michael Ströck
(vectorized by T. Michael Keesey), Blair Perry, FunkMonk (Michael B.H.;
vectorized by T. Michael Keesey), Servien (vectorized by T. Michael
Keesey), Nina Skinner, Jaime Headden (vectorized by T. Michael Keesey),
Sean McCann, NOAA Great Lakes Environmental Research Laboratory
(illustration) and Timothy J. Bartley (silhouette), Nobu Tamura,
modified by Andrew A. Farke, Yan Wong, Scott Hartman (vectorized by T.
Michael Keesey), Benchill, Anthony Caravaggi, Mihai Dragos (vectorized
by T. Michael Keesey), Daniel Stadtmauer, Taenadoman

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                               |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     201.29891 |    585.678260 | Conty (vectorized by T. Michael Keesey)                                                                                              |
|   2 |     475.55727 |    742.631504 | Margot Michaud                                                                                                                       |
|   3 |     407.34625 |    722.497961 | Jose Carlos Arenas-Monroy                                                                                                            |
|   4 |     503.15128 |     96.149961 | Scott Hartman                                                                                                                        |
|   5 |     859.20869 |    189.992322 | Rebecca Groom                                                                                                                        |
|   6 |     304.08262 |    254.722842 | Jay Matternes (modified by T. Michael Keesey)                                                                                        |
|   7 |     687.61222 |    724.729942 | Birgit Lang                                                                                                                          |
|   8 |     440.02359 |    538.595693 | Terpsichores                                                                                                                         |
|   9 |     133.82052 |    436.557881 | NA                                                                                                                                   |
|  10 |     766.58278 |    478.637228 | Steven Traver                                                                                                                        |
|  11 |     197.73023 |     66.700014 | Mali’o Kodis, photograph from <http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>                                                |
|  12 |     142.97621 |    492.935030 | Steven Traver                                                                                                                        |
|  13 |     968.73273 |     70.289856 | Jimmy Bernot                                                                                                                         |
|  14 |     626.86127 |    537.072317 | Beth Reinke                                                                                                                          |
|  15 |     600.02889 |     24.598295 | Jagged Fang Designs                                                                                                                  |
|  16 |     878.34363 |    343.106690 | Nobu Tamura, vectorized by Zimices                                                                                                   |
|  17 |     252.30383 |    778.969468 | Maija Karala                                                                                                                         |
|  18 |     154.05724 |    694.017141 | Matt Crook                                                                                                                           |
|  19 |     950.27533 |    625.527042 | Margot Michaud                                                                                                                       |
|  20 |     696.02289 |    210.671354 | Zimices                                                                                                                              |
|  21 |     639.16845 |    387.822553 | Chris Hay                                                                                                                            |
|  22 |     882.50071 |    453.591988 | Jaime Headden                                                                                                                        |
|  23 |     848.47692 |    571.687811 | Andy Wilson                                                                                                                          |
|  24 |     127.06480 |    323.373392 | Iain Reid                                                                                                                            |
|  25 |     493.70355 |    641.864312 | Gabriela Palomo-Munoz                                                                                                                |
|  26 |     507.10180 |    351.776493 | T. Tischler                                                                                                                          |
|  27 |     688.47474 |    632.276781 | Mariana Ruiz Villarreal (modified by T. Michael Keesey)                                                                              |
|  28 |     707.13296 |     81.246154 | Zimices                                                                                                                              |
|  29 |      87.15287 |    111.110762 | Kamil S. Jaron                                                                                                                       |
|  30 |     346.89331 |    411.153293 | Ferran Sayol                                                                                                                         |
|  31 |     776.95485 |    265.756981 | Chris huh                                                                                                                            |
|  32 |     310.86486 |    607.773673 | Chris huh                                                                                                                            |
|  33 |     342.20779 |    747.127385 | Jagged Fang Designs                                                                                                                  |
|  34 |     288.54031 |    665.787853 | T. Michael Keesey (after Heinrich Harder)                                                                                            |
|  35 |     796.48958 |     26.705120 | Kamil S. Jaron                                                                                                                       |
|  36 |     716.61983 |    355.985350 | Lukas Panzarin (vectorized by T. Michael Keesey)                                                                                     |
|  37 |      61.91589 |    304.493204 | Peter Coxhead                                                                                                                        |
|  38 |     867.84500 |    718.870992 | Matt Crook                                                                                                                           |
|  39 |     486.09294 |    428.880602 | Alexander Schmidt-Lebuhn                                                                                                             |
|  40 |     573.14432 |    249.121846 | Chris Hay                                                                                                                            |
|  41 |     375.66881 |    101.738787 | Kamil S. Jaron                                                                                                                       |
|  42 |     965.40037 |    277.517948 | Steven Traver                                                                                                                        |
|  43 |     709.24555 |    776.888847 | Gareth Monger                                                                                                                        |
|  44 |     872.90840 |    104.885187 | Gabriela Palomo-Munoz                                                                                                                |
|  45 |     923.20129 |    150.993866 | Dean Schnabel                                                                                                                        |
|  46 |     940.00176 |    738.915246 | Matt Crook                                                                                                                           |
|  47 |     920.83118 |    485.044062 | NA                                                                                                                                   |
|  48 |     741.11357 |    581.768062 | Matt Crook                                                                                                                           |
|  49 |     144.43478 |    401.914609 | Nobu Tamura, vectorized by Zimices                                                                                                   |
|  50 |     507.73053 |    495.523491 | Zimices                                                                                                                              |
|  51 |     632.30701 |    122.639427 | NA                                                                                                                                   |
|  52 |     307.82775 |    370.458252 | Matt Crook                                                                                                                           |
|  53 |     718.47181 |    308.899180 | Tasman Dixon                                                                                                                         |
|  54 |     728.04975 |    405.669848 | Todd Marshall, vectorized by Zimices                                                                                                 |
|  55 |     313.86256 |    534.061764 | Scott Hartman                                                                                                                        |
|  56 |     553.93075 |     50.294040 | NA                                                                                                                                   |
|  57 |     753.64258 |    672.799654 | xgirouxb                                                                                                                             |
|  58 |     228.29085 |    429.559868 | Ferran Sayol                                                                                                                         |
|  59 |     232.10063 |    734.454274 | Chris huh                                                                                                                            |
|  60 |      69.39270 |     37.654833 | Michael P. Taylor                                                                                                                    |
|  61 |     540.80523 |    704.066448 | Chris huh                                                                                                                            |
|  62 |     545.29069 |    168.904907 | Caleb M. Brown                                                                                                                       |
|  63 |     331.31394 |     64.993577 | Birgit Lang                                                                                                                          |
|  64 |     555.32226 |    313.723482 | Harold N Eyster                                                                                                                      |
|  65 |     587.35180 |    463.990920 | Scott Hartman                                                                                                                        |
|  66 |     826.91493 |    232.220489 | Jaime Headden                                                                                                                        |
|  67 |     904.79005 |     69.018333 | Christopher Laumer (vectorized by T. Michael Keesey)                                                                                 |
|  68 |     787.13639 |    435.538815 | Ignacio Contreras                                                                                                                    |
|  69 |     963.69039 |    198.795524 | John Conway                                                                                                                          |
|  70 |     239.10181 |    681.219582 | Christine Axon                                                                                                                       |
|  71 |      32.83096 |    749.770598 | Noah Schlottman, photo from Casey Dunn                                                                                               |
|  72 |     615.61241 |    589.501091 | RS                                                                                                                                   |
|  73 |     610.12397 |    767.110717 | Zimices                                                                                                                              |
|  74 |     965.58785 |    783.846032 | Zimices                                                                                                                              |
|  75 |      68.87156 |    522.556333 | Matt Crook                                                                                                                           |
|  76 |     660.56556 |    479.700161 | Scott Hartman                                                                                                                        |
|  77 |     524.77125 |    558.425795 | Gabriele Midolo                                                                                                                      |
|  78 |     483.83703 |     46.113616 | Kamil S. Jaron                                                                                                                       |
|  79 |     842.90635 |    403.097658 | Matt Crook                                                                                                                           |
|  80 |     292.10293 |    143.999202 | Emily Willoughby                                                                                                                     |
|  81 |     299.13485 |    566.046972 | Markus A. Grohme                                                                                                                     |
|  82 |     785.02331 |    108.256168 | T. Michael Keesey                                                                                                                    |
|  83 |     801.81799 |    737.871948 | Ferran Sayol                                                                                                                         |
|  84 |     154.35836 |    146.854408 | Zimices                                                                                                                              |
|  85 |     578.40129 |    620.857464 | Gareth Monger                                                                                                                        |
|  86 |     257.61789 |    482.344211 | Tasman Dixon                                                                                                                         |
|  87 |     606.54023 |    568.474770 | Michael P. Taylor                                                                                                                    |
|  88 |     865.24235 |    253.824399 | FunkMonk                                                                                                                             |
|  89 |     146.88869 |    270.734118 | M Kolmann                                                                                                                            |
|  90 |     469.69474 |    129.915164 | Tasman Dixon                                                                                                                         |
|  91 |     848.07528 |    525.325750 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey) |
|  92 |      87.59746 |     12.783672 | Ignacio Contreras                                                                                                                    |
|  93 |     599.67753 |    617.784522 | T. Michael Keesey                                                                                                                    |
|  94 |      59.45339 |    463.283964 | Matt Martyniuk                                                                                                                       |
|  95 |     916.40587 |    690.073187 | FJDegrange                                                                                                                           |
|  96 |      25.09157 |    333.121527 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                      |
|  97 |     980.52269 |    535.184173 | Tracy A. Heath                                                                                                                       |
|  98 |     549.35075 |    763.856153 | Mali’o Kodis, image from Higgins and Kristensen, 1986                                                                                |
|  99 |     388.53688 |     21.959711 | Tasman Dixon                                                                                                                         |
| 100 |     227.19100 |    358.063858 | Markus A. Grohme                                                                                                                     |
| 101 |     923.25298 |    539.726407 | Luis Cunha                                                                                                                           |
| 102 |     338.53959 |    626.930476 | Gabriela Palomo-Munoz                                                                                                                |
| 103 |     659.59178 |    277.976234 | NA                                                                                                                                   |
| 104 |     648.11413 |     39.152957 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                       |
| 105 |     819.90173 |     67.686905 | Noah Schlottman, photo by David J Patterson                                                                                          |
| 106 |     381.86934 |    627.991059 | Sergio A. Muñoz-Gómez                                                                                                                |
| 107 |     841.80893 |    542.873790 | Margot Michaud                                                                                                                       |
| 108 |     265.28520 |    593.212432 | Chuanixn Yu                                                                                                                          |
| 109 |     186.61060 |    765.663092 | Nobu Tamura (vectorized by A. Verrière)                                                                                              |
| 110 |     929.96910 |    412.812648 | Armin Reindl                                                                                                                         |
| 111 |     998.40949 |    388.016380 | Michael P. Taylor                                                                                                                    |
| 112 |     423.25790 |     29.844561 | Scott Hartman                                                                                                                        |
| 113 |     306.28869 |     25.262950 | Gareth Monger                                                                                                                        |
| 114 |      37.72402 |    697.236136 | Sarah Werning                                                                                                                        |
| 115 |     446.59993 |    107.590988 | Roberto Díaz Sibaja                                                                                                                  |
| 116 |     145.08475 |    760.089842 | Dean Schnabel                                                                                                                        |
| 117 |     368.49018 |    544.657673 | Dave Souza (vectorized by T. Michael Keesey)                                                                                         |
| 118 |     985.25300 |    489.889281 | Zimices                                                                                                                              |
| 119 |     457.30192 |    499.781873 | C. Camilo Julián-Caballero                                                                                                           |
| 120 |     524.45460 |    128.901519 | Chris huh                                                                                                                            |
| 121 |     105.80328 |    537.132817 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                     |
| 122 |      25.38026 |    160.013002 | Mario Quevedo                                                                                                                        |
| 123 |      43.10460 |     91.723031 | NA                                                                                                                                   |
| 124 |     795.02567 |    616.940965 | nicubunu                                                                                                                             |
| 125 |     569.13212 |     72.786254 | Nobu Tamura, vectorized by Zimices                                                                                                   |
| 126 |     988.07558 |    582.453172 | Matt Crook                                                                                                                           |
| 127 |     286.71873 |    126.392647 | Armin Reindl                                                                                                                         |
| 128 |      16.25676 |    414.869861 | Matt Crook                                                                                                                           |
| 129 |      45.56542 |    117.624770 | Matt Crook                                                                                                                           |
| 130 |     409.56662 |    430.780975 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                        |
| 131 |     223.02412 |    150.803129 | Zimices                                                                                                                              |
| 132 |     289.92248 |    109.382245 | Margot Michaud                                                                                                                       |
| 133 |      36.95987 |    549.711727 | Birgit Lang                                                                                                                          |
| 134 |     638.89267 |    324.158618 | Ferran Sayol                                                                                                                         |
| 135 |     835.49120 |    639.943704 | Margot Michaud                                                                                                                       |
| 136 |     601.82951 |    671.165024 | Gareth Monger                                                                                                                        |
| 137 |     674.81994 |    434.521774 | Gareth Monger                                                                                                                        |
| 138 |     894.84865 |    388.251666 | Alexis Simon                                                                                                                         |
| 139 |     628.46191 |    302.342223 | Amanda Katzer                                                                                                                        |
| 140 |     957.17392 |    422.075701 | T. Tischler                                                                                                                          |
| 141 |     444.70389 |    372.016337 | Becky Barnes                                                                                                                         |
| 142 |     540.18334 |    365.766066 | NA                                                                                                                                   |
| 143 |     764.14281 |    144.254098 | Collin Gross                                                                                                                         |
| 144 |     626.17052 |     65.674902 | Andy Wilson                                                                                                                          |
| 145 |     239.14152 |    118.785023 | Chris huh                                                                                                                            |
| 146 |     519.62919 |    390.642819 | NA                                                                                                                                   |
| 147 |     977.94620 |    676.546262 | Ferran Sayol                                                                                                                         |
| 148 |     482.91035 |    780.745298 | Sarah Werning                                                                                                                        |
| 149 |     393.70411 |    449.994990 | Steven Traver                                                                                                                        |
| 150 |      82.61055 |    383.330165 | Matt Crook                                                                                                                           |
| 151 |     661.61367 |    462.599288 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                            |
| 152 |      56.10578 |    566.498079 | Jagged Fang Designs                                                                                                                  |
| 153 |     996.33169 |    125.642209 | Mali’o Kodis, image from Brockhaus and Efron Encyclopedic Dictionary                                                                 |
| 154 |     194.01946 |    575.601548 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                    |
| 155 |     434.34283 |     66.107276 | Jesús Gómez, vectorized by Zimices                                                                                                   |
| 156 |     247.76685 |    132.879423 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                    |
| 157 |      22.98924 |    383.392224 | Chloé Schmidt                                                                                                                        |
| 158 |     708.97952 |    500.454394 | NA                                                                                                                                   |
| 159 |     489.01451 |    243.774093 | Matt Crook                                                                                                                           |
| 160 |     791.62912 |    761.498712 | Gabriela Palomo-Munoz                                                                                                                |
| 161 |     696.77180 |    282.599091 | Mali’o Kodis, photograph by Melissa Frey                                                                                             |
| 162 |     956.51963 |    690.818110 | NA                                                                                                                                   |
| 163 |      15.50757 |    601.235514 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                       |
| 164 |      46.68181 |    502.133926 | Beth Reinke                                                                                                                          |
| 165 |    1006.84576 |    438.473605 | Zimices                                                                                                                              |
| 166 |     408.70000 |    398.368965 | Andrew A. Farke                                                                                                                      |
| 167 |      91.35799 |    294.374528 | Richard Ruggiero, vectorized by Zimices                                                                                              |
| 168 |     496.93614 |    457.311969 | MPF (vectorized by T. Michael Keesey)                                                                                                |
| 169 |     249.56654 |    546.181526 | Matt Crook                                                                                                                           |
| 170 |     385.77089 |    310.330787 | NA                                                                                                                                   |
| 171 |     362.07773 |    616.782759 | Kai R. Caspar                                                                                                                        |
| 172 |     317.04542 |    693.993668 | Scott Hartman                                                                                                                        |
| 173 |     986.13013 |    688.421097 | Chris huh                                                                                                                            |
| 174 |     170.31040 |    790.740912 | Cesar Julian                                                                                                                         |
| 175 |     411.02236 |     42.191730 | Jaime Headden                                                                                                                        |
| 176 |     189.56511 |    295.666986 | Andy Wilson                                                                                                                          |
| 177 |      23.80457 |    189.951945 | Becky Barnes                                                                                                                         |
| 178 |    1007.14325 |     59.576504 | Steven Traver                                                                                                                        |
| 179 |     315.07542 |    466.012983 | Jimmy Bernot                                                                                                                         |
| 180 |     902.03865 |     27.345108 | Lukasiniho                                                                                                                           |
| 181 |     811.00798 |    195.449565 | NA                                                                                                                                   |
| 182 |     960.14998 |    175.388524 | T. Michael Keesey                                                                                                                    |
| 183 |     269.46508 |     47.840217 | Andy Wilson                                                                                                                          |
| 184 |     143.82443 |    638.561389 | Scott Hartman                                                                                                                        |
| 185 |     535.30235 |    213.529599 | C. Camilo Julián-Caballero                                                                                                           |
| 186 |     892.93568 |    422.620992 | Andy Wilson                                                                                                                          |
| 187 |     742.15141 |    526.550714 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                        |
| 188 |     301.33382 |    648.153700 | Ingo Braasch                                                                                                                         |
| 189 |     682.76443 |    455.931650 | Markus A. Grohme                                                                                                                     |
| 190 |     434.65384 |    573.688099 | Robert Gay, modifed from Olegivvit                                                                                                   |
| 191 |      38.89949 |    338.536657 | Kelly                                                                                                                                |
| 192 |     905.08806 |    633.831094 | Matt Crook                                                                                                                           |
| 193 |     566.87078 |    397.223868 | Matt Martyniuk                                                                                                                       |
| 194 |      96.02243 |    361.529858 | Dean Schnabel                                                                                                                        |
| 195 |      94.12445 |    193.189764 | Gareth Monger                                                                                                                        |
| 196 |     884.69826 |    789.485040 | Tasman Dixon                                                                                                                         |
| 197 |     151.46011 |    295.197522 | Inessa Voet                                                                                                                          |
| 198 |     132.06315 |    357.892496 | Gabriela Palomo-Munoz                                                                                                                |
| 199 |     586.88473 |     98.914524 | T. Michael Keesey                                                                                                                    |
| 200 |      14.99618 |    113.925380 | NA                                                                                                                                   |
| 201 |     420.27164 |    410.096347 | Margot Michaud                                                                                                                       |
| 202 |     771.21943 |    780.178048 | Margot Michaud                                                                                                                       |
| 203 |     972.24429 |    230.986724 | Margot Michaud                                                                                                                       |
| 204 |     862.85166 |    484.909824 | Chuanixn Yu                                                                                                                          |
| 205 |     487.69203 |    684.155432 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                  |
| 206 |     451.83372 |    147.434326 | Jimmy Bernot                                                                                                                         |
| 207 |     733.82957 |    125.167320 | Juan Carlos Jerí                                                                                                                     |
| 208 |    1001.15436 |    254.340476 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                    |
| 209 |     463.60022 |    245.844255 | Tasman Dixon                                                                                                                         |
| 210 |      12.41276 |     47.467182 | Jon Hill (Photo by DickDaniels: <http://en.wikipedia.org/wiki/File:Green_Woodhoopoe_RWD7.jpg>)                                       |
| 211 |     508.11890 |    592.228795 | Margot Michaud                                                                                                                       |
| 212 |     396.75430 |    482.079137 | Steven Traver                                                                                                                        |
| 213 |     860.47765 |    131.675477 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                          |
| 214 |      28.23039 |     57.194907 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                   |
| 215 |     586.93706 |    186.078837 | Jaime Headden                                                                                                                        |
| 216 |     296.77006 |    325.104616 | Andy Wilson                                                                                                                          |
| 217 |     353.61994 |    478.615572 | Markus A. Grohme                                                                                                                     |
| 218 |     981.53031 |    743.091098 | mystica                                                                                                                              |
| 219 |     684.21642 |     21.332689 | Margot Michaud                                                                                                                       |
| 220 |    1003.74502 |    342.697823 | C. Camilo Julián-Caballero                                                                                                           |
| 221 |     282.58201 |    633.102286 | Liftarn                                                                                                                              |
| 222 |     836.41072 |    788.207613 | Maija Karala                                                                                                                         |
| 223 |     816.39936 |    516.141667 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                        |
| 224 |     515.37441 |    790.539338 | Zimices                                                                                                                              |
| 225 |     927.94170 |     58.737356 | Felix Vaux                                                                                                                           |
| 226 |     453.46828 |     12.094689 | Zimices                                                                                                                              |
| 227 |     651.13861 |      4.157281 | Markus A. Grohme                                                                                                                     |
| 228 |      72.68636 |    411.807680 | Markus A. Grohme                                                                                                                     |
| 229 |     872.54418 |    650.814306 | Steven Traver                                                                                                                        |
| 230 |     362.66553 |    524.784256 | Erika Schumacher                                                                                                                     |
| 231 |     583.60980 |    429.011759 | Lafage                                                                                                                               |
| 232 |     206.77462 |    707.998951 | Mo Hassan                                                                                                                            |
| 233 |     910.31153 |    250.202818 | Kanchi Nanjo                                                                                                                         |
| 234 |     560.99348 |    202.450266 | Tauana J. Cunha                                                                                                                      |
| 235 |     139.33339 |    777.638485 | Chuanixn Yu                                                                                                                          |
| 236 |     630.90981 |    647.842095 | Sarah Werning                                                                                                                        |
| 237 |     421.21378 |    630.137463 | T. Michael Keesey (after Mivart)                                                                                                     |
| 238 |     633.37677 |    690.017358 | Scott Reid                                                                                                                           |
| 239 |      73.48694 |    724.358419 | Zimices                                                                                                                              |
| 240 |     195.87311 |    380.804493 | Margot Michaud                                                                                                                       |
| 241 |     411.56920 |    656.793638 | Jaime Headden                                                                                                                        |
| 242 |      25.02467 |    265.920483 | Markus A. Grohme                                                                                                                     |
| 243 |      30.69728 |    472.925435 | Yan Wong from photo by Denes Emoke                                                                                                   |
| 244 |     735.91986 |    290.266161 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                        |
| 245 |     914.43983 |    786.493174 | Gabriela Palomo-Munoz                                                                                                                |
| 246 |     690.04824 |    140.884004 | Margot Michaud                                                                                                                       |
| 247 |     973.61529 |    508.147411 | Joanna Wolfe                                                                                                                         |
| 248 |      44.87217 |    675.601037 | NA                                                                                                                                   |
| 249 |     148.92964 |    533.133475 | Matt Crook                                                                                                                           |
| 250 |     746.12227 |    103.265200 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                        |
| 251 |      98.30991 |    682.106646 | CNZdenek                                                                                                                             |
| 252 |     674.03275 |    323.865749 | Jagged Fang Designs                                                                                                                  |
| 253 |     911.15975 |    213.776194 | Gabriela Palomo-Munoz                                                                                                                |
| 254 |     173.57245 |    598.052868 | Esme Ashe-Jepson                                                                                                                     |
| 255 |     381.74574 |    742.241234 | T. Michael Keesey                                                                                                                    |
| 256 |     603.51373 |    347.383072 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                    |
| 257 |     631.96344 |     90.275297 | Margot Michaud                                                                                                                       |
| 258 |     182.53665 |    514.187371 | Robert Bruce Horsfall, vectorized by Zimices                                                                                         |
| 259 |     740.36347 |    222.872698 | Andy Wilson                                                                                                                          |
| 260 |     120.25053 |    662.186438 | Kai R. Caspar                                                                                                                        |
| 261 |     701.57514 |    414.859904 | Ferran Sayol                                                                                                                         |
| 262 |     706.32711 |     10.404270 | Todd Marshall, vectorized by Zimices                                                                                                 |
| 263 |    1005.83816 |    309.429424 | Andy Wilson                                                                                                                          |
| 264 |     535.67344 |    275.298912 | Aadx                                                                                                                                 |
| 265 |     925.09148 |    184.346393 | Gareth Monger                                                                                                                        |
| 266 |     151.47417 |    263.971995 | Ignacio Contreras                                                                                                                    |
| 267 |     669.03505 |    685.864082 | Gareth Monger                                                                                                                        |
| 268 |     553.88677 |    425.069288 | Melissa Broussard                                                                                                                    |
| 269 |     363.63808 |    280.077631 | Matus Valach                                                                                                                         |
| 270 |     538.43920 |    599.918664 | Frank Förster (based on a picture by Jerry Kirkhart; modified by T. Michael Keesey)                                                  |
| 271 |     363.73570 |    133.831645 | Zimices                                                                                                                              |
| 272 |     825.36725 |    607.282871 | Scott Hartman                                                                                                                        |
| 273 |    1005.65556 |    165.267206 | Emily Willoughby                                                                                                                     |
| 274 |     553.79422 |    116.239228 | Gabriela Palomo-Munoz                                                                                                                |
| 275 |     205.19459 |    554.124044 | NA                                                                                                                                   |
| 276 |     681.60888 |    790.739646 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                    |
| 277 |     113.61066 |     59.740329 | Jiekun He                                                                                                                            |
| 278 |     652.02460 |    429.820997 | Вальдимар (vectorized by T. Michael Keesey)                                                                                          |
| 279 |    1005.63066 |    408.881168 | SecretJellyMan                                                                                                                       |
| 280 |      57.81628 |     81.554286 | Ingo Braasch                                                                                                                         |
| 281 |     116.81598 |    419.006521 | Jagged Fang Designs                                                                                                                  |
| 282 |     834.28498 |    770.322587 | T. Michael Keesey                                                                                                                    |
| 283 |     177.25854 |    732.309773 | Noah Schlottman, photo from Casey Dunn                                                                                               |
| 284 |     270.92834 |    441.618044 | Gabriela Palomo-Munoz                                                                                                                |
| 285 |     422.54953 |    468.408201 | David Orr                                                                                                                            |
| 286 |     312.87685 |    302.722426 | Milton Tan                                                                                                                           |
| 287 |     945.31660 |    663.006445 | Luis Cunha                                                                                                                           |
| 288 |     737.50211 |    252.246629 | Scott Hartman                                                                                                                        |
| 289 |     933.95970 |    377.519930 | Tasman Dixon                                                                                                                         |
| 290 |     429.07980 |    339.354678 | C. Camilo Julián-Caballero                                                                                                           |
| 291 |    1004.37553 |    775.711692 | NA                                                                                                                                   |
| 292 |     143.10911 |    114.398442 | Steven Traver                                                                                                                        |
| 293 |      34.84375 |    520.819611 | Scott Hartman                                                                                                                        |
| 294 |     440.98630 |     42.212653 | Alexandre Vong                                                                                                                       |
| 295 |     758.66478 |    748.798577 | Tasman Dixon                                                                                                                         |
| 296 |     996.62704 |    455.420127 | Andy Wilson                                                                                                                          |
| 297 |     420.00205 |    121.219935 | Andy Wilson                                                                                                                          |
| 298 |     985.07266 |    222.826403 | Jiekun He                                                                                                                            |
| 299 |     376.82456 |    574.970076 | Matt Crook                                                                                                                           |
| 300 |     514.53065 |    145.022515 | Steven Traver                                                                                                                        |
| 301 |     950.67651 |    113.069458 | NA                                                                                                                                   |
| 302 |     834.81246 |    674.706253 | Zimices                                                                                                                              |
| 303 |     309.26668 |     84.275767 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                      |
| 304 |      16.27996 |    227.826084 | Steven Traver                                                                                                                        |
| 305 |     747.35563 |    244.038942 | Ricardo N. Martinez & Oscar A. Alcober                                                                                               |
| 306 |     320.41000 |     40.781909 | T. Michael Keesey (after Monika Betley)                                                                                              |
| 307 |    1008.50814 |    645.947482 | Agnello Picorelli                                                                                                                    |
| 308 |      45.98841 |    784.101239 | Jagged Fang Designs                                                                                                                  |
| 309 |     851.20242 |    421.204880 | Christoph Schomburg                                                                                                                  |
| 310 |     572.25272 |    724.283086 | Tasman Dixon                                                                                                                         |
| 311 |     272.74381 |    712.949299 | Chris huh                                                                                                                            |
| 312 |     764.22422 |    625.160340 | NA                                                                                                                                   |
| 313 |     491.94794 |    558.991910 | Margot Michaud                                                                                                                       |
| 314 |     302.22061 |    511.621487 | Jagged Fang Designs                                                                                                                  |
| 315 |      22.44216 |     77.507573 | T. Tischler                                                                                                                          |
| 316 |     522.36049 |    396.590677 | Gareth Monger                                                                                                                        |
| 317 |     870.38488 |     41.612831 | Matt Crook                                                                                                                           |
| 318 |    1003.94268 |     88.693082 | Margot Michaud                                                                                                                       |
| 319 |     352.06892 |    739.245810 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                              |
| 320 |     453.73463 |    784.889145 | Matt Crook                                                                                                                           |
| 321 |     133.82155 |    518.047539 | NA                                                                                                                                   |
| 322 |     609.08833 |    426.348249 | Tracy A. Heath                                                                                                                       |
| 323 |     967.21727 |    450.098127 | Jagged Fang Designs                                                                                                                  |
| 324 |    1008.11760 |     31.454790 | Chris huh                                                                                                                            |
| 325 |     809.11353 |    147.245812 | Jagged Fang Designs                                                                                                                  |
| 326 |     259.15033 |    696.211855 | Chris huh                                                                                                                            |
| 327 |     356.12296 |    662.987019 | Joseph J. W. Sertich, Mark A. Loewen                                                                                                 |
| 328 |     569.39057 |    350.506081 | Margot Michaud                                                                                                                       |
| 329 |    1008.47152 |    500.833230 | Andy Wilson                                                                                                                          |
| 330 |     649.31420 |    789.431712 | Katie S. Collins                                                                                                                     |
| 331 |     995.52374 |    561.623996 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                          |
| 332 |     785.46552 |    643.608428 | Margot Michaud                                                                                                                       |
| 333 |      17.42583 |    458.355798 | Zimices                                                                                                                              |
| 334 |     864.08138 |    585.752643 | Milton Tan                                                                                                                           |
| 335 |     995.09711 |    363.653777 | Chris huh                                                                                                                            |
| 336 |     446.14383 |    134.422242 | Markus A. Grohme                                                                                                                     |
| 337 |     523.47383 |     80.870972 | Ignacio Contreras                                                                                                                    |
| 338 |     253.52722 |     25.301450 | Zimices                                                                                                                              |
| 339 |     808.92645 |    298.232819 | Steven Coombs                                                                                                                        |
| 340 |     358.22206 |     29.542188 | Birgit Lang                                                                                                                          |
| 341 |     633.66300 |    448.574651 | Carlos Cano-Barbacil                                                                                                                 |
| 342 |     487.75349 |    521.025138 | Jagged Fang Designs                                                                                                                  |
| 343 |     901.85213 |     46.715177 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                    |
| 344 |     578.82537 |    139.006605 | Scott Hartman                                                                                                                        |
| 345 |     517.43262 |    454.900420 | T. Michael Keesey                                                                                                                    |
| 346 |     683.76989 |    597.031693 | Zimices                                                                                                                              |
| 347 |     507.65946 |    285.122481 | Margot Michaud                                                                                                                       |
| 348 |     905.31037 |    272.559803 | Iain Reid                                                                                                                            |
| 349 |     797.13592 |    795.116251 | Scott Hartman                                                                                                                        |
| 350 |     651.18372 |    665.478616 | Cesar Julian                                                                                                                         |
| 351 |     757.66149 |     13.768112 | Scott Hartman                                                                                                                        |
| 352 |     100.80501 |    160.386379 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                    |
| 353 |     409.06451 |    380.771578 | Francesca Belem Lopes Palmeira                                                                                                       |
| 354 |     145.76972 |    322.412036 | Zimices                                                                                                                              |
| 355 |    1009.64262 |    701.801216 | Beth Reinke                                                                                                                          |
| 356 |     632.79898 |    109.777746 | Josefine Bohr Brask                                                                                                                  |
| 357 |     156.72216 |    377.335564 | Ghedoghedo, vectorized by Zimices                                                                                                    |
| 358 |     810.17345 |    405.926787 | Margot Michaud                                                                                                                       |
| 359 |     764.45361 |    343.133969 | Jaime Headden                                                                                                                        |
| 360 |     259.04039 |    164.148901 | Birgit Lang                                                                                                                          |
| 361 |     616.27390 |    466.233939 | Gabriela Palomo-Munoz                                                                                                                |
| 362 |    1013.51281 |    717.646015 | Gareth Monger                                                                                                                        |
| 363 |     708.21707 |    122.308990 | Zimices                                                                                                                              |
| 364 |     950.25539 |    710.764087 | T. Michael Keesey                                                                                                                    |
| 365 |     779.76258 |    233.502809 | Jessica Anne Miller                                                                                                                  |
| 366 |     633.89722 |    659.398277 | Jagged Fang Designs                                                                                                                  |
| 367 |     543.83650 |     99.068466 | T. Michael Keesey                                                                                                                    |
| 368 |     374.29710 |    766.828929 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                    |
| 369 |     548.49684 |    538.019249 | Jagged Fang Designs                                                                                                                  |
| 370 |      68.83060 |    188.051388 | Alexander Schmidt-Lebuhn                                                                                                             |
| 371 |     337.10671 |    583.508889 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                       |
| 372 |     644.82762 |    602.323516 | Margot Michaud                                                                                                                       |
| 373 |      74.17176 |    454.484449 | FunkMonk                                                                                                                             |
| 374 |     212.99409 |    350.235011 | Scott Hartman                                                                                                                        |
| 375 |     849.79971 |    499.728191 | Margot Michaud                                                                                                                       |
| 376 |     776.13335 |    306.047231 | Michael Scroggie                                                                                                                     |
| 377 |     476.13894 |    321.345206 | Roberto Díaz Sibaja                                                                                                                  |
| 378 |     419.22505 |    576.425932 | T. Michael Keesey                                                                                                                    |
| 379 |     281.73366 |    754.838660 | Darren Naish (vectorized by T. Michael Keesey)                                                                                       |
| 380 |     222.04736 |    585.821513 | Noah Schlottman, photo from Casey Dunn                                                                                               |
| 381 |     709.84260 |    328.397462 | Collin Gross                                                                                                                         |
| 382 |     609.30721 |    687.902454 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                               |
| 383 |      15.92490 |    203.361513 | Ieuan Jones                                                                                                                          |
| 384 |     421.47301 |    793.230443 | Pete Buchholz                                                                                                                        |
| 385 |     279.10536 |     12.499907 | Rene Martin                                                                                                                          |
| 386 |     323.24423 |    710.933520 | Becky Barnes                                                                                                                         |
| 387 |     982.22171 |    415.517363 | Michelle Site                                                                                                                        |
| 388 |     615.75483 |    154.289082 | Ferran Sayol                                                                                                                         |
| 389 |     115.21824 |    150.505285 | Zimices                                                                                                                              |
| 390 |     331.55320 |    550.273359 | Andy Wilson                                                                                                                          |
| 391 |     467.73067 |    141.933678 | Conty (vectorized by T. Michael Keesey)                                                                                              |
| 392 |     920.91130 |    774.503815 | C. Camilo Julián-Caballero                                                                                                           |
| 393 |     148.63235 |    421.508938 | Josefine Bohr Brask                                                                                                                  |
| 394 |     868.05534 |     17.460842 | Tracy A. Heath                                                                                                                       |
| 395 |     115.09401 |    178.300106 | Matt Crook                                                                                                                           |
| 396 |     560.29717 |    572.407484 | Gareth Monger                                                                                                                        |
| 397 |     173.69208 |      3.673441 | Gareth Monger                                                                                                                        |
| 398 |     712.02582 |    558.449891 | Chris huh                                                                                                                            |
| 399 |     552.56818 |    678.816467 | Margot Michaud                                                                                                                       |
| 400 |     925.58145 |    392.903391 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                        |
| 401 |     644.49914 |    135.387227 | Carlos Cano-Barbacil                                                                                                                 |
| 402 |     474.95731 |    793.851525 | Pete Buchholz                                                                                                                        |
| 403 |     766.53652 |    322.143293 | Steven Blackwood                                                                                                                     |
| 404 |     415.15220 |    350.688533 | Mathilde Cordellier                                                                                                                  |
| 405 |     879.85987 |    762.198221 | Michael Scroggie                                                                                                                     |
| 406 |     603.53207 |    653.089423 | Andrew A. Farke                                                                                                                      |
| 407 |     502.48994 |      7.947170 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                      |
| 408 |     296.26155 |    430.164964 | Kamil S. Jaron                                                                                                                       |
| 409 |     872.88960 |    398.689168 | L. Shyamal                                                                                                                           |
| 410 |      90.50001 |    342.832693 | C. Camilo Julián-Caballero                                                                                                           |
| 411 |     166.68193 |    430.194494 | Markus A. Grohme                                                                                                                     |
| 412 |       9.16410 |    562.323379 | Mali’o Kodis, photograph from Jersabek et al, 2003                                                                                   |
| 413 |     478.87595 |    232.663409 | Zimices                                                                                                                              |
| 414 |     177.66259 |    259.861925 | Scott Hartman                                                                                                                        |
| 415 |     831.93896 |     14.337220 | Skye McDavid                                                                                                                         |
| 416 |     855.53915 |    777.370595 | Noah Schlottman, photo by Martin V. Sørensen                                                                                         |
| 417 |      19.05438 |    438.260950 | Pete Buchholz                                                                                                                        |
| 418 |     812.92919 |    384.141966 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                    |
| 419 |     647.67038 |     55.026935 | Zimices                                                                                                                              |
| 420 |     219.89301 |    370.727970 | Mathew Wedel                                                                                                                         |
| 421 |     338.18311 |    298.076936 | Andrew A. Farke, shell lines added by Yan Wong                                                                                       |
| 422 |     440.20070 |    659.443962 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey) |
| 423 |     872.47900 |     71.467890 | Kimberly Haddrell                                                                                                                    |
| 424 |     491.83981 |    264.701365 | Zimices / Julián Bayona                                                                                                              |
| 425 |     966.01985 |    560.109544 | Jagged Fang Designs                                                                                                                  |
| 426 |    1010.03177 |    196.951309 | Mali’o Kodis, drawing by Manvir Singh                                                                                                |
| 427 |     514.12627 |     76.269965 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                            |
| 428 |     509.12600 |    378.533163 | Gareth Monger                                                                                                                        |
| 429 |     214.98386 |    692.201322 | Melissa Broussard                                                                                                                    |
| 430 |      59.52998 |     67.843193 | Nobu Tamura, vectorized by Zimices                                                                                                   |
| 431 |      42.55829 |    656.448770 | Noah Schlottman, photo by Casey Dunn                                                                                                 |
| 432 |      85.61474 |    165.245167 | Mette Aumala                                                                                                                         |
| 433 |     569.43312 |     86.024118 | Gopal Murali                                                                                                                         |
| 434 |    1008.91000 |    223.202931 | Renato Santos                                                                                                                        |
| 435 |     937.90625 |    177.381833 | Blanco et al., 2014, vectorized by Zimices                                                                                           |
| 436 |      51.42806 |    367.981439 | Gabriela Palomo-Munoz                                                                                                                |
| 437 |     633.14031 |    494.533775 | Chris huh                                                                                                                            |
| 438 |     533.29045 |    193.917494 | Carlos Cano-Barbacil                                                                                                                 |
| 439 |     557.04014 |    633.409890 | T. Michael Keesey                                                                                                                    |
| 440 |    1012.92196 |    600.574535 | Michele M Tobias from an image By Dcrjsr - Own work, CC BY 3.0, <https://commons.wikimedia.org/w/index.php?curid=18059686>           |
| 441 |     334.36811 |    655.824748 | Ferran Sayol                                                                                                                         |
| 442 |     804.72011 |    778.196863 | Tyler McCraney                                                                                                                       |
| 443 |     575.03761 |    410.859327 | Margot Michaud                                                                                                                       |
| 444 |     205.97525 |    278.098956 | Alexandre Vong                                                                                                                       |
| 445 |     487.26872 |    600.228353 | Chloé Schmidt                                                                                                                        |
| 446 |     901.57645 |    169.385685 | Scott Hartman, modified by T. Michael Keesey                                                                                         |
| 447 |     715.90501 |     34.592787 | Joseph Smit (modified by T. Michael Keesey)                                                                                          |
| 448 |     975.45080 |    431.096973 | C. Camilo Julián-Caballero                                                                                                           |
| 449 |     643.91925 |    750.352692 | Smokeybjb                                                                                                                            |
| 450 |     928.55254 |    251.678232 | Gareth Monger                                                                                                                        |
| 451 |     735.80822 |    755.443876 | Jagged Fang Designs                                                                                                                  |
| 452 |      17.07354 |    677.363748 | Gareth Monger                                                                                                                        |
| 453 |     432.79159 |    673.509418 | Margot Michaud                                                                                                                       |
| 454 |     204.29598 |    134.613246 | Jaime Headden                                                                                                                        |
| 455 |     645.68474 |     28.473881 | Jagged Fang Designs                                                                                                                  |
| 456 |      66.78904 |    429.802567 | T. Michael Keesey                                                                                                                    |
| 457 |     762.95828 |    791.541728 | Steven Traver                                                                                                                        |
| 458 |     324.50831 |    473.358386 | Brockhaus and Efron                                                                                                                  |
| 459 |     567.45691 |     33.306205 | Margot Michaud                                                                                                                       |
| 460 |     414.04755 |     55.576940 | Mykle Hoban                                                                                                                          |
| 461 |     219.77128 |    568.414849 | Iain Reid                                                                                                                            |
| 462 |     513.38879 |    208.444168 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                 |
| 463 |     752.70555 |    517.267593 | T. Michael Keesey                                                                                                                    |
| 464 |     790.16590 |    383.679658 | Jagged Fang Designs                                                                                                                  |
| 465 |      16.26834 |    699.503231 | NA                                                                                                                                   |
| 466 |     769.49015 |    201.498480 | Scott Hartman                                                                                                                        |
| 467 |     316.69162 |    312.220413 | Nobu Tamura, vectorized by Zimices                                                                                                   |
| 468 |     425.54284 |    779.531671 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                        |
| 469 |     237.22693 |    535.346115 | SauropodomorphMonarch                                                                                                                |
| 470 |     259.58222 |    638.113047 | Tasman Dixon                                                                                                                         |
| 471 |     832.41467 |      6.245505 | Armin Reindl                                                                                                                         |
| 472 |     253.41284 |    793.096335 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                     |
| 473 |     537.26366 |    350.604826 | Andy Wilson                                                                                                                          |
| 474 |     817.78764 |    539.703101 | Noah Schlottman, photo from Casey Dunn                                                                                               |
| 475 |     932.76095 |     25.412341 | Blair Perry                                                                                                                          |
| 476 |     667.28796 |    234.689888 | Michelle Site                                                                                                                        |
| 477 |     475.54499 |    160.638633 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                             |
| 478 |     398.39873 |    606.777614 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                    |
| 479 |     157.94504 |    467.125396 | Chris huh                                                                                                                            |
| 480 |     935.02260 |    539.598011 | Jimmy Bernot                                                                                                                         |
| 481 |     189.11803 |    153.684060 | Gabriela Palomo-Munoz                                                                                                                |
| 482 |     397.37907 |      6.098801 | Servien (vectorized by T. Michael Keesey)                                                                                            |
| 483 |     875.57333 |    575.876270 | Tasman Dixon                                                                                                                         |
| 484 |     664.21024 |    223.668370 | Nina Skinner                                                                                                                         |
| 485 |     584.22077 |    681.853157 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                        |
| 486 |     922.80497 |    649.886407 | Jaime Headden                                                                                                                        |
| 487 |     828.99631 |    756.564679 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                      |
| 488 |    1004.30025 |    743.819857 | Sean McCann                                                                                                                          |
| 489 |     141.15408 |    279.785767 | NA                                                                                                                                   |
| 490 |     294.61665 |    464.604266 | Chris huh                                                                                                                            |
| 491 |     583.76258 |    439.108473 | Zimices                                                                                                                              |
| 492 |     360.52231 |    471.320413 | Chris huh                                                                                                                            |
| 493 |     622.82907 |     77.578667 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                |
| 494 |     996.53666 |    328.609294 | Nobu Tamura, modified by Andrew A. Farke                                                                                             |
| 495 |     786.19713 |    693.911523 | Yan Wong                                                                                                                             |
| 496 |     304.88515 |     47.611203 | T. Michael Keesey                                                                                                                    |
| 497 |     805.21299 |    289.931103 | Dean Schnabel                                                                                                                        |
| 498 |     951.43822 |    444.104300 | C. Camilo Julián-Caballero                                                                                                           |
| 499 |     681.16358 |    753.635193 | FunkMonk                                                                                                                             |
| 500 |     383.61495 |    661.977651 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                      |
| 501 |     592.14492 |    745.293309 | Zimices                                                                                                                              |
| 502 |     463.44252 |    532.006562 | Carlos Cano-Barbacil                                                                                                                 |
| 503 |     960.39206 |    758.363678 | Zimices                                                                                                                              |
| 504 |     192.47722 |    473.309666 | Gareth Monger                                                                                                                        |
| 505 |     376.79781 |    347.048823 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                        |
| 506 |      69.02112 |    690.978200 | Steven Traver                                                                                                                        |
| 507 |     623.03883 |    480.756724 | Benchill                                                                                                                             |
| 508 |     601.40895 |     81.305247 | Anthony Caravaggi                                                                                                                    |
| 509 |     819.09890 |    461.471152 | Emily Willoughby                                                                                                                     |
| 510 |     172.98668 |    318.728288 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                       |
| 511 |     701.40022 |    301.103028 | Melissa Broussard                                                                                                                    |
| 512 |      43.72348 |    422.848912 | Steven Coombs                                                                                                                        |
| 513 |     807.82494 |    448.571810 | Daniel Stadtmauer                                                                                                                    |
| 514 |     247.70069 |    457.282325 | NA                                                                                                                                   |
| 515 |     324.26851 |     10.486384 | Taenadoman                                                                                                                           |
| 516 |     180.42761 |    248.285539 | Zimices                                                                                                                              |
| 517 |     115.46780 |    378.036933 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                    |

    #> Your tweet has been posted!
