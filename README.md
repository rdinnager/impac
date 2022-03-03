
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

Gareth Monger, Sergio A. Muñoz-Gómez, Noah Schlottman, Jan A. Venter,
Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T.
Michael Keesey), T. Michael Keesey, Chris huh, Ferran Sayol, Ludwik
Gasiorowski, Tasman Dixon, Sarah Alewijnse, Kailah Thorn & Mark
Hutchinson, Gabriela Palomo-Munoz, Scott Hartman, Don Armstrong, Sharon
Wegner-Larsen, Margot Michaud, Scott Reid, Dmitry Bogdanov (vectorized
by T. Michael Keesey), Noah Schlottman, photo by David J Patterson, Andy
Wilson, Dean Schnabel, Michelle Site, Jagged Fang Designs, James I.
Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and
Jelle P. Wiersma (vectorized by T. Michael Keesey), Rebecca Groom,
George Edward Lodge (modified by T. Michael Keesey), Mali’o Kodis, image
from Higgins and Kristensen, 1986, Alexander Schmidt-Lebuhn, Campbell
Fleming, Tyler Greenfield, Dennis C. Murphy, after
<https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png>,
Mette Aumala, Steven Coombs, Nobu Tamura (vectorized by T. Michael
Keesey), Matt Crook, Jack Mayer Wood, Ignacio Contreras, Birgit Lang,
Christoph Schomburg, Obsidian Soul (vectorized by T. Michael Keesey),
Tracy A. Heath, Steven Traver, Enoch Joseph Wetsy (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Apokryltaros
(vectorized by T. Michael Keesey), Collin Gross, Kenneth Lacovara
(vectorized by T. Michael Keesey), Zimices, Alan Manson (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Iain Reid, Jaime
Headden, Yan Wong, Chloé Schmidt, Roberto Díaz Sibaja, Smokeybjb
(vectorized by T. Michael Keesey), CNZdenek, Lafage, Agnello Picorelli,
FunkMonk, Derek Bakken (photograph) and T. Michael Keesey
(vectorization), Jon Hill, C. W. Nash (illustration) and Timothy J.
Bartley (silhouette), Sarah Werning, Curtis Clark and T. Michael Keesey,
A. R. McCulloch (vectorized by T. Michael Keesey), Kanchi Nanjo, Michele
Tobias, Katie S. Collins, Jiekun He, Anthony Caravaggi,
SauropodomorphMonarch, Lily Hughes, Dmitry Bogdanov and FunkMonk
(vectorized by T. Michael Keesey), Auckland Museum, Michael Scroggie, T.
Michael Keesey (from a mount by Allis Markham), Mali’o Kodis, photograph
by G. Giribet, L. Shyamal, Pete Buchholz, Armin Reindl, Chris Jennings
(vectorized by A. Verrière), Renato de Carvalho Ferreira, Matt Celeskey,
Andrew A. Farke, Rachel Shoop, Kai R. Caspar, Andrew A. Farke, shell
lines added by Yan Wong, Chase Brownstein, Kamil S. Jaron, Skye McDavid,
M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius
(vectorized by T. Michael Keesey), Mateus Zica (modified by T. Michael
Keesey), Caleb M. Brown, Tauana J. Cunha, T. Michael Keesey
(vectorization) and Nadiatalent (photography), Rene Martin, Markus A.
Grohme, Noah Schlottman, photo by Casey Dunn, T. Michael Keesey
(vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees,
Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and
David W. Wrase (photography), Falconaumanni and T. Michael Keesey,
Mathew Stewart, Tim Bertelink (modified by T. Michael Keesey), Tommaso
Cancellario, Beth Reinke, Diana Pomeroy, Chris Hay, T. Michael Keesey
(photo by Sean Mack), Mr E? (vectorized by T. Michael Keesey), Chuanixn
Yu, Alex Slavenko, Qiang Ou, I. Sácek, Sr. (vectorized by T. Michael
Keesey), Michael P. Taylor, T. Michael Keesey (vectorization); Yves
Bousquet (photography), Catherine Yasuda, Yan Wong from drawing in The
Century Dictionary (1911), T. Michael Keesey (after Monika Betley), Leon
P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin, Pearson Scott
Foresman (vectorized by T. Michael Keesey), Nobu Tamura, Xavier
Giroux-Bougard, Giant Blue Anteater (vectorized by T. Michael Keesey),
Alexandre Vong, Joris van der Ham (vectorized by T. Michael Keesey), Yan
Wong from illustration by Jules Richard (1907), Noah Schlottman, photo
by Martin V. Sørensen, Charles R. Knight (vectorized by T. Michael
Keesey), Emily Willoughby, Myriam\_Ramirez, Nobu Tamura, modified by
Andrew A. Farke, Felix Vaux, Jim Bendon (photography) and T. Michael
Keesey (vectorization), Dmitry Bogdanov, S.Martini, Ghedoghedo
(vectorized by T. Michael Keesey), Matthew E. Clapham, Liftarn, Julio
Garza, Milton Tan, Stanton F. Fink (vectorized by T. Michael Keesey),
Richard J. Harris, T. Michael Keesey (after Tillyard), Mathew Wedel,
Christine Axon, Javier Luque & Sarah Gerken, Melissa Broussard, C.
Camilo Julián-Caballero, Tarique Sani (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Emma Kissling, Felix Vaux
and Steven A. Trewick, Nobu Tamura (modified by T. Michael Keesey),
Eduard Solà (vectorized by T. Michael Keesey), Darius Nau, Jakovche,
Harold N Eyster, Mali’o Kodis, photograph by Bruno Vellutini, Lukas
Panzarin, Oscar Sanisidro, Michele M Tobias, Bruno C. Vellutini, Robert
Gay, Acrocynus (vectorized by T. Michael Keesey), Mattia Menchetti,
nicubunu, Crystal Maier, Jay Matternes (vectorized by T. Michael
Keesey), Becky Barnes, Haplochromis (vectorized by T. Michael Keesey),
Martin R. Smith, SecretJellyMan - from Mason McNair, xgirouxb, Diego
Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli,
Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by
T. Michael Keesey), Young and Zhao (1972:figure 4), modified by Michael
P. Taylor, John Curtis (vectorized by T. Michael Keesey), Michael Wolf
(photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization),
Smokeybjb, Geoff Shaw, Fir0002/Flagstaffotos (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Ingo Braasch, Bennet
McComish, photo by Avenue, Siobhon Egan, Sherman Foote Denton
(illustration, 1897) and Timothy J. Bartley (silhouette)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                               |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     84.576677 |    218.178731 | Gareth Monger                                                                                                                                                                        |
|   2 |    912.289769 |    694.064828 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
|   3 |    868.387539 |    532.044714 | Noah Schlottman                                                                                                                                                                      |
|   4 |    377.568874 |    534.460000 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                                  |
|   5 |    696.845063 |    471.740768 | T. Michael Keesey                                                                                                                                                                    |
|   6 |    930.418718 |    483.660707 | Chris huh                                                                                                                                                                            |
|   7 |    262.785254 |    284.480207 | Ferran Sayol                                                                                                                                                                         |
|   8 |    462.637472 |    631.694985 | Ludwik Gasiorowski                                                                                                                                                                   |
|   9 |    821.584033 |    663.955723 | Tasman Dixon                                                                                                                                                                         |
|  10 |     78.942642 |    383.442691 | Sarah Alewijnse                                                                                                                                                                      |
|  11 |    189.570785 |    556.297946 | Kailah Thorn & Mark Hutchinson                                                                                                                                                       |
|  12 |    822.669331 |    299.236919 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  13 |    613.881120 |    558.405651 | Scott Hartman                                                                                                                                                                        |
|  14 |    541.251236 |    291.477889 | Don Armstrong                                                                                                                                                                        |
|  15 |     94.076240 |    133.400919 | Sharon Wegner-Larsen                                                                                                                                                                 |
|  16 |    303.017546 |    726.194294 | Margot Michaud                                                                                                                                                                       |
|  17 |    795.992455 |    123.795439 | Scott Reid                                                                                                                                                                           |
|  18 |    463.669170 |    435.224209 | Margot Michaud                                                                                                                                                                       |
|  19 |    602.733888 |    122.795875 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  20 |    551.613501 |    179.780241 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
|  21 |    940.506814 |    286.398191 | Noah Schlottman, photo by David J Patterson                                                                                                                                          |
|  22 |    158.471952 |    708.431474 | Andy Wilson                                                                                                                                                                          |
|  23 |    737.944005 |    369.427556 | T. Michael Keesey                                                                                                                                                                    |
|  24 |    365.040338 |    263.350766 | Dean Schnabel                                                                                                                                                                        |
|  25 |    623.608649 |    614.302900 | Margot Michaud                                                                                                                                                                       |
|  26 |    594.259298 |    408.721309 | Michelle Site                                                                                                                                                                        |
|  27 |    617.801652 |    355.137421 | Jagged Fang Designs                                                                                                                                                                  |
|  28 |    778.786409 |    567.430540 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                                 |
|  29 |    589.266959 |    764.996977 | Rebecca Groom                                                                                                                                                                        |
|  30 |     68.126692 |    605.640427 | George Edward Lodge (modified by T. Michael Keesey)                                                                                                                                  |
|  31 |    683.428117 |    219.706880 | Mali’o Kodis, image from Higgins and Kristensen, 1986                                                                                                                                |
|  32 |    926.447989 |     45.551870 | Margot Michaud                                                                                                                                                                       |
|  33 |    328.613062 |    434.234984 | NA                                                                                                                                                                                   |
|  34 |    196.925297 |     76.874672 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
|  35 |    960.653534 |    162.651601 | Campbell Fleming                                                                                                                                                                     |
|  36 |    511.035722 |     65.659054 | NA                                                                                                                                                                                   |
|  37 |    319.289532 |    633.299138 | Dean Schnabel                                                                                                                                                                        |
|  38 |    878.696182 |    422.450580 | Tyler Greenfield                                                                                                                                                                     |
|  39 |    950.716243 |    361.667318 | Dennis C. Murphy, after <https://commons.wikimedia.org/wiki/File:Queensland_State_Archives_2981_Cane_toads_at_the_Meringa_Sugar_Experiment_Station_North_Queensland_c_1935.png>      |
|  40 |    369.484668 |    382.591427 | Mette Aumala                                                                                                                                                                         |
|  41 |    507.760332 |    690.401604 | Rebecca Groom                                                                                                                                                                        |
|  42 |    446.559619 |    756.333487 | Steven Coombs                                                                                                                                                                        |
|  43 |     61.229245 |     37.726746 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  44 |    243.821082 |    482.445599 | Jagged Fang Designs                                                                                                                                                                  |
|  45 |    424.442371 |    131.168172 | Matt Crook                                                                                                                                                                           |
|  46 |    879.500483 |    218.108222 | Scott Hartman                                                                                                                                                                        |
|  47 |    347.587642 |     21.514585 | Jack Mayer Wood                                                                                                                                                                      |
|  48 |    957.567916 |    559.820624 | Sergio A. Muñoz-Gómez                                                                                                                                                                |
|  49 |    284.802514 |     54.510025 | Ignacio Contreras                                                                                                                                                                    |
|  50 |    538.114183 |    489.784969 | Margot Michaud                                                                                                                                                                       |
|  51 |     77.748653 |    315.642213 | Birgit Lang                                                                                                                                                                          |
|  52 |    707.448723 |    588.607449 | T. Michael Keesey                                                                                                                                                                    |
|  53 |     20.220397 |    678.546143 | Dean Schnabel                                                                                                                                                                        |
|  54 |    961.279982 |    766.678581 | Dean Schnabel                                                                                                                                                                        |
|  55 |    814.570394 |    399.693149 | Christoph Schomburg                                                                                                                                                                  |
|  56 |    622.354436 |     42.467423 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
|  57 |    453.034913 |    287.093743 | Tracy A. Heath                                                                                                                                                                       |
|  58 |    518.658812 |    217.692310 | Tyler Greenfield                                                                                                                                                                     |
|  59 |    579.884628 |    667.693539 | NA                                                                                                                                                                                   |
|  60 |     28.041746 |    211.124723 | Steven Traver                                                                                                                                                                        |
|  61 |    184.192289 |    607.064470 | Jagged Fang Designs                                                                                                                                                                  |
|  62 |    404.298405 |     47.167697 | Scott Hartman                                                                                                                                                                        |
|  63 |    499.581865 |    388.693974 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                   |
|  64 |     84.120608 |    433.949270 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                                       |
|  65 |    622.401859 |     72.992929 | Collin Gross                                                                                                                                                                         |
|  66 |    363.399264 |    332.513526 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                                   |
|  67 |     77.150770 |    496.041458 | Scott Hartman                                                                                                                                                                        |
|  68 |    702.311515 |    526.199961 | Zimices                                                                                                                                                                              |
|  69 |    319.822408 |    784.231024 | T. Michael Keesey                                                                                                                                                                    |
|  70 |    193.965331 |    174.238630 | Jagged Fang Designs                                                                                                                                                                  |
|  71 |    949.213363 |    688.949724 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                          |
|  72 |    264.643736 |    376.170007 | Jagged Fang Designs                                                                                                                                                                  |
|  73 |    135.492934 |    659.918842 | Iain Reid                                                                                                                                                                            |
|  74 |    475.121481 |    534.288992 | Zimices                                                                                                                                                                              |
|  75 |    523.946271 |    584.706135 | NA                                                                                                                                                                                   |
|  76 |    634.639925 |    166.091867 | Jaime Headden                                                                                                                                                                        |
|  77 |   1000.306064 |    613.385729 | Yan Wong                                                                                                                                                                             |
|  78 |    235.617664 |    423.516821 | Chloé Schmidt                                                                                                                                                                        |
|  79 |    321.532719 |    574.283471 | Roberto Díaz Sibaja                                                                                                                                                                  |
|  80 |    491.451659 |    782.199103 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                                          |
|  81 |    322.029405 |    671.382119 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  82 |    936.098919 |    183.494427 | Gabriela Palomo-Munoz                                                                                                                                                                |
|  83 |    243.524420 |    105.569047 | T. Michael Keesey                                                                                                                                                                    |
|  84 |    650.185494 |    752.584737 | CNZdenek                                                                                                                                                                             |
|  85 |    642.759639 |    145.795537 | Lafage                                                                                                                                                                               |
|  86 |     52.707402 |    532.506976 | Agnello Picorelli                                                                                                                                                                    |
|  87 |    857.812366 |     70.442743 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
|  88 |    310.029121 |    352.505544 | Jagged Fang Designs                                                                                                                                                                  |
|  89 |    989.353837 |    704.266062 | Andy Wilson                                                                                                                                                                          |
|  90 |    810.605844 |    230.966102 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
|  91 |    441.269094 |    784.266859 | Jack Mayer Wood                                                                                                                                                                      |
|  92 |     86.818474 |     78.848833 | FunkMonk                                                                                                                                                                             |
|  93 |    283.737959 |    506.663347 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                                      |
|  94 |    992.072826 |     92.102393 | Scott Hartman                                                                                                                                                                        |
|  95 |    690.983676 |    436.513585 | Jon Hill                                                                                                                                                                             |
|  96 |    522.173603 |    360.715220 | Gareth Monger                                                                                                                                                                        |
|  97 |    472.137887 |    507.817384 | C. W. Nash (illustration) and Timothy J. Bartley (silhouette)                                                                                                                        |
|  98 |    440.542861 |    223.638198 | Yan Wong                                                                                                                                                                             |
|  99 |    819.100855 |    494.650986 | Sarah Werning                                                                                                                                                                        |
| 100 |    222.283938 |    510.702752 | Scott Hartman                                                                                                                                                                        |
| 101 |    409.347790 |    709.946892 | Curtis Clark and T. Michael Keesey                                                                                                                                                   |
| 102 |    642.491365 |    367.606465 | A. R. McCulloch (vectorized by T. Michael Keesey)                                                                                                                                    |
| 103 |    698.907264 |    116.461082 | Gareth Monger                                                                                                                                                                        |
| 104 |    872.379101 |    460.164062 | Kanchi Nanjo                                                                                                                                                                         |
| 105 |    991.902701 |     69.114195 | Collin Gross                                                                                                                                                                         |
| 106 |    136.654267 |    259.407885 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 107 |    917.546458 |    128.658089 | Gareth Monger                                                                                                                                                                        |
| 108 |     67.761990 |    752.736565 | Sarah Werning                                                                                                                                                                        |
| 109 |    168.535561 |     33.650230 | NA                                                                                                                                                                                   |
| 110 |    816.048044 |     11.141034 | Chris huh                                                                                                                                                                            |
| 111 |    542.265117 |    446.368665 | Andy Wilson                                                                                                                                                                          |
| 112 |    686.289219 |    375.177664 | T. Michael Keesey                                                                                                                                                                    |
| 113 |    258.895062 |    537.109988 | Matt Crook                                                                                                                                                                           |
| 114 |    312.315118 |    536.604181 | Michele Tobias                                                                                                                                                                       |
| 115 |    263.139895 |    607.476616 | Katie S. Collins                                                                                                                                                                     |
| 116 |    711.985241 |    560.778432 | Lafage                                                                                                                                                                               |
| 117 |    785.440005 |    432.963829 | Ferran Sayol                                                                                                                                                                         |
| 118 |    557.526589 |     93.143791 | NA                                                                                                                                                                                   |
| 119 |    843.750475 |    352.536393 | Jiekun He                                                                                                                                                                            |
| 120 |    507.379721 |    396.103524 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 121 |    749.601023 |    634.699958 | Katie S. Collins                                                                                                                                                                     |
| 122 |    660.724411 |    293.456637 | Anthony Caravaggi                                                                                                                                                                    |
| 123 |    302.685043 |    612.960061 | Steven Traver                                                                                                                                                                        |
| 124 |    488.817984 |    355.082658 | SauropodomorphMonarch                                                                                                                                                                |
| 125 |    894.565500 |    141.160095 | Lily Hughes                                                                                                                                                                          |
| 126 |    906.939896 |    624.646126 | Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey)                                                                                                                       |
| 127 |     56.831370 |    420.431593 | Matt Crook                                                                                                                                                                           |
| 128 |    231.177243 |    156.728205 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 129 |    748.455253 |    215.655482 | Matt Crook                                                                                                                                                                           |
| 130 |    909.962979 |    550.223991 | Tasman Dixon                                                                                                                                                                         |
| 131 |    702.331958 |     35.421419 | Chris huh                                                                                                                                                                            |
| 132 |    118.508218 |    782.657306 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 133 |    900.417064 |     98.384598 | Auckland Museum                                                                                                                                                                      |
| 134 |    152.156399 |     87.225646 | Ferran Sayol                                                                                                                                                                         |
| 135 |    457.546892 |    349.550977 | NA                                                                                                                                                                                   |
| 136 |    937.524275 |    220.933820 | Scott Hartman                                                                                                                                                                        |
| 137 |    599.168230 |    436.387145 | Michael Scroggie                                                                                                                                                                     |
| 138 |    598.370672 |    241.815209 | NA                                                                                                                                                                                   |
| 139 |    624.577888 |    308.649102 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 140 |    396.512572 |    599.942887 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                                                    |
| 141 |    750.894040 |    288.575953 | Zimices                                                                                                                                                                              |
| 142 |    965.880510 |    450.319814 | Mali’o Kodis, photograph by G. Giribet                                                                                                                                               |
| 143 |     37.383944 |     72.084902 | Ferran Sayol                                                                                                                                                                         |
| 144 |    865.414450 |    291.146183 | Jagged Fang Designs                                                                                                                                                                  |
| 145 |    428.307051 |     70.638250 | L. Shyamal                                                                                                                                                                           |
| 146 |    590.538886 |     13.137590 | Pete Buchholz                                                                                                                                                                        |
| 147 |    437.482881 |      8.656754 | Armin Reindl                                                                                                                                                                         |
| 148 |    412.061498 |    428.813402 | Chris Jennings (vectorized by A. Verrière)                                                                                                                                           |
| 149 |    107.369840 |    557.978207 | Renato de Carvalho Ferreira                                                                                                                                                          |
| 150 |    204.532511 |    451.817063 | Jagged Fang Designs                                                                                                                                                                  |
| 151 |    891.216006 |    574.733372 | Steven Traver                                                                                                                                                                        |
| 152 |    116.606104 |    462.154006 | Dean Schnabel                                                                                                                                                                        |
| 153 |    980.921488 |    106.560103 | Scott Hartman                                                                                                                                                                        |
| 154 |    113.858622 |    582.457923 | Matt Celeskey                                                                                                                                                                        |
| 155 |    750.754977 |    162.915440 | Gareth Monger                                                                                                                                                                        |
| 156 |    942.110449 |    439.206098 | Sarah Werning                                                                                                                                                                        |
| 157 |    855.534162 |    651.406432 | Andrew A. Farke                                                                                                                                                                      |
| 158 |   1006.435928 |    230.191088 | Chris huh                                                                                                                                                                            |
| 159 |    202.727387 |    756.862539 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 160 |    823.021214 |    765.704256 | Rachel Shoop                                                                                                                                                                         |
| 161 |    723.769811 |    288.165248 | NA                                                                                                                                                                                   |
| 162 |    179.168035 |    148.122252 | Kai R. Caspar                                                                                                                                                                        |
| 163 |    847.797792 |    279.374956 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                                       |
| 164 |    488.744288 |    186.251972 | NA                                                                                                                                                                                   |
| 165 |    845.306822 |    581.552277 | Chase Brownstein                                                                                                                                                                     |
| 166 |     11.261329 |    523.768488 | Kamil S. Jaron                                                                                                                                                                       |
| 167 |    343.083126 |    399.955604 | Tasman Dixon                                                                                                                                                                         |
| 168 |    118.044824 |    353.415506 | Skye McDavid                                                                                                                                                                         |
| 169 |    975.674868 |    453.754491 | NA                                                                                                                                                                                   |
| 170 |    815.446193 |     40.161489 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                                             |
| 171 |   1005.133601 |    435.717662 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                                          |
| 172 |    248.945378 |    659.343487 | Caleb M. Brown                                                                                                                                                                       |
| 173 |    930.559704 |    454.194900 | Tauana J. Cunha                                                                                                                                                                      |
| 174 |    459.610194 |     92.062329 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                                      |
| 175 |    360.238154 |     68.492796 | Rene Martin                                                                                                                                                                          |
| 176 |    407.423798 |    475.024313 | Jaime Headden                                                                                                                                                                        |
| 177 |     61.053798 |    692.704894 | Jagged Fang Designs                                                                                                                                                                  |
| 178 |    134.711768 |    615.627284 | Sarah Werning                                                                                                                                                                        |
| 179 |    801.451374 |    425.476035 | Steven Traver                                                                                                                                                                        |
| 180 |    681.481460 |     12.413762 | Markus A. Grohme                                                                                                                                                                     |
| 181 |    561.699774 |    567.345628 | Kamil S. Jaron                                                                                                                                                                       |
| 182 |    508.451217 |    551.725123 | Jagged Fang Designs                                                                                                                                                                  |
| 183 |    883.984635 |      4.747909 | Markus A. Grohme                                                                                                                                                                     |
| 184 |    842.077335 |     34.105584 | Zimices                                                                                                                                                                              |
| 185 |    611.135597 |    726.104666 | Matt Crook                                                                                                                                                                           |
| 186 |    499.934932 |    137.320560 | Zimices                                                                                                                                                                              |
| 187 |    646.698581 |    707.211339 | Gareth Monger                                                                                                                                                                        |
| 188 |    110.774453 |    680.484486 | Noah Schlottman, photo by Casey Dunn                                                                                                                                                 |
| 189 |    629.348332 |    259.457579 | T. Michael Keesey (vectorization); Thorsten Assmann, Jörn Buse, Claudia Drees, Ariel-Leib-Leonid Friedman, Tal Levanony, Andrea Matern, Anika Timm, and David W. Wrase (photography) |
| 190 |    425.114347 |     48.752339 | Chris huh                                                                                                                                                                            |
| 191 |    951.404049 |    158.880438 | Falconaumanni and T. Michael Keesey                                                                                                                                                  |
| 192 |    511.691122 |    728.231663 | Mathew Stewart                                                                                                                                                                       |
| 193 |    615.253070 |     13.295380 | Ferran Sayol                                                                                                                                                                         |
| 194 |    322.033319 |    393.871734 | NA                                                                                                                                                                                   |
| 195 |    725.183147 |    135.772888 | NA                                                                                                                                                                                   |
| 196 |    345.046826 |    566.710800 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 197 |    626.528288 |    205.704378 | Michael Scroggie                                                                                                                                                                     |
| 198 |    892.990914 |    671.880478 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                                        |
| 199 |    872.736006 |    369.936855 | Tommaso Cancellario                                                                                                                                                                  |
| 200 |    367.783213 |    408.972966 | Steven Coombs                                                                                                                                                                        |
| 201 |     33.501437 |    787.752221 | Beth Reinke                                                                                                                                                                          |
| 202 |    376.399957 |    773.922724 | Armin Reindl                                                                                                                                                                         |
| 203 |    972.684540 |    241.751366 | Matt Crook                                                                                                                                                                           |
| 204 |    613.161092 |    503.455361 | Armin Reindl                                                                                                                                                                         |
| 205 |   1007.358871 |    742.636425 | Diana Pomeroy                                                                                                                                                                        |
| 206 |    190.143870 |    640.682297 | Chris Hay                                                                                                                                                                            |
| 207 |    821.055063 |    468.617226 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 208 |    510.841325 |    762.483084 | T. Michael Keesey (photo by Sean Mack)                                                                                                                                               |
| 209 |    852.567599 |    257.451287 | Dean Schnabel                                                                                                                                                                        |
| 210 |     79.886380 |    163.461384 | Tauana J. Cunha                                                                                                                                                                      |
| 211 |    129.466750 |    562.908956 | NA                                                                                                                                                                                   |
| 212 |    180.482031 |    216.660764 | Kanchi Nanjo                                                                                                                                                                         |
| 213 |    253.498326 |      9.674024 | NA                                                                                                                                                                                   |
| 214 |     31.473855 |    350.292353 | Kai R. Caspar                                                                                                                                                                        |
| 215 |    991.733277 |    133.648163 | Gareth Monger                                                                                                                                                                        |
| 216 |    692.783104 |    312.088811 | Gareth Monger                                                                                                                                                                        |
| 217 |    840.369882 |    376.977791 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 218 |    721.880393 |    483.691917 | Jagged Fang Designs                                                                                                                                                                  |
| 219 |    910.148588 |    254.434799 | Mr E? (vectorized by T. Michael Keesey)                                                                                                                                              |
| 220 |     76.928776 |    781.587899 | Zimices                                                                                                                                                                              |
| 221 |   1005.615619 |    497.247346 | Chuanixn Yu                                                                                                                                                                          |
| 222 |    695.161890 |    146.633229 | Margot Michaud                                                                                                                                                                       |
| 223 |    349.318657 |    692.343735 | Markus A. Grohme                                                                                                                                                                     |
| 224 |    680.288998 |    330.511243 | Andy Wilson                                                                                                                                                                          |
| 225 |   1001.622775 |    776.216175 | Alex Slavenko                                                                                                                                                                        |
| 226 |    450.089839 |    475.949844 | Margot Michaud                                                                                                                                                                       |
| 227 |    525.771065 |    115.413568 | Margot Michaud                                                                                                                                                                       |
| 228 |    877.006434 |    696.685878 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                                      |
| 229 |    624.814288 |    294.606705 | Jagged Fang Designs                                                                                                                                                                  |
| 230 |    749.091650 |    564.664872 | T. Michael Keesey                                                                                                                                                                    |
| 231 |    979.059278 |    504.087114 | Scott Hartman                                                                                                                                                                        |
| 232 |     17.976864 |    757.134473 | Chris huh                                                                                                                                                                            |
| 233 |    307.626956 |    458.319213 | Jaime Headden                                                                                                                                                                        |
| 234 |    966.016254 |    521.317969 | Ferran Sayol                                                                                                                                                                         |
| 235 |     15.740697 |    411.339427 | Andy Wilson                                                                                                                                                                          |
| 236 |    425.473551 |    397.122453 | NA                                                                                                                                                                                   |
| 237 |    163.328457 |    253.899786 | Qiang Ou                                                                                                                                                                             |
| 238 |    675.126075 |    605.963184 | Andy Wilson                                                                                                                                                                          |
| 239 |     91.320180 |     18.762436 | Tasman Dixon                                                                                                                                                                         |
| 240 |    481.453934 |    734.574881 | I. Sácek, Sr. (vectorized by T. Michael Keesey)                                                                                                                                      |
| 241 |    436.784011 |    535.601918 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 242 |    640.435325 |    510.638500 | NA                                                                                                                                                                                   |
| 243 |    443.822644 |    733.522677 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 244 |    748.061149 |    429.133758 | Michael P. Taylor                                                                                                                                                                    |
| 245 |     14.407557 |    110.928494 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                                                       |
| 246 |    392.566303 |    316.449338 | Catherine Yasuda                                                                                                                                                                     |
| 247 |   1000.695766 |    326.011934 | Margot Michaud                                                                                                                                                                       |
| 248 |    570.131618 |     63.113944 | Chris huh                                                                                                                                                                            |
| 249 |   1003.766168 |    658.946308 | Rebecca Groom                                                                                                                                                                        |
| 250 |    896.571791 |    777.211812 | Tasman Dixon                                                                                                                                                                         |
| 251 |    410.259849 |    199.401477 | T. Michael Keesey                                                                                                                                                                    |
| 252 |    700.886897 |     95.644974 | Yan Wong from drawing in The Century Dictionary (1911)                                                                                                                               |
| 253 |    160.263356 |    497.132356 | T. Michael Keesey (after Monika Betley)                                                                                                                                              |
| 254 |     27.975363 |    371.111822 | Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin                                                                                                                         |
| 255 |    616.308715 |    229.904067 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                                             |
| 256 |    365.374792 |    707.220506 | Nobu Tamura                                                                                                                                                                          |
| 257 |    227.891181 |    765.678594 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 258 |    962.887578 |    318.712599 | Alexander Schmidt-Lebuhn                                                                                                                                                             |
| 259 |     88.958271 |    282.328332 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 260 |    655.065383 |    775.550116 | NA                                                                                                                                                                                   |
| 261 |     27.232928 |    358.658806 | Xavier Giroux-Bougard                                                                                                                                                                |
| 262 |    524.455933 |    434.132293 | Ferran Sayol                                                                                                                                                                         |
| 263 |    364.759996 |    208.627991 | Giant Blue Anteater (vectorized by T. Michael Keesey)                                                                                                                                |
| 264 |    570.251075 |    337.984932 | Alexandre Vong                                                                                                                                                                       |
| 265 |    541.041138 |    604.119599 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 266 |    842.085274 |    756.564685 | Tasman Dixon                                                                                                                                                                         |
| 267 |    306.127118 |    688.773983 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                                                  |
| 268 |    923.400171 |    309.048617 | T. Michael Keesey (after Monika Betley)                                                                                                                                              |
| 269 |    828.595693 |    609.131562 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                                   |
| 270 |    148.778797 |    180.508196 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 271 |    105.138434 |     48.545018 | Sarah Werning                                                                                                                                                                        |
| 272 |     17.780658 |    135.976849 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 273 |    682.313848 |    733.856329 | Zimices                                                                                                                                                                              |
| 274 |    376.946923 |     88.321139 | Jaime Headden                                                                                                                                                                        |
| 275 |    357.918728 |    185.998321 | NA                                                                                                                                                                                   |
| 276 |    881.000252 |    196.322807 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                                         |
| 277 |     85.334131 |    407.876749 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                                                  |
| 278 |    158.589552 |     14.128740 | Roberto Díaz Sibaja                                                                                                                                                                  |
| 279 |    145.421490 |    105.794726 | Yan Wong                                                                                                                                                                             |
| 280 |    123.461355 |    374.537074 | Tauana J. Cunha                                                                                                                                                                      |
| 281 |    301.423918 |    330.882755 | Michael P. Taylor                                                                                                                                                                    |
| 282 |    977.647051 |    627.958831 | Emily Willoughby                                                                                                                                                                     |
| 283 |     46.605056 |    222.419868 | Myriam\_Ramirez                                                                                                                                                                      |
| 284 |    689.802325 |     24.952831 | Nobu Tamura, modified by Andrew A. Farke                                                                                                                                             |
| 285 |    212.207797 |    530.040242 | Caleb M. Brown                                                                                                                                                                       |
| 286 |    764.497224 |    232.686983 | Scott Hartman                                                                                                                                                                        |
| 287 |    959.409056 |    788.950740 | Steven Traver                                                                                                                                                                        |
| 288 |    798.969563 |    531.653901 | Yan Wong                                                                                                                                                                             |
| 289 |    159.275484 |    514.480376 | Markus A. Grohme                                                                                                                                                                     |
| 290 |    616.974408 |    590.556737 | Gareth Monger                                                                                                                                                                        |
| 291 |    907.879065 |    211.507183 | Steven Traver                                                                                                                                                                        |
| 292 |     61.677855 |    561.006197 | Gareth Monger                                                                                                                                                                        |
| 293 |    839.080046 |    658.498484 | Matt Crook                                                                                                                                                                           |
| 294 |    832.713934 |    447.555451 | Felix Vaux                                                                                                                                                                           |
| 295 |    314.698643 |    648.226833 | Markus A. Grohme                                                                                                                                                                     |
| 296 |   1016.006689 |    399.107413 | NA                                                                                                                                                                                   |
| 297 |    859.401214 |     91.639113 | Michelle Site                                                                                                                                                                        |
| 298 |    394.924556 |    652.874588 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                                       |
| 299 |    411.064724 |    177.840208 | Markus A. Grohme                                                                                                                                                                     |
| 300 |   1003.160206 |    250.014281 | Matt Crook                                                                                                                                                                           |
| 301 |    341.418129 |    144.154234 | Matt Crook                                                                                                                                                                           |
| 302 |    123.969216 |     67.712580 | Dmitry Bogdanov                                                                                                                                                                      |
| 303 |    936.890731 |     86.131491 | Ferran Sayol                                                                                                                                                                         |
| 304 |    879.570942 |    712.619172 | Matt Crook                                                                                                                                                                           |
| 305 |    840.619908 |    176.027127 | Scott Hartman                                                                                                                                                                        |
| 306 |     39.025267 |    148.628113 | Scott Hartman                                                                                                                                                                        |
| 307 |    386.052435 |     99.743764 | NA                                                                                                                                                                                   |
| 308 |    427.821833 |    318.548117 | Gareth Monger                                                                                                                                                                        |
| 309 |    215.628245 |    180.890091 | Chris huh                                                                                                                                                                            |
| 310 |    536.989854 |    546.708048 | T. Michael Keesey                                                                                                                                                                    |
| 311 |    601.617159 |    749.413090 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 312 |    739.321019 |    264.954768 | T. Michael Keesey                                                                                                                                                                    |
| 313 |    428.919286 |    183.290888 | Tasman Dixon                                                                                                                                                                         |
| 314 |    360.690799 |    482.039477 | Zimices                                                                                                                                                                              |
| 315 |   1008.836577 |    159.756432 | Scott Hartman                                                                                                                                                                        |
| 316 |    810.949306 |    451.516157 | Jagged Fang Designs                                                                                                                                                                  |
| 317 |    999.831793 |    466.720714 | S.Martini                                                                                                                                                                            |
| 318 |    923.550294 |     90.083263 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 319 |    613.689916 |    279.566540 | Andy Wilson                                                                                                                                                                          |
| 320 |     86.451656 |    569.091632 | Steven Traver                                                                                                                                                                        |
| 321 |    867.672692 |    631.257541 | Matthew E. Clapham                                                                                                                                                                   |
| 322 |    213.729862 |     97.317947 | Andrew A. Farke                                                                                                                                                                      |
| 323 |    167.844602 |    138.348038 | Markus A. Grohme                                                                                                                                                                     |
| 324 |    227.188494 |    134.941054 | Liftarn                                                                                                                                                                              |
| 325 |    922.520967 |    505.861764 | Zimices                                                                                                                                                                              |
| 326 |   1006.354637 |     41.281479 | Julio Garza                                                                                                                                                                          |
| 327 |    927.232483 |    603.090400 | Milton Tan                                                                                                                                                                           |
| 328 |    958.667785 |    207.129446 | Chris huh                                                                                                                                                                            |
| 329 |    945.478439 |    420.097266 | Scott Hartman                                                                                                                                                                        |
| 330 |   1001.112181 |    769.389824 | Michael P. Taylor                                                                                                                                                                    |
| 331 |    121.993456 |     25.363219 | Matt Celeskey                                                                                                                                                                        |
| 332 |     63.133378 |    261.870736 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 333 |    396.780832 |     73.465692 | Christoph Schomburg                                                                                                                                                                  |
| 334 |    715.628289 |    635.549054 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                                       |
| 335 |    890.938743 |    364.613869 | Felix Vaux                                                                                                                                                                           |
| 336 |    972.875213 |     11.383693 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                                                    |
| 337 |     36.053935 |    766.663620 | Jagged Fang Designs                                                                                                                                                                  |
| 338 |    583.003525 |    147.049843 | NA                                                                                                                                                                                   |
| 339 |    583.563340 |    228.257899 | Richard J. Harris                                                                                                                                                                    |
| 340 |    938.622840 |    529.226402 | Zimices                                                                                                                                                                              |
| 341 |    994.746104 |    413.918851 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 342 |    288.633935 |    561.576684 | Kai R. Caspar                                                                                                                                                                        |
| 343 |    525.644086 |    653.932508 | Michelle Site                                                                                                                                                                        |
| 344 |    614.568517 |    128.940792 | FunkMonk                                                                                                                                                                             |
| 345 |    541.367104 |    720.863308 | T. Michael Keesey (after Tillyard)                                                                                                                                                   |
| 346 |    142.803459 |    146.826886 | Mathew Wedel                                                                                                                                                                         |
| 347 |     79.814318 |      8.407837 | Christine Axon                                                                                                                                                                       |
| 348 |     28.258010 |    285.757821 | Margot Michaud                                                                                                                                                                       |
| 349 |    491.485444 |    562.657949 | Jagged Fang Designs                                                                                                                                                                  |
| 350 |    364.016761 |    585.712082 | CNZdenek                                                                                                                                                                             |
| 351 |    448.828132 |     62.182670 | Javier Luque & Sarah Gerken                                                                                                                                                          |
| 352 |    258.736447 |    492.632585 | Matt Crook                                                                                                                                                                           |
| 353 |    874.652746 |    112.046402 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 354 |    151.434593 |    127.296535 | T. Michael Keesey                                                                                                                                                                    |
| 355 |    852.722369 |    712.539999 | Dmitry Bogdanov                                                                                                                                                                      |
| 356 |     47.948363 |    672.771102 | NA                                                                                                                                                                                   |
| 357 |   1004.843473 |    211.395059 | Chris huh                                                                                                                                                                            |
| 358 |    561.797174 |    431.501327 | Markus A. Grohme                                                                                                                                                                     |
| 359 |    672.188202 |     50.977207 | Andy Wilson                                                                                                                                                                          |
| 360 |    211.901835 |    775.658537 | NA                                                                                                                                                                                   |
| 361 |    864.577219 |    792.156908 | S.Martini                                                                                                                                                                            |
| 362 |    550.213805 |     15.436120 | Markus A. Grohme                                                                                                                                                                     |
| 363 |    415.395664 |    219.286294 | Chris huh                                                                                                                                                                            |
| 364 |    322.459822 |    309.564846 | Tasman Dixon                                                                                                                                                                         |
| 365 |    724.532327 |    450.256957 | Gareth Monger                                                                                                                                                                        |
| 366 |    171.726307 |    108.582050 | Yan Wong                                                                                                                                                                             |
| 367 |     77.569535 |    362.663514 | Matt Crook                                                                                                                                                                           |
| 368 |    420.214277 |    582.770541 | Melissa Broussard                                                                                                                                                                    |
| 369 |    337.995393 |    296.527977 | Gareth Monger                                                                                                                                                                        |
| 370 |    781.722872 |    383.628417 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 371 |   1003.421351 |    180.855407 | Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                         |
| 372 |    458.090611 |    548.325707 | Jagged Fang Designs                                                                                                                                                                  |
| 373 |    173.683991 |    574.522551 | Gareth Monger                                                                                                                                                                        |
| 374 |    287.074341 |    677.756918 | Emma Kissling                                                                                                                                                                        |
| 375 |    810.448757 |    361.422013 | Felix Vaux and Steven A. Trewick                                                                                                                                                     |
| 376 |    742.562611 |    783.681528 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 377 |    608.500032 |     86.480050 | Lily Hughes                                                                                                                                                                          |
| 378 |    710.434468 |    408.298526 | Margot Michaud                                                                                                                                                                       |
| 379 |    738.729060 |     20.155003 | Scott Hartman                                                                                                                                                                        |
| 380 |    520.194195 |    383.012094 | NA                                                                                                                                                                                   |
| 381 |    230.882461 |    618.665199 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 382 |    341.774263 |    159.350738 | T. Michael Keesey                                                                                                                                                                    |
| 383 |    325.476271 |    475.927115 | Matt Crook                                                                                                                                                                           |
| 384 |    422.767439 |     25.419545 | Zimices                                                                                                                                                                              |
| 385 |    428.461278 |    353.666974 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                          |
| 386 |    148.302759 |    212.541864 | Margot Michaud                                                                                                                                                                       |
| 387 |    694.975266 |     63.017088 | Zimices                                                                                                                                                                              |
| 388 |    518.818233 |    622.228235 | NA                                                                                                                                                                                   |
| 389 |    211.170696 |    794.245251 | Eduard Solà (vectorized by T. Michael Keesey)                                                                                                                                        |
| 390 |    640.808037 |    761.656221 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                                         |
| 391 |     37.683347 |    103.675530 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                                          |
| 392 |    289.015945 |    305.031555 | Christoph Schomburg                                                                                                                                                                  |
| 393 |      4.857875 |    479.431626 | NA                                                                                                                                                                                   |
| 394 |    603.455025 |    199.108640 | Darius Nau                                                                                                                                                                           |
| 395 |    157.635313 |    639.431063 | Jakovche                                                                                                                                                                             |
| 396 |    198.936172 |    492.340402 | Scott Hartman                                                                                                                                                                        |
| 397 |    139.441810 |    222.269263 | Jagged Fang Designs                                                                                                                                                                  |
| 398 |    657.954686 |    117.278988 | Harold N Eyster                                                                                                                                                                      |
| 399 |     11.652813 |    583.547797 | Mali’o Kodis, photograph by Bruno Vellutini                                                                                                                                          |
| 400 |    305.470635 |    504.847506 | Agnello Picorelli                                                                                                                                                                    |
| 401 |    693.577154 |    620.159930 | Lukas Panzarin                                                                                                                                                                       |
| 402 |    498.609678 |    325.553944 | FunkMonk                                                                                                                                                                             |
| 403 |   1009.939380 |    298.768078 | Oscar Sanisidro                                                                                                                                                                      |
| 404 |    512.094319 |    744.877760 | Ignacio Contreras                                                                                                                                                                    |
| 405 |    462.821777 |    166.410312 | Michele M Tobias                                                                                                                                                                     |
| 406 |    182.908984 |    507.007695 | Bruno C. Vellutini                                                                                                                                                                   |
| 407 |    777.742027 |      8.353927 | Zimices                                                                                                                                                                              |
| 408 |    879.098729 |    341.772655 | Scott Hartman                                                                                                                                                                        |
| 409 |     31.673945 |      7.533124 | Zimices                                                                                                                                                                              |
| 410 |    334.394838 |    222.490035 | Collin Gross                                                                                                                                                                         |
| 411 |    981.102329 |    663.050225 | Robert Gay                                                                                                                                                                           |
| 412 |    883.966381 |    598.753607 | Zimices                                                                                                                                                                              |
| 413 |    125.409367 |    759.547848 | Tracy A. Heath                                                                                                                                                                       |
| 414 |    943.687473 |    659.345245 | T. Michael Keesey                                                                                                                                                                    |
| 415 |     48.668537 |    717.505476 | NA                                                                                                                                                                                   |
| 416 |    399.264648 |    627.653446 | Acrocynus (vectorized by T. Michael Keesey)                                                                                                                                          |
| 417 |    271.346672 |    450.980820 | Jagged Fang Designs                                                                                                                                                                  |
| 418 |    862.011189 |    734.273705 | Mattia Menchetti                                                                                                                                                                     |
| 419 |    357.571885 |    764.661579 | Steven Coombs                                                                                                                                                                        |
| 420 |    933.746831 |    657.950496 | T. Michael Keesey                                                                                                                                                                    |
| 421 |    355.340607 |    776.490640 | nicubunu                                                                                                                                                                             |
| 422 |    968.976409 |    415.303314 | Crystal Maier                                                                                                                                                                        |
| 423 |    354.823809 |    380.050314 | Sarah Werning                                                                                                                                                                        |
| 424 |    272.481431 |     17.624117 | Tasman Dixon                                                                                                                                                                         |
| 425 |    871.241995 |    274.743705 | NA                                                                                                                                                                                   |
| 426 |    975.903264 |    190.205114 | Gareth Monger                                                                                                                                                                        |
| 427 |    458.886938 |    793.631700 | SauropodomorphMonarch                                                                                                                                                                |
| 428 |    641.412741 |    449.439819 | Zimices                                                                                                                                                                              |
| 429 |    386.667038 |    223.551173 | Andy Wilson                                                                                                                                                                          |
| 430 |    776.801824 |    498.183608 | Gareth Monger                                                                                                                                                                        |
| 431 |    236.495985 |    145.165600 | Jay Matternes (vectorized by T. Michael Keesey)                                                                                                                                      |
| 432 |    396.087855 |    671.741854 | Jagged Fang Designs                                                                                                                                                                  |
| 433 |    231.285713 |    172.650170 | Steven Traver                                                                                                                                                                        |
| 434 |    226.663758 |    191.343439 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 435 |   1016.214157 |    638.708330 | Gareth Monger                                                                                                                                                                        |
| 436 |    384.441621 |    738.079129 | Zimices                                                                                                                                                                              |
| 437 |    970.559486 |    582.578044 | Becky Barnes                                                                                                                                                                         |
| 438 |    891.283476 |    317.349511 | Chris huh                                                                                                                                                                            |
| 439 |    302.283470 |    292.515801 | Ferran Sayol                                                                                                                                                                         |
| 440 |    842.686245 |    183.072915 | Jagged Fang Designs                                                                                                                                                                  |
| 441 |    392.932181 |    352.884945 | Markus A. Grohme                                                                                                                                                                     |
| 442 |    900.971681 |    796.143015 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                                       |
| 443 |    407.570778 |    635.914165 | Gareth Monger                                                                                                                                                                        |
| 444 |    799.625397 |     23.841275 | Kamil S. Jaron                                                                                                                                                                       |
| 445 |    367.763391 |    668.919178 | Harold N Eyster                                                                                                                                                                      |
| 446 |    337.606781 |    343.052712 | Yan Wong                                                                                                                                                                             |
| 447 |     17.590348 |    461.328948 | Martin R. Smith                                                                                                                                                                      |
| 448 |    764.487678 |    655.021027 | Andrew A. Farke                                                                                                                                                                      |
| 449 |    614.176581 |    639.958880 | Chris huh                                                                                                                                                                            |
| 450 |    387.075238 |    686.998934 | Scott Hartman                                                                                                                                                                        |
| 451 |    828.788461 |    786.714745 | Steven Traver                                                                                                                                                                        |
| 452 |    275.552399 |     95.354912 | Christoph Schomburg                                                                                                                                                                  |
| 453 |    995.594285 |    341.627739 | Ignacio Contreras                                                                                                                                                                    |
| 454 |    650.945496 |    263.334065 | SecretJellyMan - from Mason McNair                                                                                                                                                   |
| 455 |    373.612773 |    723.750522 | xgirouxb                                                                                                                                                                             |
| 456 |    796.219634 |    248.242787 | Alex Slavenko                                                                                                                                                                        |
| 457 |     95.344813 |    640.512017 | Scott Hartman                                                                                                                                                                        |
| 458 |    343.324257 |     92.710557 | Darius Nau                                                                                                                                                                           |
| 459 |    313.325970 |    768.884612 | Margot Michaud                                                                                                                                                                       |
| 460 |    679.264460 |    708.551193 | Gabriela Palomo-Munoz                                                                                                                                                                |
| 461 |     17.872497 |     86.551406 | Tasman Dixon                                                                                                                                                                         |
| 462 |    963.041772 |    742.222538 | Andrew A. Farke                                                                                                                                                                      |
| 463 |    848.128173 |    404.650956 | Jagged Fang Designs                                                                                                                                                                  |
| 464 |    770.403812 |    617.487038 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey)                |
| 465 |    275.477994 |    664.988020 | Gareth Monger                                                                                                                                                                        |
| 466 |    639.417317 |     88.600329 | Michele Tobias                                                                                                                                                                       |
| 467 |     72.907428 |    475.353827 | Chris huh                                                                                                                                                                            |
| 468 |    246.889654 |     23.771361 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                                        |
| 469 |     99.388747 |    286.207747 | Ignacio Contreras                                                                                                                                                                    |
| 470 |    739.502322 |     10.392427 | NA                                                                                                                                                                                   |
| 471 |      8.322863 |    350.383945 | T. Michael Keesey                                                                                                                                                                    |
| 472 |    641.394235 |    431.502464 | Chris huh                                                                                                                                                                            |
| 473 |    642.131681 |    183.974116 | Jack Mayer Wood                                                                                                                                                                      |
| 474 |    549.293519 |    349.849180 | John Curtis (vectorized by T. Michael Keesey)                                                                                                                                        |
| 475 |    472.265834 |    718.489085 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                                                   |
| 476 |    878.492074 |    182.090304 | Tasman Dixon                                                                                                                                                                         |
| 477 |    333.649381 |    619.199536 | Chris huh                                                                                                                                                                            |
| 478 |    520.977391 |    670.475079 | Markus A. Grohme                                                                                                                                                                     |
| 479 |    770.312071 |     14.038865 | Smokeybjb                                                                                                                                                                            |
| 480 |    626.027642 |    521.033967 | Beth Reinke                                                                                                                                                                          |
| 481 |    464.540592 |    565.252436 | Scott Hartman                                                                                                                                                                        |
| 482 |    169.937255 |    468.649788 | T. Michael Keesey                                                                                                                                                                    |
| 483 |    736.900250 |    497.550926 | Markus A. Grohme                                                                                                                                                                     |
| 484 |    470.349265 |    198.632553 | Margot Michaud                                                                                                                                                                       |
| 485 |    974.264796 |    698.679647 | Gareth Monger                                                                                                                                                                        |
| 486 |    630.759759 |    455.099934 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 487 |    453.783498 |    697.474146 | Markus A. Grohme                                                                                                                                                                     |
| 488 |    727.714499 |    303.310647 | Scott Hartman                                                                                                                                                                        |
| 489 |     44.548194 |     93.621843 | Chris huh                                                                                                                                                                            |
| 490 |    252.760642 |    674.099416 | Geoff Shaw                                                                                                                                                                           |
| 491 |    913.189319 |    742.993714 | Scott Hartman                                                                                                                                                                        |
| 492 |    720.523352 |     96.376918 | Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey                |
| 493 |    925.503066 |    108.097068 | Ingo Braasch                                                                                                                                                                         |
| 494 |    920.136156 |    406.826826 | NA                                                                                                                                                                                   |
| 495 |    674.080080 |     36.692515 | Bennet McComish, photo by Avenue                                                                                                                                                     |
| 496 |    485.884212 |    518.765816 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 497 |    863.950614 |    357.868293 | Matt Crook                                                                                                                                                                           |
| 498 |    379.648251 |    479.644673 | Harold N Eyster                                                                                                                                                                      |
| 499 |    526.369544 |    125.767322 | Chris huh                                                                                                                                                                            |
| 500 |    407.589035 |    499.810662 | Gareth Monger                                                                                                                                                                        |
| 501 |    114.816843 |    272.635347 | Beth Reinke                                                                                                                                                                          |
| 502 |    265.863623 |      1.517416 | Smokeybjb                                                                                                                                                                            |
| 503 |     87.008146 |    676.852005 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                                    |
| 504 |    896.173402 |    516.540693 | T. Michael Keesey                                                                                                                                                                    |
| 505 |     39.053280 |    124.712776 | Andrew A. Farke                                                                                                                                                                      |
| 506 |    445.709098 |    502.256521 | Ferran Sayol                                                                                                                                                                         |
| 507 |    566.198200 |    731.871556 | Zimices                                                                                                                                                                              |
| 508 |    131.760840 |    491.218777 | Gareth Monger                                                                                                                                                                        |
| 509 |    808.803361 |    440.015773 | Margot Michaud                                                                                                                                                                       |
| 510 |     68.124327 |    767.051732 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                                        |
| 511 |    143.266638 |    793.078854 | Siobhon Egan                                                                                                                                                                         |
| 512 |    185.308067 |    670.915472 | Margot Michaud                                                                                                                                                                       |
| 513 |    198.986157 |    430.631335 | Gareth Monger                                                                                                                                                                        |
| 514 |    399.762438 |    781.174517 | Zimices                                                                                                                                                                              |
| 515 |    115.306899 |    512.722728 | Sherman Foote Denton (illustration, 1897) and Timothy J. Bartley (silhouette)                                                                                                        |
| 516 |    754.327063 |    789.127743 | Michael P. Taylor                                                                                                                                                                    |
| 517 |    839.099842 |    237.777292 | C. Camilo Julián-Caballero                                                                                                                                                           |
| 518 |    425.595091 |    296.746418 | Chris huh                                                                                                                                                                            |

    #> Your tweet has been posted!
